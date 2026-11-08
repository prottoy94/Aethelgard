extends CanvasLayer
## Cutscene helpers called from .dialogue files (DIALOGUE_DESIGN.md §5.2, FR-DLG-06): letterbox bars, fading, waiting,
## a cutscene camera, moving and animating actors, emotes, shakes and flashes, playing scripted scenes, asking the
## player to type a name, and skipping (FR-DLG-07). Timed actions can be awaited (`do Cutscene.wait(1)`); a
## conversation waits for them before its next line.
##
## Scripted scenes (Phase 7): `Cutscene.play(&"dragon_hatch")` adds that scene's CutsceneScene next to Aurelia; it runs
## its dialogue, and the dialogue's `do Cutscene.cue("name")` lines run the scene's effects. A region can also play its
## own scene instance with play_scene() (the prologue).
##
## Actors and markers (Phase 8b) are found by id: actors are nodes tagged with CutsceneActor.tag() ("aurelia" is
## Aurelia, NPCs use their npc_id, "lumen", "dragon"), markers are CutsceneMarker nodes. Conversations pause the game,
## so actions run while paused: the actors a scene moves or animates keep animating until it ends.
##
## Skipping (FR-DLG-07): holding Esc (or B) for a second fast-forwards the scene instead of jumping out of it: lines
## finish at once, flavour choices take the first answer and timed actions end at once, so every effect still happens
## in order. Choices tagged [#ask] (the dragon's colour) and the name box still wait for the player. Each scene sets
## the flag cs_<id>_seen when it ends.

signal cutscene_started(id: StringName)
signal cutscene_finished(id: StringName)
signal skipped(id: StringName)
signal _text_entered(text: String)
signal _tick   ## every frame (also while paused); timed actions wait on it, so closing the game can release them

const LAYER := 25             ## the bars and fade: above the HUD and menus, below the dialogue box (30)
const PROMPT_LAYER := 45      ## the name box: above everything
const BAR_HEIGHT := 0.11      ## of the screen height
const BAR_TIME := 0.4         ## s to slide the bars in or out
const SKIP_HOLD := 1.0        ## s to hold Esc/B to skip
const SKIP_ACTION: StringName = &"ui_cancel"
const ACTOR_PLAYER: StringName = &"aurelia"
const ACTOR_LUMEN: StringName = &"lumen"
const ACTOR_DRAGON: StringName = &"dragon"
## Scripted scenes by id (loaded when played).
const SCENES := {
	&"dragon_hatch": "res://src/cutscenes/dragon_hatch/dragon_hatch_cutscene.gd",
}
const PARCHMENT := Color("f3e9d2")
const INK := Color("3b2a1e")
const GOLD := Color("b8862e")

var active: CutsceneScene
## True once the game is closing: every timed action ends at once, so no scene code is left waiting at exit.
var closing := false
## True while a scene is being fast-forwarded (FR-DLG-07). The dialogue box and timed actions read it.
var skipping := false
var _active_id: StringName = &""
var _top: ColorRect
var _bottom: ColorRect
var _fade: ColorRect
var _flash: ColorRect
var _prompt: PanelContainer
var _prompt_label: Label
var _prompt_edit: LineEdit
var _prompt_default := ""
var _skip_hint: Label
var _skip_hold := 0.0
var _skip_paused := false
var _acting := 0
var _camera: Camera3D
var _play_camera: Camera3D
## node → its process mode before the scene made it keep animating while paused
var _involved: Dictionary[Node, Node.ProcessMode] = {}


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_top = _bar(Control.PRESET_TOP_WIDE)
	_bottom = _bar(Control.PRESET_BOTTOM_WIDE)
	_fade = _full_rect(Color(0, 0, 0, 0))
	_flash = _full_rect(Color(1, 1, 1, 0))
	_build_skip_hint()
	_build_prompt()


func _exit_tree() -> void:
	# Quitting mid-scene: let every waiting action and conversation run out now instead of hanging at exit.
	closing = true
	_text_entered.emit(_prompt_default)
	for i in 64:
		_tick.emit()


func _process(delta: float) -> void:
	_tick.emit()
	var can_skip := is_playing() and not skipping and not is_asking()
	if can_skip and Input.is_action_pressed(SKIP_ACTION):
		_skip_hold += delta
		if _skip_hold >= SKIP_HOLD:
			_skip_hold = 0.0
			skip()
	else:
		_skip_hold = maxf(_skip_hold - delta * 2.0, 0.0)
	_skip_hint.visible = can_skip
	_skip_hint.text = "Hold Esc to skip" if _skip_hold <= 0.0 else "Skipping%s" % ".".repeat(1 + int(_skip_hold * 3.0))
	_skip_hint.modulate.a = 0.55 + 0.45 * clampf(_skip_hold / SKIP_HOLD, 0.0, 1.0)


