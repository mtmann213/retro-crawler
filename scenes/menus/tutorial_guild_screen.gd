class_name TutorialGuildScreen
extends Control

signal continue_requested
signal progress_changed

@onready var lesson_list: VBoxContainer = %LessonList
@onready var progress_label: Label = %ProgressLabel
@onready var lesson_title: Label = %LessonTitle
@onready var lesson_summary: Label = %LessonSummary
@onready var briefing: RichTextLabel = %Briefing
@onready var complete_button: Button = %CompleteButton
@onready var continue_button: Button = %ContinueButton

var guild_state: TutorialGuildState
var character_profile: CharacterProfile
var selected_lesson_id: StringName = &"guild_orientation"


func _ready() -> void:
	complete_button.pressed.connect(_complete_selected)
	continue_button.pressed.connect(_continue)


func present(profile: CharacterProfile, state: TutorialGuildState) -> void:
	character_profile = profile
	guild_state = state
	selected_lesson_id = &"guild_orientation"
	visible = true
	_rebuild_lessons()
	_refresh_lesson()
	continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_continue()
		get_viewport().set_input_as_handled()


func _rebuild_lessons() -> void:
	for child: Node in lesson_list.get_children():
		child.queue_free()
	for lesson_id: StringName in TutorialGuildRules.LESSON_IDS:
		var lesson := TutorialGuildRules.get_lesson(lesson_id, character_profile)
		var button := Button.new()
		button.name = String(lesson_id)
		button.text = _lesson_button_text(lesson_id, String(lesson.title))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = lesson_id == selected_lesson_id
		button.pressed.connect(_select_lesson.bind(lesson_id))
		lesson_list.add_child(button)
	progress_label.text = "CERTIFICATION // %d/%d LESSONS" % [
		guild_state.completed_count(), TutorialGuildRules.LESSON_IDS.size(),
	]


func _select_lesson(lesson_id: StringName) -> void:
	selected_lesson_id = lesson_id
	for child: Node in lesson_list.get_children():
		if child is Button:
			var button := child as Button
			var child_id := StringName(button.name)
			var lesson := TutorialGuildRules.get_lesson(child_id, character_profile)
			button.button_pressed = child_id == selected_lesson_id
			button.text = _lesson_button_text(child_id, String(lesson.title))
	_refresh_lesson()


func _lesson_button_text(lesson_id: StringName, title: String) -> String:
	var selection := "> " if lesson_id == selected_lesson_id else "  "
	var status := "[COMPLETE] " if guild_state.is_completed(lesson_id) else "[OPEN] "
	return selection + status + title


func _refresh_lesson() -> void:
	var lesson := TutorialGuildRules.get_lesson(selected_lesson_id, character_profile)
	lesson_title.text = String(lesson.title)
	lesson_summary.text = String(lesson.summary)
	briefing.text = "[color=#94a3b8]GUILD DISPATCH // OPERATOR CODA[/color]\n\n" + String(lesson.body)
	complete_button.disabled = guild_state.is_completed(selected_lesson_id)
	complete_button.text = "LESSON COMPLETE" if complete_button.disabled else "MARK LESSON COMPLETE"


func _complete_selected() -> void:
	if not guild_state.complete_lesson(selected_lesson_id):
		return
	_rebuild_lessons()
	_refresh_lesson()
	progress_changed.emit()


func _continue() -> void:
	visible = false
	continue_requested.emit()
