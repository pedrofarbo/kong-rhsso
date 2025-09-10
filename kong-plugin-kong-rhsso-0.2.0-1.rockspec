local plugin_name = "kong-rhsso"
local package_name = "kong-plugin-"..plugin_name
local package_version = "0.2.0"
local rockspec_revision = "1"

package = package_name
version = package_version .. "-" .. rockspec_revision
supported_platforms = { "linux", "macosx" }

source = {
  url = ".",
}

description = {
  summary = "Kong plugin for RHSSO/Keycloak authentication with advanced features",
  detailed = [[
    This plugin provides comprehensive RHSSO/Keycloak authentication for Kong Gateway.
    Features include:
    - Token validation via introspection endpoint
    - Multiple realm and client support
    - Advanced scope validation with multiple required scopes
    - Configurable caching for improved performance
    - Structured logging and metrics collection
    - Retry logic and configurable timeouts
    - SSL verification options
    - Request headers for downstream services
  ]],
  homepage = "https://github.com/pedrofarbo/kong-rhsso",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "lua-resty-http >= 0.15"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.kong-rhsso.handler"] = "kong/plugins/kong-rhsso/handler.lua",
    ["kong.plugins.kong-rhsso.schema"] = "kong/plugins/kong-rhsso/schema.lua"
  }
}