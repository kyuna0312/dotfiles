hs.loadSpoon("AClock")

hs.hotkey.bind({"cmd", "alt"}, "C", function()
  spoon.AClock:toggleShow()
end)

-- ARASAKA app launcher (fuzzy chooser over all apps) — alt+space
local launcher = require("arasaka_launcher")
hs.hotkey.bind({"alt"}, "space", launcher.toggle)

-- Reload this config
hs.hotkey.bind({"alt"}, "R", function()
	hs.reload()
end)

-- Avoid extra UI spam on every restart (set HAMMERSPOON_DEBUG=1 to enable)
if os.getenv("HAMMERSPOON_DEBUG") == "1" then
	hs.alert.show("Config loaded")
end

local calendar = hs.loadSpoon("GoMaCal")
if calendar then
    local home = os.getenv("HOME") or ""
    local calpath = os.getenv("DOTFILES_CALENDAR_PATH") or (home .. "/.hammerspoon/calendar-app/calapp")
    calendar:setCalendarPath(calpath)
    calendar:start()
end
