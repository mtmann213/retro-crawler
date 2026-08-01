extends GutTest


func test_fifty_seeded_full_catalog_encounters_finish_without_invalid_state() -> void:
	var used_player_skills: Dictionary[StringName, bool] = {}
	var encounter_ids: Array[StringName] = [
		PrototypeEncounter.DUEL_ENCOUNTER_ID,
		PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID,
		PrototypeEncounter.BRUTE_ENCOUNTER_ID,
	]
	for seed_offset: int in range(50):
		for encounter_id: StringName in encounter_ids:
			var simulation := PrototypeEncounter.create_simulation(
				10_000 + seed_offset,
				encounter_id,
			)
			var action_count := 0

			while not simulation.combat_finished_flag and action_count < 200:
				var actor := simulation.get_next_actor()
				assert_not_null(actor)
				var command: ActionCommand
				if actor.team == CombatantState.Team.PLAYER:
					command = _create_player_command(simulation, actor)
					used_player_skills[command.skill_id] = true
				else:
					command = simulation.create_enemy_command()

				assert_not_null(command)
				var events := simulation.resolve_action(command)
				assert_false(events.is_empty())
				assert_false(_contains_event(events, CombatEvent.EventType.ACTION_REJECTED))
				_assert_valid_combatants(simulation)
				action_count += 1

			assert_true(
				simulation.combat_finished_flag,
				"Encounter %s seed %d did not finish." % [encounter_id, seed_offset],
			)
			assert_lt(action_count, 200)

	for skill_id: StringName in [
		&"quick_strike", &"heavy_swing", &"brace", &"hamstring", &"field_patch",
	]:
		assert_true(used_player_skills.has(skill_id), "%s was never exercised." % skill_id)


func _create_player_command(
	simulation: CombatSimulation,
	player: CombatantState,
) -> ActionCommand:
	var skill_id := &"quick_strike"
	if player.current_hp <= 65 and player.get_resource(&"field_patch_charges") > 0:
		skill_id = &"field_patch"
	elif _can_use(simulation, player, &"heavy_swing"):
		skill_id = &"heavy_swing"
	elif player.actions_taken % 5 == 2:
		skill_id = &"brace"
	elif player.actions_taken > 0 and player.actions_taken % 5 == 0 and _can_use(simulation, player, &"hamstring"):
		skill_id = &"hamstring"

	var skill := simulation.get_skill(skill_id)
	var target_id := player.instance_id
	if skill.target_rule == SkillDefinition.TargetRule.SINGLE_ENEMY:
		target_id = simulation.get_first_combatant_on_team(CombatantState.Team.ENEMY).instance_id
	return ActionCommand.new(player.instance_id, skill_id, target_id)


func _can_use(
	simulation: CombatSimulation,
	player: CombatantState,
	skill_id: StringName,
) -> bool:
	var skill := simulation.get_skill(skill_id)
	return (
		player.cooldowns.get(skill_id, 0) == 0
		and player.can_spend_resource(&"stamina", skill.stamina_cost)
	)


func _assert_valid_combatants(simulation: CombatSimulation) -> void:
	for combatant: CombatantState in simulation.combatants:
		assert_gte(combatant.current_hp, 0)
		assert_lte(combatant.current_hp, combatant.max_hp)
		assert_eq(combatant.is_defeated, combatant.current_hp == 0)
		assert_gte(combatant.next_action_tick, 0)


func _contains_event(events: Array[CombatEvent], event_type: CombatEvent.EventType) -> bool:
	for event: CombatEvent in events:
		if event.event_type == event_type:
			return true
	return false
