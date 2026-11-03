class_name Npc
extends StaticBody3D
## A villager you can talk to (FR-DLG-08). Press E: the conversation in `dialogue` starts at `cue` (the level
## connects `talk_requested` to the dialogue box); the .dialogue file chooses lines from quest progress and flags,
## including a short repeat line. Walking past may trigger a remark (`bark_cue`).
## The look is a placeholder from `look`, in the "Visual" child so a real model can replace it.

signal talk_requested(npc: Npc)

const BARK_RANGE := 4.5     ## m
const BARK_COOLDOWN := 35.0 ## s
const TURN_TIME := 0.25

@export var npc_id: StringName
@export var display_name: String
@export var dialogue: DialogueResource
@export var cue := ""
@export var bark_cue := ""
@export var look: NpcLook

var visual: Node3D
var speaker: BarkSpeaker
var _player: Player


func _ready() -> void:
	add_to_group(&"npc")
	collision_layer = 1  # world
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = look.height
	shape.shape = capsule
	shape.position = Vector3(0, look.height * 0.5, 0)
	add_child(shape)
	var placeholder := NpcPlaceholder.new()
	placeholder.look = look
	placeholder.name = &"Visual"
	add_child(placeholder)
	visual = placeholder
	speaker = BarkSpeaker.new()
	speaker.resource = dialogue
	speaker.position = Vector3(0, look.height + 0.45, 0)
	add_child(speaker)
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = "Talk to %s" % display_name
	interactable.prompt_height = look.height + 0.35
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.1
	reach.shape = sphere
	reach.position = Vector3(0, 0.8, 0)
	interactable.add_child(reach)
	add_child(interactable)
	interactable.interacted.connect(talk)


func _process(_delta: float) -> void:
	if bark_cue == "":
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
		return
	if _player.global_position.distance_to(global_position) <= BARK_RANGE and not speaker.is_showing():
		speaker.bark(bark_cue, 0, BARK_COOLDOWN)


## A villager whose conversation and passing remark are the cues named after its id ("maren", "maren_bark").
static func villager(id: StringName, name_: String, look_: NpcLook, dialogue_: DialogueResource) -> Npc:
	var npc := Npc.new()
	npc.npc_id = id
	npc.display_name = name_
	npc.look = look_
	npc.dialogue = dialogue_
	npc.cue = String(id)
	npc.bark_cue = "%s_bark" % id
	return npc


## Turns the whole villager to face `point` (call once it is in the tree).
func face_point(point: Vector3) -> void:
	var offset := point - global_position
	offset.y = 0.0
	if offset.length() > 0.01:
		rotation.y = Player.yaw_of(offset)


## Turns to the speaker and asks the level to open the conversation.
func talk(by: Node = null) -> void:
	var other := by as Node3D
	if other:
		var offset := other.global_position - global_position
		offset.y = 0.0
		if offset.length() > 0.01:
			var yaw := Player.yaw_of(offset) - global_rotation.y
			var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # turns while the talk pauses the game
			tween.tween_property(visual, "rotation:y", visual.rotation.y + angle_difference(visual.rotation.y, yaw),
					TURN_TIME)
	EventBus.npc_talked.emit(npc_id)
	talk_requested.emit(self)
