local hotkey = require 'mjolnir.hotkey'
local window = require 'mjolnir.window'

local nudge = import('utils/nudge')

local function module_init()
    local mash = config:get("slide.mash", { "cmd", "ctrl", "alt" })
    local keys = config:get("slide.keys", {
        UP = "shorter",
        DOWN = "taller",
        LEFT = "narrower",
        RIGHT = "wider",
    })

    for key, direction_string in pairs(keys) do
        local nudge_fn = nudge[direction_string]


        if nudge_fn == nil then
            error("arrow: " .. direction_string .. " is not a valid direction")
        end

        hotkey.bind(mash, key, function()
            local win = window.focusedwindow()
            if win == nil then
                return
            end

            local dimensions = win:focusedwindow():frame()
            local newframe = nudge_fn(dimensions)

            win:setframe(newframe)
        end)
    end
end

return {
    init = module_init
}
