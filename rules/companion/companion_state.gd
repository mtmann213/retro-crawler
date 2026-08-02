class_name CompanionState
extends RefCounted

const MAX_BOND := 100
const DEFAULT_DIRECTIVE := &"investigate"
const DIRECTIVES: Array[StringName] = [&"safeguard", &"investigate", &"conserve"]

var bond: int = 0
var directive: StringName = DEFAULT_DIRECTIVE
var memories: Dictionary[StringName, bool] = {}


func remember(memory_id: StringName, bond_gain: int = 1) -> bool:
	if memory_id.is_empty() or memories.get(memory_id, false):
		return false
	memories[memory_id] = true
	bond = clampi(bond + maxi(bond_gain, 0), 0, MAX_BOND)
	return true


func remembers(memory_id: StringName) -> bool:
	return memories.get(memory_id, false)


func set_directive(requested_directive: StringName) -> bool:
	if not DIRECTIVES.has(requested_directive):
		return false
	directive = requested_directive
	return true


func to_snapshot() -> Dictionary:
	var memory_ids: Array[String] = []
	for memory_id: StringName in memories:
		if memories[memory_id]:
			memory_ids.append(String(memory_id))
	memory_ids.sort()
	return {
		"bond": bond,
		"directive": String(directive),
		"memories": memory_ids,
	}


static func from_snapshot(snapshot: Dictionary) -> CompanionState:
	var state := CompanionState.new()
	state.bond = clampi(int(snapshot.get("bond", 0)), 0, MAX_BOND)
	state.set_directive(StringName(snapshot.get("directive", DEFAULT_DIRECTIVE)))
	for memory_id in snapshot.get("memories", []):
		var normalized := StringName(memory_id)
		if not normalized.is_empty():
			state.memories[normalized] = true
	return state


static func validate_snapshot(snapshot: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var requested_bond = snapshot.get("bond", 0)
	if not (requested_bond is int or requested_bond is float) or int(requested_bond) < 0 or int(requested_bond) > MAX_BOND:
		errors.append("Companion bond is outside its valid range.")
	if not DIRECTIVES.has(StringName(snapshot.get("directive", DEFAULT_DIRECTIVE))):
		errors.append("Unknown companion directive.")
	if not snapshot.get("memories", []) is Array:
		errors.append("Companion memories must be an array.")
	else:
		for memory_id in snapshot.get("memories", []):
			if not memory_id is String or String(memory_id).is_empty():
				errors.append("Companion memory ID is malformed.")
	return errors
