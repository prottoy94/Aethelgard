class_name StaminaComponent
extends Node
## Magic stamina (GAME_DESIGN.md §6.1). Spells spend it; it refills after a short pause.
## At 0 the owner is Exhausted and can't cast until it refills to `recover_ratio` of the maximum.

signal changed(current: float, maximum: float)
signal exhausted_changed(is_exhausted: bool)
signal spend_failed

@export var max_stamina := 40.0
@export var regen_rate := 12.0       ## per second
@export var regen_delay := 0.8       ## s after the last spend before refilling starts
@export var recover_ratio := 0.3     ## Exhausted ends at this fraction of the maximum

var current := 0.0
var exhausted := false
var _since_spent := INF


func _ready() -> void:
	current = max_stamina


func _process(delta: float) -> void:
	tick(delta)


## Spends `cost` if there is enough and the owner isn't Exhausted. Returns true on success.
func try_spend(cost: float) -> bool:
	if exhausted or current < cost:
		spend_failed.emit()
		return false
	current -= cost
	_since_spent = 0.0
	if current <= 0.001:
		current = 0.0
		_set_exhausted(true)
	changed.emit(current, max_stamina)
	return true


func tick(delta: float) -> void:
	_since_spent += delta
	if _since_spent < regen_delay or current >= max_stamina:
		return
	# Only the part of this frame after the delay ended counts as refill time.
	var refill_time := minf(delta, _since_spent - regen_delay)
	current = minf(current + regen_rate * refill_time, max_stamina)
	if exhausted and current >= max_stamina * recover_ratio:
		_set_exhausted(false)
	changed.emit(current, max_stamina)


## Adds stamina (tonics). Ends Exhausted once past the recovery threshold.
func restore(amount: float) -> void:
	current = minf(current + amount, max_stamina)
	if exhausted and current >= max_stamina * recover_ratio:
		_set_exhausted(false)
	changed.emit(current, max_stamina)


## Changes the maximum. With `keep_gain` a higher maximum also adds the difference now.
func set_max_stamina(value: float, keep_gain: bool) -> void:
	var gain := value - max_stamina
	max_stamina = value
	if keep_gain and gain > 0.0:
		current += gain
	current = minf(current, max_stamina)
	changed.emit(current, max_stamina)


func reset() -> void:
	current = max_stamina
	_since_spent = INF
	_set_exhausted(false)
	changed.emit(current, max_stamina)


func ratio() -> float:
	return current / max_stamina if max_stamina > 0.0 else 0.0


func _set_exhausted(value: bool) -> void:
	if exhausted != value:
		exhausted = value
		exhausted_changed.emit(value)
