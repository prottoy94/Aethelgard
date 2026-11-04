class_name DragonTypes
extends RefCounted
## Shared names for the pet dragon (GAME_DESIGN.md §8): growth stages, commands and the four elements Aurelia can
## choose at hatching (approved by the owner 2026-11-04).

enum Stage { NONE, EGG, HATCHLING, JUVENILE, ADULT }
enum Command { FOLLOW, ATTACK, GUARD }

const STAGE_NAMES: Array[String] = ["", "Egg", "Hatchling", "Juvenile", "Adult"]
const COMMAND_NAMES: Array[String] = ["Follow", "Attack", "Guard"]
const COMMAND_HINTS: Array[String] = [
	"Stays close and bites enemies that come after Aurelia.",
	"Goes after Aurelia's target: the last enemy she hit, or the one she aims at.",
	"Stays at Aurelia's side, between her and danger, and catches enemy bolts.",
]
## The elements a dragon can hatch as, and the words dialogue uses for them.
const ELEMENT_IDS := {
	"frost": Elements.Type.FROST, "wind": Elements.Type.WIND, "earth": Elements.Type.EARTH, "light": Elements.Type.LIGHT,
}


static func stage_name(stage: Stage) -> String:
	return STAGE_NAMES[stage]


static func command_name(command: Command) -> String:
	return COMMAND_NAMES[command]


## Element for a dialogue word ("frost"), or NONE.
static func element_for(id: String) -> Elements.Type:
	return ELEMENT_IDS.get(id.to_lower(), Elements.Type.NONE)
