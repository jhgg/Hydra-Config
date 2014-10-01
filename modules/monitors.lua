local hotkey = require 'mjolnir.hotkey'
local window = require 'mjolnir.window'
local geometry = require 'mjolnir.geometry'
local mouse = require 'mjolnir.jstevenson.cursor'

local position = import('utils/position')
local monitors = import('utils/monitors')

local function init_module()
    for id, monitor in pairs(monitors.configured_monitors) do

        hotkey.bind({ "cmd", "ctrl" }, "PAD" .. id, function()
            local midpoint = geometry.rectmidpoint(monitor.dimensions)
            mouse.set(midpoint)
        end)

        hotkey.bind({ "cmd", "ctrl", "alt" }, "PAD" .. id, function()
            local win = window.focusedwindow()
            if win ~= nil then
                win:setframe(position.full(monitor.dimensions))
            end
        end)

        hotkey.bind({ "ctrl", "alt" }, "PAD" .. id, function()
            local win = window.focusedwindow()
            if win ~= nil then
                win:setframe(position.left(monitor.dimensions))
            end
        end)

        hotkey.bind({ "cmd", "alt" }, "PAD" .. id, function()
            local win = window.focusedwindow()
            if win ~= nil then
                win:setframe(position.right(monitor.dimensions))
            end
        end)
        hotkey.bind({ "shift", "ctrl", "alt" }, "PAD" .. id, function()
            local win = window.focusedwindow()
            if win ~= nil then
                win:setframe(monitor.dimensions:relative_window_position(win))
            end
        end)
    end
end

return {
    init = init_module
}
