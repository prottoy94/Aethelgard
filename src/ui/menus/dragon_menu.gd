class_name DragonMenu
extends MenuScreen
## The Dragon page of the Tab menu (FR-UI-04): name, element and growth stage, bond level and progress, stats, skills
## (locked ones show the bond level that unlocks them), the command (pick one), feeding a Dragon Treat and renaming.
## Before hatching it shows the egg's warmth. Rebuilt every time it opens (the game is paused while it is open).

const TREAT: ConsumableData = preload("res://data/items/dragon_treat.tres")

var _header: Label
var _egg_label: Label
var _columns: HBoxContainer
var _bond: Label
var _stats: Label
var _skills: Label
var _command_buttons: Array[Button] = []
var _feed_button: Button
var _rename_button: Button
var _message: Label


func title() -> String:
	return "Dragon"


func open() -> void:
	_message.text = ""
	super()


func refresh() -> void:
	if _header == null:
		return
	var hatched := DragonManager.is_hatched()
	_columns.visible = hatched
	_egg_label.visible = not hatched
	if not hatched:
		_header.text = "Dragon egg" if DragonManager.has_egg() else "No dragon yet"
		_egg_label.text = _egg_text()
		return
	var kind := DragonManager.species()
	var stats := DragonManager.stats()
	_header.text = "%s   ·   %s, %s" % [DragonManager.display_name(), kind.display_name,
			DragonTypes.stage_name(DragonManager.stage).to_lower()]
	var needed := DragonManager.TUNING.bond_xp_needed(DragonManager.bond_level)
	_bond.text = "Bond %d / %d   %s   ·   Adds %d Magic Power" % [DragonManager.bond_level,
			DragonManager.TUNING.max_bond(), ("(%d / %d to the next)" % [DragonManager.bond_xp, needed]) if needed > 0 \
			else "(highest bond)", DragonManager.magic_power_bonus()]
	var dragon := get_tree().get_first_node_in_group(&"dragon") as Dragon
	var current := dragon.health.current if dragon else DragonManager.health_ratio * DragonManager.max_health()
	var state := ("Knocked out: back in %d s, or rest at a Lantern Shrine" % ceili(DragonManager.knocked_out_left)) \
			if DragonManager.knocked_out_left > 0.0 else "Ready"
	_stats.text = "%s\n\nHP %d / %d   ·   Bite %d %s   ·   Speed %.1f m/s\n%s" % [kind.description, roundi(current),
			roundi(DragonManager.max_health()), roundi(stats.bite_damage * DragonManager.damage_multiplier()),
			Grimoire._element_name(kind.element), stats.move_speed * _speed_bonus(), state]
	for i in _command_buttons.size():
		_command_buttons[i].button_pressed = i == DragonManager.command
	_skills.text = _skills_text(kind)
	var treats := Inventory.count(TREAT.id)
	_feed_button.text = "Feed a %s  (%d)" % [TREAT.display_name, treats]
	_feed_button.disabled = treats <= 0
	keep_focus(_command_buttons[DragonManager.command])


## Picks a command (the same as pressing G in play).
func set_command(index: int) -> void:
	DragonManager.set_command(index as DragonTypes.Command)
	_message.text = "%s: %s" % [DragonTypes.command_name(index as DragonTypes.Command), DragonTypes.COMMAND_HINTS[index]]
	refresh()


func feed() -> void:
	var reason := DragonManager.feed(TREAT)
	var name_ := DragonManager.display_name()
	match reason:
		&"":
			_message.text = "%s gobbled the %s!" % [name_, TREAT.display_name]
		&"knocked_out":
			_message.text = "%s is knocked out. Let it rest first." % name_
		&"full":
			_message.text = "%s is full and as close to you as can be." % name_
		&"none_left":
			_message.text = "No %ss left. Make them at a crafting kit." % TREAT.display_name
		_:
			_message.text = "That wouldn't help right now."
	if reason != &"":
		AudioManager.play(&"ui_error")
	refresh()


func rename() -> void:
	var text: String = await Cutscene.ask_text("Rename your dragon", DragonManager.display_name(),
			DragonManager.TUNING.max_name_length)
	DragonManager.set_dragon_name(text)
	_message.text = "Your dragon is called %s." % DragonManager.display_name()
	refresh()
	_rename_button.grab_focus.call_deferred()


func _egg_text() -> String:
	if not DragonManager.has_egg():
		return "You don't have a dragon... yet."
	var lines: Array[String] = ["Warmth %d%%" % roundi(DragonManager.warmth_ratio() * 100.0), ""]
	if DragonManager.is_egg_ready():
		lines.append("The egg is glowing. Rest at a Lantern Shrine and it will hatch.")
	else:
		lines.append("Eggs warm to courage and to new roads. Fight, solve puzzles and explore with it.")
		lines.append("When it glows, rest at a Lantern Shrine.")
	return "\n".join(lines)


func _skills_text(kind: DragonSpeciesData) -> String:
	var lines: Array[String] = ["Skills", ""]
	for skill in kind.unlocked_skills(DragonManager.stage, DragonManager.bond_level):
		var extra := "   ·   Cooldown %.0f s" % skill.cooldown if skill.kind == DragonSkillData.Kind.ACTIVE else ""
		lines.append("%s   (%s%s)" % [skill.display_name, skill.kind_name(), extra])
		lines.append(skill.description)
		lines.append("")
	for skill in kind.locked_skills(DragonManager.stage, DragonManager.bond_level):
		lines.append("Locked until bond %d:  %s (%s)" % [skill.bond_required, skill.display_name, skill.kind_name()])
		lines.append(skill.description)
		lines.append("")
	lines.append("Raise the bond by fighting together, feeding treats and petting (E beside it).")
	return "\n".join(lines)


func _speed_bonus() -> float:
	var multiplier := 1.0
	for entry in DragonManager.passives():
		multiplier *= entry.speed_multiplier
	return multiplier


func _build_body() -> void:
	_header = make_label("", 30, INK)
	body.add_child(_header)
	_egg_label = make_label("", 21, INK)
	_egg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_egg_label)
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 28)
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 12)
	_columns.add_child(left)
	_bond = make_label("", 20, GOLD.darkened(0.2))
	left.add_child(_bond)
	_stats = make_label("", 19, INK)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_stats)
	left.add_child(make_label("Command  (G in play)", 19, INK))
	var commands := HBoxContainer.new()
	commands.add_theme_constant_override("separation", 10)
	left.add_child(commands)
	for i in DragonTypes.COMMAND_NAMES.size():
		var button := Button.new()
		button.text = DragonTypes.COMMAND_NAMES[i]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(150, 42)
		style_button(button, 19)
		button.pressed.connect(set_command.bind(i))
		commands.add_child(button)
		_command_buttons.append(button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	left.add_child(actions)
	_feed_button = Button.new()
	_feed_button.custom_minimum_size = Vector2(300, 42)
	style_button(_feed_button, 19)
	_feed_button.pressed.connect(feed)
	actions.add_child(_feed_button)
	_rename_button = Button.new()
	_rename_button.text = "Rename"
	_rename_button.custom_minimum_size = Vector2(150, 42)
	style_button(_rename_button, 19)
	_rename_button.pressed.connect(rename)
	actions.add_child(_rename_button)
	_message = make_label("", 18, GOOD)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_message)
	_skills = make_label("", 18, INK)
	_skills.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skills.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_columns.add_child(_skills)
