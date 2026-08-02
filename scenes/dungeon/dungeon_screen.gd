class_name DungeonScreen
extends Control

const FLOOR: FloorDefinition = preload("res://content/floors/floor_service_level.tres")
const COMBAT_SCREEN := preload("res://scenes/combat/combat_screen.tscn")

@onready var exploration_view: Control = %ExplorationView
@onready var combat_host: Control = %CombatHost
@onready var floor_clock: FloorClock = %FloorClock
@onready var room_title: Label = %RoomTitle
@onready var room_description: Label = %RoomDescription
@onready var map_area: Control = %MapArea
@onready var exit_list: HBoxContainer = %ExitList
@onready var interaction_button: DungeonInteractable = %InteractionButton
@onready var inventory_button: Button = %InventoryButton
@onready var event_log: RichTextLabel = %EventLog
@onready var inventory_screen: InventoryScreen = %InventoryScreen
@onready var end_panel: PanelContainer = %EndPanel
@onready var end_label: Label = %EndLabel
@onready var extract_button: Button = %ExtractButton

var floor_state := FloorState.new(FLOOR)
var reward_session := RewardSession.new()
var active_combat: CombatScreen


func _ready() -> void:
	assert(RoomTransitionRules.validate_graph(FLOOR).is_empty())
	interaction_button.interaction_requested.connect(_interact)
	inventory_button.pressed.connect(_open_inventory)
	inventory_screen.item_used.connect(_spend_inventory_time)
	extract_button.pressed.connect(_extract)
	_build_map()
	_append_log("SYSTEM // Service Level loaded. Clock begins when you leave Intake Shelter.")
	_render_room()


func _build_map() -> void:
	for room: RoomDefinition in FLOOR.rooms:
		var button := Button.new()
		button.name = String(room.content_id)
		button.position = room.map_position
		button.size = Vector2(112, 38)
		button.text = room.display_name.to_upper()
		button.tooltip_text = room.description
		button.pressed.connect(_move_to_room.bind(room.content_id))
		map_area.add_child(button)


func _render_room() -> void:
	var room := FLOOR.get_room(floor_state.current_room_id)
	var room_state := floor_state.get_room_state(room.content_id)
	room_title.text = room.display_name.to_upper()
	room_description.text = room.description
	floor_clock.present(floor_state)
	interaction_button.setup(room, room_state.interaction_completed)
	for child: Node in exit_list.get_children():
		child.free()
	for exit_id: StringName in room.connected_room_ids:
		var destination := FLOOR.get_room(exit_id)
		var button := Button.new()
		button.text = "MOVE: %s  //  -%d SEC" % [destination.display_name.to_upper(), FLOOR.room_transition_cost]
		button.disabled = floor_state.floor_failed or floor_state.extracted
		button.pressed.connect(_move_to_room.bind(exit_id))
		exit_list.add_child(button)
	for map_node: Node in map_area.get_children():
		var map_button := map_node as Button
		var map_room_id := StringName(map_button.name)
		var visited := floor_state.get_room_state(map_room_id).visited
		map_button.text = ("> " if map_room_id == floor_state.current_room_id else "") + FLOOR.get_room(map_room_id).display_name.to_upper()
		map_button.disabled = not room.connected_room_ids.has(map_room_id) or floor_state.floor_failed or floor_state.extracted
		map_button.modulate = Color.WHITE if visited or map_room_id == floor_state.current_room_id else Color(0.45, 0.48, 0.52)
	end_panel.visible = floor_state.floor_failed or floor_state.extracted
	if floor_state.extracted:
		end_label.text = "RUN ENDED // EMERGENCY EXTRACTION COMPLETE\nRooms reached: %d/5  //  Time remaining: %d sec" % [_visited_count(), floor_state.remaining_seconds]
		extract_button.visible = false
	elif floor_state.floor_failed:
		end_label.text = "FLOOR FAILURE // SHUTDOWN DEADLINE REACHED"
		extract_button.visible = true


func _move_to_room(room_id: StringName) -> void:
	var before := floor_state.current_room_id
	var events := RoomTransitionRules.transition(floor_state, FLOOR, room_id)
	_present_clock_events(events)
	if floor_state.current_room_id == before:
		_render_room()
		return
	_append_log("ENTERED // %s" % FLOOR.get_room(room_id).display_name.to_upper())
	_render_room()
	var state := floor_state.get_room_state(room_id)
	var room := FLOOR.get_room(room_id)
	if not room.encounter_id.is_empty() and not state.encounter_completed:
		_start_combat(room.encounter_id)


