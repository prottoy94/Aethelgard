class_name GuideTrail
extends Node3D
## The "show the way" trail: little lights in Lumen's blue float along the ground from Aurelia towards the target in a
## few waves, and a beam of light marks the target when it is close enough to see. Removes itself afterwards.

const COLOR := Color(0.55, 0.85, 1.0)
const MAX_LENGTH := 28.0   ## m of trail shown (the direction matters more than the whole way)
const SPACING := 1.4       ## m between lights
const WAVES := 3
const WAVE_GAP := 0.45     ## s
const TRAVEL := 1.6        ## s for a light to run the trail
const HEIGHT := 0.35
const BEAM_RANGE := 45.0   ## m: the target gets a beam when closer than this
const LIFETIME := 4.0


func _init() -> void:
	top_level = true


func run(from: Vector3, to: Vector3) -> void:
	var flat := to - from
	flat.y = 0.0
	var length := minf(flat.length(), MAX_LENGTH)
	var direction := flat.normalized() if flat.length() > 0.01 else Vector3.FORWARD
	var material := ToonMaterials.glow(COLOR, 3.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var count := maxi(int(length / SPACING), 2)
	for wave in WAVES:
		for i in count:
			var mote := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 0.13
			mesh.height = 0.26
			mote.mesh = mesh
			mote.material_override = material
			mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mote)
			var start := from + Vector3(0, HEIGHT, 0)
			mote.global_position = start
			mote.scale = Vector3.ZERO
			var end := start + direction * (float(i + 1) / count) * length
			var tween := create_tween()
			tween.tween_interval(wave * WAVE_GAP + i * (TRAVEL / count) * 0.35)
			tween.tween_property(mote, "scale", Vector3.ONE, 0.15)
			tween.parallel().tween_property(mote, "global_position", end, TRAVEL * (float(i + 1) / count))
			tween.tween_property(mote, "scale", Vector3.ZERO, 0.4)
	if flat.length() <= BEAM_RANGE:
		var beam := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.25
		cylinder.bottom_radius = 0.25
		cylinder.height = 8.0
		beam.mesh = cylinder
		var beam_material := ToonMaterials.glow(COLOR, 2.0)
		beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam_material.albedo_color.a = 0.35
		beam.material_override = beam_material
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(beam)
		beam.global_position = to + Vector3(0, 4.0, 0)
		var pulse := create_tween()
		pulse.tween_property(beam, "transparency", 1.0, LIFETIME).set_ease(Tween.EASE_IN)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)
