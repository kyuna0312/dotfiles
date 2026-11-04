--!strict
-- Pure Luau maths for simulator, tycoon, clicker and idle economies.
-- No engine services: it runs under Lune 0.11.0 (balance.luau and
-- test_economy_math.luau use it) and inside a Roblox ModuleScript unchanged.

local EconomyMath = {}

-- Display suffixes, one per factor of 1000. Index 1 is 1e3 (K); index 21 is 1e63 (Vg).
EconomyMath.SUFFIXES = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg",
}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- Price of the next level when `level` levels are owned: floor(base * growth ^ level).
function EconomyMath.levelCost(base: number, growth: number, level: number): number
	return math.floor(base * growth ^ level)
end

-- Total cost of going from `from` to `to` levels (geometric series, before flooring
-- each step). Use cumulativeCostExact when the floored sum matters.
function EconomyMath.cumulativeCost(base: number, growth: number, from: number, to: number): number
	if to <= from then
		return 0
	end
	if growth == 1 then
		return base * (to - from)
	end
	return base * growth ^ from * (growth ^ (to - from) - 1) / (growth - 1)
end

-- Sum of the floored per-level prices from `from` to `to`: what players actually pay.
function EconomyMath.cumulativeCostExact(base: number, growth: number, from: number, to: number): number
	local total = 0
	for level = from, to - 1 do
		total += EconomyMath.levelCost(base, growth, level)
	end
	return total
end

-- "Buy max": how many levels `money` buys starting from `owned`, never going past
-- `maxLevel`. Returns the count and the total price. Errors on a price below 1 or a
-- non-finite amount, either of which would otherwise loop forever.
function EconomyMath.maxAffordable(
	base: number,
	growth: number,
	owned: number,
	money: number,
	maxLevel: number
): (number, number)
	if not isFinite(money) or not isFinite(maxLevel) then
		error("maxAffordable: money and maxLevel must be finite numbers", 2)
	end
	local count, spent = 0, 0
	while owned + count < maxLevel do
		local price = EconomyMath.levelCost(base, growth, owned + count)
		if price < 1 then
			error("maxAffordable: every price must be at least 1 (raise baseCost)", 2)
		end
		if spent + price > money then
			break
		end
		spent += price
		count += 1
	end
	return count, spent
end

-- Requirement for the next rebirth after `done` rebirths: floor(base * growth ^ done).
function EconomyMath.rebirthRequirement(base: number, growth: number, done: number): number
	return math.floor(base * growth ^ done)
end

-- Additive income multiplier after `done` rebirths: 1 + done * perRebirth.
function EconomyMath.rebirthMultiplier(perRebirth: number, done: number): number
	return 1 + done * perRebirth
end

-- Seconds needed to earn `amount` at `perSecond`; math.huge when there is no income.
function EconomyMath.secondsToEarn(amount: number, perSecond: number): number
	if not (perSecond > 0) then
		return math.huge
	end
	return amount / perSecond
end

-- Offline income: seconds away (server clock), capped at maxHours, scaled by
-- efficiency, floored. Zero, negative or NaN time away pays nothing.
function EconomyMath.offlineIncome(secondsAway: number, perSecond: number, maxHours: number, efficiency: number): number
	if not (secondsAway > 0) then
		return 0
	end
	local counted = math.min(secondsAway, maxHours * 3600)
	return math.floor(counted * perSecond * efficiency)
end

-- Spends several currencies at once, or none. `wallet` is changed only when every
-- cost is a finite, non-negative number the wallet covers.
function EconomyMath.trySpend(wallet: { [string]: number }, costs: { [string]: number }): boolean
	for currency, cost in costs do
		if type(cost) ~= "number" or not isFinite(cost) or cost < 0 then
			return false
		end
		if (wallet[currency] or 0) < cost then
			return false
		end
	end
	for currency, cost in costs do
		wallet[currency] = (wallet[currency] or 0) - cost
	end
	return true
end

-- Repairs one stored currency amount: anything that is not a finite, non-negative
-- number becomes 0, and fractions are floored. Never errors.
function EconomyMath.sanitizeAmount(value: unknown): number
	if type(value) ~= "number" or not isFinite(value) or value < 0 then
		return 0
	end
	return math.floor(value)
end

-- Repairs one stored upgrade level: a whole number from 0 to maxLevel.
function EconomyMath.sanitizeLevel(value: unknown, maxLevel: number): number
	return math.min(EconomyMath.sanitizeAmount(value), maxLevel)
end

export type WeightedOutcome = { id: string, weight: number }

local function totalWeight(outcomes: { WeightedOutcome }): number
	if #outcomes == 0 then
		error("weighted outcomes: the list is empty", 3)
	end
	local total = 0
	for _, outcome in outcomes do
		if type(outcome.weight) ~= "number" or not isFinite(outcome.weight) or outcome.weight <= 0 then
			error(`weighted outcomes: "{outcome.id}" needs a finite weight above 0`, 3)
		end
		total += outcome.weight
	end
	return total
end

-- Percent chance of every outcome, keyed by id. Use the same list the server rolls
-- with (after applying any luck boost or pity) so the shown odds cannot drift.
function EconomyMath.oddsPercent(outcomes: { WeightedOutcome }): { [string]: number }
	local total = totalWeight(outcomes)
	local percents: { [string]: number } = {}
	for _, outcome in outcomes do
		percents[outcome.id] = outcome.weight / total * 100
	end
	return percents
end

-- Picks an outcome id from `unit`, a uniform random number in [0, 1], walking the
-- weights in list order. Roblox's Random:NextNumber() is documented as inclusive of 1;
-- a unit of 1 (or more) returns the last outcome.
function EconomyMath.pickWeighted(outcomes: { WeightedOutcome }, unit: number): string
	local target = unit * totalWeight(outcomes)
	local running = 0
	for _, outcome in outcomes do
		running += outcome.weight
		if target < running then
			return outcome.id
		end
	end
	return outcomes[#outcomes].id
end

-- Formats a number for display: 999 -> "999", 1500 -> "1.5K", 999950 -> "1.0M"
-- (rounds before choosing the suffix, so it never prints "1000.0K"). Values past the
-- last suffix use scientific notation. Display only; never parse the result back.
function EconomyMath.formatNumber(value: number, decimals: number?): string
	local places = decimals or 1
	if value ~= value then
		return "nan"
	elseif value == math.huge then
		return "inf"
	elseif value == -math.huge then
		return "-inf"
	end
	local sign = if value < 0 then "-" else ""
	local scaled = math.abs(value)
	if scaled < 1000 then
		return sign .. string.format("%d", math.floor(scaled))
	end
	local tier = 0
	while scaled >= 1000 and tier < #EconomyMath.SUFFIXES do
		scaled /= 1000
		tier += 1
	end
	if scaled >= 1000 then
		return sign .. string.format("%.2e", math.abs(value))
	end
	local factor = 10 ^ places
	local rounded = math.floor(scaled * factor + 0.5) / factor
	if rounded >= 1000 then
		if tier == #EconomyMath.SUFFIXES then
			return sign .. string.format("%.2e", math.abs(value))
		end
		rounded /= 1000
		tier += 1
	end
	return sign .. string.format("%." .. places .. "f", rounded) .. EconomyMath.SUFFIXES[tier]
end

return EconomyMath
