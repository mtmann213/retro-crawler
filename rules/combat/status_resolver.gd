class_name StatusResolver
extends RefCounted


static func apply_status(
	target: CombatantState,
	definition: StatusDefinition,
	source_instance_id: int,
	events: Array[CombatEvent],
) -> void:
	if target == null or target.is_defeated or definition == null:
		return

	var existing := get_status(target, definition.content_id)
	if existing != null:
		existing.stacks = mini(existing.stacks + 1, definition.maximum_stacks)
		existing.remaining_turns = definition.base_duration
	else:
		target.statuses.append(StatusState.new(definition, source_instance_id))

	events.append(CombatEvent.status_applied(
		source_instance_id,
		target.instance_id,
		definition.content_id,
		definition.base_duration,
	))


static func remove_status(
	target: CombatantState,
	status_id: StringName,
	events: Array[CombatEvent],
) -> bool:
	for index: int in range(target.statuses.size() - 1, -1, -1):
		if target.statuses[index].definition.content_id == status_id:
			target.statuses.remove_at(index)
			events.append(CombatEvent.status_expired(target.instance_id, status_id))
			return true
	return false


static func tick_phase(
	combatant: CombatantState,
	phase: StatusDefinition.TickPhase,
	events: Array[CombatEvent],
) -> void:
	for index: int in range(combatant.statuses.size() - 1, -1, -1):
		var status := combatant.statuses[index]
		if status.definition.tick_phase != phase:
			continue

		if status.definition.periodic_damage > 0 and not combatant.is_defeated:
			var applied := combatant.apply_damage(status.definition.periodic_damage * status.stacks)
			events.append(CombatEvent.damage_dealt(
				status.source_instance_id,
				combatant.instance_id,
				applied,
				false,
			))

		status.remaining_turns -= 1
		if status.remaining_turns <= 0:
			var status_id := status.definition.content_id
			combatant.statuses.remove_at(index)
			events.append(CombatEvent.status_expired(combatant.instance_id, status_id))


static func get_status(combatant: CombatantState, status_id: StringName) -> StatusState:
	for status: StatusState in combatant.statuses:
		if status.definition.content_id == status_id:
			return status
	return null


static func has_status(combatant: CombatantState, status_id: StringName) -> bool:
	return get_status(combatant, status_id) != null


static func get_effective_defense(combatant: CombatantState) -> int:
	var multiplier := 1.0
	for status: StatusState in combatant.statuses:
		multiplier *= pow(status.definition.defense_multiplier, status.stacks)
	return maxi(0, int(round(float(combatant.defense) * multiplier)))


static func get_effective_speed(combatant: CombatantState) -> int:
	var multiplier := 1.0
	for status: StatusState in combatant.statuses:
		multiplier *= pow(status.definition.speed_multiplier, status.stacks)
	return maxi(1, int(round(float(combatant.speed) * multiplier)))


static func get_damage_taken_multiplier(combatant: CombatantState) -> float:
	var multiplier := 1.0
	for status: StatusState in combatant.statuses:
		multiplier *= pow(status.definition.damage_taken_multiplier, status.stacks)
	return multiplier
