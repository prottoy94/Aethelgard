class_name DamageInfo
extends RefCounted
## One hit: how much, which element, which way it pushes, and who caused it (TECHNICAL_DESIGN.md §4.5).

var amount := 0.0
var element := Elements.Type.NONE
var knockback := Vector3.ZERO   ## world-space push (direction × strength, m/s)
var stagger := false            ## interrupts the target's current action
var source: Node                ## who dealt the hit (may be null)
var status := &""               ## status effect to apply (StatusEffectComponent id), or none
var status_duration := 0.0
var status_power := 0.0


static func create(amount_: float, element_: Elements.Type, knockback_: Vector3, source_: Node, stagger_ := false) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = amount_
	info.element = element_
	info.knockback = knockback_
	info.source = source_
	info.stagger = stagger_
	return info


## Adds a status effect to this hit and returns it (for chaining).
func with_status(id: StringName, duration: float, power := 0.0) -> DamageInfo:
	status = id
	status_duration = duration
	status_power = power
	return self
