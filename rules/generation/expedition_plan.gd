class_name ExpeditionPlan
extends RefCounted

const MIN_ROOMS := 8
const MAX_ROOMS := 12
const VALID_ROLES: Array[StringName] = [
	&"entrance", &"transit", &"encounter", &"discovery", &"resource",
	&"hazard", &"objective",
]

var seed: int = 1
var theme_id: StringName = &"service_ruins"
var objective_id: StringName = &"restore_relay"
var start_room_id: StringName = &""
var objective_room_id: StringName = &""
var extraction_room_id: StringName = &""
var critical_route: Array[StringName] = []
var rooms: Dictionary[StringName, Dictionary] = {}


func add_room(room_id: StringName, role: StringName, critical: bool, depth: int) -> bool:
	if room_id.is_empty() or rooms.has(room_id):
		return false
	rooms[room_id] = {
		"role": role,
		"critical": critical,
		"depth": maxi(depth, 0),
		"neighbors": [] as Array[StringName],
	}
	return true


func connect_rooms(first_id: StringName, second_id: StringName) -> bool:
	if first_id == second_id or not rooms.has(first_id) or not rooms.has(second_id):
		return false
	var first := rooms[first_id]
	var second := rooms[second_id]
	var first_neighbors: Array[StringName] = first.neighbors
	var second_neighbors: Array[StringName] = second.neighbors
	if not first_neighbors.has(second_id):
		first_neighbors.append(second_id)
	if not second_neighbors.has(first_id):
		second_neighbors.append(first_id)
	return true


func neighbors(room_id: StringName) -> Array[StringName]:
	if not rooms.has(room_id):
		return []
	return ((rooms[room_id] as Dictionary).neighbors as Array[StringName]).duplicate()


func optional_room_count() -> int:
	var count := 0
	for room: Dictionary in rooms.values():
		if not bool(room.critical):
			count += 1
	return count


func encounter_room_count() -> int:
	var count := 0
	for room: Dictionary in rooms.values():
		if StringName(room.role) == &"encounter":
			count += 1
	return count


func is_reachable(from_id: StringName, to_id: StringName) -> bool:
	if not rooms.has(from_id) or not rooms.has(to_id):
		return false
	var frontier: Array[StringName] = [from_id]
	var visited: Dictionary[StringName, bool] = {from_id: true}
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		if current == to_id:
			return true
		for neighbor: StringName in neighbors(current):
			if not visited.get(neighbor, false):
				visited[neighbor] = true
				frontier.append(neighbor)
	return false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if seed <= 0:
		errors.append("Expedition seed must be positive.")
	if rooms.size() < MIN_ROOMS or rooms.size() > MAX_ROOMS:
		errors.append("Expedition room count must be between %d and %d." % [MIN_ROOMS, MAX_ROOMS])
	for required_id: StringName in [start_room_id, objective_room_id, extraction_room_id]:
		if required_id.is_empty() or not rooms.has(required_id):
			errors.append("Expedition references a missing required room.")
	if not errors.is_empty():
		return errors
	if StringName(rooms[start_room_id].role) != &"entrance":
		errors.append("Start room must use the entrance role.")
	if StringName(rooms[objective_room_id].role) != &"objective":
		errors.append("Objective room must use the objective role.")
	if critical_route.is_empty() or critical_route.front() != start_room_id or critical_route.back() != objective_room_id:
		errors.append("Critical route must connect the entrance to the objective.")
	for room_id: StringName in rooms:
		var room: Dictionary = rooms[room_id]
		if not VALID_ROLES.has(StringName(room.get("role", ""))):
			errors.append("Room %s has an unknown role." % room_id)
		if not room.get("neighbors", []) is Array:
			errors.append("Room %s neighbors are malformed." % room_id)
			continue
		for neighbor_id: StringName in room.neighbors:
			if neighbor_id == room_id or not rooms.has(neighbor_id):
				errors.append("Room %s has an invalid connection." % room_id)
			elif not neighbors(neighbor_id).has(room_id):
				errors.append("Connection %s to %s is not symmetric." % [room_id, neighbor_id])
	for index: int in critical_route.size():
		var room_id := critical_route[index]
		if not rooms.has(room_id) or not bool(rooms[room_id].critical):
			errors.append("Critical route contains an invalid room.")
		elif index > 0 and not neighbors(critical_route[index - 1]).has(room_id):
			errors.append("Critical route contains a disconnected step.")
	if optional_room_count() < 2:
		errors.append("Expedition requires at least two optional rooms.")
	if encounter_room_count() < 2:
		errors.append("Expedition requires at least two encounter rooms.")
	if not is_reachable(start_room_id, objective_room_id):
		errors.append("Objective is unreachable from the entrance.")
	if not is_reachable(objective_room_id, extraction_room_id):
		errors.append("Extraction is unreachable from the objective.")
	var reachable_count := 0
	for room_id: StringName in rooms:
		if is_reachable(start_room_id, room_id):
			reachable_count += 1
	if reachable_count != rooms.size():
		errors.append("Expedition contains unreachable rooms.")
	return errors


