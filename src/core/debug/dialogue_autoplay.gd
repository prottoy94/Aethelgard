class_name DialogueAutoplay
extends Node
## Dev tool (`-- --autoplay` or `-- --autoplay=<choice number>`): walks conversations forward by itself, so a test run
## can show a whole cutscene without anyone at the keyboard. Advances a line every STEP seconds, picks the given
## choice (the first by default) and accepts the suggested name. Added by RegionRuntime.

const STEP := 1.0  ## s per line

var choice := 0
var _left := STEP


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = STEP
	if Cutscene.is_asking():
		Cutscene.submit_text("")
		return
	var box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if box == null or not box.is_open() or box.line == null:
		return
	if box.line.responses.is_empty():
		box.advance()
	else:
		box.choose(clampi(choice, 0, box.line.responses.size() - 1))
