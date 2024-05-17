package = "kong-rhsso"
version = "0.1-1"
source = {
  url = "#"
}

description = {
  summary = "Kong plugin for RHSSO authentication",
  detailed = [[
    This plugin uses the RHSSO introspection endpoint to validate tokens and
    supports multiple realms, clients, and scope validation.
  ]],
  homepage = "#",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "lua-resty-http >= 0.15"
}

build = {
  type = "builtin",
  modules = {
    ["kong-rhsso.handler"] = "handler.lua",
    ["kong-rhsso.schema"] = "schema.lua"
  }
}