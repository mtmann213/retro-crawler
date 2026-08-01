class_name CombatSimulation
extends RefCounted

signal combat_finished(winning_team: int)

var state: CombatState
var combatants: Array[CombatantState] = []
var combat_finished_flag: bool = false
var winning_team: int = -1

var _skills: Dictionary[StringName, SkillDefinition] = {}
var _status_definitions: Dictionary[StringName, StatusDefinition] = {}
var _enemy_definitions: Dictionary[StringName, EnemyDefinition] = {}
var _rng := RandomNumberGenerator.new()
var _prepared_actor_id: int = -1
var _prepared_actor_tick: int = -1


func _init(
	initial_combatants: Array[CombatantState],
	initial_skills: Array[SkillDefinition],
	seed_value: int = 1,
	initial_status_definitions: Array[StatusDefinition] = [],
	initial_enemy_definitions: Array[EnemyDefinition] = [],
) -> void:
	assert(not initial_combatants.is_empty())
	combatants = initial_combatants
	state = CombatState.new(combatants)
	_rng.seed = seed_value

	for skill: SkillDefinition in initial_skills:
		assert(skill != null)
		assert(skill.validate().is_empty())
		assert(not _skills.has(skill.content_id))
		_skills[skill.content_id] = skill

	for definition: StatusDefinition in initial_status_definitions:
		assert(definition != null)
		assert(definition.validate().is_empty())
		assert(not _status_definitions.has(definition.content_id))
		_status_definitions[definition.content_id] = definition

	for definition: EnemyDefinition in initial_enemy_definitions:
		assert(definition != null)
		assert(definition.validate().is_empty())
		assert(not _enemy_definitions.has(definition.content_id))
		_enemy_definitions[definition.content_id] = definition

	_plan_all_enemy_intents()


func get_combatant(combatant_id: int) -> CombatantState:
	return state.get_combatant(combatant_id)


func get_first_combatant_on_team(team: CombatantState.Team) -> CombatantState:
	var members := state.get_living_team_members(team)
	return members[0] if not members.is_empty() else null


func get_skill(skill_id: StringName) -> SkillDefinition:
	return _skills.get(skill_id) as SkillDefinition


func get_status_definition(status_id: StringName) -> StatusDefinition:
	return _status_definitions.get(status_id) as StatusDefinition


func get_next_actor() -> CombatantState:
	return TimelineResolver.get_next_actor(combatants)


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
	state.turn_count += 1
	events.append(CombatEvent.turn_started(actor.instance_id))

	var was_alive := not actor.is_defeated
	StatusResolver.tick_phase(actor, StatusDefinition.TickPhase.START_OF_TURN, events)
	if was_alive and actor.is_defeated:
		events.append(CombatEvent.combatant_defeated(actor.instance_id))
		_check_combat_end(events)
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
	if not skill.validate().is_empty():
		return _rejected(&"invalid_skill")
	if actor.cooldowns.get(skill.content_id, 0) > 0:
		return _rejected(&"skill_on_cooldown")
	if not actor.can_spend_resource(&"stamina", skill.stamina_cost):
		return _rejected(&"insufficient_stamina")
	if skill.charge_cost > 0 and not actor.can_spend_resource(skill.charge_resource_id, skill.charge_cost):
		return _rejected(&"insufficient_charges")

	var target := _validate_target(actor, command.target_instance_id, skill)
	if target == null:
		return _rejected(&"invalid_target")

	var events := prepare_next_turn()
	if combat_finished_flag or not actor.can_act():
		return events
	events.append(CombatEvent.action_started(actor.instance_id, target.instance_id, skill.content_id))

	_spend_costs(actor, skill, events)
	var action_speed := StatusResolver.get_effective_speed(actor)

	if skill.action_kind == SkillDefinition.ActionKind.BRACE:
		actor.is_defending = true
		events.append(CombatEvent.defense_applied(actor.instance_id))
	else:
		events.append_array(EffectResolver.resolve_effects(
			actor,
			target,
			skill,
			_status_definitions,
			_rng,
		))

	if skill.stamina_gain > 0:
		var gained := actor.gain_resource(&"stamina", skill.stamina_gain)
		if gained > 0:
			events.append(CombatEvent.resource_changed(
				CombatEvent.EventType.RESOURCE_GAINED,
				actor.instance_id,
				&"stamina",
				gained,
			))

	actor.advance_cooldowns()
	if skill.cooldown_turns > 0:
		actor.cooldowns[skill.content_id] = skill.cooldown_turns
		events.append(CombatEvent.cooldown_applied(
			actor.instance_id,
			skill.content_id,
			skill.cooldown_turns,
		))

	actor.actions_taken += 1
	StatusResolver.tick_phase(actor, StatusDefinition.TickPhase.END_OF_ACTION, events)
	actor.next_action_tick += TimelineResolver.calculate_recovery(skill.base_recovery, action_speed)
	_prepared_actor_id = -1
	_prepared_actor_tick = -1
	_check_combat_end(events)

	if actor.team == CombatantState.Team.ENEMY and not combat_finished_flag and actor.can_act():
		var intent := _plan_enemy_intent(actor)
		if intent != null:
			events.append(CombatEvent.intent_changed(
				actor.instance_id,
				intent.target_instance_id,
				intent.skill_id,
			))

	return events


