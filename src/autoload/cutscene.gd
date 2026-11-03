extends CanvasLayer
## Cutscene helpers called from .dialogue files (DIALOGUE_DESIGN.md §5.2, FR-DLG-06). Phase 6 has the basics:
## letterbox bars, fading to and from black, and waiting. Camera moves, actor movement, animations, emotes and
## skipping arrive with the story cutscenes (Phase 8). Each timed action can be awaited (`do Cutscene.wait(1)`).

const BAR_HEIGHT := 0.11      ## of the screen height
const BAR_TIME := 0.4         ## s to slide the bars in or out

var _top: ColorRect
var _bottom: ColorRect
var _fade: ColorRect


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_top = _bar(Control.PRESET_TOP_WIDE)
	_bottom = _bar(Control.PRESET_BOTTOM_WIDE)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func is_letterboxed() -> bool:
	return _top.scale.y > 0.5


## Slides the black bars in (true) or out (false).
func letterbox(on: bool) -> void:
	var target := 1.0 if on else 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_top, "scale:y", target, BAR_TIME)
	tween.tween_property(_bottom, "scale:y", target, BAR_TIME)
	await tween.finished


func fade_out(seconds := 0.6) -> void:
	await _fade_to(1.0, seconds)


func fade_in(seconds := 0.6) -> void:
	await _fade_to(0.0, seconds)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


## Back to normal at once (scene changes, skipping).
func clear() -> void:
	_top.scale.y = 0.0
	_bottom.scale.y = 0.0
	_fade.color.a = 0.0


func _fade_to(alpha: float, seconds: float) -> void:
	if seconds <= 0.0:
		_fade.color.a = alpha
		return
	await create_tween().tween_property(_fade, "color:a", alpha, seconds).finished


func _bar(preset: Control.LayoutPreset) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(preset)
	bar.anchor_top = 0.0 if preset == Control.PRESET_TOP_WIDE else 1.0 - BAR_HEIGHT
	bar.anchor_bottom = BAR_HEIGHT if preset == Control.PRESET_TOP_WIDE else 1.0
	bar.offset_top = 0.0
	bar.offset_bottom = 0.0
	bar.scale.y = 0.0
	add_child(bar)
	bar.resized.connect(func() -> void:  # scale from the screen edge
		bar.pivot_offset = Vector2(0, 0.0 if preset == Control.PRESET_TOP_WIDE else bar.size.y))
	return bar
