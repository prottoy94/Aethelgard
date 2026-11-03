class_name QuestStep
extends Resource
## One objective of a quest (FR-QST-02). Most finish by themselves from game events; TALK steps are finished by
## the conversation (`do QuestManager.advance(...)` in a .dialogue file).

enum Objective { TALK, COLLECT, DEFEAT, REACH, SOLVE, LEARN_SPELL, FLAG }

@export var description: String     ## shown in the journal and the HUD tracker
@export var objective := Objective.TALK
## What the objective is about: an item id (COLLECT), enemy id (DEFEAT), place id (REACH), puzzle id (SOLVE),
## spell id (LEARN_SPELL) or GameState flag (FLAG). Unused for TALK.
@export var target: StringName
@export var amount := 1             ## items to hold (COLLECT) or enemies to defeat (DEFEAT)


## Shows the counter for steps that count something.
func shows_progress() -> bool:
	return amount > 1 and (objective == Objective.COLLECT or objective == Objective.DEFEAT)
