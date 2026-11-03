class_name QuestData
extends Resource
## A quest: steps done in order, and rewards when the last one is done (GAME_DESIGN.md §11).
## Files: data/quests/*.tres, listed in data/quests/quest_library.tres.

enum Kind { MAIN, SIDE, TRIAL, BOUNTY }

@export var id: StringName
@export var title: String
@export var kind := Kind.SIDE
@export var giver: String           ## who asked (journal)
@export_multiline var summary: String
@export var steps: Array[QuestStep] = []

@export_group("Rewards")
@export var reward_items: Array[ItemData] = []      ## one entry per unit
@export var reward_recipes: Array[RecipeData] = []
