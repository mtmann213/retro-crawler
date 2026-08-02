class_name SessionSnapshot
extends RefCounted

const CURRENT_VERSION := 1

var version: int = CURRENT_VERSION
var floor_snapshot: Dictionary = {}
var reward_snapshot: Dictionary = {}
var player_run_state: Dictionary = {}
var dialogue_snapshot: Dictionary = {}
var narrative_flags: Dictionary = {}


func to_dictionary() -> Dictionary:
	return {
		"version": version,
		"floor": floor_snapshot.duplicate(true),
		"rewards": reward_snapshot.duplicate(true),
		"player": player_run_state.duplicate(true),
		"dialogue": dialogue_snapshot.duplicate(true),
		"narrative_flags": narrative_flags.duplicate(true),
	}


static func from_dictionary(data: Dictionary) -> SessionSnapshot:
	var snapshot := SessionSnapshot.new()
	snapshot.version = int(data.get("version", 0))
	snapshot.floor_snapshot = (data.get("floor", {}) as Dictionary).duplicate(true)
	snapshot.reward_snapshot = (data.get("rewards", {}) as Dictionary).duplicate(true)
	snapshot.player_run_state = (data.get("player", {}) as Dictionary).duplicate(true)
	snapshot.dialogue_snapshot = (data.get("dialogue", {}) as Dictionary).duplicate(true)
	snapshot.narrative_flags = (data.get("narrative_flags", {}) as Dictionary).duplicate(true)
	return snapshot


func equivalent_to(other: SessionSnapshot) -> bool:
	if other == null:
		return false
	var self_canonical = JSON.parse_string(JSON.stringify(to_dictionary()))
	var other_canonical = JSON.parse_string(JSON.stringify(other.to_dictionary()))
	return self_canonical == other_canonical
