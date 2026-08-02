class_name AnnouncementPanel
extends PanelContainer

@onready var kind_label: Label = %KindLabel
@onready var speaker_label: Label = %SpeakerLabel
@onready var body_label: Label = %BodyLabel
@onready var dismiss_button: Button = %DismissButton

var _queue: Array[DialogueEventDefinition] = []


func _ready() -> void:
	dismiss_button.pressed.connect(_advance)
	visible = false


func present_events(events: Array[DialogueEventDefinition]) -> void:
	_queue.append_array(events)
	if not visible:
		_advance()


func _advance() -> void:
	if _queue.is_empty():
		visible = false
		return
	var event: DialogueEventDefinition = _queue.pop_front()
	kind_label.text = DialogueEventDefinition.Presentation.keys()[event.presentation]
	speaker_label.text = event.speaker.to_upper()
	body_label.text = event.text
	visible = true
	dismiss_button.grab_focus()
