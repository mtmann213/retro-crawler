extends GutTest


func _damage_effect(base_amount: int = 4) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.effect_type = EffectDefinition.EffectType.DAMAGE
	effect.base_amount = base_amount
	effect.scaling_ratio = 1.0
	effect.defense_scaling = 1.0
	return effect


func test_normal_damage_uses_readable_formula() -> void:
	var damage := DamageResolver.calculate_damage(_damage_effect(), 12, 4)
	assert_eq(damage, 12, "4 base + 12 power - 4 defense should deal 12 damage.")


func test_defending_reduces_incoming_damage() -> void:
	var normal := DamageResolver.calculate_damage(_damage_effect(), 12, 4)
	var defended := DamageResolver.calculate_damage(_damage_effect(), 12, 4, true)
	assert_lt(defended, normal)
	assert_eq(defended, 6)


func test_critical_damage_uses_skill_multiplier() -> void:
	var normal := DamageResolver.calculate_damage(_damage_effect(), 12, 4)
	var critical := DamageResolver.calculate_damage(_damage_effect(), 12, 4, false, true, 1.5)
	assert_eq(critical, 18)
	assert_gt(critical, normal)


func test_damage_never_falls_below_one() -> void:
	var damage := DamageResolver.calculate_damage(_damage_effect(0), 1, 999)
	assert_eq(damage, 1)


func test_immunity_is_the_only_zero_damage_case() -> void:
	var damage := DamageResolver.calculate_damage(
		_damage_effect(), 12, 4, false, false, 1.5, 1.0, 1.0, 1.0, true,
	)
	assert_eq(damage, 0)


func test_fixed_seed_produces_fixed_result() -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 90210
	second_rng.seed = 90210
	var first := DamageResolver.resolve(_damage_effect(), 12, 4, first_rng, false, 0.25)
	var second := DamageResolver.resolve(_damage_effect(), 12, 4, second_rng, false, 0.25)
	assert_eq(first, second)
