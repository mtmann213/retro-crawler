class_name PrototypeEncounter
extends RefCounted

const DEFAULT_SEED := 731_2026
const DUEL_ENCOUNTER_ID := &"encounter_duel"
const TWO_ENEMY_ENCOUNTER_ID := &"encounter_two_enemy"
const BRUTE_ENCOUNTER_ID := &"encounter_brute"


static func create_simulation(
	seed_value: int = DEFAULT_SEED,
	encounter_id: StringName = DUEL_ENCOUNTER_ID,
) -> CombatSimulation:
	var statuses := _create_statuses()
	var skills := _create_skills()
	var enemies := _create_enemy_definitions()
	var encounter := _get_encounter(encounter_id)
	assert(encounter != null)

	var player_skills: Array[StringName] = [
		&"quick_strike", &"heavy_swing", &"brace", &"hamstring", &"field_patch",
	]
	var player := CombatantState.new(
		1, &"character_test_crawler", "Test Crawler", CombatantState.Team.PLAYER,
		100, 12, 8, 10, 0, player_skills,
	)
	player.set_resource(&"stamina", 10, 40)
	player.set_resource(&"field_patch_charges", 2, 2)

	var combatants: Array[CombatantState] = [player]
	var instance_id := 2
	for enemy_id: StringName in encounter.enemy_definition_ids:
		var definition := _find_enemy(enemies, enemy_id)
		assert(definition != null)
		var enemy := CombatantState.new(
			instance_id,
			definition.content_id,
			definition.display_name,
			CombatantState.Team.ENEMY,
			definition.max_hp,
			definition.power,
			definition.defense,
			definition.speed,
			instance_id - 1,
			definition.skill_ids,
		)
		enemy.next_action_tick = 25 + (instance_id - 2)
		combatants.append(enemy)
		instance_id += 1

	return CombatSimulation.new(combatants, skills, seed_value, statuses, enemies)


static func _create_statuses() -> Array[StatusDefinition]:
	var slowed := StatusDefinition.new()
	slowed.content_id = &"slowed"
	slowed.display_name = "Slowed"
	slowed.description = "Speed is reduced by 35% for two actions."
	slowed.base_duration = 2
	slowed.maximum_stacks = 1
	slowed.tick_phase = StatusDefinition.TickPhase.END_OF_ACTION
	slowed.speed_multiplier = 0.65

	var exposed := StatusDefinition.new()
	exposed.content_id = &"exposed"
	exposed.display_name = "Exposed"
	exposed.description = "Defense is reduced by 30% for two actions."
	exposed.base_duration = 2
	exposed.maximum_stacks = 1
	exposed.tick_phase = StatusDefinition.TickPhase.END_OF_ACTION
	exposed.defense_multiplier = 0.70

	var definitions: Array[StatusDefinition] = [slowed, exposed]
	return definitions


static func _create_skills() -> Array[SkillDefinition]:
	var quick_strike := _skill(
		&"quick_strike", "Quick Strike", "A fast attack that builds 3 stamina.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 70,
		[_damage(4, 1.0)],
	)
	quick_strike.stamina_gain = 3
	quick_strike.critical_chance = 0.05

	var heavy_swing := _skill(
		&"heavy_swing", "Heavy Swing", "A powerful hit with a two-turn cooldown.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 140,
		[_damage(18, 1.4)],
	)
	heavy_swing.stamina_cost = 12
	heavy_swing.cooldown_turns = 2
	heavy_swing.dungeon_time_cost = 8

	var brace := _skill(
		&"brace", "Brace", "Halves incoming damage until your next turn.",
		SkillDefinition.ActionKind.BRACE, SkillDefinition.TargetRule.SELF, 80, [],
	)

	var hamstring := _skill(
		&"hamstring", "Hamstring", "Deals damage, then Slows the target for two actions.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 100,
		[_damage(6, 0.8), _apply_status(&"slowed")],
	)
	hamstring.stamina_cost = 6
	hamstring.cooldown_turns = 3

	var field_patch := _skill(
		&"field_patch", "Field Patch", "Restore health. Two charges per encounter.",
		SkillDefinition.ActionKind.UTILITY, SkillDefinition.TargetRule.SELF, 120,
		[_heal(20, 0.5)],
	)
	field_patch.charge_resource_id = &"field_patch_charges"
	field_patch.charge_cost = 1
	field_patch.dungeon_time_cost = 4

	var scrap_bite := _skill(
		&"scrap_bite", "Bite", "A quick mechanical bite.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 90,
		[_damage(5, 1.0)],
	)
	var circle := _skill(
		&"scrap_circle", "Circle", "Brace while searching for an opening.",
		SkillDefinition.ActionKind.BRACE, SkillDefinition.TargetRule.SELF, 80, [],
	)
	var charged_shot := _skill(
		&"drone_charged_shot", "Charged Shot", "A slow, high-powered ranged attack.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 130,
		[_damage(9, 1.1)],
	)
	charged_shot.dungeon_time_cost = 8
	var reposition := _skill(
		&"drone_reposition", "Reposition", "The drone braces and adjusts its aim.",
		SkillDefinition.ActionKind.BRACE, SkillDefinition.TargetRule.SELF, 75, [],
	)
	var crush := _skill(
		&"brute_crush", "Crush", "A crushing blow that leaves the target Exposed.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 140,
		[_damage(12, 1.2), _apply_status(&"exposed")],
	)
	crush.dungeon_time_cost = 8
	var slam := _skill(
		&"brute_slam", "Slam", "A heavy but reliable strike.",
		SkillDefinition.ActionKind.STRIKE, SkillDefinition.TargetRule.SINGLE_ENEMY, 110,
		[_damage(8, 1.0)],
	)
	slam.dungeon_time_cost = 8

	var definitions: Array[SkillDefinition] = [
		quick_strike, heavy_swing, brace, hamstring, field_patch,
		scrap_bite, circle, charged_shot, reposition, crush, slam,
	]
	return definitions


