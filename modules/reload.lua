local hotkey = require 'mjolnir.hotkey'

return {
    init = function()
        hotkey.bind(config:get("reload.mash", { "cmd", "ctrl", "alt" }), config:get("reload.key", "E"), mjolnir.reload)
    end
}
