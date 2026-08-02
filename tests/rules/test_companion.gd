extends GutTest


func test_mox_reactions_are_authored_memorable_and_once_only() -> void:
	var state := CompanionState.new()
	var first := CompanionRules.reaction_once(state, &"room_broken_junction")
	assert_string_contains(first, "MOX //")
	assert_string_contains(first, "professionally distinct ways")
	assert_eq(state.bond, 1)
	assert_eq(CompanionRules.reaction_once(state, &"room_broken_junction"), "")
	assert_eq(state.bond, 1)


func test_companion_snapshot_round_trip_preserves_relationship_and_directive() -> void:
	var original := CompanionState.new()
	original.set_directive(&"safeguard")
	CompanionRules.reaction_once(original, &"room_warden_chamber")
	CompanionRules.reaction_once(original, &"cache_recovered")
	var restored := CompanionState.from_snapshot(original.to_snapshot())
	assert_eq(restored.to_snapshot(), original.to_snapshot())
	assert_eq(restored.directive, &"safeguard")
	assert_eq(restored.bond, 4)
	assert_true(CompanionState.validate_snapshot(restored.to_snapshot()).is_empty())


func test_unknown_directives_and_reactions_fail_safely() -> void:
	var state := CompanionState.new()
	assert_false(state.set_directive(&"reckless"))
	assert_eq(state.directive, CompanionState.DEFAULT_DIRECTIVE)
	assert_eq(CompanionRules.reaction_once(state, &"unknown_trigger"), "")
