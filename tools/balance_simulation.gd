extends SceneTree

const RUNS_PER_ENCOUNTER := 250
const ENCOUNTERS: Array[StringName] = [
	PrototypeEncounter.DUEL_ENCOUNTER_ID,
	PrototypeEncounter.TWO_ENEMY_ENCOUNTER_ID,
	PrototypeEncounter.BRUTE_ENCOUNTER_ID,
	PrototypeEncounter.WARDEN_ENCOUNTER_ID,
]


func _initialize() -> void:
	print("RETRO CRAWLER // RELEASE BALANCE SIMULATION")
	var all_within_guardrails := true
	for encounter_id: StringName in ENCOUNTERS:
		var victories := 0
		var total_actions := 0
		var longest := 0
		for seed_offset: int in range(RUNS_PER_ENCOUNTER):
			var result := _run_encounter(encounter_id, 90_000 + seed_offset)
			victories += 1 if result.victory else 0
			total_actions += result.actions
			longest = maxi(longest, result.actions)
		var win_rate := float(victories) / RUNS_PER_ENCOUNTER
		var average_actions := float(total_actions) / RUNS_PER_ENCOUNTER
		print("%s // win %.1f%% // avg %.1f actions // max %d" % [
			String(encounter_id), win_rate * 100.0, average_actions, longest,
		])
		all_within_guardrails = all_within_guardrails and win_rate >= 0.60 and longest < 80
	quit(0 if all_within_guardrails else 1)


func _run_encounter(encounter_id: StringName, seed_value: int) -> Dictionary:
	var simulation := PrototypeEncounter.create_simulation(seed_value, encounter_id)
	var actions := 0
	while not simulation.combat_finished_flag and actions < 100:
		var actor := simulation.get_next_actor()
		var command: ActionCommand
		if actor.team == CombatantState.Team.PLAYER:
			command = _player_command(simulation, actor)
		else:
			command = simulation.create_enemy_command()
		if command == null:
			break
		simulation.resolve_action(command)
		actions += 1
	var player := simulation.get_first_combatant_on_team(CombatantState.Team.PLAYER)
	return {"victory": player != null and not player.is_defeated, "actions": actions}


func _player_command(simulation: CombatSimulation, player: CombatantState) -> ActionCommand:
	var skill_id := &"quick_strike"
	if player.current_hp <= 58 and player.get_resource(&"field_patch_charges") > 0:
		skill_id = &"field_patch"
	elif _can_use(simulation, player, &"heavy_swing"):
		skill_id = &"heavy_swing"
	elif player.actions_taken % 5 == 2:
		skill_id = &"brace"
	elif player.actions_taken > 0 and player.actions_taken % 5 == 0 and _can_use(simulation, player, &"hamstring"):
		skill_id = &"hamstring"
	var skill := simulation.get_skill(skill_id)
	var target_id := player.instance_id
	if skill.target_rule == SkillDefinition.TargetRule.SINGLE_ENEMY:
		target_id = simulation.get_first_combatant_on_team(CombatantState.Team.ENEMY).instance_id
	return ActionCommand.new(player.instance_id, skill_id, target_id)


func _can_use(simulation: CombatSimulation, player: CombatantState, skill_id: StringName) -> bool:
	var skill := simulation.get_skill(skill_id)
	return player.cooldowns.get(skill_id, 0) == 0 and player.can_spend_resource(&"stamina", skill.stamina_cost)
