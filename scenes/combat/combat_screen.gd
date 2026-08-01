class_name CombatScreen
extends Control

const PLAYER_ID := 1
const FIRST_ENEMY_ID := 2
const SECOND_ENEMY_ID := 3

@onready var player_name_label: Label = %PlayerName
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_stamina_label: Label = %PlayerStaminaLabel
@onready var player_stamina_bar: ProgressBar = %PlayerStaminaBar
@onready var player_guard_label: Label = %PlayerGuard
@onready var player_statuses: Label = %PlayerStatuses
@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_guard_label: Label = %EnemyGuard
@onready var enemy_statuses: Label = %EnemyStatuses
@onready var enemy_two_name_label: Label = %EnemyTwoName
@onready var enemy_two_hp_label: Label = %EnemyTwoHPLabel
@onready var enemy_two_hp_bar: ProgressBar = %EnemyTwoHPBar
@onready var enemy_two_guard_label: Label = %EnemyTwoGuard
@onready var enemy_two_statuses: Label = %EnemyTwoStatuses
@onready var intent_label: Label = %IntentLabel
@onready var timeline_label: Label = %TimelineLabel
@onready var status_label: Label = %StatusLabel
@onready var target_label: Label = %TargetLabel
@onready var strike_button: Button = %StrikeButton
@onready var heavy_button: Button = %HeavyButton
@onready var brace_button: Button = %BraceButton
@onready var hamstring_button: Button = %HamstringButton
@onready var patch_button: Button = %PatchButton
@onready var target_one_button: Button = %TargetOneButton
@onready var target_two_button: Button = %TargetTwoButton
@onready var restart_button: Button = %RestartButton
@onready var combat_log: CombatLog = %CombatLog

var simulation: CombatSimulation
var encounter_faulted: bool = false
var selected_target_id: int = FIRST_ENEMY_ID


func _ready() -> void:
	strike_button.pressed.connect(_submit_player_action.bind(&"quick_strike", false))
	heavy_button.pressed.connect(_submit_player_action.bind(&"heavy_swing", false))
	brace_button.pressed.connect(_submit_player_action.bind(&"brace", true))
	hamstring_button.pressed.connect(_submit_player_action.bind(&"hamstring", false))
	patch_button.pressed.connect(_submit_player_action.bind(&"field_patch", true))
	target_one_button.pressed.connect(_select_target.bind(FIRST_ENEMY_ID))
	target_two_button.pressed.connect(_select_target.bind(SECOND_ENEMY_ID))
	restart_button.pressed.connect(_start_encounter)
	_start_encounter()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		_select_target(FIRST_ENEMY_ID)
	elif event.is_action_pressed("move_right"):
		_select_target(SECOND_ENEMY_ID)
	elif event.is_action_pressed("confirm") and get_viewport().gui_get_focus_owner() == null:
		strike_button.grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()


func _start_encounter() -> void:
	simulation = PrototypeEncounter.create_simulation(
		PrototypeEncounter.DEFAULT_SEED,
		PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID,
	)
	selected_target_id = FIRST_ENEMY_ID
	encounter_faulted = false
	combat_log.clear_entries()
	combat_log.append_entry("SYSTEM // two-hostile deterministic encounter loaded", Color("7dd3fc"))
	combat_log.append_entry("Choose a target, read both telegraphs, then commit an action.")
	restart_button.visible = false
	_present_events(simulation.prepare_next_turn())
	_refresh_view()
	strike_button.grab_focus()


func _select_target(target_id: int) -> void:
	var target := simulation.get_combatant(target_id)
	if target != null and not target.is_defeated:
		selected_target_id = target_id
		_refresh_view()


func _submit_player_action(skill_id: StringName, targets_self: bool) -> void:
	if simulation == null or simulation.combat_finished_flag or encounter_faulted:
		return
	var active_actor := simulation.get_next_actor()
	if active_actor == null or active_actor.team != CombatantState.Team.PLAYER:
		return

	var target_id := PLAYER_ID if targets_self else selected_target_id
	var player_events := simulation.resolve_action(ActionCommand.new(active_actor.instance_id, skill_id, target_id))
	_present_events(player_events)
	if _contains_event(player_events, CombatEvent.EventType.ACTION_REJECTED):
		_refresh_view()
		return

	while not simulation.combat_finished_flag and not encounter_faulted:
		active_actor = simulation.get_next_actor()
		if active_actor == null or active_actor.team == CombatantState.Team.PLAYER:
			break
		var enemy_command := simulation.create_enemy_command()
		if enemy_command == null:
			_fault_encounter()
			break
		var enemy_events := simulation.resolve_action(enemy_command)
		_present_events(enemy_events)
		if _contains_event(enemy_events, CombatEvent.EventType.ACTION_REJECTED):
			_fault_encounter()

	_present_events(simulation.prepare_next_turn())
	_choose_living_target()
	_refresh_view()


func _fault_encounter() -> void:
	encounter_faulted = true
	combat_log.append_entry("ENCOUNTER HALTED // restart required", Color("fb7185"))


