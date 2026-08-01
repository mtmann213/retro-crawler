class_name PrototypeRewardCatalog
extends RefCounted


static func create_items() -> Array[ItemDefinition]:
	var field_patch := _item(&"item_field_patch", "Field Patch", "Restores 30 HP.", ItemDefinition.ItemType.CONSUMABLE, ItemDefinition.Rarity.COMMON, 5)
	field_patch.usable_outside_combat = true
	field_patch.effects = [_heal(30)]
	var injector := _item(&"item_stamina_injector", "Stamina Injector", "Restores 15 stamina.", ItemDefinition.ItemType.CONSUMABLE, ItemDefinition.Rarity.UNCOMMON, 3)
	injector.usable_outside_combat = true
	injector.effects = [_resource(&"stamina", 15)]
	var scrap := _item(&"item_scrap_material", "Scrap Material", "Useful machine salvage.", ItemDefinition.ItemType.MATERIAL, ItemDefinition.Rarity.COMMON, 20)
	var collar := _item(&"item_worn_collar", "Worn Collar", "A unique trophy from a Scrap Hound.", ItemDefinition.ItemType.QUEST, ItemDefinition.Rarity.UNIQUE, 1)
	var cleaver := _item(&"item_salvaged_cleaver", "Salvaged Cleaver", "+3 Power.", ItemDefinition.ItemType.WEAPON, ItemDefinition.Rarity.UNCOMMON, 1)
	cleaver.equipment_slot = ItemDefinition.EquipmentSlot.WEAPON
	cleaver.stat_modifiers = {&"power": 3}
	var plating := _item(&"item_patchwork_plating", "Patchwork Plating", "+3 Defense and +10 maximum HP.", ItemDefinition.ItemType.ARMOR, ItemDefinition.Rarity.RARE, 1)
	plating.equipment_slot = ItemDefinition.EquipmentSlot.ARMOR
	plating.stat_modifiers = {&"defense": 3, &"max_hp": 10}
	var definitions: Array[ItemDefinition] = [field_patch, injector, scrap, collar, cleaver, plating]
	return definitions


static func create_loot_tables() -> Array[LootTableDefinition]:
	var victory := LootTableDefinition.new()
	victory.content_id = &"loot_combat_victory"
	victory.roll_count = 4
	victory.entries = [
		_entry(&"item_scrap_material", 35, 1, 2),
		_entry(&"item_field_patch", 20),
		_entry(&"item_stamina_injector", 15),
		_entry(&"item_salvaged_cleaver", 12),
		_entry(&"item_patchwork_plating", 10),
		_entry(&"item_worn_collar", 8, 1, 1, true),
	]
	var tables: Array[LootTableDefinition] = [victory]
	return tables


static func _item(
	content_id: StringName,
	display_name: String,
	description: String,
	item_type: ItemDefinition.ItemType,
	rarity: ItemDefinition.Rarity,
	maximum_stack: int,
) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.content_id = content_id
	item.display_name = display_name
	item.description = description
	item.item_type = item_type
	item.rarity = rarity
	item.maximum_stack = maximum_stack
	return item


static func _entry(
	content_id: StringName,
	weight: int,
	minimum_quantity: int = 1,
	maximum_quantity: int = 1,
	unique: bool = false,
) -> LootEntryDefinition:
	var entry := LootEntryDefinition.new()
	entry.content_id = content_id
	entry.weight = weight
	entry.minimum_quantity = minimum_quantity
	entry.maximum_quantity = maximum_quantity
	entry.unique = unique
	return entry


static func _heal(amount: int) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.effect_type = EffectDefinition.EffectType.HEAL
	effect.base_amount = amount
	effect.scaling_ratio = 0.0
	return effect


static func _resource(resource_id: StringName, amount: int) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.effect_type = EffectDefinition.EffectType.MODIFY_RESOURCE
	effect.resource_id = resource_id
	effect.base_amount = amount
	effect.scaling_ratio = 0.0
	return effect
