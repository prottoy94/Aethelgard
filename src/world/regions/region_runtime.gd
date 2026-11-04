class_name RegionRuntime
extends Node
## Everything a playable region needs besides its own world (TECHNICAL_DESIGN.md §4.7): sky, sun and the day/night
## cycle with weather; Aurelia, placed from the SceneLoader arrival, a saved position, a `-- --spawn=<id>` start option
## or the "start" RegionSpawn; the camera, HUD, menus (Tab/Esc), dialogue box, Lumen, toasts and the perf overlay.
## It links the region's NPCs, crafting stations and Lantern Shrines (resting autosaves) by group, and plays the
## region's music and ambience for the time of day and weather, with the combat layer while enemies are engaged.
## Phase 7: spawns the pet dragon beside Aurelia once hatched, and hatches a warm egg when she rests at a shrine.
## A region script builds its world (with RegionSpawn markers), then adds this node and calls start().

signal player_spawned(player: Player)

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const CAMERA_SETTINGS := preload("res://data/camera/follow_camera.tres")
const DAY_NIGHT := preload("res://data/world/day_night.tres")
const ANIM_SET := preload("res://data/animations/humanoid_default.tres")
const PLACEHOLDER := preload("res://src/actors/player/aurelia_placeholder.gd")
const STAND_IN_TINT := Color("7a5a8a")  # plum, like Aurelia's cape
const COMBAT_CHECK := 0.3  ## s between checks for engaged enemies
const RAIN_AMBIENCE: StringName = &"amb_weather_rain"
const TREAT: ConsumableData = preload("res://data/items/dragon_treat.tres")

@export var region_id: StringName

var player: Player
var camera_rig: CameraRig
var hud: Hud
var game_menu: GameMenu
var crafting: CraftingMenu
var dialogue: DialogueBox
var lumen: Lumen
var dragon: Dragon
var cycle: DayNightCycle
var environment: Environment
var sun: DirectionalLight3D
var _toast: Label
var _toast_timer := 0.0
var _animated := false
var _combat_check := 0.0


## The sky, sun, environment and day/night cycle, added under `world`.
func build_sky(world: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.ground_bottom_color = Color(0.2, 0.25, 0.15)
	sky_material.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_aerial_perspective = 0.4
	environment.fog_sky_affect = 0.2
	environment.glow_intensity = 0.9
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.12
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)
	sun = DirectionalLight3D.new()
	world.add_child(sun)
	cycle = DayNightCycle.new()
	cycle.data = DAY_NIGHT
	cycle.sun = sun
	cycle.environment = environment
	cycle.sky = sky_material
	world.add_child(cycle)
	Settings.graphics_changed.connect(_apply_graphics)
	_apply_graphics(Settings.graphics)


## Spawns Aurelia and the interface, and links the region's objects. Call after the world is built.
func start() -> void:
	if SceneLoader.current_region == &"":
		SceneLoader.current_region = region_id  # the scene was started directly (editor, tests)
	var world := get_parent() as Node3D
	_spawn_player(world)
	camera_rig = CameraRig.new()
	camera_rig.settings = CAMERA_SETTINGS
	camera_rig.target = player
	world.add_child(camera_rig)
	player.camera_rig = camera_rig
	camera_rig.set_yaw(player.facing_yaw)  # look the way she arrives
	camera_rig.snap_to_target()
	if cycle:
		cycle.follow = player
	lumen = Lumen.new()
	world.add_child(lumen)
	if DragonManager.is_hatched():
		dragon = Dragon.spawn(world, player)
	hud = Hud.new()
	add_child(hud)
	hud.bind(player)
	game_menu = GameMenu.new()
	add_child(game_menu)
	var inventory_menu := InventoryMenu.new()
	game_menu.add_page(inventory_menu)
	inventory_menu.bind(player)
	game_menu.add_page(Grimoire.new())
	game_menu.add_page(DragonMenu.new())
	game_menu.add_page(JournalMenu.new())
	game_menu.add_page(SaveMenu.new())
	game_menu.add_page(OptionsMenu.new())
	crafting = CraftingMenu.new()
	add_child(crafting)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	_build_toast()
	add_child(PerfOverlay.new())
	_link_world()
	TimeOfDay.hour_changed.connect(_on_hour_changed)
	TimeOfDay.weather_changed.connect(_on_weather_changed)
	update_audio()
	TimeOfDay.running = true
	player_spawned.emit(player)
	_apply_start_options()


