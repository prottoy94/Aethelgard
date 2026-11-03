extends SceneTree
## Draws labelled placeholder art at the final sizes (TECHNICAL_DESIGN.md §2, §4.15) into
## res://assets/art/placeholders/. Needs no art software; works headless.
##
## Run (from the project folder):
##   godot --headless --path . --script res://tools/placeholders/generate_placeholders.gd
## then `godot --headless --import` so Godot picks up the new PNGs.
## Layouts are documented in res://assets/art/placeholders/README.md.

const OUT := "res://assets/art/placeholders/"
const FRAME := 128
const TILE := 64

const DIRS_8: Array[String] = ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
const DIRS_4: Array[String] = ["down", "right", "up", "left"]
const DIR_LABEL := {
	"down": "D", "down_right": "DR", "right": "R", "up_right": "UR",
	"up": "U", "up_left": "UL", "left": "L", "down_left": "DL",
}

const SHADOW := Color(0, 0, 0, 0.35)
const OUTLINE := Color("1a1424")
const GOLD := Color("e8c66a")

## 5x7 bitmap font so labels can be drawn without a renderer.
const GLYPHS := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"G": ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
	"J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
	"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"N": ["10001", "10001", "11001", "10101", "10011", "10001", "10001"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	"Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
	"X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
	"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
	"3": ["11111", "00010", "00100", "00010", "00001", "10001", "01110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
	"6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
	" ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
	"-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
	".": ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
}

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 7
	_save(_aurelia_sheet(), "characters/aurelia_sheet.png")
	_save(_thornling_sheet(), "enemies/thornling_sheet.png")
	_save(_terrain_atlas(), "tiles/terrain_atlas.png")
	_save(_tree(), "props/tree.png")
	_save(_ruin_pillar(), "props/ruin_pillar.png")
	_save(_lantern_shrine(), "props/lantern_shrine.png")
	_save(_element_icons(), "ui/element_icons.png")
	quit()


# --- Sheets ------------------------------------------------------------------------------

## 8 rows (DIRS_8) x 10 columns: idle 0-3, walk 4-9. Feet at (64, 118) of each frame.
func _aurelia_sheet() -> Image:
	var img := _new(FRAME * 10, FRAME * 8)
	var idle_bob: Array[int] = [0, -1, -2, -1]
	var walk_bob: Array[int] = [0, -3, 0, 0, -3, 0]
	for row in DIRS_8.size():
		var dir := _dir_vector(DIRS_8[row])
		for col in 10:
			var o := Vector2(col * FRAME, row * FRAME)
			var walking := col >= 4
			var step := col - 4
			var bob := walk_bob[step] if walking else idle_bob[col]
			_ellipse(img, o + Vector2(64, 118), 24, 7, SHADOW)
			if walking:  # legs alternate
				var swing := 6.0 if step % 3 == 1 else (-6.0 if step % 3 == 2 else 0.0)
				_rect(img, Rect2i(Vector2i(o + Vector2(52 + swing, 104)), Vector2i(9, 14)), Color("3a2a2a"))
				_rect(img, Rect2i(Vector2i(o + Vector2(67 - swing, 104)), Vector2i(9, 14)), Color("3a2a2a"))
			_ellipse(img, o + Vector2(64, 82 + bob), 24, 30, Color("5b2c4f"))  # cloak
			_ellipse(img, o + Vector2(64, 82 + bob), 24, 30, Color("c9a24a"), true)  # gold trim
			if dir.y >= 0.0:  # front: green dress shows
				_rect(img, Rect2i(Vector2i(o + Vector2(54, 70 + bob)), Vector2i(20, 34)), Color("3f6b46"))
			_circle(img, o + Vector2(64, 44 + bob), 18, Color("dcdce6"))  # silver hair
			if dir.y > -0.5:  # face visible unless facing away
				_circle(img, o + Vector2(64 + dir.x * 6, 47 + bob + dir.y * 3), 10, Color("f2d7c4"))
			var side := -1.0 if dir.x < -0.1 else 1.0
			_line(img, o + Vector2(64 + side * 28, 56 + bob), o + Vector2(64 + side * 28, 116), 4, Color("7a5230"))
			_circle(img, o + Vector2(64 + side * 28, 54 + bob), 5, Color("6fd3ff"))  # staff gem
			_arrow(img, o + Vector2(64, 86 + bob), dir, 28, GOLD)
			_text(img, Vector2i(o) + Vector2i(4, 4), DIR_LABEL[DIRS_8[row]], 2, Color.WHITE)
			_text(img, Vector2i(o) + Vector2i(4, 112), ("W%d" % step) if walking else ("I%d" % col), 1, Color.WHITE)
			_text(img, Vector2i(o) + Vector2i(86, 4), "AUR", 1, GOLD)
	return img


