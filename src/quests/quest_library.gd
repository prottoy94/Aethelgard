class_name QuestLibrary
extends Resource
## Every quest, so saves and dialogue can refer to quests by id. File: data/quests/quest_library.tres.

@export var quests: Array[QuestData] = []


func find(id: StringName) -> QuestData:
	for quest in quests:
		if quest.id == id:
			return quest
	return null