func show_toast(text: String, seconds := 6.0) -> void:
	_toast.text = text
	_toast_timer = seconds
	_toast.modulate.a = 1.0


func _process(delta: float) -> void:
	_combat_check -= delta
	if _combat_check <= 0.0 and not get_tree().paused:
		_combat_check = COMBAT_CHECK
		AudioManager.set_combat(get_tree().get_nodes_in_group(&"enemy").any(
				func(enemy: Node) -> bool: return enemy is Enemy and (enemy as Enemy).is_engaged()))
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_V:
		_set_animated(not _animated)


# --- Aurelia -----------------------------------------------------------------------------------

func _spawn_player(world: Node3D) -> void:
	var arrival := SceneLoader.take_arrival()
	var spawn_id: StringName = arrival.get("spawn", &"")
	var state: Dictionary = arrival.get("player", {})
	if spawn_id == &"" and state.is_empty():
		spawn_id = _start_option_spawn()  # a new game or a direct start: `-- --spawn=<id>` may pick the spot
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	var shrine := get_tree().get_first_node_in_group(&"rest_point") as RestPoint
	var spawn := RegionSpawn.find(get_tree(), spawn_id if spawn_id != &"" else &"start")
	if spawn == null:
		spawn = RegionSpawn.find(get_tree(), &"start")
	if spawn:
		player.global_position = spawn.global_position
		player.face_instantly(-spawn.global_basis.z)
	player.respawn_point = shrine.respawn_position() if shrine else player.global_position
	SaveManager.apply_player(player, state, spawn_id == &"")


func _start_option_spawn() -> StringName:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spawn="):
			return StringName(arg.trim_prefix("--spawn="))
	return &""


## Switches Aurelia between the shape placeholder and the animated stand-in (V), until her VRoid model arrives.
func _set_animated(on: bool) -> void:
	_animated = on
	if on:
		var humanoid := HumanoidVisual.new()
		humanoid.model_scene = ANIM_SET.library_scene
		humanoid.anim_set = ANIM_SET
		humanoid.stand_in_tint = STAND_IN_TINT
		player.set_visual(humanoid)
		show_toast("Animated stand-in model (press V to switch back)", 3.0)
	else:
		player.set_visual(PLACEHOLDER.new())
		show_toast("Placeholder Aurelia (press V for the animated stand-in)", 3.0)


# --- Linking the world -------------------------------------------------------------------------

func _link_world() -> void:
	for node in get_tree().get_nodes_in_group(&"npc"):
		(node as Npc).talk_requested.connect(func(who: Npc) -> void: dialogue.start(who.dialogue, who.cue, [who]))
	for node in get_tree().get_nodes_in_group(&"crafting_station"):
		(node as CraftingStation).used.connect(func(_by: Player, at: RecipeData.Station) -> void: crafting.open_station(at))
	for node in get_tree().get_nodes_in_group(&"rest_point"):
		(node as RestPoint).rested.connect(_on_rested)
	PlayerData.tome_found.connect(_on_tome_found)
	Inventory.recipe_learned.connect(_on_recipe_learned)
	QuestManager.quest_started.connect(_on_quest_started)
	DragonManager.egg_received.connect(_on_egg_received)
	DragonManager.egg_ready.connect(_on_egg_ready)
	DragonManager.bond_level_up.connect(_on_bond_level_up)
	DragonManager.skill_unlocked.connect(_on_dragon_skill_unlocked)


