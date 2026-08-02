class_name SaveService
extends RefCounted

const PRIMARY_PATH := "user://session.json"
const BACKUP_PATH := "user://session.backup.json"


static func save_session(
	snapshot: SessionSnapshot,
	primary_path: String = PRIMARY_PATH,
	backup_path: String = BACKUP_PATH,
) -> Dictionary:
	if snapshot == null:
		return {"ok": false, "error": "invalid_snapshot"}
	var temporary_path := primary_path + ".tmp"
	var payload := JSON.stringify(snapshot.to_dictionary(), "  ")
	if not _write_text(temporary_path, payload):
		return {"ok": false, "error": "temporary_write_failed"}
	if not _load_path(temporary_path).get("ok", false):
		_remove_path(temporary_path)
		return {"ok": false, "error": "temporary_validation_failed"}
	if FileAccess.file_exists(primary_path):
		var existing_result := _load_path(primary_path)
		if existing_result.get("ok", false):
			var existing := FileAccess.get_file_as_string(primary_path)
			if not _write_text(backup_path, existing):
				_remove_path(temporary_path)
				return {"ok": false, "error": "backup_write_failed"}
			if not _load_path(backup_path).get("ok", false):
				_remove_path(temporary_path)
				return {"ok": false, "error": "backup_validation_failed"}
		if not _remove_path(primary_path):
			_remove_path(temporary_path)
			return {"ok": false, "error": "primary_replace_failed"}
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(primary_path),
	)
	if rename_error != OK:
		return {"ok": false, "error": "primary_promote_failed"}
	return {"ok": true, "path": primary_path}


static func load_session(
	primary_path: String = PRIMARY_PATH,
	backup_path: String = BACKUP_PATH,
) -> Dictionary:
	var primary := _load_path(primary_path)
	if primary.get("ok", false):
		primary["source"] = "primary"
		return primary
	var backup := _load_path(backup_path)
	if backup.get("ok", false):
		backup["source"] = "backup"
		backup["primary_error"] = primary.get("error", "load_failed")
		return backup
	return {
		"ok": false,
		"error": primary.get("error", "save_not_found"),
		"backup_error": backup.get("error", "save_not_found"),
	}


static func load_backup(backup_path: String = BACKUP_PATH) -> Dictionary:
	var result := _load_path(backup_path)
	if result.get("ok", false):
		result["source"] = "backup"
	return result


static func has_save(primary_path: String = PRIMARY_PATH, backup_path: String = BACKUP_PATH) -> bool:
	return FileAccess.file_exists(primary_path) or FileAccess.file_exists(backup_path)


static func _load_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "save_not_found"}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {"ok": false, "error": "corrupted_save"}
	var parsed = json.data
	if not parsed is Dictionary:
		return {"ok": false, "error": "corrupted_save"}
	var migration := SaveMigrator.migrate(parsed as Dictionary)
	if not migration.get("ok", false):
		return migration
	var migrated_data := migration["data"] as Dictionary
	var validation_errors := SessionSnapshot.validate_dictionary(migrated_data)
	if not validation_errors.is_empty():
		return {"ok": false, "error": "corrupted_save", "details": validation_errors}
	var snapshot := SessionSnapshot.from_dictionary(migrated_data)
	return {"ok": true, "snapshot": snapshot}


static func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var succeeded := file.get_error() == OK
	file.close()
	return succeeded


static func _remove_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
