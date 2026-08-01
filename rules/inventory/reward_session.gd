class_name RewardSession
extends RefCounted

var inventory := InventoryState.new()
var progression := ProgressionState.new()
var item_catalog: Dictionary[StringName, ItemDefinition] = {}
var loot_tables: Dictionary[StringName, LootTableDefinition] = {}


func _init() -> void:
	for definition: ItemDefinition in PrototypeRewardCatalog.create_items():
		assert(definition.validate().is_empty())
		item_catalog[definition.content_id] = definition
	for table: LootTableDefinition in PrototypeRewardCatalog.create_loot_tables():
		assert(table.validate().is_empty())
		loot_tables[table.content_id] = table


func grant_rewards(
	loot_table_id: StringName,
	experience_amount: int,
	seed_value: int,
) -> Array[LootDrop]:
	var table := loot_tables.get(loot_table_id) as LootTableDefinition
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rolled := LootResolver.roll(table, rng, inventory.acquired_unique_items)
	var accepted: Array[LootDrop] = []
	for drop: LootDrop in rolled:
		var definition := get_item(drop.item_id)
		var added := InventoryRules.add_item(inventory, definition, drop.quantity)
		if added > 0:
			accepted.append(LootDrop.new(drop.item_id, added, drop.unique))
			if drop.unique:
				inventory.acquired_unique_items[drop.item_id] = true
	ExperienceRules.grant_experience(progression, experience_amount)
	return accepted


func get_item(item_id: StringName) -> ItemDefinition:
	return item_catalog.get(item_id) as ItemDefinition


func to_snapshot() -> Dictionary:
	return {
		"inventory": inventory.to_snapshot(),
		"progression": progression.to_snapshot(),
	}


static func from_snapshot(snapshot: Dictionary) -> RewardSession:
	var session := RewardSession.new()
	session.inventory = InventoryState.from_snapshot(snapshot.get("inventory", {}))
	session.progression = ProgressionState.from_snapshot(snapshot.get("progression", {}))
	return session
