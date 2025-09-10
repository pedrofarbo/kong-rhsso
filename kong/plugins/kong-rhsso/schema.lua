local typedefs = require "kong.db.schema.typedefs"

return {
  name = "kong-rhsso",
  fields = {
    {
      consumer = typedefs.no_consumer
    },
    {
      protocols = typedefs.protocols_http
    },
    { config = {
        type = "record",
        fields = {
          { rhsso_base_url = { type = "string", required = true }, },
          { clients = {
              type = "array",
              elements = {
                type = "record",
                fields = {
                  { client_id = { type = "string", required = true }, },
                  { client_secret = { type = "string", required = true, encrypted = true }, },
                  { realm = { type = "string", required = true }, },
                  { scopes = { type = "string", required = false }, }, -- Changed from 'scope' to 'scopes' for multiple scopes support
                }
              },
              required = true,
          }, },
          { timeout = { 
              type = "number", 
              default = 10,
              between = { 1, 300 },
              description = "Timeout for RHSSO requests in seconds"
          }, },
          { ssl_verify = { 
              type = "boolean", 
              default = false,
              description = "Whether to verify SSL certificates when making requests to RHSSO"
          }, },
          { cache_ttl = { 
              type = "number", 
              default = 300,
              between = { 0, 3600 },
              description = "Cache TTL for token validation results in seconds (0 to disable cache)"
          }, },
          { enable_metrics = { 
              type = "boolean", 
              default = true,
              description = "Whether to enable metrics collection for monitoring"
          }, },
          { log_level = { 
              type = "string", 
              default = "info",
              one_of = { "debug", "info", "warn", "error" },
              description = "Log level for plugin-specific logging"
          }, },
        },
      },
    },
  },
}
