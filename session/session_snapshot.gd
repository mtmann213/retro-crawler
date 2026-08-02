class_name SessionSnapshot
extends RefCounted

const CURRENT_VERSION := 1

var version: int = CURRENT_VERSION
var floor_snapshot: Dictionary = {}
var reward_snapshot: Dictionary = {}
var player_run_state: Dictionary = {}
var dialogue_snapshot: Dictionary = {}
var narrative_flags: Dictionary = {}
var pending_encounter_id: StringName = &""
var world_position := Vector2(70, 102)


func to_dictionary() -> Dictionary:
	return {
		"version": version,
		"floor": floor_snapshot.duplicate(true),
		"rewards": reward_snapshot.duplicate(true),
		"player": player_run_state.duplicate(true),
		"dialogue": dialogue_snapshot.duplicate(true),
		"narrative_flags": narrative_flags.duplicate(true),
		"pending_encounter_id": String(pending_encounter_id),
		"world_position": {"x": world_position.x, "y": world_position.y},
	}


static func from_dictionary(data: Dictionary) -> SessionSnapshot:
	var snapshot := SessionSnapshot.new()
	snapshot.version = int(data.get("version", 0))
	snapshot.floor_snapshot = (data.get("floor", {}) as Dictionary).duplicate(true)
	snapshot.reward_snapshot = (data.get("rewards", {}) as Dictionary).duplicate(true)
	snapshot.player_run_state = (data.get("player", {}) as Dictionary).duplicate(true)
	snapshot.dialogue_snapshot = (data.get("dialogue", {}) as Dictionary).duplicate(true)
	snapshot.narrative_flags = (data.get("narrative_flags", {}) as Dictionary).duplicate(true)
	snapshot.pending_encounter_id = StringName(data.get("pending_encounter_id", ""))
	var world: Dictionary = data.get("world_position", {"x": 70, "y": 102})
	snapshot.world_position = Vector2(float(world.get("x", 70)), float(world.get("y", 102)))
	return snapshot


