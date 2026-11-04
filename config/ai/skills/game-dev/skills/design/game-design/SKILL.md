---
name: game-design
description: This skill should be used when the user asks to "design a game mechanic", "evaluate gameplay feel", "tune game systems", "review player experience", "debug why something feels wrong", "balance combat", "design progression", or when working on any player-facing game feature. Provides a constraint system for evaluating mechanics with focus on player experience over feature completion.
metadata:
  mcpmarket-version: 1.0.0
---
# Game Design Framework

**Purpose:** Constraint system for evaluating and implementing game mechanics with focus on player experience over feature completion.

**Core principle:** Mechanics are code. Gameplay is the player's *experience* of that code. The goal is not to implement features, but to implement **Relevance**.

---

## Quick Reference: The 5-Component Filter

Before implementing or critiquing ANY game feature, evaluate against:

| Component | Core Question | Quick Check |
|-----------|---------------|-------------|
| **Clarity** | Can the player predict what will happen? | Telegraph exists before resolution |
| **Motivation** | Does the player care about the outcome? | Outcome affects persistent state |
| **Response** | Do player inputs matter? | Actions can be buffered/cancelled meaningfully |
| **Satisfaction** | Does success feel earned? | Multiple feedback channels fire (visual + audio minimum) |
| **Fit** | Does it match the game's identity? | Weight, timing, audio match entity type |

**Conflict priority:** Response > Clarity > Satisfaction > Fit > Motivation

For detailed evaluation rubrics, consult `references/5-component-rubric.md`.

---

## Operating Protocol

### 1. Before Implementation

1. Identify active domain(s) from `references/domain-guide.md`
2. Evaluate against the 5-Component Filter
3. Complete the State Machine Checklist if the feature involves player state changes
4. Check the Numbers Policy before proposing any values

### 2. Numbers Policy (Mandatory)

When proposing ANY numeric value (timing windows, costs, speeds, damage, etc.), choose ONE:

**Option A — Source-backed:**
- Cite a verifiable reference (GDC talk, postmortem, published analysis)
- Example: "Coyote time of 80-150ms (Source: Maddy Thorson's Celeste postmortem)"

**Option B — Starting value with test plan:**
- Label explicitly as "Starting value"
- Include: micro test plan, pass/fail metric, adjustment direction if it fails
- Example: "Starting value: 120ms. Test: Can players make intended jumps 9/10 times? If fail rate >20%, increase by 30ms increments."

**Never** claim "industry standard" or "common practice" without a source.

### 3. Assumption Labeling

When critical information is missing, state explicitly:

```
ASSUMPTION: [what you're assuming]
IMPACT: [why it matters to the design]
IF WRONG: [failure mode]
VALIDATE: [how to check quickly]
```

### 4. Research Triggers

Search before proposing when:
- About to claim "best practice" or "standard approach"
- Balance/economy values need benchmarks
- Accessibility requirements apply
- Comparative references needed from similar games

If search unavailable, convert to "Assumption + Test Plan" format.

---

## State Machine Checklist

For ANY feature that changes player state (movement abilities, combat actions, status effects):

| Property | Must Define |
|----------|-------------|
| **Entry conditions** | What states can transition INTO this? |
| **Exit conditions** | What ends this state? (timer, input, external event) |
| **Interruptibility** | What can cancel this? (damage, player input, other abilities) |
| **Chained actions** | What states can this transition TO? |
| **Resource cost** | What is consumed on entry? On sustain? |
| **Edge cases** | Behavior on: slopes, ceilings, moving platforms, during hitstun, at resource zero |

---

## Debugging Protocol

When told "it feels wrong/boring/clunky," diagnose in order:

| Symptom | Check First | Before Tuning Numbers |
|---------|-------------|----------------------|
| "I didn't know that would happen" | Clarity | Add telegraph, audio cue, UI indicator |
| "I don't care" | Motivation | Connect to progression, increase stakes |
| "It feels laggy" | Response | Add buffering, allow cancels, reduce lockouts |
| "It feels weak" | Satisfaction | Add feedback channels (minimum 2) |
| "It doesn't fit" | Fit | Adjust timing, weight, audio texture |

**Rule:** Do not tune damage/timing numbers until Clarity and Response are verified as not the root cause.

---

## Playtest Requirements

Every significant feature must include scenarios for:

1. **New player test:** Can they infer the rules without being told?
2. **Stress test:** Spam inputs, boundary conditions, edge cases
3. **Skill test:** Can mastery improve outcomes meaningfully?
4. **Abuse test:** Can this be exploited to skip content or trivialize risk?
5. **Readability test:** Can an observer understand what happened and why?

---

## Red Flags (Stop and Clarify)

- State machine transitions are undefined ("works from any state")
- Multiplayer authority is unspecified
- Economy/currency feature has no balance targets
- Camera behavior during action is undefined
- Feature scope is actually 3+ features in disguise

---

## Definition of Done

- [ ] 5-Component Filter evaluated and documented
- [ ] State Machine Checklist completed (if applicable)
- [ ] Edge cases enumerated and handled
- [ ] Minimum 2 feedback channels for significant actions
- [ ] Playtest script written and smoke-tested
- [ ] Numbers justified per Numbers Policy

---

## Output Structure

When proposing or critiquing a feature:

1. **Player Goal & Context** — What is the player trying to do and why?
2. **System Rules** — Core behavior, failure conditions, edge cases
3. **5-Component Evaluation** — Which components are strong/weak?
4. **Risks & Abuse Cases** — What could break or be exploited?
5. **Playtest Scenarios** — How to validate quickly
6. **Tuning Priority** — What to adjust first if it doesn't feel right

---

## Reference Files

For detailed guidance:

- **`references/5-component-rubric.md`** - Full evaluation rubrics with signals, rules, knobs, acceptance tests
- **`references/domain-guide.md`** - Combat, movement, camera, audio, UI/UX, progression, persistence domains
- **`references/templates.md`** - Edge case enumeration, debugging flow, playtest scripts
