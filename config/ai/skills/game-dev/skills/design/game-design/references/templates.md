# Templates & Checklists

## Edge Case Enumeration Template

For traversal, combat, or ability mechanics, complete:

| Scenario | Expected Behavior | Implemented? | Notes |
|----------|-------------------|--------------|-------|
| On slope (ascending) | | | |
| On slope (descending) | | | |
| Against ceiling | | | |
| On moving platform | | | |
| During hitstun/knockback | | | |
| While carrying object | | | |
| In water/special zone | | | |
| While another ability active | | | |
| At resource zero | | | |
| During animation lock | | | |
| Near geometry edge | | | |
| At frame-rate extremes | | | |

---

## Extended Debugging Protocol

When told "it feels wrong/boring/clunky," diagnose in order:

| Symptom | Check First | Before Tuning Numbers |
|---------|-------------|----------------------|
| "I didn't know that would happen" | Clarity | Add telegraph, audio cue, UI indicator |
| "I don't care" | Motivation | Connect to progression, increase stakes |
| "It feels laggy" | Response | Add buffering, allow cancels, reduce lockouts |
| "It feels weak" | Satisfaction | Add feedback channels (minimum 2) |
| "It doesn't fit" | Fit | Adjust timing, weight, audio texture |
| "I can't see what's happening" | Camera | Adjust framing, reduce visual noise |
| "I didn't know I could do that" | UI/UX | Add contextual prompts, improve tutorialization |

**Rule:** Do not tune damage/timing numbers until Clarity and Response are verified as not the root cause.

---

## Playtest Script Template

### 1. New Player Test
- **Setup:** Fresh player, no prior explanation
- **Task:** Complete [objective] using [mechanic]
- **Pass:** Player succeeds 8/10 times OR correctly identifies failure reason
- **Observe:** What questions do they ask? Where do they look?

### 2. Stress Test
- **Inputs to spam:** [list specific inputs]
- **Boundary conditions:** [list edge cases]
- **Expected behavior:** System degrades gracefully, no crashes/exploits

### 3. Skill Test
- **Novice baseline:** [expected outcome]
- **Expert ceiling:** [best possible outcome]
- **Gap required:** Experts should outperform novices by [X]%

### 4. Abuse Test
- **Exploit attempts:** [list potential exploits]
- **Content skip attempts:** [list skip vectors]
- **Expected result:** Exploits either impossible or not worth the effort

### 5. Readability Test
- **Observer setup:** Someone watching over shoulder
- **Question:** "What just happened and why?"
- **Pass:** Observer can explain correctly 8/10 times

---

## Feature Proposal Template

```markdown
## Feature: [Name]

### Player Goal & Context
What is the player trying to do and why?

### System Rules
- Core behavior:
- Failure conditions:
- Edge cases:

### 5-Component Evaluation

| Component | Rating | Notes |
|-----------|--------|-------|
| Clarity | | |
| Motivation | | |
| Response | | |
| Satisfaction | | |
| Fit | | |

### State Machine (if applicable)
- Entry conditions:
- Exit conditions:
- Interruptibility:
- Chained actions:
- Resource cost:

### Risks & Abuse Cases
- Potential exploits:
- Balance concerns:

### System Impact
- Level design implications:
- Difficulty curve effects:
- Economy effects:

### Playtest Scenarios
1. New player:
2. Stress:
3. Skill:
4. Abuse:
5. Readability:

### Numbers & Tuning
| Value | Starting | Source/Test Plan |
|-------|----------|------------------|
| | | |

### Tuning Priority
If it doesn't feel right, adjust in this order:
1.
2.
3.
```

---

## State Machine Documentation Template

```markdown
## State: [Name]

### Entry Conditions
- From [State A]: when [condition]
- From [State B]: when [condition]
- NOT from: [forbidden states]

### Exit Conditions
- To [State A]: when [condition]
- To [State B]: when [condition]
- Timeout: [duration] → [default state]

### Interruptibility
- Cancelled by: [damage, input, ability]
- NOT cancelled by: [list]
- Interrupt behavior: [immediate, queued, ignored]

### During State
- Player can: [list allowed actions]
- Player cannot: [list forbidden actions]
- Visuals: [description]
- Audio: [description]

### Resource Interaction
- On entry: consume [resource]
- Per frame: drain [resource] at [rate]
- On exit: [refund/nothing]
- At zero: [behavior]

### Edge Cases
| Condition | Behavior |
|-----------|----------|
| Hit during | |
| Input during | |
| Resource depleted | |
| State interrupted | |
```
