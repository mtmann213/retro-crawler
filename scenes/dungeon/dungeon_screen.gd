class_name DungeonScreen
extends Control

signal session_snapshot_changed(snapshot: SessionSnapshot)

const FLOOR: FloorDefinition = preload("res://content/floors/floor_service_level.tres")
const COMBAT_SCREEN := preload("res://scenes/combat/combat_screen.tscn")

@onready var exploration_view: Control = %ExplorationView
@onready var combat_host: Control = %CombatHost
@onready var floor_clock: FloorClock = %FloorClock
@onready var room_title: Label = %RoomTitle
@onready var room_description: Label = %RoomDescription
@onready var map_area: WalkableWorld = %MapArea
@onready var interaction_button: DungeonInteractable = %InteractionButton
@onready var inventory_button: Button = %InventoryButton
@onready var emergency_button: Button = %EmergencyButton
@onready var event_log: RichTextLabel = %EventLog
@onready var inventory_screen: InventoryScreen = %InventoryScreen
@onready var end_panel: PanelContainer = %EndPanel
@onready var end_label: Label = %EndLabel
@onready var extract_button: Button = %ExtractButton
@onready var announcement_panel: AnnouncementPanel = %AnnouncementPanel
@onready var transition_overlay: ColorRect = %TransitionOverlay

var floor_state := FloorState.new(FLOOR)
var reward_session := RewardSession.new()
var player_run_state: Dictionary = {}
var active_combat: CombatScreen
var dialogue_state := DialogueState.new()
var dialogue_events: Array[DialogueEventDefinition] = []
var narrative_flags: Dictionary[StringName, bool] = {}


func _ready() -> void:
	assert(RoomTransitionRules.validate_graph(FLOOR).is_empty())
	assert(ContentRegistry.validate_all().is_empty())
	dialogue_events = ContentRegistry.get_dialogue_events()
	interaction_button.interaction_requested.connect(_interact)
	inventory_button.pressed.connect(_open_inventory)
	inventory_screen.item_used.connect(_spend_inventory_time)
	inventory_screen.continue_requested.connect(_return_from_inventory)
	extract_button.pressed.connect(_extract)
	emergency_button.pressed.connect(_extract)
	announcement_panel.event_acknowledged.connect(_acknowledge_dialogue)
	map_area.room_entered.connect(_move_to_room)
	map_area.interaction_requested.connect(_world_interact)
	map_area.inventory_requested.connect(_open_inventory)
	map_area.interaction_proximity_changed.connect(_sync_interaction_proximity)
	map_area.encounter_requested.connect(_world_encounter)
	_append_log("SYSTEM // Service Level loaded. Clock begins when you leave Intake Shelter.")
	_render_room()


func _render_room() -> void:
	var room := FLOOR.get_room(floor_state.current_room_id)
	var room_state := floor_state.get_room_state(room.content_id)
	room_title.text = room.display_name.to_upper()
	room_description.text = room.description
	var visited: Dictionary[StringName, bool] = {}
	for room_id: StringName in floor_state.rooms:
		visited[room_id] = floor_state.get_room_state(room_id).visited
	floor_clock.present(floor_state)
	interaction_button.setup(room, room_state.interaction_completed)
	var encounter_pending := (
		not room.encounter_id.is_empty()
		and not room_state.encounter_completed
		and room.content_id != &"room_warden_chamber"
	)
	map_area.present(
		room.content_id,
		visited,
		room.interaction_label,
		not room_state.interaction_completed,
		encounter_pending,
	)
	_sync_interaction_proximity(map_area.can_interact_here(), room.interaction_label)
	emergency_button.visible = (
		room.content_id == &"room_warden_chamber"
		and not floor_state.boss_defeated
		and not floor_state.extracted
	)
	end_panel.visible = floor_state.floor_failed or floor_state.extracted or floor_state.victory_ending
	if floor_state.victory_ending:
		end_label.text = "RUN COMPLETE // WARDEN DEFEATED\nThe Service Level is safely shut down."
		extract_button.visible = false
	elif floor_state.extracted:
		end_label.text = "RUN ENDED // EMERGENCY EXTRACTION COMPLETE\nRooms reached: %d/5  //  Time remaining: %d sec" % [_visited_count(), floor_state.remaining_seconds]
		extract_button.visible = false
	elif floor_state.floor_failed:
		end_label.text = "FLOOR FAILURE // SHUTDOWN DEADLINE REACHED"
		extract_button.visible = true
	call_deferred("_focus_default_control")
	map_area.movement_enabled = not floor_state.floor_failed and not floor_state.extracted and not floor_state.victory_ending


