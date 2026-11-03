class_name NpcLook
extends Resource
## A villager's placeholder look: simple shapes in these colours, at real size. Files: data/npcs/*.tres.

enum Hair { SHORT, LONG, BALD_BEARD, PIGTAILS }
enum Prop { NONE, STAFF, BASKET }

@export var height := 1.65             ## m
@export var robe := Color("6f8a4f")
@export var accent := Color("e9dcc0")  ## apron, sash or collar
@export var skin := Color("f2d3bd")
@export var hair_color := Color("6b4a32")
@export var hair := Hair.SHORT
@export var prop := Prop.NONE
