class_name ContentRegistry
extends RefCounted

const WARDEN_ENEMY_PATH := "res://content/enemies/enemy_warden_unit.tres"
const WARDEN_ENCOUNTER_PATH := "res://content/encounters/encounter_warden.tres"
const WORLD_LAYOUT_PATH := "res://content/worlds/service_level_layout.tres"
const DIALOGUE_PATHS: Array[String] = [
	"res://content/dialogue/floor_intro.tres",
	"res://content/dialogue/junction_intro.tres",
	"res://content/dialogue/cache_found.tres",
	"res://content/dialogue/cache_achievement.tres",
	"res://content/dialogue/processing_intro.tres",
	"res://content/dialogue/warden_intro.tres",
	"res://content/dialogue/phase_containment.tres",
	"res://content/dialogue/phase_purge.tres",
	"res://content/dialogue/victory_ending.tres",
	"res://content/dialogue/extraction_ending.tres",
]


static func get_warden_enemy() -> EnemyDefinition:
	return load(WARDEN_ENEMY_PATH) as EnemyDefinition


static func get_warden_encounter() -> EncounterDefinition:
	return load(WARDEN_ENCOUNTER_PATH) as EncounterDefinition


static func get_dialogue_events() -> Array[DialogueEventDefinition]:
	var events: Array[DialogueEventDefinition] = []
	for path: String in DIALOGUE_PATHS:
		events.append(load(path) as DialogueEventDefinition)
	return events


static func get_world_layout() -> WorldLayoutDefinition:
	return load(WORLD_LAYOUT_PATH) as WorldLayoutDefinition


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var enemy := get_warden_enemy()
	var encounter := get_warden_encounter()
	var world_layout := get_world_layout()
	if enemy == null:
		errors.append("Warden enemy content could not be loaded.")
	else:
		errors.append_array(enemy.validate())
	if encounter == null:
		errors.append("Warden encounter content could not be loaded.")
	else:
		errors.append_array(encounter.validate())
		if enemy != null and not encounter.enemy_definition_ids.has(enemy.content_id):
			errors.append("Warden encounter does not reference the Warden enemy.")
	if world_layout == null:
		errors.append("Service Level world layout could not be loaded.")
	else:
		errors.append_array(world_layout.validate())
	var ids: Dictionary[StringName, bool] = {}
	for event: DialogueEventDefinition in get_dialogue_events():
		if event == null:
			errors.append("Dialogue content could not be loaded.")
			continue
		errors.append_array(event.validate())
		if ids.has(event.content_id):
			errors.append("Duplicate dialogue ID %s." % event.content_id)
		ids[event.content_id] = true
	return errors
