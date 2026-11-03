class_name PortraitLibrary
extends Resource
## Portrait styles for every speaker. File: data/dialogue/portraits.tres.

@export var styles: Array[PortraitStyle] = []


func find(character: String) -> PortraitStyle:
	for style in styles:
		if style.character == character:
			return style
	return null