func _present_events(events: Array[CombatEvent]) -> void:
	for event: CombatEvent in events:
		match event.event_type:
			CombatEvent.EventType.ACTION_STARTED:
				var actor := simulation.get_combatant(event.actor_id)
				var skill := simulation.get_skill(event.skill_id)
				combat_log.append_entry("%s uses %s." % [actor.display_name, skill.display_name])
			CombatEvent.EventType.DAMAGE_DEALT:
				var target := simulation.get_combatant(event.target_id)
				combat_log.append_entry(
					"%s takes %d damage.%s" % [target.display_name, event.amount, " CRITICAL!" if event.critical else ""],
					Color("fca5a5") if event.target_id == PLAYER_ID else Color("fde68a"),
				)
			CombatEvent.EventType.HEALING_DONE:
				var target := simulation.get_combatant(event.target_id)
				combat_log.append_entry("%s restores %d HP." % [target.display_name, event.amount], Color("86efac"))
			CombatEvent.EventType.DEFENSE_APPLIED:
				var actor := simulation.get_combatant(event.actor_id)
				combat_log.append_entry("%s braces for the next attack." % actor.display_name, Color("93c5fd"))
			CombatEvent.EventType.STATUS_APPLIED:
				var target := simulation.get_combatant(event.target_id)
				var definition := simulation.get_status_definition(event.status_id)
				combat_log.append_entry("%s gains %s for %d actions." % [target.display_name, definition.display_name, event.remaining_turns], Color("c4b5fd"))
			CombatEvent.EventType.STATUS_EXPIRED:
				var target := simulation.get_combatant(event.target_id)
				var definition := simulation.get_status_definition(event.status_id)
				combat_log.append_entry("%s's %s expires." % [target.display_name, definition.display_name], Color("94a3b8"))
			CombatEvent.EventType.RESOURCE_GAINED:
				if event.actor_id == PLAYER_ID:
					combat_log.append_entry("%s +%d" % [_resource_name(event.resource_id), event.amount], Color("86efac"))
			CombatEvent.EventType.RESOURCE_SPENT:
				if event.actor_id == PLAYER_ID:
					combat_log.append_entry("%s -%d" % [_resource_name(event.resource_id), event.amount], Color("fcd34d"))
			CombatEvent.EventType.COOLDOWN_APPLIED:
				var skill := simulation.get_skill(event.skill_id)
				combat_log.append_entry("%s cooldown: %d owner actions." % [skill.display_name, event.remaining_turns], Color("94a3b8"))
			CombatEvent.EventType.COMBATANT_DEFEATED:
				var target := simulation.get_combatant(event.target_id)
				combat_log.append_entry("%s is defeated." % target.display_name, Color("fb7185"))
			CombatEvent.EventType.COMBAT_FINISHED:
				var won := event.winning_team == CombatantState.Team.PLAYER
				combat_log.append_entry("VICTORY // threats neutralized" if won else "DEFEAT // crawler incapacitated", Color("86efac") if won else Color("fb7185"))
			CombatEvent.EventType.ACTION_REJECTED:
				combat_log.append_entry("ACTION REJECTED // %s" % event.reason, Color("fb7185"))


func _refresh_view() -> void:
	var player := simulation.get_combatant(PLAYER_ID)
	var enemy_one := simulation.get_combatant(FIRST_ENEMY_ID)
	var enemy_two := simulation.get_combatant(SECOND_ENEMY_ID)
	_update_player(player)
	_update_enemy(enemy_one, enemy_name_label, enemy_hp_label, enemy_hp_bar, enemy_guard_label, enemy_statuses)
	_update_enemy(enemy_two, enemy_two_name_label, enemy_two_hp_label, enemy_two_hp_bar, enemy_two_guard_label, enemy_two_statuses)

	var active_actor := simulation.get_next_actor()
	if encounter_faulted:
		status_label.text = "ENCOUNTER ERROR // RESTART REQUIRED"
	elif simulation.combat_finished_flag:
		status_label.text = "ENCOUNTER COMPLETE"
	elif active_actor != null and active_actor.team == CombatantState.Team.PLAYER:
		status_label.text = "YOUR TURN // CHOOSE AN ACTION"
	else:
		status_label.text = "ENEMY TURN // RESOLVING"

	_update_intents(player)
	_update_timeline()
	var selected := simulation.get_combatant(selected_target_id)
	target_label.text = "TARGET // %s" % selected.display_name.to_upper()
	target_one_button.text = ("> " if selected_target_id == FIRST_ENEMY_ID else "") + enemy_one.display_name.to_upper()
	target_two_button.text = ("> " if selected_target_id == SECOND_ENEMY_ID else "") + enemy_two.display_name.to_upper()
	target_one_button.disabled = enemy_one.is_defeated
	target_two_button.disabled = enemy_two.is_defeated

	var player_can_act := not simulation.combat_finished_flag and not encounter_faulted and active_actor != null and active_actor.team == CombatantState.Team.PLAYER
	_update_skill_button(strike_button, &"quick_strike", player_can_act)
	_update_skill_button(heavy_button, &"heavy_swing", player_can_act)
	_update_skill_button(brace_button, &"brace", player_can_act)
	_update_skill_button(hamstring_button, &"hamstring", player_can_act)
	_update_skill_button(patch_button, &"field_patch", player_can_act)
	restart_button.visible = simulation.combat_finished_flag or encounter_faulted
	if restart_button.visible:
		restart_button.grab_focus()


