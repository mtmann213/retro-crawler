# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical-slice prototype. Milestone 5 completes the first beginning-to-ending run with original narrative events, achievements, a three-phase Warden boss, and distinct victory and emergency-extraction endings.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Run the project (`F6`/`F5`).
3. Leave the Intake Shelter to start the 12-minute dungeon clock.
4. Traverse the Broken Junction, optionally search the Maintenance Cache, clear the Processing Hall, and reach the Warden Chamber.
5. During encounters, choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch** while watching each action's dungeon-time cost.
6. Claim deterministic rewards, inspect item rarity, use consumables, equip gear, and return to the room that triggered combat.
7. In the Warden Chamber, engage the boss and adapt as it shifts through Assessment, Containment, and Purge phases—or use emergency extraction to end the run early.

Keyboard and controller are supported. Use arrow keys, WASD, or the D-pad to move focus; Enter or controller A confirms. The prototype also defines the full input-action list from the development blueprint so later screens do not need direct key checks.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers combat rules and UI, stack limits, equipment, loot, progression, the five-room graph, mandatory-room reachability, advertised time costs, once-only clock thresholds and narrative events, optional-detour pressure, Warden phase exclusivity and action availability, both endings and their saved flags, combat return routing, viewport fit, and 50 deterministic combat seeds.

## Milestone 5 boundaries

Included: all prior combat, rewards, and exploration systems; data-driven dialogue events; queued announcements, room dialogue, and achievement messages; a Warden boss with three exclusive HP-gated phases and readable telegraphs; phase-safe AI replanning; a complete victory path; emergency extraction; ending-state snapshots; GUT tests; and headless coverage.

Deferred: shops, crafting, durability, random affixes, set bonuses, full disk-save orchestration, final art, audio, and animation polish.