func is_letterboxed() -> bool:
	return _top.scale.y > 0.5


## Slides the black bars in (true) or out (false).
func letterbox(on: bool) -> void:
	var target := 1.0 if on else 0.0
	if skipping or closing or not is_inside_tree():
		_top.scale.y = target
		_bottom.scale.y = target
		return
	_acting += 1
	var tween := create_tween().set_parallel()
	tween.tween_property(_top, "scale:y", target, BAR_TIME)
	tween.tween_property(_bottom, "scale:y", target, BAR_TIME)
	await until_done(tween)
	_acting -= 1


func fade_out(seconds := 0.6) -> void:
	await _fade_to(1.0, seconds)


func fade_in(seconds := 0.6) -> void:
	await _fade_to(0.0, seconds)


func wait(seconds: float) -> void:
	_acting += 1
	var left := seconds
	while left > 0.0 and not skipping and not closing:
		await _tick
		left -= get_process_delta_time()
	_acting -= 1


## A white (or coloured) flash over the screen, e.g. a spell striking. Doesn't wait.
func flash(color := "ffffff", seconds := 0.5) -> void:
	_flash.color = Color(color)
	_flash.color.a = 0.85
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.05 if skipping else seconds)


## Shakes the camera for a moment. Doesn't wait (the next line shows while it shakes).
func shake(strength := 0.3, seconds := 0.5) -> void:
	var camera := get_viewport().get_camera_3d()
	var rig := get_tree().get_first_node_in_group(&"camera_rig") as CameraRig
	if camera == null or skipping or (rig and not rig.shake_enabled):  # the accessibility switch (GDD §13)
		return
	var target: WeakRef = weakref(camera)  # the cutscene camera may be freed before the shake ends
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var shaken: Camera3D = target.get_ref() as Camera3D
		if shaken:
			var power := strength * (1.0 - t)
			shaken.h_offset = randf_range(-power, power)
			shaken.v_offset = randf_range(-power, power), 0.0, 1.0, seconds)
	tween.tween_callback(func() -> void:
		var shaken: Camera3D = target.get_ref() as Camera3D
		if shaken:
			shaken.h_offset = 0.0
			shaken.v_offset = 0.0)


## Waits for `tween` to finish, or less if the scene is skipped or the game closes (use instead of tween.finished).
func until_done(tween: Tween) -> void:
	while is_instance_valid(tween) and tween.is_valid() and tween.is_running() and not closing:
		if skipping:
			tween.custom_step(1000.0)
			return
		await _tick


## True while a timed action (camera move, walk, wait, cue) is running: the dialogue box steps aside.
func is_acting() -> bool:
	return _acting > 0


## Back to normal at once (scene changes, the end of a scene).
func clear() -> void:
	_top.scale.y = 0.0
	_bottom.scale.y = 0.0
	_fade.color.a = 0.0
	_flash.color.a = 0.0
	if _prompt.visible:
		_submit(_prompt_edit.text)
	_release_camera()
	_release_involved()
	skipping = false
	_skip_paused = false
	_acting = 0


# --- Camera ---------------------------------------------------------------------------------------

## Moves the cutscene camera to marker `marker_id` (its place, looking along its -Z) over `seconds`. The first call
## starts from the play camera, so the view blends from gameplay.
func camera_to(marker_id: String, seconds := 1.0) -> void:
	var target := CutsceneMarker.find(get_tree(), StringName(marker_id))
	if target == null:
		push_warning("Cutscene: no marker %s" % marker_id)
		return
	if not _ensure_camera():
		return
	await _move_camera(target.global_transform, seconds)


## Blends back to the play camera and hands the view back to it.
func camera_back(seconds := 0.8) -> void:
	if _camera == null:
		return
	if is_instance_valid(_play_camera) and _play_camera.is_inside_tree() and _camera.is_inside_tree():
		await _move_camera(_play_camera.global_transform, seconds)
	_release_camera()


func has_camera() -> bool:
	return _camera != null


# --- Actors -----------------------------------------------------------------------------------------

