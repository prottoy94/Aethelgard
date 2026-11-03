class_name MagicProgression
extends Resource
## Rules for growing stronger (GAME_DESIGN.md §5.2, §6.3): Arcane Ranks, spell mastery and Magic Power.
## Values: data/progression/magic_progression.tres.

@export_group("Arcane Ranks")
@export var rank_letters: PackedStringArray = ["F", "E", "D", "C", "B", "A", "S"]
@export var rank_names: PackedStringArray = ["Spark", "Glimmer", "Lantern", "Beacon", "Star", "Radiant", "Sovereign"]
@export var rank_thresholds: PackedInt32Array = [0, 50, 150, 300, 500, 800, 1200]  ## Magic Power needed
@export var stamina_bonus_per_rank := 10.0
@export var health_bonus_per_rank := 5.0

@export_group("Mastery")
@export var max_mastery := 5
@export var xp_to_next: PackedInt32Array = [20, 50, 100, 200]  ## I→II, II→III, III→IV, IV→V
@export var xp_per_cast := 1
@export var xp_per_hit := 1
@export var power_bonus_per_level := 0.25     ## Magic Power from a spell: power_value × (1 + this × (level − 1))
@export var damage_bonus_per_level := 0.1
@export var cost_reduction_per_level := 0.05
@export var cooldown_reduction_per_level := 0.05

@export_group("Magic Power")
@export var damage_per_power := 0.002         ## spell damage × (1 + Magic Power × this)


func rank_for(magic_power: int) -> int:
	var rank := 0
	for i in rank_thresholds.size():
		if magic_power >= rank_thresholds[i]:
			rank = i
	return rank


func rank_label(rank: int) -> String:
	return "%s · %s" % [rank_letters[rank], rank_names[rank]]


## Magic Power needed for the next rank, or -1 at the top rank.
func next_threshold(rank: int) -> int:
	return rank_thresholds[rank + 1] if rank + 1 < rank_thresholds.size() else -1


func spell_power(spell: SpellData, level: int) -> float:
	return spell.power_value * (1.0 + power_bonus_per_level * (level - 1))


## XP needed to go from `level` to the next one (0 at max mastery).
func xp_needed(level: int) -> int:
	return xp_to_next[level - 1] if level < max_mastery else 0
