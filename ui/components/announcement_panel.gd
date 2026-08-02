class_name AnnouncementPanel
extends PanelContainer

signal event_acknowledged(event_id: StringName)

@onready var kind_label: Label = %KindLabel
@onready var speaker_label: Label = %SpeakerLabel
@onready var body_label: Label = %BodyLabel
@onready var dismiss_button: Button = %DismissButton

var _queue: Array[DialogueEventDefinition] = []
var _current_event: DialogueEventDefinition


func _ready() -> void:
	dismiss_button.pressed.connect(_advance)
	visible = false


func present_events(events: Array[DialogueEventDefinition]) -> void:
	_queue.append_array(events)
	if not visible:
		_advance()


func _advance() -> void:
	if _current_event != null:
		event_acknowledged.emit(_current_event.content_id)
		_current_event = null
	if _queue.is_empty():
		visible = false
		return
	_current_event = _queue.pop_front()
	kind_label.text = DialogueEventDefinition.Presentation.keys()[_current_event.presentation]
	speaker_label.text = _current_event.speaker.to_upper()
	body_label.text = _current_event.text
	visible = true
	dismiss_button.grab_focus()


func pending_event_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if _current_event != null:
		ids.append(_current_event.content_id)
	for event: DialogueEventDefinition in _queue:
		ids.append(event.content_id)
	return ids
