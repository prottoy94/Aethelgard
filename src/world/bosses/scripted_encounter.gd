class_name ScriptedEncounter
extends Node3D
## A scripted boss fight (TECHNICAL_DESIGN.md §4.12, FR-BOS-04): the boss waits hidden as a cutscene actor (tagged
## `data.actor_id`) until a scene spawns it, then start() wakes it with its music and the HUD boss bar. It can't be
## hurt, and Aurelia can't fall (her health stops at `player_minimum_health`). The fight ends after `duration`
## seconds or when her health falls to `end_health_ratio`, whichever comes first, so it always ends in the story's
## cutscene, never in a defeat. The region plays that cutscene from `finished`, then calls release().

signal fight_started(boss: Boss)
signal fight_ended(won: bool)
signal finished(reason: StringName)   ## &"time" or &"health"

const REASON_TIME: StringName = &"time"
const REASON_HEALTH: StringName = &"health"

@export var data: ScriptedEncounterData

var boss: Boss
var running := false
var elapsed := 0.0
var _player: Player


func _ready() -> void:
	add_to_group(&"scripted_encounter")
	if data == null or data.boss_scene == null:
		return
	boss = data.boss_scene.instantiate() as Boss
	add_child(boss)
	boss.visible = false
	boss.process_mode = Node.PROCESS_MODE_DISABLED  # asleep until the fight (cutscenes still animate its visual)
	CutsceneActor.tag(boss, data.actor_id)


## Wakes the boss where it stands and starts the clock.
func start() -> void:
	if running or boss == null:
		return
	_player = get_tree().get_first_node_in_group(&"player") as Player
	running = true
	elapsed = 0.0
	boss.visible = true
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	boss.home = boss.global_position
	if _player:
		_player.health.minimum = data.player_minimum_health
	var music := data.music if data.music != &"" else boss.boss_data().music
	if music != &"":
		AudioManager.set_combat_layer(&"")
		AudioManager.play_music(music)
	boss.begin_fight()
	fight_started.emit(boss)


func _physics_process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	if elapsed >= data.duration:
		end(REASON_TIME)
	elif _player and _player.health.ratio() <= data.end_health_ratio:
		end(REASON_HEALTH)


## Stops the fight (also used by tests): the boss stands still, Aurelia is safe for a moment.
func end(reason: StringName) -> void:
	if not running:
		return
	running = false
	if is_instance_valid(boss):
		boss.fighting = false
		boss.end_telegraph()
		boss.end_attack()
		boss.current_move = null
		boss.velocity = Vector3.ZERO
		boss.state_machine.transition_to(&"Idle")
	if _player:
		_player.status_effects.clear()
		_player.grant_invulnerability(data.safe_time)
	if data.done_flag != &"":
		GameState.set_flag(data.done_flag)
	fight_ended.emit(false)
	finished.emit(reason)


## After the story scene: Aurelia can fall again, and the boss is gone.
func release() -> void:
	if _player and is_instance_valid(_player):
		_player.health.minimum = 0.0
	if is_instance_valid(boss):
		boss.queue_free()
	boss = null
