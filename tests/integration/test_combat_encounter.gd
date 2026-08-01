extends GutTest


func test_one_hundred_seeded_encounters_finish_without_invalid_state() -> void:
	for encounter_index: int in range(100):
		var simulation := PrototypeEncounter.create_simulation(10_000 + encounter_index)
		var action_count := 0

		while not simulation.combat_finished_flag and action_count < 100:
			var actor := simulation.get_next_actor()
			assert_not_null(actor)
			var command: ActionCommand
			if actor.team == CombatantState.Team.PLAYER:
				command = ActionCommand.new(actor.instance_id, &"quick_strike", 2)
			else:
				command = simulation.create_enemy_command()

			var events := simulation.resolve_action(command)
			assert_false(events.is_empty())
			assert_ne(events[0].event_type, CombatEvent.EventType.ACTION_REJECTED)
			_assert_valid_combatants(simulation)
			action_count += 1

		assert_true(simulation.combat_finished_flag, "Encounter %d did not finish." % encounter_index)
		assert_eq(simulation.winning_team, CombatantState.Team.PLAYER)
		assert_lt(action_count, 100)


func _assert_valid_combatants(simulation: CombatSimulation) -> void:
	for combatant: CombatantState in simulation.combatants:
		assert_gte(combatant.current_hp, 0)
		assert_lte(combatant.current_hp, combatant.max_hp)
		assert_eq(combatant.is_defeated, combatant.current_hp == 0)
		assert_gte(combatant.next_action_tick, 0)
