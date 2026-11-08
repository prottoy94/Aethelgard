class_name RuneSequence
extends Node
## Runes that must be lit in order (the Gust Trial: "one breath, then two, then three"). A part of a Puzzle: on once
## every rune is lit in the right order. Lighting one out of turn puts them all out again (`wrong`), so the shrine
## teaches its rule by trying. Pure logic, so it can be tested without a scene.

signal state_changed
signal wrong

var runes: Array[TrialRune] = []
var next := 1          ## the order number that must be lit next
var complete := false


func setup(runes_: Array[TrialRune]) -> void:
	runes = runes_
	for rune in runes:
		rune.lit_up.connect(on_lit)


func is_on() -> bool:
	return complete


## A rune was lit: right if it is the next in order.
func on_lit(rune: TrialRune) -> void:
	if complete:
		return
	if rune.order == next:
		next += 1
		complete = next > runes.size()
	else:
		next = 1
		for other in runes:
			if other.is_lit:
				other.fizzle()
		if rune.is_inside_tree():
			AudioManager.play(&"puzzle_rune_wrong", rune.global_position)
		wrong.emit()
	state_changed.emit()


## Already solved (a loaded game): every rune lit, nothing to check.
func set_complete() -> void:
	complete = true
	next = runes.size() + 1
	for rune in runes:
		rune.set_lit(true)
