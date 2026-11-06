class_name VillageExtras
extends RefCounted
## More of Elderroot Village (owner request 2026-11-05): a market square to the east, the mill with its wheat field to
## the west, Bram's forge (with a workbench) to the south-east, four more cottages to the south, lamp posts, paths,
## three more villagers (Bram, Wenna, Pell: draft), a notice board, and a pine border with invisible walls.
## Called by elderroot_village.gd before its runtime starts.

const VILLAGE_MIN := Vector2(-40, -26)
const VILLAGE_MAX := Vector2(40, 34)
const FOLK: DialogueResource = preload("res://dialogue/npcs/elderroot_folk.dialogue")
const GATHER := "res://data/items/gather/%s.tres"
const DIRT := Color(0.62, 0.5, 0.36)
const FORGE_GLOW := Color(1.0, 0.45, 0.15)
const WHEAT := Color(0.88, 0.76, 0.38)
## Places kept clear of the village's random trees: [centre, radius].
const RESERVED: Array = [
	[Vector3(22, 0, -4), 8.0], [Vector3(-24, 0, -2), 11.0], [Vector3(18, 0, 16), 6.0], [Vector3(-2, 0, 24), 9.0],
	[Vector3(-24, 0, 22), 6.0],
]
const PLACES: Array = [
	[&"market_square", "Market Square", Vector3(22, 0, -4), 7.0],
	[&"elderroot_mill", "Elderroot Mill", Vector3(-24, 0, -6), 8.0],
	[&"brams_forge", "Bram's Forge", Vector3(18, 0, 16), 6.0],
	[&"village_well", "Village Well", Vector3(0, 0, 0), 5.0],
]

var level: Node3D
var rng := RandomNumberGenerator.new()
var mill_hub: Node3D


static func is_reserved(p: Vector3) -> bool:
	for spot: Array in RESERVED:
		var at: Vector3 = spot[0]
		if Vector2(p.x - at.x, p.z - at.z).length() < float(spot[1]):
			return true
	return false


func build(level_: Node3D) -> void:
	level = level_
	rng.seed = 711
	for place: Array in PLACES:
		var landmark := Landmark.new()
		landmark.place_id = place[0]
		landmark.display_name = place[1]
		landmark.radius = place[3]
		landmark.position = place[2]
		level.add_child(landmark)
	_paths()
	_market(Vector3(22, 0, -4))
	_mill(Vector3(-24, 0, -8))
	_forge(Vector3(18, 0, 16))
	_south_lane()
	for at: Vector3 in [Vector3(3, 0, -14), Vector3(-3.5, 0, -7), Vector3(8, 0, 8.5), Vector3(-8.5, 0, 9),
			Vector3(15, 0, -1.5), Vector3(-15, 0, -2), Vector3(2.5, 0, 17)]:
		PropKit.lamp_post(level, at)
	var notice := LoreStone.new()
	notice.cue = "village_notice"
	notice.look = LoreStone.Look.BOARD
	notice.position = Vector3(-4.5, 0, -10.5)
	level.add_child(notice)
	_folk(&"bram", "Bram", Vector3(15.5, 0, 13.5), Vector3(18, 0, 16))
	_folk(&"wenna", "Wenna", Vector3(-19.5, 0, -4.0), Vector3(0, 0, 0))
	_folk(&"pell", "Pell", Vector3(5, 0, 21), Vector3(0, 0, 0))
	_border()


