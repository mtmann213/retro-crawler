extends GutTest

const FLOOR: FloorDefinition = preload("res://content/floors/floor_service_level.tres")


func test_identical_run_seeds_produce_identical_variations() -> void:
	var first := RunVariationRules.generate(424_242, FLOOR)
	var second := RunVariationRules.generate(424_242, FLOOR)
	assert_eq(JSON.stringify(first), JSON.stringify(second))
	assert_eq(first.seed, 424_242)


func test_seed_sample_changes_presentation_resources_and_encounter_composition() -> void:
	var themes: Dictionary[String, bool] = {}
	var cache_counts: Dictionary[int, bool] = {}
	var processing_encounters: Dictionary[String, bool] = {}
	var complete_variants: Dictionary[String, bool] = {}
	for seed_value: int in range(1, 65):
		var variation := RunVariationRules.generate(seed_value, FLOOR)
		themes[String(variation.theme_id)] = true
		cache_counts[int(variation.cache_patch_count)] = true
		processing_encounters[String(variation.encounters.room_processing_hall)] = true
		complete_variants[JSON.stringify(variation)] = true
	assert_gt(themes.size(), 1)
	assert_gt(cache_counts.size(), 1)
	assert_true(processing_encounters.has("encounter_two_enemy"))
	assert_true(processing_encounters.has("encounter_brute"))
	assert_gt(complete_variants.size(), 8)


func test_variation_preserves_required_route_and_boss_contract() -> void:
	for seed_value: int in range(100, 150):
		var variation := RunVariationRules.generate(seed_value, FLOOR)
		assert_eq(
			RunVariationRules.encounter_for_room(
				variation, FLOOR.get_room(&"room_broken_junction"),
			),
			PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID,
		)
		assert_true(
			RunVariationRules.encounter_for_room(
				variation, FLOOR.get_room(&"room_processing_hall"),
			) in [PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID, PrototypeEncounter.BRUTE_ENCOUNTER_ID],
		)
		assert_eq(
			RunVariationRules.encounter_for_room(
				variation, FLOOR.get_room(&"room_warden_chamber"),
			),
			PrototypeEncounter.WARDEN_ENCOUNTER_ID,
		)


func test_floor_snapshot_restores_the_same_seed_and_variation() -> void:
	var original := FloorState.new(FLOOR, 987_654)
	var restored := FloorState.from_snapshot(FLOOR, original.to_snapshot())
	assert_eq(restored.run_seed, original.run_seed)
	assert_eq(JSON.stringify(restored.run_variation), JSON.stringify(original.run_variation))
	assert_eq(
		RunVariationRules.combat_seed(restored.run_seed, &"room_processing_hall"),
		RunVariationRules.combat_seed(original.run_seed, &"room_processing_hall"),
	)