## 4 rows (DIRS_4) x 12 columns: idle 0-3, walk 4-7, attack 8-11 (windup, windup, strike, recover).
func _thornling_sheet() -> Image:
	var img := _new(FRAME * 12, FRAME * 4)
	for row in DIRS_4.size():
		var dir := _dir_vector(DIRS_4[row])
		for col in 12:
			var o := Vector2(col * FRAME, row * FRAME)
			var bob := -2.0 if col % 2 == 1 else 0.0
			var center := o + Vector2(64, 84 + bob)
			_ellipse(img, o + Vector2(64, 114), 26, 7, SHADOW)
			if col == 8 or col == 9:  # telegraph: red ring grows during the wind-up
				_circle(img, center, 36 + (col - 8) * 6, Color(1, 0.2, 0.2, 0.55), true, 4)
			for i in 8:  # thorns
				var a := TAU * i / 8.0
				var d := Vector2.from_angle(a)
				var tip := center + d * 40
				var base_l := center + Vector2.from_angle(a - 0.35) * 24
				var base_r := center + Vector2.from_angle(a + 0.35) * 24
				_poly(img, PackedVector2Array([tip, base_l, base_r]), Color("2e5e2a"))
			_circle(img, center, 27, Color("5aa04a"))
			_circle(img, center + dir * 12, 7, Color("d8342c"))  # eye
			if col == 10:  # strike: long thorn in the facing direction
				_poly(img, PackedVector2Array([center + dir * 62, center + dir * 20 + dir.orthogonal() * 8,
						center + dir * 20 - dir.orthogonal() * 8]), Color("b8e07a"))
			var phase := "I" if col < 4 else ("W" if col < 8 else "A")
			_text(img, Vector2i(o) + Vector2i(4, 4), DIR_LABEL[DIRS_4[row]], 2, Color.WHITE)
			_text(img, Vector2i(o) + Vector2i(4, 112), "%s%d" % [phase, col % 4], 1, Color.WHITE)
			_text(img, Vector2i(o) + Vector2i(80, 4), "THORN", 1, Color("b8e07a"))
	return img


## 4 x 2 tiles of 64 px.
func _terrain_atlas() -> Image:
	var img := _new(TILE * 4, TILE * 2)
	var tiles: Array[Array] = [
		["GRASS", Color("4f8a3c")], ["FLOWERS", Color("4f8a3c")], ["DIRT", Color("9a7b4f")], ["STONE", Color("8d8d96")],
		["WATER", Color("3a8fb7")], ["CLIFF T", Color("6f9a4a")], ["CLIFF F", Color("6e6158")], ["WALL", Color("9b958a")],
	]
	for i in tiles.size():
		var o := Vector2i((i % 4) * TILE, (i / 4) * TILE)
		var base: Color = tiles[i][1]
		_rect(img, Rect2i(o, Vector2i(TILE, TILE)), base)
		match tiles[i][0]:
			"GRASS", "FLOWERS":
				for n in 40:
					_rect(img, Rect2i(o + Vector2i(_rng.randi_range(0, 61), _rng.randi_range(0, 61)), Vector2i(2, 3)), base.darkened(0.25))
				if tiles[i][0] == "FLOWERS":
					for n in 10:
						var c := Color("f4d35e") if n % 2 == 0 else Color("f29ec8")
						_circle(img, Vector2(o) + Vector2(_rng.randi_range(4, 60), _rng.randi_range(4, 60)), 2, c)
			"DIRT":
				for n in 14:
					_circle(img, Vector2(o) + Vector2(_rng.randi_range(3, 61), _rng.randi_range(3, 61)), 2, base.darkened(0.3))
			"STONE", "WALL":
				var h := 16 if tiles[i][0] == "WALL" else 32
				for y in range(0, TILE, h):
					_rect(img, Rect2i(o + Vector2i(0, y), Vector2i(TILE, 2)), base.darkened(0.3))
					var shift := 16 if (y / h) % 2 == 1 else 0
					for x in range(shift, TILE, 32):
						_rect(img, Rect2i(o + Vector2i(x, y), Vector2i(2, h)), base.darkened(0.3))
			"WATER":
				for y in range(8, TILE, 14):
					for x in range(4, TILE - 12, 20):
						_rect(img, Rect2i(o + Vector2i(x + (y % 3) * 3, y), Vector2i(10, 2)), base.lightened(0.35))
			"CLIFF T":
				_rect(img, Rect2i(o + Vector2i(0, 54), Vector2i(TILE, 10)), Color("6e6158"))
				_rect(img, Rect2i(o + Vector2i(0, 52), Vector2i(TILE, 3)), Color("3e3530"))
			"CLIFF F":
				for x in range(6, TILE, 12):
					_rect(img, Rect2i(o + Vector2i(x, 0), Vector2i(2, TILE)), base.darkened(0.3))
		_rect_outline(img, Rect2i(o, Vector2i(TILE, TILE)), base.darkened(0.45))
		_text(img, o + Vector2i(3, 3), tiles[i][0], 1, Color.WHITE)
	return img


