extends GutTest

const FLOOR := preload("res://content/floors/floor_service_level.tres")
const PRIMARY := "user://gut_m6_session.json"
const BACKUP := "user://gut_m6_session.backup.json"
const SETTINGS := "user://gut_m6_settings.json"


func before_each() -> void:
	_remove(PRIMARY)
	_remove(BACKUP)
	_remove(SETTINGS)


func after_each() -> void:
	_remove(PRIMARY)
	_remove(BACKUP)
	_remove(SETTINGS)


func test_save_load_round_trip_produces_equivalent_full_run_state() -> void:
	var snapshot := _sample_snapshot()
	assert_true(SaveService.save_session(snapshot, PRIMARY, BACKUP).get("ok", false))
	assert_false(FileAccess.file_exists(PRIMARY + ".tmp"))
	var result := SaveService.load_session(PRIMARY, BACKUP)
	assert_true(result.get("ok", false))
	assert_true(snapshot.equivalent_to(result["snapshot"] as SessionSnapshot))
	var floor := FloorState.from_snapshot(FLOOR, (result["snapshot"] as SessionSnapshot).floor_snapshot)
	assert_true(floor.get_room_state(&"room_broken_junction").encounter_completed)
	assert_true(floor.triggered_thresholds.get(360, false))
	assert_eq(floor.run_seed, 424_242)
	assert_eq((result["snapshot"] as SessionSnapshot).character_profile.class_id, "scavenger")
	assert_eq((result["snapshot"] as SessionSnapshot).character_profile.name, "Latch")


func test_corrupted_primary_save_falls_back_to_last_backup() -> void:
	var first := _sample_snapshot()
	assert_true(SaveService.save_session(first, PRIMARY, BACKUP).get("ok", false))
	var second := _sample_snapshot()
	second.floor_snapshot["remaining_seconds"] = 111
	assert_true(SaveService.save_session(second, PRIMARY, BACKUP).get("ok", false))
	var file := FileAccess.open(PRIMARY, FileAccess.WRITE)
	file.store_string("{not valid json")
	file.close()
	var result := SaveService.load_session(PRIMARY, BACKUP)
	assert_true(result.get("ok", false))
	assert_eq(result.get("source"), "backup")
	assert_true(first.equivalent_to(result["snapshot"] as SessionSnapshot))
	assert_true(SaveService.save_session(result["snapshot"], PRIMARY, BACKUP).get("ok", false))
	var preserved_backup := SaveService.load_backup(BACKUP)
	assert_true(preserved_backup.get("ok", false))
	assert_true(first.equivalent_to(preserved_backup["snapshot"] as SessionSnapshot))


func test_semantically_corrupted_primary_falls_back_to_backup() -> void:
	var first := _sample_snapshot()
	assert_true(SaveService.save_session(first, PRIMARY, BACKUP).get("ok", false))
	var second := _sample_snapshot()
	second.floor_snapshot["remaining_seconds"] = 222
	assert_true(SaveService.save_session(second, PRIMARY, BACKUP).get("ok", false))
	var damaged: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PRIMARY))
	damaged["floor"]["current_room_id"] = "room_that_does_not_exist"
	var file := FileAccess.open(PRIMARY, FileAccess.WRITE)
	file.store_string(JSON.stringify(damaged))
	file.close()
	var result := SaveService.load_session(PRIMARY, BACKUP)
	assert_true(result.get("ok", false))
	assert_eq(result.get("source"), "backup")
	assert_true(first.equivalent_to(result["snapshot"] as SessionSnapshot))


func test_unsupported_save_version_fails_safely() -> void:
	var file := FileAccess.open(PRIMARY, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 999}))
	file.close()
	var result := SaveService.load_session(PRIMARY, BACKUP)
	assert_false(result.get("ok", false))
	assert_eq(result.get("error"), "unsupported_save_version")


func test_audio_and_tutorial_settings_persist_and_are_clamped() -> void:
	var settings := {
		"master_volume": 0.35,
		"music_volume": 2.0,
		"effects_volume": -1.0,
		"muted": true,
		"tutorials": false,
	}
	assert_true(SettingsService.save_settings(settings, SETTINGS))
	var loaded := SettingsService.load_settings(SETTINGS)
	assert_eq(loaded.master_volume, 0.35)
	assert_eq(loaded.music_volume, 1.0)
	assert_eq(loaded.effects_volume, 0.0)
	assert_true(loaded.muted)
	assert_false(loaded.tutorials)


