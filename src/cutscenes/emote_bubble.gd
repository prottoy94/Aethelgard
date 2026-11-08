class_name EmoteBubble
extends Label3D
## A small emote over a character's head (DIALOGUE_DESIGN.md §5.2 `emote`): "!", "?", "♥", "♪", "…". Pops in, floats
## a little and fades. Runs while the game is paused (cutscene conversations pause it).

const RISE := 0.25    ## m
const TIME := 1.6     ## s on screen


static func show_over(node: Node3D, icon: String, height: float) -> EmoteBubble:
	var bubble := EmoteBubble.new()
	bubble.text = icon
	node.add_child(bubble)
	bubble.position = Vector3(0, height, 0)
	return bubble


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = 72
	outline_size = 18
	pixel_size = 0.006
	modulate = Color(1.0, 0.97, 0.88)
	outline_modulate = Color(0.23, 0.16, 0.12)
	scale = Vector3.ONE * 0.2
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", position.y + RISE, TIME)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4).set_delay(TIME - 0.4)
	tween.tween_callback(queue_free)