func _paths() -> void:
	for strip: Array in [[Vector3(14, 0, -2), Vector3(18, 0.02, 2.4), 0.15], [Vector3(-14, 0, -3), Vector3(18, 0.02, 2.4), -0.1],
			[Vector3(10, 0, 9), Vector3(16, 0.02, 2.2), -0.7], [Vector3(0, 0, 14), Vector3(2.4, 0.02, 14), 0.0]]:
		var mi := PropKit.mesh(level, PropKit.box_mesh(strip[1]), DIRT, strip[0] + Vector3(0, 0.012, 0), 0.0, 0.05)
		mi.rotation.y = strip[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _market(center: Vector3) -> void:
	var cloths := [Color(0.75, 0.25, 0.22), Color(0.25, 0.45, 0.7), Color(0.85, 0.65, 0.2)]
	for i in 3:
		var a := -PI * 0.5 + (i - 1) * 0.9
		PropKit.stall(level, center + Vector3(cos(a), 0, sin(a)) * 5.0, -a - PI * 0.5, cloths[i])
	for at: Vector3 in [Vector3(4, 0, 3), Vector3(4.8, 0, 2.2), Vector3(-3.5, 0, 3.5)]:
		PropKit.crate(level, center + at, rng)
	PropKit.barrel(level, center + Vector3(-4.5, 0, 2.5))
	PropKit.barrel(level, center + Vector3(5.6, 0, 3.4))
	for i in 5:  # baskets of fruit on the counters (colour dots)
		PropKit.mesh(level, PropKit.sphere_mesh(0.12), [Color(0.9, 0.3, 0.2), Color(0.95, 0.75, 0.2), Color(0.5, 0.75, 0.3)][i % 3],
				center + Vector3(-1.0 + i * 0.5, 1.02, -5.0), 0.0)


func _mill(center: Vector3) -> void:
	mill_hub = PropKit.windmill(level, center, PI * 0.15)
	var spin := level.get_tree().create_tween().set_loops()  # the sails turn slowly
	spin.bind_node(mill_hub)
	spin.tween_property(mill_hub, "rotation:z", TAU, 12.0).as_relative()
	var a := center + Vector3(-8, 0, 4)
	var b := center + Vector3(4, 0, 14)
	PropKit.fence(level, Vector3(a.x, 0, a.z), Vector3(b.x, 0, a.z))
	PropKit.fence(level, Vector3(a.x, 0, a.z), Vector3(a.x, 0, b.z))
	PropKit.fence(level, Vector3(a.x, 0, b.z), Vector3(b.x - 3.0, 0, b.z))
	PropKit.fence(level, Vector3(b.x, 0, a.z), Vector3(b.x, 0, b.z))
	for row in 5:
		for k in 8:
			PropKit.mesh(level, PropKit.cylinder_mesh(0.18, 0.12, rng.randf_range(0.7, 0.95), 6), WHEAT,
					Vector3(a.x + 1.3 + k * 1.35, 0.4, a.z + 1.4 + row * 1.8), 0.0)
	var board := LoreStone.new()
	board.cue = "mill_sign"
	board.look = LoreStone.Look.BOARD
	board.position = center + Vector3(3.2, 0, 3.0)
	board.rotation.y = -0.4
	level.add_child(board)
	for at: Vector3 in [Vector3(6, 0, 6), Vector3(-10, 0, -1)]:
		var flowers := GatherNode.new()
		flowers.persist_id = StringName("village_extra_sunpetal_%d" % roundi(at.x))
		flowers.data = load(GATHER % "sunpetal_patch")
		flowers.position = center + at
		level.add_child(flowers)


func _forge(center: Vector3) -> void:
	var shed := PropKit.solid(level, center, "stone")
	shed.rotation.y = -0.5
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		PropKit.add_box_shape(shed, Vector3(0.25, 3.0, 0.25), Vector3(corner.x * 2.2, 1.5, corner.y * 1.8))
		PropKit.mesh(shed, PropKit.box_mesh(Vector3(0.22, 3.0, 0.22)), PropKit.WOOD.darkened(0.2), Vector3(corner.x * 2.2, 1.5, corner.y * 1.8), 0.01)
	PropKit.mesh(shed, PropKit.box_mesh(Vector3(5.2, 0.2, 4.4)), PropKit.ROOF.darkened(0.2), Vector3(0, 3.1, 0), 0.015)
	PropKit.add_box_shape(shed, Vector3(1.6, 1.2, 1.2), Vector3(-1.2, 0.6, -1.1))
	PropKit.mesh(shed, PropKit.box_mesh(Vector3(1.6, 1.2, 1.2)), Color(0.45, 0.42, 0.4), Vector3(-1.2, 0.6, -1.1))
	var coals := MeshInstance3D.new()
	coals.mesh = PropKit.box_mesh(Vector3(1.0, 0.1, 0.7))
	coals.material_override = ToonMaterials.glow(FORGE_GLOW, 3.0)
	coals.position = Vector3(-1.2, 1.22, -1.1)
	shed.add_child(coals)
	PropKit.mesh(shed, PropKit.cylinder_mesh(0.3, 0.35, 3.0, 8), Color(0.45, 0.42, 0.4), Vector3(-1.2, 2.7, -1.4))
	var glow := OmniLight3D.new()
	glow.light_color = FORGE_GLOW
	glow.light_energy = 1.4
	glow.omni_range = 5.5
	glow.position = Vector3(-1.2, 1.6, -0.6)
	shed.add_child(glow)
	PropKit.add_box_shape(shed, Vector3(0.8, 0.8, 0.4), Vector3(1.0, 0.4, 0.3))
	PropKit.mesh(shed, PropKit.box_mesh(Vector3(0.35, 0.55, 0.3)), Color(0.3, 0.3, 0.32), Vector3(1.0, 0.28, 0.3))
	PropKit.mesh(shed, PropKit.box_mesh(Vector3(0.8, 0.2, 0.35)), Color(0.32, 0.32, 0.35), Vector3(1.0, 0.65, 0.3))
	var bench := CraftingStation.new()
	bench.station = RecipeData.Station.WORKBENCH
	bench.position = center + Vector3(3.6, 0, 1.0)
	bench.rotation.y = -0.5
	level.add_child(bench)
	PropKit.barrel(level, center + Vector3(-3.4, 0, 1.5))
	PropKit.crate(level, center + Vector3(-3.0, 0, 2.6), rng)


func _south_lane() -> void:
	for spec: Array in [[Vector3(-8, 0, 25), Vector3(4.8, 3.0, 4.2), PI], [Vector3(6, 0, 27), Vector3(4.4, 2.8, 4.0), PI + 0.2],
			[Vector3(-24, 0, 22), Vector3(5.0, 3.1, 4.4), PI * 0.5], [Vector3(-16, 0, 29), Vector3(4.2, 2.8, 3.8), PI - 0.3]]:
		PropKit.cottage(level, spec[0], spec[1], spec[2], [PropKit.ROOF, Color(0.35, 0.4, 0.55), Color(0.45, 0.5, 0.3)][rng.randi() % 3])
	for at: Vector3 in [Vector3(-4.5, 0, 21.5), Vector3(9, 0, 23.5)]:
		PropKit.fence(level, at, at + Vector3(4.0, 0, 0))
	for i in 6:  # flower boxes
		PropKit.mesh(level, PropKit.sphere_mesh(0.25), [Color(0.95, 0.5, 0.6), Color(0.95, 0.85, 0.3), Color(0.7, 0.55, 0.9)][i % 3],
				Vector3(-11 + i * 3.6, 0.2, 21.0 + (i % 2) * 0.8), 0.0)


func _folk(id: StringName, name_: String, at: Vector3, look_at: Vector3) -> void:
	var npc := Npc.villager(id, name_, load("res://data/npcs/%s.tres" % id), FOLK)
	npc.position = at
	level.add_child(npc)
	npc.face_point(look_at)


func _border() -> void:
	var sides: Array = [
		[Vector3(VILLAGE_MIN.x, 0, VILLAGE_MIN.y), Vector3(VILLAGE_MAX.x, 0, VILLAGE_MIN.y)],
		[Vector3(VILLAGE_MIN.x, 0, VILLAGE_MAX.y), Vector3(VILLAGE_MAX.x, 0, VILLAGE_MAX.y)],
		[Vector3(VILLAGE_MIN.x, 0, VILLAGE_MIN.y), Vector3(VILLAGE_MIN.x, 0, VILLAGE_MAX.y)],
		[Vector3(VILLAGE_MAX.x, 0, VILLAGE_MIN.y), Vector3(VILLAGE_MAX.x, 0, VILLAGE_MAX.y)],
	]
	for side: Array in sides:
		var from: Vector3 = side[0]
		var to: Vector3 = side[1]
		var count := int(from.distance_to(to) / 6.5)
		for i in count + 1:
			var at := from.lerp(to, float(i) / count)
			if absf(at.x) < 4.0 and at.z < 0.0:
				continue  # the road north to the meadow
			PropKit.pine(level, at + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), rng, rng.randf_range(1.1, 1.6))
	PropKit.edge(level, VILLAGE_MIN, VILLAGE_MAX)
