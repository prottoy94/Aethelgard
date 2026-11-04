class_name BossBar
extends Control
## The boss health bar (FR-BOS-02): the boss's name and title above a wide bar at the top of the screen, with marks
## where its next phases begin and a line when a phase starts. Shown while a boss fight runs.

const SIZE := Vector2(720, 70)
const BAR_HEIGHT := 18.0
const BACK := Color(0.06, 0.04, 0.06, 0.85)
const FILL := Color("e8553a")
const LOST := Color("f2c14e")
const TEXT := Color(1, 0.94, 0.86)
const ANNOUNCE_TIME := 3.0

var boss: Boss
var _shown_ratio := 1.0
var _announce := ""
var _announce_left := 0.0


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_boss(new_boss: Boss) -> void:
	boss = new_boss
	_shown_ratio = 1.0
	visible = true
	if not boss.phase_changed.is_connected(_on_phase_changed):
		boss.phase_changed.connect(_on_phase_changed)


func hide_boss() -> void:
	visible = false
	boss = null


func _process(delta: float) -> void:
	if not visible:
		return
	if boss == null or not is_instance_valid(boss):
		visible = false
		return
	_shown_ratio = move_toward(_shown_ratio, boss.health.ratio(), delta * 0.4)  # the lost part drains slowly
	_announce_left = maxf(_announce_left - delta, 0.0)
	queue_redraw()


func _on_phase_changed(index: int, phase: BossPhaseData) -> void:
	if index > 0 and phase and phase.announce != "":
		_announce = phase.announce
		_announce_left = ANNOUNCE_TIME


func _draw() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var font := get_theme_default_font()
	var data := boss.boss_data()
	var title := "%s   ·   %s" % [data.display_name, data.title] if data.title != "" else data.display_name
	draw_string_outline(font, Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 22, 6, Color.BLACK)
	draw_string(font, Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 22, TEXT)
	var bar := Rect2(0, 32, SIZE.x, BAR_HEIGHT)
	draw_rect(bar, BACK)
	var inner := bar.grow(-3)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * _shown_ratio, inner.size.y)), LOST)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * boss.health.ratio(), inner.size.y)), FILL)
	for phase in data.phases:
		if phase.health_ratio < 1.0:
			var x := inner.position.x + inner.size.x * phase.health_ratio
			draw_line(Vector2(x, bar.position.y - 2), Vector2(x, bar.end.y + 2), TEXT, 2.0)
	if _announce_left > 0.0:
		var color := Color(LOST, clampf(_announce_left, 0.0, 1.0))
		draw_string_outline(font, Vector2(0, 68), _announce, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 18, 5,
				Color(0, 0, 0, color.a))
		draw_string(font, Vector2(0, 68), _announce, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 18, color)
