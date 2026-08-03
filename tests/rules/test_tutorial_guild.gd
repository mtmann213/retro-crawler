extends GutTest


func test_lesson_completion_is_validated_and_idempotent() -> void:
	var state := TutorialGuildState.new()
	assert_true(state.complete_lesson(&"guild_orientation"))
	assert_false(state.complete_lesson(&"guild_orientation"))
	assert_false(state.complete_lesson(&"not_a_lesson"))
	assert_eq(state.completed_count(), 1)
	assert_true(state.is_completed(&"guild_orientation"))


func test_guild_progress_round_trip_preserves_completed_lessons() -> void:
	var original := TutorialGuildState.new()
	original.complete_lesson(&"movement_and_time")
	original.complete_lesson(&"combat_intents")
	var restored := TutorialGuildState.from_snapshot(original.to_snapshot())
	assert_eq(restored.to_snapshot(), original.to_snapshot())
	assert_eq(restored.completed_count(), 2)


func test_class_doctrine_is_specific_to_the_selected_profile() -> void:
	var vanguard := TutorialGuildRules.get_lesson(
		&"class_doctrine", CharacterProfile.new("One", &"vanguard", &"cyan"),
	)
	var scavenger := TutorialGuildRules.get_lesson(
		&"class_doctrine", CharacterProfile.new("Two", &"scavenger", &"amber"),
	)
	var signalist := TutorialGuildRules.get_lesson(
		&"class_doctrine", CharacterProfile.new("Three", &"signalist", &"violet"),
	)
	assert_string_contains(vanguard.body, "Vanguard doctrine")
	assert_string_contains(scavenger.body, "Scavenger doctrine")
	assert_string_contains(signalist.body, "Signalist doctrine")
	assert_ne(vanguard.body, scavenger.body)
	assert_ne(scavenger.body, signalist.body)
