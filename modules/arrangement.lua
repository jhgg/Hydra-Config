local alert = require 'mjolnir.alert'
local notify = require 'mjolnir._asm.notify'
local fnutils = require 'mjolnir.fnutils'
local hotkey = require 'mjolnir.hotkey'

local find = import('utils/find')
local monitors = import('utils/monitors').configured_monitors
local position = import('utils/position')

local function get_window(arrangement_table)
    if arrangement_table.app_title ~= nil then
        return find.window.by_application_title(arrangement_table.app_title)
    end

    if arrangement_table.title ~= nil then
        return find.window.by_title(arrangement_table.app_title)
    end

    error("Arrangement table needs: app_title or title to be set")
end


local function arrange(arrangement)
    fnutils.map(arrangement, function(item)

        local window = get_window(item)
        if window == nil then
            return
        end

        local monitor = item.monitor
        local item_position = item.position

        if monitor == nil then
            error("arrangement table does not have monitor")
        end

        if item_position == nil then
            error("arrangement table does not have position")
        end

        if monitors[monitor] == nil then
            error("monitor " .. monitor .. " does not exist")
        end

        local win_full = window:isfullscreen()

        if item_position ~= "full_screen" and win_full then
                    window:setfullscreen(false)
        end

        if type(item_position) == "string" then

            if item_position == "full_screen" then
                window:setframe(monitors[monitor].dimensions.f)

                if not win_full then
                    window:setfullscreen(true)
                end

            else
                if position[item_position] == nil then
                    alert.show("Unknown position: " .. item_position, 1.0)
                else
                    window:setframe(position[item_position](monitors[monitor].dimensions))
                end
            end

        elseif type(item_position) == "function" then
            window:setframe(monitors[monitor].dimensions:relative_to(item_position(monitors[monitor].dimensions, {
                monitor = monitors[monitor],
                window = window,
                position = position
            })))

        elseif type(item_position) == "table" then
            window:setframe(monitors[monitor].dimensions:relative_to(item_position))

        else
            error("position cannot be a " .. type(item_position))
        end
    end)
end

local function handle_arrangement(arrangement)
    arrange(arrangement.arrangement)

    if arrangement.alert == true then
        alert.show("Arranged monitors with: " .. (arrangement.name or "unnamed arrangement"), 1.0)
    end
end

local function init_module()
    if config.arrangements == nil then
        notify.show("Arrangements has no available configs", "", "Set some configs set in config.arrangements or unload this module", "")
        return
    end

    for _, arrangement in ipairs(config.arrangements) do
        if arrangement.key == nil and arrangement.menu ~= true then
            error("Arrangement is missing a key value, and isn't bound to the menu.")
        end

        if arrangement.key ~= nil then
            hotkey.bind(arrangement.mash or { "cmd", "ctrl", "alt" }, arrangement.key, fnutils.partial(handle_arrangement, arrangement))
        end
    end

    if config:get('arrangements.fuzzy_search', false) then
        local mash = config:get('arrangements.fuzzy_search.mash', {"ctrl", "alt", "cmd"})
        local key = config:get('arrangements.fuzzy_search.key', "F")

        local match_dialogue = import('utils/match_dialogue')

        local matcher = match_dialogue(function()
            local list = fnutils.filter(config.arrangements, function(arrangement) return arrangement.name ~= nil end)
            return fnutils.map(list, function(arrangement)
                return {
                    string = arrangement.name,
                    arrangement = arrangement
                }
            end)
        end, function(match)
            handle_arrangement(match.arrangement)
        end)

        hotkey.bind(mash, key, fnutils.partial(matcher.show, matcher))

    end


end

local function init_menu()
    if config.arrangements == nil then
        return
    end

    local menu = {}

    for _, arrangement in ipairs(config.arrangements) do
        if arrangement.menu == true then
            table.insert(menu, {
                title = "Arrange: " .. arrangement.name,
                fn = function()
                    handle_arrangement(arrangement)
                end
            })
        end
    end

    if #menu > 0 then
        return fnutils.concat(menu, { { title = "-" } })
    else
        return menu
    end
end

return {
    init = init_module,
    menu = init_menu
}
