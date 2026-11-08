extends GutTest
## Checks every .dialogue file (FR-DLG-10, FR-DLG-04, DIALOGUE_DESIGN.md §2.3 and §11): each `do`/`if`/`set`/`{{ }}`
## reference names an allowed game object and a method or property that exists; every file says its status; every
## speaker has a portrait style; the cues the game code uses exist.

const ALLOWED: Array[String] = ["GameState", "QuestManager", "Inventory", "PlayerData", "DragonManager", "Cutscene",
		"AudioManager"]
const PORTRAITS: PortraitLibrary = preload("res://data/dialogue/portraits.tres")
## Cues started from code (NPC cues and barks, Lumen and puzzle hints).
const CODE_CUES := {
	"res://dialogue/npcs/elderroot_villagers.dialogue": ["elder", "maren", "tamsin", "elder_bark", "maren_bark",
			"tamsin_bark"],
	"res://dialogue/barks/lumen.dialogue": ["lumen_secret_nearby", "lumen_low_health", "lumen_hint_braziers",
			"lumen_hint_steps", "lumen_hint_block", "lumen_hint_runes"],
	"res://dialogue/story/dragon_hatch.dialogue": ["dragon_hatch"],
	"res://dialogue/world/elderroot_lore.dialogue": ["grove_stone", "tower_stone", "falls_stone", "camp_orders",
			"farm_sign", "circle_stone", "village_notice", "mill_sign"],
	"res://dialogue/npcs/elderroot_folk.dialogue": ["bram", "bram_bark", "wenna", "wenna_bark", "pell", "pell_bark"],
	"res://dialogue/main/prologue.dialogue": ["prologue_morning", "prologue_rank_trial", "prologue_ignis_arrives",
			"prologue_unwinnable", "sylvaris_first_meeting", "elder_quest_start"],
	"res://dialogue/system/trial_shrines.dialogue": ["trial_gust_intro", "trial_gust_test", "trial_gust_complete",
			"trial_gust_repeat"],
}

var _reference := RegEx.create_from_string("\\b([A-Z][A-Za-z]+)\\.([a-z_][a-z_0-9]*)")
var _speaker := RegEx.create_from_string("^\\s*(?:%\\s*)?([A-Z][A-Za-z]+):\\s")


func _dialogue_files(dir := "res://dialogue") -> Array[String]:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".dialogue"):
			files.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		files.append_array(_dialogue_files(dir.path_join(sub)))
	return files


func test_there_are_dialogue_files() -> void:
	assert_gt(_dialogue_files().size(), 1)


func test_references_exist_and_are_allowed() -> void:
	for path in _dialogue_files():
		var number := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			number += 1
			var code := line.strip_edges()
			if code.begins_with("#"):
				continue
			var is_code := code.begins_with("do ") or code.begins_with("if ") or code.begins_with("elif ") \
					or code.begins_with("set ")
			if not is_code and not "{{" in code:
				continue
			for reference in _reference.search_all(code):
				var object := reference.get_string(1)
				var member := reference.get_string(2)
				var where := "%s:%d %s.%s" % [path.get_file(), number, object, member]
				assert_has(ALLOWED, object, "%s: only allowed objects (DIALOGUE_DESIGN.md §2.3)" % where)
				var node := get_tree().root.get_node_or_null(object)
				assert_not_null(node, where)
				if node:
					assert_true(node.has_method(member) or member in node, "%s exists" % where)


func test_files_have_a_status_and_known_speakers() -> void:
	for path in _dialogue_files():
		var text := FileAccess.get_file_as_string(path)
		assert_true(text.begins_with("# status:"), "%s starts with its status" % path.get_file())
		for line in text.split("\n"):
			var found := _speaker.search(line)
			if found:
				assert_not_null(PORTRAITS.find(found.get_string(1)), "%s: %s has a portrait style" % [
					path.get_file(), found.get_string(1)])


func test_cues_used_by_code_exist() -> void:
	for path: String in CODE_CUES:
		var resource := load(path) as DialogueResource
		assert_not_null(resource, path)
		var cues := resource.get_cues()
		for cue: String in CODE_CUES[path]:
			assert_has(cues, cue, "%s has ~ %s" % [path.get_file(), cue])
