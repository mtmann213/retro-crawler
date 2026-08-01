class_name InventoryRules
extends RefCounted


static func add_item(
	state: InventoryState,
	definition: ItemDefinition,
	quantity: int,
) -> int:
	if state == null or definition == null or quantity <= 0:
		return 0
	var current := state.get_quantity(definition.content_id)
	var added := mini(quantity, maxi(definition.maximum_stack - current, 0))
	if added > 0:
		state.quantities[definition.content_id] = current + added
		if definition.rarity == ItemDefinition.Rarity.UNIQUE:
			state.acquired_unique_items[definition.content_id] = true
	return added


static func remove_item(state: InventoryState, item_id: StringName, quantity: int) -> bool:
	if state == null or quantity <= 0 or state.get_quantity(item_id) < quantity:
		return false
	var remaining := state.get_quantity(item_id) - quantity
	if remaining == 0:
		state.quantities.erase(item_id)
	else:
		state.quantities[item_id] = remaining
	return true


static func use_item(
	state: InventoryState,
	definition: ItemDefinition,
	target: CombatantState,
	status_definitions: Dictionary[StringName, StatusDefinition] = {},
	rng: RandomNumberGenerator = null,
) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	if (
		state == null
		or definition == null
		or target == null
		or definition.item_type != ItemDefinition.ItemType.CONSUMABLE
		or not definition.usable_outside_combat
		or state.get_quantity(definition.content_id) <= 0
	):
		return events
	var item_rng := rng if rng != null else RandomNumberGenerator.new()
	var skill := SkillDefinition.new()
	skill.content_id = definition.content_id
	skill.display_name = definition.display_name
	skill.description = definition.description
	skill.action_kind = SkillDefinition.ActionKind.UTILITY
	skill.target_rule = SkillDefinition.TargetRule.SELF
	skill.base_recovery = definition.combat_recovery
	skill.effects = definition.effects
	events = EffectResolver.resolve_effects(
		target, target, skill, status_definitions, item_rng,
	)
	if not events.is_empty():
		remove_item(state, definition.content_id, 1)
	return events
