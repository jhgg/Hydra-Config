local fnutils = require 'mjolnir.fnutils'
local window = require 'mjolnir.window'
local mouse = require 'mjolnir.jstevenson.cursor'

local find = {
    window = {},
    windows = {},
    audio_device = {}
}

local geom = import('utils/geometry')

function find.window.by_title(title)
    return fnutils.find(window.allwindows(), function(window)
        return string.match(window:title(), title) ~= nil
    end)
end

function find.window.underneath_mouse()
    local pos = mouse.get()
    return fnutils.find(window.orderedwindows(), function(window)
        return geom.point_in_rect(window:frame(), pos)
    end)
end

function find.window.by_application_title(title)
    return fnutils.find(window.allwindows(), function(window)
        return string.match(window:application():title(), title) ~= nil
    end)
end

function find.windows.by_title(title)
    return fnutils.filter(window.allwindows(), function(window)
        return string.match(window:title(), title) ~= nil
    end)
end

function find.windows.by_application_title(title)
    return fnutils.filter(window.allwindows(), function(window)
        return string.match(window:application():title(), title) ~= nil
    end)
end

function find.windows.underneath_mouse()
    local pos = mouse.get()
    return fnutils.filter(window.orderedwindows(), function(window)
        return geom.point_in_rect(window:frame(), pos)
    end)
end

function find.audio_device.by_name(name)
    return fnutils.find(audio.alloutputdevices(), function(device)
        return string.match(audio:name(), name) ~= nil
    end)
end

return find

