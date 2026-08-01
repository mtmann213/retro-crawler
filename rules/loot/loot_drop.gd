class_name LootDrop
extends RefCounted

var item_id: StringName
var quantity: int
var unique: bool


func _init(new_item_id: StringName, new_quantity: int, is_unique: bool = false) -> void:
	item_id = new_item_id
	quantity = new_quantity
	unique = is_unique
