class_name ExpeditionGenerator
extends RefCounted

const THEMES: Array[StringName] = [&"service_ruins", &"arc_vault", &"rust_garden"]
const OBJECTIVES: Array[StringName] = [&"restore_relay", &"recover_archive", &"locate_missing_team"]
const CRITICAL_ROLES: Array[StringName] = [&"transit", &"encounter", &"discovery", &"hazard"]
const OPTIONAL_ROLES: Array[StringName] = [&"resource", &"discovery", &"encounter", &"hazard"]


static func generate(requested_seed: int) -> ExpeditionPlan:
	var plan := ExpeditionPlan.new()
	plan.seed = maxi(absi(requested_seed), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = plan.seed
	plan.theme_id = THEMES[rng.randi_range(0, THEMES.size() - 1)]
	plan.objective_id = OBJECTIVES[rng.randi_range(0, OBJECTIVES.size() - 1)]
	var total_rooms := rng.randi_range(ExpeditionPlan.MIN_ROOMS, ExpeditionPlan.MAX_ROOMS)
	var critical_count := rng.randi_range(5, mini(7, total_rooms - 2))
	for index: int in critical_count:
		var room_id := _room_id(index)
		var role := &"entrance" if index == 0 else &"objective" if index == critical_count - 1 else CRITICAL_ROLES[rng.randi_range(0, CRITICAL_ROLES.size() - 1)]
		if index == mini(2, critical_count - 2):
			role = &"encounter"
		plan.add_room(room_id, role, true, index)
		plan.critical_route.append(room_id)
		if index > 0:
			plan.connect_rooms(_room_id(index - 1), room_id)
	plan.start_room_id = plan.critical_route.front()
	plan.objective_room_id = plan.critical_route.back()
	plan.extraction_room_id = plan.start_room_id
	var optional_parents: Array[StringName] = []
	for index: int in range(1, critical_count - 1):
		optional_parents.append(plan.critical_route[index])
	for index: int in range(critical_count, total_rooms):
		var parent_id := optional_parents[rng.randi_range(0, optional_parents.size() - 1)]
		var parent: Dictionary = plan.rooms[parent_id]
		var room_id := _room_id(index)
		var role := OPTIONAL_ROLES[rng.randi_range(0, OPTIONAL_ROLES.size() - 1)]
		plan.add_room(room_id, role, false, int(parent.depth) + 1)
		plan.connect_rooms(parent_id, room_id)
		if int(plan.rooms[room_id].depth) < 3 and rng.randf() < 0.42:
			optional_parents.append(room_id)
	_ensure_encounter_minimum(plan)
	return plan


static func _ensure_encounter_minimum(plan: ExpeditionPlan) -> void:
	if plan.encounter_room_count() >= 2:
		return
	for room_id: StringName in plan.rooms:
		if room_id in [plan.start_room_id, plan.objective_room_id]:
			continue
		var room: Dictionary = plan.rooms[room_id]
		if StringName(room.role) != &"encounter":
			room.role = &"encounter"
			if plan.encounter_room_count() >= 2:
				return


static func _room_id(index: int) -> StringName:
	return StringName("sector_%02d" % index)
