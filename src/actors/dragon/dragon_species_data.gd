class_name DragonSpeciesData
extends Resource
## One element's pet dragon (GAME_DESIGN.md §8.2, FR-DRG-06): one body shape, recoloured, with its own skills and stats
## per growth stage. Files: data/dragons/<element>.tres, listed in data/dragons/dragon_tuning.tres.

@export var element := Elements.Type.FROST
@export var display_name := "Frost dragon"
@export_multiline var description := ""

@export_group("Colours")
@export var body_color := Color("8fc6ee")
@export var belly_color := Color("e4f3ff")
@export var wing_color := Color("5f9fd6")
@export var horn_color := Color("f4f8ff")
@export var eye_color := Color("1d3557")
@export var breath_color := Color("bfe6ff")

@export_group("Growth and skills")
@export var stages: Array[DragonStageStats] = []
@export var skills: Array[DragonSkillData] = []


## Stats for `stage` (or the closest earlier stage that has some).
func stats_for(stage: DragonTypes.Stage) -> DragonStageStats:
	var best: DragonStageStats = null
	for entry in stages:
		if entry.stage <= stage and (best == null or entry.stage > best.stage):
			best = entry
	return best if best else (stages[0] if not stages.is_empty() else DragonStageStats.new())


func unlocked_skills(stage: DragonTypes.Stage, bond_level: int) -> Array[DragonSkillData]:
	var found: Array[DragonSkillData] = []
	for skill in skills:
		if skill.is_unlocked(stage, bond_level):
			found.append(skill)
	return found


## The breath the player triggers: the last unlocked active skill, or null.
func active_skill(stage: DragonTypes.Stage, bond_level: int) -> DragonSkillData:
	var found: DragonSkillData = null
	for skill in unlocked_skills(stage, bond_level):
		if skill.kind == DragonSkillData.Kind.ACTIVE:
			found = skill
	return found


func passives(stage: DragonTypes.Stage, bond_level: int) -> Array[DragonSkillData]:
	return unlocked_skills(stage, bond_level).filter(func(skill: DragonSkillData) -> bool:
		return skill.kind == DragonSkillData.Kind.PASSIVE)


## Skills of `stage` (and earlier) that are still locked by bond level, for the Dragon menu.
func locked_skills(stage: DragonTypes.Stage, bond_level: int) -> Array[DragonSkillData]:
	var found: Array[DragonSkillData] = []
	for skill in skills:
		if skill.stage <= stage and bond_level < skill.bond_required:
			found.append(skill)
	return found
