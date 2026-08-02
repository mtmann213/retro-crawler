class_name PauseMenu
extends Control

signal resume_requested
signal save_requested
signal title_requested
signal settings_changed(settings: Dictionary)

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var effects_slider: HSlider = %EffectsSlider
@onready var mute_check: CheckButton = %MuteCheck
@onready var tutorials_check: CheckButton = %TutorialsCheck
@onready var tutorial_label: Label = %TutorialLabel
@onready var status_label: Label = %StatusLabel

var _settings: Dictionary = {}
var _presenting: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%ResumeButton.pressed.connect(resume_requested.emit)
	%SaveButton.pressed.connect(save_requested.emit)
	%TitleButton.pressed.connect(title_requested.emit)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	effects_slider.value_changed.connect(_on_effects_changed)
	mute_check.toggled.connect(_on_mute_changed)
	tutorials_check.toggled.connect(_on_tutorials_changed)
	visible = false


func present(settings: Dictionary, message: String = "") -> void:
	_presenting = true
	_settings = settings.duplicate(true)
	master_slider.value = float(_settings.get("master_volume", 0.8)) * 100.0
	music_slider.value = float(_settings.get("music_volume", 0.7)) * 100.0
	effects_slider.value = float(_settings.get("effects_volume", 0.8)) * 100.0
	mute_check.button_pressed = bool(_settings.get("muted", false))
	tutorials_check.button_pressed = bool(_settings.get("tutorials", true))
	tutorial_label.visible = tutorials_check.button_pressed
	status_label.text = message
	visible = true
	_presenting = false
	%ResumeButton.grab_focus()


func set_status(message: String) -> void:
	status_label.text = message


func _on_master_changed(value: float) -> void:
	_settings["master_volume"] = value / 100.0
	_emit_settings()


func _on_music_changed(value: float) -> void:
	_settings["music_volume"] = value / 100.0
	_emit_settings()


func _on_effects_changed(value: float) -> void:
	_settings["effects_volume"] = value / 100.0
	_emit_settings()


func _on_mute_changed(enabled: bool) -> void:
	_settings["muted"] = enabled
	_emit_settings()


func _on_tutorials_changed(enabled: bool) -> void:
	_settings["tutorials"] = enabled
	tutorial_label.visible = enabled
	_emit_settings()


func _emit_settings() -> void:
	if not _presenting:
		settings_changed.emit(_settings.duplicate(true))
