class_name AudioService
extends RefCounted


static func apply_settings(settings: Dictionary) -> void:
	_set_bus_volume("Master", float(settings.get("master_volume", 0.8)))
	_set_bus_volume("Music", float(settings.get("music_volume", 0.7)))
	_set_bus_volume("Effects", float(settings.get("effects_volume", 0.8)))
	var master_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_index, bool(settings.get("muted", false)))


static func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(linear) if linear > 0.0 else -80.0)
