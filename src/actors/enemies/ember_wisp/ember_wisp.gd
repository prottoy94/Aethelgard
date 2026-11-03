class_name EmberWisp
extends Enemy
## Ember Wisp (GAME_DESIGN.md §7.1): a floating flame from Ignis's forces. Keeps its distance, glows while it
## aims (with a line on the ground showing where), then throws a slow ember bolt that sets the target Burning.
## Ember element: weak to Light and Frost.

const EMBER_COLOR := Color(1.0, 0.35, 0.12)
const SHOT_HEIGHT := 1.2


func perform_attack() -> void:
	visual.play_attack()
	if not has_live_target():
		return
	var bolt := Projectile.new()
	get_parent().add_child(bolt)
	var from := global_position + Vector3(0, SHOT_HEIGHT, 0)
	bolt.launch(self, from, direction_to(target.global_position), HurtboxComponent.Team.ENEMY, data.attack_damage,
			data.attack_element, EMBER_COLOR, data.projectile_speed, data.projectile_range, data.projectile_radius)
	bolt.hitbox.status_effect = data.attack_status
	bolt.hitbox.status_duration = data.attack_status_duration
	bolt.hitbox.status_power = data.attack_status_power


func end_attack() -> void:
	pass  # the bolt flies on its own
