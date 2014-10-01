local hotkey = require 'mjolnir.hotkey'
local window = require 'mjolnir.window'

local function module_init()
    local mash = config:get('fullscreen.mash', { "cmd", "ctrl" })
    local key = config:get('fullscreen.key', "A")

    hotkey.bind(mash, key, function()
        local win = window.focusedwindow()
        if win ~= nil then
            win:setfullscreen(not win:isfullscreen())
        end
    end)
end

return {
    init = module_init
}
