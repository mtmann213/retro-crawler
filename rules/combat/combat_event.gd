class_name CombatEvent
extends RefCounted

enum EventType {
	TURN_STARTED,
	ACTION_STARTED,
	RESOURCE_SPENT,
	RESOURCE_GAINED,
	DAMAGE_DEALT,
	DEFENSE_APPLIED,
	COMBATANT_DEFEATED,
	COMBAT_FINISHED,
	ACTION_REJECTED,
}

var event_type: EventType
var actor_id: int = -1
var target_id: int = -1
var skill_id: StringName = &""
var resource_id: StringName = &""
var amount: int = 0
var critical: bool = false
var winning_team: int = -1
var reason: StringName = &""


func _init(new_event_type: EventType) -> void:
	event_type = new_event_type


static func turn_started(new_actor_id: int) -> CombatEvent:
	var event := CombatEvent.new(EventType.TURN_STARTED)
	event.actor_id = new_actor_id
	return event


static func action_started(new_actor_id: int, new_target_id: int, new_skill_id: StringName) -> CombatEvent:
	var event := CombatEvent.new(EventType.ACTION_STARTED)
	event.actor_id = new_actor_id
	event.target_id = new_target_id
	event.skill_id = new_skill_id
	return event


static func resource_changed(
	new_event_type: EventType,
	new_actor_id: int,
	new_resource_id: StringName,
	new_amount: int,
) -> CombatEvent:
	var event := CombatEvent.new(new_event_type)
	event.actor_id = new_actor_id
	event.resource_id = new_resource_id
	event.amount = new_amount
	return event


static func damage_dealt(
	new_actor_id: int,
	new_target_id: int,
	new_amount: int,
	was_critical: bool,
) -> CombatEvent:
	var event := CombatEvent.new(EventType.DAMAGE_DEALT)
	event.actor_id = new_actor_id
	event.target_id = new_target_id
	event.amount = new_amount
	event.critical = was_critical
	return event


static func defense_applied(new_actor_id: int) -> CombatEvent:
	var event := CombatEvent.new(EventType.DEFENSE_APPLIED)
	event.actor_id = new_actor_id
	return event


static func combatant_defeated(new_target_id: int) -> CombatEvent:
	var event := CombatEvent.new(EventType.COMBATANT_DEFEATED)
	event.target_id = new_target_id
	return event


static func combat_ended(new_winning_team: int) -> CombatEvent:
	var event := CombatEvent.new(EventType.COMBAT_FINISHED)
	event.winning_team = new_winning_team
	return event


static func action_rejected(new_reason: StringName) -> CombatEvent:
	var event := CombatEvent.new(EventType.ACTION_REJECTED)
	event.reason = new_reason
	return event