## The node playing `actor_id`: "aurelia", "lumen", "dragon", or any tagged actor.
func actor(actor_id: String) -> Node3D:
	match StringName(actor_id):
		ACTOR_PLAYER:
			return get_tree().get_first_node_in_group(&"player") as Node3D
		ACTOR_LUMEN:
			return get_tree().get_first_node_in_group(&"lumen") as Node3D
		ACTOR_DRAGON:
			return get_tree().get_first_node_in_group(&"dragon") as Node3D
	return CutsceneActor.find(get_tree(), StringName(actor_id))


## Puts `actor_id` at marker `marker_id` (facing along it) and shows it.
func spawn(actor_id: String, marker_id: String) -> void:
	var node := _actor_or_warn(actor_id)
	var at := CutsceneMarker.find(get_tree(), StringName(marker_id))
	if node == null or at == null:
		if at == null:
			push_warning("Cutscene: no marker %s" % marker_id)
		return
	node.global_position = at.global_position
	_set_facing(node, -at.global_basis.z)
	node.visible = true
	involve(node)
	if node.has_method(&"on_spawned"):
		node.call(&"on_spawned")


func despawn(actor_id: String) -> void:
	var node := _actor_or_warn(actor_id)
	if node:
		node.visible = false


## Walks `actor_id` to marker `marker_id` in `seconds`, facing the way it goes.
func move(actor_id: String, marker_id: String, seconds := 1.5) -> void:
	var node := _actor_or_warn(actor_id)
	var at := CutsceneMarker.find(get_tree(), StringName(marker_id))
	if node == null or at == null:
		if at == null:
			push_warning("Cutscene: no marker %s" % marker_id)
		return
	await walk_to(node, at.global_position, seconds)


## Walks `node` to `to` in `seconds` (also used by scene code).
func walk_to(node: Node3D, to: Vector3, seconds: float) -> void:
	var from := node.global_position
	var distance := Vector2(to.x - from.x, to.z - from.z).length()
	if distance > 0.01:
		_set_facing(node, to - from)
	if seconds <= 0.0 or distance <= 0.01 or skipping or closing:
		node.global_position = to
		_animate_walk(node, 0.0, 0.016)
		return
	involve(node)
	_acting += 1
	var speed := distance / seconds
	var elapsed := 0.0
	while elapsed < seconds and not skipping and not closing and is_instance_valid(node):
		await _tick
		var delta := get_process_delta_time()
		elapsed += delta
		node.global_position = from.lerp(to, minf(elapsed / seconds, 1.0))
		_animate_walk(node, speed, delta)
	if is_instance_valid(node):
		node.global_position = to
		_animate_walk(node, 0.0, 0.016)
	_acting -= 1


## Turns `actor_id` towards another actor or a marker called `target_id`.
func face(actor_id: String, target_id: String) -> void:
	var node := _actor_or_warn(actor_id)
	if node == null:
		return
	var target: Node3D = actor(target_id)
	if target == null:
		target = CutsceneMarker.find(get_tree(), StringName(target_id))
	if target:
		_set_facing(node, target.global_position - node.global_position)


## Plays animation `anim_name` on `actor_id`: Aurelia's roles ("cast", "strike", "hurt", "interact", "rest"), or the
## actor's own (play_anim). Doesn't wait.
func anim(actor_id: String, anim_name: String) -> void:
	var node := _actor_or_warn(actor_id)
	if node == null:
		return
	involve(node)
	if node.has_method(&"play_anim"):
		node.call(&"play_anim", StringName(anim_name))
		return
	var visual := _visual_of(node)
	if anim_name == "idle" and visual and visual.has_method(&"reset_pose"):
		visual.call(&"reset_pose")  # back to standing (after "rest", "hurt"…)
		return
	if visual and visual.has_method(&"play_role"):
		visual.call(&"play_role", StringName(anim_name))
	elif visual and visual.has_method(&"play_anim"):
		visual.call(&"play_anim", StringName(anim_name))


## An emote bubble over `actor_id`: "!", "?", "♥", "♪", "…".
func emote(actor_id: String, icon: String) -> void:
	var node := _actor_or_warn(actor_id)
	if node == null:
		return
	var height: float = node.get(&"emote_height") if &"emote_height" in node else 2.0
	EmoteBubble.show_over(node, icon, height)


## Keeps `node` (or its visual) animating while a conversation pauses the game, until the scene ends.
func involve(node: Node3D) -> void:
	var target: Node = _visual_of(node)
	if node is CutsceneActor or target == null:
		target = node
	if _involved.has(target):
		return
	_involved[target] = target.process_mode
	target.process_mode = Node.PROCESS_MODE_ALWAYS


# --- Scripted scenes -----------------------------------------------------------------------------

func is_playing() -> bool:
	return active != null