func test_keyboard_and_controller_bindings_cover_mandatory_menu_actions() -> void:
	for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_accept", &"cancel"]:
		var has_keyboard := false
		var has_controller := false
		for event: InputEvent in InputMap.action_get_events(action):
			has_keyboard = has_keyboard or event is InputEventKey
			has_controller = has_controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
		assert_true(has_keyboard, "%s requires a keyboard binding." % action)
		assert_true(has_controller, "%s requires a controller binding." % action)
	for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		assert_true(_has_physical_letter_binding(action), "%s requires its WASD binding." % action)


func test_losing_focus_disarms_pause_input_until_a_later_frame() -> void:
	var main_scene := load("res://main/main.tscn") as PackedScene
	var main := main_scene.instantiate() as Main
	add_child_autofree(main)
	await get_tree().process_frame
	var dummy_dungeon := DungeonScreen.new()
	main.dungeon_screen = dummy_dungeon
	main.title_screen.visible = false
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(main._input_armed)
	assert_true(main.title_screen.new_game_button.disabled)
	assert_true(main.pause_menu.resume_button.disabled)
	var cancel := InputEventAction.new()
	cancel.action = &"cancel"
	cancel.pressed = true
	main._unhandled_input(cancel)
	assert_false(main.pause_menu.visible)
	main.dungeon_screen = null
	dummy_dungeon.free()
	await get_tree().process_frame
	assert_false(get_tree().paused)
	main._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(main._input_armed)
	assert_false(main.title_screen.new_game_button.disabled)


func test_new_game_opens_registration_before_creating_a_dungeon() -> void:
	var main_scene := load("res://main/main.tscn") as PackedScene
	var main := main_scene.instantiate() as Main
	add_child_autofree(main)
	await get_tree().process_frame
	main.title_screen.new_game_button.pressed.emit()
	assert_false(main.title_screen.visible)
	assert_true(main.character_setup.visible)
	assert_null(main.dungeon_screen)
	main.character_setup.back_button.pressed.emit()
	assert_true(main.title_screen.visible)
	assert_false(main.character_setup.visible)


func test_dungeon_screen_restores_a_complete_checkpoint() -> void:
	var original := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(original)
	await get_tree().process_frame
	original.floor_state.current_room_id = &"room_processing_hall"
	original.floor_state.remaining_seconds = 222
	original.floor_state.clock_started = true
	original.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	original.player_run_state = {"current_hp": 63, "resources": {"stamina": 4}}
	original.map_area.restore_position(Vector2(350, 102), &"room_processing_hall")
	var patch := original.reward_session.get_item(&"item_field_patch")
	InventoryRules.add_item(original.reward_session.inventory, patch, 2)
	var checkpoint := original.create_session_snapshot()
	var restored := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(restored)
	await get_tree().process_frame
	restored.restore_session(checkpoint)
	assert_eq(restored.floor_state.current_room_id, &"room_processing_hall")
	assert_eq(restored.floor_state.remaining_seconds, 222)
	assert_true(restored.floor_state.get_room_state(&"room_broken_junction").encounter_completed)
	assert_eq(restored.player_run_state.current_hp, 63)
	assert_eq(restored.reward_session.inventory.get_quantity(&"item_field_patch"), 2)
	assert_eq(restored.map_area.player_position, Vector2(350, 102))


func test_midcombat_checkpoint_restarts_the_pending_encounter() -> void:
	var original := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(original)
	await get_tree().process_frame
	original.floor_state.current_room_id = &"room_broken_junction"
	original._start_combat(PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID)
	var checkpoint := original.create_session_snapshot()
	assert_eq(checkpoint.pending_encounter_id, PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID)
	var restored := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(restored)
	await get_tree().process_frame
	restored.restore_session(checkpoint)
	await get_tree().process_frame
	assert_not_null(restored.active_combat)
	assert_eq(restored.active_combat.encounter_id, PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID)
	assert_false(restored.exploration_view.visible)


func test_controller_focus_returns_to_world_after_physical_room_entry() -> void:
	var screen := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(screen)
	await get_tree().process_frame
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen._move_to_room(&"room_broken_junction")
	await get_tree().process_frame
	while screen.announcement_panel.visible:
		(screen.announcement_panel.get_node("%DismissButton") as Button).pressed.emit()
	screen.map_area.grab_focus()
	screen.map_area.player_position = Vector2(205, 30)
	screen.map_area.player_sprite.position = screen.map_area.player_position
	screen.map_area._check_room_entry()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(screen.floor_state.current_room_id, &"room_maintenance_cache")
	assert_eq(get_viewport().gui_get_focus_owner(), screen.map_area)


