extends GutTest

const FLOOR := preload("res://content/floors/floor_service_level.tres")


func test_dialogue_events_fire_only_once_and_missing_flags_are_safe() -> void:
	var event := DialogueEventDefinition.new()
	event.content_id = &"test_once"
	event.trigger_id = &"test_trigger"
	event.text = "Test"
	event.required_flags = [&"ready"]
	var events: Array[DialogueEventDefinition] = [event]
	var state := DialogueState.new()
	var empty_flags: Dictionary[StringName, bool] = {}
	assert_true(DialogueResolver.resolve(events, &"test_trigger", empty_flags, state).is_empty())
	var ready_flags: Dictionary[StringName, bool] = {&"ready": true}
	assert_eq(DialogueResolver.resolve(events, &"test_trigger", ready_flags, state).size(), 1)
	assert_true(DialogueResolver.resolve(events, &"test_trigger", ready_flags, state).is_empty())


func test_warden_phases_are_exclusive_at_every_boundary() -> void:
	var simulation := PrototypeEncounter.create_simulation(1, PrototypeEncounter.WARDEN_ENCOUNTER_ID)
	var boss := simulation.get_combatant(2)
	boss.current_hp = boss.max_hp
	assert_eq(BossPhaseRules.phase_for(boss), BossPhaseRules.Phase.ASSESSMENT)
	boss.current_hp = 99
	assert_eq(BossPhaseRules.phase_for(boss), BossPhaseRules.Phase.CONTAINMENT)
	boss.current_hp = 49
	assert_eq(BossPhaseRules.phase_for(boss), BossPhaseRules.Phase.PURGE)


func test_warden_replans_an_intent_that_is_unavailable_in_the_new_phase() -> void:
	var simulation := PrototypeEncounter.create_simulation(2, PrototypeEncounter.WARDEN_ENCOUNTER_ID)
	var player := simulation.get_combatant(1)
	var boss := simulation.get_combatant(2)
	assert_true(BossPhaseRules.skill_pattern_for(BossPhaseRules.Phase.ASSESSMENT).has(boss.intent_skill_id))
	boss.current_hp = 1
	player.next_action_tick = 100
	var command := simulation.create_enemy_command()
	assert_not_null(command)
	assert_true(BossPhaseRules.skill_pattern_for(BossPhaseRules.Phase.PURGE).has(command.skill_id))


func test_authored_content_references_validate() -> void:
	assert_true(ContentRegistry.validate_all().is_empty())
	assert_eq(ContentRegistry.get_dialogue_events().size(), 10)


func test_victory_and_extraction_flags_survive_a_snapshot() -> void:
	var original := FloorState.new(FLOOR)
	original.boss_defeated = true
	original.victory_ending = true
	original.extraction_ending = true
	var restored := FloorState.from_snapshot(FLOOR, original.to_snapshot())
	assert_true(restored.boss_defeated)
	assert_true(restored.victory_ending)
	assert_true(restored.extraction_ending)

