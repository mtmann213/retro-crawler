# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical slice. The complete beginning-to-ending run now includes a physically walkable Service Level, an original top-down crawler, combat impact feedback, three adaptive retro music modes, sound cues, versioned save recovery, persistent settings, and full keyboard/controller navigation.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Press **F5** to run the complete project. F6 only runs the scene currently open in the editor.
3. Choose **New Game** (or **Continue** after creating a save), then walk out of the Intake Shelter to start the 12-minute dungeon clock.
4. Traverse the Broken Junction, optionally search the Maintenance Cache, clear the Processing Hall, and reach the Warden Chamber.
5. During encounters, choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch** while watching each action's dungeon-time cost.
6. Claim deterministic rewards, inspect item rarity, use consumables, equip gear, and return to the room that triggered combat.
7. In the Warden Chamber, engage the boss and adapt as it shifts through Assessment, Containment, and Purge phases—or use emergency extraction to end the run early.

Keyboard and controller are supported. In the Service Level, use WASD, arrow keys, or the D-pad to walk; E, Enter, or controller A interacts; I or controller X opens inventory. Menus use the same directional controls, with Enter or controller A to confirm.

Press Escape, controller B, or the controller Menu button to pause. The pause screen can save the run, return to the title, adjust Master/Music/Effects volume, mute audio, and toggle tutorial reminders. F9 creates a quick checkpoint. Saves use a versioned primary file and preserve the last valid primary as a recoverable backup.

## Test the rules

From this directory, with Godot available on `PATH`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

The suite covers combat rules and UI, stack limits, equipment, loot, progression, the five-room graph, mandatory-room reachability, advertised time costs, once-only clock thresholds and narrative events, optional-detour pressure, Warden phase exclusivity and action availability, both endings, full save/load round trips, corrupt-primary backup recovery, save-version rejection, persistent settings, focus-loss safety, controller bindings, viewport fit, and deterministic combat seeds.

Run the larger release balance sample with:

```powershell
godot --headless --path . -s tools/balance_simulation.gd
```

## Build downloadable versions

Install Godot 4.7.1 export templates, then run:

```powershell
godot --headless --path . --export-release "Windows Desktop"
godot --headless --path . --export-release "Linux"
```

Builds are written under `builds/`. Outside-player release gates and the observation checklist are in `PLAYTEST.md`.

## Release-candidate boundaries

Included: all prior combat, rewards, exploration, boss, and narrative systems; a walkable five-room Service Level with constrained corridors, physical room-entry triggers, interaction markers, an original crawler sprite, and saved world position; transitions and combat feedback; adaptive procedural music and sound cues; title/new/continue flows; full session snapshots; automatic checkpoints; manual and quick saves; valid-backup rotation and recovery; safe version rejection; pause and focus-loss behavior; persistent Master/Music/Effects/tutorial settings; explicit keyboard/controller menu bindings; export presets; GUT tests; and headless coverage.

Deferred beyond this vertical slice: shops, crafting, durability, random affixes, set bonuses, additional floors, and a free-walking overworld. Final release still requires recorded outside playtests and locally installed export templates.
