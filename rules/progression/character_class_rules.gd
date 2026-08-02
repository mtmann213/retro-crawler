class_name CharacterClassRules
extends RefCounted

const DEFAULT_CLASS_ID := &"vanguard"
const DEFAULT_COLOR_ID := &"cyan"
const CLASS_ORDER: Array[StringName] = [&"vanguard", &"scavenger", &"signalist"]
const COLOR_ORDER: Array[StringName] = [&"cyan", &"amber", &"violet"]


static func has_class(class_id: StringName) -> bool:
	return CLASS_ORDER.has(class_id)


static func has_color(color_id: StringName) -> bool:
	return COLOR_ORDER.has(color_id)


static func get_definition(class_id: StringName) -> Dictionary:
	match class_id:
		&"scavenger":
			return {
				"display_name": "Scavenger",
				"description": "Fast salvage runner. High Power and Speed, but lighter armor.",
				"max_hp": 90, "power": 14, "defense": 6, "speed": 12,
				"stamina_start": 15, "stamina_max": 45, "patches": 2,
			}
		&"signalist":
			return {
				"display_name": "Signalist",
				"description": "Resource specialist. Deep stamina reserves and extra field support.",
				"max_hp": 95, "power": 11, "defense": 7, "speed": 10,
				"stamina_start": 20, "stamina_max": 50, "patches": 3,
			}
		_:
			return {
				"display_name": "Vanguard",
				"description": "Armored line-breaker. Highest health and defense, with deliberate speed.",
				"max_hp": 100, "power": 12, "defense": 8, "speed": 10,
				"stamina_start": 10, "stamina_max": 40, "patches": 2,
			}


static func apply_profile(player: CombatantState, profile: CharacterProfile) -> void:
	if player == null or profile == null:
		return
	var definition := get_definition(profile.class_id)
	player.display_name = profile.crawler_name
	player.max_hp = int(definition.max_hp)
	player.current_hp = player.max_hp
	player.power = int(definition.power)
	player.defense = int(definition.defense)
	player.speed = int(definition.speed)
	player.set_resource(&"stamina", int(definition.stamina_start), int(definition.stamina_max))
	player.set_resource(&"field_patch_charges", int(definition.patches), int(definition.patches))


static func color_for(color_id: StringName) -> Color:
	match color_id:
		&"amber":
			return Color("fbbf75")
		&"violet":
			return Color("d8b4fe")
		_:
			return Color("a5f3fc")


static func class_summary(class_id: StringName) -> String:
	var definition := get_definition(class_id)
	return "HP %d  POW %d  DEF %d  SPD %d\nSTAMINA %d/%d  PATCHES %d" % [
		int(definition.max_hp), int(definition.power), int(definition.defense), int(definition.speed),
		int(definition.stamina_start), int(definition.stamina_max), int(definition.patches),
	]
