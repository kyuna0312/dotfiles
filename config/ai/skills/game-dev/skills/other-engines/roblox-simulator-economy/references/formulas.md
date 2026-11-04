# Economy formulas and a worked example

Read this when you need the derivation behind a number in `SKILL.md`, want to solve for a
parameter instead of trying values, or need to explain the calculator's output. Every formula here
is implemented in `scripts/economy_math.luau` and checked by `scripts/test_economy_math.luau`.

## Geometric upgrade prices

Owning `n` levels, the next one costs `c(n) = floor(b0 * g^n)`.

Ignoring the floor, going from `a` to `b` levels costs

    S(a, b) = sum over n = a .. b-1 of b0 * g^n = b0 * g^a * (g^(b-a) - 1) / (g - 1)    (g > 1)

and `b0 * (b - a)` when `g = 1`. The floored total that players pay is lower by less than one coin
per level (`cumulativeCost` vs `cumulativeCostExact`).

**Buy max without the floor:** the largest `k` with `S(a, a+k) <= M` is

    k = floor( log(1 + M * (g - 1) / (b0 * g^a)) / log(g) )

With floored prices this can be off by one, so `maxAffordable` walks the real prices instead and
stops at the upgrade's `maxLevel`. The cap matters: with `g = 1` and a very large balance, an
uncapped loop runs once per affordable level.

**How fast prices grow:** the price doubles every `log(2) / log(g)` levels — about every 5 levels
at `g = 1.15`, every 10 at `g = 1.07`, every 2 at `g = 1.5`. Level 50 at `g = 1.5` costs
`1.5^50`, about 637 million times level 0.

## Rebirth pacing

With requirement `R_k = R0 * r^k`, an additive multiplier `m_k = 1 + k*p`, and a fixed income `I`
after the upgrades are rebought (everything else resets), the wait for rebirth `k+1` is
`T_k = R_k / (I * m_k)`. The ratio between consecutive waits is

    T_{k+1} / T_k = r * (1 + k*p) / (1 + (k+1)*p)

It starts at `r / (1 + p)` and climbs towards `r`. Two consequences:

- With an additive multiplier, `r` alone sets the long-run ratio. To keep later rebirths about
  x1.6 longer than the previous one, `r` must be near 1.6, whatever `p` is.
- A multiplicative multiplier `m_k = q^k` gives a constant ratio `r / q`. It is easy to tune but
  the multiplier itself grows exponentially, so every other income source must be designed for it.

The test `rebirth wait ratio matches ...` checks this formula against the functions.

## Worked example (the calculator's defaults)

`baseIncome 1; upgrade baseCost 10, costGrowth 1.15, +1 income/s per level, 40 levels;`
`rebirth baseRequirement 1e6, requirementGrowth 3, +0.5 multiplier per rebirth`

Output of `lune run scripts/balance.luau` (Lune 0.11.0):

- Reaching level 40 takes 9m 49s; the last levels take about a minute each.
- Rebirth 1 at 41 income/s takes 6h 46m; rebirth 8 takes 137 days. The `vs prev` column reads
  x2.00, x2.25, x2.40 ... x2.67 — the formula above with `r = 3`, `p = 0.5`.
- With `requirementGrowth` 1.8 (same `p`), the column reads x1.20 rising to x1.60 and rebirth 8
  takes 3d 20h.
- Keeping `r = 3` with a multiplicative multiplier `q = 2.4` gives a constant `3 / 2.4 = x1.25`.

## Offline earnings

    paid = floor( min(away, maxHours * 3600) * rate * efficiency )      away <= 0 or NaN -> 0

`away` is the server's `os.time()` now minus the server's `os.time()` saved when the player left.
Clamp before multiplying, so a corrupted or very old timestamp cannot produce an enormous payout.
Efficiency below 1 and a cap keep active play worth more than idling.

## Odds for weighted random outcomes

For outcomes with positive weights `w_i` and total `W`, the probability of outcome `i` is
`w_i / W`, so the percentages `100 * w_i / W` sum to 100 (up to floating-point rounding).
`oddsPercent` returns those percentages and `pickWeighted(outcomes, u)` maps a uniform `u` in
`[0, 1]` to an outcome by walking the cumulative weights in list order (`u = 1`, which Roblox's
`Random:NextNumber()` can return, maps to the last outcome). Because both read the same
list, the displayed odds and the server's roll cannot drift apart. Apply luck boosts or pity by
producing a new weight list, then feed that one list to both functions.

## Number precision

Luau numbers are IEEE-754 doubles. Every integer up to `2^53` (about `9.007e15`) is exact; above
it, adding a small income to a large balance can round away entirely. If balances can exceed
roughly `1e15`, store them as a mantissa/exponent pair (or a base-10 logarithm) and compare in that
form, rather than as plain numbers.
