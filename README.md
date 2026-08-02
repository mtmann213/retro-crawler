# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical-slice prototype. Milestone 4 connects the deterministic combat and reward systems to a five-room graybox dungeon with interactions, an optional detour, and a visible action-driven floor clock.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Run the project (`F6`/`F5`).
3. Leave the Intake Shelter to start the 12-minute dungeon clock.
4. Traverse the Broken Junction, optionally search the Maintenance Cache, clear the Processing Hall, and reach the Warden Chamber.
5. During encounters, choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch** while watching each action's dungeon-time cost.
6. Claim deterministic rewards, inspect item rarity, use consumables, equip gear, and return to the room that triggered combat.
7. Reach the Warden Chamber or use emergency extraction when the floor deadline expires.

Keyboard and controller are supported. Use arrow keys, WASD, or the D-pad to move focus; Enter or controller A confirms. The prototype also defines the full input-action list from the development blueprint so later screens do not need direct key checks.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers combat rules and UI, stack limits, equipment, loot, progression, the five-room graph, mandatory-room reachability, advertised time costs, once-only clock thresholds and deadline behavior, optional-detour pressure, emergency extraction, combat return routing, viewport fit, and 50 deterministic combat seeds.

## Milestone 4 boundaries

Included: Milestone 3 combat and rewards; immutable floor and room definitions; mutable floor and room state; a validated five-room graph; deterministic action-based clock; warning thresholds; graybox navigation; zero-time menus; cache interaction and loot; optional detour; two combat handoffs; return-to-room routing; boss-room arrival; floor failure; emergency extraction; GUT tests; and headless coverage.

Deferred: the Warden boss, narrative announcements, shops, crafting, durability, random affixes, set bonuses, disk saves, final art, and animation polish.
