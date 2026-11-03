class_name TitleBackground
extends Control
## A painted Elderroot dusk for the title screen, drawn with shapes: a sky gradient with stars, layered hills, the
## World Tree's silhouette against the glow, and drifting fireflies.

const SKY_TOP := Color(0.08, 0.1, 0.26)
const SKY_GLOW := Color(0.98, 0.66, 0.46)
const HILLS: Array[Color] = [Color(0.27, 0.24, 0.38), Color(0.17, 0.2, 0.26), Color(0.09, 0.12, 0.14)]
const TREE := Color(0.06, 0.08, 0.1)
const FIREFLY := Color(1.0, 0.9, 0.55)
const STARS := 90
const FIREFLIES := 26

var _time := 0.0
var _stars: PackedVector2Array = []
var _flies: PackedVector3Array = []  ## x, y (0–1 of the screen) and a phase


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in STARS:
		_stars.append(Vector2(rng.randf(), rng.randf() * 0.45))
	for i in FIREFLIES:
		_flies.append(Vector3(rng.randf(), rng.randf_range(0.62, 0.95), rng.randf() * TAU))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.72), Vector2(0, h * 0.72)]),
			PackedColorArray([SKY_TOP, SKY_TOP, SKY_GLOW, SKY_GLOW]))
	for star in _stars:
		var twinkle := 0.5 + 0.5 * sin(_time * 1.7 + star.x * 40.0)
		draw_circle(Vector2(star.x * w, star.y * h), 1.2 + twinkle, Color(1, 1, 1, 0.25 + 0.5 * twinkle * (1.0 - star.y * 1.6)))
	draw_circle(Vector2(w * 0.68, h * 0.66), h * 0.12, Color(1.0, 0.8, 0.55, 0.35))  # glow behind the tree
	for i in HILLS.size():
		_draw_hill(h * (0.62 + i * 0.09), 40.0 - i * 8.0, 2.0 + i, HILLS[i])
		if i == 1:
			_draw_world_tree(Vector2(w * 0.68, h * 0.66), h)
	for fly in _flies:
		var p := Vector2(fly.x * w + sin(_time * 0.5 + fly.z) * 30.0, fly.y * h + cos(_time * 0.7 + fly.z) * 14.0)
		var glow := 0.5 + 0.5 * sin(_time * 2.2 + fly.z * 3.0)
		draw_circle(p, 6.0, Color(FIREFLY, 0.12 * glow))
		draw_circle(p, 2.2, Color(FIREFLY, 0.85 * glow))


func _draw_hill(base_y: float, height: float, waves: float, color: Color) -> void:
	var points := PackedVector2Array([Vector2(0, size.y)])
	for i in 41:
		var x := size.x * i / 40.0
		points.append(Vector2(x, base_y - sin(i / 40.0 * PI * waves + base_y) * height))
	points.append(Vector2(size.x, size.y))
	draw_colored_polygon(points, color)


func _draw_world_tree(root: Vector2, h: float) -> void:
	var trunk_w := h * 0.035
	draw_colored_polygon(PackedVector2Array([root + Vector2(-trunk_w * 1.8, 0), root + Vector2(-trunk_w * 0.6, -h * 0.22),
			root + Vector2(trunk_w * 0.6, -h * 0.22), root + Vector2(trunk_w * 1.8, 0)]), TREE)
	for blob: Vector3 in [Vector3(0, -0.3, 0.13), Vector3(-0.11, -0.26, 0.09), Vector3(0.11, -0.25, 0.1),
			Vector3(-0.05, -0.38, 0.09), Vector3(0.07, -0.37, 0.08)]:
		draw_circle(root + Vector2(blob.x, blob.y) * h, blob.z * h, TREE)