static func _create_enemy_definitions() -> Array[EnemyDefinition]:
	var hound := EnemyDefinition.new()
	hound.content_id = &"enemy_scrap_hound"
	hound.display_name = "Scrap Hound"
	hound.max_hp = 42
	hound.power = 10
	hound.defense = 4
	hound.speed = 13
	hound.skill_ids = [&"scrap_bite", &"scrap_circle"]
	hound.ai_pattern = [&"scrap_bite", &"scrap_circle"]
	hound.loot_table_id = &"loot_combat_victory"
	hound.experience_reward = 40

	var drone := EnemyDefinition.new()
	drone.content_id = &"enemy_sentry_drone"
	drone.display_name = "Sentry Drone"
	drone.max_hp = 34
	drone.power = 9
	drone.defense = 5
	drone.speed = 10
	drone.skill_ids = [&"drone_charged_shot", &"drone_reposition"]
	drone.ai_pattern = [&"drone_charged_shot", &"drone_reposition"]
	drone.loot_table_id = &"loot_combat_victory"
	drone.experience_reward = 45

	var brute := EnemyDefinition.new()
	brute.content_id = &"enemy_scrap_brute"
	brute.display_name = "Scrap Brute"
	brute.max_hp = 72
	brute.power = 13
	brute.defense = 7
	brute.speed = 7
	brute.skill_ids = [&"brute_crush", &"brute_slam"]
	brute.ai_pattern = [&"brute_crush", &"brute_slam"]
	brute.loot_table_id = &"loot_combat_victory"
	brute.experience_reward = 90

	var definitions: Array[EnemyDefinition] = [hound, drone, brute]
	return definitions


static func _get_encounter(encounter_id: StringName) -> EncounterDefinition:
	var encounter := EncounterDefinition.new()
	encounter.content_id = encounter_id
	match encounter_id:
		DUEL_ENCOUNTER_ID:
			encounter.enemy_definition_ids = [&"enemy_scrap_hound"]
		TWO_ENEMY_ENCOUNTER_ID:
			encounter.enemy_definition_ids = [&"enemy_scrap_hound", &"enemy_sentry_drone"]
		BRUTE_ENCOUNTER_ID:
			encounter.enemy_definition_ids = [&"enemy_scrap_brute"]
		_:
			return null
	return encounter


static func _find_enemy(
	definitions: Array[EnemyDefinition],
	content_id: StringName,
) -> EnemyDefinition:
	for definition: EnemyDefinition in definitions:
		if definition.content_id == content_id:
			return definition
	return null


static func _skill(
	content_id: StringName,
	display_name: String,
	description: String,
	action_kind: SkillDefinition.ActionKind,
	target_rule: SkillDefinition.TargetRule,
	base_recovery: int,
	effects: Array[EffectDefinition],
) -> SkillDefinition:
	var skill := SkillDefinition.new()
	skill.content_id = content_id
	skill.display_name = display_name
	skill.description = description
	skill.action_kind = action_kind
	skill.target_rule = target_rule
	skill.base_recovery = base_recovery
	skill.effects = effects
	return skill


static func _damage(base_amount: int, scaling_ratio: float) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.effect_type = EffectDefinition.EffectType.DAMAGE
	effect.base_amount = base_amount
	effect.scaling_ratio = scaling_ratio
	effect.defense_scaling = 1.0
	return effect


static func _heal(base_amount: int, scaling_ratio: float) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.effect_type = EffectDefinition.EffectType.HEAL
	effect.base_amount = base_amount
	effect.scaling_ratio = scaling_ratio
	return effect


static func _apply_status(status_id: StringName) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.effect_type = EffectDefinition.EffectType.APPLY_STATUS
	effect.referenced_content_id = status_id
	effect.success_chance = 1.0
	return effect
