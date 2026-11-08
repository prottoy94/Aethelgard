class_name CutsceneScene
extends Node3D
## A scripted scene started by `Cutscene.play(id)` (DIALOGUE_DESIGN.md §5.1, "complex scenes"). It runs its dialogue
## in the region's DialogueBox and answers the dialogue's `do Cutscene.cue("name")` lines with movement and effects.
## Conversations pause the game, so the scene keeps running while paused; its tweens use TWEEN_PAUSE_PROCESS.
## While the scene is skipped (Cutscene.skipping) its pauses end at once and its tweens run very fast, so its
## effects still happen (FR-DLG-07).

const SKIP_SPEED := 40.0  ## tween speed while skipping

## Cutscene.play_scene() frees the scene when it ends (a region keeping its own scene object sets this false).
var free_when_done := true


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## The whole scene; Cutscene.play() waits for it. Override.
func run() -> void:
	pass


## One effect asked for by the dialogue. Override; may await.
func cue(_cue_name: StringName) -> void:
	pass


## Plays `cue_title` of `resource` in the region's dialogue box and waits until the conversation ends.
func talk(resource: DialogueResource, cue_title: String) -> void:
	var box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if box == null:
		push_warning("CutsceneScene: no dialogue box in this scene")
		return
	box.start(resource, cue_title, [self])
	if box.is_open():
		await box.finished


## Waits for a tween made with scene_tween() (ends at once if the scene is skipped or the game closes).
func until_done(tween: Tween) -> void:
	await Cutscene.until_done(tween)


## A tween that keeps running while the game is paused.
func scene_tween() -> Tween:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if Cutscene.skipping:
		tween.set_speed_scale(SKIP_SPEED)
	return tween


## Waits `seconds`, or less once the scene is being skipped.
func pause_for(seconds: float) -> void:
	await Cutscene.wait(seconds)