func test_pending_narrative_queue_survives_restore_until_acknowledged() -> void:
	var original := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(original)
	await get_tree().process_frame
	original.narrative_flags[&"took_detour"] = true
	original._trigger_narrative(&"cache_found")
	assert_eq(original.announcement_panel.pending_event_ids().size(), 2)
	var restored := load("res://scenes/dungeon/dungeon_screen.tscn").instantiate() as DungeonScreen
	add_child_autofree(restored)
	await get_tree().process_frame
	restored.restore_session(original.create_session_snapshot())
	assert_eq(restored.announcement_panel.pending_event_ids().size(), 2)
	(restored.announcement_panel.get_node("%DismissButton") as Button).pressed.emit()
	assert_eq(restored.announcement_panel.pending_event_ids().size(), 1)
	(restored.announcement_panel.get_node("%DismissButton") as Button).pressed.emit()
	assert_true(restored.dialogue_state.pending_events.is_empty())
	assert_true(restored.dialogue_state.shown_events.get(&"achievement_salvage_instinct", false))


func test_title_character_setup_and_pause_screens_fit_the_internal_viewport() -> void:
	for path: String in [
		"res://scenes/title/title_screen.tscn",
		"res://scenes/title/character_setup.tscn",
		"res://scenes/menus/pause_menu.tscn",
	]:
		var screen := (load(path) as PackedScene).instantiate() as Control
		add_child_autofree(screen)
		screen.visible = true
		await get_tree().process_frame
		assert_lte(screen.get_combined_minimum_size().x, 640.0)
		assert_lte(screen.get_combined_minimum_size().y, 360.0)


func test_character_setup_emits_a_sanitized_profile() -> void:
	var setup := load("res://scenes/title/character_setup.tscn").instantiate() as CharacterSetup
	add_child_autofree(setup)
	setup.present()
	setup.name_edit.text = "  Nova!  "
	(setup.get_node("Panel/Layout/Body/Controls/ClassButtons/ScavengerButton") as Button).pressed.emit()
	(setup.get_node("Panel/Layout/Body/Controls/ColorButtons/AmberButton") as Button).pressed.emit()
	var received: Array[Dictionary] = []
	setup.character_confirmed.connect(func(profile: Dictionary) -> void: received.append(profile))
	setup.confirm_button.pressed.emit()
	assert_eq(received.size(), 1)
	assert_eq(received[0].name, "Nova")
	assert_eq(received[0].class_id, "scavenger")
	assert_eq(received[0].color_id, "amber")


func test_pause_panel_keeps_a_visible_margin_inside_the_viewport() -> void:
	var pause := (load("res://scenes/menus/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	add_child_autofree(pause)
	pause.visible = true
	await get_tree().process_frame
	var panel := pause.get_node("Panel") as PanelContainer
	assert_gte(panel.position.x, 8.0)
	assert_gte(panel.position.y, 8.0)
	assert_lte(panel.position.x + panel.size.x, 632.0)
	assert_lte(panel.position.y + panel.size.y, 352.0)


func _sample_snapshot() -> SessionSnapshot:
	var floor := FloorState.new(FLOOR, 424_242)
	floor.current_room_id = &"room_broken_junction"
	floor.remaining_seconds = 333
	floor.clock_started = true
	floor.triggered_thresholds[360] = true
	floor.get_room_state(&"room_broken_junction").visited = true
	floor.get_room_state(&"room_broken_junction").encounter_completed = true
	var rewards := RewardSession.new()
	InventoryRules.add_item(rewards.inventory, rewards.get_item(&"item_field_patch"), 2)
	var snapshot := SessionSnapshot.new()
	snapshot.floor_snapshot = floor.to_snapshot()
	snapshot.reward_snapshot = rewards.to_snapshot()
	snapshot.player_run_state = {"current_hp": 71, "resources": {"stamina": 9}}
	snapshot.dialogue_snapshot = {"shown_events": ["dialogue_floor_intro"]}
	snapshot.narrative_flags = {"took_detour": true}
	snapshot.character_profile = CharacterProfile.new("Latch", &"scavenger", &"amber").to_snapshot()
	return snapshot


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _has_physical_letter_binding(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
			return true
	return false
