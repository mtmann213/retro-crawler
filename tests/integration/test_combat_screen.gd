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
	assert_gt(player.current_hp, 90, "The guarded Bite should deal substantially less than ten damage.")
	assert_string_contains(
		(screen.get_node("%CombatLog") as CombatLog).entries.get_parsed_text(),
		"braces",
	)


func test_restart_button_replaces_finished_state() -> void:
	var screen := await _spawn_screen()
	var enemy := screen.simulation.get_combatant(2)
	enemy.current_hp = 1
	(screen.get_node("%StrikeButton") as Button).pressed.emit()
	assert_true(screen.simulation.combat_finished_flag)
	assert_true((screen.get_node("%RestartButton") as Button).visible)

	(screen.get_node("%RestartButton") as Button).pressed.emit()

	assert_false(screen.simulation.combat_finished_flag)
	assert_eq(screen.simulation.get_combatant(1).current_hp, 100)
	assert_eq(screen.simulation.get_combatant(2).current_hp, 42)
	assert_false((screen.get_node("%RestartButton") as Button).visible)


func _spawn_screen() -> CombatScreen:
	var screen := COMBAT_SCREEN_SCENE.instantiate() as CombatScreen
	add_child_autofree(screen)
	await get_tree().process_frame
	return screen
