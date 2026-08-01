class_name CombatScreen
extends Control

const PLAYER_ID := 1
const ENEMY_ID := 2

@onready var player_name_label: Label = %PlayerName
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_stamina_label: Label = %PlayerStaminaLabel
@onready var player_stamina_bar: ProgressBar = %PlayerStaminaBar
@onready var player_guard_label: Label = %PlayerGuard
@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_guard_label: Label = %EnemyGuard
@onready var intent_label: Label = %IntentLabel
@onready var timeline_label: Label = %TimelineLabel
@onready var status_label: Label = %StatusLabel
@onready var strike_button: Button = %StrikeButton
@onready var brace_button: Button = %BraceButton
@onready var restart_button: Button = %RestartButton
@onready var combat_log: CombatLog = %CombatLog

var simulation: CombatSimulation


func _ready() -> void:
	strike_button.pressed.connect(_on_strike_pressed)
	brace_button.pressed.connect(_on_brace_pressed)
	restart_button.pressed.connect(_start_encounter)
	_start_encounter()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
		strike_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		brace_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and get_viewport().gui_get_focus_owner() == null:
		strike_button.grab_focus()
		get_viewport().set_input_as_handled()


func _start_encounter() -> void:
	simulation = PrototypeEncounter.create_simulation()
	combat_log.clear_entries()
	combat_log.append_entry("SYSTEM // deterministic encounter seed loaded", Color("7dd3fc"))
	combat_log.append_entry("The Scrap Hound lowers its chassis and prepares to bite.")
	restart_button.visible = false
	_present_events(simulation.prepare_next_turn())
	_refresh_view()
	strike_button.grab_focus()


func _on_strike_pressed() -> void:
	_submit_player_action(&"quick_strike", ENEMY_ID)


func _on_brace_pressed() -> void:
	_submit_player_action(&"brace", PLAYER_ID)


func _submit_player_action(skill_id: StringName, target_id: int) -> void:
	if simulation == null or simulation.combat_finished_flag:
		return

	var active_actor := simulation.get_next_actor()
	if active_actor == null or active_actor.team != CombatantState.Team.PLAYER:
		return

	var command := ActionCommand.new(active_actor.instance_id, skill_id, target_id)
	_present_events(simulation.resolve_action(command))

	while not simulation.combat_finished_flag:
		active_actor = simulation.get_next_actor()
		if active_actor == null or active_actor.team == CombatantState.Team.PLAYER:
			break

		var enemy_command := simulation.create_enemy_command()
		if enemy_command == null:
			break
		_present_events(simulation.resolve_action(enemy_command))

	_present_events(simulation.prepare_next_turn())
	_refresh_view()


func _present_events(events: Array[CombatEvent]) -> void:
	for event: CombatEvent in events:
		match event.event_type:
			CombatEvent.EventType.ACTION_STARTED:
				var actor := simulation.get_combatant(event.actor_id)
				var skill := simulation.get_skill(event.skill_id)
				combat_log.append_entry("%s uses %s." % [actor.display_name, skill.display_name])
			CombatEvent.EventType.DAMAGE_DEALT:
				var target := simulation.get_combatant(event.target_id)
				var critical_text := " CRITICAL!" if event.critical else ""
				combat_log.append_entry(
					"%s takes %d damage.%s" % [target.display_name, event.amount, critical_text],
					Color("fca5a5") if event.target_id == PLAYER_ID else Color("fde68a"),
				)
			CombatEvent.EventType.DEFENSE_APPLIED:
				var actor := simulation.get_combatant(event.actor_id)
				combat_log.append_entry("%s braces for the next attack." % actor.display_name, Color("93c5fd"))
			CombatEvent.EventType.RESOURCE_GAINED:
				if event.actor_id == PLAYER_ID:
					combat_log.append_entry("Stamina +%d" % event.amount, Color("86efac"))
			CombatEvent.EventType.RESOURCE_SPENT:
				if event.actor_id == PLAYER_ID:
					combat_log.append_entry("Stamina -%d" % event.amount, Color("fcd34d"))
			CombatEvent.EventType.COMBATANT_DEFEATED:
				var target := simulation.get_combatant(event.target_id)
				combat_log.append_entry("%s is defeated." % target.display_name, Color("fb7185"))
			CombatEvent.EventType.COMBAT_FINISHED:
				var result := "VICTORY // threat neutralized" if event.winning_team == CombatantState.Team.PLAYER else "DEFEAT // crawler incapacitated"
				combat_log.append_entry(result, Color("86efac") if event.winning_team == CombatantState.Team.PLAYER else Color("fb7185"))
			CombatEvent.EventType.ACTION_REJECTED:
				combat_log.append_entry("ACTION REJECTED // %s" % event.reason, Color("fb7185"))


