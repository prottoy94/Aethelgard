class_name Elements
extends RefCounted
## The elements of Aethelgard's magic (GAME_DESIGN.md §6.2) and their strengths.
## Pairs are easy to remember: Fire↔Frost, Wind↔Earth, Light↔Ember (strong both ways).
## Frost is also strong against Ember (Ignis's corrupted fire); Ember resists pure Fire.

enum Type { NONE, LIGHT, WIND, FROST, EARTH, FIRE, EMBER }

const STRONG := 1.5
const NORMAL := 1.0
const RESISTED := 0.5

## attacker → elements it is strong against
const STRONG_AGAINST := {
	Type.LIGHT: [Type.EMBER],
	Type.EMBER: [Type.LIGHT],
	Type.WIND: [Type.EARTH],
	Type.EARTH: [Type.WIND],
	Type.FIRE: [Type.FROST],
	Type.FROST: [Type.FIRE, Type.EMBER],
}
## attacker → elements that resist it (besides its own element)
const RESISTED_BY := {
	Type.FIRE: [Type.EMBER],
}

const COLORS := {
	Type.NONE: Color("e8e0d0"),
	Type.LIGHT: Color("ffe066"),
	Type.WIND: Color("7ee0c8"),
	Type.FROST: Color("9fd4ff"),
	Type.EARTH: Color("b08050"),
	Type.FIRE: Color("ff8a3c"),
	Type.EMBER: Color("b3202a"),
}


## Damage multiplier for an attack of element `attack` hitting a target of element `defender`.
static func multiplier(attack: Type, defender: Type) -> float:
	if attack == Type.NONE or defender == Type.NONE:
		return NORMAL
	if defender in STRONG_AGAINST.get(attack, []):
		return STRONG
	if attack == defender or defender in RESISTED_BY.get(attack, []):
		return RESISTED
	return NORMAL


static func color(type: Type) -> Color:
	return COLORS.get(type, Color.WHITE)
