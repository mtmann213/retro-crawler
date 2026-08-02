class_name InventoryScreen
extends Control

signal continue_requested
signal item_used(seconds: int, description: String)

const ITEM_CARD_SCENE := preload("res://ui/components/item_card.tscn")

@onready var reward_label: Label = %RewardLabel
@onready var progression_label: Label = %ProgressionLabel
@onready var stats_label: Label = %StatsLabel
@onready var equipment_label: Label = %EquipmentLabel
@onready var item_list: VBoxContainer = %ItemList
@onready var details_label: RichTextLabel = %DetailsLabel
@onready var use_button: Button = %UseItemButton
@onready var equip_button: Button = %EquipItemButton
@onready var continue_button: Button = %ContinueButton

var session: RewardSession
var player: CombatantState
var selected_item_id: StringName = &""


func _ready() -> void:
	use_button.pressed.connect(_use_selected_item)
	equip_button.pressed.connect(_toggle_selected_equipment)
	continue_button.pressed.connect(_continue)


func present(
	new_session: RewardSession,
	new_player: CombatantState,
	rewards: Array[LootDrop],
	continue_text: String = "CONTINUE TO NEXT ENCOUNTER",
) -> void:
	session = new_session
	player = new_player
	visible = true
	var reward_parts: PackedStringArray = []
	for drop: LootDrop in rewards:
		var definition := session.get_item(drop.item_id)
		reward_parts.append("%s x%d" % [definition.display_name, drop.quantity])
	reward_label.text = "RECOVERED // " + (", ".join(reward_parts) if not reward_parts.is_empty() else "inventory full")
	selected_item_id = StringName(session.inventory.quantities.keys()[0]) if not session.inventory.quantities.is_empty() else &""
	continue_button.text = continue_text
	_rebuild()
	continue_button.grab_focus()


func _rebuild() -> void:
	for child: Node in item_list.get_children():
		child.queue_free()
	var item_ids: Array = session.inventory.quantities.keys()
	item_ids.sort()
	for item_id: StringName in item_ids:
		var definition := session.get_item(item_id)
		var card := ITEM_CARD_SCENE.instantiate() as ItemCard
		item_list.add_child(card)
		card.setup(definition, session.inventory.get_quantity(item_id), _is_equipped(definition))
		card.item_selected.connect(_select_item)
	_update_summary()
	_update_details()


func _select_item(item_id: StringName) -> void:
	selected_item_id = item_id
	_update_details()


func _update_summary() -> void:
	progression_label.text = "LEVEL %d  //  XP %d  //  NEXT %d" % [
		session.progression.level,
		session.progression.total_experience,
		ExperienceRules.experience_to_next_level(session.progression),
	]
	stats_label.text = "HP %d/%d  //  POW %d  //  DEF %d  //  SPD %d" % [
		player.current_hp, player.max_hp, player.power, player.defense, player.speed,
	]
	var weapon := session.inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	var armor := session.inventory.get_equipped(ItemDefinition.EquipmentSlot.ARMOR)
	equipment_label.text = "WEAPON: %s\nARMOR: %s" % [_item_name(weapon), _item_name(armor)]


func _update_details() -> void:
	var definition := session.get_item(selected_item_id)
	if definition == null:
		details_label.text = "Select recovered loot to inspect it."
		use_button.visible = false
		equip_button.visible = false
		use_button.disabled = true
		equip_button.disabled = true
		return
	details_label.text = "[color=#7dd3fc]%s[/color]\n[%s]\n\n%s\n\n%s" % [
		definition.display_name.to_upper(),
		definition.rarity_name().to_upper(),
		definition.description,
		_modifier_text(definition),
	]
	use_button.visible = definition.item_type == ItemDefinition.ItemType.CONSUMABLE
	use_button.disabled = not definition.usable_outside_combat
	equip_button.visible = definition.equipment_slot != ItemDefinition.EquipmentSlot.NONE
	equip_button.text = "UNEQUIP" if _is_equipped(definition) else "EQUIP"
	equip_button.disabled = false


func _use_selected_item() -> void:
	var definition := session.get_item(selected_item_id)
	var events := InventoryRules.use_item(session.inventory, definition, player)
	if not events.is_empty():
		reward_label.text = "%s USED // statistics updated" % definition.display_name.to_upper()
		item_used.emit(definition.dungeon_time_cost, "ITEM // %s" % definition.display_name)
		if session.inventory.get_quantity(selected_item_id) == 0:
			selected_item_id = &""
		_rebuild()


func _toggle_selected_equipment() -> void:
	var definition := session.get_item(selected_item_id)
	if _is_equipped(definition):
		EquipmentRules.unequip(session.inventory, player, definition.equipment_slot, session.item_catalog)
	else:
		EquipmentRules.equip(session.inventory, player, definition, session.item_catalog)
	_rebuild()


func _continue() -> void:
	visible = false
	continue_requested.emit()


func _is_equipped(definition: ItemDefinition) -> bool:
	return (
		definition != null
		and definition.equipment_slot != ItemDefinition.EquipmentSlot.NONE
		and session.inventory.get_equipped(definition.equipment_slot) == definition.content_id
	)


func _item_name(item_id: StringName) -> String:
	var definition := session.get_item(item_id)
	return definition.display_name if definition != null else "NONE"


func _modifier_text(definition: ItemDefinition) -> String:
	if definition.stat_modifiers.is_empty():
		return "No equipment modifiers."
	var parts: PackedStringArray = []
	for stat_id: StringName in definition.stat_modifiers:
		parts.append("%s %+d" % [String(stat_id).to_upper(), definition.stat_modifiers[stat_id]])
	return "  //  ".join(parts)
