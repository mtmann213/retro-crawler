class_name PrototypeEncounter
extends RefCounted

const DEFAULT_SEED := 731_2026


static func create_simulation(seed_value: int = DEFAULT_SEED) -> CombatSimulation:
	var quick_strike_effect := EffectDefinition.new()
	quick_strike_effect.effect_type = EffectDefinition.EffectType.DAMAGE
	quick_strike_effect.base_amount = 4
	quick_strike_effect.scaling_ratio = 1.0
	quick_strike_effect.defense_scaling = 1.0

	var quick_strike := SkillDefinition.new()
	quick_strike.content_id = &"quick_strike"
	quick_strike.display_name = "Quick Strike"
	quick_strike.description = "A fast attack that builds 3 stamina."
	quick_strike.action_kind = SkillDefinition.ActionKind.STRIKE
	quick_strike.stamina_gain = 3
	quick_strike.base_recovery = 70
	quick_strike.critical_chance = 0.05
	quick_strike.effects = [quick_strike_effect]

	var brace := SkillDefinition.new()
	brace.content_id = &"brace"
	brace.display_name = "Brace"
	brace.description = "Halves incoming damage until your next turn."
	brace.action_kind = SkillDefinition.ActionKind.BRACE
	brace.base_recovery = 80

	var bite_effect := EffectDefinition.new()
	bite_effect.effect_type = EffectDefinition.EffectType.DAMAGE
	bite_effect.base_amount = 5
	bite_effect.scaling_ratio = 1.0
	bite_effect.defense_scaling = 1.0

	var scrap_bite := SkillDefinition.new()
	scrap_bite.content_id = &"scrap_bite"
	scrap_bite.display_name = "Bite"
	scrap_bite.description = "A quick mechanical bite."
	scrap_bite.action_kind = SkillDefinition.ActionKind.STRIKE
	scrap_bite.base_recovery = 100
	scrap_bite.effects = [bite_effect]

	var player_skills: Array[StringName] = [&"quick_strike", &"brace"]
	var enemy_skills: Array[StringName] = [&"scrap_bite"]
	var player := CombatantState.new(
		1,
		&"character_test_crawler",
		"Test Crawler",
		CombatantState.Team.PLAYER,
		100,
		12,
		8,
		10,
		0,
		player_skills,
	)
	player.set_resource(&"stamina", 10, 40)

	var enemy := CombatantState.new(
		2,
		&"enemy_scrap_hound",
		"Scrap Hound",
		CombatantState.Team.ENEMY,
		42,
		10,
		4,
		8,
		1,
		enemy_skills,
	)

	var combatants: Array[CombatantState] = [player, enemy]
	var skills: Array[SkillDefinition] = [quick_strike, brace, scrap_bite]
	return CombatSimulation.new(combatants, skills, seed_value)