## The region's music and ambience for the time of day, and rain sounds when it rains (FR-AUD-07, FR-AUD-09).
func update_audio() -> void:
	var region := SceneLoader.REGIONS.find(region_id)
	if region == null:
		return
	var night := TimeOfDay.is_night()
	AudioManager.play_music(region.music_night if night and region.music_night != &"" else region.music_day)
	AudioManager.set_combat_layer(region.combat_layer)
	AudioManager.play_ambience(region.ambience_night if night and region.ambience_night != &"" else region.ambience_day)
	AudioManager.play_weather(RAIN_AMBIENCE if TimeOfDay.weather == &"rain" else &"")


func _on_hour_changed(_hour: int) -> void:
	update_audio()


func _on_weather_changed(_weather: StringName) -> void:
	update_audio()


func _on_rested(_player: Player, result: Dictionary) -> void:
	DragonManager.rest()
	var lines: Array[String] = ["You rest at the Lantern Shrine. Health and stamina restored."]
	for spell: SpellData in result["learned"]:
		lines.append("You read the tome and learned %s!" % spell.display_name)
	for spell: SpellData in result["blocked"]:
		lines.append("The %s tome is too advanced: it needs Magic Power %d (you have %d)." % [
			spell.display_name, spell.required_magic_power, PlayerData.magic_power])
	if DragonManager.has_egg() and not DragonManager.is_egg_ready():
		lines.append("The dragon egg is warm (%d%%). Fight and explore together to warm it more." % roundi(
				DragonManager.warmth_ratio() * 100.0))
	if SaveManager.autosave():
		lines.append("Game saved.")
	if DragonManager.is_egg_ready() and not Cutscene.is_playing():
		_hatch_egg.call_deferred()
		return
	show_toast("\n".join(lines), 6.0)


## The warm egg hatches here (FR-DRG-01), then the game saves with the new dragon.
func _hatch_egg() -> void:
	await Cutscene.play(&"dragon_hatch")
	dragon = get_tree().get_first_node_in_group(&"dragon") as Dragon
	if DragonManager.is_hatched():
		SaveManager.autosave()
		show_toast("%s hatched!   G: give a command   H: breath skill   Tab: the Dragon page" % DragonManager.display_name(),
				7.0)


func _on_egg_received() -> void:
	show_toast("You received a dragon egg! Fight and explore together to warm it.  (Tab: Dragon page)", 6.0)


func _on_egg_ready() -> void:
	show_toast("The dragon egg is glowing! Rest at a Lantern Shrine.", 6.0)


func _on_bond_level_up(level: int) -> void:
	hud.show_banner("%s's bond grew!   Bond %d" % [DragonManager.display_name(), level])


func _on_dragon_skill_unlocked(skill: DragonSkillData) -> void:
	show_toast("%s learned %s: %s" % [DragonManager.display_name(), skill.display_name, skill.description], 6.0)


func _on_tome_found(spell: SpellData) -> void:
	show_toast("Found the %s tome! Rest at a Lantern Shrine to read it." % spell.display_name, 5.0)


func _on_recipe_learned(recipe: RecipeData) -> void:
	show_toast("Learned a recipe: %s. Make it at the %s." % [recipe.display_name(),
			RecipeData.STATION_NAMES[recipe.station].to_lower()], 5.0)


func _on_quest_started(quest: QuestData) -> void:
	show_toast("New quest: %s  (J: journal)" % quest.title, 4.0)


func _exit_tree() -> void:
	# The autoloads outlive the region: drop the connections made to them.
	for connection in [[PlayerData.tome_found, _on_tome_found], [Inventory.recipe_learned, _on_recipe_learned],
			[QuestManager.quest_started, _on_quest_started], [Settings.graphics_changed, _apply_graphics],
			[DragonManager.egg_received, _on_egg_received], [DragonManager.egg_ready, _on_egg_ready],
			[DragonManager.bond_level_up, _on_bond_level_up], [DragonManager.skill_unlocked, _on_dragon_skill_unlocked],
			[TimeOfDay.hour_changed, _on_hour_changed], [TimeOfDay.weather_changed, _on_weather_changed]]:
		var sig: Signal = connection[0]
		if sig.is_connected(connection[1]):
			sig.disconnect(connection[1])


