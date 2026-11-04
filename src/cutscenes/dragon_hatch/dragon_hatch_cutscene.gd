class_name DragonHatchCutscene
extends CutsceneScene
## The egg hatches (FR-DRG-01, FR-DLG-09; DIALOGUE_DESIGN.md §10 `dragon_hatch`). Started after Aurelia rests at a
## Lantern Shrine with a warm egg: she sets it down, it wobbles, she picks the colour it hatches as (its element), it
## cracks, the hatchling pops out, and she names it. Lines: dialogue/story/dragon_hatch.dialogue.
## Cues: egg_down, wobble, crack, hatch, chirp.

const DIALOGUE: DialogueResource = preload("res://dialogue/story/dragon_hatch.dialogue")
const CUE_TITLE := "dragon_hatch"
const SIDE_DISTANCE := 1.25  ## m to Aurelia's side, as seen by the camera (in front of her it would hide behind her)
const TOWARD_CAMERA := 0.35  ## m towards the camera

var player: Player
var egg: DragonEgg
var dragon: Dragon
var _spot := Vector3.ZERO


func run() -> void:
	player = get_tree().get_first_node_in_group(&"player") as Player
	_spot = global_position
	if player:
		# The egg goes beside her on the camera's right, and she turns to it, so both are seen side by side.
		var yaw := player.camera_yaw()
		var right := Vector3.RIGHT.rotated(Vector3.UP, yaw)
		var toward_camera := Vector3.BACK.rotated(Vector3.UP, yaw)
		_spot = player.global_position + right * SIDE_DISTANCE + toward_camera * TOWARD_CAMERA
		player.velocity = Vector3.ZERO
		player.face_instantly(_spot - player.global_position)
	await talk(DIALOGUE, CUE_TITLE)
	# Make sure it ends hatched even if the conversation stopped early.
	if not DragonManager.is_hatched():
		DragonManager.hatch()
	if dragon == null:
		_spawn_dragon()
	if is_instance_valid(egg):
		egg.queue_free()


func cue(cue_name: StringName) -> void:
	match cue_name:
		&"egg_down":
			_place_egg()
			await pause_for(0.5)
		&"wobble":
			if egg:
				await egg.wobble(3)
		&"crack":
			if egg:
				var kind := DragonManager.TUNING.species_for(DragonManager.element)
				if kind:
					egg.set_tint(kind.breath_color)
				await egg.crack()
		&"hatch":
			DragonManager.hatch()
			if egg:
				egg.burst()
			AudioManager.play(&"dragon_hatch", _egg_spot())
			_spawn_dragon()
			await pause_for(0.9)
		&"chirp":
			if dragon:
				dragon.chirp()
				dragon.show_emote("♥", 2.0)
				dragon.visual.play_happy()
			await pause_for(0.6)


func _egg_spot() -> Vector3:
	return _spot


func _place_egg() -> void:
	if egg:
		return
	egg = DragonEgg.new()
	get_parent().add_child(egg)
	egg.global_position = _egg_spot()
	egg.scale = Vector3.ONE * 0.1
	scene_tween().tween_property(egg, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_dragon() -> void:
	dragon = get_tree().get_first_node_in_group(&"dragon") as Dragon
	if dragon == null:
		dragon = Dragon.spawn(get_parent(), null)
	dragon.global_position = _egg_spot() + Vector3(0, 0.05, 0)
	if player:
		dragon.face(player.global_position - dragon.global_position)
		dragon.visual.rotation.y = dragon.facing_yaw
	dragon.refresh_stats(false)
	dragon.visual.pop_in()
	dragon.visual.play_happy()
