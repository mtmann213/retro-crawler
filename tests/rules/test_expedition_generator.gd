extends GutTest


func test_one_thousand_seeded_expeditions_are_valid_and_traversable() -> void:
	for seed: int in range(1, 1001):
		var plan := ExpeditionGenerator.generate(seed)
		assert_true(plan.validate().is_empty(), "Seed %d must generate a valid expedition." % seed)
		assert_between(plan.rooms.size(), ExpeditionPlan.MIN_ROOMS, ExpeditionPlan.MAX_ROOMS)
		assert_gte(plan.optional_room_count(), 2)
		assert_gte(plan.encounter_room_count(), 2)
		assert_true(plan.is_reachable(plan.start_room_id, plan.objective_room_id))
		assert_true(plan.is_reachable(plan.objective_room_id, plan.extraction_room_id))


func test_same_seed_produces_an_identical_plan() -> void:
	var first := ExpeditionGenerator.generate(8675309)
	var second := ExpeditionGenerator.generate(8675309)
	assert_eq(first.to_snapshot(), second.to_snapshot())
	assert_eq(first.summary(), second.summary())


func test_seed_sample_varies_structure_theme_and_objective() -> void:
	var signatures: Dictionary[String, bool] = {}
	var themes: Dictionary[StringName, bool] = {}
	var objectives: Dictionary[StringName, bool] = {}
	for seed: int in range(1, 65):
		var plan := ExpeditionGenerator.generate(seed)
		signatures[JSON.stringify(plan.to_snapshot())] = true
		themes[plan.theme_id] = true
		objectives[plan.objective_id] = true
	assert_gte(signatures.size(), 48)
	assert_eq(themes.size(), ExpeditionGenerator.THEMES.size())
	assert_eq(objectives.size(), ExpeditionGenerator.OBJECTIVES.size())


func test_plan_snapshot_round_trip_is_exact() -> void:
	var original := ExpeditionGenerator.generate(424242)
	var restored := ExpeditionPlan.from_snapshot(original.to_snapshot())
	assert_eq(restored.to_snapshot(), original.to_snapshot())
	assert_true(restored.validate().is_empty())


func test_validator_rejects_a_broken_required_route() -> void:
	var plan := ExpeditionGenerator.generate(77)
	var second_id := plan.critical_route[1]
	(plan.rooms[plan.start_room_id].neighbors as Array[StringName]).erase(second_id)
	assert_false(plan.validate().is_empty())
