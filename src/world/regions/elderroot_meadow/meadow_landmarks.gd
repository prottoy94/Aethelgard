class_name MeadowLandmarks
extends RefCounted
## More of Elderroot Meadow to explore (owner request 2026-11-05). Builds places around the original meadow, each with
## something to find, and names the old spots so they show on the map once found:
## - Whispering Grove (west): a ring of trees around glowing mushrooms, a carved stone, a chest, Moonbloom.
## - Old Watchtower (east): a broken round tower with a chest inside; Ember Wisps nearby.
## - Silverbrook: a stream from the waterfall across the north path (with a footbridge) to the west.
## - Mistfall Basin (under the waterfall): a pool, and spirit steps (Lantern Glow) up to a hidden ledge with a chest.
## - Emberbound Camp (north-west): tents, a campfire, orders on a board, a chest, Emberbound Scouts.
## - Hollin Farm (south-east): a fenced wheat field, a barn, a scarecrow, Sunpetal.
## - Moonring Stones (south-west): a stone circle; lighting its brazier (Light) opens a hidden chest.
## A pine border and invisible walls close the meadow off. Called by the meadow (test_level_3d.gd) before its runtime starts.

const MEADOW_MIN := Vector2(-72, -70)        ## x, z of the walkable area's corners
const MEADOW_MAX := Vector2(72, 42)
const SCOUT := preload("res://src/actors/enemies/emberbound/emberbound_scout.tscn")
const WISP := preload("res://src/actors/enemies/ember_wisp/ember_wisp.tscn")
const THORNLING := preload("res://src/actors/enemies/thornling/thornling.tscn")
const GATHER := "res://data/items/gather/%s.tres"
const ITEMS := "res://data/items/%s.tres"
const MUSHROOM_GLOW := Color(0.55, 0.9, 1.0)
const WHEAT := Color(0.88, 0.76, 0.38)
const BANNER := Color(0.62, 0.12, 0.1)

## [id, name, position, radius] of every named place (new and old).
const PLACES: Array = [
	[&"whispering_grove", "Whispering Grove", Vector3(-42, 0, -6), 10.0],
	[&"old_watchtower", "Old Watchtower", Vector3(44, 0, -10), 8.0],
	[&"silverbrook", "Silverbrook Bridge", Vector3(-3.4, 0, -30), 5.0],
	[&"mistfall_basin", "Mistfall Basin", Vector3(42, 0, -45), 7.0],
	[&"emberbound_camp", "Emberbound Camp", Vector3(-38, 0, -44), 9.0],
	[&"hollin_farm", "Hollin Farm", Vector3(34, 0, 28), 10.0],
	[&"moonring_stones", "Moonring Stones", Vector3(-36, 0, 26), 7.0],
	[&"shrine_ruins", "Old Shrine Ruins", Vector3(19, 0, 11), 7.0],
	[&"mirror_pond", "Mirror Pond", Vector3(7, 0, 2), 6.0],
	[&"overlook", "Overlook", Vector3(-11, 0, -13), 5.0],
	[&"scorched_clearing", "Scorched Clearing", Vector3(1.8, 0, -44), 11.0],
]

var level: Node3D
var noise: Texture2D
var rng := RandomNumberGenerator.new()
var spawn_enemy: Callable   ## level's (scene, position) spawner, so enemies respawn like the others


func build(level_: Node3D, noise_: Texture2D, spawner: Callable) -> void:
	level = level_
	noise = noise_
	spawn_enemy = spawner
	rng.seed = 2611
	for place: Array in PLACES:
		var landmark := Landmark.new()
		landmark.place_id = place[0]
		landmark.display_name = place[1]
		landmark.radius = place[3]
		landmark.position = place[2]
		level.add_child(landmark)
	_whispering_grove(Vector3(-42, 0, -6))
	_watchtower(Vector3(44, 0, -10))
	_silverbrook()
	_mistfall_basin(Vector3(42, 0, -45))
	_emberbound_camp(Vector3(-38, 0, -44))
	_hollin_farm(Vector3(34, 0, 28))
	_moonring(Vector3(-36, 0, 26))
	_border()


