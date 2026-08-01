extends GutTest


func test_timeline_uses_tick_then_speed_then_spawn_order() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	assert_eq(simulation.get_next_actor().instance_id, 1, "The faster player should win the initial tie.")

	var player := simulation.get_combatant(1)
	var enemy := simulation.get_combatant(2)
	player.next_action_tick = 100
	enemy.next_action_tick = 10
	assert_eq(simulation.get_next_actor().instance_id, 2, "The lowest timeline tick acts first.")


func test_out_of_turn_actions_are_rejected_without_mutation() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var player_hp := simulation.get_combatant(1).current_hp
	var events := simulation.resolve_action(ActionCommand.new(2, &"scrap_bite", 1))
	assert_eq(events[0].event_type, CombatEvent.EventType.ACTION_REJECTED)
	assert_eq(events[0].reason, &"actor_out_of_turn")
	assert_eq(simulation.get_combatant(1).current_hp, player_hp)


func test_dead_actors_cannot_act() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var player := simulation.get_combatant(1)
	player.apply_damage(player.max_hp)
	var events := simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	assert_eq(events[0].event_type, CombatEvent.EventType.ACTION_REJECTED)
	assert_eq(events[0].reason, &"actor_cannot_act")


func test_resource_costs_are_validated_before_resolution() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var strike := simulation.get_skill(&"quick_strike")
	strike.stamina_cost = 11
	var player := simulation.get_combatant(1)
	var enemy_hp := simulation.get_combatant(2).current_hp
	var events := simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	assert_eq(events[0].event_type, CombatEvent.EventType.ACTION_REJECTED)
	assert_eq(events[0].reason, &"insufficient_stamina")
	assert_eq(player.get_resource(&"stamina"), 10)
	assert_eq(simulation.get_combatant(2).current_hp, enemy_hp)


func test_brace_reduces_the_next_enemy_attack() -> void:
	var open_simulation := PrototypeEncounter.create_simulation(77)
	open_simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	open_simulation.resolve_action(open_simulation.create_enemy_command())
	var open_damage := 100 - open_simulation.get_combatant(1).current_hp

	var guarded_simulation := PrototypeEncounter.create_simulation(77)
	guarded_simulation.resolve_action(ActionCommand.new(1, &"brace", 1))
	guarded_simulation.resolve_action(guarded_simulation.create_enemy_command())
	var guarded_damage := 100 - guarded_simulation.get_combatant(1).current_hp

	assert_lt(guarded_damage, open_damage)
	assert_true(guarded_simulation.get_combatant(1).is_defending)
	guarded_simulation.prepare_next_turn()
	assert_false(guarded_simulation.get_combatant(1).is_defending)


func test_combat_ends_when_a_team_is_defeated() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var enemy := simulation.get_combatant(2)
	enemy.current_hp = 1
	var events := simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	assert_true(enemy.is_defeated)
	assert_true(simulation.combat_finished_flag)
	assert_eq(simulation.winning_team, CombatantState.Team.PLAYER)
	assert_true(_contains_event(events, CombatEvent.EventType.COMBATANT_DEFEATED))
	assert_true(_contains_event(events, CombatEvent.EventType.COMBAT_FINISHED))


func test_identical_seed_and_commands_produce_identical_state() -> void:
	var first := PrototypeEncounter.create_simulation(4242)
	var second := PrototypeEncounter.create_simulation(4242)

	for simulation: CombatSimulation in [first, second]:
		simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
		simulation.resolve_action(simulation.create_enemy_command())
		simulation.resolve_action(ActionCommand.new(1, &"brace", 1))
		simulation.resolve_action(simulation.create_enemy_command())

	assert_eq(first.get_combatant(1).current_hp, second.get_combatant(1).current_hp)
	assert_eq(first.get_combatant(2).current_hp, second.get_combatant(2).current_hp)
	assert_eq(first.get_combatant(1).get_resource(&"stamina"), second.get_combatant(1).get_resource(&"stamina"))
	assert_eq(first.get_combatant(1).next_action_tick, second.get_combatant(1).next_action_tick)


func _contains_event(events: Array[CombatEvent], event_type: CombatEvent.EventType) -> bool:
	for event: CombatEvent in events:
		if event.event_type == event_type:
			return true
	return false
