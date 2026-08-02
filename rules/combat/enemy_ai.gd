class_name EnemyAI
extends RefCounted


static func plan_intent(
	actor: CombatantState,
	state: CombatState,
	skills: Dictionary[StringName, SkillDefinition],
	enemy_definition: EnemyDefinition,
	pattern_override: Array[StringName] = [],
) -> ActionCommand:
	if actor == null or not actor.can_act() or enemy_definition == null:
		return null

	var pattern := pattern_override
	if pattern.is_empty():
		pattern = enemy_definition.ai_pattern
	if pattern.is_empty():
		pattern = enemy_definition.skill_ids
	if pattern.is_empty():
		return null

	for offset: int in range(pattern.size()):
		var index := (actor.ai_pattern_index + offset) % pattern.size()
		var skill_id := pattern[index]
		var skill := skills.get(skill_id) as SkillDefinition
		if not _can_use_skill(actor, skill):
			continue

		var target := _choose_target(actor, state, skill)
		if target == null:
			continue

		actor.ai_pattern_index = (index + 1) % pattern.size()
		actor.intent_skill_id = skill_id
		actor.intent_target_id = target.instance_id
		return ActionCommand.new(actor.instance_id, skill_id, target.instance_id)

	actor.intent_skill_id = &""
	actor.intent_target_id = -1
	return null


static func command_from_intent(
	actor: CombatantState,
	state: CombatState,
	skills: Dictionary[StringName, SkillDefinition],
) -> ActionCommand:
	if actor.intent_skill_id.is_empty():
		return null
	var skill := skills.get(actor.intent_skill_id) as SkillDefinition
	var target := state.get_combatant(actor.intent_target_id)
	if not _can_use_skill(actor, skill) or target == null or target.is_defeated:
		return null
	return ActionCommand.new(actor.instance_id, actor.intent_skill_id, actor.intent_target_id)


static func _can_use_skill(actor: CombatantState, skill: SkillDefinition) -> bool:
	if skill == null or not actor.knows_skill(skill.content_id):
		return false
	if actor.cooldowns.get(skill.content_id, 0) > 0:
		return false
	if not actor.can_spend_resource(&"stamina", skill.stamina_cost):
		return false
	if skill.charge_cost > 0 and not actor.can_spend_resource(skill.charge_resource_id, skill.charge_cost):
		return false
	return skill.validate().is_empty()


static func _choose_target(
	actor: CombatantState,
	state: CombatState,
	skill: SkillDefinition,
) -> CombatantState:
	if skill.target_rule == SkillDefinition.TargetRule.SELF:
		return actor
	var opposing_team := (
		CombatantState.Team.ENEMY
		if actor.team == CombatantState.Team.PLAYER
		else CombatantState.Team.PLAYER
	)
	var targets := state.get_living_team_members(opposing_team)
	return targets[0] if not targets.is_empty() else null