## True if `p` is inside one of the new places (the meadow's tree scatter keeps out of them).
static func is_reserved(p: Vector3) -> bool:
	for place: Array in PLACES.slice(0, 7):
		var at: Vector3 = place[2]
		if Vector2(p.x - at.x, p.z - at.z).length() < float(place[3]) + 3.0:
			return true
	return absf(p.z - stream_z(p.x)) < 3.0 and p.x < 44.0


## The stream's line (z for an x), from the waterfall pool west across the meadow.
static func stream_z(x: float) -> float:
	return -30.0 - 6.0 * sin((x - 4.0) * 0.06) + (0.0 if x < 20.0 else -(x - 20.0) * 0.6)


func _gather(kind: String, pos: Vector3) -> void:
	var node := GatherNode.new()
	node.persist_id = StringName("meadow_extra_%s_%d_%d" % [kind, roundi(pos.x), roundi(pos.z)])
	node.data = load(GATHER % kind)
	node.position = pos
	node.rotation.y = rng.randf() * TAU
	level.add_child(node)


func _chest(id: StringName, pos: Vector3, rot_y: float, items: Array[String], locked := false) -> Chest:
	var chest := Chest.new()
	chest.persist_id = id
	chest.locked = locked
	var contents: Array[ItemData] = []
	for item in items:
		contents.append(load(ITEMS % item))
	chest.contents = contents
	chest.position = pos
	chest.rotation.y = rot_y
	level.add_child(chest)
	return chest


func _lore(cue: String, pos: Vector3, rot_y: float, look := LoreStone.Look.STONE) -> void:
	var stone := LoreStone.new()
	stone.cue = cue
	stone.look = look
	stone.position = pos
	stone.rotation.y = rot_y
	level.add_child(stone)


func _whispering_grove(center: Vector3) -> void:
	for i in 14:  # a ring of old trees, open to the east
		var a := TAU * i / 14.0
		if absf(wrapf(a, -PI, PI)) < 0.45:
			continue
		PropKit.tree(level, center + Vector3(cos(a), 0, sin(a)) * rng.randf_range(10.0, 12.5), rng, rng.randf_range(1.1, 1.4))
	for i in 9:  # the mushroom ring
		var a := TAU * i / 9.0
		var at := center + Vector3(cos(a), 0, sin(a)) * 4.0
		PropKit.mesh(level, PropKit.cylinder_mesh(0.05, 0.07, 0.35, 6), Color(0.95, 0.93, 0.85), at + Vector3(0, 0.17, 0), 0.0)
		var cap := MeshInstance3D.new()
		cap.mesh = PropKit.sphere_mesh(0.2)
		cap.scale = Vector3(1, 0.5, 1)
		cap.material_override = ToonMaterials.glow(MUSHROOM_GLOW, 1.5)
		cap.position = at + Vector3(0, 0.38, 0)
		level.add_child(cap)
	var light := OmniLight3D.new()
	light.light_color = MUSHROOM_GLOW
	light.light_energy = 1.0
	light.omni_range = 7.0
	light.position = center + Vector3(0, 1.0, 0)
	level.add_child(light)
	_lore("grove_stone", center + Vector3(0, 0, -1.0), 0.0)
	_chest(&"grove_chest", center + Vector3(-5.5, 0, 2.5), PI * 0.4, ["healing_potion", "healing_potion", "moonbloom"])
	for offset: Vector3 in [Vector3(2.5, 0, 6), Vector3(-6, 0, -3), Vector3(6.5, 0, -4)]:
		_gather("moonbloom_patch", center + offset)
	_gather("elderwood_branch", center + Vector3(9, 0, 9))
	spawn_enemy.call(THORNLING, center + Vector3(14, 0, -6))
	spawn_enemy.call(THORNLING, center + Vector3(13, 0, 8))


