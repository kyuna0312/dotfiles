-- Pacing calculator for a simulator / tycoon / idle economy (Lune 0.11.0).
-- Read-only: it reads one optional JSON file and prints to stdout.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local EconomyMath = require("./economy_math")

local USAGE = [[
Usage: lune run scripts/balance.luau [CONFIG.json]
       lune run scripts/balance.luau --print-defaults
       lune run scripts/balance.luau --help

Prints, for one player who spends everything on a single upgrade:
  - price, total spent, income and wait for each upgrade level;
  - requirement, multiplier, wait and growth ratio ("vs prev") for each rebirth;
  - the most one offline session can pay.

With no CONFIG it uses built-in example numbers. --print-defaults writes those
numbers as JSON, ready to copy into your own CONFIG file.

CONFIG fields (all numbers):
  baseIncome                                  income per second before upgrades
  upgrade.baseCost        (>= 1)              price of the first level
  upgrade.costGrowth      (>= 1)              price multiplier per level owned
  upgrade.incomePerLevel  (>= 0)              income per second added by each level
  upgrade.levels          (whole, 1..1000)    levels to simulate
  rebirth.baseRequirement (> 0)               currency needed for the first rebirth
  rebirth.requirementGrowth (>= 1)            requirement multiplier per rebirth
  rebirth.multiplierPerRebirth (>= 0)         additive income multiplier per rebirth
  rebirth.count           (whole, 1..100)     rebirths to simulate
  offline.maxHours        (>= 0)              offline earning cap in hours
  offline.efficiency      (0..1)              share of online income paid offline

Exit status: 0 on success, 1 on a missing file, invalid JSON or invalid config.]]

local DEFAULT = {
	baseIncome = 1,
	upgrade = { baseCost = 10, costGrowth = 1.15, incomePerLevel = 1, levels = 40 },
	rebirth = { baseRequirement = 1e6, requirementGrowth = 3, multiplierPerRebirth = 0.5, count = 8 },
	offline = { maxHours = 8, efficiency = 0.5 },
}

local function fail(message: string): never
	stdio.ewrite("balance.luau: " .. message .. "\n")
	stdio.ewrite("Run with --help for usage.\n")
	return process.exit(1)
end

-- Each rule: section (nil = top level), field, minimum, maximum, whole number?
local RULES: { { any } } = {
	{ nil, "baseIncome", 0, math.huge, false },
	{ "upgrade", "baseCost", 1, math.huge, false },
	{ "upgrade", "costGrowth", 1, math.huge, false },
	{ "upgrade", "incomePerLevel", 0, math.huge, false },
	{ "upgrade", "levels", 1, 1000, true },
	{ "rebirth", "baseRequirement", 1e-9, math.huge, false },
	{ "rebirth", "requirementGrowth", 1, math.huge, false },
	{ "rebirth", "multiplierPerRebirth", 0, math.huge, false },
	{ "rebirth", "count", 1, 100, true },
	{ "offline", "maxHours", 0, math.huge, false },
	{ "offline", "efficiency", 0, 1, false },
}

local function validate(config: any)
	if type(config) ~= "table" or #config > 0 then
		fail("config must be a JSON object")
	end
	for _, rule in RULES do
		local section, field, low, high, whole = rule[1], rule[2], rule[3], rule[4], rule[5]
		local container = config
		local path = field
		if section then
			container = config[section]
			path = section .. "." .. field
			if type(container) ~= "table" then
				fail(`missing object "{section}"`)
			end
		end
		local value = container[field]
		if type(value) ~= "number" or value ~= value or value == math.huge then
			fail(`"{path}" must be a finite number`)
		end
		if value < low or value > high then
			fail(`"{path}" is {value}; allowed range is {low} to {high}`)
		end
		if whole and value % 1 ~= 0 then
			fail(`"{path}" must be a whole number`)
		end
	end
end

local args = process.args
if #args > 1 then
	fail("expected at most one argument")
end

local config: any = DEFAULT
local first = args[1]
if first == "--help" or first == "-h" then
	print(USAGE)
	process.exit(0)
elseif first == "--print-defaults" then
	print(serde.encode("json", DEFAULT, true))
	process.exit(0)
elseif first and string.sub(first, 1, 1) == "-" then
	fail(`unknown option "{first}"`)
elseif first then
	if not fs.isFile(first) then
		fail(`config file not found (or not a regular file): {first}`)
	end
	local readOk, text = pcall(fs.readFile, first)
	if not readOk then
		fail(`cannot read {first}: {string.match(tostring(text), "^[^\n]*")}`)
	end
	local decodeOk, decoded = pcall(serde.decode, "json", text)
	if not decodeOk then
		-- Keep only the first line: the decoder's message carries a stack trace.
		local reason = string.match(tostring(decoded), "^[^\n]*")
		fail(`{first} is not valid JSON: {reason}`)
	end
	config = decoded
end
validate(config)

local function clock(seconds: number): string
	if seconds == math.huge then
		return "never"
	elseif seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		return string.format("%dm %02ds", seconds // 60, seconds % 60)
	elseif seconds < 86400 then
		return string.format("%dh %02dm", seconds // 3600, (seconds % 3600) // 60)
	end
	return string.format("%dd %dh", seconds // 86400, (seconds % 86400) // 3600)
end

local show = EconomyMath.formatNumber

local up = config.upgrade
print("Upgrade pacing (no rebirths, buying one level at a time)")
print(string.format("%5s %14s %14s %12s %12s", "level", "price", "total spent", "income/s", "wait"))
local totalTime = 0
for level = 0, up.levels - 1 do
	local income = config.baseIncome + level * up.incomePerLevel
	local price = EconomyMath.levelCost(up.baseCost, up.costGrowth, level)
	local wait = EconomyMath.secondsToEarn(price, income)
	totalTime += wait
	if level < 10 or level % 5 == 4 or level == up.levels - 1 then
		print(
			string.format(
				"%5d %14s %14s %12s %12s",
				level + 1,
				show(price),
				show(EconomyMath.cumulativeCostExact(up.baseCost, up.costGrowth, 0, level + 1)),
				show(income),
				clock(wait)
			)
		)
	end
end
print(string.format("Time to level %d: %s", up.levels, clock(totalTime)))

local rb = config.rebirth
local income = config.baseIncome + up.levels * up.incomePerLevel
print(string.format("\nRebirth pacing (income %s/s before multipliers)", show(income)))
print(string.format("%7s %16s %11s %12s %8s", "rebirth", "requirement", "multiplier", "wait", "vs prev"))
local previous: number? = nil
for done = 0, rb.count - 1 do
	local requirement = EconomyMath.rebirthRequirement(rb.baseRequirement, rb.requirementGrowth, done)
	local multiplier = EconomyMath.rebirthMultiplier(rb.multiplierPerRebirth, done)
	local wait = EconomyMath.secondsToEarn(requirement, income * multiplier)
	local ratio = "-"
	if previous and previous > 0 and previous ~= math.huge then
		ratio = string.format("x%.2f", wait / previous)
	end
	print(
		string.format(
			"%7d %16s %11s %12s %8s",
			done + 1,
			show(requirement),
			string.format("x%.1f", multiplier),
			clock(wait),
			ratio
		)
	)
	previous = wait
end

local off = config.offline
print(
	string.format(
		"\nOffline: %g h cap at %d%% efficiency pays up to %s at %s/s",
		off.maxHours,
		off.efficiency * 100,
		show(EconomyMath.offlineIncome(off.maxHours * 3600, income, off.maxHours, off.efficiency)),
		show(income)
	)
)
