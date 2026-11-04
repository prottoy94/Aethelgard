class_name MapMenu
extends MenuScreen
## The map (FR-UI-03, owner request 2026-11-04): a page of the Tab menu, also opened with M. Shows the current area
## from above (a picture taken by an orthographic camera when the page opens) with Aurelia (arrow), her dragon,
## the people, Lantern Shrines, crafting stations, the exits to other areas and a gold star on the current objective.
## The area's map frame comes from RegionData (map_center, map_size).

const MAP_SIZE := 620.0          ## px on screen
const PICTURE_SIZE := 1024       ## px of the top-down picture
const CAMERA_HEIGHT := 90.0      ## m above the ground
const PAPER := Color(1.0, 0.95, 0.85)   ## tint over the picture, so it reads as a map
const PLAYER_COLOR := Color("8a4fb0")
const SHRINE_COLOR := Color("ffb340")
const NPC_COLOR := Color("3b6fb0")
const EXIT_COLOR := Color("2f7a3a")
const STATION_COLOR := Color("8a5a2b")
const GOAL_COLOR := Color("ffd23f")

var region: RegionData
var goal: Dictionary = {}
var picture: Texture2D
var _view: Control
var _region_label: Label
var _goal_label: Label
var _time := 0.0


func title() -> String:
	return "Map"


func open() -> void:
	region = SceneLoader.REGIONS.find(SceneLoader.current_region)
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	goal = Navigator.objective(get_tree(), player.global_position) if player else {}
	super()
	_take_picture()


func _process(delta: float) -> void:
	if is_open():
		_time += delta
		_view.queue_redraw()


func _menu_input(event: InputEvent) -> bool:
	if event.is_action_pressed("map"):
		close()
		return true
	return false


func refresh() -> void:
	if _region_label == null:
		return
	_region_label.text = region.display_name if region else "Unknown place"
	var lines: Array[String] = []
	if String(goal.get("quest", "")) != "":
		lines.append(String(goal["quest"]))
	lines.append(Navigator.describe(goal))
	if goal.get("position") == null and String(goal.get("quest", "")) != "" and String(goal.get("via", "")) == "":
		lines.append("(no single place to show: look around)")
	_goal_label.text = "\n".join(lines)


## World position → point on the map, or null when the area has no map frame.
func to_map(world: Vector3) -> Vector2:
	var half := region.map_size * 0.5
	return Vector2((world.x - region.map_center.x + half) / region.map_size,
			(world.z - region.map_center.y + half) / region.map_size) * MAP_SIZE


func _take_picture() -> void:
	picture = null
	if region == null or region.map_size <= 0.0 or DisplayServer.get_name() == "headless":
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(PICTURE_SIZE, PICTURE_SIZE)
	viewport.world_3d = get_viewport().world_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = region.map_size
	camera.far = CAMERA_HEIGHT + 60.0
	camera.position = Vector3(region.map_center.x, CAMERA_HEIGHT, region.map_center.y)
	camera.rotation_degrees = Vector3(-90, 0, 0)  # straight down, north (−Z) at the top
	var environment := Environment.new()  # no fog or sky haze from up here
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.35, 0.5, 0.3)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.85, 0.85, 0.8)
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	camera.environment = environment
	camera.current = true
	viewport.add_child(camera)
	add_child(viewport)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	if image and not image.is_empty():
		picture = ImageTexture.create_from_image(image)
	_view.queue_redraw()


func _draw_map() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(MAP_SIZE, MAP_SIZE))
	_view.draw_rect(rect, PARCHMENT.darkened(0.12))
	if region == null or region.map_size <= 0.0:
		_view.draw_string(_view.get_theme_default_font(), Vector2(20, 40), "No map of this place.", HORIZONTAL_ALIGNMENT_LEFT,
				-1, 22, INK)
		return
	if picture:
		_view.draw_texture_rect(picture, rect, false, PAPER)
	else:
		_view.draw_string(_view.get_theme_default_font(), Vector2(20, 40), "Drawing the map...", HORIZONTAL_ALIGNMENT_LEFT,
				-1, 20, INK)
	var font := _view.get_theme_default_font()
	for node in get_tree().get_nodes_in_group(&"region_exit"):
		var exit := node as RegionExit
		var to := SceneLoader.REGIONS.find(exit.target_region)
		_marker(font, to_map(exit.global_position), EXIT_COLOR, "▼ To %s" % (to.display_name if to else "?"), 9.0)
	for node in get_tree().get_nodes_in_group(&"rest_point"):
		_marker(font, to_map((node as Node3D).global_position), SHRINE_COLOR, "Lantern Shrine", 8.0)
	for node in get_tree().get_nodes_in_group(&"crafting_station"):
		var station := node as CraftingStation
		if station.station == RecipeData.Station.WORKBENCH:
			_marker(font, to_map(station.global_position), STATION_COLOR, "Workbench", 6.0)
	for node in get_tree().get_nodes_in_group(&"npc"):
		var npc := node as Npc
		_marker(font, to_map(npc.global_position), NPC_COLOR, npc.display_name, 7.0)
	var dragon := get_tree().get_first_node_in_group(&"dragon") as Dragon
	if dragon:
		_view.draw_circle(to_map(dragon.global_position), 6.0, dragon.species.body_color if dragon.species else Color.WHITE)
		_view.draw_arc(to_map(dragon.global_position), 6.0, 0, TAU, 16, INK, 1.5)
	if goal.get("position") is Vector3:
		_star(to_map(goal["position"]), 13.0 + 2.5 * sin(_time * 4.0))
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		var at := to_map(player.global_position)
		var forward := Vector2(player.facing_direction().x, player.facing_direction().z)
		var side := Vector2(-forward.y, forward.x)
		var arrow := PackedVector2Array([at + forward * 14.0, at - forward * 8.0 + side * 8.0, at - forward * 3.0,
				at - forward * 8.0 - side * 8.0])
		_view.draw_colored_polygon(arrow, PLAYER_COLOR)
		_view.draw_polyline(arrow + PackedVector2Array([arrow[0]]), Color.WHITE, 2.0)
	_view.draw_rect(rect, GOLD, false, 3.0)
	_view.draw_string(font, Vector2(MAP_SIZE - 34, 26), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)


func _marker(font: Font, at: Vector2, color: Color, label: String, radius: float) -> void:
	_view.draw_circle(at, radius, color)
	_view.draw_arc(at, radius, 0, TAU, 20, Color.WHITE, 1.5)
	var baseline := at + Vector2(radius + 4, 5)
	_view.draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, PARCHMENT)
	_view.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)


func _star(at: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var a := -PI * 0.5 + i * PI / 5.0
		points.append(at + Vector2(cos(a), sin(a)) * r)
	_view.draw_colored_polygon(points, GOAL_COLOR)
	_view.draw_polyline(points + PackedVector2Array([points[0]]), INK, 2.0)


func _build_body() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 26)
	body.add_child(columns)
	_view = Control.new()
	_view.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	_view.clip_contents = true
	_view.draw.connect(_draw_map)
	columns.add_child(_view)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 14)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(side)
	_region_label = make_label("", 30, INK)
	side.add_child(_region_label)
	side.add_child(make_label("Next", 20, GOLD.darkened(0.2)))
	_goal_label = make_label("", 19, INK)
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_goal_label)
	var legend := make_label("★  your objective\n▲  Aurelia\n●  Lantern Shrine (rest, save, craft)\n●  people\n"
			+ "●  way to another area\n\nIn play: N shows the way.   M: map", 17, INK.lightened(0.15))
	side.add_child(legend)
