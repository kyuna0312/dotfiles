# Domain-Specific Design Guide

## Combat Design

**Core question:** Is the player fighting?

**Sub-domains:**
- **Melee:** Spacing, hitbox/hurtbox clarity, commitment frames, cancel windows
- **Ranged:** Projectile vs. hitscan rules, ammo economy, aim assist policy
- **Group combat:** Crowd control, threat readability, aggro management, target switching

**Feedback requirements:**
- Distinguish: hit confirmation vs. damage magnitude vs. status effects
- Scale feedback with importance (avoid "noise soup")

**Decision gate:** If feedback includes "cheap," "unfair," or "confusing" — do NOT tune numbers first. Evaluate Clarity + Response (telegraphs, counter windows, failure messaging) before touching damage values.

---

## Movement / Traversal

**Core question:** How does the player move through space?

**Feel model:**
- Responsiveness vs. weight is a **Fit** decision
- Forgiveness rules (buffering, grace windows) are **Response** decisions

**Reference starting values** (label as such, test before committing):

| Mechanic | Starting Value | Test Criteria |
|----------|----------------|---------------|
| Coyote time | 80-150ms | Players make intended jumps 9/10 times |
| Jump buffer | 100-200ms | Pre-landing jumps register reliably |
| Corner correction | 4-8 pixels | Head-bumps on near-misses are rare |
| Input-to-action | ≤100ms | Inputs feel immediate |

**Diagnostic — "Floaty" feel:**
- Increase gravity/downward acceleration
- Reduce air control
- Reduce jump apex hangtime
- Add landing commitment frames

**Diagnostic — "Unresponsive" feel:**
- Increase initial acceleration
- Add input buffering
- Reduce animation lockouts
- Verify input-to-action latency

---

## Camera Systems

**Core question:** How does the player see the world?

**Parameters to define:**

| Parameter | Purpose | Typical Range |
|-----------|---------|---------------|
| Follow lag | Smoothness vs. precision | 0.1–0.5s |
| Dead zone | Movement before camera responds | 10–30% screen |
| Look-ahead | Anticipate player direction | 0–2 units |

**Context transitions** (define behavior for each):
- Exploration → Combat
- Combat → Dialogue
- Gameplay → Cinematic

**Collision rules:**
- Camera must not clip geometry
- Define: zoom, transparency, or cut when obstructed
- Minimum distance when compressed

---

## Audio

**Core question:** What does the player hear?

**Spatial audio requirements:**
- Threats audible before visible
- Directional information clear
- Distance attenuation appropriate

**Adaptive music states:**
- Exploration (low intensity)
- Tension/suspicious (building)
- Combat (full intensity)
- Resolution (stinger + transition)

**Priority/ducking hierarchy:**

| Priority | Examples | Behavior |
|----------|----------|----------|
| Critical | Player damage, death, critical UI | Ducks everything |
| High | Combat impacts, dialogue | Ducks ambient/music |
| Medium | Footsteps, environmental | Normal mix |
| Low | Ambient loops | Ducked by all |

**Variation requirement:** Any sound that plays frequently needs 3+ variants to prevent repetition fatigue.

---

## Actions & Interactions

**Core question:** How does the player manipulate the world?

**Context action types:**
- Auto-trigger (proximity): High clarity risk — requires strong feedback on trigger zone
- Hold-to-confirm: Slow but safe — requires progress indicator
- Tap-to-execute: Fast but error-prone — requires distinct prompts
- Dual-purpose buttons: Avoid without explicit state indicator

**Resource economy rules:**
Every resource must answer: "What decision does this create?"

| Resource | Decision Type |
|----------|---------------|
| Stamina | Pacing within encounters |
| Mana/Energy | Ability selection and timing |
| Cooldowns | Rotation and commitment |
| Ammunition | Engagement distance and target priority |

**Decision gate:** If one input does multiple things, define: priority order, disambiguation signals, failure messaging.

---

## Abilities & Progression

**Core question:** How does the player evolve?

**Structure types:**
- Linear: Clear but no expression
- Branching: Choice but balance complexity
- Modular/loadout: Replayability but requires breadth

**Progression integrity gate:** Before adding any upgrade/ability, answer:
1. What new decision does this create?
2. What content does this make obsolete?
3. How does this affect difficulty pacing?

**Power curve warning:** "+5% forever" is not meaningful progression. Upgrades should change *decisions*, not just numbers.

---

## Core Loop & Pacing

**Core question:** What does the player do repeatedly, and why do they return?

**Loop definition (mandatory for new games):**
- **Loop verbs:** Primary actions (fight/loot/upgrade/explore/build)
- **Reward cadence:** How often meaningful progress occurs
- **Session arcs:** What changes at 30s / 2min / 10min / session-end

**Pacing rules:**
- Players need "breath" after encounters lasting >60s or requiring significant resources
- Rest points should be visible before challenges, not discovered after
- Intensity ramp should change *decisions*, not just numbers

**Decision gate:** If a feature doesn't strengthen the core loop, it's a distraction. Must justify Fit + Motivation within the loop.

---

## UI/UX & Information Architecture

**Core question:** How does the player understand, decide, and act?

**HUD hierarchy:**

| Priority | Content | Visibility |
|----------|---------|------------|
| Critical | Health, immediate threats | Always visible |
| Important | Objectives, cooldowns | Glanceable |
| Reference | Inventory, stats, map | On-demand |

**Onboarding principle:** Players don't read. Design for learning-by-doing.
- Show → Safe practice → Test → Remix

**Accessibility baseline:**
- Remappable controls (high priority)
- Subtitles/captions (high priority)
- Colorblind modes (high priority)
- Motion sensitivity options (camera shake, blur toggles)

**Decision gate:** If the player can't tell *why* something happened, it's broken. Define: success conditions, failure reasons, signals for both.

---

## State Persistence

**Core question:** What survives across sessions?

**Save system types:**
- Manual: Player control, save-scum risk
- Checkpoint: Designer control, frustration if sparse
- Autosave: Safety net, can overwrite wanted state
- Hybrid: Flexibility, complexity

**What to persist:**

| Always | Consider | Usually Not |
|--------|----------|-------------|
| Player position/state | Camera orientation | Particle states |
| Inventory | Enemy positions | Transient audio |
| Quest/story flags | Destructible states | Animation frames |
| Unlocks/abilities | Environmental changes | Temporary UI state |

**Edge cases to define:**
- Quit during combat: Resume in combat, reset encounter, or flee to safety?
- Quit during cutscene: Resume, skip, or replay?
- Save corruption: Backup strategy, graceful error, cloud recovery?
