local fnutils = require 'mjolnir.fnutils'
local screen = require 'mjolnir.screen'

local dimensions__proto = {}
local dimensions__mt = { __index = dimensions__proto }

function dimensions__proto:relative_to(position)
    if position._relative ~= nil then
        return position
    end

    return {
        w = position.w,
        h = position.h,
        x = self.x + position.x,
        y = self.y + position.y,
        _relative = true
    }
end

function dimensions__proto:relative_window_position(win)
    local frame = win:frame()
    local screen = win:screen()
    local screenframe = screen:frame()

    return self:relative_to({
        w = frame.w,
        h = frame.h,
        x = frame.x - screenframe.x,
        y = frame.y - screenframe.y,
    })

end

function dimensions__proto:translate_from(position_func, translation_table)
    if type(position_func) == "string" then
        position_func = import('utils/position')[position_func]
    end

    local position = position_func(self)
    position._relative = true

    for k, v in pairs(translation_table) do
        position[k] = position[k] + v
    end

    return position
end


local function get_screen_dimensions(screen)

    local dim = screen:frame()
    local frame = screen:fullframe()

    local dimensions = {
        w = dim.w,
        h = dim.h,
        x = dim.x,
        y = dim.y,
        f = {
            w = frame.w,
            h = frame.h,
            x = frame.x,
            y = frame.y
        }
    }

    setmetatable(dimensions, dimensions__mt)
    return dimensions
end

local function get_screen_dimensions_at_index(index)
    local screen = screen.allscreens()[index]
    if screen == nil then
        error("Cannot find screen with index " .. index)
    end

    return get_screen_dimensions(screen)
end

local function autodiscover_monitors(rows)
    local screens = screen.allscreens()
    local primary_screen = fnutils.find(screens, function(screen)
        local dim = screen:fullframe()
        return dim.x == 0 and dim.y == 0
    end)
    local screen_table = {}
    local reference_screen_frame = primary_screen:fullframe()

    for _ = 1, rows do
        local monitors_in_row = fnutils.filter(screens, function(screen)
            return screen:fullframe().y == reference_screen_frame.y
        end)

        table.sort(monitors_in_row, function(a, b)
            return a:fullframe().x < b:fullframe().x
        end)

        fnutils.concat(screen_table, monitors_in_row)
        reference_screen_frame.y = reference_screen_frame.y - reference_screen_frame.h
    end

    return fnutils.map(screen_table, function(screen)
        return {
            dimensions = get_screen_dimensions(screen)
        }
    end)
end

local monitors = {
    get_screen_dimensions = get_screen_dimensions,
    configured_monitors = {}
}

if config:get("monitors.autodiscover", false) then
    monitors.configured_monitors = autodiscover_monitors(config:get("monitors.rows", 1))
else
    for i, v in ipairs(config:get("monitors", {})) do
        monitors.configured_monitors[i] = {
            dimensions = get_screen_dimensions_at_index(v)
        }
    end
end

return monitors
