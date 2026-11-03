class_name InteractableComponent
extends Area3D
## Something the player can interact with: NPC, sign, chest, rest point (FR-PLY-06).
## Lives on the "interactable" physics layer; the player's detector finds it and shows the prompt.
## Give it a CollisionShape3D child for the interaction range.

signal interacted(by: Node)

const INTERACTABLE_LAYER := 1 << 6  # layer 7

@export var prompt_verb := "Interact"
@export var prompt_height := 1.7

var _label: Label3D


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	_label = Label3D.new()
	_label.text = "%s  %s" % [_key_name(), prompt_verb]
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 40
	_label.outline_size = 12
	_label.pixel_size = 0.006
	_label.position = Vector3(0, prompt_height, 0)
	_label.visible = false
	add_child(_label)


func show_prompt(visible_now: bool) -> void:
	_label.visible = visible_now


func interact(by: Node) -> void:
	interacted.emit(by)


## Shows the first keyboard key bound to "interact" (E by default), so remapping updates the prompt.
static func _key_name() -> String:
	for event in InputMap.action_get_events(&"interact"):
		var key := event as InputEventKey
		if key:
			return OS.get_keycode_string(key.physical_keycode)
	return "?"
