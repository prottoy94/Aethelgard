class_name BossData
extends EnemyData
## A boss (GAME_DESIGN.md §7.2, TECHNICAL_DESIGN.md §4.12): its enemy numbers plus phases (moves unlocked as its HP
## drops), title, music, the flag set when it is beaten and the rewards. Files: data/bosses/*.tres.

@export var title := ""                       ## shown under its name on the boss bar
@export var phases: Array[BossPhaseData] = []
@export var music: StringName                 ## MusicTrack id while fighting
@export var defeat_flag: StringName           ## GameState flag once beaten (it stays beaten)

@export_group("Rewards")
@export var reward_items: Array[ItemData] = []      ## one entry per unit
@export var reward_recipes: Array[RecipeData] = []
