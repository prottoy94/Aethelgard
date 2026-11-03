extends Node
## Global signals for events that cross systems (TECHNICAL_DESIGN.md §4.1).
## Systems emit and connect here instead of holding references to each other.
## Scenes still call down to children and signal up to parents directly.

@warning_ignore_start("unused_signal")

# Combat & progression
signal enemy_defeated(enemy_id: StringName)
signal spell_learned(spell_id: StringName)
signal magic_power_changed(magic_power: int)
signal rank_changed(rank: int)

# Items & quests
signal item_collected(item_id: StringName, amount: int)
signal item_crafted(item_id: StringName)
signal quest_started(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal place_reached(place_id: StringName)
signal npc_talked(npc_id: StringName)

# World & story
signal region_changed(region_id: StringName)
signal secret_found(secret_id: StringName)
signal puzzle_solved(puzzle_id: StringName)
signal dragon_hatched()

@warning_ignore_restore("unused_signal")
