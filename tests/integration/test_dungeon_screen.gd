extends GutTest

const DUNGEON_SCREEN := preload("res://scenes/dungeon/dungeon_screen.tscn")


func test_initial_room_pauses_clock_and_advertises_move_cost() -> void:
	var screen := await _spawn_screen()
	assert_eq(screen.floor_state.current_room_id, &"room_intake_shelter")
	assert_false(screen.floor_state.clock_started)
	assert_eq(screen.floor_state.remaining_seconds, 720)
	assert_string_contains((screen.get_node("%FloorClock") as FloorClock).time_label.text, "12:00")
	var exits := screen.get_node("%ExitList") as HBoxContainer
	assert_string_contains((exits.get_child(0) as Button).text, "-15 SEC")


func test_opening_inventory_costs_no_time() -> void:
	var screen := await _spawn_screen()
	(screen.get_node("%InventoryButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 720)
	var inventory := screen.get_node("%InventoryScreen") as InventoryScreen
	assert_true(inventory.visible)
	(inventory.get_node("%ContinueButton") as Button).pressed.emit()
	assert_false(inventory.visible)
	assert_eq(screen.floor_state.remaining_seconds, 720)


func test_using_inventory_consumable_spends_its_advertised_time() -> void:
	var screen := await _spawn_screen()
	FloorClockRules.start_clock(screen.floor_state)
	var patch := screen.reward_session.get_item(&"item_field_patch")
	InventoryRules.add_item(screen.reward_session.inventory, patch, 1)
	(screen.get_node("%InventoryButton") as Button).pressed.emit()
	var inventory := screen.get_node("%InventoryScreen") as InventoryScreen
	(inventory.get_node("%UseItemButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 716)
	assert_string_contains((screen.get_node("%EventLog") as RichTextLabel).get_parsed_text(), "ITEM // Field Patch // -4 sec")


func test_optional_cache_detour_and_search_spend_advertised_time() -> void:
	var screen := await _spawn_screen()
	screen.floor_state.get_room_state(&"room_broken_junction").encounter_completed = true
	screen._move_to_room(&"room_broken_junction")
	screen._move_to_room(&"room_maintenance_cache")
	assert_eq(screen.floor_state.remaining_seconds, 690)
	(screen.get_node("%InteractionButton") as Button).pressed.emit()
	assert_eq(screen.floor_state.remaining_seconds, 670)
	assert_gt(screen.reward_session.inventory.get_quantity(&"item_field_patch"), 0)
	assert_true(screen.floor_state.get_room_state(&"room_maintenance_cache").interaction_completed)


func test_combat_rewards_return_to_the_room_that_triggered_them() -> void:
	var screen := await _spawn_screen()
	screen._move_to_room(&"room_broken_junction")
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


func test_deadline_reached_during_combat_aborts_to_extraction_state() -> void:
	var screen := await _spawn_screen()
	screen._move_to_room(&"room_broken_junction")
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
	(screen.get_node("%InteractionButton") as Button).pressed.emit()
	assert_true(screen.floor_state.extracted)
	assert_true((screen.get_node("%EndPanel") as PanelContainer).visible)


func test_dungeon_screen_fits_the_internal_viewport() -> void:
	var screen := await _spawn_screen()
	var minimum_size := screen.get_combined_minimum_size()
	assert_lte(minimum_size.x, 640.0)
	assert_lte(minimum_size.y, 360.0)


func _spawn_screen() -> DungeonScreen:
	var screen := DUNGEON_SCREEN.instantiate() as DungeonScreen
	add_child_autofree(screen)
	await get_tree().process_frame
	return screen