# --- Props (origin = feet/base centre, bottom of the image) ------------------------------

func _tree() -> Image:
	var img := _new(128, 192)
	_ellipse(img, Vector2(64, 184), 34, 8, SHADOW)
	_rect(img, Rect2i(55, 116, 18, 70), Color("6b4a2e"))
	for c: Array in [[Vector2(36, 98), 32.0], [Vector2(92, 98), 32.0], [Vector2(64, 70), 50.0]]:
		_circle(img, c[0], c[1], Color("3f7a3a"))
	_circle(img, Vector2(52, 58), 18, Color("5c9a4a"))
	_text(img, Vector2i(4, 4), "TREE", 2, Color.WHITE)
	return img


func _ruin_pillar() -> Image:
	var img := _new(64, 160)
	_ellipse(img, Vector2(32, 154), 26, 6, SHADOW)
	_rect(img, Rect2i(14, 22, 36, 124), Color("a9a39a"))
	_rect(img, Rect2i(8, 12, 48, 14), Color("bdb7ad"))
	_rect(img, Rect2i(8, 140, 48, 14), Color("bdb7ad"))
	for n in 6:
		_circle(img, Vector2(_rng.randi_range(16, 48), _rng.randi_range(30, 140)), _rng.randi_range(3, 6), Color("5c8a3a"))
	_line(img, Vector2(30, 40), Vector2(24, 70), 2, Color("6f6a62"))
	_text(img, Vector2i(3, 30), "PILLAR", 1, Color.WHITE)
	return img


func _lantern_shrine() -> Image:
	var img := _new(64, 128)
	_ellipse(img, Vector2(32, 122), 26, 6, SHADOW)
	_rect(img, Rect2i(10, 100, 44, 22), Color("8d8d96"))
	_rect(img, Rect2i(28, 40, 8, 62), Color("6b4a2e"))
	_circle(img, Vector2(32, 34), 20, Color(1.0, 0.85, 0.4, 0.35))  # glow
	_rect(img, Rect2i(22, 22, 20, 24), Color("3a2a2a"))
	_rect(img, Rect2i(25, 25, 14, 18), Color("ffd27a"))
	_text(img, Vector2i(14, 4), "REST", 1, Color.WHITE)
	return img


## 6 icons of 64 px, each with a distinct SHAPE as well as colour (NFR-ACC-02):
## Light = circle with rays, Wind = triangle, Frost = diamond, Earth = square, Fire = flame, Ember = cross.
func _element_icons() -> Image:
	var img := _new(64 * 6, 64)
	var c := Vector2(32, 28)
	var defs: Array[Array] = [
		["LIGHT", Color("ffe066")], ["WIND", Color("7ee0c8")], ["FROST", Color("9fd4ff")],
		["EARTH", Color("b08050")], ["FIRE", Color("ff8a3c")], ["EMBER", Color("b3202a")],
	]
	for i in defs.size():
		var o := Vector2(i * 64, 0)
		var col: Color = defs[i][1]
		_circle(img, o + c, 26, Color(0.1, 0.08, 0.15, 0.9))
		match defs[i][0]:
			"LIGHT":
				for r in 8:
					_line(img, o + c, o + c + Vector2.from_angle(TAU * r / 8.0) * 20, 3, col)
				_circle(img, o + c, 10, col)
			"WIND":
				_poly(img, PackedVector2Array([o + c + Vector2(0, -18), o + c + Vector2(17, 14), o + c + Vector2(-17, 14)]), col)
			"FROST":
				_poly(img, PackedVector2Array([o + c + Vector2(0, -19), o + c + Vector2(15, 0), o + c + Vector2(0, 19), o + c + Vector2(-15, 0)]), col)
			"EARTH":
				_rect(img, Rect2i(Vector2i(o + c - Vector2(14, 14)), Vector2i(28, 28)), col)
			"FIRE":
				_circle(img, o + c + Vector2(0, 6), 11, col)
				_poly(img, PackedVector2Array([o + c + Vector2(0, -19), o + c + Vector2(11, 4), o + c + Vector2(-11, 4)]), col)
			"EMBER":
				_line(img, o + c + Vector2(-14, -14), o + c + Vector2(14, 14), 6, col)
				_line(img, o + c + Vector2(14, -14), o + c + Vector2(-14, 14), 6, col)
		_text(img, Vector2i(o) + Vector2i(32 - defs[i][0].length() * 3, 56), defs[i][0], 1, Color.WHITE)
	return img


