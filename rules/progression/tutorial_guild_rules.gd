class_name TutorialGuildRules
extends RefCounted

const LESSON_IDS: Array[StringName] = [
	&"guild_orientation",
	&"movement_and_time",
	&"combat_intents",
	&"inventory_loadout",
	&"class_doctrine",
]


static func has_lesson(lesson_id: StringName) -> bool:
	return LESSON_IDS.has(lesson_id)


static func get_lesson(lesson_id: StringName, profile: CharacterProfile = null) -> Dictionary:
	match lesson_id:
		&"movement_and_time":
			return {
				"title": "FIELD MOVEMENT",
				"summary": "Walking, room costs, and the shutdown clock",
				"body": "Walk with WASD, arrows, or the D-pad. Free movement inside a room costs no time. Entering a connected room costs 15 seconds. Menus pause dungeon decisions, but combat actions and field items display their exact time cost before you commit.",
			}
		&"combat_intents":
			return {
				"title": "READ THE INTENT",
				"summary": "Targets, telegraphs, defense, and tempo",
				"body": "Approach a hostile contact to engage. Read every enemy intent before acting: it shows the incoming skill, damage range, and time cost. Select targets deliberately. Brace reduces the next hit; Hamstring changes turn order; every committed action advances the dungeon clock.",
			}
		&"inventory_loadout":
			return {
				"title": "RECOVERY AND LOADOUT",
				"summary": "Loot, equipment, field patches, and detours",
				"body": "Inventory access costs no time. Equipment changes statistics immediately and remains equipped across encounters. Consumables show their field-time cost. The Maintenance Cache is optional: its supplies help, but reaching and searching it consumes precious seconds.",
			}
		&"class_doctrine":
			return {
				"title": "CLASS DOCTRINE",
				"summary": "Use your crawler profile instead of fighting the baseline",
				"body": _class_guidance(profile),
			}
		_:
			return {
				"title": "GUILD ORIENTATION",
				"summary": "The Service Level contract and safe extraction",
				"body": "Guild Dispatch has one rule: information is equipment. Leave the Intake Shelter when ready; that starts the 12-minute shutdown clock. Clear locked routes, reach the Warden Chamber, and defeat the Warden—or use emergency extraction when survival matters more than completion.",
			}


static func _class_guidance(profile: CharacterProfile) -> String:
	var class_id := profile.class_id if profile != null else CharacterClassRules.DEFAULT_CLASS_ID
	match class_id:
		&"scavenger":
			return "Scavenger doctrine: your Power and Speed reward decisive fights. Lighter armor makes prolonged exchanges dangerous. Use Hamstring to control tempo, focus one target, and treat Brace as insurance rather than a default turn."
		&"signalist":
			return "Signalist doctrine: your deep stamina reserve supports flexible skill chains and an extra patch. Your direct combat statistics are lighter, so read intents, preserve charges, and convert resources into control before pressure escalates."
		_:
			return "Vanguard doctrine: your balanced frame matches the Guild baseline. Absorb pressure with Brace, choose targets methodically, and spend stamina steadily. You lack an extreme advantage, but no encounter exposes a severe class weakness."
