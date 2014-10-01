local hotkey = require 'mjolnir.hotkey'
local window = require 'mjolnir.window'

local position = import('utils/position')
local monitors = import('utils/monitors')

local function module_init()
    local mash = config:get("arrows.mash", { "cmd", "ctrl", "alt" })
    local keys = config:get("arrows.keys", {
        UP = "top",
        DOWN = "bottom",
        LEFT = "left",
        RIGHT = "right",
        SPACE = "full",
        PAD7 = "left_third",
        PAD8 = "middle_third",
        PAD9 = "right_third",
    })

    for key, position_string in pairs(keys) do
        local position_fn = position[position_string]

        if position_fn == nil then
            error("arrow: " .. position_string .. " is not a valid position")
        end

        hotkey.bind(mash, key, function()
            local win = window.focusedwindow()
            if win == nil then
                return
            end

            local screen = win:screen()
            local dimensions = monitors.get_screen_dimensions(screen)
            local newframe = position_fn(dimensions)

            win:setframe(newframe)
        end)

    end

end

return {
    init = module_init
}
