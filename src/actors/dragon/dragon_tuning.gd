class_name DragonTuning
extends Resource
## Rules for the pet dragon (GAME_DESIGN.md §8, TECHNICAL_DESIGN.md §4.11): warming the egg, naming, bond, the
## companion AI and being knocked out, plus the four species. Values: data/dragons/dragon_tuning.tres.

@export var species: Array[DragonSpeciesData] = []

@export_group("Egg")
@export var warmth_needed := 60.0
@export var warmth_per_enemy := 8.0       ## defeating an enemy with the egg
@export var warmth_per_puzzle := 12.0
@export var warmth_per_secret := 8.0
@export var warmth_per_place := 4.0       ## reaching a named place
@export var warmth_per_region := 6.0      ## arriving in a new area
@export var warmth_per_100m := 5.0        ## walking

@export_group("Name")
@export var default_name := "Pip"
@export var max_name_length := 14

@export_group("Bond")
@export var bond_xp_to_next: PackedInt32Array = [30, 40, 50, 60, 70, 80, 90, 100, 120]  ## 1→2 … 9→10
@export var bond_per_fight := 6           ## each enemy defeated while the dragon is out
@export var bond_per_pet := 8
@export var pet_cooldown_minutes := 240.0 ## game minutes between petting that raises the bond
@export var health_bonus_per_bond := 0.06 ## × max HP per bond level above 1
@export var damage_bonus_per_bond := 0.06
@export var power_per_bond := 3           ## Magic Power per bond level (GAME_DESIGN.md §5.2: "dragon bond")

@export_group("Companion AI")
@export var follow_distance := 1.8        ## m from Aurelia where it settles
@export var follow_restart := 3.2         ## m: starts walking again when farther than this
@export var catch_up_distance := 6.0      ## m: runs faster beyond this
@export var catch_up_multiplier := 1.6
@export var leash_distance := 13.0        ## m: appears back beside her when left farther behind
@export var engage_radius := 6.0          ## m: Follow bites enemies this close to Aurelia that are after her
@export var attack_search_radius := 12.0  ## m: Attack looks this far from Aurelia for her target
@export var attack_aim_angle := 35.0      ## degrees: an enemy this close to her aim counts as aimed at
@export var attack_leash := 15.0          ## m: gives up a target this far from Aurelia
@export var target_memory := 6.0          ## s: the last enemy she hit stays her target
@export var guard_distance := 1.3         ## m from Aurelia, towards the nearest threat
@export var guard_engage_radius := 3.0    ## m: Guard bites enemies this close to Aurelia
@export var danger_margin := 0.6          ## m it keeps outside enemies' telegraph rings
@export var distract_time := 3.0          ## s an enemy it bites goes after it instead
@export var skill_approach_time := 1.5    ## s it may run towards a target before breathing

@export_group("Health")
@export var ko_time := 20.0               ## s knocked out before it comes back (FR-DRG-07)
@export var ko_return_health := 0.5       ## of max HP when it comes back
@export var calm_regen := 2.0             ## HP/s while no enemy is engaged
@export var calm_regen_delay := 4.0       ## s after being hurt
@export var hurt_invulnerable := 0.4      ## s


func species_for(element: Elements.Type) -> DragonSpeciesData:
	for entry in species:
		if entry.element == element:
			return entry
	return null


## Bond XP from `level` to the next (0 at the top level).
func bond_xp_needed(level: int) -> int:
	return bond_xp_to_next[level - 1] if level >= 1 and level <= bond_xp_to_next.size() else 0


func max_bond() -> int:
	return bond_xp_to_next.size() + 1
