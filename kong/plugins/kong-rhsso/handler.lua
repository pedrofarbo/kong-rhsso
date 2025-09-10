local http = require "resty.http"
local json = require "cjson"

local RhssoHandler = {
  VERSION = "0.2.0",
  PRIORITY = 1000
}

-- Simple in-memory cache using ngx.shared.DICT
local function get_cache()
  return ngx.shared.kong_cache or ngx.shared.kong
end

-- Cache functions
local function get_cache_key(token, client_id)
  return "rhsso:" .. ngx.md5(token .. ":" .. client_id)
end

local function get_from_cache(token, client_id, ttl)
  if not ttl or ttl <= 0 then
    return nil -- Cache disabled
  end
  
  local cache = get_cache()
  if not cache then
    return nil -- No cache available
  end
  
  local cache_key = get_cache_key(token, client_id)
  local cached_data, flags = cache:get(cache_key)
  
  if cached_data then
    log_debug("Cache hit", { cache_key = cache_key })
    local ok, result = pcall(json.decode, cached_data)
    return ok and result or nil
  end
  
  return nil
end

local function set_in_cache(token, client_id, introspection_result, ttl)
  if not ttl or ttl <= 0 then
    return -- Cache disabled
  end
  
  local cache = get_cache()
  if not cache then
    return -- No cache available
  end
  
  local cache_key = get_cache_key(token, client_id)
  local cache_data = json.encode(introspection_result)
  
  local ok, err = cache:set(cache_key, cache_data, ttl)
  if not ok then
    log_debug("Failed to set cache", { error = err, cache_key = cache_key })
  else
    log_debug("Cache set", { cache_key = cache_key, ttl = ttl })
  end
end

-- Constants
local ERROR_CODES = {
  TOKEN_EXPIRED = "COD-01",
  ACCESS_DENIED = "COD-02", 
  TOKEN_VALIDATION_FAILED = "COD-03",
  INVALID_TOKEN_FORMAT = "COD-04",
  TOKEN_REQUIRED = "COD-05",
  NETWORK_ERROR = "COD-06",
  INVALID_RESPONSE = "COD-07"
}

-- Utility functions
local function log_error(message, err)
  kong.log.err(message, err and (" - " .. err) or "")
end

local function log_debug(message, data)
  if data then
    kong.log.debug(message, " - ", json.encode(data))
  else
    kong.log.debug(message)
  end
end

local function log_with_level(level, message, data)
  local log_func = kong.log[level] or kong.log.info
  if data then
    log_func(message, " - ", json.encode(data))
  else
    log_func(message)
  end
end

local function build_error_response(code, message)
  return {
    error = true,
    code = code,
    message = message,
    timestamp = ngx.time()
  }
end

-- Metrics collection
local function collect_metrics(conf, metric_name, value, tags)
  if not conf.enable_metrics then
    return
  end
  
  tags = tags or {}
  tags.plugin = "kong-rhsso"
  tags.version = RhssoHandler.VERSION
  
  -- Log metrics in a structured format for external collection
  kong.log.info("METRIC", {
    name = metric_name,
    value = value,
    tags = tags,
    timestamp = ngx.time()
  })
end

-- Utility function to split string by spaces
local function split_string(str, sep)
  local sep, fields = sep or " ", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

-- Token extraction function
local function extract_bearer_token(authorization_header)
  if not authorization_header then
    return nil, ERROR_CODES.TOKEN_REQUIRED, "Token é obrigatório!"
  end

  local token = authorization_header:match("^Bearer%s+(.+)$")
  if not token then
    return nil, ERROR_CODES.INVALID_TOKEN_FORMAT, "Formato do token inválido!"
  end

  return token
end

-- HTTP client with retry logic
local function make_http_request(url, body, headers, timeout, ssl_verify)
  local httpc = http.new()
  httpc:set_timeout((timeout or 10) * 1000) -- Convert to milliseconds
  
  local max_retries = 2
  local retry_delay = 0.1
  
  for attempt = 1, max_retries + 1 do
    local res, err = httpc:request_uri(url, {
      method = "POST",
      body = body,
      headers = headers,
      ssl_verify = ssl_verify or false,
    })
    
    if res then
      return res, nil
    end
    
    if attempt <= max_retries then
      log_debug("HTTP request failed, retrying", { attempt = attempt, error = err })
      ngx.sleep(retry_delay * attempt)
    else
      return nil, err
    end
  end
end

-- Token introspection function
local function introspect_token(token, client, conf)
  local introspect_url = string.format(
    "%s/realms/%s/protocol/openid-connect/token/introspect", 
    conf.rhsso_base_url, 
    client.realm
  )
  
  local request_body = ngx.encode_args({
    token = token,
    client_id = client.client_id,
    client_secret = client.client_secret,
  })
  
  local headers = {
    ["Content-Type"] = "application/x-www-form-urlencoded",
    ["User-Agent"] = "Kong RHSSO Plugin v" .. RhssoHandler.VERSION
  }
  
  log_debug("Making introspection request", { 
    url = introspect_url, 
    client_id = client.client_id,
    realm = client.realm 
  })
  
  local res, err = make_http_request(
    introspect_url, 
    request_body, 
    headers, 
    conf.timeout,
    conf.ssl_verify
  )
  
  if not res then
    log_error("Failed to validate token via introspection", err)
    return nil, ERROR_CODES.NETWORK_ERROR, "Falha na comunicação com o servidor de autenticação"
  end
  
  if res.status ~= 200 then
    log_error("Introspection endpoint returned non-200 status", res.status)
    return nil, ERROR_CODES.TOKEN_VALIDATION_FAILED, "Falha ao validar o token"
  end
  
  local ok, response_body = pcall(json.decode, res.body)
  if not ok then
    log_error("Failed to parse introspection response", response_body)
    return nil, ERROR_CODES.INVALID_RESPONSE, "Resposta inválida do servidor de autenticação"
  end
  
  return response_body
