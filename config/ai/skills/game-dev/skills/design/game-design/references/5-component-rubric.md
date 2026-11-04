# The 5-Component Filter: Full Rubric

For significant features, evaluate each component across four dimensions.

## Clarity (Telegraphing)

| Dimension | Specification |
|-----------|---------------|
| **Signals** | Visual tells, audio cues, UI states, animation windups, camera behavior |
| **Rules** | When telegraph triggers, what overrides it, minimum duration before resolution |
| **Knobs** | Indicator duration, readability distance, contrast, cue timing |
| **Acceptance Test** | Can a new player predict outcomes 8/10 times within 2 minutes of encountering the mechanic? |

## Motivation (Stakes)

| Dimension | Specification |
|-----------|---------------|
| **Signals** | Reward indicators, risk cues, threat escalation, scarcity markers |
| **Rules** | What is gained/lost, consequences for success/failure, persistence |
| **Knobs** | Reward magnitude, failure cost, frequency, opportunity cost |
| **Acceptance Test** | Do players voluntarily engage without being forced? Do they retry after failure? |

## Response (Agency)

| Dimension | Specification |
|-----------|---------------|
| **Signals** | Immediate input acknowledgment, control state indicators, counter-play windows |
| **Rules** | Input windows, cancel rules, buffer windows, lockout conditions |
| **Knobs** | Timing windows, lockout durations, cooldowns, movement curves |
| **Acceptance Test** | If a player changes their mind mid-action, do they have meaningful options? |

## Satisfaction (Feedback)

| Dimension | Specification |
|-----------|---------------|
| **Signals** | Impact effects, audio layers, screen response, particles, UI pulses |
| **Rules** | What triggers feedback, scaling with outcome magnitude, layering rules |
| **Knobs** | Intensity, duration, frequency (avoid noise spam) |
| **Acceptance Test** | Can players feel the difference between weak/strong outcomes without reading numbers? |

## Fit (Fantasy/Identity)

| Dimension | Specification |
|-----------|---------------|
| **Signals** | Animation weight, timing curves, audio texture, VFX language |
| **Rules** | What the fantasy allows/disallows, consistency constraints |
| **Knobs** | Timing, exaggeration level, responsiveness vs. weight balance |
| **Acceptance Test** | Does this action look/feel like it belongs in this world and on this character? |

---

## Priority Resolution

When components conflict, resolve in this order:

1. **Response** - Player must feel in control
2. **Clarity** - Player must understand what happened
3. **Satisfaction** - Player must feel the impact
4. **Fit** - Experience must match fantasy
5. **Motivation** - Stakes can be adjusted last

Example: If making an attack feel "weighty" (Fit) would make it feel "laggy" (Response), prioritize Response. Find weight through feedback channels instead.
