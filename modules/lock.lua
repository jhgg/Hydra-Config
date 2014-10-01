local hotkey = require 'mjolnir.hotkey'
local hydra = require 'mjolnir._asm.hydra'

local function module_init()
    local mash = config:get("lock.mash", {})
    local key = config:get("lock.key", "F13")

    hotkey.bind(mash, key, function()
        hydra.exec("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend")
    end)

end

return {
    init = module_init
}
