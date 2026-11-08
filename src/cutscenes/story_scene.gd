class_name StoryScene
extends CutsceneScene
## A story cutscene written as one title of a .dialogue file (DIALOGUE_DESIGN.md §5.1, "simple scenes"): the lines
## stage it with Cutscene actions (camera, spawn, move, face, anim, emote…), and its `do Cutscene.cue("name")` lines
## are answered by `handler` (the region's director, e.g. VillagePrologue), which may await.

var resource: DialogueResource
var title := ""
var handler: Object   ## has cue(name: StringName) (may be a coroutine)


func run() -> void:
	await talk(resource, title)


func cue(cue_name: StringName) -> void:
	if handler and handler.has_method(&"cue"):
		await handler.call(&"cue", cue_name)
