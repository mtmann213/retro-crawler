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


func test_target_selection_routes_attacks_to_the_drone() -> void:
	var screen := await _spawn_screen()
	var hound_hp := screen.simulation.get_combatant(2).current_hp
	var drone_hp := screen.simulation.get_combatant(3).current_hp
	(screen.get_node("%TargetTwoButton") as Button).pressed.emit()
	(screen.get_node("%StrikeButton") as Button).pressed.emit()
	assert_eq(screen.simulation.get_combatant(2).current_hp, hound_hp)
	assert_lt(screen.simulation.get_combatant(3).current_hp, drone_hp)


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