func _watchtower(center: Vector3) -> void:
	var stone := Color(0.62, 0.6, 0.56)
	for i in 12:  # a broken round wall, open to the west
		var a := TAU * i / 12.0
		if absf(wrapf(a - PI, -PI, PI)) < 0.4:
			continue
		var height := 2.0 + 4.0 * absf(sin(i * 1.7))
		PropKit.block(level, Vector3(1.9, height, 0.8), stone.darkened(0.05 * (i % 3)),
				center + Vector3(cos(a), 0, sin(a)) * 4.2, -a + PI * 0.5)
	for i in 5:  # fallen stones outside
		PropKit.rock(level, center + Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(5, 9)), rng, 1.1)
	PropKit.block(level, Vector3(2.0, 0.5, 2.0), stone.darkened(0.15), center + Vector3(0, 0, 0.5))
	_chest(&"watchtower_chest", center + Vector3(0, 0.5, 0.5), PI * 0.5, ["lumen_crystal", "lumen_crystal", "elderwood", "elderwood"])
	_lore("tower_stone", center + Vector3(-2.2, 0, -2.0), PI * 0.6)
	_gather("iron_ore_vein", center + Vector3(-7, 0, -6))
	spawn_enemy.call(WISP, center + Vector3(-6, 0, -8))
	spawn_enemy.call(WISP, center + Vector3(5, 0, 9))


func _silverbrook() -> void:
	var points := PackedVector3Array()
	var x := 40.0
	while x > -66.0:
		points.append(Vector3(x, 0, stream_z(x)))
		x -= 4.0
	PropKit.stream(level, points, 3.0, noise)
	PropKit.bridge(level, Vector3(sin(-30.0 * 0.08) * 5.0, 0, stream_z(-3.4)), 0.0, 5.5)
	for sx: float in [-22.0, 18.0]:  # stepping stones
		for k in 3:
			PropKit.block(level, Vector3(0.7, 0.18, 0.7), PropKit.STONE, Vector3(sx + rng.randf_range(-0.3, 0.3), 0, stream_z(sx) - 1.0 + k))
	for i in 10:  # reeds and pebbles along the banks
		var bx := rng.randf_range(-60, 36)
		var side := 1.0 if i % 2 == 0 else -1.0
		PropKit.mesh(level, PropKit.cylinder_mesh(0.03, 0.05, 0.9, 5), Color(0.4, 0.55, 0.3),
				Vector3(bx, 0.45, stream_z(bx) + side * 1.8), 0.0)
	_gather("moonbloom_patch", Vector3(-30, 0, stream_z(-30) + 2.6))


func _mistfall_basin(center: Vector3) -> void:
	var pool := MeshInstance3D.new()
	pool.mesh = PropKit.cylinder_mesh(4.5, 4.5, 0.05, 24)
	pool.material_override = ToonMaterials.shader_material(PropKit.WATER, {"noise_tex": noise})
	pool.position = center + Vector3(0, 0.03, -2.0)
	level.add_child(pool)
	for i in 10:  # mossy rocks around the pool
		var a := TAU * i / 10.0
		if a > 0.9 and a < 2.2:
			continue  # the way in (south-west)
		PropKit.rock(level, center + Vector3(cos(a), 0, sin(a) - 0.4) * 5.6, rng, 1.0)
	var ledge := Vector3(center.x + 5.2, 0, center.z - 2.0)
	var stone := Color(0.55, 0.55, 0.52)
	PropKit.block(level, Vector3(3.0, 1.4, 3.0), stone, ledge)
	var steps := HiddenSteps.new()
	steps.persist_id = &"mistfall_steps"
	steps.height = 1.4
	steps.position = Vector3(ledge.x, 0, ledge.z + 1.5 + steps.steps * steps.step_depth)
	level.add_child(steps)
	_chest(&"mistfall_chest", ledge + Vector3(0, 1.4, -0.4), 0.0, ["lumen_crystal", "lumen_crystal", "healing_potion", "stamina_tonic"])
	_lore("falls_stone", center + Vector3(-4.0, 0, 3.5), PI * 0.8)


