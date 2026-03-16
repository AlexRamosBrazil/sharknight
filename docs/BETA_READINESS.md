# SharKnight Beta Readiness

This document focuses on the next practical goal for SharKnight: turning the current modular foundation into a stable and satisfying beta build.

It is not a feature wishlist. It is a prioritized review of what most improves quality, readability, and player trust.

## 1. Priority Order

### P0 - Feel, reliability, and player clarity

These are the changes with the best cost/benefit ratio for a beta:

1. Improve jump feel and movement forgiveness
2. Add stronger damage and attack feedback
3. Make scene transitions and respawn flow clearer
4. Tighten collision setup and level readability
5. Normalize signal ownership and connection flow

### P1 - Combat readability and feedback

1. Telegraph enemy and boss attacks more clearly
2. Add hit stop on strong hits
3. Add screen shake on damage, heavy attacks, and boss actions
4. Add simple particles for hit, heal, pickup, and death
5. Make healing and mana recovery more visible

### P2 - Content safety and maintainability

1. Add debug utilities for checkpoints, boss state, and save data
2. Review export defaults for stamina, magic, cooldowns, and enemy health
3. Audit scene hierarchy consistency across levels
4. Add basic profiling pass on a busier scene

## 2. Architectural Review

### Scene organization

Current direction is good:

- `LevelBase` gives a reusable level shell
- player, enemies, bosses, and UI are already separated
- scenes are mostly split by responsibility

Recommended improvements:

- keep all reusable gameplay pieces instanced under `scenes/core/`
- keep boss encounter pieces together:
  - boss scene in `scenes/bosses/`
  - arena trigger in `scenes/core/`
  - encounter-specific props in the level scene
- when a level grows, prefer sub-scenes for arena chunks, hazard clusters, and scripted set pieces instead of one giant `.tscn`
- keep alternate exits and spawn tags documented per biome to avoid transition drift

### Script reuse

Current direction is also solid:

- `EnemyBase` and `BossBase` reduce duplication
- `PlayerMovement` and `PlayerCombat` already split responsibilities

Recommended improvements:

- keep new movement mechanics in `PlayerMovement`
- keep new combat logic in `PlayerCombat`
- avoid putting one-off logic directly into state scripts unless the behavior is truly state-specific
- add small helper scripts for feedback rather than sprinkling VFX logic into gameplay scripts

### Signal management

Current signal usage is healthy, but the project will benefit from stricter ownership rules:

- `Main` should remain the top-level coordinator for scene flow and UI binding
- `GameState` should remain the source of truth for persistent values shown in HUD
- gameplay actors should emit local intent, not directly manipulate unrelated UI nodes

Recommended rule of thumb:

- actor -> emits signal
- system manager or owner scene -> listens and routes
- UI -> reacts to state or routed signals

## 3. Implemented High-Impact Improvement

### Coyote time and jump buffering

These two changes are already added to `PlayerMovement` and integrated into the player loop.

Files:

- `scripts/player/player.gd`
- `scripts/player/player_movement.gd`
- `scripts/player/states/idle_state.gd`
- `scripts/player/states/run_state.gd`
- `scripts/player/states/crouch_state.gd`

What this improves:

- late jump inputs still work right after leaving a ledge
- early jump inputs are remembered briefly before landing
- jumps feel more intentional and less frustrating

Why this matters for beta:

- players notice movement feel immediately
- it improves trust in controls before any art or audio polish
- it reduces false negatives during playtests

## 4. Next Best Implementations

These are the most valuable next code changes after jump polish.

### Hit stop

Best hook:

- `scripts/combat/attack_hitbox.gd`
- `Player.take_damage(...)`
- enemy and boss `take_damage(...)`

Recommended structure:

- create a small `FeedbackManager` or `TimeEffects` node owned by `Main`
- expose a method like `request_hit_stop(duration, scale := 0.05)`
- call it only on:
  - charge hit
  - special hit
  - boss damage
  - player hurt

Minimal example:

```gdscript
func request_hit_stop(duration: float, slow_scale: float = 0.05) -> void:
	Engine.time_scale = slow_scale
	await get_tree().create_timer(duration * slow_scale, true, false, true).timeout
	Engine.time_scale = 1.0
```

Important note:

- keep durations very short, around `0.03` to `0.06`
- do not stack many hit stops at once

### Screen shake

Best hook:

- add a `Camera2D` owned by the player or level
- trigger shake from player hurt, boss slam, heavy attacks, and checkpoints