func _interact(interaction_id: StringName) -> void:
	var room_state := floor_state.get_room_state(floor_state.current_room_id)
	if room_state.interaction_completed:
		return
	match interaction_id:
		&"inspect_station":
			room_state.interaction_completed = true
			_append_log("SUPPLY STATION // inventory access confirmed // 0 sec")
		&"search_cache":
			var room := FLOOR.get_room(floor_state.current_room_id)
			_present_clock_events(FloorClockRules.spend_time(
				floor_state, room.interaction_time_cost, "SEARCH // Corroded Cache", FLOOR.threshold_seconds,
			))
			if not floor_state.floor_failed:
				room_state.interaction_completed = true
				var patch := reward_session.get_item(&"item_field_patch")
				var added := InventoryRules.add_item(reward_session.inventory, patch, 2)
				_append_log("CACHE RECOVERED // Field Patch x%d" % added)
		&"emergency_extract":
			_extract()
	_render_room()


func _open_inventory() -> void:
	var player := PrototypeEncounter.create_simulation().get_combatant(1)
	EquipmentRules.apply_equipped_items(reward_session.inventory, player, reward_session.item_catalog)
	inventory_screen.present(reward_session, player, [], "RETURN TO DUNGEON")
	_append_log("INVENTORY OPENED // 0 sec")


func _spend_inventory_time(seconds: int, description: String) -> void:
	_present_clock_events(FloorClockRules.spend_time(
		floor_state, seconds, description, FLOOR.threshold_seconds,
	))
	if floor_state.floor_failed:
		inventory_screen.visible = false
	_render_room()


func _start_combat(encounter_id: StringName) -> void:
	exploration_view.visible = false
	active_combat = COMBAT_SCREEN.instantiate() as CombatScreen
	active_combat.reward_session = reward_session
	active_combat.encounter_id = encounter_id
	active_combat.continue_starts_encounter = false
	active_combat.dungeon_time_spent.connect(_spend_combat_time)
	active_combat.dungeon_return_requested.connect(_return_from_combat)
	combat_host.add_child(active_combat)
	active_combat.set_dungeon_clock_remaining(floor_state.remaining_seconds)
	_append_log("ENCOUNTER STARTED // returning to %s after rewards" % FLOOR.get_room(floor_state.current_room_id).display_name)


func _spend_combat_time(seconds: int, description: String) -> void:
	_present_clock_events(FloorClockRules.spend_time(
		floor_state, seconds, description, FLOOR.threshold_seconds,
	))
	if active_combat != null:
		active_combat.set_dungeon_clock_remaining(floor_state.remaining_seconds)
	if floor_state.floor_failed:
		call_deferred("_abort_combat_for_deadline")


func _abort_combat_for_deadline() -> void:
	if active_combat == null:
		return
	active_combat.queue_free()
	active_combat = null
	exploration_view.visible = true
	_append_log("ENCOUNTER ABORTED // shutdown deadline overrides combat")
	_render_room()


func _return_from_combat() -> void:
	floor_state.get_room_state(floor_state.current_room_id).encounter_completed = true
	active_combat.queue_free()
	active_combat = null
	exploration_view.visible = true
	_append_log("ENCOUNTER CLEARED // returned to %s" % FLOOR.get_room(floor_state.current_room_id).display_name)
	_render_room()


func _present_clock_events(events: Array[FloorClockEvent]) -> void:
	for event: FloorClockEvent in events:
		match event.event_type:
			FloorClockEvent.EventType.TIME_SPENT:
				_append_log("%s // -%d sec // %d remaining" % [event.description, event.seconds, event.remaining_seconds])
			FloorClockEvent.EventType.THRESHOLD_REACHED:
				_append_log("CLOCK WARNING // %d-second threshold" % event.threshold_seconds)
			FloorClockEvent.EventType.DEADLINE_REACHED:
				_append_log("FLOOR FAILURE // emergency extraction required")
	if is_node_ready():
		floor_clock.present(floor_state)


func _extract() -> void:
	_present_clock_events(FloorClockRules.emergency_extract(floor_state))
	_append_log("EXTRACTION // run state secured")
	_render_room()


func _append_log(message: String) -> void:
	event_log.append_text(message + "\n")
	event_log.scroll_to_line(event_log.get_line_count())


func _visited_count() -> int:
	var count := 0
	for room_state: RoomState in floor_state.rooms.values():
		if room_state.visited:
			count += 1
	return count