func _emberbound_camp(center: Vector3) -> void:
	for t: Array in [[Vector3(-4, 0, -3), 0.4], [Vector3(4, 0, -3.5), -0.5], [Vector3(-1, 0, -6.5), 0.0]]:
		PropKit.tent(level, center + t[0], t[1], Color(0.55, 0.42, 0.36))
	PropKit.campfire(level, center + Vector3(0, 0, 1.0), rng)
	for c: Vector3 in [Vector3(5, 0, 2), Vector3(5.8, 0, 3.0), Vector3(-5.5, 0, 2.5)]:
		PropKit.crate(level, center + c, rng)
	PropKit.barrel(level, center + Vector3(-6.2, 0, 1.2))
	var pole := PropKit.solid(level, center + Vector3(2.5, 0, -0.5), "wood")
	PropKit.add_cylinder_shape(pole, 0.1, 4.0, Vector3(0, 2.0, 0))
	PropKit.mesh(pole, PropKit.cylinder_mesh(0.06, 0.08, 4.0, 6), PropKit.WOOD.darkened(0.3), Vector3(0, 2.0, 0), 0.0)
	PropKit.mesh(pole, PropKit.box_mesh(Vector3(1.0, 1.4, 0.04)), BANNER, Vector3(0.55, 3.2, 0), 0.0)
	_lore("camp_orders", center + Vector3(-2.5, 0, 4.0), PI, LoreStone.Look.BOARD)
	_chest(&"camp_chest", center + Vector3(-1, 0, -4.2), 0.0, ["ember_cinder", "ember_cinder", "iron_ore", "healing_potion"])
	spawn_enemy.call(SCOUT, center + Vector3(4, 0, 4))
	spawn_enemy.call(SCOUT, center + Vector3(-5, 0, -1))


func _hollin_farm(center: Vector3) -> void:
	var a := center + Vector3(-7, 0, -5)
	var b := center + Vector3(7, 0, 5)
	PropKit.fence(level, Vector3(a.x, 0, a.z), Vector3(b.x, 0, a.z))
	PropKit.fence(level, Vector3(b.x, 0, a.z), Vector3(b.x, 0, b.z))
	PropKit.fence(level, Vector3(a.x, 0, b.z), Vector3(center.x - 1.5, 0, b.z))  # a gap to walk in
	PropKit.fence(level, Vector3(center.x + 1.5, 0, b.z), Vector3(b.x, 0, b.z))
	PropKit.fence(level, Vector3(a.x, 0, a.z), Vector3(a.x, 0, b.z))
	for row in 6:  # wheat rows
		for k in 9:
			var at := Vector3(a.x + 1.5 + k * 1.4, 0, a.z + 1.2 + row * 1.5)
			if Vector2(at.x - center.x, at.z - center.z).length() < 1.6:
				continue
			PropKit.mesh(level, PropKit.cylinder_mesh(0.18, 0.12, rng.randf_range(0.7, 0.95), 6), WHEAT, at + Vector3(0, 0.4, 0), 0.0)
	var scarecrow := PropKit.solid(level, center, "wood")
	PropKit.add_cylinder_shape(scarecrow, 0.15, 1.8, Vector3(0, 0.9, 0))
	PropKit.mesh(scarecrow, PropKit.box_mesh(Vector3(0.1, 1.8, 0.1)), PropKit.WOOD, Vector3(0, 0.9, 0), 0.0)
	PropKit.mesh(scarecrow, PropKit.box_mesh(Vector3(1.3, 0.1, 0.1)), PropKit.WOOD, Vector3(0, 1.4, 0), 0.0)
	PropKit.mesh(scarecrow, PropKit.box_mesh(Vector3(0.6, 0.6, 0.3)), Color(0.45, 0.35, 0.6), Vector3(0, 1.3, 0), 0.01)
	PropKit.mesh(scarecrow, PropKit.sphere_mesh(0.2), Color(0.85, 0.75, 0.5), Vector3(0, 1.85, 0), 0.01)
	PropKit.mesh(scarecrow, PropKit.cylinder_mesh(0.05, 0.35, 0.3, 8), Color(0.6, 0.45, 0.25), Vector3(0, 2.1, 0), 0.0)
	PropKit.cottage(level, center + Vector3(12, 0, -2), Vector3(5.0, 3.2, 6.0), -PI * 0.5, Color(0.6, 0.2, 0.16))
	PropKit.barrel(level, center + Vector3(9, 0, 2.5))
	PropKit.crate(level, center + Vector3(9.2, 0, 3.6), rng)
	_lore("farm_sign", center + Vector3(-2.5, 0, 6.5), PI, LoreStone.Look.BOARD)
	for offset: Vector3 in [Vector3(-10, 0, 4), Vector3(-10.5, 0, -3), Vector3(3, 0, 8.5)]:
		_gather("sunpetal_patch", center + offset)


