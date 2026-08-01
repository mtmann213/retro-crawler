class_name DamageResolver
extends RefCounted

const MINIMUM_VARIANCE := 0.95
const MAXIMUM_VARIANCE := 1.05
const DEFENDING_MULTIPLIER := 0.5


static func calculate_damage(
	effect: EffectDefinition,
	attacker_power: int,
	defender_defense: int,
	defended: bool = false,
	critical: bool = false,
	critical_multiplier: float = 1.5,
	variance_multiplier: float = 1.0,
	damage_type_modifier: float = 1.0,
	status_modifier: float = 1.0,
	immune: bool = false,
) -> int:
	if immune:
		return 0

	assert(effect != null)
	assert(effect.effect_type == EffectDefinition.EffectType.DAMAGE)

	var attack_value := float(effect.base_amount) + float(attacker_power) * effect.scaling_ratio
	var mitigation := float(defender_defense) * effect.defense_scaling
	var raw_damage := maxf(1.0, attack_value - mitigation)
	var final_damage := raw_damage * damage_type_modifier * status_modifier

	if defended:
		final_damage *= DEFENDING_MULTIPLIER
	if critical:
		final_damage *= critical_multiplier

	final_damage *= variance_multiplier
	return maxi(1, int(round(final_damage)))


static func resolve(
	effect: EffectDefinition,
	attacker_power: int,
	defender_defense: int,
	rng: RandomNumberGenerator,
	defended: bool = false,
	critical_chance: float = 0.0,
	critical_multiplier: float = 1.5,
) -> Dictionary:
	assert(rng != null)

	var critical := rng.randf() < clampf(critical_chance, 0.0, 1.0)
	var variance := rng.randf_range(MINIMUM_VARIANCE, MAXIMUM_VARIANCE)
	var damage := calculate_damage(
		effect,
		attacker_power,
		defender_defense,
		defended,
		critical,
		critical_multiplier,
		variance,
	)

	return {
		"damage": damage,
		"critical": critical,
		"variance": variance,
	}


static func preview_range(
	effect: EffectDefinition,
	attacker_power: int,
	defender_defense: int,
	defended: bool = false,
) -> Vector2i:
	var minimum := calculate_damage(
		effect,
		attacker_power,
		defender_defense,
		defended,
		false,
		1.0,
		MINIMUM_VARIANCE,
	)
	var maximum := calculate_damage(
		effect,
		attacker_power,
		defender_defense,
		defended,
		false,
		1.0,
		MAXIMUM_VARIANCE,
	)
	return Vector2i(minimum, maximum)
