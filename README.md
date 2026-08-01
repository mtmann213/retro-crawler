# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical-slice prototype. Milestone 2 expands the deterministic combat proof into a reusable combat foundation with multi-enemy encounters, resources, cooldowns, status effects, telegraphs, and an explanatory event log.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Run the project (`F6`/`F5`).
3. Select the Scrap Hound or Sentry Drone as your target.
4. Choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch**.
5. Read both enemy intents, the timeline, status durations, cooldowns, and event log, then win, lose, or restart.

Keyboard and controller are supported. Use arrow keys, WASD, or the D-pad to move focus; Enter or controller A confirms. The prototype also defines the full input-action list from the development blueprint so later screens do not need direct key checks.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers damage math, owner-turn cooldowns, phase-based statuses, stable timeline ties, AI validity, telegraph fidelity, ordered multi-effects, target selection, combat completion, and 100 deterministic encounter simulations.

## Milestone 2 boundaries

Included: immutable skill, status, enemy, and encounter definitions; mutable combat state; five player skills; three ordinary enemy types; two-enemy combat; stamina and limited charges; owner-turn cooldowns; status effects; a speed timeline; visible AI intents; event-driven UI; immediate restart; GUT tests; and headless soak coverage.

Deferred: dungeon exploration, the floor clock, inventory, loot drops, saves, narrative, final art, and animation polish.
