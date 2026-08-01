class_name CombatState
extends RefCounted

var combatants: Array[CombatantState] = []
var turn_count: int = 0
var is_finished: bool = false
var winning_team: int = -1


func _init(initial_combatants: Array[CombatantState]) -> void:
	combatants = initial_combatants


func get_combatant(combatant_id: int) -> CombatantState:
	for combatant: CombatantState in combatants:
		if combatant.instance_id == combatant_id:
			return combatant
	return null


func get_living_team_members(team: CombatantState.Team) -> Array[CombatantState]:
	var members: Array[CombatantState] = []
	for combatant: CombatantState in combatants:
		if combatant.team == team and combatant.can_act():
			members.append(combatant)
	return members
