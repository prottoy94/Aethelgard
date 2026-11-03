extends SceneTree
## Dev tool: (re)builds data/items/item_library.tres from every ItemData in data/items/ and every RecipeData in
## data/recipes/. Run after adding an item or recipe:
##   godot --headless --path . --script res://tools/dev/build_item_library.gd

const PATH := "res://data/items/item_library.tres"


func _init() -> void:
	var library := ItemLibrary.new()
	for file in DirAccess.get_files_at("res://data/items"):
		var item := load("res://data/items/" + file) as ItemData if file.ends_with(".tres") else null
		if item:
			library.items.append(item)
	for file in DirAccess.get_files_at("res://data/recipes"):
		var recipe := load("res://data/recipes/" + file) as RecipeData if file.ends_with(".tres") else null
		if recipe:
			library.recipes.append(recipe)
	library.recipes.sort_custom(func(a: RecipeData, b: RecipeData) -> bool:
		return a.station < b.station if a.station != b.station else a.display_name() < b.display_name())
	print("items: ", library.items.map(func(i: ItemData) -> StringName: return i.id))
	print("recipes: ", library.recipes.map(func(r: RecipeData) -> StringName: return r.id))
	print("library save: ", error_string(ResourceSaver.save(library, PATH)))
	quit()
