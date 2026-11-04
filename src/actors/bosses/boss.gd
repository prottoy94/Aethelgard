class_name Boss
extends Enemy
## A boss (TECHNICAL_DESIGN.md §4.12; FR-BOS-01): an Enemy whose moves come from its current phase. New phases start
## at HP thresholds (BossData.phases), can open with a move (calling helpers) and speed it up. It waits until its
## BossArena starts the fight, shows its health on the HUD boss bar instead of a bar over its head, and resets to full
## when Aurelia falls. Ordinary hits don't stagger it (EnemyData.stagger_resistant).

signal phase_changed(index: int, phase: BossPhaseData)
signal fight_started

var phase_index := 0
var fighting := false
var helpers: Array[Node3D] = []


func _ready() -> void:
	super()
	add_to_group(&"boss")
	if _health_bar:
		_health_bar.queue_free()  # the HUD boss bar shows it instead
		_health_bar = null
	health.changed.connect(_on_health_changed)
	summoned.connect(func(helper: Node3D) -> void: helpers.append(helper))


func boss_data() -> BossData:
	return data as BossData


func phase() -> BossPhaseData:
	var phases := boss_data().phases
	return phases[phase_index] if phase_index < phases.size() else null


func available_moves() -> Array[EnemyMoveData]:
	var current := phase()
	return current.moves if current else data.moves


## The arena calls this when Aurelia steps in.
func begin_fight() -> void:
	fighting = true
	_enter_phase(0, false)
	state_machine.transition_to(&"Chase")
	fight_started.emit()


## Back to the start: full health, home, first phase, waiting (Aurelia fell). Its helpers vanish.
func reset_fight() -> void:
	fighting = false
	for helper in helpers:
		if is_instance_valid(helper):
			helper.queue_free()
	helpers.clear()
	end_attack()
	end_telegraph()
	current_move = null
	status_effects.clear()
	health.reset()
	global_position = home
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	phase_index = 0
	state_machine.transition_to(&"Idle")


## Phases speed up its movement.
func move(target_velocity: Vector3, delta: float) -> void:
	var current := phase()
	super(target_velocity * (current.speed_multiplier if current else 1.0), delta)


func _on_health_changed(current_health: float, maximum: float) -> void:
	if not fighting or health.is_dead() or maximum <= 0.0:
		return
	var ratio := current_health / maximum
	var phases := boss_data().phases
	for i in range(phases.size() - 1, phase_index, -1):
		if ratio <= phases[i].health_ratio:
			_enter_phase(i, true)
			return


func _enter_phase(index: int, announce: bool) -> void:
	phase_index = index
	var current := phase()
	phase_changed.emit(index, current)
	if announce and current and current.opening_move != &"" and not health.is_dead():
		var opening := find_move(current.opening_move)
		if opening:
			current_move = opening
			state_machine.transition_to(&"Telegraph")