func _refresh_view() -> void:
	var player := simulation.get_combatant(PLAYER_ID)
	var enemy := simulation.get_combatant(ENEMY_ID)
	player_name_label.text = player.display_name.to_upper()
	player_hp_label.text = "HP  %d / %d" % [player.current_hp, player.max_hp]
	player_hp_bar.max_value = player.max_hp
	player_hp_bar.value = player.current_hp
	player_stamina_label.text = "STAMINA  %d / %d" % [
		player.get_resource(&"stamina"),
		player.get_max_resource(&"stamina"),
	]
	player_stamina_bar.max_value = player.get_max_resource(&"stamina")
	player_stamina_bar.value = player.get_resource(&"stamina")
	player_guard_label.visible = player.is_defending

	enemy_name_label.text = enemy.display_name.to_upper()
	enemy_hp_label.text = "HP  %d / %d" % [enemy.current_hp, enemy.max_hp]
	enemy_hp_bar.max_value = enemy.max_hp
	enemy_hp_bar.value = enemy.current_hp
	enemy_guard_label.visible = enemy.is_defending

	var active_actor := simulation.get_next_actor()
	if simulation.combat_finished_flag:
		status_label.text = "ENCOUNTER COMPLETE"
		intent_label.text = "THREAT STATUS // OFFLINE" if enemy.is_defeated else "CRAWLER STATUS // INCAPACITATED"
	elif active_actor != null and active_actor.team == CombatantState.Team.PLAYER:
		status_label.text = "YOUR TURN // CHOOSE AN ACTION"
		_update_enemy_intent(enemy, player)
	else:
		status_label.text = "ENEMY TURN // RESOLVING"
		_update_enemy_intent(enemy, player)

	timeline_label.text = "TIMELINE  YOU %03d  //  HOUND %03d" % [
		player.next_action_tick,
		enemy.next_action_tick,
	]

	var player_can_act := (
		not simulation.combat_finished_flag
		and active_actor != null
		and active_actor.team == CombatantState.Team.PLAYER
	)
	strike_button.disabled = not player_can_act
	brace_button.disabled = not player_can_act
	restart_button.visible = simulation.combat_finished_flag

	var strike_preview := simulation.get_damage_preview(&"quick_strike", PLAYER_ID, ENEMY_ID)
	strike_button.text = "QUICK STRIKE   %d–%d DMG" % [strike_preview.x, strike_preview.y]
	strike_button.tooltip_text = "+3 stamina  //  70 recovery  //  5% critical"
	brace_button.tooltip_text = "Halve incoming damage  //  80 recovery"

	if simulation.combat_finished_flag:
		restart_button.grab_focus()
	elif player_can_act and get_viewport().gui_get_focus_owner() == null:
		strike_button.grab_focus()


func _update_enemy_intent(enemy: CombatantState, player: CombatantState) -> void:
	if enemy.is_defeated:
		intent_label.text = "INTENT // NONE"
		return

	var preview := simulation.get_damage_preview(&"scrap_bite", enemy.instance_id, player.instance_id)
	intent_label.text = "ENEMY INTENT // BITE  //  %d–%d DAMAGE%s" % [
		preview.x,
		preview.y,
		"  //  GUARDED" if player.is_defending else "",
	]
