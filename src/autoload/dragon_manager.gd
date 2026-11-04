extends Node
## The pet dragon's lasting state (GAME_DESIGN.md §8; FR-DRG-01/04/05/06/07): the egg and its warmth, the element and
## name chosen at hatching, the growth stage, bond level and XP, the current command, health and the knock-out timer.
## Saved by SaveManager (to_dict/from_dict). Each bond level adds Magic Power (PlayerData.set_dragon_power).
## The Dragon actor in a region shows and moves the dragon; dialogue may call receive_egg(), choose_element(),
## ask_name() and read dragon_name, stage and bond_level (DIALOGUE_DESIGN.md §2.3).

signal egg_received
signal warmth_changed(warmth: float, needed: float)
signal egg_ready
signal element_chosen(element: Elements.Type)
signal hatched
signal name_changed(new_name: String)
signal bond_changed(level: int, xp: int)
signal bond_level_up(level: int)
signal skill_unlocked(skill: DragonSkillData)
signal command_changed(command: DragonTypes.Command)
signal fed(item: ConsumableData)
signal petted(gave_bond: bool)
signal knocked_out
signal recovered
signal rested

const TUNING: DragonTuning = preload("res://data/dragons/dragon_tuning.tres")
const EGG_FLAG: StringName = &"egg_received"
const WARM_FLAG: StringName = &"egg_warm"
const HATCHED_FLAG: StringName = &"dragon_hatched"
const WALK_STEP := 10.0   ## m walked per warmth update
const MAX_STEP := 3.0     ## m in one frame still counted as walking (bigger jumps are teleports)

var stage := DragonTypes.Stage.NONE
var element := Elements.Type.NONE
var dragon_name := ""
var warmth := 0.0
var bond_level := 1
var bond_xp := 0
var command := DragonTypes.Command.FOLLOW
var health_ratio := 1.0         ## the dragon's health (0–1), kept between areas and in saves
var knocked_out_left := 0.0     ## s until it comes back (0 = awake)
var last_pet_minute := -1.0     ## game minute of the last petting that raised the bond (-1 = never)
var _walked := 0.0
var _last_position: Variant = null


func _ready() -> void:
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.puzzle_solved.connect(func(_id: StringName) -> void: add_warmth(TUNING.warmth_per_puzzle))
	EventBus.secret_found.connect(func(_id: StringName) -> void: add_warmth(TUNING.warmth_per_secret))
	EventBus.place_reached.connect(func(_id: StringName) -> void: add_warmth(TUNING.warmth_per_place))
	EventBus.region_changed.connect(func(_id: StringName) -> void: add_warmth(TUNING.warmth_per_region))


func _physics_process(delta: float) -> void:
	if not TimeOfDay.running:
		_last_position = null
		return
	if stage == DragonTypes.Stage.EGG:
		_count_walking()
	if knocked_out_left > 0.0:
		knocked_out_left = maxf(knocked_out_left - delta, 0.0)
		if knocked_out_left <= 0.0:
			health_ratio = TUNING.ko_return_health
			recovered.emit()


# --- Questions -----------------------------------------------------------------------------------

func has_egg() -> bool:
	return stage == DragonTypes.Stage.EGG


func is_hatched() -> bool:
	return stage >= DragonTypes.Stage.HATCHLING


## Hatched and not knocked out.
func is_active() -> bool:
	return is_hatched() and knocked_out_left <= 0.0


func is_egg_ready() -> bool:
	return has_egg() and warmth >= TUNING.warmth_needed


func warmth_ratio() -> float:
	return clampf(warmth / TUNING.warmth_needed, 0.0, 1.0) if TUNING.warmth_needed > 0.0 else 1.0


func species() -> DragonSpeciesData:
	return TUNING.species_for(element)


func stats() -> DragonStageStats:
	var kind := species()
	return kind.stats_for(stage) if kind else DragonStageStats.new()


## Max HP and bite damage grow with the bond.
func health_multiplier() -> float:
	return 1.0 + TUNING.health_bonus_per_bond * (bond_level - 1)


func damage_multiplier() -> float:
	return 1.0 + TUNING.damage_bonus_per_bond * (bond_level - 1)


func max_health() -> float:
	return stats().max_health * health_multiplier()


## Magic Power from the bond (GAME_DESIGN.md §5.2): power_per_bond per bond level once hatched.
func magic_power_bonus() -> int:
	return TUNING.power_per_bond * bond_level if is_hatched() else 0


func bond_progress() -> float:
	var needed := TUNING.bond_xp_needed(bond_level)
	return 1.0 if needed <= 0 else clampf(float(bond_xp) / needed, 0.0, 1.0)


func active_skill() -> DragonSkillData:
	var kind := species()
	return kind.active_skill(stage, bond_level) if kind and is_hatched() else null


