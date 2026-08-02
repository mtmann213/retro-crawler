extends GutTest

const DUNGEON_SCREEN := preload("res://scenes/dungeon/dungeon_screen.tscn")


func test_initial_room_pauses_clock_and_advertises_room_entry_cost() -> void:
	var screen := await _spawn_screen()
	assert_eq(screen.floor_state.current_room_id, &"room_intake_shelter")
	assert_false(screen.floor_state.clock_started)
	assert_eq(screen.floor_state.remaining_seconds, 720)
	assert_string_contains((screen.get_node("%FloorClock") as FloorClock).time_label.text, "12:00")
	assert_string_contains((screen.get_node("ExplorationView/Margin/Layout/Footer") as Label).text, "ROOM ENTRY: -15 SEC")
	assert_eq(
		(screen.get_node("%CombatHost") as Control).mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"The empty combat overlay must not intercept exploration clicks.",
	)


func test_opening_inventory_costs_no_time() -> void:
	var screen := await _spawn_screen()
	(screen.get_node("%InventoryButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 720)
	var inventory := screen.get_node("%InventoryScreen") as InventoryScreen
	assert_true(inventory.visible)
	(inventory.get_node("%ContinueButton") as Button).pressed.emit()
	await get_tree().process_frame
	assert_false(inventory.visible)
	assert_eq(screen.floor_state.remaining_seconds, 720)
	assert_eq(get_viewport().gui_get_focus_owner(), screen.map_area)


func test_entering_a_hostile_room_reveals_contact_before_combat() -> void:
	var screen := await _spawn_screen()
	screen.map_area.player_position = Vector2(160, 100)
	screen.map_area.player_sprite.position = screen.map_area.player_position
	screen.map_area._check_room_entry()
	await get_tree().process_frame
	assert_eq(screen.floor_state.current_room_id, &"room_broken_junction")
	assert_eq(screen.floor_state.remaining_seconds, 705)
	assert_null(screen.active_combat)
	assert_true(screen.map_area.encounter_available)
	assert_true(screen.map_area.is_progression_locked(&"room_broken_junction"))
	assert_false(screen.map_area._is_walkable(Vector2(260, 100)))
	_approach_encounter(screen, &"room_broken_junction")
	assert_not_null(screen.active_combat)


func test_walkable_world_constrains_player_to_rooms_and_connected_corridors() -> void:
	var screen := await _spawn_screen()
	assert_true(screen.map_area._is_walkable(Vector2(120, 100)))
	assert_true(screen.map_area._is_walkable(Vector2(205, 65)))
	assert_true(screen.map_area._is_walkable(Vector2(280, 100)))
	assert_false(screen.map_area._is_walkable(Vector2(280, 35)))
	assert_false(screen.map_area._is_walkable(Vector2(620, 149)))


func test_service_level_uses_a_valid_authored_world_layout_and_separate_renderer() -> void:
	var screen := await _spawn_screen()
	var layout := ContentRegistry.get_world_layout()
	assert_not_null(layout)
	assert_true(layout.validate().is_empty())
	assert_eq(layout.rooms.size(), 5)
	assert_eq(layout.corridors.size(), 4)
	assert_eq(layout.starting_position, Vector2(70, 102))
	assert_true(screen.map_area.renderer is WorldRenderer)
	for room: RoomDefinition in screen.FLOOR.rooms:
		assert_not_null(layout.get_room(room.content_id), "Missing world room for %s." % room.content_id)


func test_hostile_sprites_appear_for_active_encounters_and_hide_when_cleared() -> void:
	var screen := await _spawn_screen()
	screen._move_to_room(&"room_broken_junction")
	await get_tree().process_frame
	assert_eq(screen.map_area.renderer.hostile_sprites.size(), 2)
	assert_true(screen.map_area.renderer.hostile_sprites[0].visible)
	assert_true(screen.map_area.renderer.hostile_sprites[1].visible)
	assert_not_null(screen.map_area.renderer.hostile_sprites[0].texture)
	assert_not_null(screen.map_area.renderer.hostile_sprites[1].texture)
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen._render_room()
	await get_tree().process_frame
	assert_false(screen.map_area.renderer.hostile_sprites[0].visible)
	assert_false(screen.map_area.renderer.hostile_sprites[1].visible)


func test_processing_contact_and_combat_use_the_seeded_encounter_variant() -> void:
	var screen := await _spawn_screen()
	screen.floor_state = FloorState.new(screen.FLOOR, 23)
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen._move_to_room(&"room_broken_junction")
	screen._move_to_room(&"room_processing_hall")
	await get_tree().process_frame
	var expected := RunVariationRules.encounter_for_room(
		screen.floor_state.run_variation,
		screen.FLOOR.get_room(&"room_processing_hall"),
	)
	assert_eq(screen.map_area.encounter_id, expected)
	assert_eq(screen.map_area.renderer.encounter_id, expected)
	if expected == PrototypeEncounter.BRUTE_ENCOUNTER_ID:
		assert_true(screen.map_area.renderer.hostile_sprites[0].visible)
		assert_false(screen.map_area.renderer.hostile_sprites[1].visible)
	_approach_encounter(screen, &"room_processing_hall")
	assert_eq(screen.active_combat.encounter_id, expected)
	assert_eq(
		screen.active_combat.encounter_seed,
		RunVariationRules.combat_seed(screen.floor_state.run_seed, &"room_processing_hall"),
	)


func test_room_interactions_require_the_player_to_reach_the_point_of_interest() -> void:
	var screen := await _spawn_screen()
	assert_false(screen.map_area.can_interact_here())
	assert_true(screen.interaction_button.disabled)
	screen.map_area.restore_position(
		screen.map_area.interaction_point_for_room(&"room_intake_shelter"),
		&"room_intake_shelter",
	)
	assert_true(screen.map_area.can_interact_here())
	assert_false(screen.interaction_button.disabled)
	screen._world_interact()
	assert_true(screen.floor_state.get_room_state(&"room_intake_shelter").interaction_completed)


func test_s_moves_down_without_sending_focus_to_the_action_buttons() -> void:
	var screen := await _spawn_screen()
	screen.map_area.grab_focus()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_S
	event.unicode = KEY_S
	event.pressed = true
	get_viewport().push_input(event)
	await get_tree().process_frame
	assert_eq(get_viewport().gui_get_focus_owner(), screen.map_area)
	event.pressed = false
	get_viewport().push_input(event)
	var start := screen.map_area.player_position
	Input.action_press(&"move_down")
	await get_tree().process_frame
	Input.action_release(&"move_down")
	assert_gt(screen.map_area.player_position.y, start.y)


func test_using_inventory_consumable_spends_its_advertised_time() -> void:
	var screen := await _spawn_screen()
	FloorClockRules.start_clock(screen.floor_state)
	screen.player_run_state = {
		"current_hp": 50,
		"resources": {"stamina": 7, "field_patch_charges": 1},
	}
	var patch := screen.reward_session.get_item(&"item_field_patch")
	InventoryRules.add_item(screen.reward_session.inventory, patch, 1)
	(screen.get_node("%InventoryButton") as Button).pressed.emit()
	var inventory := screen.get_node("%InventoryScreen") as InventoryScreen
	(inventory.get_node("%UseItemButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 716)
	assert_eq(int(screen.player_run_state["current_hp"]), 80)
	assert_string_contains((screen.get_node("%EventLog") as RichTextLabel).get_parsed_text(), "ITEM // Field Patch // -4 sec")


func test_optional_cache_detour_and_search_spend_advertised_time() -> void:
	var screen := await _spawn_screen()
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen._move_to_room(&"room_broken_junction")
	screen._move_to_room(&"room_maintenance_cache")
	assert_eq(screen.floor_state.remaining_seconds, 690)
	screen.map_area.restore_position(
		screen.map_area.interaction_point_for_room(&"room_maintenance_cache"),
		&"room_maintenance_cache",
	)
	(screen.get_node("%InteractionButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 670)
	assert_gt(screen.reward_session.inventory.get_quantity(&"item_field_patch"), 0)
	assert_true(screen.floor_state.get_room_state(&"room_maintenance_cache").interaction_completed)


func test_combat_rewards_return_to_the_room_that_triggered_them() -> void:
	var screen := await _spawn_screen()
	screen._move_to_room(&"room_broken_junction")
	_approach_encounter(screen, &"room_broken_junction")
	assert_eq(screen.floor_state.current_room_id, &"room_broken_junction")
	assert_false((screen.get_node("%ExplorationView") as Control).visible)
	var combat := screen.active_combat
	combat.simulation.get_combatant(2).current_hp = 1
	combat.simulation.get_combatant(3).apply_damage(combat.simulation.get_combatant(3).max_hp)
	(combat.get_node("%StrikeButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 700)
	assert_eq((combat.get_node("%DungeonClockLabel") as Label).text, "FLOOR 11:40")
	assert_string_contains((combat.get_node("%CombatLog") as CombatLog).entries.get_parsed_text(), "costs 5 seconds")
	(combat.get_node("%RewardsButton") as Button).pressed.emit()
	var rewards := combat.get_node("%InventoryScreen") as InventoryScreen
	(rewards.get_node("%ContinueButton") as Button).pressed.emit()
	await get_tree().process_frame
	assert_eq(screen.floor_state.current_room_id, &"room_broken_junction")
	assert_true(screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed)
	assert_true((screen.get_node("%ExplorationView") as Control).visible)
	assert_false(screen.map_area.encounter_available)
	assert_false(screen.map_area.is_progression_locked(&"room_broken_junction"))
	assert_true(screen.map_area._is_walkable(Vector2(260, 100)))


func test_player_health_and_resources_persist_into_the_next_room_encounter() -> void:
	var screen := await _spawn_screen()
	screen._move_to_room(&"room_broken_junction")
	_approach_encounter(screen, &"room_broken_junction")
	var first_combat := screen.active_combat
	first_combat.simulation.get_combatant(2).current_hp = 1
	first_combat.simulation.get_combatant(3).apply_damage(first_combat.simulation.get_combatant(3).max_hp)
	(first_combat.get_node("%StrikeButton") as Button).pressed.emit()
	var player := first_combat.simulation.get_combatant(1)
	player.current_hp = 47
	player.resources[&"stamina"] = 7
	player.resources[&"field_patch_charges"] = 1
	(first_combat.get_node("%RewardsButton") as Button).pressed.emit()
	var rewards := first_combat.get_node("%InventoryScreen") as InventoryScreen
	(rewards.get_node("%ContinueButton") as Button).pressed.emit()
	await get_tree().process_frame

	screen._move_to_room(&"room_processing_hall")
	_approach_encounter(screen, &"room_processing_hall")
	var next_player := screen.active_combat.simulation.get_combatant(1)
	assert_eq(next_player.current_hp, 47)
	assert_eq(next_player.get_resource(&"stamina"), 7)
	assert_eq(next_player.get_resource(&"field_patch_charges"), 1)


func test_clock_thresholds_apply_real_idempotent_combat_modifiers() -> void:
	var screen := await _spawn_screen()
	screen.floor_state.triggered_thresholds = {360: true, 180: true, 60: true}
	screen._start_combat(PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID)
	var combat := screen.active_combat
	var player := combat.simulation.get_combatant(1)
	var hound := combat.simulation.get_combatant(2)
	assert_eq(player.get_max_resource(&"stamina"), 35)
	assert_eq(player.speed, 8)
	assert_eq(hound.power, 12)
	assert_eq(hound.defense, 5)
	combat.activate_dungeon_threshold(180)
	assert_eq(hound.power, 12)
	assert_eq(hound.defense, 5)
	var log_text := (combat.get_node("%CombatLog") as CombatLog).entries.get_parsed_text()
	assert_string_contains(log_text, "POWER INSTABILITY")
	assert_string_contains(log_text, "HOSTILE MODIFIERS")
	assert_string_contains(log_text, "ENVIRONMENTAL FAILURE")


func test_deadline_reached_during_combat_aborts_to_extraction_state() -> void:
	var screen := await _spawn_screen()
	screen._move_to_room(&"room_broken_junction")
	_approach_encounter(screen, &"room_broken_junction")
	screen.floor_state.remaining_seconds = 3
	var combat := screen.active_combat
	(combat.get_node("%StrikeButton") as Button).pressed.emit()
	await get_tree().process_frame
	assert_true(screen.floor_state.floor_failed)
	assert_null(screen.active_combat)
	assert_true((screen.get_node("%ExplorationView") as Control).visible)
	assert_true((screen.get_node("%EndPanel") as PanelContainer).visible)


func test_deadline_failure_exposes_once_only_emergency_extraction() -> void:
	var screen := await _spawn_screen()
	FloorClockRules.start_clock(screen.floor_state)
	screen._present_clock_events(FloorClockRules.spend_time(
		screen.floor_state, 720, "test deadline", screen.FLOOR.threshold_seconds,
	))
	screen._render_room()
	assert_true(screen.floor_state.floor_failed)
	assert_true((screen.get_node("%EndPanel") as PanelContainer).visible)
	(screen.get_node("%ExtractButton") as Button).pressed.emit()
	assert_true(screen.floor_state.extracted)
	assert_false((screen.get_node("%ExtractButton") as Button).visible)


func test_player_can_reach_warden_room_and_extract() -> void:
	var screen := await _spawn_screen()
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen.floor_state.get_room_state(&"room_processing_hall").encounter_completed = true
	screen._move_to_room(&"room_broken_junction")
	screen._move_to_room(&"room_processing_hall")
	screen._move_to_room(&"room_warden_chamber")
	assert_true(screen.floor_state.boss_room_reached)
	assert_eq(screen.floor_state.current_room_id, &"room_warden_chamber")
	(screen.get_node("%EmergencyButton") as Button).pressed.emit()
	assert_true(screen.floor_state.extracted)
	assert_true((screen.get_node("%EndPanel") as PanelContainer).visible)


func test_player_can_defeat_warden_and_reach_victory_ending() -> void:
	var screen := await _spawn_screen()
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen.floor_state.get_room_state(&"room_processing_hall").encounter_completed = true
	screen._move_to_room(&"room_broken_junction")
	screen._move_to_room(&"room_processing_hall")
	screen._move_to_room(&"room_warden_chamber")
	screen.map_area.restore_position(
		screen.map_area.interaction_point_for_room(&"room_warden_chamber"),
		&"room_warden_chamber",
	)
	(screen.get_node("%InteractionButton") as Button).pressed.emit()
	var combat := screen.active_combat
	assert_eq(combat.encounter_id, PrototypeEncounter.WARDEN_ENCOUNTER_ID)
	combat.simulation.get_combatant(2).current_hp = 1
	(combat.get_node("%StrikeButton") as Button).pressed.emit()
	(combat.get_node("%RewardsButton") as Button).pressed.emit()
	var rewards := combat.get_node("%InventoryScreen") as InventoryScreen
	(rewards.get_node("%ContinueButton") as Button).pressed.emit()
	await get_tree().process_frame
	assert_true(screen.floor_state.boss_defeated)
	assert_true(screen.floor_state.victory_ending)
	assert_true((screen.get_node("%EndPanel") as PanelContainer).visible)


func test_dungeon_screen_fits_the_internal_viewport() -> void:
	var screen := await _spawn_screen()
	var minimum_size := screen.get_combined_minimum_size()
	assert_lte(minimum_size.x, 640.0)
	assert_lte(minimum_size.y, 360.0)
	screen.floor_state.current_room_id = &"room_broken_junction"
	screen.floor_state.get_room_state(&"room_broken_junction").visited = true
	screen._render_room()
	await get_tree().process_frame
	var content_rect := (screen.get_node("ExplorationView/Margin/Layout") as VBoxContainer).get_global_rect()
	assert_gte(content_rect.position.x, 10.0)
	assert_lte(content_rect.end.x, 630.0)
	assert_gte(content_rect.position.y, 7.0)
	assert_lte(content_rect.end.y, 353.0)
	var map_rect := screen.map_area.get_global_rect()
	assert_true(map_rect.has_point(map_rect.position + screen.map_area.player_position))
	assert_eq(screen.map_area.current_room_id, &"room_broken_junction")


func _spawn_screen() -> DungeonScreen:
	var screen := DUNGEON_SCREEN.instantiate() as DungeonScreen
	add_child_autofree(screen)
	await get_tree().process_frame
	return screen


func _approach_encounter(screen: DungeonScreen, room_id: StringName) -> void:
	screen.map_area.restore_position(screen.map_area.encounter_point_for_room(room_id), room_id)
	screen.map_area._check_encounter_proximity()
