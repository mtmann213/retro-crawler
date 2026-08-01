class_name ExperienceRules
extends RefCounted

const MAXIMUM_LEVEL := 20


static func threshold_for_level(level: int) -> int:
	var safe_level := maxi(level, 1)
	return 100 * (safe_level - 1) * (safe_level - 1)


static func level_for_experience(total_experience: int) -> int:
	var level := 1
	while level < MAXIMUM_LEVEL and total_experience >= threshold_for_level(level + 1):
		level += 1
	return level


static func grant_experience(state: ProgressionState, amount: int) -> int:
	if state == null or amount <= 0:
		return 0
	var previous_level := state.level
	state.total_experience += amount
	state.level = level_for_experience(state.total_experience)
	return state.level - previous_level


static func experience_to_next_level(state: ProgressionState) -> int:
	if state.level >= MAXIMUM_LEVEL:
		return 0
	return threshold_for_level(state.level + 1) - state.total_experience
