# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical-slice prototype. Milestone 6 wraps the complete beginning-to-ending run in a title screen, versioned save and backup recovery, persistent audio settings, pause controls, tutorials, and full keyboard/controller navigation.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Press **F5** to run the complete project. F6 only runs the scene currently open in the editor.
3. Choose **New Game** (or **Continue** after creating a save), then leave the Intake Shelter to start the 12-minute dungeon clock.
4. Traverse the Broken Junction, optionally search the Maintenance Cache, clear the Processing Hall, and reach the Warden Chamber.
5. During encounters, choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch** while watching each action's dungeon-time cost.
6. Claim deterministic rewards, inspect item rarity, use consumables, equip gear, and return to the room that triggered combat.
7. In the Warden Chamber, engage the boss and adapt as it shifts through Assessment, Containment, and Purge phases—or use emergency extraction to end the run early.

Keyboard and controller are supported. Use arrow keys, WASD, or the D-pad to move focus; Enter or controller A confirms. The prototype also defines the full input-action list from the development blueprint so later screens do not need direct key checks.

Press Escape, controller B, or the controller Menu button to pause. The pause screen can save the run, return to the title, adjust Master/Music/Effects volume, mute audio, and toggle tutorial reminders. F9 creates a quick checkpoint. Saves use a versioned primary file and preserve the last valid primary as a recoverable backup.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers combat rules and UI, stack limits, equipment, loot, progression, the five-room graph, mandatory-room reachability, advertised time costs, once-only clock thresholds and narrative events, optional-detour pressure, Warden phase exclusivity and action availability, both endings, full save/load round trips, corrupt-primary backup recovery, save-version rejection, persistent settings, focus-loss safety, controller bindings, viewport fit, and 50 deterministic combat seeds.

## Milestone 6 boundaries

Included: all prior combat, rewards, exploration, boss, and narrative systems; title/new/continue flows; full session snapshots; automatic checkpoints; manual and quick saves; valid-backup rotation and recovery; safe version rejection; pause and focus-loss behavior; persistent Master/Music/Effects/tutorial settings; explicit keyboard/controller menu bindings; retro UI theme; GUT tests; and headless coverage.

Deferred: shops, crafting, durability, random affixes, set bonuses, final art, authored music and sound assets, animation polish, balance playtests, and distributable builds.
