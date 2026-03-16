# SharKnight

SharKnight is a 2D platformer built with Godot 4.6 and GDScript. The project mixes medieval fantasy with underwater themes: the hero is a Shark Knight who fights with a fishbone sword and a turtle-shell shield while exploring the Drowned Kingdom.

The codebase is being shaped as a scalable production base, not just a one-off prototype. The current focus is a playable vertical slice with modular systems for player movement, combat, enemies, bosses, progression, UI, save/load, and themed levels.

## Project Summary

- Engine: Godot 4.6
- Language: GDScript
- Visual style: 2D pixel art
- Tile size: 16x16
- Current status: Active development
- Goal: Reach a solid beta-ready playable build

## Current Features

- Main menu, pause, game over, and victory flow
- HUD with health, stamina, magic, coins, projectiles, area name, and boss bar
- Player state machine with modular movement and combat
- Basic combat set with combo, air attack, crouch attack, charge, ranged, special, and block
- Expanded movement with double jump, dash, wall slide, wall jump, ladder climb, ledge hang, and swimming
- Reusable enemy architecture and boss architecture
- Functional bosses with multi-phase behavior
- Themed level chain covering the main biomes of the Drowned Kingdom
- Biome-specific enemies such as CoralCrab and AbyssWisp
- Checkpoints, pickups, upgrades, progression, and JSON save/load
- Level base structure ready for multiple themed areas
- Early responsiveness polish with coyote time and jump buffering

## Project Structure

```text
sharknight/
|- assets/
|- docs/
|- scenes/
|  |- bosses/
|  |- combat/
|  |- core/
|  |- enemies/
|  |- levels/
|  |- player/
|  |- ui/
|- scripts/
|  |- bosses/
|  |- combat/
|  |- core/
|  |- enemies/
|  |- player/
|  |  |- states/
|  |- ui/
|- project.godot
|- README.md
```

## Main Systems

### Player

- `scripts/player/player.gd`: central orchestration
- `scripts/player/player_movement.gd`: locomotion and traversal
- `scripts/player/player_combat.gd`: attacks, block, hitboxes, cooldowns
- `scripts/player/player_state_machine.gd`: state transitions
- `scripts/player/states/`: isolated player states

### Core

- `scripts/core/main.gd`: game flow and scene/UI coordination
- `scripts/core/game_state.gd`: runtime and persistent game data
- `scripts/core/game_manager.gd`: progression and save orchestration
- `scripts/core/save_manager.gd`: JSON save persistence
- `scripts/core/level_base.gd`: shared level flow

### Combat and Enemies

- Reusable attack hitboxes, hurtboxes, and projectiles
- `EnemyBase` for common enemy behavior
- `BossBase` for multi-phase bosses and HUD boss integration
- Derived enemies for each biome plus specialized lightweight variants

### Levels

- The project now starts in `scenes/levels/coast/Level_CoastKingdom.tscn`
- Each main area has its own scene with:
  - main route
  - checkpoint
  - biome enemies
  - pickups
  - door to the next area
  - optional special exit or alternate spawn routing

## Running the Project

1. Open Godot 4.6.
2. Import `project.godot`.
3. Run `res://scenes/Main.tscn`.

## Documentation

- General evolution guide: `docs/PROJECT_EVOLUTION_GUIDE.md`
- Beta readiness review: `docs/BETA_READINESS.md`

## License

This project is licensed under the MIT License.

That means the project can be copied, modified, and redistributed, including in derived works, as long as the original copyright notice and license text are kept.

## Beta Focus

The next quality milestone is not adding more systems first. It is tightening the feel and reliability of what already exists:

- responsive jump and movement feel
- better damage and combat feedback
- stable boss encounters and level transitions
- collision cleanup and level readability
- lightweight performance checks on a content-heavy scene

## Next Natural Steps

- Replace placeholders with production art and animation
- Add hit stop, screen shake, particles, and audio feedback
- Add smoother scene transitions and encounter presentation
- Replace placeholder geometry with tile-based production layouts
- Add playtest metrics and balance passes for stamina, magic, enemy health, and boss pacing
