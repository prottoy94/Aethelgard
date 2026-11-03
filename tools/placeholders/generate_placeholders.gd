extends SceneTree
## Draws labelled placeholder 2D UI art (element icons) into res://assets/art/placeholders/.
## The game is 3D now: world and character placeholders are simple 3D shapes built in the levels,
## so the 2D sprite sheets were removed from this script (TECHNICAL_DESIGN.md §4.15). Works headless.
##
## Run (from the project folder):
##   godot --headless --path . --script res://tools/placeholders/generate_placeholders.gd
## then `godot --headless --import` so Godot picks up the new PNGs.
## Layouts are documented in res://assets/art/placeholders/README.md.

const OUT := "res://assets/art/placeholders/"

const OUTLINE := Color("1a1424")

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


func _init() -> void:
	_save(_element_icons(), "ui/element_icons.png")
	quit()


# --- UI ------------------------------------------------------------------------------------

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
