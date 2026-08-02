class_name WalkableWorld
extends Control

signal room_entered(room_id: StringName)
signal interaction_requested
signal inventory_requested
signal interaction_proximity_changed(in_range: bool, prompt: String)
signal encounter_requested(room_id: StringName)

const PLAYER_TEXTURE := preload("res://assets/characters/crawler_topdown.png")
const LAYOUT: WorldLayoutDefinition = preload("res://content/worlds/service_level_layout.tres")
const MOVE_SPEED := 82.0
const INTERACTION_RADIUS := 24.0
const ENCOUNTER_RADIUS := 24.0

var player_position := LAYOUT.starting_position
var current_room_id: StringName = &"room_intake_shelter"
var visited_room_ids: Dictionary[StringName, bool] = {}
var interaction_text := ""
var interaction_available := false
var encounter_available := false
var movement_enabled := true
var renderer := WorldRenderer.new()
var player_sprite := Sprite2D.new()
var _interaction_in_range := false
var _encounter_triggered := false


func _ready() -> void:
	assert(LAYOUT.validate().is_empty())
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	renderer.z_index = 0
	add_child(renderer)
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_TEXTURE
	atlas.region = Rect2(340, 180, 580, 770)
	player_sprite.texture = atlas
	player_sprite.scale = Vector2(0.042, 0.042)
	player_sprite.position = player_position
	player_sprite.z_index = 5
	add_child(player_sprite)
	_refresh_renderer()


func _process(delta: float) -> void:
	if not movement_enabled or not is_visible_in_tree() or not has_focus():
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		return
	var motion := direction.normalized() * MOVE_SPEED * delta
	var next := player_position
	var horizontal := next + Vector2(motion.x, 0)
	if _is_walkable(horizontal):
		next = horizontal
	var vertical := next + Vector2(0, motion.y)
	if _is_walkable(vertical):
		next = vertical
	player_position = next
	player_sprite.position = player_position
	_check_room_entry()
	_refresh_interaction_proximity()
	_check_encounter_proximity()
	_refresh_renderer()


func _gui_input(event: InputEvent) -> void:
	if not movement_enabled or not has_focus():
		return
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		if event.is_action_pressed(action):
			accept_event()
			return


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled or not is_visible_in_tree() or not has_focus():
		return
	if (event.is_action_pressed("inspect") or event.is_action_pressed("confirm")) and can_interact_here():
		interaction_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		inventory_requested.emit()
		get_viewport().set_input_as_handled()


func present(
	room_id: StringName,
	visited: Dictionary[StringName, bool],
	interaction_label: String,
	can_interact: bool,
	has_encounter: bool,
) -> void:
	visited_room_ids = visited.duplicate()
	interaction_text = interaction_label
	interaction_available = can_interact
	encounter_available = has_encounter
	_encounter_triggered = false
	if current_room_id != room_id:
		sync_to_room(room_id)
	_refresh_interaction_proximity()
	_refresh_renderer()


func sync_to_room(room_id: StringName, force_warp: bool = true) -> void:
	current_room_id = room_id
	_encounter_triggered = false
	var room := LAYOUT.get_room(room_id)
	if room == null:
		return
	if force_warp or not room.bounds.has_point(player_position):
		player_position = room.bounds.get_center()
		player_sprite.position = player_position
	_refresh_interaction_proximity()
	_refresh_renderer()


func restore_position(position: Vector2, room_id: StringName) -> void:
	current_room_id = room_id
	var room := LAYOUT.get_room(room_id)
	if room == null:
		return
	player_position = position if _is_walkable(position) else room.bounds.get_center()
	player_sprite.position = player_position
	_refresh_interaction_proximity()
	_refresh_renderer()


func can_interact_here() -> bool:
	var room := LAYOUT.get_room(current_room_id)
	if not interaction_available or room == null or not room.has_interaction_point():
		return false
	return player_position.distance_to(room.interaction_point) <= INTERACTION_RADIUS


func interaction_point_for_room(room_id: StringName) -> Vector2:
	var room := LAYOUT.get_room(room_id)
	return room.interaction_point if room != null and room.has_interaction_point() else Vector2.INF


func encounter_point_for_room(room_id: StringName) -> Vector2:
	var room := LAYOUT.get_room(room_id)
	return room.encounter_point if room != null and room.has_encounter_point() else Vector2.INF


func can_trigger_encounter() -> bool:
	var room := LAYOUT.get_room(current_room_id)
	if not encounter_available or room == null or not room.has_encounter_point():
		return false
	return player_position.distance_to(room.encounter_point) <= ENCOUNTER_RADIUS


func is_progression_locked(room_id: StringName) -> bool:
	var room := LAYOUT.get_room(room_id)
	return encounter_available and current_room_id == room_id and room != null and not room.locked_exit_rects.is_empty()


func _refresh_interaction_proximity() -> void:
	var in_range := can_interact_here()
	if in_range == _interaction_in_range:
		return
	_interaction_in_range = in_range
	interaction_proximity_changed.emit(in_range, interaction_text)


func _check_encounter_proximity() -> void:
	if _encounter_triggered or not can_trigger_encounter():
		return
	_encounter_triggered = true
	encounter_requested.emit(current_room_id)


func _check_room_entry() -> void:
	for room: WorldRoomDefinition in LAYOUT.rooms:
		if room.bounds.grow(-4.0).has_point(player_position) and room.content_id != current_room_id:
			current_room_id = room.content_id
			room_entered.emit(room.content_id)
			return


func _is_walkable(position: Vector2) -> bool:
	var inside_floor := false
	for room: WorldRoomDefinition in LAYOUT.rooms:
		if room.bounds.grow(-3.0).has_point(position):
			inside_floor = true
			break
	if not inside_floor:
		for corridor: Rect2 in LAYOUT.corridors:
			if corridor.has_point(position):
				inside_floor = true
				break
	if not inside_floor:
		return false
	var current := LAYOUT.get_room(current_room_id)
	if is_progression_locked(current_room_id):
		for barrier: Rect2 in current.locked_exit_rects:
			if barrier.has_point(position):
				return false
	return true


func _refresh_renderer() -> void:
	if not is_instance_valid(renderer):
		return
	renderer.present(
		LAYOUT,
		current_room_id,
		visited_room_ids,
		interaction_text,
		interaction_available,
		can_interact_here(),
		encounter_available,
	)
