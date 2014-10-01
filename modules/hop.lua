local hotkey = require 'mjolnir.hotkey'
local window = require 'mjolnir.window'

local function module_init()
    local mash = config:get("hop.mash", { "cmd", "ctrl", "alt", "shift" })
    local keys = config:get("hop.keys", {
        UP = "north",
        DOWN = "south",
        LEFT = "west",
        RIGHT = "east",
    })

    for key, direction_string in pairs(keys) do
        local fn = window['focuswindow_' .. direction_string]
        if fn == nil then
            error("The direction must be one of north, south, east, or west. Not " .. direction_string)
        end

        hotkey.bind(mash, key, function()
            local win = window.focusedwindow()
            if win == nil then
                return
            end
            fn(win)
        end)
    end
end


return {
    init = module_init
}
