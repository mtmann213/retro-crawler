class_name SettingsService
extends RefCounted

const SETTINGS_PATH := "user://settings.json"
const DEFAULTS := {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"effects_volume": 0.8,
	"muted": false,
	"tutorials": true,
}


static func load_settings(path: String = SETTINGS_PATH) -> Dictionary:
	var settings := DEFAULTS.duplicate(true)
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			settings.merge(parsed as Dictionary, true)
	return sanitize(settings)


static func save_settings(settings: Dictionary, path: String = SETTINGS_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(sanitize(settings), "  "))
	return file.get_error() == OK


static func sanitize(settings: Dictionary) -> Dictionary:
	return {
		"master_volume": clampf(float(settings.get("master_volume", DEFAULTS.master_volume)), 0.0, 1.0),
		"music_volume": clampf(float(settings.get("music_volume", DEFAULTS.music_volume)), 0.0, 1.0),
		"effects_volume": clampf(float(settings.get("effects_volume", DEFAULTS.effects_volume)), 0.0, 1.0),
		"muted": bool(settings.get("muted", false)),
		"tutorials": bool(settings.get("tutorials", true)),
	}
