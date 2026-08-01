extends GutTest


func test_cooldowns_count_completed_owner_actions() -> void:
	var simulation := PrototypeEncounter.create_simulation(
		101,
		PrototypeEncounter.BRUTE_ENCOUNTER_ID,
	)
	var player := simulation.get_combatant(1)
	player.set_resource(&"stamina", 40, 40)
	simulation.resolve_action(ActionCommand.new(1, &"heavy_swing", 2))
	_advance_to_player(simulation)
	assert_eq(_rejection_reason(simulation, &"heavy_swing"), &"skill_on_cooldown")
	simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	_advance_to_player(simulation)
	assert_eq(_rejection_reason(simulation, &"heavy_swing"), &"skill_on_cooldown")
	simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	_advance_to_player(simulation)
	var events := simulation.resolve_action(ActionCommand.new(1, &"heavy_swing", 2))
	assert_eq(events[0].event_type, CombatEvent.EventType.TURN_STARTED)


func test_status_expires_on_its_configured_phase() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var enemy := simulation.get_combatant(2)
	var status := simulation.get_status_definition(&"slowed")
	var events: Array[CombatEvent] = []
	StatusResolver.apply_status(enemy, status, 1, events)
	StatusResolver.tick_phase(enemy, StatusDefinition.TickPhase.START_OF_TURN, events)
	assert_true(StatusResolver.has_status(enemy, &"slowed"))
	StatusResolver.tick_phase(enemy, StatusDefinition.TickPhase.END_OF_ACTION, events)
	assert_true(StatusResolver.has_status(enemy, &"slowed"))
	StatusResolver.tick_phase(enemy, StatusDefinition.TickPhase.END_OF_ACTION, events)
	assert_false(StatusResolver.has_status(enemy, &"slowed"))
	assert_true(_contains_event(events, CombatEvent.EventType.STATUS_EXPIRED))


func test_timeline_ties_are_stable() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var player := simulation.get_combatant(1)
	var enemy := simulation.get_combatant(2)
	player.next_action_tick = 10
	enemy.next_action_tick = 10
	player.speed = enemy.speed
	assert_eq(TimelineResolver.get_next_actor(simulation.combatants).instance_id, 1)
	assert_eq(TimelineResolver.get_next_actor(simulation.combatants).instance_id, 1)


func test_enemy_ai_never_returns_an_invalid_command() -> void:
	for seed_value: int in range(50):
		for encounter_id: StringName in [PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID, PrototypeEncounter.BRUTE_ENCOUNTER_ID]:
			var simulation := PrototypeEncounter.create_simulation(seed_value, encounter_id)
			for combatant: CombatantState in simulation.combatants:
				if combatant.team == CombatantState.Team.ENEMY:
					var skill := simulation.get_skill(combatant.intent_skill_id)
					assert_not_null(skill)
					assert_true(combatant.knows_skill(skill.content_id))
					assert_true(skill.validate().is_empty())
					assert_not_null(simulation.get_combatant(combatant.intent_target_id))


func test_telegraph_matches_the_action_that_resolves() -> void:
	var simulation := PrototypeEncounter.create_simulation(202)
	var player := simulation.get_combatant(1)
	var enemy := simulation.get_combatant(2)
	player.next_action_tick = 100
	enemy.next_action_tick = 0
	var telegraphed_skill := enemy.intent_skill_id
	var command := simulation.create_enemy_command()
	assert_eq(command.skill_id, telegraphed_skill)
	var events := simulation.resolve_action(command)
	var started := _first_event(events, CombatEvent.EventType.ACTION_STARTED)
	assert_not_null(started)
	assert_eq(started.skill_id, telegraphed_skill)


func test_multiple_effects_resolve_in_authored_order() -> void:
	var simulation := PrototypeEncounter.create_simulation(303)
	var player := simulation.get_combatant(1)
	player.set_resource(&"stamina", 40, 40)
	var events := simulation.resolve_action(ActionCommand.new(1, &"hamstring", 2))
	var damage_index := _event_index(events, CombatEvent.EventType.DAMAGE_DEALT)
	var status_index := _event_index(events, CombatEvent.EventType.STATUS_APPLIED)
	assert_gte(damage_index, 0)
	assert_gt(status_index, damage_index)


func _advance_to_player(simulation: CombatSimulation) -> void:
	var safety := 20
	while not simulation.combat_finished_flag and safety > 0:
		var actor := simulation.get_next_actor()
		if actor.team == CombatantState.Team.PLAYER:
			return
		simulation.resolve_action(simulation.create_enemy_command())
		safety -= 1
	assert_gt(safety, 0)


func _rejection_reason(simulation: CombatSimulation, skill_id: StringName) -> StringName:
	var events := simulation.resolve_action(ActionCommand.new(1, skill_id, 2))
	return events[0].reason


func _event_index(events: Array[CombatEvent], event_type: CombatEvent.EventType) -> int:
	for index: int in events.size():
		if events[index].event_type == event_type:
			return index
	return -1


func _first_event(events: Array[CombatEvent], event_type: CombatEvent.EventType) -> CombatEvent:
	var index := _event_index(events, event_type)
	return events[index] if index >= 0 else null


func _contains_event(events: Array[CombatEvent], event_type: CombatEvent.EventType) -> bool:
	return _event_index(events, event_type) >= 0
