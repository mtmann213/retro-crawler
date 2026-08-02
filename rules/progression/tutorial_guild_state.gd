class_name TutorialGuildState
extends RefCounted

var completed_lessons: Dictionary[StringName, bool] = {}


func complete_lesson(lesson_id: StringName) -> bool:
	if not TutorialGuildRules.has_lesson(lesson_id) or completed_lessons.get(lesson_id, false):
		return false
	completed_lessons[lesson_id] = true
	return true


func is_completed(lesson_id: StringName) -> bool:
	return completed_lessons.get(lesson_id, false)


func completed_count() -> int:
	var count := 0
	for completed: bool in completed_lessons.values():
		if completed:
			count += 1
	return count


func to_snapshot() -> Dictionary:
	var completed: Array[String] = []
	for lesson_id: StringName in completed_lessons:
		if completed_lessons[lesson_id]:
			completed.append(String(lesson_id))
	completed.sort()
	return {"completed_lessons": completed}


static func from_snapshot(snapshot: Dictionary) -> TutorialGuildState:
	var state := TutorialGuildState.new()
	for lesson_id: String in snapshot.get("completed_lessons", []):
		if TutorialGuildRules.has_lesson(StringName(lesson_id)):
			state.completed_lessons[StringName(lesson_id)] = true
	return state
