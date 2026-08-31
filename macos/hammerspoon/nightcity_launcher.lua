-- NIGHT CITY app launcher — CyberArch-Dotfiles style (Night City Mix)
-- Dark chooser, soft grey-blue text like the terminal/tmux Night City palette.
local M = {}

local APP_DIRS = {
	"/Applications",
	"/System/Applications",
	"/System/Applications/Utilities",
	os.getenv("HOME") .. "/Applications",
}

local choices = {}

local function buildChoices()
	choices = {}
	for _, dir in ipairs(APP_DIRS) do
		local ok, iter, dobj = pcall(hs.fs.dir, dir)
		if ok and iter then
			for file in iter, dobj do
				if file:sub(-4) == ".app" then
					local path = dir .. "/" .. file
					choices[#choices + 1] = {
						text = "⌁ " .. file:sub(1, -5),
						subText = path,
						path = path,
						image = hs.image.iconForFile(path),
					}
				end
			end
		end
	end
	table.sort(choices, function(a, b) return a.text:lower() < b.text:lower() end)
end

local chooser = hs.chooser.new(function(choice)
	if choice then hs.application.open(choice.path) end
end)
chooser:bgDark(true)
chooser:fgColor({ hex = "#b6c5d3" })
chooser:subTextColor({ hex = "#5b7189" })
chooser:placeholderText("▸ BREACH PROTOCOL // launch")
chooser:rows(9)
chooser:width(24)
chooser:searchSubText(false)

function M.toggle()
	if chooser:isVisible() then
		chooser:hide()
	else
		chooser:query("")
		chooser:choices(choices)
		chooser:show()
	end
end

buildChoices()
-- ponytail: app list built once at load; alt+R (hs.reload) refreshes it
return M
