class_name NewGameItems
extends Resource
## What Aurelia owns at the start of a new game. File: data/items/new_game_items.tres.

@export var items: Array[ItemData] = []           ## one entry per unit (list an item twice for two)
@export var equipment: Array[EquipmentData] = []  ## equipped at the start
@export var recipes: Array[RecipeData] = []       ## known at the start
