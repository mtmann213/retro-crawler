# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical-slice prototype. The current repository intentionally contains **Milestone 1 only**: a deterministic, one-versus-one combat rules proof with a playable graybox interface.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Run the project (`F6`/`F5`).
3. Choose **Quick Strike** or **Brace**.
4. Read the Scrap Hound's intent and the event log, then win, lose, or restart.

Keyboard and controller are supported. Use arrow keys, WASD, or the D-pad to move focus; Enter or controller A confirms. The prototype also defines the full input-action list from the development blueprint so later screens do not need direct key checks.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers normal, guarded, critical, minimum, immune, and seeded damage; turn selection; invalid and dead-actor commands; stamina costs; combat completion; and 100 deterministic encounter simulations.

## Milestone 1 boundaries

Included: immutable Resource definitions, mutable combat state, deterministic rules, a speed timeline, visible enemy intent, event-driven UI, immediate restart, GUT tests, and headless soak coverage.

Deferred: dungeon exploration, the floor clock, inventory, loot, status effects, saves, narrative, final art, and animation polish.
