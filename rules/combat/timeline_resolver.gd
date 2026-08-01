class_name TimelineResolver
extends RefCounted

const BASELINE_SPEED := 10.0
const MINIMUM_RECOVERY := 20


static func get_next_actor(combatants: Array[CombatantState]) -> CombatantState:
	var best_actor: CombatantState = null
	for combatant: CombatantState in combatants:
		if not combatant.can_act():
			continue
		if best_actor == null or acts_before(combatant, best_actor):
			best_actor = combatant
	return best_actor


static func acts_before(a: CombatantState, b: CombatantState) -> bool:
	if a.next_action_tick != b.next_action_tick:
		return a.next_action_tick < b.next_action_tick

	var a_speed := StatusResolver.get_effective_speed(a)
	var b_speed := StatusResolver.get_effective_speed(b)
	if a_speed != b_speed:
		return a_speed > b_speed
	return a.spawn_order < b.spawn_order


static func calculate_recovery(base_recovery: int, effective_speed: int) -> int:
	var speed := maxi(effective_speed, 1)
	return maxi(MINIMUM_RECOVERY, int(round(float(base_recovery) * BASELINE_SPEED / float(speed))))