func passives() -> Array[DragonSkillData]:
	var kind := species()
	return kind.passives(stage, bond_level) if kind and is_hatched() else ([] as Array[DragonSkillData])


func display_name() -> String:
	return dragon_name if dragon_name != "" else TUNING.default_name


# --- The egg and hatching ------------------------------------------------------------------------

## The Elder hands Aurelia the egg (FR-DRG-01; owner decision 2026-11-04, a stand-in until the story scenes).
func receive_egg() -> void:
	if stage != DragonTypes.Stage.NONE:
		return
	stage = DragonTypes.Stage.EGG
	warmth = 0.0
	GameState.set_flag(EGG_FLAG)
	egg_received.emit()
	warmth_changed.emit(warmth, TUNING.warmth_needed)


## Fighting and exploring warm the egg (GAME_DESIGN.md §8.2). Once warm it waits to hatch at a Lantern Shrine.
func add_warmth(amount: float) -> void:
	if not has_egg() or amount <= 0.0 or is_egg_ready():
		return
	warmth = minf(warmth + amount, TUNING.warmth_needed)
	warmth_changed.emit(warmth, TUNING.warmth_needed)
	if is_egg_ready():
		GameState.set_flag(WARM_FLAG)
		egg_ready.emit()


## Picks the element from a dialogue word: "frost", "wind", "earth" or "light" (FR-DRG-06). Only before hatching.
func choose_element(id: String) -> bool:
	var chosen := DragonTypes.element_for(id)
	if chosen == Elements.Type.NONE or TUNING.species_for(chosen) == null or is_hatched():
		return false
	element = chosen
	element_chosen.emit(element)
	return true


## The egg hatches into a hatchling (FR-DRG-01). Without a chosen element it becomes the first species.
func hatch() -> void:
	if is_hatched():
		return
	if TUNING.species_for(element) == null:
		element = TUNING.species[0].element
	stage = DragonTypes.Stage.HATCHLING
	warmth = TUNING.warmth_needed
	bond_level = 1
	bond_xp = 0
	health_ratio = 1.0
	knocked_out_left = 0.0
	command = DragonTypes.Command.FOLLOW
	if dragon_name == "":
		dragon_name = TUNING.default_name
	_update_power(true)
	hatched.emit()
	EventBus.dragon_hatched.emit()  # its stinger first; the quest it finishes comes next
	GameState.set_flag(WARM_FLAG)
	GameState.set_flag(HATCHED_FLAG)


## Asks the player for a name (FR-DLG-09). An empty answer keeps the default, "Pip" (owner decision 2026-11-04).
func ask_name() -> void:
	var text: String = await Cutscene.ask_text("Name your dragon", TUNING.default_name, TUNING.max_name_length)
	set_dragon_name(text)


func set_dragon_name(text: String) -> void:
	dragon_name = clean_name(text, TUNING.max_name_length, TUNING.default_name)
	name_changed.emit(dragon_name)


## Trims the name, drops characters that would act as text markup, cuts it to `max_length`; empty → `fallback`.
static func clean_name(text: String, max_length: int, fallback: String) -> String:
	var cleaned := ""
	for letter in text.strip_edges():
		if not "[]{}<>\\\"|\n\t".contains(letter):
			cleaned += letter
	while "  " in cleaned:
		cleaned = cleaned.replace("  ", " ")
	cleaned = cleaned.strip_edges().left(max_length).strip_edges()
	return cleaned if cleaned != "" else fallback


# --- Bond (FR-DRG-05) ----------------------------------------------------------------------------

func add_bond_xp(amount: int) -> void:
	if not is_hatched() or amount <= 0 or bond_level >= TUNING.max_bond():
		return
	var before := species().unlocked_skills(stage, bond_level) if species() else ([] as Array[DragonSkillData])
	bond_xp += amount
	while bond_level < TUNING.max_bond() and bond_xp >= TUNING.bond_xp_needed(bond_level):
		bond_xp -= TUNING.bond_xp_needed(bond_level)
		bond_level += 1
		bond_level_up.emit(bond_level)
	if bond_level >= TUNING.max_bond():
		bond_xp = 0
	bond_changed.emit(bond_level, bond_xp)
	if species():
		for skill in species().unlocked_skills(stage, bond_level):
			if not skill in before:
				skill_unlocked.emit(skill)
	_update_power(true)


## Petting (interact near the dragon): always welcome; raises the bond once every few game hours.
func can_pet_for_bond() -> bool:
	return is_active() and (last_pet_minute < 0.0 \
			or TimeOfDay.total_minutes() - last_pet_minute >= TUNING.pet_cooldown_minutes)


func pet() -> bool:
	if not is_active():
		return false
	var gives_bond := can_pet_for_bond()
	if gives_bond:
		last_pet_minute = TimeOfDay.total_minutes()
		add_bond_xp(TUNING.bond_per_pet)
	petted.emit(gives_bond)
	return gives_bond


