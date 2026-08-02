class_name BossPresenter
extends RefCounted

var current_phase: int = -1


func update(boss: CombatantState) -> StringName:
	if boss == null or boss.definition_id != BossPhaseRules.WARDEN_ID:
		return &""
	var phase := BossPhaseRules.phase_for(boss)
	if phase == current_phase:
		return &""
	current_phase = phase
	match phase:
		BossPhaseRules.Phase.CONTAINMENT:
			return &"boss_phase_containment"
		BossPhaseRules.Phase.PURGE:
			return &"boss_phase_purge"
	return &"boss_phase_assessment"


func label_text() -> String:
	if current_phase < 0:
		return ""
	return "WARDEN PHASE // %s" % BossPhaseRules.phase_name(current_phase).to_upper()
