class_name Cooldown
extends RefCounted
## A simple countdown timer for dashes, spells and abilities. Call tick() every frame.

var duration := 0.0
var remaining := 0.0


func start(seconds: float) -> void:
	duration = seconds
	remaining = seconds


func tick(delta: float) -> void:
	remaining = maxf(remaining - delta, 0.0)


func is_ready() -> bool:
	return remaining <= 0.0


## 0 = just started, 1 = ready (used for radial cooldown displays).
func progress() -> float:
	if duration <= 0.0:
		return 1.0
	return 1.0 - remaining / duration
