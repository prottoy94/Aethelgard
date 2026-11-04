extends Node
## Active and finished quests (FR-QST-02). Objectives advance by themselves from game events (items in the bag,
## enemies defeated, puzzles solved, spells learned, places reached, flags set); TALK steps are advanced by dialogue.
## Finishing the last step hands out the rewards. Dialogue may call start/advance/is_active/is_done/is_on_step.
## Saved by SaveManager through to_dict() / from_dict(), by id.

signal quest_started(quest: QuestData)
signal quest_updated(quest: QuestData)
signal quest_completed(quest: QuestData)

const LIBRARY: QuestLibrary = preload("res://data/quests/quest_library.tres")

## quest id → {"step": int, "count": int} for quests in progress
var active: Dictionary[StringName, Dictionary] = {}
var done: Array[StringName] = []
## The quest the HUD tracker shows (the last one started or updated).
var tracked: StringName = &""


func _ready() -> void:
	EventBus.item_collected.connect(func(_id: StringName, _amount: int) -> void: _check_all())
	EventBus.enemy_defeated.connect(func(id: StringName) -> void: _count(QuestStep.Objective.DEFEAT, id))
	EventBus.puzzle_solved.connect(func(id: StringName) -> void: _count(QuestStep.Objective.SOLVE, id))
	EventBus.spell_learned.connect(func(_id: StringName) -> void: _check_all())
	EventBus.place_reached.connect(func(id: StringName) -> void: _count(QuestStep.Objective.REACH, id))
	GameState.flag_changed.connect(func(_flag: StringName, _value: bool) -> void: _check_all())
	Inventory.item_removed.connect(func(_item: ItemData, _amount: int) -> void: _changed_counts())
	Inventory.item_added.connect(func(_item: ItemData, _amount: int) -> void: _changed_counts())


## The GameState flag set when quest `id` is finished, e.g. "quest_done_herbs_for_maren".
static func done_flag(id: StringName) -> StringName:
	return StringName("quest_done_%s" % id)


func reset() -> void:
	active.clear()
	done.clear()
	tracked = &""


# --- Used by dialogue and the game ------------------------------------------------------------

func start(id: StringName) -> bool:
	var quest := LIBRARY.find(id)
	if quest == null or is_active(id) or is_done(id):
		return false
	active[id] = {"step": 0, "count": 0}
	tracked = id
	quest_started.emit(quest)
	EventBus.quest_started.emit(id)
	_check(quest)
	return true


func is_active(id: StringName) -> bool:
	return active.has(id)


func is_done(id: StringName) -> bool:
	return id in done


## True while quest `id` is active and on step `index` (0-based).
func is_on_step(id: StringName, index: int) -> bool:
	return is_active(id) and int(active[id]["step"]) == index


func step_index(id: StringName) -> int:
	return int(active[id]["step"]) if is_active(id) else -1


## Finishes the current step (TALK steps, or a conversation that hands items over). Returns false if not active.
func advance(id: StringName) -> bool:
	var quest := LIBRARY.find(id)
	if quest == null or not is_active(id):
		return false
	var entry := active[id]
	entry["step"] = int(entry["step"]) + 1
	entry["count"] = 0
	tracked = id
	if int(entry["step"]) >= quest.steps.size():
		_complete(quest)
	else:
		quest_updated.emit(quest)
		_check(quest)
	return true


func current_step(id: StringName) -> QuestStep:
	var quest := LIBRARY.find(id)
	return quest.steps[step_index(id)] if quest and is_active(id) else null


## How far the current step's counter is (held items for COLLECT, defeats for DEFEAT).
func progress(id: StringName) -> int:
	var step := current_step(id)
	if step == null:
		return 0
	if step.objective == QuestStep.Objective.COLLECT:
		return mini(Inventory.count(step.target), step.amount)
	return int(active[id]["count"])


func active_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for id in active:
		var quest := LIBRARY.find(id)
		if quest:
			result.append(quest)
	return result


func done_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for id in done:
		var quest := LIBRARY.find(id)
		if quest:
			result.append(quest)
	return result


## "Gather Sunpetal (2/3)" for the HUD tracker and journal.
func step_text(id: StringName) -> String:
	var step := current_step(id)
	if step == null:
		return ""
	return "%s (%d/%d)" % [step.description, progress(id), step.amount] if step.shows_progress() else step.description


# --- Objectives --------------------------------------------------------------------------------

func _count(objective: QuestStep.Objective, target: StringName) -> void:
	for id in active.keys():
		var step := current_step(id)
		if step and step.objective == objective and step.target == target:
			active[id]["count"] = int(active[id]["count"]) + 1
			tracked = id
			quest_updated.emit(LIBRARY.find(id))
	_check_all()


func _changed_counts() -> void:
	for id in active.keys():
		var step := current_step(id)
		if step and step.objective == QuestStep.Objective.COLLECT:
			quest_updated.emit(LIBRARY.find(id))
	_check_all()


func _check_all() -> void:
	for id in active.keys():
		if is_active(id):
			_check(LIBRARY.find(id))


## Finishes the current step if its objective is met (repeats: the next step may already be met too).
func _check(quest: QuestData) -> void:
	var step := current_step(quest.id)
	if step and _is_met(quest.id, step):
		advance(quest.id)


func _is_met(id: StringName, step: QuestStep) -> bool:
	match step.objective:
		QuestStep.Objective.COLLECT:
			return Inventory.has(step.target, step.amount)
		QuestStep.Objective.LEARN_SPELL:
			return PlayerData.knows(step.target)
		QuestStep.Objective.FLAG:
			return GameState.has_flag(step.target)
		QuestStep.Objective.DEFEAT, QuestStep.Objective.REACH, QuestStep.Objective.SOLVE:
			return int(active[id]["count"]) >= step.amount
	return false  # TALK: the conversation advances it


func _complete(quest: QuestData) -> void:
	active.erase(quest.id)
	done.append(quest.id)
	if tracked == quest.id:
		tracked = active.keys()[0] if not active.is_empty() else &""
	for item in quest.reward_items:
		Inventory.add(item)
	for recipe in quest.reward_recipes:
		Inventory.learn_recipe(recipe)
	quest_completed.emit(quest)
	EventBus.quest_completed.emit(quest.id)
	GameState.set_flag(done_flag(quest.id))  # other quests can wait for this one (FLAG steps)


# --- Saving ------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	var running := {}
	var ids: Array[StringName] = []
	ids.assign(active.keys())
	ids.sort()
	for id in ids:
		running[String(id)] = {"step": int(active[id]["step"]), "count": int(active[id]["count"])}
	var finished: Array[String] = []
	for id in done:
		finished.append(String(id))
	return {"active": running, "done": finished, "tracked": String(tracked)}


## Restores saved quests. Ids no longer in the game are skipped.
func from_dict(data: Dictionary) -> void:
	reset()
	var running: Dictionary = data.get("active", {})
	for key: Variant in running:
		var quest := LIBRARY.find(StringName(str(key)))
		if quest:
			var entry: Dictionary = running[key]
			active[quest.id] = {"step": clampi(int(entry.get("step", 0)), 0, quest.steps.size() - 1),
					"count": int(entry.get("count", 0))}
	for key: Variant in data.get("done", []):
		if LIBRARY.find(StringName(str(key))):
			done.append(StringName(str(key)))
	tracked = StringName(str(data.get("tracked", "")))
	if not active.has(tracked):
		tracked = active.keys()[0] if not active.is_empty() else &""
