class_name LootResolver
extends RefCounted


static func roll(
	table: LootTableDefinition,
	rng: RandomNumberGenerator,
	acquired_unique_items: Dictionary[StringName, bool] = {},
	active_flags: Dictionary[StringName, bool] = {},
) -> Array[LootDrop]:
	var drops: Array[LootDrop] = []
	if table == null or rng == null or not table.validate().is_empty():
		return drops
	var unavailable_unique_items := acquired_unique_items.duplicate()
	for roll_index: int in table.roll_count:
		var eligible := _eligible_entries(table.entries, unavailable_unique_items, active_flags)
		if eligible.is_empty():
			break
		var selected := _weighted_choice(eligible, rng)
		var quantity := rng.randi_range(selected.minimum_quantity, selected.maximum_quantity)
		drops.append(LootDrop.new(selected.content_id, quantity, selected.unique))
		if selected.unique:
			unavailable_unique_items[selected.content_id] = true
	return drops


static func _eligible_entries(
	entries: Array[LootEntryDefinition],
	unavailable_unique_items: Dictionary[StringName, bool],
	active_flags: Dictionary[StringName, bool],
) -> Array[LootEntryDefinition]:
	var eligible: Array[LootEntryDefinition] = []
	for entry: LootEntryDefinition in entries:
		if entry.unique and unavailable_unique_items.get(entry.content_id, false):
			continue
		var allowed := true
		for required_flag: StringName in entry.required_flags:
			if not active_flags.get(required_flag, false):
				allowed = false
		for excluded_flag: StringName in entry.excluded_flags:
			if active_flags.get(excluded_flag, false):
				allowed = false
		if allowed:
			eligible.append(entry)
	return eligible


static func _weighted_choice(
	entries: Array[LootEntryDefinition],
	rng: RandomNumberGenerator,
) -> LootEntryDefinition:
	var total_weight := 0
	for entry: LootEntryDefinition in entries:
		total_weight += entry.weight
	var roll_value := rng.randi_range(1, total_weight)
	var cumulative := 0
	for entry: LootEntryDefinition in entries:
		cumulative += entry.weight
		if roll_value <= cumulative:
			return entry
	return entries.back()
