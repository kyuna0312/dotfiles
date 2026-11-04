# Physics bodies & space queries reference (Godot 4.7)

Depth companion to `godot-physics`. Use the `2D`/`3D` suffix to match your world.

## Body type cheat sheet

| Node | Moves? | Simulated? | Move it by | Use for |
|------|--------|-----------|-----------|---------|
| `StaticBody2D/3D` | No | No | (don't) | Level geometry, walls, floors |
| `AnimatableBody2D/3D` | Yes (scripted/anim) | No | animation / `position` | Moving platforms, doors |
| `RigidBody2D/3D` | Yes | Yes | forces / impulses / `linear_velocity` | Props, debris, balls |
| `CharacterBody2D/3D` | Yes (scripted) | No | `velocity` + `move_and_slide()` | Players, enemies |
| `Area2D/3D` | Yes | No (detection only) | `position` | Triggers, hurt/hitboxes, water |

## Collision layer/mask helpers

```gdscript
set_collision_layer_value(bit, enabled)   # 1-based bit (matches editor checkboxes)
set_collision_mask_value(bit, enabled)
get_collision_layer_value(bit) -> bool
collision_layer = 0b0101                   # raw bitmask (advanced)
```

Name layers in Project Settings > Layer Names > 2D/3D Physics so the editor checkboxes
read like `Player`, `Walls`, `Enemies`.

## RigidBody control

```gdscript
apply_central_impulse(v)     # instant velocity change at center of mass
apply_impulse(v, pos)        # impulse at an offset -> adds spin
apply_central_force(v)       # continuous force (apply each _physics_process)
apply_torque_impulse(t)      # instant angular change
linear_velocity = v          # direct set (use sparingly)
freeze = true                # stop simulation; freeze_mode = FREEZE_MODE_KINEMATIC|STATIC
gravity_scale = 0.0          # disable gravity for this body
```

Full control via `_integrate_forces`:

```gdscript
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    state.linear_velocity = state.linear_velocity.limit_length(max_speed)
    # To teleport safely: state.transform = new_transform; state.linear_velocity = Vector3.ZERO
```

Enable `contact_monitor` and set `max_contacts_reported > 0` to receive
`body_entered`/`body_exited` on a RigidBody.

## Space-state queries (code-driven, no node)

```gdscript
var space := get_world_3d().direct_space_state

# Ray
var rq := PhysicsRayQueryParameters3D.create(from, to)
rq.collision_mask = 0b0010
rq.exclude = [self.get_rid()]
var hit := space.intersect_ray(rq)   # {position, normal, collider, collider_id, rid, shape, face_index}

# Shape overlap (e.g. "what's inside this sphere?")
var shape := SphereShape3D.new(); shape.radius = 2.0
var sq := PhysicsShapeQueryParameters3D.new()
sq.shape = shape
sq.transform = Transform3D(Basis(), global_position)
var hits := space.intersect_shape(sq, 32)  # array of {collider, rid, shape}
```

`intersect_point` (point picks) and `cast_motion`/`collide_shape` (swept and contact tests)
exist on both the 2D and 3D space states. Space-state queries must run during physics (`_physics_process`) for valid data.

## RayCast node tips

- Set `target_position` (relative to the node) and `enabled = true`.
- `is_colliding()`, `get_collider()`, `get_collision_point()`, `get_collision_normal()`.
- `collide_with_areas` / `collide_with_bodies` toggle what it detects.
- After moving the ray within a frame, call `force_raycast_update()` before reading.
- `add_exception(node)` / `add_exception_rid(rid)` to skip specific colliders.

## Joints

`PinJoint`, `HingeJoint`, `SliderJoint`, `Generic6DOFJoint` (3D) and `PinJoint2D`,
`GrooveJoint2D`, `DampedSpringJoint2D` (2D) connect two bodies. Assign `node_a`/`node_b`
to the bodies' paths. Use for ragdolls, chains, vehicles, swinging platforms.

## One-way collision

On a `CollisionShape2D`/`CollisionPolygon2D`, enable **one_way_collision** so bodies pass
from one side only (platforms). The shape blocks motion along
`one_way_collision_direction` (Godot 4.7+, default `Vector2(0, 1)`: things land on top and
pass through from below); before 4.7 that local-down direction is fixed.

## Areas with physics influence

An `Area` can override gravity/damping in its region (`gravity_space_override`,
`gravity`, `linear_damp`) — useful for water, wind, or low-gravity zones affecting any
RigidBody inside.
