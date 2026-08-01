class_name CombatSimulation
extends RefCounted

signal combat_finished(winning_team: int)

var combatants: Array[CombatantState] = []
var combat_finished_flag: bool = false
var winning_team: int = -1

var _skills: Dictionary[StringName, SkillDefinition] = {}
var _rng := RandomNumberGenerator.new()
var _prepared_actor_id: int = -1
var _prepared_actor_tick: int = -1


func _init(
	initial_combatants: Array[CombatantState],
	initial_skills: Array[SkillDefinition],
	seed_value: int = 1,
) -> void:
	assert(not initial_combatants.is_empty())
	combatants = initial_combatants
	_rng.seed = seed_value

	for skill: SkillDefinition in initial_skills:
		assert(skill != null)
		assert(skill.validate().is_empty())
		assert(not _skills.has(skill.content_id))
		_skills[skill.content_id] = skill


func get_combatant(combatant_id: int) -> CombatantState:
	for combatant: CombatantState in combatants:
		if combatant.instance_id == combatant_id:
			return combatant
	return null


func get_first_combatant_on_team(team: CombatantState.Team) -> CombatantState:
	for combatant: CombatantState in combatants:
		if combatant.team == team and combatant.can_act():
			return combatant
	return null


func get_skill(skill_id: StringName) -> SkillDefinition:
	return _skills.get(skill_id) as SkillDefinition


func get_next_actor() -> CombatantState:
	var best_actor: CombatantState = null

	for combatant: CombatantState in combatants:
		if not combatant.can_act():
			continue
		if best_actor == null or _acts_before(combatant, best_actor):
			best_actor = combatant

	return best_actor


func prepare_next_turn() -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	if combat_finished_flag:
		return events

	var actor := get_next_actor()
	if actor == null:
		return events
	if _prepared_actor_id == actor.instance_id and _prepared_actor_tick == actor.next_action_tick:
		return events

	actor.begin_turn()
	_prepared_actor_id = actor.instance_id
	_prepared_actor_tick = actor.next_action_tick
	events.append(CombatEvent.turn_started(actor.instance_id))
	return events


func resolve_action(command: ActionCommand) -> Array[CombatEvent]:
	if combat_finished_flag:
		return _rejected(&"combat_finished")
	if command == null:
		return _rejected(&"invalid_command")

	var actor := get_combatant(command.actor_instance_id)
	if actor == null:
		return _rejected(&"invalid_actor")
	if not actor.can_act():
		return _rejected(&"actor_cannot_act")
	if actor != get_next_actor():
		return _rejected(&"actor_out_of_turn")

	var skill := get_skill(command.skill_id)
	if skill == null or not actor.knows_skill(command.skill_id):
		return _rejected(&"unknown_skill")
	if not actor.can_spend_resource(&"stamina", skill.stamina_cost):
		return _rejected(&"insufficient_stamina")

	var target := get_combatant(command.target_instance_id)
	if skill.action_kind == SkillDefinition.ActionKind.STRIKE:
		if target == null or target.is_defeated or target.team == actor.team:
			return _rejected(&"invalid_target")
	else:
		target = actor

	var events := prepare_next_turn()
	events.append(CombatEvent.action_started(actor.instance_id, target.instance_id, skill.content_id))

	if skill.stamina_cost > 0:
		actor.spend_resource(&"stamina", skill.stamina_cost)
		events.append(CombatEvent.resource_changed(
			CombatEvent.EventType.RESOURCE_SPENT,
			actor.instance_id,
			&"stamina",
			skill.stamina_cost,
		))

	match skill.action_kind:
		SkillDefinition.ActionKind.STRIKE:
			_resolve_strike(actor, target, skill, events)
		SkillDefinition.ActionKind.BRACE:
			actor.is_defending = true
			events.append(CombatEvent.defense_applied(actor.instance_id))

	if skill.stamina_gain > 0:
		var gained := actor.gain_resource(&"stamina", skill.stamina_gain)
		if gained > 0:
			events.append(CombatEvent.resource_changed(
				CombatEvent.EventType.RESOURCE_GAINED,
				actor.instance_id,
				&"stamina",
				gained,
			))

	actor.next_action_tick += skill.base_recovery
	_prepared_actor_id = -1
	_prepared_actor_tick = -1
	_check_combat_end(events)
	return events


func create_enemy_command() -> ActionCommand:
	var actor := get_next_actor()
	if actor == null or actor.team != CombatantState.Team.ENEMY:
		return null

	var target := get_first_combatant_on_team(CombatantState.Team.PLAYER)
	if target == null or actor.skill_ids.is_empty():
		return null

	return ActionCommand.new(actor.instance_id, actor.skill_ids[0], target.instance_id)


func get_damage_preview(
	skill_id: StringName,
	actor_id: int,
	target_id: int,
	assume_defending: bool = false,
) -> Vector2i:
	var skill := get_skill(skill_id)
	var actor := get_combatant(actor_id)
	var target := get_combatant(target_id)
	if skill == null or actor == null or target == null or skill.effects.is_empty():
		return Vector2i.ZERO

	var effect := skill.effects[0]
	return DamageResolver.preview_range(
		effect,
		actor.power,
		target.defense,
		assume_defending,
	)


func _resolve_strike(
	actor: CombatantState,
	target: CombatantState,
	skill: SkillDefinition,
	events: Array[CombatEvent],
) -> void:
	var effect := skill.effects[0]
	var result := DamageResolver.resolve(
		effect,
		actor.power,
		target.defense,
		_rng,
		target.is_defending,
		skill.critical_chance,
		skill.critical_multiplier,
	)
	var applied_damage := target.apply_damage(result.damage)
	events.append(CombatEvent.damage_dealt(
		actor.instance_id,
		target.instance_id,
		applied_damage,
		result.critical,
	))

	if target.is_defeated:
		events.append(CombatEvent.combatant_defeated(target.instance_id))


func _check_combat_end(events: Array[CombatEvent]) -> void:
	var players_alive := get_first_combatant_on_team(CombatantState.Team.PLAYER) != null
	var enemies_alive := get_first_combatant_on_team(CombatantState.Team.ENEMY) != null
	if players_alive and enemies_alive:
		return

	combat_finished_flag = true
	winning_team = (
		CombatantState.Team.PLAYER
		if players_alive
		else CombatantState.Team.ENEMY
	)
	events.append(CombatEvent.combat_ended(winning_team))
	combat_finished.emit(winning_team)


func _acts_before(a: CombatantState, b: CombatantState) -> bool:
	if a.next_action_tick != b.next_action_tick:
		return a.next_action_tick < b.next_action_tick
	if a.speed != b.speed:
		return a.speed > b.speed
	return a.spawn_order < b.spawn_order


func _rejected(reason: StringName) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	events.append(CombatEvent.action_rejected(reason))
	return events
