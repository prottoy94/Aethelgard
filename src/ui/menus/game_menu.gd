class_name GameMenu
extends Node
## The Tab / Start menu (FR-UI-03): a book whose pages are menu screens (Inventory, Grimoire). It opens on the
## last page used; Q/R (D-pad left/right) or the tabs turn the page. Crafting is opened by stations instead.

var pages: Array[MenuScreen] = []
var current := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func add_page(page: MenuScreen) -> void:
	pages.append(page)
	add_child(page)


func is_open() -> bool:
	return pages.any(func(page: MenuScreen) -> bool: return page.is_open())


## Opens page `index` (closing the page that was open).
func open(index := current) -> void:
	for page in pages:
		if page.is_open():
			page.close()
	current = index
	var titles := PackedStringArray()
	for page in pages:
		titles.append(page.title())
	pages[index].set_tabs(titles, index, open)
	pages[index].open()


func page_of(type: Script) -> MenuScreen:
	for page in pages:
		if page.get_script() == type:
			return page
	return null


func _unhandled_input(event: InputEvent) -> void:
	# Open pages receive input first and close themselves; this only opens the menu during play.
	if event.is_action_pressed("menu") and not get_tree().paused and not pages.is_empty():
		open()
		get_viewport().set_input_as_handled()
