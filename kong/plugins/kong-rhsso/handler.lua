local http = require "resty.http"
local cjson = require "cjson"

local kong_rhsso = {
  PRIORITY = 1000
}

function kong_rhsso:access(conf)
  local req = kong.request
  local token = req.get_header("Authorization")
  if not token then
    return kong.response.exit(401, { message = "Acesso não autorizado!" })
  end

  token = token:match("^Bearer%s+(.+)$")
  if not token then
    return kong.response.exit(401, { message = "Formato do token inválido!" })
  end

  local httpc = http.new()
  for _, client in ipairs(conf.clients) do
    local introspect_url = string.format("%s/realms/%s/protocol/openid-connect/token/introspect", conf.rhsso_base_url, client.realm)
    local res, err = httpc:request_uri(introspect_url, {
      method = "POST",
      body = ngx.encode_args({
        token = token,
        client_id = client.client_id,
        client_secret = client.client_secret,
      }),
      headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
      },
      ssl_verify = false,
    })

    if not res then
      kong.log.err("Falha ao validar token: ", err)
      return kong.response.exit(500, { message = "Internal Server Error" })
    end

    local response_body = cjson.decode(res.body)
    
    kong.log.err(response_body)

    if response_body.active then
      -- Validate the required scope for the client
      local token_scopes = response_body.scope and response_body.scope:split(" ") or {}
      local required_scope = client.scope
      local scope_found = false
      for _, scope in ipairs(token_scopes) do
        if scope == required_scope then
          scope_found = true
          break
        end
      end

      if not scope_found then
        return kong.response.exit(403, { message = "Acesso não autorizado!" })
      end

      return -- token is valid, allow the request
    end
  end

  return kong.response.exit(401, { message = "Token inválido ou expirado!" })
end

-- Utility function to split string by spaces
function string:split(sep)
  local sep, fields = sep or " ", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

return kong_rhsso