func active_id() -> StringName:
	return _active_id


## Plays scripted scene `id` next to Aurelia and returns when it is over. Does nothing while another one plays.
func play(id: StringName) -> void:
	if active or not SCENES.has(id):
		if not SCENES.has(id):
			push_warning("Cutscene: no scene called %s" % id)
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var parent: Node = player.get_parent() if player else get_tree().current_scene
	if parent == null:
		return
	var script := load(SCENES[id]) as Script
	var scene := script.new() as CutsceneScene
	parent.add_child(scene)
	await play_scene(scene, id)


## Plays a scene instance the caller made (and added to the tree), e.g. a region's own story scene.
func play_scene(scene: CutsceneScene, id: StringName) -> void:
	if active:
		return
	active = scene
	_active_id = id
	cutscene_started.emit(id)
	await scene.run()
	if is_instance_valid(scene) and scene.free_when_done:
		scene.queue_free()
	active = null
	_active_id = &""
	GameState.set_flag(seen_flag(id))
	var was_skipping := skipping
	skipping = false
	_skip_paused = false
	_release_involved()
	if _camera:
		await camera_back(0.0 if was_skipping else 0.6)
	letterbox(false)
	if was_skipping:
		_fade.color.a = 0.0
	cutscene_finished.emit(id)


## The flag a scene sets once it has played: cs_<id>_seen.
static func seen_flag(id: StringName) -> StringName:
	return StringName("cs_%s_seen" % id)


## Runs effect `cue_name` of the scene that is playing (`do Cutscene.cue("hatch")`); waits until it is done.
func cue(cue_name: String) -> void:
	if active:
		_acting += 1
		await active.cue(StringName(cue_name))
		_acting -= 1


## Fast-forwards the playing scene (FR-DLG-07).
func skip() -> void:
	if not is_playing() or skipping:
		return
	skipping = true
	skipped.emit(_active_id)
	var box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if box:
		box.fast_forward()


## A choice or name box that needs the player stops the fast-forward for a moment.
func pause_skip() -> void:
	if skipping:
		skipping = false
		_skip_paused = true


func resume_skip() -> void:
	if _skip_paused and is_playing():
		_skip_paused = false
		skipping = true
		var box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
		if box:
			box.fast_forward.call_deferred()


# --- Typing a name (FR-DLG-09) -------------------------------------------------------------------

func is_asking() -> bool:
	return _prompt.visible


## Shows a small parchment box with a text field and waits for Enter or OK. An empty answer returns `default_text`.
func ask_text(question: String, default_text: String, max_length := 14) -> String:
	pause_skip()
	_prompt_label.text = question
	_prompt_default = default_text
	_prompt_edit.text = ""
	_prompt_edit.placeholder_text = default_text
	_prompt_edit.max_length = max_length
	_prompt.visible = true
	_prompt_edit.grab_focus.call_deferred()
	var text: String = await _text_entered
	resume_skip()
	return text


## Answers the open name box (the OK button, Enter, and tests).
func submit_text(text: String) -> void:
	if _prompt.visible:
		_submit(text)


func _submit(text: String) -> void:
	_prompt.visible = false
	var answer := text.strip_edges()
	_text_entered.emit(answer if answer != "" else _prompt_default)


func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	_prompt.add_theme_stylebox_override("panel", style)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BOTH
	_prompt.custom_minimum_size = Vector2(460, 0)
	_prompt.visible = false
	var prompt_layer := CanvasLayer.new()
	prompt_layer.layer = PROMPT_LAYER
	add_child(prompt_layer)
	prompt_layer.add_child(_prompt)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_prompt.add_child(column)
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 26)
	_prompt_label.add_theme_color_override("font_color", INK)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_prompt_label)
	_prompt_edit = LineEdit.new()
	_prompt_edit.add_theme_font_size_override("font_size", 26)
	_prompt_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_edit.custom_minimum_size = Vector2(0, 48)
	_prompt_edit.text_submitted.connect(_submit)
	column.add_child(_prompt_edit)
	var hint := Label.new()
	hint.text = "Type a name, then Enter.  Leave it empty to keep the suggestion."
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", INK.lightened(0.3))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(140, 44)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuScreen.style_button(ok, 20)
	ok.pressed.connect(func() -> void: _submit(_prompt_edit.text))
	column.add_child(ok)
	_prompt_edit.focus_neighbor_bottom = _prompt_edit.get_path_to(ok)
	ok.focus_neighbor_top = ok.get_path_to(_prompt_edit)


