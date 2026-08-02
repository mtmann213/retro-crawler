# Retro Crawler

Retro Crawler is a Godot 4.7.1 vertical slice. The complete beginning-to-ending run now includes character creation with three classes and suit accents, the persistent survey companion Mox, an optional Tutorial Guild, a physically walkable Service Level, an original animated top-down crawler, visible animated Scrap Hound and Sentry Drone contacts, seeded run variation, combat impact feedback, three adaptive retro music modes, sound cues, versioned save recovery, persistent settings, and full keyboard/controller navigation.

Mox is a visible exploration companion with an authored personality, deterministic contextual reactions, bounded relationship growth, and saved memories. The companion foundation is fully offline; optional model-enhanced incidental conversation is reserved for a later milestone.

The expedition-generation foundation deterministically produces validated 8–12-room plans with a traversable critical route, optional branches, encounter and resource roles, a final objective, and a safe extraction path. Physical placement and rendering of these plans is the next generation milestone.

Defeating the Warden now returns the crawler and Mox to the Wayfarer mobile base. Its navigation board renders the next seeded expedition contract and can survey alternate contracts instead of leaving the completed run on an actionless ending panel.

Visual production follows the original 16-bit-inspired technical and style contract in [docs/VISUAL_DIRECTION.md](docs/VISUAL_DIRECTION.md).

The Service Level world is authored in `content/worlds/service_level_layout.tres`. Its reusable room resources define bounds, visual styles, interaction and encounter sockets, progression barriers, and corridors independently from the movement controller. `WorldRenderer` presents that data as an 8x8 tiled layer with animated room lighting, hostile contacts, encounter warnings, and progression locks, providing the foundation for future imported tilesets and seeded room variants without putting generated geometry into combat or save rules.

Every New Game now creates and saves a run seed. That seed deterministically selects one of three lighting circuits, per-room hazard markings and light phases, the Processing Hall enemy formation, the Maintenance Cache supply count, combat randomness, and loot randomness. Continue and recovery reproduce the same selections exactly; starting another New Game produces a fresh combination while preserving the five-room route and Warden finale.

## Play the prototype

1. Open this folder in Godot 4.7.1.
2. Press **F5** to run the complete project. F6 only runs the scene currently open in the editor.
3. Choose **New Game**, enter a callsign, and select Vanguard, Scavenger, or Signalist plus a suit accent. Continue bypasses registration and restores the saved profile.
4. Walk out of the Intake Shelter to start the 12-minute dungeon clock.
5. Traverse the Broken Junction, approach visible hostiles to engage them, optionally search the Maintenance Cache, clear the Processing Hall to unlock the final route, and reach the Warden Chamber.
6. During encounters, choose among **Quick Strike**, **Heavy Swing**, **Brace**, **Hamstring**, and **Field Patch** while watching each action's dungeon-time cost.
7. Claim deterministic rewards, inspect item rarity, use consumables, equip gear, and return to the room that triggered combat.
8. In the Warden Chamber, engage the boss and adapt as it shifts through Assessment, Containment, and Purge phases—or use emergency extraction to end the run early.

Keyboard and controller are supported. In the Service Level, use WASD, arrow keys, or the D-pad to walk. Move into the highlighted radius around a point of interest, then press E, Enter, or controller A to interact; I or controller X opens inventory. Menus use the same directional controls, with Enter or controller A to confirm.

The Intake Shelter provides a zero-time Tutorial Guild link. Operator Coda's five optional briefings cover the floor contract, movement and time, combat intents, inventory/loadout decisions, and class-specific doctrine. Lesson completion is saved with the run. Turning off tutorial reminders suppresses the automatic Guild hint while leaving the archive available on demand.

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

Included: all prior combat, rewards, exploration, boss, and narrative systems; a walkable five-room Service Level with constrained corridors, physical room-entry triggers, visible hostile contacts, proximity-triggered encounters, clear-to-unlock progression barriers, proximity-based points of interest, contextual prompts, distinct room machinery and hazards, an original crawler sprite, and saved world position; transitions and combat feedback; adaptive procedural music and sound cues; title/new/continue flows; full session snapshots; automatic checkpoints; manual and quick saves; valid-backup rotation and recovery; safe version rejection; pause and focus-loss behavior; persistent Master/Music/Effects/tutorial settings; explicit keyboard/controller menu bindings; export presets; GUT tests; and headless coverage.

Deferred beyond this vertical slice: shops, crafting, durability, random affixes, set bonuses, additional floors, and a free-walking overworld. Final release still requires recorded outside playtests and locally installed export templates.
