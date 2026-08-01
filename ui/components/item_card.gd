class_name ItemCard
extends Button

signal item_selected(item_id: StringName)

var item_id: StringName = &""


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(definition: ItemDefinition, quantity: int, equipped: bool) -> void:
	item_id = definition.content_id
	text = "%s%s  x%d\n[%s]" % [
		"> " if equipped else "",
		definition.display_name,
		quantity,
		definition.rarity_name().to_upper(),
	]
	tooltip_text = definition.description


func _on_pressed() -> void:
	item_selected.emit(item_id)