func create_enemy_command() -> ActionCommand:
	var actor := get_next_actor()
	if actor == null or actor.team != CombatantState.Team.ENEMY:
		return null

	var command := EnemyAI.command_from_intent(actor, state, _skills)
	if command != null:
		return command
	return _plan_enemy_intent(actor)


func get_enemy_intent_skill(actor_id: int) -> SkillDefinition:
	var actor := get_combatant(actor_id)
	if actor == null or actor.intent_skill_id.is_empty():
		return null
	return get_skill(actor.intent_skill_id)


func get_damage_preview(
	skill_id: StringName,
	actor_id: int,
	target_id: int,
	assume_defending: bool = false,
) -> Vector2i:
	var skill := get_skill(skill_id)
	var actor := get_combatant(actor_id)
	var target := get_combatant(target_id)
	if skill == null or actor == null or target == null:
		return Vector2i.ZERO

	var damage_effect: EffectDefinition = null
	for effect: EffectDefinition in skill.effects:
		if effect != null and effect.effect_type == EffectDefinition.EffectType.DAMAGE:
			damage_effect = effect
			break
	if damage_effect == null:
		return Vector2i.ZERO

	var base_range := DamageResolver.preview_range(
		damage_effect,
		actor.power,
		StatusResolver.get_effective_defense(target),
		assume_defending,
	)
	var modifier := StatusResolver.get_damage_taken_multiplier(target)
	return Vector2i(
		maxi(1, int(round(float(base_range.x) * modifier))),
		maxi(1, int(round(float(base_range.y) * modifier))),
	)


func _validate_target(
	actor: CombatantState,
	target_instance_id: int,
	skill: SkillDefinition,
) -> CombatantState:
	if skill.target_rule == SkillDefinition.TargetRule.SELF:
		return actor
	var target := get_combatant(target_instance_id)
	if target == null or target.is_defeated or target.team == actor.team:
		return null
	return target


func _spend_costs(
	actor: CombatantState,
	skill: SkillDefinition,
	events: Array[CombatEvent],
) -> void:
	if skill.stamina_cost > 0:
		actor.spend_resource(&"stamina", skill.stamina_cost)
		events.append(CombatEvent.resource_changed(
			CombatEvent.EventType.RESOURCE_SPENT,
			actor.instance_id,
			&"stamina",
			skill.stamina_cost,
		))
	if skill.charge_cost > 0:
		actor.spend_resource(skill.charge_resource_id, skill.charge_cost)
		events.append(CombatEvent.resource_changed(
			CombatEvent.EventType.RESOURCE_SPENT,
			actor.instance_id,
			skill.charge_resource_id,
			skill.charge_cost,
		))


func _plan_all_enemy_intents() -> void:
	for combatant: CombatantState in combatants:
		if combatant.team == CombatantState.Team.ENEMY:
			_plan_enemy_intent(combatant)


func _plan_enemy_intent(actor: CombatantState) -> ActionCommand:
	var definition := _enemy_definitions.get(actor.definition_id) as EnemyDefinition
	return EnemyAI.plan_intent(actor, state, _skills, definition)


func _check_combat_end(events: Array[CombatEvent]) -> void:
	var players_alive := not state.get_living_team_members(CombatantState.Team.PLAYER).is_empty()
	var enemies_alive := not state.get_living_team_members(CombatantState.Team.ENEMY).is_empty()
	if players_alive and enemies_alive:
		return

	combat_finished_flag = true
	winning_team = CombatantState.Team.PLAYER if players_alive else CombatantState.Team.ENEMY
	state.is_finished = true
	state.winning_team = winning_team
	events.append(CombatEvent.combat_ended(winning_team))
	combat_finished.emit(winning_team)


func _rejected(reason: StringName) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	events.append(CombatEvent.action_rejected(reason))
	return events
