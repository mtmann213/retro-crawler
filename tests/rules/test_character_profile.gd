extends GutTest


func test_profile_sanitizes_name_and_unknown_options() -> void:
	var profile := CharacterProfile.new("  R!ook\n-7  ", &"missing", &"missing")
	assert_eq(profile.crawler_name, "Rook-7")
	assert_eq(profile.class_id, CharacterClassRules.DEFAULT_CLASS_ID)
	assert_eq(profile.color_id, CharacterClassRules.DEFAULT_COLOR_ID)
	assert_eq(CharacterProfile.new("***").crawler_name, CharacterProfile.DEFAULT_NAME)
	assert_lte(CharacterProfile.new("This Callsign Is Much Too Long").crawler_name.length(), 18)


func test_three_classes_have_distinct_gameplay_profiles() -> void:
	var signatures: Dictionary[String, bool] = {}
	for class_id: StringName in CharacterClassRules.CLASS_ORDER:
		var definition := CharacterClassRules.get_definition(class_id)
		var signature := "%d/%d/%d/%d/%d/%d" % [
			definition.max_hp, definition.power, definition.defense,
			definition.speed, definition.stamina_max, definition.patches,
		]
		signatures[signature] = true
	assert_eq(signatures.size(), 3)


func test_profile_applies_name_class_stats_and_resources() -> void:
	var player := PrototypeEncounter.create_simulation().get_combatant(1)
	var profile := CharacterProfile.new("Nova", &"signalist", &"violet")
	CharacterClassRules.apply_profile(player, profile)
	assert_eq(player.display_name, "Nova")
	assert_eq(player.max_hp, 95)
	assert_eq(player.current_hp, 95)
	assert_eq(player.power, 11)
	assert_eq(player.get_resource(&"stamina"), 20)
	assert_eq(player.get_max_resource(&"stamina"), 50)
	assert_eq(player.get_resource(&"field_patch_charges"), 3)


func test_profile_snapshot_round_trip_is_exact() -> void:
	var original := CharacterProfile.new("Latch Key", &"scavenger", &"amber")
	var restored := CharacterProfile.from_snapshot(original.to_snapshot())
	assert_eq(restored.to_snapshot(), original.to_snapshot())
	assert_true(CharacterProfile.validate_snapshot(restored.to_snapshot()).is_empty())
