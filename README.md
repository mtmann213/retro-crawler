# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical-slice prototype. Milestone 3 adds a deterministic post-combat reward loop to the reusable multi-enemy combat foundation: loot, rarity, consumable stacks, equipment, experience, and in-memory persistence.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Run the project (`F6`/`F5`).
3. Select the Scrap Hound or Sentry Drone as your target.
4. Choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch**.
5. Read both enemy intents, the timeline, status durations, cooldowns, and event log.
6. Win the encounter, claim deterministic rewards, inspect item rarity, use consumables, equip gear, and continue with the updated inventory and progression.

Keyboard and controller are supported. Use arrow keys, WASD, or the D-pad to move focus; Enter or controller A confirms. The prototype also defines the full input-action list from the development blueprint so later screens do not need direct key checks.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers combat rules and UI, stack limits, equipment application and removal, weighted and unique loot, deterministic reward seeds, monotonic experience thresholds, in-memory reload, the victory-to-inventory flow, and 50 deterministic combat seeds across all three encounter configurations.

## Milestone 3 boundaries

Included: Milestone 2 combat; immutable item and loot definitions; mutable inventory and progression state; deterministic weighted loot; unique drops; consumable stacks and use; weapon and armor slots; visible stat changes; experience progression; reward and inventory UI; continue-to-next-encounter flow; in-memory snapshot reload; GUT tests; and headless coverage.

Deferred: dungeon exploration, the floor clock, shops, crafting, durability, random affixes, set bonuses, disk saves, narrative, final art, and animation polish.
