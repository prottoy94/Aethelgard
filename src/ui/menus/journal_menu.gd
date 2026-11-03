class_name JournalMenu
extends MenuScreen
## The Journal page (FR-QST-05, MVP part: quests). Active quests first, then finished ones; choose one to read who
## asked, what it's about, the steps done so far and the current step. Opens from the Tab menu or with J.

const DONE_MARK := "✓"
const CURRENT_MARK := "▸"

var selected: QuestData
var _list: VBoxContainer
var _details: Label


func _ready() -> void:
	super()
	QuestManager.quest_started.connect(func(_quest: QuestData) -> void: _refresh_if_open())
	QuestManager.quest_updated.connect(func(_quest: QuestData) -> void: _refresh_if_open())
	QuestManager.quest_completed.connect(func(_quest: QuestData) -> void: _refresh_if_open())


func title() -> String:
	return "Journal"


func open() -> void:
	if selected == null or not (QuestManager.is_active(selected.id) or QuestManager.is_done(selected.id)):
		var tracked := QuestManager.LIBRARY.find(QuestManager.tracked)
		selected = tracked if tracked else _first_quest()
	super()


func select(quest: QuestData) -> void:
	selected = quest
	refresh()


func refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	var chosen: Button
	for group: Array in [["In progress", QuestManager.active_quests()], ["Finished", QuestManager.done_quests()]]:
		var quests: Array = group[1]
		if quests.is_empty():
			continue
		_list.add_child(make_label(group[0], 17, GOLD.darkened(0.25)))
		for quest: QuestData in quests:
			var button := Button.new()
			button.text = quest.title
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.toggle_mode = true
			button.button_pressed = quest == selected
			style_button(button, 18)
			button.pressed.connect(select.bind(quest))
			_list.add_child(button)
			if quest == selected:
				chosen = button
	if _list.get_child_count() == 0:
		_list.add_child(make_label("No quests yet. Talk to the people of Elderroot.", 17, INK))
	keep_focus(chosen)
	_details.text = quest_text(selected) if selected else ""


## The journal entry for a quest: giver, summary and steps (finished ones ticked).
static func quest_text(quest: QuestData) -> String:
	var lines := PackedStringArray([quest.title, "Asked by %s" % quest.giver, "", quest.summary, ""])
	var finished := QuestManager.is_done(quest.id)
	var current := QuestManager.step_index(quest.id)
	for i in quest.steps.size():
		if finished or i < current:
			lines.append("%s  %s" % [DONE_MARK, quest.steps[i].description])
		elif i == current:
			lines.append("%s  %s" % [CURRENT_MARK, QuestManager.step_text(quest.id)])
	if finished:
		lines.append("")
		lines.append("Finished.")
	return "\n".join(lines)


func _refresh_if_open() -> void:
	if is_open():
		refresh()


func _first_quest() -> QuestData:
	var all := QuestManager.active_quests() + QuestManager.done_quests()
	return all[0] if not all.is_empty() else null


func _build_body() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(400, 0)
	_list.add_theme_constant_override("separation", 4)
	columns.add_child(_list)
	_details = make_label("", 19, INK)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(_details)