func _update_player(player: CombatantState) -> void:
	player_name_label.text = player.display_name.to_upper()
	player_hp_label.text = "HP %d/%d" % [player.current_hp, player.max_hp]
	player_hp_bar.max_value = player.max_hp
	player_hp_bar.value = player.current_hp
	player_stamina_label.text = "STAMINA %d/%d  //  PATCHES %d" % [player.get_resource(&"stamina"), player.get_max_resource(&"stamina"), player.get_resource(&"field_patch_charges")]
	player_stamina_bar.max_value = player.get_max_resource(&"stamina")
	player_stamina_bar.value = player.get_resource(&"stamina")
	player_guard_label.visible = player.is_defending and not player.is_defeated
	player_statuses.text = _status_text(player)


func _update_enemy(enemy: CombatantState, name_label: Label, hp_label: Label, hp_bar: ProgressBar, guard_label: Label, statuses_label: Label) -> void:
	name_label.text = enemy.display_name.to_upper()
	hp_label.text = "HP %d/%d" % [enemy.current_hp, enemy.max_hp]
	hp_bar.max_value = enemy.max_hp
	hp_bar.value = enemy.current_hp
	guard_label.visible = enemy.is_defending and not enemy.is_defeated
	statuses_label.text = "DEFEATED" if enemy.is_defeated else _status_text(enemy)


func _update_skill_button(button: Button, skill_id: StringName, player_can_act: bool) -> void:
	var player := simulation.get_combatant(PLAYER_ID)
	var skill := simulation.get_skill(skill_id)
	var cooldown: int = player.cooldowns.get(skill_id, 0)
	var usable := player_can_act and cooldown == 0 and player.can_spend_resource(&"stamina", skill.stamina_cost) and (skill.charge_cost == 0 or player.can_spend_resource(skill.charge_resource_id, skill.charge_cost))
	button.disabled = not usable
	var suffix := " [CD %d]" % cooldown if cooldown > 0 else ""
	button.text = skill.display_name.to_upper() + suffix
	button.tooltip_text = "%s // stamina %d // recovery %d" % [skill.description, skill.stamina_cost, skill.base_recovery]


func _update_intents(player: CombatantState) -> void:
	var lines: PackedStringArray = []
	for enemy: CombatantState in simulation.state.get_living_team_members(CombatantState.Team.ENEMY):
		var skill := simulation.get_enemy_intent_skill(enemy.instance_id)
		if skill == null:
			lines.append("%s // NO VALID INTENT" % enemy.display_name.to_upper())
			continue
		var detail := skill.display_name.to_upper()
		var preview := simulation.get_damage_preview(skill.content_id, enemy.instance_id, player.instance_id, player.is_defending)
		if preview != Vector2i.ZERO:
			detail += " // %d-%d DAMAGE" % [preview.x, preview.y]
		lines.append("%s: %s" % [_short_name(enemy), detail])
	intent_label.text = "INTENTS // " + "  |  ".join(lines)


func _update_timeline() -> void:
	var ordered := simulation.combatants.duplicate()
	ordered.sort_custom(TimelineResolver.acts_before)
	var entries: PackedStringArray = []
	for combatant: CombatantState in ordered:
		if not combatant.is_defeated:
			entries.append("%s %03d" % [combatant.display_name.to_upper(), combatant.next_action_tick])
	timeline_label.text = "TIMELINE // " + "  >  ".join(entries)


func _choose_living_target() -> void:
	var selected := simulation.get_combatant(selected_target_id)
	if selected != null and not selected.is_defeated:
		return
	var enemies := simulation.state.get_living_team_members(CombatantState.Team.ENEMY)
	if not enemies.is_empty():
		selected_target_id = enemies[0].instance_id


func _status_text(combatant: CombatantState) -> String:
	if combatant.statuses.is_empty():
		return "STATUS // CLEAR"
	var labels: PackedStringArray = []
	for status: StatusState in combatant.statuses:
		labels.append("%s %d" % [status.definition.display_name.to_upper(), status.remaining_turns])
	return "STATUS // " + ", ".join(labels)


func _resource_name(resource_id: StringName) -> String:
	return "PATCH" if resource_id == &"field_patch_charges" else String(resource_id).to_upper()


func _short_name(combatant: CombatantState) -> String:
	return combatant.display_name.get_slice(" ", combatant.display_name.get_slice_count(" ") - 1).to_upper()


func _contains_event(events: Array[CombatEvent], event_type: CombatEvent.EventType) -> bool:
	for event: CombatEvent in events:
		if event.event_type == event_type:
			return true
	return false
