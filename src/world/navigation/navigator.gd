class_name Navigator
extends Node
## "Show the way" (owner request 2026-11-04): press N (gamepad: left stick) and a trail of light runs from Aurelia
## towards her current objective, with a line saying what to do, where and how far. The objective is the tracked
## quest's current step (else the first active quest); its waypoint is looked up in this region, and when it is in
## another region the trail leads to the exit towards it. The map (MapMenu) uses objective() for its star.
## Added by RegionRuntime.

signal shown(objective: Dictionary)

const COOLDOWN := 0.6  ## s between presses

var hud: Hud
var _cooldown := 0.0


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("navigate"):
		show_way()
		get_viewport().set_input_as_handled()


## Shows the trail and the line. Returns the objective (see objective()).
func show_way() -> Dictionary:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null or _cooldown > 0.0:
		return {}
	_cooldown = COOLDOWN
	var goal := objective(get_tree(), player.global_position)
	if hud:
		hud.show_guide(describe(goal))
	if goal.get("position") is Vector3:
		var trail := GuideTrail.new()
		player.get_parent().add_child(trail)
		trail.run(player.global_position, goal["position"])
	AudioManager.play(&"ui_guide")
	shown.emit(goal)
	return goal


## What to do next, as a dictionary: "text" (the step), "quest" (title), "position" (Vector3 or null), "distance",
## "region" (where the target is) and "via" (the exit's destination name when the target is in another region).
static func objective(tree: SceneTree, from: Vector3) -> Dictionary:
	var step := current_step()
	if step.is_empty():
		return {"text": "No quest right now. Explore, or talk to the people of Elderroot.", "quest": "",
				"position": null}
	var quest: QuestData = step["quest"]
	var current: QuestStep = step["step"]
	var goal := {"text": QuestManager.step_text(quest.id), "quest": quest.title, "position": null,
			"region": current.waypoint_region, "via": ""}
	if current.waypoint == &"":
		return goal
	var here := SceneLoader.current_region
	if current.waypoint_region == &"" or current.waypoint_region == here:
		var target := Waypoint.find(tree, current.waypoint, from)
		if target:
			goal["position"] = target.global_position
			goal["distance"] = target.global_position.distance_to(from)
			goal["region"] = here
			return goal
	if current.waypoint_region != &"" and current.waypoint_region != here:
		var exit := exit_to(tree, current.waypoint_region)
		var region := SceneLoader.REGIONS.find(current.waypoint_region)
		goal["via"] = region.display_name if region else String(current.waypoint_region)
		if exit:
			goal["position"] = exit.global_position
			goal["distance"] = exit.global_position.distance_to(from)
	return goal


## {"quest": QuestData, "step": QuestStep} of the tracked quest (or the first active one), or {}.
static func current_step() -> Dictionary:
	var ids: Array[StringName] = []
	if QuestManager.tracked != &"":
		ids.append(QuestManager.tracked)
	for quest in QuestManager.active_quests():
		if not quest.id in ids:
			ids.append(quest.id)
	for id in ids:
		var quest := QuestManager.LIBRARY.find(id)
		var step := QuestManager.current_step(id)
		if quest and step:
			return {"quest": quest, "step": step}
	return {}


## The exit in this scene that leads to `region_id`, or null.
static func exit_to(tree: SceneTree, region_id: StringName) -> RegionExit:
	for node in tree.get_nodes_in_group(&"region_exit"):
		var exit := node as RegionExit
		if exit and exit.target_region == region_id:
			return exit
	return null


## One line for the screen, e.g. "Talk to the Elder in Elderroot Village  ·  go to Elderroot Village  ·  24 m".
static func describe(goal: Dictionary) -> String:
	var parts: Array[String] = [String(goal.get("text", ""))]
	if String(goal.get("via", "")) != "":
		parts.append("go to %s" % goal["via"])
	if goal.has("distance"):
		parts.append("%d m" % roundi(float(goal["distance"])))
	elif goal.get("position") == null and String(goal.get("quest", "")) != "":
		parts.append("look around")
	return "  ·  ".join(parts)
