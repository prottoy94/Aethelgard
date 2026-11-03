class_name PerfOverlay
extends CanvasLayer
## On-screen performance readout for test levels (frame time, draw calls, memory, GPU, preset).
## F1 / F2 / F3 switch the graphics preset (Low / Medium / High). F4 hides the overlay.
##
## Benchmark mode: run the game with `-- --benchmark=<output folder>`. The overlay disables V-Sync,
## waits WARMUP_FRAMES, measures MEASURE_FRAMES, saves benchmark.txt and benchmark.png there, and quits.

const WARMUP_FRAMES := 120
const MEASURE_FRAMES := 300
const PRESET_KEYS := {KEY_F1: &"low", KEY_F2: &"medium", KEY_F3: &"high"}

var _label: Label
var _benchmark_dir := ""
var _frames := 0
var _sum_ms := 0.0
var _sum_gpu_ms := 0.0
var _done := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep measuring while menus pause the game
	_label = Label.new()
	_label.position = Vector2(16, 12)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--benchmark="):
			_benchmark_dir = arg.trim_prefix("--benchmark=")
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if PRESET_KEYS.has(key.keycode):
		Settings.set_graphics_preset(PRESET_KEYS[key.keycode])
	elif key.keycode == KEY_F4:
		_label.visible = not _label.visible


func _process(delta: float) -> void:
	var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	if _label.visible:
		_label.text = _stats_text(delta * 1000.0, gpu_ms)
	if _benchmark_dir.is_empty() or _done:
		return
	_frames += 1
	if _frames > WARMUP_FRAMES:
		_sum_ms += delta * 1000.0
		_sum_gpu_ms += gpu_ms
	if _frames == WARMUP_FRAMES + MEASURE_FRAMES:
		_done = true
		_finish_benchmark()


func _stats_text(frame_ms: float, gpu_ms: float) -> String:
	var preset := Settings.graphics.display_name if Settings.graphics else "?"
	return "\n".join([
		"%.0f FPS   frame %.2f ms   GPU %.2f ms" % [Engine.get_frames_per_second(), frame_ms, gpu_ms],
		"draw calls %d   triangles %.2f M" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1.0e6],
		"video mem %.0f MB   engine RAM %.0f MB" % [
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0],
		"%s   %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method()],
		"Graphics: %s   (F1 Low  F2 Medium  F3 High  F4 hide)" % preset,
	])


func _finish_benchmark() -> void:
	var avg := _sum_ms / MEASURE_FRAMES
	var report := "%s\nresolution %s, preset %s\navg frame %.2f ms (%.0f FPS), avg GPU %.2f ms\n%s\n" % [
		Time.get_datetime_string_from_system(), str(get_viewport().get_visible_rect().size),
		Settings.graphics.display_name, avg, 1000.0 / avg, _sum_gpu_ms / MEASURE_FRAMES,
		_stats_text(avg, _sum_gpu_ms / MEASURE_FRAMES)]
	print(report)
	var file := FileAccess.open(_benchmark_dir.path_join("benchmark.txt"), FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
	_label.visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_benchmark_dir.path_join("benchmark.png"))
	get_tree().quit()