static func validate_dictionary(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key: String in ["floor", "rewards", "player", "dialogue", "narrative_flags"]:
		if not data.get(key, {}) is Dictionary:
			errors.append("%s must be a dictionary." % key)
	if not errors.is_empty():
		return errors
	var floor: Dictionary = data.get("floor", {})
	var valid_rooms := [
		"room_intake_shelter", "room_broken_junction", "room_maintenance_cache",
		"room_processing_hall", "room_warden_chamber",
	]
	if String(floor.get("floor_id", "")) != "floor_service_level":
		errors.append("Unknown floor_id.")
	if not valid_rooms.has(String(floor.get("current_room_id", ""))):
		errors.append("Unknown current_room_id.")
	var remaining = floor.get("remaining_seconds", -1)
	if not (remaining is int or remaining is float) or int(remaining) < 0 or int(remaining) > 720:
		errors.append("remaining_seconds is outside the floor range.")
	if not floor.get("triggered_thresholds", []) is Array:
		errors.append("triggered_thresholds must be an array.")
	else:
		for threshold in floor.get("triggered_thresholds", []):
			if int(threshold) not in [360, 180, 60, 0]:
				errors.append("Unknown floor threshold.")
	if not floor.get("rooms", {}) is Dictionary:
		errors.append("rooms must be a dictionary.")
	else:
		for room_id in (floor.get("rooms", {}) as Dictionary):
			if not valid_rooms.has(String(room_id)) or not floor["rooms"][room_id] is Dictionary:
				errors.append("Invalid room snapshot %s." % room_id)
				continue
			var room: Dictionary = floor["rooms"][room_id]
			for flag: String in ["visited", "encounter_completed", "interaction_completed"]:
				if room.has(flag) and not room[flag] is bool:
					errors.append("Room flag %s is malformed." % flag)
	var rewards: Dictionary = data.get("rewards", {})
	if not rewards.get("inventory", {}) is Dictionary or not rewards.get("progression", {}) is Dictionary:
		errors.append("Reward state is malformed.")
	else:
		var inventory: Dictionary = rewards.get("inventory", {})
		if not inventory.get("quantities", {}) is Dictionary:
			errors.append("Inventory quantities are malformed.")
		else:
			var quantities: Dictionary = inventory.get("quantities", {})
			var item_catalog := _item_catalog()
			for item_id in quantities:
				var definition := item_catalog.get(StringName(item_id)) as ItemDefinition
				var quantity = quantities[item_id]
				if definition == null:
					errors.append("Unknown inventory item %s." % item_id)
				elif not (quantity is int or quantity is float) or int(quantity) < 0 or int(quantity) > definition.maximum_stack:
					errors.append("Invalid quantity for %s." % item_id)
		if not inventory.get("equipment", {}) is Dictionary:
			errors.append("Equipment state is malformed.")
		else:
			var item_catalog := _item_catalog()
			for slot in (inventory.get("equipment", {}) as Dictionary):
				var item_id := String(inventory["equipment"][slot])
				if not item_id.is_empty() and not item_catalog.has(StringName(item_id)):
					errors.append("Unknown equipped item %s." % item_id)
		if not inventory.get("acquired_unique_items", []) is Array:
			errors.append("Unique item state is malformed.")
		else:
			var item_catalog := _item_catalog()
			for item_id in inventory.get("acquired_unique_items", []):
				if not item_catalog.has(StringName(item_id)):
					errors.append("Unknown unique item %s." % item_id)
		var progression: Dictionary = rewards.get("progression", {})
		if int(progression.get("level", 0)) < 1 or int(progression.get("total_experience", -1)) < 0:
			errors.append("Progression state is malformed.")
	var player: Dictionary = data.get("player", {})
	if player.has("resources") and not player["resources"] is Dictionary:
		errors.append("Player resources are malformed.")
	elif player.has("resources"):
		for resource_id in (player["resources"] as Dictionary):
			var amount = player["resources"][resource_id]
			if not (amount is int or amount is float) or int(amount) < 0:
				errors.append("Player resource %s is malformed." % resource_id)
	var dialogue: Dictionary = data.get("dialogue", {})
	if not dialogue.get("shown_events", []) is Array or not dialogue.get("pending_events", []) is Array:
		errors.append("Dialogue state is malformed.")
	else:
		var valid_dialogue: Dictionary[StringName, bool] = {}
		for event: DialogueEventDefinition in ContentRegistry.get_dialogue_events():
			valid_dialogue[event.content_id] = true
		for key: String in ["shown_events", "pending_events"]:
			for event_id in dialogue.get(key, []):
				if not valid_dialogue.has(StringName(event_id)):
					errors.append("Unknown dialogue event %s." % event_id)
	for flag_id in (data.get("narrative_flags", {}) as Dictionary):
		if not data["narrative_flags"][flag_id] is bool:
			errors.append("Narrative flag %s is malformed." % flag_id)
	var encounter_id := String(data.get("pending_encounter_id", ""))
	if not ["", "encounter_two_enemy", "encounter_warden"].has(encounter_id):
		errors.append("Unknown pending encounter.")
	var room_id := String(floor.get("current_room_id", ""))
	if encounter_id == "encounter_warden" and room_id != "room_warden_chamber":
		errors.append("Warden encounter is not in the Warden chamber.")
	if encounter_id == "encounter_two_enemy" and room_id not in ["room_broken_junction", "room_processing_hall"]:
		errors.append("Ordinary encounter is not in an encounter room.")
	if data.has("world_position"):
		if not data.world_position is Dictionary:
			errors.append("World position must be a dictionary.")
		else:
			for axis: String in ["x", "y"]:
				var coordinate = data.world_position.get(axis, null)
				if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
					errors.append("World position %s is malformed." % axis)
	return errors


static func _item_catalog() -> Dictionary[StringName, ItemDefinition]:
	var catalog: Dictionary[StringName, ItemDefinition] = {}
	for definition: ItemDefinition in PrototypeRewardCatalog.create_items():
		catalog[definition.content_id] = definition
	return catalog


func equivalent_to(other: SessionSnapshot) -> bool:
	if other == null:
		return false
	var self_canonical = JSON.parse_string(JSON.stringify(to_dictionary()))
	var other_canonical = JSON.parse_string(JSON.stringify(other.to_dictionary()))
	return self_canonical == other_canonical
