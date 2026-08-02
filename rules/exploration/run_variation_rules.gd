class_name RunVariationRules
extends RefCounted

const DEFAULT_SEED := 731_2026
const MAX_SEED := 2_147_483_646
const THEMES: Array[StringName] = [&"cold", &"emergency", &"arc"]

static var _last_seed := DEFAULT_SEED


static func create_seed() -> int:
	var seed_value := absi((int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()) % MAX_SEED) + 1
	if seed_value == _last_seed:
		seed_value = (seed_value % MAX_SEED) + 1
	_last_seed = seed_value
	return seed_value


static func generate(seed_value: int, definition: FloorDefinition) -> Dictionary:
	var safe_seed := seed_value if seed_value > 0 else DEFAULT_SEED
	var rng := RandomNumberGenerator.new()
	rng.seed = safe_seed
	var theme_id := THEMES[rng.randi_range(0, THEMES.size() - 1)]
	var room_variants := {}
	for room: RoomDefinition in definition.rooms:
		room_variants[String(room.content_id)] = {
			"hazard_pattern": rng.randi_range(0, 2),
			"light_phase": rng.randf_range(0.0, TAU),
		}
	var processing_encounter := (
		PrototypeEncounter.BRUTE_ENCOUNTER_ID
		if rng.randi_range(0, 1) == 1
		else PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID
	)
	return {
		"seed": safe_seed,
		"theme_id": String(theme_id),
		"cache_patch_count": rng.randi_range(1, 3),
		"encounters": {
			"room_broken_junction": String(PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID),
			"room_processing_hall": String(processing_encounter),
			"room_warden_chamber": String(PrototypeEncounter.WARDEN_ENCOUNTER_ID),
		},
		"rooms": room_variants,
	}


static func encounter_for_room(variation: Dictionary, room: RoomDefinition) -> StringName:
	if room == null:
		return &""
	var encounters: Dictionary = variation.get("encounters", {})
	return StringName(encounters.get(String(room.content_id), String(room.encounter_id)))


static func combat_seed(run_seed: int, room_id: StringName) -> int:
	var room_hash := String(room_id).hash()
	return absi((run_seed * 31 + room_hash * 17) % MAX_SEED) + 1


static func cache_patch_count(variation: Dictionary) -> int:
	return clampi(int(variation.get("cache_patch_count", 2)), 1, 3)


static func room_flavor(variation: Dictionary) -> String:
	match StringName(variation.get("theme_id", "cold")):
		&"emergency":
			return "Emergency lamps strobe through suspended iron dust."
		&"arc":
			return "Violet arc residue crawls across exposed conduits."
		_:
			return "Cold condensation hangs over the dormant machinery."


static func summary(variation: Dictionary) -> String:
	return "SEED %d // %s CIRCUIT" % [
		int(variation.get("seed", DEFAULT_SEED)),
		String(variation.get("theme_id", "cold")).to_upper(),
	]
