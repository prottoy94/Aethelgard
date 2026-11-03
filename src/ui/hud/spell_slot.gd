class_name SpellSlot
extends Control
## One HUD spell slot (FR-UI-01): element icon, key number, stamina cost and a radial cooldown sweep.
## Dims when the spell can't be cast (Exhausted / not enough stamina).

const SIZE := Vector2(76, 76)
const ICONS_PATH := "res://assets/art/placeholders/ui/element_icons.png"
const ICON_SIZE := 64
const BACKGROUND := Color(0.1, 0.08, 0.14, 0.82)
const COOLDOWN_SHADE := Color(0, 0, 0, 0.6)
const DIM := Color(1, 1, 1, 0.4)
const PIE_POINTS := 32

var spell: SpellData
var cooldown: Cooldown
var key_text := ""
var usable := true
var _icon: Texture2D


func _init() -> void:
	custom_minimum_size = SIZE


func setup(spell_: SpellData, cooldown_: Cooldown, key: String) -> void:
	spell = spell_
	cooldown = cooldown_
	key_text = key
	_icon = _element_icon(spell.element) if spell else null
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, SIZE)
	draw_rect(rect, BACKGROUND)
	var font := get_theme_default_font()
	if spell:
		var element_color := Elements.color(spell.element)
		var tint := Color.WHITE if usable else DIM
		if _icon:
			draw_texture_rect(_icon, rect.grow(-6), false, tint)
		else:
			draw_circle(SIZE / 2.0, 22.0, element_color * tint)
		if cooldown and not cooldown.is_ready():
			_draw_cooldown_pie(1.0 - cooldown.progress())
			draw_string(font, Vector2(0, SIZE.y / 2.0 + 8), "%.1f" % cooldown.remaining, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 22)
		draw_rect(rect, element_color if usable else Color(0.4, 0.4, 0.45), false, 2.0)
		draw_string(font, Vector2(4, SIZE.y - 6), str(roundi(spell.stamina_cost)), HORIZONTAL_ALIGNMENT_RIGHT, SIZE.x - 8, 15, Color("9fe8ff"))
	else:
		draw_rect(rect, Color(0.35, 0.35, 0.4, 0.6), false, 1.0)
	draw_string(font, Vector2(5, 18), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.9))


## Dark pie covering the remaining fraction of the cooldown, sweeping clockwise from the top.
func _draw_cooldown_pie(remaining: float) -> void:
	var center := SIZE / 2.0
	var radius := SIZE.length() / 2.0
	var points := PackedVector2Array([center])
	var start := -PI / 2.0
	for i in PIE_POINTS + 1:
		var a := start + TAU * remaining * float(i) / PIE_POINTS
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	# Pull the circle's points onto the square's edge so the shade fills the slot's corners.
	var clipped := PackedVector2Array()
	for p in points:
		clipped.append(p.clamp(Vector2.ZERO, SIZE))
	draw_colored_polygon(clipped, COOLDOWN_SHADE)


static func _element_icon(element: Elements.Type) -> Texture2D:
	if element == Elements.Type.NONE or not ResourceLoader.exists(ICONS_PATH):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ICONS_PATH)
	atlas.region = Rect2((int(element) - 1) * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE)
	return atlas
