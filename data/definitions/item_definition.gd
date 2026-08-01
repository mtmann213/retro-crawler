class_name ItemDefinition
extends Resource

enum ItemType { MATERIAL, CONSUMABLE, WEAPON, ARMOR, QUEST }
enum Rarity { COMMON, UNCOMMON, RARE, UNIQUE }
enum EquipmentSlot { NONE, WEAPON, ARMOR }

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export_range(1, 99, 1) var maximum_stack: int = 1
@export_range(0, 99999, 1) var base_value: int = 0
@export var usable_in_combat: bool = false
@export var usable_outside_combat: bool = false
@export var effects: Array[EffectDefinition] = []
@export var equipment_slot: EquipmentSlot = EquipmentSlot.NONE
@export var stat_modifiers: Dictionary[StringName, int] = {}
@export_range(1, 999, 1) var combat_recovery: int = 90
@export_range(0, 999, 1) var dungeon_time_cost: int = 4


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if display_name.is_empty():
		errors.append("display_name is required.")
	if maximum_stack <= 0:
		errors.append("maximum_stack must be positive.")
	if equipment_slot != EquipmentSlot.NONE and maximum_stack != 1:
		errors.append("Equipment must have a maximum stack of one.")
	if item_type == ItemType.WEAPON and equipment_slot != EquipmentSlot.WEAPON:
		errors.append("Weapons must use the weapon slot.")
	if item_type == ItemType.ARMOR and equipment_slot != EquipmentSlot.ARMOR:
		errors.append("Armor must use the armor slot.")
	if item_type == ItemType.CONSUMABLE and effects.is_empty():
		errors.append("Consumables require at least one effect.")
	for effect: EffectDefinition in effects:
		if effect == null:
			errors.append("effects cannot contain null entries.")
		else:
			errors.append_array(effect.validate())
	for stat_id: StringName in stat_modifiers:
		if not [&"max_hp", &"power", &"defense", &"speed"].has(stat_id):
			errors.append("Unknown stat modifier %s." % stat_id)
	return errors


func rarity_name() -> String:
	return Rarity.keys()[rarity].capitalize()
