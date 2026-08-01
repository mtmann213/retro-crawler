class_name InventoryState
extends RefCounted

var quantities: Dictionary[StringName, int] = {}
var equipment: Dictionary[int, StringName] = {}
var acquired_unique_items: Dictionary[StringName, bool] = {}


func get_quantity(item_id: StringName) -> int:
	return quantities.get(item_id, 0)


func get_equipped(slot: ItemDefinition.EquipmentSlot) -> StringName:
	return equipment.get(slot, &"")


func to_snapshot() -> Dictionary:
	var quantity_snapshot := {}
	for item_id: StringName in quantities:
		quantity_snapshot[String(item_id)] = quantities[item_id]
	var equipment_snapshot := {}
	for slot: int in equipment:
		equipment_snapshot[str(slot)] = String(equipment[slot])
	var unique_snapshot: Array[String] = []
	for item_id: StringName in acquired_unique_items:
		if acquired_unique_items[item_id]:
			unique_snapshot.append(String(item_id))
	return {
		"quantities": quantity_snapshot,
		"equipment": equipment_snapshot,
		"acquired_unique_items": unique_snapshot,
	}


static func from_snapshot(snapshot: Dictionary) -> InventoryState:
	var state := InventoryState.new()
	for item_id: String in snapshot.get("quantities", {}):
		state.quantities[StringName(item_id)] = int(snapshot["quantities"][item_id])
	for slot: String in snapshot.get("equipment", {}):
		state.equipment[int(slot)] = StringName(snapshot["equipment"][slot])
	for item_id: String in snapshot.get("acquired_unique_items", []):
		state.acquired_unique_items[StringName(item_id)] = true
	return state
