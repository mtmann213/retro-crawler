class_name CombatantState
extends RefCounted

enum Team {
	PLAYER,
	ENEMY,
}

var instance_id: int
var definition_id: StringName
var display_name: String
var team: Team

var max_hp: int
var current_hp: int
var power: int
var defense: int
var speed: int

var resources: Dictionary[StringName, int] = {}
var max_resources: Dictionary[StringName, int] = {}
var cooldowns: Dictionary[StringName, int] = {}
var statuses: Array[StatusState] = []
var skill_ids: Array[StringName] = []
var next_action_tick: int = 0
var spawn_order: int = 0
var is_defending: bool = false
var is_defeated: bool = false
var actions_taken: int = 0
var ai_pattern_index: int = 0
var intent_skill_id: StringName = &""
var intent_target_id: int = -1
var applied_equipment: Dictionary[int, StringName] = {}


func _init(
	new_instance_id: int,
	new_definition_id: StringName,
	new_display_name: String,
	new_team: Team,
	new_max_hp: int,
	new_power: int,
	new_defense: int,
	new_speed: int,
	new_spawn_order: int = 0,
	new_skill_ids: Array[StringName] = [],
) -> void:
	assert(new_max_hp > 0)

	instance_id = new_instance_id
	definition_id = new_definition_id
	display_name = new_display_name
	team = new_team
	max_hp = new_max_hp
	current_hp = new_max_hp
	power = new_power
	defense = new_defense
	speed = new_speed
	spawn_order = new_spawn_order
	skill_ids = new_skill_ids.duplicate()


func apply_damage(amount: int) -> int:
	if is_defeated:
		return 0

	var applied := mini(maxi(amount, 0), current_hp)
	current_hp -= applied

	if current_hp <= 0:
		current_hp = 0
		is_defeated = true

	return applied


func heal(amount: int) -> int:
	if is_defeated:
		return 0

	var previous_hp := current_hp
	current_hp = mini(current_hp + maxi(amount, 0), max_hp)
	return current_hp - previous_hp


func can_act() -> bool:
	return not is_defeated


func knows_skill(skill_id: StringName) -> bool:
	return skill_ids.has(skill_id)


func set_resource(resource_id: StringName, current_amount: int, maximum_amount: int) -> void:
	var safe_maximum := maxi(maximum_amount, 0)
	max_resources[resource_id] = safe_maximum
	resources[resource_id] = clampi(current_amount, 0, safe_maximum)


func get_resource(resource_id: StringName) -> int:
	return resources.get(resource_id, 0)


func get_max_resource(resource_id: StringName) -> int:
	return max_resources.get(resource_id, 0)


func can_spend_resource(resource_id: StringName, amount: int) -> bool:
	return amount >= 0 and get_resource(resource_id) >= amount


func spend_resource(resource_id: StringName, amount: int) -> bool:
	if not can_spend_resource(resource_id, amount):
		return false

	resources[resource_id] = get_resource(resource_id) - amount
	return true


func gain_resource(resource_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0

	var previous_amount := get_resource(resource_id)
	var maximum_amount := get_max_resource(resource_id)
	resources[resource_id] = mini(previous_amount + amount, maximum_amount)
	return resources[resource_id] - previous_amount


func begin_turn() -> void:
	is_defending = false


func advance_cooldowns() -> void:

	for skill_id: StringName in cooldowns.keys():
		cooldowns[skill_id] = maxi(cooldowns[skill_id] - 1, 0)
