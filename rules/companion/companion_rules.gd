class_name CompanionRules
extends RefCounted

const COMPANION_ID := &"companion_mox"
const DISPLAY_NAME := "MOX"
const FULL_NAME := "MOX-7 SURVEY UNIT"
const ROLE := "Decommissioned Guild survey drone // advanced risk modeler"

const REACTIONS := {
	&"expedition_start": "Survey unit online. I reviewed the survival odds and chose not to share them.",
	&"room_broken_junction": "That junction is broken in at least three professionally distinct ways.",
	&"room_maintenance_cache": "Optional salvage detected. Optional is a word used by people with full supply lockers.",
	&"room_processing_hall": "Processing machinery ahead. Let us avoid becoming an input.",
	&"room_warden_chamber": "Warden signal confirmed. I preferred it when it was theoretical.",
	&"cache_recovered": "Useful supplies acquired. I remain heroically unsurprised.",
	&"warden_defeated": "Threat removed. Updating your file from improbable to statistically irritating.",
	&"emergency_extraction": "Extraction is not retreat. It is survival with better paperwork.",
}

const BOND_GAINS := {
	&"expedition_start": 0,
	&"room_broken_junction": 1,
	&"room_maintenance_cache": 1,
	&"room_processing_hall": 1,
	&"room_warden_chamber": 2,
	&"cache_recovered": 2,
	&"warden_defeated": 4,
	&"emergency_extraction": 1,
}


static func reaction_once(state: CompanionState, trigger_id: StringName) -> String:
	if state == null or not REACTIONS.has(trigger_id):
		return ""
	var memory_id := StringName("reaction:%s" % trigger_id)
	if not state.remember(memory_id, int(BOND_GAINS.get(trigger_id, 0))):
		return ""
	return "%s // %s" % [DISPLAY_NAME, REACTIONS[trigger_id]]
