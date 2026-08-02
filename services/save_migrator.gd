class_name SaveMigrator
extends RefCounted


static func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version == SessionSnapshot.CURRENT_VERSION:
		return {"ok": true, "data": data}
	return {
		"ok": false,
		"error": "unsupported_save_version",
		"version": version,
	}
