local notify = require 'mjolnir._asm.notify'
local hydra = require 'mjolnir._asm.hydra'
local timer = require 'mjolnir._asm.timer'

-- show available updates
local function showupdate()
    os.execute('open https://github.com/sdegutis/mjolnir/releases')
end

-- what to do when an update is checked
local function updates_available(available)
    if available then
        notify.show("Mjolnir update available", "", "Click here to see the changelog and maybe even install it", "showupdate")
        hydra.updates.newversion = available
    else
        hydra.alert("No update available.")
    end
end

-- save the time when updates are checked
local function checkforupdates()
    hydra.updates.check(updates_available)
    hydra.settings.set('lastcheckedupdates', os.time())
end

local function module_init()

    -- check for updates every week
    timer.new(timer.days(1), checkforupdates):start()
    notify.register("showupdate", showupdate)

    -- if this is your first time running Mjolnir, you're launching it more than a week later, check now
    local lastcheckedupdates = hydra.settings.get('lastcheckedupdates')
    if lastcheckedupdates == nil or lastcheckedupdates <= os.time() - timer.days(7) then
        checkforupdates()
    end

end

local function module_menu()
    local updatetitles = { [true] = "Install Update", [false] = "Check for Update..." }
    local updatefns = { [true] = hydra.updates.install, [false] = checkforupdates }
    local hasupdate = (hydra.updates.newversion ~= nil)

    return {
        { title = updatetitles[hasupdate], fn = updatefns[hasupdate] },
    }
end

return {
    init = module_init,
    menu = module_menu
}
