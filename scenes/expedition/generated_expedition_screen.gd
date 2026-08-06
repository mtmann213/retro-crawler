class_name GeneratedExpeditionScreen
extends Control

signal return_to_base_requested

@onready var title_label: Label = %TitleLabel
@onready var room_label: Label = %RoomLabel
@onready var description_label: Label = %DescriptionLabel
@onready var progress_label: Label = %ProgressLabel
@onready var world: WalkableWorld = %GeneratedWorld
@onready var return_button: Button = %ReturnButton

var plan: ExpeditionPlan
var generated_layout: WorldLayoutDefinition
var current_room_id: StringName = &""
var visited_room_ids: Dictionary[StringName, bool] = {}
var objective_reached := false


func _ready() -> void:
	return_button.pressed.connect(_return_to_base)
	world.room_entered.connect(_enter_room)
	visible = false


func present(expedition_plan: ExpeditionPlan, crawler_accent: Color) -> void:
	assert(expedition_plan != null and expedition_plan.validate().is_empty())
	plan = expedition_plan
	generated_layout = ExpeditionWorldBuilder.build(plan)
	current_room_id = plan.start_room_id
	visited_room_ids = {current_room_id: true}
	objective_reached = false
	world.configure_layout(generated_layout, current_room_id)
	world.set_character_appearance(crawler_accent)
	world.movement_enabled = true
	move_to_front()
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_refresh()
	world.call_deferred("grab_focus")


func _enter_room(room_id: StringName) -> void:
	current_room_id = room_id
	visited_room_ids[room_id] = true
	if room_id == plan.objective_room_id:
		objective_reached = true
	_refresh()


func _refresh() -> void:
	var room_data: Dictionary = plan.rooms[current_room_id]
	var role := StringName(room_data.role)
	title_label.text = "EXPEDITION // %s  //  SEED %d" % [
		String(plan.theme_id).replace("_", " ").to_upper(), plan.seed,
	]
	room_label.text = "%s // %s" % [
		generated_layout.get_room(current_room_id).display_name,
		String(current_room_id).replace("sector_", "SECTOR ").to_upper(),
	]
	description_label.text = _room_description(role)
	progress_label.text = "%d/%d SURVEYED  //  %s" % [
		visited_room_ids.size(), plan.rooms.size(),
		"OBJECTIVE REACHED" if objective_reached else "OBJECTIVE // %s" % String(plan.objective_id).replace("_", " ").to_upper(),
	]
	world.present(
		current_room_id, visited_room_ids, "", false, false, &"", {"theme_id": String(plan.theme_id)},
	)


func _return_to_base() -> void:
	world.movement_enabled = false
	world.release_focus()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	return_to_base_requested.emit()


func _room_description(role: StringName) -> String:
	match role:
		&"entrance": return "Landing zone secured. Choose a connected passage and begin the survey."
		&"objective": return "The contract objective is here. This first deployment slice records your arrival."
		&"encounter": return "Contact signatures detected. Combat integration follows this traversal pass."
		&"resource": return "A salvage cache flickers on the local scan."
		&"discovery": return "An unknown signal resolves as Mox follows you into the sector."
		&"hazard": return "Environmental instability disrupts the route ahead."
		_: return "A generated passage links the expedition network."
