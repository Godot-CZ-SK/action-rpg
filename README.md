action-rpg
==========
Experimental RPG system...

# Goals
- multiple levels (tools to create levels)
- combat: melee, ranged & magic
- player stats & skills, running
- inventory, weapon slots, items, drops...
- NPC, dialogues, quests, active elements (levers, switches, doors...), rewards
- multiplayer
- game menus, HUD, settings, themes
- save & load game
- KISS: keep it simple, stupid

# Directories
```
assets/
	audio/       - sounds and music
	backgrounds/ - 
	effects/     - reusable effects
	enemies/     - every enemy in custom subdirectory
	items/       - inventory items & drops
	levels/      - Levels
	shaders/     - Shaders
	shadows/     - shadows
	ui/          - UI assets
	world/       - assets for levels
core/     - core scripts and scenes, autoloads...
```

# Game Objects

## AutoLoaded
- `Cam` with Camera2D
- `Player` (moved over scene tree by `init_in_level()`)
- `HUD`
- `LevelManager` with `change_level(level, position)`

## Levels
Every Level (at `assets/levels/<LevelName>.tscn`) should have following main nodes:

- `Background` Sprite
- `TileMap`s
- `YSort` node (needed for Player to be attached here)
- `CamLimits` with enabled **Editable Children** option to limit Cam borders by position of `TopLeft` and `BottomRight` (or Camera movement will be limited by limits of previous level or by Cam's default settings)

## Level Nodes
- Enemies (currently only Bat)
- Portal
- HealthFountain

# Credits
Initial fork from https://github.com/uheartbeast/youtube-tutorials. See [LICENSE](LICENSE).

## Assets
- https://github.com/uheartbeast/youtube-tutorials
- https://opengameart.org/content/dungeon-crawl-32x32-tiles
- https://opengameart.org/content/dungeon-crawl-32x32-tiles-supplemental

