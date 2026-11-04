extends State
## Knocked out (FR-DRG-07): curled up with "zzz", can't be hit, bitten or petted. DragonManager counts down and the
## Dragon wakes up beside Aurelia when the time is over, or at once when she rests at a Lantern Shrine.

const ZZZ_EVERY := 2.0  ## s

var _zzz := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	var dragon := actor as Dragon
	dragon.target = null
	dragon.bite_hitbox.deactivate()
	dragon.visual.set_knocked_out(true)
	dragon.interactable.set_deferred(&"monitorable", false)
	dragon.status_effects.clear()
	AudioManager.play(&"dragon_ko", dragon.global_position)
	_zzz = 0.0


func exit() -> void:
	var dragon := actor as Dragon
	dragon.visual.set_knocked_out(false)
	dragon.update_pet_prompt.call_deferred()  # once DragonManager says it is awake again


func physics_update(delta: float) -> void:
	var dragon := actor as Dragon
	dragon.move_with(Vector3.ZERO, delta, false)
	_zzz -= delta
	if _zzz <= 0.0:
		_zzz = ZZZ_EVERY
		dragon.show_emote("zzz", ZZZ_EVERY * 0.8)