func _moonring(center: Vector3) -> void:
	var stone := Color(0.58, 0.6, 0.62)
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		PropKit.block(level, Vector3(0.9, 2.4 + 0.5 * (i % 3), 0.6), stone.darkened(0.04 * (i % 2)),
				center + Vector3(cos(a), 0, sin(a)) * 5.5, -a + PI * 0.5)
	var brazier := LanternBrazier.new()
	brazier.persist_id = &"moonring_brazier"
	brazier.position = center
	level.add_child(brazier)
	var chest := _chest(&"moonring_chest", center + Vector3(0, 0, -3.2), 0.0, ["swift_quill_charm", "moonbloom"], true)
	var puzzle := Puzzle.new()
	puzzle.puzzle_id = &"moonring"
	puzzle.hint_cue = "lumen_hint_braziers"
	puzzle.position = center
	level.add_child(puzzle)
	puzzle.setup([brazier] as Array[Node], [chest] as Array[Node])
	_lore("circle_stone", center + Vector3(2.5, 0, 3.0), PI * 1.2)


## Pines along the edge and invisible walls just inside them (the meadow's border).
func _border() -> void:
	var spacing := 7.0
	var sides: Array = [
		[Vector3(MEADOW_MIN.x, 0, MEADOW_MIN.y), Vector3(MEADOW_MAX.x, 0, MEADOW_MIN.y)],
		[Vector3(MEADOW_MIN.x, 0, MEADOW_MAX.y), Vector3(MEADOW_MAX.x, 0, MEADOW_MAX.y)],
		[Vector3(MEADOW_MIN.x, 0, MEADOW_MIN.y), Vector3(MEADOW_MIN.x, 0, MEADOW_MAX.y)],
		[Vector3(MEADOW_MAX.x, 0, MEADOW_MIN.y), Vector3(MEADOW_MAX.x, 0, MEADOW_MAX.y)],
	]
	for side: Array in sides:
		var from: Vector3 = side[0]
		var to: Vector3 = side[1]
		var count := int(from.distance_to(to) / spacing)
		for i in count + 1:
			var at := from.lerp(to, float(i) / count)
			if absf(at.x) < 4.0 and at.z > 30.0:
				continue  # the road south to the village
			var out := Vector3(signf(at.x) if absf(at.x) >= MEADOW_MAX.x - 1.0 else 0.0, 0,
					signf(at.z) if absf(at.z - (MEADOW_MIN.y + MEADOW_MAX.y) * 0.5) > 50.0 else 0.0)
			PropKit.pine(level, at + out * rng.randf_range(1.0, 3.0) + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)),
					rng, rng.randf_range(1.2, 1.7))
	PropKit.edge(level, MEADOW_MIN, MEADOW_MAX)
