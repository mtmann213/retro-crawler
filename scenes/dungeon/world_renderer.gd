class_name WorldRenderer
extends Node2D

const INTERACTION_RADIUS := 24.0
const ENCOUNTER_RADIUS := 24.0
const SCRAP_HOUND_TEXTURE := preload("res://assets/enemies/scrap_hound_topdown.png")
const SENTRY_DRONE_TEXTURE := preload("res://assets/enemies/sentry_drone_topdown.png")

var layout: WorldLayoutDefinition
var current_room_id: StringName
var visited_room_ids: Dictionary[StringName, bool] = {}
var interaction_text := ""
var interaction_available := false
var interaction_in_range := false
var encounter_available := false
var encounter_id: StringName = &""
var run_variation: Dictionary = {}
var hostile_sprites: Array[Sprite2D] = []
var _animation_time := 0.0


func _ready() -> void:
	for texture: Texture2D in [SCRAP_HOUND_TEXTURE, SENTRY_DRONE_TEXTURE]:
		var hostile := Sprite2D.new()
		hostile.texture = texture
		hostile.scale = Vector2(0.115, 0.115)
		hostile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hostile.z_index = 4
		hostile.visible = false
		hostile_sprites.append(hostile)
		add_child(hostile)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_animation_time += delta
	_update_hostile_animation()
	queue_redraw()


func present(
	definition: WorldLayoutDefinition,
	room_id: StringName,
	visited: Dictionary[StringName, bool],
	prompt: String,
	can_interact: bool,
	in_range: bool,
	has_encounter: bool,
	presented_encounter_id: StringName = &"",
	presented_run_variation: Dictionary = {},
) -> void:
	layout = definition
	current_room_id = room_id
	visited_room_ids = visited.duplicate()
	interaction_text = prompt
	interaction_available = can_interact
	interaction_in_range = in_range
	encounter_available = has_encounter
	encounter_id = presented_encounter_id
	run_variation = presented_run_variation.duplicate(true)
	_sync_hostile_visibility()
	queue_redraw()


func _draw() -> void:
	if layout == null:
		return
	var canvas_size := Vector2(620, 150)
	var parent_control := get_parent() as Control
	if parent_control != null:
		canvas_size = parent_control.size
	draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(0.012, 0.02, 0.031, 0.94), true)
	for corridor: Rect2 in layout.corridors:
		_draw_tiled_surface(corridor, Color("142a39"), Color("183242"))
		_draw_route_markings(corridor)
	for room: WorldRoomDefinition in layout.rooms:
		var visited: bool = visited_room_ids.get(room.content_id, false) or room.content_id == current_room_id
		_draw_room(room, visited)
	var current := layout.get_room(current_room_id)
	if current != null:
		_draw_room_ambience(current)
	if current != null and encounter_available and current.has_encounter_point():
		_draw_encounter(current)
		_draw_locked_exits(current)
	if current != null and interaction_available and current.has_interaction_point():
		_draw_interaction(current, canvas_size)
	draw_rect(Rect2(Vector2.ZERO, canvas_size), Color("31536b"), false, 1.0)


func _draw_room(room: WorldRoomDefinition, visited: bool) -> void:
	var accent := _theme_accent()
	var base := Color("102536").lerp(accent, 0.10) if visited else Color("09131c")
	var alternate := Color("132c3e").lerp(accent, 0.08) if visited else Color("0b1822")
	_draw_tiled_surface(room.bounds, base, alternate)
	draw_rect(room.bounds, Color("7dd3fc") if room.content_id == current_room_id else Color("35566d"), false, 2.0 if room.content_id == current_room_id else 1.0)
	draw_string(ThemeDB.fallback_font, room.bounds.position + Vector2(6, 13), room.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("a9c5d8") if visited else Color("536674"))
	if visited:
		_draw_room_details(room)


