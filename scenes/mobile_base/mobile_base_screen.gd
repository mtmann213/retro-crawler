class_name MobileBaseScreen
extends Control

signal return_to_title_requested
signal deploy_requested(plan: ExpeditionPlan)

@onready var contract_label: Label = %ContractLabel
@onready var route_label: Label = %RouteLabel
@onready var map_preview: ExpeditionMapPreview = %ExpeditionMapPreview
@onready var deploy_button: Button = %DeployButton
@onready var survey_button: Button = %SurveyButton
@onready var return_button: Button = %ReturnButton

var completed_seed: int = 1
var survey_index: int = 0
var next_plan: ExpeditionPlan


func _ready() -> void:
	deploy_button.pressed.connect(_deploy)
	survey_button.pressed.connect(_survey_another)
	return_button.pressed.connect(return_to_title_requested.emit)
	visible = false


func present(run_seed: int) -> void:
	completed_seed = maxi(run_seed, 1)
	survey_index = 0
	_generate_contract()
	_activate()


func resume() -> void:
	_activate()


func deactivate() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _deploy() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	deploy_requested.emit(next_plan)


func _survey_another() -> void:
	survey_index += 1
	_generate_contract()


func _generate_contract() -> void:
	var next_seed := completed_seed + 104729 * (survey_index + 1)
	next_plan = ExpeditionGenerator.generate(next_seed)
	contract_label.text = "NEXT CONTRACT // %s\nOBJECTIVE // %s  //  SEED %d" % [
		String(next_plan.theme_id).replace("_", " ").to_upper(),
		String(next_plan.objective_id).replace("_", " ").to_upper(),
		next_plan.seed,
	]
	route_label.text = "%d SECTORS  //  %d CRITICAL  //  %d OPTIONAL  //  %d CONTACT ZONES" % [
		next_plan.rooms.size(), next_plan.critical_route.size(),
		next_plan.optional_room_count(), next_plan.encounter_room_count(),
	]
	map_preview.present(next_plan)


func _activate() -> void:
	visible = true
	move_to_front()
	mouse_filter = Control.MOUSE_FILTER_STOP
	deploy_button.call_deferred("grab_focus")
