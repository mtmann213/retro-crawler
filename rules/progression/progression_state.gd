class_name ProgressionState
extends RefCounted

var level: int = 1
var total_experience: int = 0


func to_snapshot() -> Dictionary:
	return {"level": level, "total_experience": total_experience}


static func from_snapshot(snapshot: Dictionary) -> ProgressionState:
	var state := ProgressionState.new()
	state.level = maxi(1, int(snapshot.get("level", 1)))
	state.total_experience = maxi(0, int(snapshot.get("total_experience", 0)))
	return state
