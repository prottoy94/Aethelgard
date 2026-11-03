extends GutTest
## QuestManager (FR-QST-02): starting, objectives that finish by themselves, TALK steps, rewards, saving.

const SUNPETAL := preload("res://data/items/sunpetal.tres")
const GUST := preload("res://data/spells/gust.tres")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")

var _test_quest: QuestData


func before_each() -> void:
	Inventory.reset()
	PlayerData.reset([LIGHT_MOTE] as Array[SpellData])
	GameState.reset()
	QuestManager.reset()


func after_each() -> void:
	if _test_quest:
		QuestManager.LIBRARY.quests.erase(_test_quest)
		_test_quest = null


## A quest with one step of every self-finishing kind, added to the library for the test.
func _make_test_quest() -> QuestData:
	_test_quest = QuestData.new()
	_test_quest.id = &"test_every_objective"
	_test_quest.title = "Test"
	var kinds := [
		[QuestStep.Objective.DEFEAT, &"thornling", 2], [QuestStep.Objective.SOLVE, &"test_puzzle", 1],
		[QuestStep.Objective.REACH, &"test_place", 1], [QuestStep.Objective.FLAG, &"test_flag", 1],
		[QuestStep.Objective.LEARN_SPELL, &"gust", 1],
	]
	for kind: Array in kinds:
		var step := QuestStep.new()
		step.objective = kind[0]
		step.target = kind[1]
		step.amount = kind[2]
		step.description = "Step"
		_test_quest.steps.append(step)
	QuestManager.LIBRARY.quests.append(_test_quest)
	return _test_quest


func test_collect_then_talk_then_rewards() -> void:
	watch_signals(QuestManager)
	assert_true(QuestManager.start(&"herbs_for_maren"))
	assert_false(QuestManager.start(&"herbs_for_maren"), "already running")
	assert_true(QuestManager.is_on_step(&"herbs_for_maren", 0))
	assert_eq(QuestManager.step_text(&"herbs_for_maren"), "Gather 3 Sunpetal (0/3)")
	Inventory.add(SUNPETAL, 2)
	assert_eq(QuestManager.progress(&"herbs_for_maren"), 2)
	Inventory.add(SUNPETAL, 1)
	assert_true(QuestManager.is_on_step(&"herbs_for_maren", 1), "holding 3 finishes the gathering step")
	assert_false(QuestManager.advance(&"no_such_quest"))
	assert_true(QuestManager.advance(&"herbs_for_maren"), "the conversation hands them over")
	assert_true(QuestManager.is_done(&"herbs_for_maren"))
	assert_signal_emitted(QuestManager, "quest_completed")
	assert_true(Inventory.knows_recipe(&"stamina_tonic"), "reward recipe")
	assert_eq(Inventory.count(&"moonbloom"), 2, "reward items")
	assert_false(QuestManager.start(&"herbs_for_maren"), "can't start a finished quest")


func test_starting_with_items_already_held() -> void:
	Inventory.add(SUNPETAL, 5)
	QuestManager.start(&"herbs_for_maren")
	assert_true(QuestManager.is_on_step(&"herbs_for_maren", 1))


func test_every_objective_kind() -> void:
	var quest := _make_test_quest()
	QuestManager.start(quest.id)
	EventBus.enemy_defeated.emit(&"thornling")
	assert_true(QuestManager.is_on_step(quest.id, 0), "1 of 2 defeated")
	EventBus.enemy_defeated.emit(&"ember_wisp")
	assert_true(QuestManager.is_on_step(quest.id, 0), "a different enemy doesn't count")
	EventBus.enemy_defeated.emit(&"thornling")
	assert_true(QuestManager.is_on_step(quest.id, 1))
	EventBus.puzzle_solved.emit(&"test_puzzle")
	assert_true(QuestManager.is_on_step(quest.id, 2))
	EventBus.place_reached.emit(&"test_place")
	assert_true(QuestManager.is_on_step(quest.id, 3))
	GameState.set_flag(&"test_flag")
	assert_true(QuestManager.is_on_step(quest.id, 4))
	PlayerData.learn(GUST)
	assert_true(QuestManager.is_done(quest.id))


func test_tracked_quest_follows_activity() -> void:
	QuestManager.start(&"herbs_for_maren")
	QuestManager.start(&"lost_satchel")
	assert_eq(QuestManager.tracked, &"lost_satchel", "the latest one")
	Inventory.add(SUNPETAL, 1)
	assert_eq(QuestManager.tracked, &"lost_satchel", "gathering doesn't steal the tracker")
	QuestManager.advance(&"herbs_for_maren")
	assert_eq(QuestManager.tracked, &"herbs_for_maren", "advancing a step tracks that quest")


func test_save_round_trip() -> void:
	QuestManager.start(&"herbs_for_maren")
	QuestManager.start(&"lost_satchel")
	QuestManager.advance(&"lost_satchel")
	QuestManager.advance(&"lost_satchel")
	var json := JSON.stringify(QuestManager.to_dict())
	QuestManager.reset()
	QuestManager.from_dict(JSON.parse_string(json))
	assert_true(QuestManager.is_active(&"herbs_for_maren"))
	assert_true(QuestManager.is_done(&"lost_satchel"))
	assert_eq(JSON.stringify(QuestManager.to_dict()), json, "same data after loading")


func test_load_skips_unknown_quests() -> void:
	QuestManager.from_dict({"active": {"gone_quest": {"step": 0}, "herbs_for_maren": {"step": 9}}, "done": ["gone"]})
	assert_false(QuestManager.is_active(&"gone_quest"))
	assert_eq(QuestManager.step_index(&"herbs_for_maren"), 1, "step clamped to the last one")
	assert_true(QuestManager.done.is_empty())


func test_quest_data_is_consistent() -> void:
	var ids: Array[StringName] = []
	for quest in QuestManager.LIBRARY.quests:
		assert_false(quest.id in ids, "unique id %s" % quest.id)
		ids.append(quest.id)
		assert_false(quest.steps.is_empty(), "%s has steps" % quest.id)
		for step in quest.steps:
			assert_ne(step.description, "", "%s steps are described" % quest.id)
			if step.objective == QuestStep.Objective.COLLECT:
				assert_not_null(Inventory.LIBRARY.find_item(step.target), "%s collects a real item" % quest.id)
