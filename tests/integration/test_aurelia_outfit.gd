extends GutTest
## Aurelia's dressed stand-in (owner request 2026-11-07): her own slim body and clothes as skinned meshes on the
## mannequin's skeleton (the mannequin mesh is hidden), and spring-bone physics for hair, braid, cape, skirts and satchel.

const ANIM_SET := preload("res://data/animations/humanoid_default.tres")


func _dressed() -> HumanoidVisual:
	var visual := HumanoidVisual.new()
	visual.model_scene = ANIM_SET.library_scene
	visual.anim_set = ANIM_SET
	add_child_autofree(visual)
	AureliaOutfit.dress(visual)
	return visual


func test_builder_normalises_weights() -> void:
	var builder := SkinnedMeshBuilder.new()
	builder.add_vertex(Vector3.ZERO, Vector3.UP, {1: 2.0, 2: 1.0, 3: 1.0, 4: 0.5, 5: 0.25})
	builder.add_vertex(Vector3.ONE, Vector3.UP, {1: 1.0})
	builder.add_vertex(Vector3.RIGHT, Vector3.UP, {1: 1.0})
	builder._indices.append_array([0, 1, 2])
	var data := builder.commit().surface_get_arrays(0)
	var weights: PackedFloat32Array = data[Mesh.ARRAY_WEIGHTS]
	var bones: PackedInt32Array = data[Mesh.ARRAY_BONES]
	assert_almost_eq(weights[0] + weights[1] + weights[2] + weights[3], 1.0, 0.001, "weights add up to 1")
	assert_eq(bones[0], 1, "the strongest bone comes first")
	assert_false(5 in [bones[0], bones[1], bones[2], bones[3]], "only the 4 strongest bones are kept")


func test_builder_vertex_colours() -> void:
	var builder := SkinnedMeshBuilder.new()
	builder.vertex_colors = true
	builder.color = Color.RED
	builder.add_vertex(Vector3.ZERO, Vector3.UP, {1: 1.0})
	builder.add_vertex(Vector3.ONE, Vector3.UP, {1: 1.0}, Color.BLUE)
	builder.add_vertex(Vector3.RIGHT, Vector3.UP, {1: 1.0})
	builder._indices.append_array([0, 1, 2])
	var colors: PackedColorArray = builder.commit().surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_eq(colors[0], Color.RED, "a vertex without its own colour gets the builder's")
	assert_eq(colors[1], Color.BLUE, "a vertex keeps its own colour")
	var plain := SkinnedMeshBuilder.new()
	for p: Vector3 in [Vector3.ZERO, Vector3.ONE, Vector3.RIGHT]:
		plain.add_vertex(p, Vector3.UP, {1: 1.0})
	plain._indices.append_array([0, 1, 2])
	var none: Variant = plain.commit().surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_true(none == null or (none as PackedColorArray).is_empty(), "no colours unless asked for")


func test_face_is_painted_with_soft_gradients() -> void:
	var visual := _dressed()
	var paint := visual.skeleton.get_node_or_null("Aurelia_paint") as MeshInstance3D
	assert_not_null(paint, "eyes, brows, blush, nose and mouth are one painted mesh")
	var material := paint.material_override as ShaderMaterial
	assert_eq(material.shader, ToonMaterials.SOFT, "painted with the soft skin shader, so it shades like her skin")
	assert_true(material.get_shader_parameter(&"use_vertex_color"), "its colours come from the vertices")
	assert_gt((paint.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray).size(), 1000,
			"gradients need many painted vertices")


func test_mannequin_hidden_and_body_built() -> void:
	var visual := _dressed()
	var shown := 0
	for mi: MeshInstance3D in visual.skeleton.find_children("*", "MeshInstance3D", false, false):
		if mi.visible:
			shown += 1
			assert_not_null(mi.skin, "%s is skinned to the skeleton" % mi.name)
		else:
			assert_false(mi.name.begins_with("Aurelia_"), "only the mannequin is hidden")
	assert_gt(shown, 8, "her body and clothes are built in several colours")


func test_hair_and_clothes_have_physics() -> void:
	var visual := _dressed()
	var sims := visual.skeleton.find_children("*", "SpringBoneSimulator3D", false, false)
	assert_eq(sims.size(), 3, "hair, cape and skirt simulators")
	var chains := 0
	for sim: SpringBoneSimulator3D in sims:
		chains += sim.setting_count
		assert_gt(sim.get_child_count(), 0, "%s has bodies to collide with" % sim.name)
	assert_eq(chains, AureliaOutfit.HAIR_ANGLES.size() + 2 + 1 + AureliaOutfit.CAPE_COLUMNS.size()
			+ AureliaOutfit.TUNIC_CHAINS + AureliaOutfit.SKIRT_CHAINS + 1)
	assert_gt(visual.skeleton.find_bone(&"Cape2_4"), 0, "chain bones are added to the skeleton")


func test_cape_swings_when_she_moves() -> void:
	var visual := _dressed()
	var sk := visual.skeleton
	var tip := sk.find_bone(&"Cape2_4")
	await wait_physics_frames(5)
	var before := sk.get_bone_global_pose(tip).origin
	for i in 20:
		visual.global_position += Vector3(0, 0, 0.15)  # running
		await wait_process_frames(1)
	var after := sk.get_bone_global_pose(tip).origin
	assert_gt(before.distance_to(after), 0.01, "the cape's hem trails behind as she moves")
