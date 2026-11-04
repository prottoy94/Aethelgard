class_name DragonPanel
extends Control
## HUD dragon panel (FR-UI-02), bottom left: a placeholder portrait, name and stage, HP bar, current command (G) and
## the breath skill's cooldown (H), plus the bond level. Before hatching it shows the egg and its warmth.
## Hidden until Aurelia has an egg. Reads DragonManager and the Dragon in the region.

const SIZE := Vector2(360, 104)
const BACK := Color(0.08, 0.06, 0.1, 0.78)
const HP_COLOR := Color("e2557a")
const WARM_COLOR := Color("ffb45a")
const TEXT := Color(1, 1, 1, 0.95)
const DIM := Color(1, 1, 1, 0.6)
const SHELL := Color("efe6d2")
const PORTRAIT_RADIUS := 36.0
const FIND_EVERY := 0.5   ## s between looks for the dragon node

var dragon: Dragon
var _find_left := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false                              # until the first update says there is an egg or a dragon
	process_mode = Node.PROCESS_MODE_ALWAYS      # stays right while menus pause the game


func _process(delta: float) -> void:
	_time += delta
	visible = DragonManager.stage != DragonTypes.Stage.NONE
	if not visible:
		return
	_find_left -= delta
	if (dragon == null or not is_instance_valid(dragon)) and _find_left <= 0.0:
		_find_left = FIND_EVERY
		dragon = get_tree().get_first_node_in_group(&"dragon") as Dragon
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), BACK)
	var center := Vector2(14 + PORTRAIT_RADIUS, SIZE.y * 0.5)
	var x := center.x + PORTRAIT_RADIUS + 14.0
	var font := get_theme_default_font()
	if DragonManager.has_egg():
		_draw_egg(center)
		_text(font, Vector2(x, 26), "Dragon egg", 19, TEXT)
		_bar(Rect2(x, 36, SIZE.x - x - 14, 16), DragonManager.warmth_ratio(), WARM_COLOR,
				"Warmth %d%%" % roundi(DragonManager.warmth_ratio() * 100.0))
		var hint := "Glowing! Rest at a Lantern Shrine." if DragonManager.is_egg_ready() \
				else "Fight and explore to warm it."
		_text(font, Vector2(x, 76), hint, 15, WARM_COLOR if DragonManager.is_egg_ready() else DIM)
		return
	var kind := DragonManager.species()
	_draw_face(center, kind)
	_text(font, Vector2(x, 24), "%s   %s %s" % [DragonManager.display_name(),
			kind.display_name.trim_suffix(" dragon") if kind else "", DragonTypes.stage_name(DragonManager.stage).to_lower()],
			18, TEXT)
	var current := dragon.health.current if dragon else DragonManager.health_ratio * DragonManager.max_health()
	var maximum := dragon.health.max_health if dragon else DragonManager.max_health()
	_bar(Rect2(x, 33, SIZE.x - x - 14, 15), current / maxf(maximum, 1.0), HP_COLOR,
			"HP  %d / %d" % [roundi(current), roundi(maximum)])
	if DragonManager.knocked_out_left > 0.0:
		_text(font, Vector2(x, 70), "Knocked out: back in %d s" % ceili(DragonManager.knocked_out_left), 15, DIM)
	else:
		_text(font, Vector2(x, 70), "G  %s" % DragonTypes.command_name(DragonManager.command), 16, TEXT)
		_text(font, Vector2(x + 110, 70), "Bond %d" % DragonManager.bond_level, 15, Color("ffd98a"))
	var skill := DragonManager.active_skill()
	if skill:
		var line := "H  %s" % skill.display_name
		if dragon and not dragon.skill_cooldown.is_ready():
			line += "   %.1f s" % dragon.skill_cooldown.remaining
		var ready := dragon != null and dragon.skill_cooldown.is_ready() and DragonManager.is_active()
		_text(font, Vector2(x, 92), line, 15, Elements.color(skill.element) if ready else DIM)


func _draw_egg(center: Vector2) -> void:
	var glow := DragonManager.warmth_ratio()
	if DragonManager.is_egg_ready():
		glow = 0.75 + 0.25 * sin(_time * 4.0)
	draw_circle(center, PORTRAIT_RADIUS, Color(WARM_COLOR, 0.25 * glow + 0.1))
	draw_set_transform(center, 0.0, Vector2(0.78, 1.0))
	draw_circle(Vector2.ZERO, PORTRAIT_RADIUS * 0.8, SHELL.lerp(Color("ffe3b0"), glow))
	draw_set_transform(Vector2.ZERO)
	for dot: Vector2 in [Vector2(-8, -12), Vector2(9, -4), Vector2(-4, 10), Vector2(6, 16)]:
		draw_circle(center + dot, 3.0, Color("9a8a6a"))


## Placeholder portrait: the dragon's colours, horns and eyes in a circle.
func _draw_face(center: Vector2, kind: DragonSpeciesData) -> void:
	var body := kind.body_color if kind else Color.GRAY
	var out := DragonManager.knocked_out_left > 0.0
	draw_circle(center, PORTRAIT_RADIUS, (kind.wing_color if kind else Color.DIM_GRAY).darkened(0.35))
	var horn := kind.horn_color if kind else Color.WHITE
	for side: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([center + Vector2(side * 12, -14), center + Vector2(side * 22, -34),
				center + Vector2(side * 4, -18)]), horn)
	draw_circle(center + Vector2(0, 2), 22.0, body.darkened(0.3) if out else body)
	draw_circle(center + Vector2(0, 14), 11.0, (kind.belly_color if kind else Color.WHITE))
	for side: float in [-1.0, 1.0]:
		var eye := center + Vector2(side * 9, -2)
		if out:
			draw_line(eye - Vector2(5, 0), eye + Vector2(5, 0), Color.BLACK, 2.0)
		else:
			draw_circle(eye, 5.0, kind.eye_color if kind else Color.BLACK)
			draw_circle(eye + Vector2(1.5, -1.5), 1.6, Color.WHITE)


func _bar(rect: Rect2, ratio: float, color: Color, label: String) -> void:
	draw_rect(rect, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2((rect.size.x - 4) * clampf(ratio, 0.0, 1.0), rect.size.y - 4)),
			color)
	var font := get_theme_default_font()
	var baseline := rect.position + Vector2(8, rect.size.y * 0.5 + 5.0)
	draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color.BLACK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