func _move_to_room(room_id: StringName) -> void:
	_pulse_transition()
	var before := floor_state.current_room_id
	var events := RoomTransitionRules.transition(floor_state, FLOOR, room_id)
	_present_clock_events(events)
	if floor_state.current_room_id == before:
		_render_room()
		return
	get_tree().call_group("audio_director", "play_move")
	_append_log("ENTERED // %s" % FLOOR.get_room(room_id).display_name.to_upper())
	if before == FLOOR.starting_room_id:
		_trigger_narrative(&"floor_started")
	_trigger_narrative(room_id)
	_render_room()
	var room := FLOOR.get_room(room_id)
	if not room.encounter_id.is_empty() and room_id != &"room_warden_chamber":
		_append_log("HOSTILES DETECTED // approach contact to engage // routes locked")
	_request_save()


func _interact(interaction_id: StringName) -> void:
	var room_state := floor_state.get_room_state(floor_state.current_room_id)
	if room_state.interaction_completed or not map_area.can_interact_here():
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
				narrative_flags[&"took_detour"] = true
				_trigger_narrative(&"cache_found")
		&"engage_warden":
			_start_combat(PrototypeEncounter.WARDEN_ENCOUNTER_ID)
	_render_room()
	_request_save()


func _world_interact() -> void:
	var room := FLOOR.get_room(floor_state.current_room_id)
	if not room.interaction_id.is_empty() and map_area.can_interact_here():
		_interact(room.interaction_id)


func _world_encounter(room_id: StringName) -> void:
	if room_id != floor_state.current_room_id or active_combat != null:
		return
	var room := FLOOR.get_room(room_id)
	var room_state := floor_state.get_room_state(room_id)
	if room == null or room.encounter_id.is_empty() or room_state.encounter_completed:
		return
	_start_combat(room.encounter_id)
	_request_save()


func _sync_interaction_proximity(in_range: bool, _prompt: String) -> void:
	var room := FLOOR.get_room(floor_state.current_room_id)
	var completed := floor_state.get_room_state(room.content_id).interaction_completed
	interaction_button.disabled = room.interaction_id.is_empty() or completed or not in_range
	interaction_button.tooltip_text = "" if in_range else "Walk to the highlighted point of interest to interact."


func _open_inventory() -> void:
	var player := PrototypeEncounter.create_simulation().get_combatant(1)
	EquipmentRules.apply_equipped_items(reward_session.inventory, player, reward_session.item_catalog)
	CombatScreen.apply_player_run_snapshot(player, player_run_state)
	inventory_screen.present(reward_session, player, [], "RETURN TO DUNGEON")
	_append_log("INVENTORY OPENED // 0 sec")


func _return_from_inventory() -> void:
	if inventory_screen.player != null:
		player_run_state = CombatScreen.create_player_run_snapshot(inventory_screen.player)
	call_deferred("_focus_default_control")
	_request_save()


func _spend_inventory_time(seconds: int, description: String) -> void:
	player_run_state = CombatScreen.create_player_run_snapshot(inventory_screen.player)
	_present_clock_events(FloorClockRules.spend_time(
		floor_state, seconds, description, FLOOR.threshold_seconds,
	))
	if floor_state.floor_failed:
		inventory_screen.visible = false
	_render_room()


func _start_combat(encounter_id: StringName) -> void:
	get_tree().call_group("audio_director", "set_music_mode", AudioDirector.MusicMode.COMBAT)
	exploration_view.visible = false
	active_combat = COMBAT_SCREEN.instantiate() as CombatScreen
	active_combat.reward_session = reward_session
	active_combat.encounter_id = encounter_id
	active_combat.continue_starts_encounter = false
	active_combat.carried_player_state = player_run_state.duplicate(true)
	active_combat.dungeon_thresholds = floor_state.triggered_thresholds.duplicate()
	active_combat.dungeon_time_spent.connect(_spend_combat_time)
	active_combat.dungeon_return_requested.connect(_return_from_combat)
	active_combat.boss_phase_changed.connect(_trigger_narrative)
	combat_host.add_child(active_combat)
	active_combat.set_dungeon_clock_remaining(floor_state.remaining_seconds)
	transition_overlay.color.a = 0.0
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
	get_tree().call_group("audio_director", "set_music_mode", AudioDirector.MusicMode.EXPLORATION)
	_append_log("ENCOUNTER ABORTED // shutdown deadline overrides combat")
	_render_room()


func _return_from_combat() -> void:
	var defeated_warden := active_combat.encounter_id == PrototypeEncounter.WARDEN_ENCOUNTER_ID
	floor_state.get_room_state(floor_state.current_room_id).encounter_completed = true
	player_run_state = active_combat.get_player_run_snapshot()
	active_combat.queue_free()
	active_combat = null
	exploration_view.visible = true
	get_tree().call_group("audio_director", "set_music_mode", AudioDirector.MusicMode.EXPLORATION)
	_append_log("ENCOUNTER CLEARED // returned to %s" % FLOOR.get_room(floor_state.current_room_id).display_name)
	if defeated_warden:
		floor_state.boss_defeated = true
		floor_state.victory_ending = true
		narrative_flags[&"boss_defeated"] = true
		_trigger_narrative(&"victory_ending")
	_render_room()
	_request_save()