end

-- Scope validation function
local function validate_scopes(token_scopes_str, required_scopes)
  if not required_scopes or #required_scopes == 0 then
    return true -- No scope validation required
  end
  
  local token_scopes = split_string(token_scopes_str or "", " ")
  local token_scope_set = {}
  
  -- Create a set for faster lookup
  for _, scope in ipairs(token_scopes) do
    token_scope_set[scope] = true
  end
  
  -- Check if all required scopes are present
  for _, required_scope in ipairs(required_scopes) do
    if not token_scope_set[required_scope] then
      log_debug("Required scope not found", { 
        required = required_scope, 
        available = token_scopes 
      })
      return false
    end
  end
  
  return true
end

function RhssoHandler:access(conf)
  local start_time = ngx.now()
  
  -- Collect request metric
  collect_metrics(conf, "rhsso_requests_total", 1, { type = "incoming" })
  
  -- Extract token from Authorization header
  local token, error_code, error_message = extract_bearer_token(kong.request.get_header("Authorization"))
  if not token then
    collect_metrics(conf, "rhsso_errors_total", 1, { 
      error_code = error_code,
      type = "token_extraction" 
    })
    log_with_level(conf.log_level, "Token validation failed", { 
      code = error_code, 
      message = error_message 
    })
    return kong.response.exit(401, build_error_response(error_code, error_message))
  end
  
  log_debug("Processing token validation", { 
    clients_count = #conf.clients,
    cache_enabled = (conf.cache_ttl and conf.cache_ttl > 0)
  })
  
  -- Try to validate token against each configured client
  for i, client in ipairs(conf.clients) do
    log_debug("Validating against client", { 
      index = i, 
      client_id = client.client_id, 
      realm = client.realm 
    })
    
    -- Check cache first
    local introspection_result = get_from_cache(token, client.client_id, conf.cache_ttl)
    
    if not introspection_result then
      -- Cache miss, perform introspection
      local err_code, err_msg
      introspection_result, err_code, err_msg = introspect_token(token, client, conf)
      
      if introspection_result then
        -- Cache the result if token is active
        if introspection_result.active then
          set_in_cache(token, client.client_id, introspection_result, conf.cache_ttl)
        end
      else
        log_debug("Token introspection failed for client", { 
          client_id = client.client_id, 
          error = err_msg 
        })
        goto continue
      end
    else
      log_debug("Using cached introspection result", { client_id = client.client_id })
    end
    
    if introspection_result then
      if introspection_result.active then
        -- Parse required scopes
        local required_scopes = client.scopes and split_string(client.scopes, ",") or {}
        
        -- Trim whitespace from scopes
        for j, scope in ipairs(required_scopes) do
          required_scopes[j] = scope:match("^%s*(.-)%s*$")
        end
        
        -- Validate scopes if required
        if not validate_scopes(introspection_result.scope, required_scopes) then
          collect_metrics(conf, "rhsso_errors_total", 1, { 
            error_code = ERROR_CODES.ACCESS_DENIED,
            type = "scope_validation",
            client_id = client.client_id
          })
          kong.log.info("Access denied - insufficient scopes", {
            required = required_scopes,
            provided = introspection_result.scope,
            client_id = client.client_id
          })
          return kong.response.exit(403, build_error_response(
            ERROR_CODES.ACCESS_DENIED, 
            "Acesso não autorizado - escopo insuficiente!"
          ))
        end
        
        -- Token is valid and has required scopes
        local processing_time = ngx.now() - start_time
        
        collect_metrics(conf, "rhsso_successful_validations_total", 1, {
          client_id = client.client_id,
          realm = client.realm
        })
        collect_metrics(conf, "rhsso_processing_time_seconds", processing_time, {
          client_id = client.client_id,
          realm = client.realm
        })
        
        kong.log.info("Token validation successful", {
          client_id = client.client_id,
          realm = client.realm,
          processing_time_ms = math.floor(processing_time * 1000),
          user = introspection_result.username or introspection_result.sub
        })
        
        -- Set user context for downstream services
        kong.service.request.set_header("X-Authenticated-User", introspection_result.username or introspection_result.sub)
        kong.service.request.set_header("X-Authenticated-Client", client.client_id)
        kong.service.request.set_header("X-User-Scopes", introspection_result.scope or "")
        
        return -- Allow the request to proceed
      else
        log_debug("Token is not active for client", { client_id = client.client_id })
      end
    end
    
    ::continue::
  end
  
  -- If we get here, token validation failed for all clients
  local processing_time = ngx.now() - start_time
  
  collect_metrics(conf, "rhsso_errors_total", 1, { 
    error_code = ERROR_CODES.TOKEN_EXPIRED,
    type = "token_validation_failed"
  })
  collect_metrics(conf, "rhsso_processing_time_seconds", processing_time, {
    result = "failed"
  })
  
  kong.log.info("Token validation failed for all clients", {
    clients_tried = #conf.clients,
    processing_time_ms = math.floor(processing_time * 1000)
  })
  
  return kong.response.exit(401, build_error_response(
    ERROR_CODES.TOKEN_EXPIRED, 
    "Token inválido ou expirado!"
  ))
end

return RhssoHandler
