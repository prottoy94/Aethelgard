class_name PortraitStyle
extends Resource
## How a speaker's placeholder portrait is drawn (DIALOGUE_DESIGN.md §6): colours and a body shape, with the
## expression from the line's [#mood] tag. Real 512×768 portraits replace these later.

## DRAGON: Sylvaris (skin = scales, hair = horns, outfit = gold); SPIRIT: a shrine voice (skin = its glow);
## HERALD: Ignis (a crown of embers, a high collar); SOLDIER: an Emberbound helmet (hair = the visor glow).
enum Look { ELF, HUMAN, CHILD, ELDER, BUTTERFLY, DRAGON, SPIRIT, HERALD, SOLDIER }

@export var character: String          ## the name used in .dialogue files ("Aurelia", "Maren", ...)
@export var look := Look.HUMAN
@export var skin := Color("f2d3bd")
@export var hair := Color("6b4a32")
@export var outfit := Color("5f7a4a")
@export var background := Color("e9dcc0")
@export var name_color := Color("3b2a1e")
