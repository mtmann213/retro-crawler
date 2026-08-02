class_name BossPhaseRules
extends RefCounted

enum Phase { ASSESSMENT, CONTAINMENT, PURGE }

const WARDEN_ID := &"enemy_warden_unit"


static func phase_for(combatant: CombatantState) -> Phase:
	var ratio := float(combatant.current_hp) / float(combatant.max_hp)
	if ratio > 0.66:
		return Phase.ASSESSMENT
	if ratio > 0.33:
		return Phase.CONTAINMENT
	return Phase.PURGE


static func skill_pattern_for(phase: Phase) -> Array[StringName]:
	match phase:
		Phase.ASSESSMENT:
			return [&"warden_probe", &"warden_scan"]
		Phase.CONTAINMENT:
			return [&"warden_barrier", &"warden_suppress"]
		Phase.PURGE:
			return [&"warden_purge", &"warden_lockdown"]
	return []


static func phase_name(phase: Phase) -> String:
	return Phase.keys()[phase].capitalize()


static func skill_is_available(combatant: CombatantState, skill_id: StringName) -> bool:
	return skill_pattern_for(phase_for(combatant)).has(skill_id)