func summary() -> String:
	return "%s // %d rooms // %d critical // %d optional // %s" % [
		String(theme_id).to_upper(), rooms.size(), critical_route.size(),
		optional_room_count(), String(objective_id).to_upper(),
	]


func to_snapshot() -> Dictionary:
	var ordered_ids: Array[StringName] = []
	ordered_ids.assign(rooms.keys())
	ordered_ids.sort()
	var room_snapshots: Array[Dictionary] = []
	for room_id: StringName in ordered_ids:
		var room: Dictionary = rooms[room_id]
		var ordered_neighbors: Array[StringName] = neighbors(room_id)
		ordered_neighbors.sort()
		var neighbor_strings: Array[String] = []
		for neighbor_id: StringName in ordered_neighbors:
			neighbor_strings.append(String(neighbor_id))
		room_snapshots.append({
			"id": String(room_id),
			"role": String(room.role),
			"critical": bool(room.critical),
			"depth": int(room.depth),
			"neighbors": neighbor_strings,
		})
	var route_strings: Array[String] = []
	for room_id: StringName in critical_route:
		route_strings.append(String(room_id))
	return {
		"seed": seed,
		"theme_id": String(theme_id),
		"objective_id": String(objective_id),
		"start_room_id": String(start_room_id),
		"objective_room_id": String(objective_room_id),
		"extraction_room_id": String(extraction_room_id),
		"critical_route": route_strings,
		"rooms": room_snapshots,
	}


static func from_snapshot(snapshot: Dictionary) -> ExpeditionPlan:
	var plan := ExpeditionPlan.new()
	plan.seed = int(snapshot.get("seed", 1))
	plan.theme_id = StringName(snapshot.get("theme_id", "service_ruins"))
	plan.objective_id = StringName(snapshot.get("objective_id", "restore_relay"))
	plan.start_room_id = StringName(snapshot.get("start_room_id", ""))
	plan.objective_room_id = StringName(snapshot.get("objective_room_id", ""))
	plan.extraction_room_id = StringName(snapshot.get("extraction_room_id", ""))
	for room_data: Dictionary in snapshot.get("rooms", []):
		plan.add_room(
			StringName(room_data.get("id", "")), StringName(room_data.get("role", "")),
			bool(room_data.get("critical", false)), int(room_data.get("depth", 0)),
		)
	for room_data: Dictionary in snapshot.get("rooms", []):
		var room_id := StringName(room_data.get("id", ""))
		for neighbor_id in room_data.get("neighbors", []):
			plan.connect_rooms(room_id, StringName(neighbor_id))
	for room_id in snapshot.get("critical_route", []):
		plan.critical_route.append(StringName(room_id))
	return plan
