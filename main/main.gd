class_name Main
extends Node

const DUNGEON_SCREEN := preload("res://scenes/dungeon/dungeon_screen.tscn")

@onready var screen_host: Control = %ScreenHost
@onready var title_screen: TitleScreen = %TitleScreen
@onready var character_setup: CharacterSetup = %CharacterSetup
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var audio_director: AudioDirector = $Services/AudioDirector

var dungeon_screen: DungeonScreen
var settings: Dictionary = {}
var _input_armed: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings = SettingsService.load_settings()
	AudioService.apply_settings(settings)
	title_screen.new_game_requested.connect(_start_new_game)
	title_screen.continue_requested.connect(_continue_game)
	title_screen.recover_requested.connect(_recover_game)
	title_screen.quit_requested.connect(get_tree().quit)
	character_setup.character_confirmed.connect(_begin_new_game)
	character_setup.canceled.connect(_present_title)
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.save_requested.connect(_save_current)
	pause_menu.title_requested.connect(_return_to_title)
	pause_menu.settings_changed.connect(_update_settings)
	_present_title()


func _unhandled_input(event: InputEvent) -> void:
	if not _input_armed or dungeon_screen == null or title_screen.visible:
		return
	if event.is_action_pressed("quick_save") and not pause_menu.visible:
		_save_current()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		if pause_menu.visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_input_armed = false
		if is_node_ready():
			title_screen.set_input_enabled(false)
			character_setup.set_input_enabled(false)
			pause_menu.set_input_enabled(false)
		if is_node_ready() and dungeon_screen != null and not title_screen.visible:
			call_deferred("_pause_game")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		call_deferred("_arm_input_after_focus")


func _arm_input_after_focus() -> void:
	await get_tree().process_frame
	while (
		Input.is_action_pressed("ui_accept")
		or Input.is_action_pressed("confirm")
		or Input.is_action_pressed("cancel")
		or Input.is_action_pressed("menu")
	):
		await get_tree().process_frame
	_input_armed = true
	title_screen.set_input_enabled(true)
	character_setup.set_input_enabled(true)
	pause_menu.set_input_enabled(true)


func _start_new_game() -> void:
	title_screen.visible = false
	character_setup.present()


func _begin_new_game(profile_snapshot: Dictionary) -> void:
	character_setup.visible = false
	_start_session(null, profile_snapshot)
	_save_current()


func _continue_game() -> void:
	var result := SaveService.load_session()
	if not result.get("ok", false):
		_present_title("SAVE COULD NOT BE LOADED // %s" % result.get("error", "unknown"))
		return
	_start_session(result["snapshot"] as SessionSnapshot)
	if result.get("source", "primary") == "backup":
		_pause_game("PRIMARY SAVE DAMAGED // BACKUP RECOVERED")


func _recover_game() -> void:
	var result := SaveService.load_backup()
	if not result.get("ok", false):
		_present_title("BACKUP COULD NOT BE LOADED")
		return
	_start_session(result["snapshot"] as SessionSnapshot)
	_pause_game("BACKUP SAVE RECOVERED")


func _start_session(snapshot: SessionSnapshot, profile_snapshot: Dictionary = {}) -> void:
	audio_director.set_music_mode(AudioDirector.MusicMode.EXPLORATION)
	get_tree().paused = false
	pause_menu.visible = false
	title_screen.visible = false
	character_setup.visible = false
	if dungeon_screen != null:
		dungeon_screen.queue_free()
	dungeon_screen = DUNGEON_SCREEN.instantiate() as DungeonScreen
	if snapshot == null:
		dungeon_screen.new_run_seed = RunVariationRules.create_seed()
		dungeon_screen.new_character_profile = profile_snapshot.duplicate(true)
	dungeon_screen.session_snapshot_changed.connect(_on_session_snapshot_changed)
	screen_host.add_child(dungeon_screen)
	if snapshot != null:
		dungeon_screen.restore_session(snapshot)


func _on_session_snapshot_changed(snapshot: SessionSnapshot) -> void:
	SaveService.save_session(snapshot)


func _save_current() -> void:
	if dungeon_screen == null:
		return
	var result := SaveService.save_session(dungeon_screen.create_session_snapshot())
	pause_menu.set_status("SAVE COMPLETE" if result.get("ok", false) else "SAVE FAILED")


func _pause_game(message: String = "") -> void:
	if dungeon_screen == null or title_screen.visible or pause_menu.visible:
		return
	get_tree().paused = true
	pause_menu.present(settings, message)
	pause_menu.set_input_enabled(_input_armed)
	audio_director.play_ui()


func _resume_game() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	audio_director.play_ui()


func _return_to_title() -> void:
	_save_current()
	get_tree().paused = false
	pause_menu.visible = false
	if dungeon_screen != null:
		dungeon_screen.queue_free()
		dungeon_screen = null
	_present_title("SESSION SAVED")


func _update_settings(updated: Dictionary) -> void:
	settings = SettingsService.sanitize(updated)
	SettingsService.save_settings(settings)
	AudioService.apply_settings(settings)


func _present_title(message: String = "") -> void:
	audio_director.set_music_mode(AudioDirector.MusicMode.TITLE)
	title_screen.set_tutorials_enabled(bool(settings.get("tutorials", true)))
	character_setup.visible = false
	title_screen.present(
		SaveService.has_save(),
		FileAccess.file_exists(SaveService.BACKUP_PATH),
		message,
	)
