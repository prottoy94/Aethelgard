class_name GameMenu
extends Node
## The Tab / Start menu (FR-UI-03): a book whose pages are menu screens (Inventory, Grimoire, Journal, Save, Options).
## Tab/Start open the last page used, Esc opens the Save page (to save, load or quit); Q/R (D-pad left/right) or the
## tabs turn the page; J opens the Journal, M (Select) the Map.
## Crafting is opened by stations instead.

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


func open_page(type: Script) -> void:
	var page := page_of(type)
	if page:
		open(pages.find(page))


func _unhandled_input(event: InputEvent) -> void:
	# Open pages receive input first and close themselves; this only opens the menu during play.
	if get_tree().paused or pages.is_empty():
		return
	if event.is_action_pressed("menu"):
		open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map") and page_of(MapMenu):
		open_page(MapMenu)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal") and page_of(JournalMenu):
		open_page(JournalMenu)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and page_of(SaveMenu):
		open_page(SaveMenu)
		get_viewport().set_input_as_handled()
