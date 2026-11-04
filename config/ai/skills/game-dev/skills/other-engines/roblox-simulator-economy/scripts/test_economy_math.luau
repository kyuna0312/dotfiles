-- Tests for economy_math.luau (Lune 0.11.0).
-- From the skill folder: lune run scripts/test_economy_math.luau
-- Exits 0 when every test passes, 1 otherwise.

local process = require("@lune/process")

local EconomyMath = require("./economy_math")

if process.args[1] == "--help" or process.args[1] == "-h" then
	print("Usage: lune run scripts/test_economy_math.luau\nRuns the economy_math tests; exit 1 on any failure.")
	process.exit(0)
end

local passed, failed = 0, 0

local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print(`FAIL  {name}\n      {err}`)
	end
end

local function eq(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(`{label or "value"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

local function near(actual: number, expected: number, tolerance: number, label: string)
	if math.abs(actual - expected) > tolerance then
		error(`{label}: expected ~{expected}, got {actual}`, 2)
	end
end

test("levelCost floors base * growth ^ level", function()
	eq(EconomyMath.levelCost(10, 1.15, 0), 10, "level 0")
	eq(EconomyMath.levelCost(10, 1.15, 1), 11, "level 1 (11.5 floored)")
	eq(EconomyMath.levelCost(100, 2, 10), 102400, "doubling")
end)

test("cumulativeCost matches the summed series", function()
	local loop = 0
	for level = 3, 19 do
		loop += 50 * 1.2 ^ level
	end
	near(EconomyMath.cumulativeCost(50, 1.2, 3, 20), loop, 1e-6, "geometric sum")
	eq(EconomyMath.cumulativeCost(50, 1, 3, 20), 50 * 17, "flat growth")
	eq(EconomyMath.cumulativeCost(50, 1.2, 5, 5), 0, "empty range")
end)

test("cumulativeCostExact sums floored prices and stays under the smooth sum", function()
	local exact = EconomyMath.cumulativeCostExact(10, 1.15, 0, 30)
	local smooth = EconomyMath.cumulativeCost(10, 1.15, 0, 30)
	assert(exact <= smooth, "floored sum is at most the smooth sum")
	assert(smooth - exact < 30, "and loses less than 1 per level")
end)

test("maxAffordable buys exactly as many levels as the money covers", function()
	local owned, money = 4, 1000
	local count, spent = EconomyMath.maxAffordable(10, 1.15, owned, money, 100)
	eq(spent, EconomyMath.cumulativeCostExact(10, 1.15, owned, owned + count), "reported total")
	assert(spent <= money, "affordable")
	assert(spent + EconomyMath.levelCost(10, 1.15, owned + count) > money, "one more is not")
	eq((EconomyMath.maxAffordable(10, 1.15, 0, 9, 100)), 0, "can't afford the first level")
end)

test("maxAffordable stops at maxLevel and rejects inputs that would never end", function()
	eq((EconomyMath.maxAffordable(10, 1, 0, 1e12, 25)), 25, "capped at maxLevel")
	eq((EconomyMath.maxAffordable(10, 1, 30, 1e12, 25)), 0, "already past the cap")
	assert(not pcall(EconomyMath.maxAffordable, 0.5, 1.15, 0, 100, 10), "price 0 errors")
	assert(not pcall(EconomyMath.maxAffordable, 10, 1.15, 0, math.huge, 10), "infinite money errors")
	assert(not pcall(EconomyMath.maxAffordable, 10, 1.15, 0, 0 / 0, 10), "NaN money errors")
end)

test("rebirth requirement and multiplier", function()
	eq(EconomyMath.rebirthRequirement(1e6, 3, 0), 1e6, "first")
	eq(EconomyMath.rebirthRequirement(1e6, 3, 2), 9e6, "third")
	eq(EconomyMath.rebirthMultiplier(0.5, 0), 1, "no rebirths")
	eq(EconomyMath.rebirthMultiplier(0.5, 3), 2.5, "three rebirths")
end)

test("rebirth wait ratio matches r * (1 + k*p) / (1 + (k+1)*p)", function()
	local r, p, income = 3, 0.5, 41
	for k = 0, 6 do
		local now = EconomyMath.secondsToEarn(
			EconomyMath.rebirthRequirement(1e6, r, k),
			income * EconomyMath.rebirthMultiplier(p, k)
		)
		local nextWait = EconomyMath.secondsToEarn(
			EconomyMath.rebirthRequirement(1e6, r, k + 1),
			income * EconomyMath.rebirthMultiplier(p, k + 1)
		)
		near(nextWait / now, r * (1 + k * p) / (1 + (k + 1) * p), 1e-9, `ratio at k={k}`)
	end
end)

test("secondsToEarn handles zero and NaN income", function()
	eq(EconomyMath.secondsToEarn(100, 4), 25, "simple")
	eq(EconomyMath.secondsToEarn(100, 0), math.huge, "no income")
	eq(EconomyMath.secondsToEarn(100, 0 / 0), math.huge, "NaN income")
end)

test("offlineIncome caps, scales and ignores backwards or NaN clocks", function()
	eq(EconomyMath.offlineIncome(3600, 10, 8, 0.5), 18000, "one hour at half rate")
	eq(EconomyMath.offlineIncome(48 * 3600, 10, 8, 1), 8 * 3600 * 10, "capped at 8 hours")
	eq(EconomyMath.offlineIncome(-500, 10, 8, 1), 0, "clock went backwards")
	eq(EconomyMath.offlineIncome(0 / 0, 10, 8, 1), 0, "NaN time away")
end)

test("trySpend is all-or-nothing", function()
	local wallet = { Coins = 100, Gems = 5 }
	eq(EconomyMath.trySpend(wallet, { Coins = 60, Gems = 10 }), false, "gems short")
	eq(wallet.Coins, 100, "coins untouched after failed spend")
	eq(EconomyMath.trySpend(wallet, { Coins = 60, Gems = 5 }), true, "affordable")
	eq(wallet.Coins, 40, "coins spent")
	eq(wallet.Gems, 0, "gems spent")
	eq(EconomyMath.trySpend(wallet, { Coins = -10 }), false, "negative cost rejected")
	eq(EconomyMath.trySpend(wallet, { Coins = 0 / 0 }), false, "NaN cost rejected")
	eq(EconomyMath.trySpend(wallet, { Tickets = 1 }), false, "missing currency counts as 0")
	eq(wallet.Coins, 40, "coins untouched after rejected spends")
end)

test("sanitizeAmount and sanitizeLevel repair tampered or old save values", function()
	eq(EconomyMath.sanitizeAmount(250.9), 250, "fraction floored")
	eq(EconomyMath.sanitizeAmount(-5), 0, "negative")
	eq(EconomyMath.sanitizeAmount(0 / 0), 0, "NaN")
	eq(EconomyMath.sanitizeAmount(math.huge), 0, "inf")
	eq(EconomyMath.sanitizeAmount("999"), 0, "string")
	eq(EconomyMath.sanitizeAmount(nil), 0, "missing")
	eq(EconomyMath.sanitizeLevel(80, 50), 50, "clamped to max level")
	eq(EconomyMath.sanitizeLevel(12, 50), 12, "valid level kept")
end)

test("formatNumber rounds before picking a suffix", function()
	eq(EconomyMath.formatNumber(0), "0", "zero")
	eq(EconomyMath.formatNumber(999), "999", "below 1000")
	eq(EconomyMath.formatNumber(1500), "1.5K", "thousands")
	eq(EconomyMath.formatNumber(999950), "1.0M", "rollover: not 1000.0K")
	eq(EconomyMath.formatNumber(999949), "999.9K", "just below rollover")
	eq(EconomyMath.formatNumber(3.4e6), "3.4M", "millions")
	eq(EconomyMath.formatNumber(2e15), "2.0Qa", "quadrillions")
	eq(EconomyMath.formatNumber(-1500), "-1.5K", "negative")
	eq(EconomyMath.formatNumber(1234567, 2), "1.23M", "two decimals")
	eq(EconomyMath.formatNumber(1e63), "1.0Vg", "last suffix")
	eq(EconomyMath.formatNumber(1e66), "1.00e+66", "past the last suffix")
	eq(EconomyMath.formatNumber(0 / 0), "nan", "NaN")
	eq(EconomyMath.formatNumber(math.huge), "inf", "inf")
end)

test("oddsPercent and pickWeighted read the same weights", function()
	local outcomes = {
		{ id = "Common", weight = 70 },
		{ id = "Rare", weight = 25 },
		{ id = "Legendary", weight = 5 },
	}
	local odds = EconomyMath.oddsPercent(outcomes)
	eq(odds.Common, 70, "common percent")
	eq(odds.Legendary, 5, "legendary percent")
	near(odds.Common + odds.Rare + odds.Legendary, 100, 1e-9, "sum")
	local thirds = EconomyMath.oddsPercent({ { id = "A", weight = 1 }, { id = "B", weight = 1 }, { id = "C", weight = 1 } })
	near(thirds.A + thirds.B + thirds.C, 100, 1e-9, "sum of thirds")
	eq(EconomyMath.pickWeighted(outcomes, 0), "Common", "lowest roll")
	eq(EconomyMath.pickWeighted(outcomes, 0.6999), "Common", "just under the first boundary")
	eq(EconomyMath.pickWeighted(outcomes, 0.7), "Rare", "first boundary")
	eq(EconomyMath.pickWeighted(outcomes, 0.95), "Legendary", "second boundary")
	eq(EconomyMath.pickWeighted(outcomes, 0.999999), "Legendary", "highest roll")
	eq(EconomyMath.pickWeighted(outcomes, 1), "Legendary", "inclusive upper bound")
	assert(not pcall(EconomyMath.oddsPercent, {}), "empty list errors")
	assert(not pcall(EconomyMath.oddsPercent, { { id = "Bad", weight = 0 } }), "zero weight errors")
	assert(not pcall(EconomyMath.pickWeighted, { { id = "Bad", weight = 0 / 0 } }, 0.5), "NaN weight errors")
end)

print(`\n{passed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
