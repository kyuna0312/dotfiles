# Roguelike generation, FOV, and loot (depth)

Algorithms behind the systems in `SKILL.md`. Engine-neutral pseudocode. For the noise/RNG
primitives and seeding, defer to `procedural-gen`; this file is the roguelike-specific glue.

## 1. Dungeon generation approaches

Pick by the *texture* you want. All must end with a **connectivity pass** (§2).

### Rooms-and-corridors (classic, readable)

```python
# Place non-overlapping rooms, then connect their centers with L-shaped tunnels.
rooms = []
for _ in range(MAX_ROOMS):
    r = random_rect(rng, min=4, max=10)
    if any(r.intersects(other.expand(1)) for other in rooms):
        continue                      # reject overlaps (expand by 1 to keep walls between)
    carve_room(map, r)
    if rooms:                         # connect to the previous room
        carve_h_then_v(map, rooms[-1].center, r.center, rng)
    rooms.append(r)
# First room = player spawn; last/farthest room = stairs down.
```

### BSP (binary space partition — tidy, building-like)

Recursively split the map rectangle into sub-rectangles; place one room per leaf; connect
sibling rooms as you unwind the recursion. Produces evenly distributed, non-overlapping rooms.

### Cellular automata (organic caves)

```python
# Random fill, then smooth with the "4-5 rule": a cell is wall in the next map if 5 or more of
# the 9 cells in its 3x3 block (itself included) are walls. Same thing: a wall stays a wall with
# 4+ wall neighbours; a floor becomes wall with 5+.
fill_random(map, wall_chance=0.45, rng=rng)
for _ in range(5):                         # 4–5 passes is typical
    new_map = copy(map)                    # read the old map, write a new one
    for cell in map:
        walls = count_walls_3x3(map, cell) # out-of-bounds cells count as walls (solid border)
        new_map[cell] = WALL if walls >= 5 else FLOOR
    map = new_map
# Then keep only the largest connected floor region (discard isolated pockets).
```

Updating the map in place while scanning it makes earlier cells influence later ones in the same
pass, which smears caves in the scan direction. Always write to a second buffer.

### Drunkard's walk (cheap, winding)

Start at a point and random-walk, carving floor, until a target floor percentage is reached.
Guaranteed connected (one continuous path) but can be too snaky without tuning.

## 2. Connectivity (never skip this)

```python
# Flood-fill from the player's start; any walkable cell not reached must be connected or removed.
reached = flood_fill(map, player_start)
regions = find_disconnected_floor_regions(map, reached)
for region in regions:
    carve_corridor(map, nearest_cell(reached), nearest_cell(region), rng)
# Re-flood and assert: every floor cell is now reachable.
```

For caves, the common shortcut is to keep only the single largest region and discard the rest.

## 3. Field of view — symmetric shadowcasting

Properties you want: **symmetric** (if floor tile A sees floor tile B, B sees A), no blind
corners, and walls that light up as you walk along them. Classic recursive shadowcasting (eight
octants, tiles shown if they touch the visible slope range) is fast but breaks symmetry.
*Symmetric shadowcasting* (Albert Ford, 2021) fixes it with one rule: a **floor** tile is
visible only if its **centre** lies inside the visible slope range; a **wall** tile is visible
if any part of it does.

```python
# Pseudocode. Scan each of the 4 quadrants (N, E, S, W) row by row, moving away from the origin.
# Slopes are col/depth; keep them as exact fractions (rationals), not floats, so the edge
# tests do not wobble. (depth, col) is mapped to (x, y) per quadrant by a small transform.
def scan(quadrant, depth, start, end):           # first call: depth=1, start=-1, end=+1
    prev_wall = None
    for col in range(round_half_up(depth * start), round_half_down(depth * end) + 1):
        wall = is_wall(quadrant, depth, col)
        centre_inside = depth * start <= col <= depth * end
        if wall or centre_inside:
            mark_visible(quadrant, depth, col)
        if prev_wall is True and not wall:        # leaving a wall: narrow the start
            start = Fraction(2 * col - 1, 2 * depth)
        if prev_wall is False and wall:           # hitting a wall: scan the gap before it
            scan(quadrant, depth + 1, start, Fraction(2 * col - 1, 2 * depth))
        prev_wall = wall
    if prev_wall is False:                        # row ended on floor: continue outward
        scan(quadrant, depth + 1, start, end)
```

`round_half_up(x)` is `floor(x + 1/2)` and `round_half_down(x)` is `ceil(x - 1/2)`. The origin
tile is always visible and treated as not blocking. Stop recursing at the map edge or at your
light radius, and use a circular check (`dx*dx + dy*dy <= R*R`) for a round light rather than a
square one.

Test it: on random maps, compute FOV from every floor tile and assert that whenever A sees B,
B sees A. This version passes that test; classic recursive shadowcasting does not.

Implementation notes:
- Keep `explored` separately; render explored-but-not-visible cells dimmed.
- Recompute only when the viewer moves or a door/wall changes, not every frame.

## 4. Weighted, depth-scaled loot and spawn tables

```python
# A drop table is a list of (entry, weight). Weight is relative, not a probability.
goblin_loot = [
    ("nothing",      60),
    ("gold_small",   25),
    ("healing_potion", 10),
    ("rare_scroll",   5),
]
def roll(table, rng):
    total = sum(w for _, w in table)
    pick  = rng.range(0, total)        # [0, total)
    upto  = 0
    for entry, w in table:
        upto += w
        if pick < upto:
            return entry

# Depth scaling: shift weights toward stronger entries as depth increases,
# e.g. add depth-gated entries or multiply rare weights by a depth factor.
```

Design guidance:
- Keep "nothing"/common as the bulk of weight so rares stay exciting.
- Gate powerful items behind a minimum depth so early runs can't snowball.
- Separate **monster** spawn tables from **item** drop tables; both scale with depth.
- For "exactly one of" results use weighted pick; for "each may drop" iterate independent rolls.

## 5. Run vs. profile state (permadeath + meta-progression)

- **Run state** (current dungeon, HP, inventory, seed): lives only during the run. For *true*
  permadeath, delete or invalidate this save the moment it is loaded so it cannot be reloaded.
- **Profile state** (unlocked items/classes, high scores, achievements, currency): persists
  across deaths. This is what a roguelite spends on meta-progression.
- Keep them in separate files/sections so wiping a run never touches the profile (see
  `save-systems` for slot/versioning details).
