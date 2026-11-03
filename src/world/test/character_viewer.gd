extends Node3D
## Close-up stage for checking character models and animations (and later Aurelia's VRoid model).
## Shows the animated model on the left and the placeholder Aurelia on the right, facing the camera.
## Start options (after `--`): --model=<res path of a .vrm/.glb>  --anim=<animation name>  --benchmark=<dir>
## Keys: 1 idle, 2 walk, 3 run, 4 dash, 5 cast, 6 strike, 7 interact, Q/R turn the models, Esc quit.

const ANIM_SET := preload("res://data/animations/humanoid_default.tres")
const PLACEHOLDER := preload("res://src/actors/player/aurelia_placeholder.gd")
const STAND_IN_TINT := Color("7a5a8a")
const TURN_SPEED := 1.5

var _humanoid: HumanoidVisual
var _placeholder: Node3D
var _pivot: Node3D
var _mode := &"idle"
var _forced_anim := &""


func _ready() -> void:
	_build_stage()
	_pivot = Node3D.new()
	add_child(_pivot)
	var model_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="):
			model_path = arg.trim_prefix("--model=")
		elif arg.begins_with("--anim="):
			_forced_anim = StringName(arg.trim_prefix("--anim="))
	_humanoid = HumanoidVisual.new()
	_humanoid.anim_set = ANIM_SET
	if model_path.is_empty():
		_humanoid.model_scene = ANIM_SET.library_scene
		_humanoid.stand_in_tint = STAND_IN_TINT
	else:
		_humanoid.model_scene = load(model_path)
	_humanoid.position = Vector3(-0.55, 0, 0)
	_humanoid.rotation_degrees.y = 180.0  # face the camera
	_pivot.add_child(_humanoid)
	_placeholder = PLACEHOLDER.new()
	_placeholder.position = Vector3(0.55, 0, 0)
	_placeholder.rotation_degrees.y = 180.0
	_pivot.add_child(_placeholder)
	add_child(PerfOverlay.new())
	if not _forced_anim.is_empty():
		_humanoid.play_action(_forced_anim)


func _process(delta: float) -> void:
	_pivot.rotate_y(Input.get_axis("camera_rotate_left", "camera_rotate_right") * TURN_SPEED * delta)
	var speeds := {&"idle": 0.0, &"walk": 1.6, &"run": 5.0, &"dash": 15.0}
	if _forced_anim.is_empty() and speeds.has(_mode):
		var speed: float = speeds[_mode]
		_humanoid.update_motion(minf(speed / 5.0, 1.0), _mode == &"dash", delta, speed)
	_placeholder.update_motion(minf(float(speeds.get(_mode, 0.0)) / 5.0, 1.0), _mode == &"dash", delta)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var modes := {KEY_1: &"idle", KEY_2: &"walk", KEY_3: &"run", KEY_4: &"dash"}
	var actions := {KEY_5: ANIM_SET.cast, KEY_6: ANIM_SET.strike, KEY_7: ANIM_SET.interact}
	if modes.has(key.keycode):
		_mode = modes[key.keycode]
		_forced_anim = &""
	elif actions.has(key.keycode):
		_forced_anim = &""
		_humanoid.play_action(actions[key.keycode])
	elif key.keycode == KEY_ESCAPE:
		get_tree().quit()


func _build_stage() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_horizon_color = Color(1.0, 0.85, 0.7)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	var ground := CylinderMesh.new()
	ground.top_radius = 3.0
	ground.bottom_radius = 3.0
	ground.height = 0.05
	var ground_mi := MeshInstance3D.new()
	ground_mi.mesh = ground
	ground_mi.material_override = ToonMaterials.toon(Color(0.42, 0.6, 0.3), 0.1)
	ground_mi.position.y = -0.025
	add_child(ground_mi)
	var camera := Camera3D.new()
	camera.fov = 35.0
	add_child(camera)
	camera.position = Vector3(0, 1.1, 4.2)
	camera.look_at(Vector3(0, 0.85, 0), Vector3.UP)
