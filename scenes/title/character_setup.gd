class_name CharacterSetup
extends Control

signal character_confirmed(profile_snapshot: Dictionary)
signal canceled

const PLAYER_TEXTURE := preload("res://assets/characters/crawler_topdown.png")

@onready var name_edit: LineEdit = %NameEdit
@onready var class_description: Label = %ClassDescription
@onready var class_stats: Label = %ClassStats
@onready var preview: TextureRect = %Preview
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton

var selected_class_id: StringName = CharacterClassRules.DEFAULT_CLASS_ID
var selected_color_id: StringName = CharacterClassRules.DEFAULT_COLOR_ID


func _ready() -> void:
	%VanguardButton.pressed.connect(_select_class.bind(&"vanguard"))
	%ScavengerButton.pressed.connect(_select_class.bind(&"scavenger"))
	%SignalistButton.pressed.connect(_select_class.bind(&"signalist"))
	%CyanButton.pressed.connect(_select_color.bind(&"cyan"))
	%AmberButton.pressed.connect(_select_color.bind(&"amber"))
	%VioletButton.pressed.connect(_select_color.bind(&"violet"))
	confirm_button.pressed.connect(_confirm)
	back_button.pressed.connect(canceled.emit)
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_TEXTURE
	atlas.region = Rect2(340, 180, 580, 770)
	preview.texture = atlas
	_refresh_view()


func present() -> void:
	visible = true
	selected_class_id = CharacterClassRules.DEFAULT_CLASS_ID
	selected_color_id = CharacterClassRules.DEFAULT_COLOR_ID
	name_edit.text = CharacterProfile.DEFAULT_NAME
	_refresh_view()
	name_edit.grab_focus()
	name_edit.select_all()


func set_input_enabled(enabled: bool) -> void:
	for control: Control in find_children("*", "Button", true, false):
		(control as Button).disabled = not enabled
	name_edit.editable = enabled


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		canceled.emit()
		get_viewport().set_input_as_handled()


func _select_class(class_id: StringName) -> void:
	selected_class_id = class_id
	_refresh_view()


func _select_color(color_id: StringName) -> void:
	selected_color_id = color_id
	_refresh_view()


func _refresh_view() -> void:
	if not is_node_ready():
		return
	var definition := CharacterClassRules.get_definition(selected_class_id)
	class_description.text = String(definition.display_name).to_upper() + " // " + String(definition.description)
	class_stats.text = CharacterClassRules.class_summary(selected_class_id)
	preview.modulate = CharacterClassRules.color_for(selected_color_id)
	%VanguardButton.text = ("> " if selected_class_id == &"vanguard" else "") + "VANGUARD"
	%ScavengerButton.text = ("> " if selected_class_id == &"scavenger" else "") + "SCAVENGER"
	%SignalistButton.text = ("> " if selected_class_id == &"signalist" else "") + "SIGNALIST"
	%CyanButton.text = ("> " if selected_color_id == &"cyan" else "") + "CYAN"
	%AmberButton.text = ("> " if selected_color_id == &"amber" else "") + "AMBER"
	%VioletButton.text = ("> " if selected_color_id == &"violet" else "") + "VIOLET"


func _confirm() -> void:
	var profile := CharacterProfile.new(name_edit.text, selected_class_id, selected_color_id)
	character_confirmed.emit(profile.to_snapshot())