# --- Drawing helpers ---------------------------------------------------------------------

func _new(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _save(img: Image, rel_path: String) -> void:
	var path := OUT + rel_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := img.save_png(path)
	print("%s  %dx%d  %s" % [path, img.get_width(), img.get_height(), error_string(err)])


func _dir_vector(dir: String) -> Vector2:
	var v := Vector2.ZERO
	if dir.contains("up"):
		v.y = -1
	if dir.contains("down"):
		v.y = 1
	if dir.contains("left"):
		v.x = -1
	if dir.contains("right"):
		v.x = 1
	return v.normalized()


func _plot(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if color.a >= 1.0:
		img.set_pixel(x, y, color)
	else:
		img.set_pixel(x, y, img.get_pixel(x, y).blend(color))


func _rect(img: Image, r: Rect2i, color: Color) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_plot(img, x, y, color)


func _rect_outline(img: Image, r: Rect2i, color: Color) -> void:
	_rect(img, Rect2i(r.position, Vector2i(r.size.x, 1)), color)
	_rect(img, Rect2i(r.position + Vector2i(0, r.size.y - 1), Vector2i(r.size.x, 1)), color)
	_rect(img, Rect2i(r.position, Vector2i(1, r.size.y)), color)
	_rect(img, Rect2i(r.position + Vector2i(r.size.x - 1, 0), Vector2i(1, r.size.y)), color)


func _ellipse(img: Image, c: Vector2, rx: float, ry: float, color: Color, ring := false, width := 2.0) -> void:
	for y in range(floori(c.y - ry), ceili(c.y + ry) + 1):
		for x in range(floori(c.x - rx), ceili(c.x + rx) + 1):
			var d := pow((x - c.x) / rx, 2) + pow((y - c.y) / ry, 2)
			if d > 1.0:
				continue
			if ring and d < pow(1.0 - width / minf(rx, ry), 2):
				continue
			_plot(img, x, y, color)


func _circle(img: Image, c: Vector2, r: float, color: Color, ring := false, width := 2.0) -> void:
	_ellipse(img, c, r, r, color, ring, width)


func _poly(img: Image, points: PackedVector2Array, color: Color) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for p in points:
		box = box.expand(p)
	for y in range(floori(box.position.y), ceili(box.end.y) + 1):
		for x in range(floori(box.position.x), ceili(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), points):
				_plot(img, x, y, color)


func _line(img: Image, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var steps := maxi(1, ceili(a.distance_to(b)))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		_circle(img, p, width * 0.5, color)


func _arrow(img: Image, from: Vector2, dir: Vector2, length: float, color: Color) -> void:
	var tip := from + dir * length
	_line(img, from, tip - dir * 6, 3, color)
	var side := dir.orthogonal() * 6
	_poly(img, PackedVector2Array([tip, tip - dir * 10 + side, tip - dir * 10 - side]), color)


func _text(img: Image, pos: Vector2i, text: String, scale: int, color: Color) -> void:
	var x := pos.x
	for ch in text.to_upper():
		var glyph: Array = GLYPHS.get(ch, GLYPHS[" "])
		for row in 7:
			for colm in 5:
				if glyph[row][colm] == "1":
					var p := Vector2i(x + colm * scale, pos.y + row * scale)
					_rect(img, Rect2i(p + Vector2i(1, 1), Vector2i(scale, scale)), OUTLINE)  # shadow
					_rect(img, Rect2i(p, Vector2i(scale, scale)), color)
		x += 6 * scale