static func is_food(item: ItemData) -> bool:
	var food := item as ConsumableData
	return food != null and (food.dragon_bond > 0 or food.dragon_heal > 0.0)


## Feeds a dragon treat from the bag. Returns &"" if eaten, otherwise why not: &"not_food", &"no_dragon",
## &"knocked_out", &"none_left" or &"full" (top bond and full health).
func feed(item: ConsumableData) -> StringName:
	if not is_food(item):
		return &"not_food"
	if not is_hatched():
		return &"no_dragon"
	if knocked_out_left > 0.0:
		return &"knocked_out"
	if not Inventory.has(item.id):
		return &"none_left"
	if bond_level >= TUNING.max_bond() and health_ratio >= 1.0:
		return &"full"
	Inventory.remove(item.id)
	health_ratio = minf(health_ratio + item.dragon_heal / maxf(max_health(), 1.0), 1.0)
	add_bond_xp(item.dragon_bond)
	fed.emit(item)
	return &""


# --- Commands, knock-outs, resting ---------------------------------------------------------------

func cycle_command() -> DragonTypes.Command:
	set_command(((command + 1) % DragonTypes.COMMAND_NAMES.size()) as DragonTypes.Command)
	return command


func set_command(new_command: DragonTypes.Command) -> void:
	command = new_command
	command_changed.emit(command)


## Health 0: it retreats and comes back after a while (FR-DRG-07). It never dies.
func knock_out() -> void:
	if not is_active():
		return
	health_ratio = 0.0
	knocked_out_left = TUNING.ko_time
	knocked_out.emit()


## Resting at a Lantern Shrine heals the dragon fully and wakes it if knocked out.
func rest() -> void:
	if not is_hatched():
		return
	health_ratio = 1.0
	knocked_out_left = 0.0
	rested.emit()


# --- Saving --------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	if stage == DragonTypes.Stage.NONE:
		return {}
	return {
		"stage": int(stage),
		"element": element_id(element),
		"name": dragon_name,
		"warmth": warmth,
		"bond_level": bond_level,
		"bond_xp": bond_xp,
		"command": int(command),
		"health": health_ratio,
		"knocked_out": knocked_out_left,
		"last_pet": last_pet_minute,
	}


## Restores to_dict()'s result; an empty dictionary means no dragon yet (a new game).
func from_dict(data: Dictionary) -> void:
	stage = clampi(int(data.get("stage", 0)), 0, DragonTypes.Stage.ADULT) as DragonTypes.Stage
	element = DragonTypes.element_for(str(data.get("element", "")))
	dragon_name = clean_name(str(data.get("name", "")), TUNING.max_name_length, "") if data.has("name") else ""
	warmth = clampf(float(data.get("warmth", 0.0)), 0.0, TUNING.warmth_needed)
	bond_level = clampi(int(data.get("bond_level", 1)), 1, TUNING.max_bond())
	bond_xp = maxi(int(data.get("bond_xp", 0)), 0)
	command = clampi(int(data.get("command", 0)), 0, DragonTypes.COMMAND_NAMES.size() - 1) as DragonTypes.Command
	health_ratio = clampf(float(data.get("health", 1.0)), 0.0, 1.0)
	knocked_out_left = clampf(float(data.get("knocked_out", 0.0)), 0.0, TUNING.ko_time)
	last_pet_minute = float(data.get("last_pet", -1.0))
	if is_hatched() and species() == null:
		element = TUNING.species[0].element
	_walked = 0.0
	_last_position = null
	_update_power(false)


## "frost", "wind", "earth" or "light" for an element (saves and sound ids use these words).
static func element_id(type: Elements.Type) -> String:
	for id: String in DragonTypes.ELEMENT_IDS:
		if DragonTypes.ELEMENT_IDS[id] == type:
			return id
	return ""


# --- Inside --------------------------------------------------------------------------------------

func _update_power(announce: bool) -> void:
	PlayerData.set_dragon_power(magic_power_bonus(), announce)


func _on_enemy_defeated(_enemy_id: StringName) -> void:
	if has_egg():
		add_warmth(TUNING.warmth_per_enemy)
	elif is_active():
		add_bond_xp(TUNING.bond_per_fight)  # fighting together


func _count_walking() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		_last_position = null
		return
	var here := player.global_position
	if _last_position is Vector3:
		var last: Vector3 = _last_position
		var step := Vector2(here.x - last.x, here.z - last.z).length()
		if step < MAX_STEP:
			_walked += step
	_last_position = here
	if _walked >= WALK_STEP:
		_walked -= WALK_STEP
		add_warmth(TUNING.warmth_per_100m * WALK_STEP / 100.0)