func _draw_tiled_surface(rect: Rect2, base: Color, alternate: Color) -> void:
	var tile := layout.tile_size
	for y: int in range(int(rect.position.y), int(rect.end.y), tile.y):
		for x: int in range(int(rect.position.x), int(rect.end.x), tile.x):
			var tile_rect := Rect2(Vector2(x, y), Vector2(tile)).intersection(rect)
			var checker := ((x / tile.x) + (y / tile.y)) as int
			draw_rect(tile_rect, base if checker % 2 == 0 else alternate, true)
			draw_line(tile_rect.position, tile_rect.position + Vector2(tile_rect.size.x, 0), Color("29485a", 0.22), 1.0)


func _draw_interaction(room: WorldRoomDefinition, canvas_size: Vector2) -> void:
	var color := Color("86efac") if interaction_in_range else Color("fcd34d")
	draw_arc(room.interaction_point, INTERACTION_RADIUS, 0, TAU, 32, Color(color, 0.24), 1.0)
	draw_circle(room.interaction_point, 5.0, color)
	draw_string(ThemeDB.fallback_font, room.interaction_point + Vector2(8, 3), "E / A" if interaction_in_range else "POI", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	var prompt := ("E / A // " if interaction_in_range else "MOVE CLOSER // ") + interaction_text
	draw_string(ThemeDB.fallback_font, Vector2(8, canvas_size.y - 5), prompt, HORIZONTAL_ALIGNMENT_CENTER, canvas_size.x - 16, 7, color)


func _draw_encounter(room: WorldRoomDefinition) -> void:
	var pulse := 0.5 + sin(_animation_time * 4.0) * 0.5
	draw_circle(room.encounter_point, ENCOUNTER_RADIUS + pulse * 2.0, Color("7f1d2d", 0.08 + pulse * 0.05), true)
	draw_arc(room.encounter_point, ENCOUNTER_RADIUS + pulse * 2.0, 0, TAU, 32, Color("fb7185", 0.42), 1.0)
	draw_arc(room.encounter_point, ENCOUNTER_RADIUS - 5.0, -PI * 0.15, PI * 1.15, 20, Color("fecdd3", 0.34), 1.0)
	var width := (get_parent() as Control).size.x
	draw_string(ThemeDB.fallback_font, Vector2(8, (get_parent() as Control).size.y - 5), "HOSTILES // APPROACH TO ENGAGE // PROGRESSION ROUTES LOCKED", HORIZONTAL_ALIGNMENT_CENTER, width - 16, 7, Color("fb7185"))


func _sync_hostile_visibility() -> void:
	var room := layout.get_room(current_room_id) if layout != null else null
	var should_show := encounter_available and room != null and room.has_encounter_point()
	var hostile_count := 1 if encounter_id == PrototypeEncounter.BRUTE_ENCOUNTER_ID else 2
	for index: int in hostile_sprites.size():
		hostile_sprites[index].visible = (
			should_show and index < mini(room.encounter_count, hostile_count)
			if room != null
			else false
		)
	_update_hostile_animation()


func _update_hostile_animation() -> void:
	if layout == null:
		return
	var room := layout.get_room(current_room_id)
	if room == null or not room.has_encounter_point():
		return
	for index: int in hostile_sprites.size():
		var hostile := hostile_sprites[index]
		if not hostile.visible:
			continue
		var phase := _animation_time * (4.5 if index == 0 else 3.2) + index * 1.7
		var is_brute := encounter_id == PrototypeEncounter.BRUTE_ENCOUNTER_ID
		var offset := Vector2(0, sin(phase) * 0.7) if is_brute else Vector2((index - 0.5) * 28.0, sin(phase) * (0.8 if index == 0 else 1.8))
		hostile.position = room.encounter_point + offset
		hostile.rotation = sin(phase * 0.7) * (0.025 if index == 0 else 0.055)
		var pulse := 1.0 + sin(phase) * (0.018 if index == 0 else 0.035)
		hostile.scale = Vector2(0.15, 0.15) * pulse if is_brute else Vector2(0.115, 0.115) * pulse
		hostile.modulate = Color("fecaca") if is_brute else Color.WHITE


func _draw_room_ambience(room: WorldRoomDefinition) -> void:
	var room_variant: Dictionary = (run_variation.get("rooms", {}) as Dictionary).get(String(room.content_id), {})
	var breath := 0.5 + sin(_animation_time * 1.7 + float(room_variant.get("light_phase", 0.0))) * 0.5
	var inset := room.bounds.grow(-4.0)
	var accent := _theme_accent()
	draw_rect(inset, Color(accent, 0.012 + breath * 0.014), true)
	for light_x: float in [inset.position.x + 12.0, inset.end.x - 12.0]:
		draw_circle(Vector2(light_x, inset.position.y + 7.0), 2.0 + breath, Color(accent, 0.28 + breath * 0.18), true)
	var hazard_pattern := int(room_variant.get("hazard_pattern", 0))
	for index: int in hazard_pattern + 1:
		var marker := inset.position + Vector2(18 + index * 29, inset.size.y - 7)
		draw_line(marker, marker + Vector2(7, -4), Color(accent, 0.32), 1.0)


func _theme_accent() -> Color:
	match StringName(run_variation.get("theme_id", "cold")):
		&"emergency":
			return Color("fb923c")
		&"arc":
			return Color("c084fc")
		_:
			return Color("7dd3fc")


func _draw_locked_exits(room: WorldRoomDefinition) -> void:
	for barrier: Rect2 in room.locked_exit_rects:
		draw_rect(barrier, Color("fb7185", 0.38), true)
		if barrier.size.x > barrier.size.y:
			for x: int in range(int(barrier.position.x) + 2, int(barrier.end.x), 4):
				draw_line(Vector2(x, barrier.position.y), Vector2(x, barrier.end.y), Color("fecdd3"), 1.0)
		else:
			for y: int in range(int(barrier.position.y) + 2, int(barrier.end.y), 4):
				draw_line(Vector2(barrier.position.x, y), Vector2(barrier.end.x, y), Color("fecdd3"), 1.0)


func _draw_route_markings(corridor: Rect2) -> void:
	var center := corridor.get_center()
	if corridor.size.x > corridor.size.y:
		draw_line(center - Vector2(5, 0), center + Vector2(5, 0), Color("7dd3fc", 0.55), 1.0)
		draw_line(center + Vector2(5, 0), center + Vector2(2, -2), Color("7dd3fc", 0.55), 1.0)
	else:
		draw_line(center - Vector2(0, 5), center + Vector2(0, 5), Color("7dd3fc", 0.55), 1.0)
		draw_line(center + Vector2(0, 5), center + Vector2(-2, 2), Color("7dd3fc", 0.55), 1.0)


func _draw_room_details(room: WorldRoomDefinition) -> void:
	var rect := room.bounds
	var detail := Color("52758a", 0.75)
	match room.visual_style:
		&"shelter":
			draw_rect(Rect2(rect.position + Vector2(7, 24), Vector2(18, 14)), detail, false, 1.0)
			draw_rect(Rect2(rect.position + Vector2(72, 25), Vector2(23, 11)), Color("29475a"), true)
			draw_circle(room.interaction_point, 8.0, Color("163649"), true)
		&"damaged":
			draw_line(rect.position + Vector2(16, 30), rect.position + Vector2(94, 30), Color("fb7185", 0.55), 2.0)
			draw_line(rect.position + Vector2(48, 21), rect.position + Vector2(64, 40), Color("fcd34d", 0.7), 1.0)
		&"storage":
			draw_rect(Rect2(room.interaction_point - Vector2(10, 9), Vector2(17, 18)), Color("27485b"), true)
			draw_line(room.interaction_point - Vector2(8, 2), room.interaction_point + Vector2(5, -2), detail, 1.0)
		&"processing":
			for offset: float in [25.0, 45.0, 65.0, 85.0]:
				draw_rect(Rect2(rect.position + Vector2(offset, 25), Vector2(12, 14)), Color("213e50"), true)
			draw_line(rect.position + Vector2(16, 42), rect.position + Vector2(104, 42), detail, 2.0)
		&"warden":
			draw_circle(rect.get_center(), 17.0, Color("4b1f2b", 0.7), true)
			draw_arc(rect.get_center(), 21.0, 0, TAU, 24, Color("fb7185", 0.65), 2.0)
			draw_rect(Rect2(room.interaction_point - Vector2(8, 7), Vector2(16, 14)), Color("27485b"), true)
