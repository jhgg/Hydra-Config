-- Hi!
-- Save this as ~/.mjolnir/init.lua and choose Reload Config from the menu
local hydra = require 'mjolnir._asm.hydra'
local alert = require 'mjolnir.alert'

import = require('utils/import')
import.clear_cache()

config = import('config')

function config:get(key_path, default)
    local root = self
    for part in string.gmatch(key_path, "[^\\.]+") do
        root = root[part]
        if root == nil then
            return default
        end
    end
    return root
end

local modules = {}

for _, v in ipairs(config.modules) do
    local module_name = 'modules/' .. v
    local module = import(module_name)

    if type(module.init) == "function" then
        module.init()
    end

    table.insert(modules, module)
end

hydra.autolaunch(config:get("autolaunch", false))

local buf = {}

if hydra.was_loaded == nil then
    hydra.was_loaded = true
    table.insert(buf, "Mjolnir loaded: ")
else
    table.insert(buf, "Mjolnir re-loaded: ")
end

table.insert(buf, #modules .. " modules.")

alert.show(table.concat(buf))



