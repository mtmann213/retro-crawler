class_name EquipmentRules
extends RefCounted


static func equip(
	state: InventoryState,
	combatant: CombatantState,
	definition: ItemDefinition,
	item_catalog: Dictionary[StringName, ItemDefinition],
) -> bool:
	if (
		state == null
		or combatant == null
		or definition == null
		or definition.equipment_slot == ItemDefinition.EquipmentSlot.NONE
		or state.get_quantity(definition.content_id) <= 0
	):
		return false
	var slot := definition.equipment_slot
	var previous_id := state.get_equipped(slot)
	if previous_id == definition.content_id:
		return false
	_remove_applied_slot(combatant, slot, item_catalog)
	state.equipment[slot] = definition.content_id
	_apply_modifiers(combatant, definition.stat_modifiers, 1)
	combatant.applied_equipment[slot] = definition.content_id
	return true


static func unequip(
	state: InventoryState,
	combatant: CombatantState,
	slot: ItemDefinition.EquipmentSlot,
	item_catalog: Dictionary[StringName, ItemDefinition],
) -> bool:
	var item_id := state.get_equipped(slot)
	if item_id.is_empty():
		return false
	_remove_applied_slot(combatant, slot, item_catalog)
	state.equipment.erase(slot)
	return true


static func apply_equipped_items(
	state: InventoryState,
	combatant: CombatantState,
	item_catalog: Dictionary[StringName, ItemDefinition],
) -> void:
	for slot: int in state.equipment:
		var item_id := state.equipment[slot]
		if combatant.applied_equipment.get(slot, &"") == item_id:
			continue
		_remove_applied_slot(combatant, slot, item_catalog)
		var definition := item_catalog.get(item_id) as ItemDefinition
		if definition != null:
			_apply_modifiers(combatant, definition.stat_modifiers, 1)
			combatant.applied_equipment[slot] = item_id


static func _remove_applied_slot(
	combatant: CombatantState,
	slot: ItemDefinition.EquipmentSlot,
	item_catalog: Dictionary[StringName, ItemDefinition],
) -> void:
	var applied_id: StringName = combatant.applied_equipment.get(slot, &"")
	if applied_id.is_empty():
		return
	var definition := item_catalog.get(applied_id) as ItemDefinition
	if definition != null:
		_apply_modifiers(combatant, definition.stat_modifiers, -1)
	combatant.applied_equipment.erase(slot)


static func _apply_modifiers(
	combatant: CombatantState,
	modifiers: Dictionary[StringName, int],
	direction: int,
) -> void:
	for stat_id: StringName in modifiers:
		var amount: int = modifiers[stat_id] * direction
		match stat_id:
			&"max_hp":
				combatant.max_hp = maxi(1, combatant.max_hp + amount)
				combatant.current_hp = mini(combatant.current_hp, combatant.max_hp)
			&"power":
				combatant.power = maxi(0, combatant.power + amount)
			&"defense":
				combatant.defense = maxi(0, combatant.defense + amount)
			&"speed":
				combatant.speed = maxi(1, combatant.speed + amount)