# --- Inside --------------------------------------------------------------------------------------

func _fade_to(alpha: float, seconds: float) -> void:
	if seconds <= 0.0 or skipping or closing:
		_fade.color.a = alpha
		return
	_acting += 1
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await until_done(tween)
	_fade.color.a = alpha
	_acting -= 1


func _ensure_camera() -> bool:
	if _camera:
		return true
	_play_camera = get_viewport().get_camera_3d()
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var parent: Node = player.get_parent() if player else get_tree().current_scene
	if _play_camera == null or parent == null:
		return false
	_camera = Camera3D.new()
	_camera.name = &"CutsceneCamera"
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # moved by tweens every frame
	parent.add_child(_camera)
	_camera.global_transform = _play_camera.global_transform
	_camera.fov = _play_camera.fov
	_camera.near = _play_camera.near
	_camera.far = _play_camera.far
	_camera.cull_mask = _play_camera.cull_mask
	_camera.make_current()
	return true


func _move_camera(to: Transform3D, seconds: float) -> void:
	if _camera == null or not _camera.is_inside_tree():
		return
	if seconds <= 0.0 or skipping or closing:
		_camera.global_transform = to
		return
	_acting += 1
	var from := _camera.global_transform
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(_camera):
			_camera.global_transform = from.interpolate_with(to, t), 0.0, 1.0, seconds) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await until_done(tween)
	if is_instance_valid(_camera) and _camera.is_inside_tree():
		_camera.global_transform = to
	_acting -= 1


func _release_camera() -> void:
	if _camera and is_instance_valid(_camera):
		_camera.queue_free()
	_camera = null
	if is_instance_valid(_play_camera) and _play_camera.is_inside_tree():
		_play_camera.make_current()
	_play_camera = null


func _release_involved() -> void:
	for node: Node in _involved:
		if is_instance_valid(node):
			node.process_mode = _involved[node]
	_involved.clear()


func _actor_or_warn(actor_id: String) -> Node3D:
	var node := actor(actor_id)
	if node == null:
		push_warning("Cutscene: no actor %s" % actor_id)
	return node


func _visual_of(node: Node3D) -> Node:
	var visual: Variant = node.get(&"visual") if &"visual" in node else null
	return visual as Node if visual is Node else node.get_node_or_null(^"Visual")


func _set_facing(node: Node3D, direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	if node is Player:
		(node as Player).face_instantly(direction)
	elif node is Enemy:
		(node as Enemy).face(direction)
	elif node is Npc:
		(node as Npc).face_point(node.global_position + direction)
		var visual := (node as Npc).visual
		if visual:
			visual.rotation.y = 0.0
	else:
		node.rotation.y = Player.yaw_of(direction)


## Leg and wing motion while a cutscene walks an actor.
func _animate_walk(node: Node3D, speed: float, delta: float) -> void:
	if node is Player:
		var player := node as Player
		player.velocity = Vector3.ZERO
		if player.visual.has_method(&"update_motion"):
			player.visual.update_motion(speed / player.stats.walk_speed, false, delta, speed)
	elif node is CharacterBody3D:
		(node as CharacterBody3D).velocity = -node.global_basis.z * speed if speed > 0.0 else Vector3.ZERO
		if node is Enemy and (node as Enemy).visual.has_method(&"set_walking"):
			(node as Enemy).visual.call(&"set_walking", speed)
	elif node.has_method(&"set_walking"):
		node.call(&"set_walking", speed)


func _full_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	return rect


func _build_skip_hint() -> void:
	_skip_hint = Label.new()
	_skip_hint.add_theme_font_size_override("font_size", 18)
	_skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_skip_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_skip_hint.add_theme_constant_override("outline_size", 6)
	_skip_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip_hint.offset_left = -260.0
	_skip_hint.offset_right = -24.0
	_skip_hint.offset_top = 18.0
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.visible = false
	add_child(_skip_hint)


func _bar(preset: Control.LayoutPreset) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(preset)
	bar.anchor_top = 0.0 if preset == Control.PRESET_TOP_WIDE else 1.0 - BAR_HEIGHT
	bar.anchor_bottom = BAR_HEIGHT if preset == Control.PRESET_TOP_WIDE else 1.0
	bar.offset_top = 0.0
	bar.offset_bottom = 0.0
	bar.scale.y = 0.0
	add_child(bar)
	bar.resized.connect(func() -> void:  # scale from the screen edge
		bar.pivot_offset = Vector2(0, 0.0 if preset == Control.PRESET_TOP_WIDE else bar.size.y))
	return bar
