class_name TitleScreen
extends Control

signal new_game_requested
signal continue_requested
signal recover_requested
signal quit_requested

@onready var continue_button: Button = %ContinueButton
@onready var recover_button: Button = %RecoverButton
@onready var status_label: Label = %StatusLabel
@onready var new_game_button: Button = %NewGameButton
@onready var tutorial_label: Label = %TutorialLabel
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	%NewGameButton.pressed.connect(new_game_requested.emit)
	continue_button.pressed.connect(continue_requested.emit)
	recover_button.pressed.connect(recover_requested.emit)
	%QuitButton.pressed.connect(quit_requested.emit)


func present(has_save: bool, has_backup: bool, message: String = "") -> void:
	visible = true
	continue_button.disabled = not has_save
	recover_button.disabled = not has_backup
	status_label.text = message
	new_game_button.grab_focus()


func set_tutorials_enabled(enabled: bool) -> void:
	tutorial_label.visible = enabled


func set_input_enabled(enabled: bool) -> void:
	new_game_button.disabled = not enabled
	continue_button.disabled = not enabled or not SaveService.has_save()
	recover_button.disabled = not enabled or not FileAccess.file_exists(SaveService.BACKUP_PATH)
	quit_button.disabled = not enabled