func _present_clock_events(events: Array[FloorClockEvent]) -> void:
	for event: FloorClockEvent in events:
		match event.event_type:
			FloorClockEvent.EventType.TIME_SPENT:
				_append_log("%s // -%d sec // %d remaining" % [event.description, event.seconds, event.remaining_seconds])
			FloorClockEvent.EventType.THRESHOLD_REACHED:
				_append_log("CLOCK WARNING // %d-second threshold" % event.threshold_seconds)
				if active_combat != null and event.threshold_seconds > 0:
					active_combat.activate_dungeon_threshold(event.threshold_seconds)
			FloorClockEvent.EventType.DEADLINE_REACHED:
				_append_log("FLOOR FAILURE // emergency extraction required")
	if is_node_ready():
		floor_clock.present(floor_state)


func _extract() -> void:
	_present_clock_events(FloorClockRules.emergency_extract(floor_state))
	floor_state.extraction_ending = true
	narrative_flags[&"extracted"] = true
	_trigger_narrative(&"extraction_ending")
	_append_log("EXTRACTION // run state secured")
	_render_room()
	_request_save()


func _append_log(message: String) -> void:
	event_log.append_text(message + "\n")
	event_log.scroll_to_line(event_log.get_line_count())


func _pulse_transition() -> void:
	transition_overlay.color = Color(0.02, 0.027, 0.039, 0.58)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.2)


func _visited_count() -> int:
	var count := 0
	for room_state: RoomState in floor_state.rooms.values():
		if room_state.visited:
			count += 1
	return count


func _trigger_narrative(trigger_id: StringName) -> void:
	var events := DialogueResolver.resolve(
		dialogue_events, trigger_id, narrative_flags, dialogue_state,
	)
	if not events.is_empty():
		announcement_panel.present_events(events)


func create_session_snapshot() -> SessionSnapshot:
	var snapshot := SessionSnapshot.new()
	snapshot.floor_snapshot = floor_state.to_snapshot()
	snapshot.reward_snapshot = reward_session.to_snapshot()
	snapshot.player_run_state = player_run_state.duplicate(true)
	snapshot.dialogue_snapshot = dialogue_state.to_snapshot()
	snapshot.world_position = map_area.player_position
	for flag_id: StringName in narrative_flags:
		snapshot.narrative_flags[String(flag_id)] = narrative_flags[flag_id]
	if active_combat != null:
		snapshot.pending_encounter_id = active_combat.encounter_id
	return snapshot


func restore_session(snapshot: SessionSnapshot) -> void:
	if snapshot == null:
		return
	floor_state = FloorState.from_snapshot(FLOOR, snapshot.floor_snapshot)
	reward_session = RewardSession.from_snapshot(snapshot.reward_snapshot)
	player_run_state = snapshot.player_run_state.duplicate(true)
	dialogue_state = DialogueState.from_snapshot(snapshot.dialogue_snapshot)
	narrative_flags.clear()
	for flag_id: String in snapshot.narrative_flags:
		narrative_flags[StringName(flag_id)] = bool(snapshot.narrative_flags[flag_id])
	_render_room()
	map_area.restore_position(snapshot.world_position, floor_state.current_room_id)
	_append_log("SYSTEM // saved session restored")
	var pending: Array[DialogueEventDefinition] = []
	for event: DialogueEventDefinition in dialogue_events:
		if dialogue_state.pending_events.get(event.content_id, false):
			pending.append(event)
	if not pending.is_empty():
		announcement_panel.present_events(pending)
	if not snapshot.pending_encounter_id.is_empty():
		call_deferred("_start_combat", snapshot.pending_encounter_id)


func _request_save() -> void:
	session_snapshot_changed.emit(create_session_snapshot())


func _acknowledge_dialogue(event_id: StringName) -> void:
	dialogue_state.pending_events.erase(event_id)
	dialogue_state.shown_events[event_id] = true
	_request_save()
	call_deferred("_focus_default_control")


func _focus_default_control() -> void:
	if not exploration_view.visible or announcement_panel.visible or inventory_screen.visible:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if (
		focus_owner != null
		and is_instance_valid(focus_owner)
		and not focus_owner.is_queued_for_deletion()
		and focus_owner.is_visible_in_tree()
	):
		return
	if floor_state.floor_failed and extract_button.visible:
		extract_button.grab_focus()
	else:
		map_area.grab_focus()
