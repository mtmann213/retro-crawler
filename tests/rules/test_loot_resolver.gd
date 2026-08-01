extends GutTest


func test_stack_limits_are_enforced() -> void:
	var session := RewardSession.new()
	var patch := session.get_item(&"item_field_patch")
	assert_eq(InventoryRules.add_item(session.inventory, patch, 8), 5)
	assert_eq(session.inventory.get_quantity(patch.content_id), 5)
	assert_eq(InventoryRules.add_item(session.inventory, patch, 1), 0)


func test_equipment_modifiers_apply_once_and_restore() -> void:
	var session := RewardSession.new()
	var player := _player()
	var cleaver := session.get_item(&"item_salvaged_cleaver")
	InventoryRules.add_item(session.inventory, cleaver, 1)
	assert_true(EquipmentRules.equip(session.inventory, player, cleaver, session.item_catalog))
	assert_eq(player.power, 15)
	assert_false(EquipmentRules.equip(session.inventory, player, cleaver, session.item_catalog))
	assert_eq(player.power, 15)
	EquipmentRules.apply_equipped_items(session.inventory, player, session.item_catalog)
	assert_eq(player.power, 15)
	assert_true(EquipmentRules.unequip(session.inventory, player, ItemDefinition.EquipmentSlot.WEAPON, session.item_catalog))
	assert_eq(player.power, 12)


func test_loot_weights_and_quantity_ranges_are_valid() -> void:
	for table: LootTableDefinition in PrototypeRewardCatalog.create_loot_tables():
		assert_true(table.validate().is_empty())
		for entry: LootEntryDefinition in table.entries:
			assert_gt(entry.weight, 0)
			assert_gte(entry.maximum_quantity, entry.minimum_quantity)


func test_unique_items_cannot_drop_twice() -> void:
	var unique_table := LootTableDefinition.new()
	unique_table.content_id = &"unique_test"
	unique_table.roll_count = 3
	var unique_entry := LootEntryDefinition.new()
	unique_entry.content_id = &"unique_item"
	unique_entry.unique = true
	unique_table.entries = [unique_entry]
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var drops := LootResolver.roll(unique_table, rng)
	assert_eq(drops.size(), 1)
	var already_owned: Dictionary[StringName, bool] = {&"unique_item": true}
	assert_true(LootResolver.roll(unique_table, rng, already_owned).is_empty())


func test_fixed_seed_produces_identical_loot() -> void:
	var table := PrototypeRewardCatalog.create_loot_tables()[0]
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 731
	second_rng.seed = 731
	assert_eq(_drop_signature(LootResolver.roll(table, first_rng)), _drop_signature(LootResolver.roll(table, second_rng)))


func test_experience_thresholds_are_monotonic() -> void:
	var previous := -1
	for level: int in range(1, ExperienceRules.MAXIMUM_LEVEL + 1):
		var threshold := ExperienceRules.threshold_for_level(level)
		assert_gt(threshold, previous)
		previous = threshold


func test_inventory_survives_in_memory_reload() -> void:
	var session := RewardSession.new()
	var cleaver := session.get_item(&"item_salvaged_cleaver")
	var patch := session.get_item(&"item_field_patch")
	InventoryRules.add_item(session.inventory, cleaver, 1)
	InventoryRules.add_item(session.inventory, patch, 3)
	var player := _player()
	EquipmentRules.equip(session.inventory, player, cleaver, session.item_catalog)
	ExperienceRules.grant_experience(session.progression, 175)
	var restored := RewardSession.from_snapshot(session.to_snapshot())
	assert_eq(restored.inventory.get_quantity(patch.content_id), 3)
	assert_eq(restored.inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON), cleaver.content_id)
	assert_eq(restored.progression.total_experience, 175)
	assert_eq(restored.progression.level, session.progression.level)


func test_combat_reward_equipment_and_item_loop() -> void:
	var session := RewardSession.new()
	var drops := session.grant_rewards(&"loot_combat_victory", 125, 404)
	assert_false(drops.is_empty())
	assert_gt(session.progression.total_experience, 0)
	var player := _player()
	var cleaver := session.get_item(&"item_salvaged_cleaver")
	var patch := session.get_item(&"item_field_patch")
	InventoryRules.add_item(session.inventory, cleaver, 1)
	InventoryRules.add_item(session.inventory, patch, 1)
	assert_true(EquipmentRules.equip(session.inventory, player, cleaver, session.item_catalog))
	assert_eq(player.power, 15)
	player.current_hp = 50
	var before := session.inventory.get_quantity(patch.content_id)
	var events := InventoryRules.use_item(session.inventory, patch, player)
	assert_false(events.is_empty())
	assert_eq(player.current_hp, 80)
	assert_eq(session.inventory.get_quantity(patch.content_id), before - 1)


func test_table_unique_item_stays_unique_across_reward_grants() -> void:
	var session := RewardSession.new()
	var table := LootTableDefinition.new()
	table.content_id = &"forced_unique"
	table.roll_count = 1
	var entry := LootEntryDefinition.new()
	entry.content_id = &"item_worn_collar"
	entry.unique = true
	table.entries = [entry]
	session.loot_tables[table.content_id] = table
	assert_eq(session.grant_rewards(table.content_id, 0, 7).size(), 1)
	assert_true(session.grant_rewards(table.content_id, 0, 7).is_empty())


func _player() -> CombatantState:
	return CombatantState.new(
		1, &"character_test_crawler", "Test Crawler",
		CombatantState.Team.PLAYER, 100, 12, 8, 10,
	)


func _drop_signature(drops: Array[LootDrop]) -> String:
	var parts: PackedStringArray = []
	for drop: LootDrop in drops:
		parts.append("%s:%d" % [drop.item_id, drop.quantity])
	return "|".join(parts)