func _apply_graphics(preset: GraphicsPreset) -> void:
	if environment:
		preset.apply_to_environment(environment)
	if sun:
		preset.apply_to_sun(sun)


func _build_toast() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -160.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.modulate.a = 0.0
	layer.add_child(_toast)


## Test start options: --open=inventory|grimoire|dragon|journal|save|options|crafting, --talk=<npc id>,
## --give=materials|treats, --visual=animated, --hour=<0–24>, --weather=clear|rain|fog,
## --dragon=egg|ready|hatch|frost|wind|earth|light (an egg, a warm egg, the hatching scene right away, or a hatched
## dragon of that element), --autoplay[=<choice>] (conversations advance by themselves; dev tool)
## (--spawn=<id> is read when spawning).
func _apply_start_options() -> void:
	var args := OS.get_cmdline_user_args()
	if "--visual=animated" in args:
		_set_animated(true)
	if "--give=materials" in args:
		for item in Inventory.LIBRARY.items:
			if item.category == ItemData.Category.MATERIAL:
				Inventory.add(item, 5)
	if "--give=treats" in args:
		Inventory.add(TREAT, 5)
	for arg in args:
		if arg.begins_with("--dragon="):
			_start_with_dragon(arg.trim_prefix("--dragon="))
		elif arg == "--autoplay" or arg.begins_with("--autoplay="):
			var autoplay := DialogueAutoplay.new()
			autoplay.choice = maxi(int(arg.trim_prefix("--autoplay=")) - 1, 0) if "=" in arg else 0
			add_child(autoplay)
	var pages := {"inventory": InventoryMenu, "grimoire": Grimoire, "dragon": DragonMenu, "journal": JournalMenu,
			"save": SaveMenu, "options": OptionsMenu}
	for arg in args:
		if arg.begins_with("--hour="):
			TimeOfDay.set_hour(float(arg.trim_prefix("--hour=")))
		elif arg.begins_with("--weather="):
			TimeOfDay.set_weather(StringName(arg.trim_prefix("--weather=")))
			cycle.rain_amount = 1.0 if TimeOfDay.weather == &"rain" else 0.0
			cycle.fog_amount = 1.0 if TimeOfDay.weather == &"fog" else 0.0
		var option := arg.trim_prefix("--open=")
		if arg.begins_with("--open=") and pages.has(option):
			game_menu.open_page.call_deferred(pages[option])
		elif arg == "--open=crafting":
			crafting.open_station.call_deferred(RecipeData.Station.WORKBENCH)
		elif arg.begins_with("--talk="):
			for node in get_tree().get_nodes_in_group(&"npc"):
				var npc := node as Npc
				if String(npc.npc_id) == arg.trim_prefix("--talk="):
					player.global_position = npc.global_position + Vector3(0, 0, 1.6)
					camera_rig.snap_to_target()
					get_tree().create_timer(0.5).timeout.connect(npc.talk.bind(player))


## --dragon=egg (just received), ready (warm: rest at a shrine to hatch it) or an element (already hatched).
func _start_with_dragon(option: String) -> void:
	if DragonManager.stage == DragonTypes.Stage.NONE:
		DragonManager.receive_egg()
		QuestManager.start(&"dragon_egg")
	if option == "egg":
		return
	DragonManager.add_warmth(DragonManager.TUNING.warmth_needed)
	if option == "ready":
		return
	if option == "hatch":
		_hatch_egg.call_deferred()
		return
	DragonManager.choose_element(option)
	DragonManager.hatch()
	if dragon == null:
		dragon = Dragon.spawn(player.get_parent(), player)
