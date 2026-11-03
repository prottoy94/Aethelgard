class_name ItemLibrary
extends Resource
## Every item and recipe in the game, so saves can refer to them by id. File: data/items/item_library.tres
## (rebuilt by tools/dev/build_item_library.gd after adding items or recipes).

@export var items: Array[ItemData] = []
@export var recipes: Array[RecipeData] = []


func find_item(id: StringName) -> ItemData:
	for item in items:
		if item.id == id:
			return item
	return null


func find_recipe(id: StringName) -> RecipeData:
	for recipe in recipes:
		if recipe.id == id:
			return recipe
	return null
