extends GutTest

const COMBAT_SCREEN_SCENE := preload("res://scenes/combat/combat_screen.tscn")


func test_strike_button_resolves_player_and_enemy_actions() -> void:
	var screen := await _spawn_screen()
	var enemy_hp_before := screen.simulation.get_combatant(2).current_hp
	var player_hp_before := screen.simulation.get_combatant(1).current_hp

	(screen.get_node("%StrikeButton") as Button).pressed.emit()

	assert_lt(screen.simulation.get_combatant(2).current_hp, enemy_hp_before)
	assert_lt(screen.simulation.get_combatant(1).current_hp, player_hp_before)
	assert_string_contains(
		(screen.get_node("%CombatLog") as CombatLog).entries.get_parsed_text(),
		"Quick Strike",
	)


func test_brace_button_guards_the_enemy_response() -> void:
	var screen := await _spawn_screen()
	(screen.get_node("%BraceButton") as Button).pressed.emit()
	var player := screen.simulation.get_combatant(1)

	assert_false(player.is_defending, "Brace expires when the next player turn begins.")
	assert_gte(player.current_hp, 90, "Brace should mitigate the two-enemy response.")
	assert_string_contains(
		(screen.get_node("%CombatLog") as CombatLog).entries.get_parsed_text(),
		"braces",
	)


func test_restart_button_replaces_finished_state() -> void:
	var screen := await _spawn_screen()
	var enemy := screen.simulation.get_combatant(2)
	var second_enemy := screen.simulation.get_combatant(3)
	enemy.current_hp = 1
	second_enemy.apply_damage(second_enemy.max_hp)
	(screen.get_node("%StrikeButton") as Button).pressed.emit()
	assert_true(screen.simulation.combat_finished_flag)
	assert_true((screen.get_node("%RestartButton") as Button).visible)

	(screen.get_node("%RestartButton") as Button).pressed.emit()

	assert_false(screen.simulation.combat_finished_flag)
	assert_eq(screen.simulation.get_combatant(1).current_hp, 100)
	assert_eq(screen.simulation.get_combatant(2).current_hp, 42)
	assert_eq(screen.simulation.get_combatant(3).current_hp, 34)
	assert_false((screen.get_node("%RestartButton") as Button).visible)


func test_victory_claims_rewards_and_continues_with_persistent_progress() -> void:
	var screen := await _spawn_screen()
	var enemy := screen.simulation.get_combatant(2)
	var second_enemy := screen.simulation.get_combatant(3)
	enemy.current_hp = 1
	second_enemy.apply_damage(second_enemy.max_hp)
	(screen.get_node("%StrikeButton") as Button).pressed.emit()
	var rewards_button := screen.get_node("%RewardsButton") as Button
	assert_true(rewards_button.visible)

	rewards_button.pressed.emit()

	var inventory_screen := screen.get_node("%InventoryScreen") as InventoryScreen
	assert_true(inventory_screen.visible)
	assert_eq(screen.reward_session.progression.total_experience, 85)
	assert_false(screen.reward_session.inventory.quantities.is_empty())
	assert_false(rewards_button.visible)
	var has_equipment := false
	var has_consumable := false
	for item_id: StringName in screen.reward_session.inventory.quantities:
		var item := screen.reward_session.get_item(item_id)
		has_equipment = has_equipment or item.equipment_slot != ItemDefinition.EquipmentSlot.NONE
		has_consumable = has_consumable or item.item_type == ItemDefinition.ItemType.CONSUMABLE
	assert_true(has_equipment, "The first deterministic reward should expose equipment interaction.")
	assert_true(has_consumable, "The first deterministic reward should expose item use.")

	(inventory_screen.get_node("%ContinueButton") as Button).pressed.emit()
	assert_false(inventory_screen.visible)
	assert_false(screen.simulation.combat_finished_flag)
	assert_eq(screen.reward_session.progression.total_experience, 85)


func test_target_selection_routes_attacks_to_the_drone() -> void:
	var screen := await _spawn_screen()
	var hound_hp := screen.simulation.get_combatant(2).current_hp
	var drone_hp := screen.simulation.get_combatant(3).current_hp
	(screen.get_node("%TargetTwoButton") as Button).pressed.emit()
	(screen.get_node("%StrikeButton") as Button).pressed.emit()
	assert_eq(screen.simulation.get_combatant(2).current_hp, hound_hp)
	assert_lt(screen.simulation.get_combatant(3).current_hp, drone_hp)


func test_screen_fits_the_internal_viewport() -> void:
	var screen := await _spawn_screen()
	var minimum_size := screen.get_combined_minimum_size()
	assert_lte(minimum_size.x, 640.0)
	assert_lte(minimum_size.y, 360.0)
	var content_rect := (screen.get_node("Margin/Layout") as VBoxContainer).get_global_rect()
	assert_gte(content_rect.position.x, 10.0)
	assert_lte(content_rect.end.x, 630.0)
	assert_true((screen.get_node("%RestartButton") as Button).get_global_rect().end.y <= 360.0)


func test_invalid_enemy_action_halts_in_a_restartable_state() -> void:
	var screen := await _spawn_screen()
	var enemy := screen.simulation.get_combatant(2)
	for index: int in enemy.skill_ids.size():
		enemy.skill_ids[index] = &"missing_enemy_skill"

	(screen.get_node("%StrikeButton") as Button).pressed.emit()

	assert_true(screen.encounter_faulted)
	assert_true((screen.get_node("%RestartButton") as Button).visible)
	assert_true((screen.get_node("%StrikeButton") as Button).disabled)
	assert_string_contains(
		(screen.get_node("%CombatLog") as CombatLog).entries.get_parsed_text(),
		"ENCOUNTER HALTED",
	)


func test_defeated_player_does_not_display_guard_status() -> void:
	var screen := await _spawn_screen()
	var player := screen.simulation.get_combatant(1)
	player.current_hp = 1

	(screen.get_node("%BraceButton") as Button).pressed.emit()

	assert_true(player.is_defeated)
	assert_false((screen.get_node("%PlayerGuard") as Label).visible)


func _spawn_screen() -> CombatScreen:
	var screen := COMBAT_SCREEN_SCENE.instantiate() as CombatScreen
	add_child_autofree(screen)
	await get_tree().process_frame
	return screen
