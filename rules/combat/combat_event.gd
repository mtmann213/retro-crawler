class_name CombatEvent
extends RefCounted

enum EventType {
	TURN_STARTED,
	ACTION_STARTED,
	RESOURCE_SPENT,
	RESOURCE_GAINED,
	DAMAGE_DEALT,
	HEALING_DONE,
	DEFENSE_APPLIED,
	STATUS_APPLIED,
	STATUS_EXPIRED,
	COOLDOWN_APPLIED,
	INTENT_CHANGED,
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
var status_id: StringName = &""
var remaining_turns: int = 0


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


static func healing_done(new_actor_id: int, new_target_id: int, new_amount: int) -> CombatEvent:
	var event := CombatEvent.new(EventType.HEALING_DONE)
	event.actor_id = new_actor_id
	event.target_id = new_target_id
	event.amount = new_amount
	return event


static func status_applied(
	new_actor_id: int,
	new_target_id: int,
	new_status_id: StringName,
	new_remaining_turns: int,
) -> CombatEvent:
	var event := CombatEvent.new(EventType.STATUS_APPLIED)
	event.actor_id = new_actor_id
	event.target_id = new_target_id
	event.status_id = new_status_id
	event.remaining_turns = new_remaining_turns
	return event


static func status_expired(new_target_id: int, new_status_id: StringName) -> CombatEvent:
	var event := CombatEvent.new(EventType.STATUS_EXPIRED)
	event.target_id = new_target_id
	event.status_id = new_status_id
	return event


static func cooldown_applied(new_actor_id: int, new_skill_id: StringName, turns: int) -> CombatEvent:
	var event := CombatEvent.new(EventType.COOLDOWN_APPLIED)
	event.actor_id = new_actor_id
	event.skill_id = new_skill_id
	event.remaining_turns = turns
	return event


static func intent_changed(new_actor_id: int, new_target_id: int, new_skill_id: StringName) -> CombatEvent:
	var event := CombatEvent.new(EventType.INTENT_CHANGED)
	event.actor_id = new_actor_id
	event.target_id = new_target_id
	event.skill_id = new_skill_id
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