Recommended structure:

- `scripts/core/camera_shake.gd`
- method `shake(strength, duration)`

Minimal example:

```gdscript
var shake_strength := 0.0
var shake_time := 0.0

func shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, duration)

func _process(delta: float) -> void:
	if shake_time <= 0.0:
		offset = offset.lerp(Vector2.ZERO, 0.25)
		return
	shake_time -= delta
	offset = Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
```

### Feedback particles

Start simple. Do not wait for final art.

Recommended reusable scenes:

- `HitSpark.tscn`
- `HealBurst.tscn`
- `CoinBurst.tscn`
- `DustPuff.tscn`

Where to spawn them:

- attack hit confirmed
- landing from jump or dash
- collecting pickups
- healing or mana restoration
- enemy death

### Damage and heal feedback

Recommended minimum beta feedback:

- player flashes on damage
- enemy flashes on damage
- heal pickup briefly tints player green-blue
- mana pickup briefly tints player cyan
- floating text or tiny icon burst on heal/mana/coins

## 5. Balance Recommendations

The project is still at a stage where simple consistency is better than deep balancing.

Suggested first-pass targets:

- player basic combo should defeat a weak enemy in 2 to 3 clean hits
- ranged attack should feel useful, not dominant
- stamina should recover quickly enough to keep pace high outside danger
- block should be strong against frontal threats but not free forever
- boss phase transitions should happen fast enough to feel dynamic

Suggested review points:

- stamina costs across melee, ranged, and special
- enemy health bands:
  - weak: 2 to 3
  - medium: 4 to 6
  - tanky: 7 to 10
- boss telegraph duration versus player move speed

## 6. Collision and Control Quality

### Collision cleanup

Recommended rules:

- keep player body collision simple
- avoid decorative collision whenever possible
- separate hazard collision from solid terrain logic
- prefer larger clean colliders over jagged per-pixel feeling geometry

Common beta bugs to watch for:

- edge snagging on corners
- ledge hang firing where it should not
- wall slide starting on decorative surfaces
- ladder overlap zones slightly misaligned with the visible ladder

### Control responsiveness

Already improved:

- coyote time
- jump buffering

Recommended next steps:

- variable jump height by cutting upward velocity when jump is released
- slightly stronger ground acceleration and softer air acceleration
- faster turn response during run
- landing feedback on strong falls or dashes

## 7. Performance Recommendations

The game is still small, so the goal is prevention, not premature optimization.

Recommended actions:

- keep enemy AI cheap when off-screen or far from the player
- avoid oversized `Area2D` detection ranges without a need
- keep placeholder particles lightweight
- profile a stress scene with several enemies, hazards, and pickups active at once
- prefer more reuse of enemy scenes over adding many one-off scripted encounters

Likely future hotspots:

- many simultaneous projectiles
- too many active `Area2D` overlaps in dense rooms
- large scene trees with everything always active

## 8. Scene Transitions

Scene transitions are one of the easiest ways to make a beta feel more intentional.

Recommended minimum:

- quick fade-out on death, victory, and level change
- quick fade-in on new level spawn
- optional area title card using the existing area name from `GameState`

Suggested ownership:

- transition overlay scene owned by `Main`
- `Main` coordinates:
  - pause visibility
  - fade
  - level replacement
  - HUD rebind

## 9. Testing and Debugging Recommendations

### Playtest checklist

Movement:

- test walking off small ledges and jumping late
- test pressing jump just before landing
- test dash into wall, ledge, ladder, and water
- test wall jump near corners and one-tile lips

Combat:

- test combo continuation timing
- test hitbox spacing versus enemy hurtboxes
- test block from front and from behind
- test ranged and special resource consumption

Progression:

- test checkpoint save and reload
- test continue after closing the game
- test boss defeat into victory flow

### Debug tooling suggestions

Useful additions for beta:

- debug toggle to show collision shapes
- debug labels for player state and boss phase
- optional prints behind a `DEBUG_MODE` flag
- a test room scene with:
  - one ladder
  - one water pool
  - one wall jump section
  - one checkpoint
  - one enemy of each family
  - one boss arena trigger

## 10. Recommended Next Implementation Order

1. Keep coyote time and jump buffer, then playtest movement
2. Add variable jump height
3. Add hit stop for heavy hits and player hurt
4. Add camera shake
5. Add simple particles and sound hooks
6. Add fade transitions between level loads and death/retry
7. Run a balancing pass on enemies, bosses, stamina, and magic
