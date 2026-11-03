class_name PortraitView
extends Control
## Draws a placeholder bust portrait (DIALOGUE_DESIGN.md §6): a coloured figure with a simple face for the
## expression, and the expression's name underneath, until real portraits exist. Lumen is drawn as a butterfly.

const SIZE := Vector2(220, 270)
const INK := Color("3b2a1e")
const GOLD := Color("b8862e")
const EYE := Color("2a2230")
const BLUSH := Color(1.0, 0.55, 0.6, 0.55)

var style: PortraitStyle
var mood := "neutral"
var active := true  ## the speaker; the listener is dimmed


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_portrait(style_: PortraitStyle, mood_: String, active_: bool) -> void:
	style = style_
	mood = mood_ if mood_ != "" else "neutral"
	active = active_
	visible = style != null
	modulate = Color.WHITE if active else Color(0.62, 0.6, 0.66)
	queue_redraw()


func clear() -> void:
	style = null
	visible = false


func _draw() -> void:
	if style == null:
		return
	var panel := StyleBoxFlat.new()
	panel.bg_color = style.background
	panel.border_color = GOLD
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(12)
	draw_style_box(panel, Rect2(Vector2.ZERO, SIZE))
	if style.look == PortraitStyle.Look.BUTTERFLY:
		_draw_butterfly(Vector2(SIZE.x * 0.5, SIZE.y * 0.45), 1.6)
	else:
		_draw_figure()
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, SIZE.y - 10), mood, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 14, INK.lightened(0.35))


func _draw_figure() -> void:
	var child := style.look == PortraitStyle.Look.CHILD
	var head_r := 50.0 if child else 56.0
	var head := Vector2(SIZE.x * 0.5, 118.0 if child else 108.0)
	# shoulders and neck
	var shoulders := PackedVector2Array([Vector2(26, SIZE.y - 24), Vector2(58, head.y + head_r + 12),
			Vector2(SIZE.x - 58, head.y + head_r + 12), Vector2(SIZE.x - 26, SIZE.y - 24)])
	draw_colored_polygon(shoulders, style.outfit)
	draw_rect(Rect2(head.x - 14, head.y + head_r - 14, 28, 30), style.skin.darkened(0.08))
	# hair behind the head
	match style.look:
		PortraitStyle.Look.ELF:
			draw_rect(Rect2(head.x - head_r - 6, head.y - 10, head_r * 2 + 12, 110), style.hair)
		PortraitStyle.Look.CHILD:
			draw_circle(head + Vector2(-head_r - 10, 10), 20, style.hair)
			draw_circle(head + Vector2(head_r + 10, 10), 20, style.hair)
	# ears (pointed for elves), head
	if style.look == PortraitStyle.Look.ELF:
		for side: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([head + Vector2(side * (head_r - 8), -6),
					head + Vector2(side * (head_r + 34), -30), head + Vector2(side * (head_r - 4), 18)]), style.skin)
	draw_circle(head, head_r, style.skin)
	# hair on top
	match style.look:
		PortraitStyle.Look.ELDER:
			for side: float in [-1.0, 1.0]:
				draw_circle(head + Vector2(side * head_r * 0.8, -4), 18, style.hair)
			draw_colored_polygon(PackedVector2Array([head + Vector2(-36, 26), head + Vector2(36, 26),
					head + Vector2(0, 104)]), style.hair)  # beard
		_:
			draw_arc(head, head_r, PI * 1.02, TAU * 0.99, 24, style.hair, head_r * 0.62)
	_draw_face(head, head_r)


func _draw_face(head: Vector2, r: float) -> void:
	var eye_y := head.y - r * 0.02
	var eye_dx := r * 0.36
	var mouth := head + Vector2(0, r * 0.45)
	if style.look == PortraitStyle.Look.ELDER:
		mouth.y -= 4.0
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(head.x + side * eye_dx, eye_y)
		match mood:
			"happy", "proud", "excited":
				draw_arc(eye + Vector2(0, 4), 7, PI * 1.1, PI * 1.9, 8, EYE, 3.0)
			"wink":
				if side < 0.0:
					draw_circle(eye, 5, EYE)
				else:
					draw_arc(eye + Vector2(0, 4), 7, PI * 1.1, PI * 1.9, 8, EYE, 3.0)
			"surprised", "scared":
				draw_circle(eye, 7, EYE)
			_:
				draw_circle(eye, 5, EYE)
		var brow := eye + Vector2(0, -15)
		var inner := brow + Vector2(-side * 9, 0)
		var outer := brow + Vector2(side * 9, 0)
		match mood:
			"worried", "sad", "scared":
				draw_line(outer + Vector2(0, 2), inner + Vector2(0, -4), EYE, 2.5)
			"angry", "determined":
				draw_line(outer + Vector2(0, -4), inner + Vector2(0, 3), EYE, 3.0)
			"thinking":
				draw_line(outer, inner + Vector2(0, -side * 3), EYE, 2.5)
	match mood:
		"happy", "proud", "excited", "wink":
			draw_arc(mouth + Vector2(0, -6), 12, PI * 0.15, PI * 0.85, 12, EYE, 3.0)
		"sad", "worried", "scared":
			draw_arc(mouth + Vector2(0, 8), 10, PI * 1.2, PI * 1.8, 12, EYE, 3.0)
		"surprised":
			draw_circle(mouth, 6, EYE)
		"embarrassed":
			draw_line(mouth + Vector2(-8, 0), mouth + Vector2(8, 0), EYE, 2.5)
			for side: float in [-1.0, 1.0]:
				draw_circle(Vector2(head.x + side * r * 0.55, head.y + r * 0.25), 10, BLUSH)
		"angry", "determined":
			draw_line(mouth + Vector2(-10, 0), mouth + Vector2(10, 0), EYE, 3.0)
		_:
			draw_line(mouth + Vector2(-7, 0), mouth + Vector2(7, 0), EYE, 2.5)


func _draw_butterfly(center: Vector2, scale_: float) -> void:
	var wing := Color(0.45, 0.75, 1.0)
	for side: float in [-1.0, 1.0]:
		_draw_ellipse(center + Vector2(side * 28, -18) * scale_, Vector2(30, 24) * scale_, wing)
		_draw_ellipse(center + Vector2(side * 22, 20) * scale_, Vector2(20, 16) * scale_, wing.lightened(0.25))
	draw_line(center + Vector2(0, -26) * scale_, center + Vector2(0, 30) * scale_, Color("e8f4ff"), 5.0 * scale_)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
