class_name AureliaOutfit
extends RefCounted
## Dresses the animated stand-in as Aurelia until her VRoid model arrives (Phase 2b), after the owner's design sheet
## (Game Images/white_hair_girl_character.jpeg; mood reference only, everything here is built from simple shapes):
## long silver hair with a crown braid and a beaded braid, elf ears, amber eyes (face after her portrait); a plum hooded capelet and cape with gold trim, a green
## tunic over a cream dress, belts, a strap and a satchel, fingerless gloves, dark leggings and brown boots.
##
## The muscular mannequin mesh is hidden; her slim body and clothes are skinned meshes (SkinnedMeshBuilder) weighted
## to the same skeleton, so they fit at every joint and bend with every animation. Hair, braid, cape, both skirts and
## the satchel hang on extra bone chains with spring-bone physics (ClothRig; values data/animations/aurelia_cloth.tres).
## Positions are in the skeleton's rest space (mannequin units, ~1.83 tall; she faces +Z, +X is her left).

const CLOTH: AureliaClothTuning = preload("res://data/animations/aurelia_cloth.tres")

const HAIR := Color("c9c6d0")         ## silver (painted per vertex: streaks, deeper tips, a ring of shine)
const HAIR_SHADE := Color("9f9aac")   ## the long hair underneath
const HAIR_SHINE := Color("fdfcff")
const HAIR_STREAK := Color("a8a3b4")  ## the fine darker streaks along each strand
const BRAID := Color("c0bdca")
const SKIN := Color("f4c9ba")         ## face and ears (soft toon shader)
const SKIN_BODY := Color("dcb7a6")    ## neck, arms and hands (standard toon, brighter in sun: a deeper tone)
const EYE_WHITE := Color("f7f4f7")
const EYE_SHADOW := Color("cbbcd2")   ## the lid's shadow on the white
const IRIS_TOP := Color("5e3556")     ## violet-brown, under the lid
const IRIS_MID := Color("c7832a")
const IRIS_LOW := Color("fbe68e")     ## glowing gold at the bottom
const IRIS_GLOW := Color("f3b850")    ## the soft ring round the pupil
const IRIS_RIM := Color("5a2b16")
const PUPIL := Color("8c3f1c")
const PUPIL_RING := Color("4a1d0e")
const SPARKLE := Color("ffffff")
const EYE_LINE := Color("2c1714")
const LID_INNER := Color("6e372b")
const LOWER_LID := Color("7a3f33")
const CREASE := Color("cf9586")
const LID_SHADOW := Color("f1bcae")
const BROW := Color("8e797d")
const BLUSH := Color("f7907f")
const BLUSH_LINE := Color("e57b6c")
const CHEEK_LIGHT := Color("fff6f1")
const NOSE_TINT := Color("f6c2b2")
const SKIN_SHADOW := Color("eab0a2")   ## the soft shadow of her hair on her face
const NOSE_LINE := Color("b8705f")
const NOSE_LIGHT := Color("fffaf6")
const LIPS := Color("f2a296")
const LIP_LIGHT := Color("fde5dd")
const MOUTH := Color("9c4945")
const EAR_INNER := Color("eea594")
const PEARL := Color("efebe3")
const PEARL_GREY := Color("c9c6c2")
const CAPE := Color("4b2840")
const GOLD := Color("d4a849")
const DRESS := Color("e6dcc0")
const DRESS_HEM := Color("cdbf9c")
const COAT := Color("2f5a3a")       ## her green tunic (also the hidden mannequin's tint)
const COLLAR := Color("2f292d")
const LEGGINGS := Color("3b2b2e")
const BOOTS := Color("6a4429")
const LEATHER := Color("4e3220")
const SATCHEL := Color("6b4a30")
const GLOVE := Color("4a3022")
const BEAD := Color("8fc4d4")
const THREAD := Color("e0b658")      ## gold embroidery thread
const METAL := Color("c3c7cf")       ## steel buckles and studs
const STRAP_LIGHT := Color("7a5236") ## lighter leather straps on her gloves
const DRESS_LINE := Color("b8996a")  ## the woven lines near the dress's hem
const OUTLINE := 0.012
const FINE_OUTLINE := 0.005
const FACE_OUTLINE := 0.008   ## head and hair: a lighter line than the clothes
## Outlines are this thick from the game camera; up close they thin down to CLOSE_LINES, so faces get fine lines.
## The outline shader keeps a minimum in screen pixels; GAME_PIXEL = one pixel of the game camera at its usual
## distance, in skeleton units.
const CLOSE_LINES := {OUTLINE: 0.004, FINE_OUTLINE: 0.0016, FACE_OUTLINE: 0.0014}
const GAME_PIXEL := 0.0104
## Skin and hair get a line in a darker shade of their own colour instead of near-black (gentler, like the portrait).
const OUTLINE_TINTS := {SKIN: Color("9a5246"), HAIR: Color("5e5260"), HAIR_SHADE: Color("54485a"),
		BRAID: Color("5e5260")}
## Skin, ears, hair and the face paint use the soft toon shader: the tint of their shaded side, how much of the
## light reaches them and how much of it the shaded side keeps.
const SOFT_SHADES := {SKIN: Color("ffd0c8"), EAR_INNER: Color("ffd0c8"), HAIR: Color("cfcbe6"),
		HAIR_SHADE: Color("cfcbe6"), BRAID: Color("cfcbe6")}
const SOFT_LIGHT := 0.38
const SOFT_TINT := 0.4
const SOFT_SHADE := 0.55
const SOFT_RIM := 0.06
const RIM_OVERRIDES := {SKIN_BODY: 0.2}

## Torso cross-sections: height, half-width, half-depth, centre z, weights.
const TORSO := [
	[0.86, 0.15, 0.115, -0.02, {&"Hips": 1.0}],
	[0.95, 0.148, 0.11, -0.02, {&"Hips": 1.0}],
	[1.05, 0.125, 0.09, -0.015, {&"Hips": 0.3, &"Spine": 0.7}],
	[1.12, 0.122, 0.088, -0.01, {&"Spine": 1.0}],
	[1.2, 0.133, 0.097, -0.005, {&"Spine": 0.4, &"Chest": 0.6}],
	[1.28, 0.143, 0.104, 0.0, {&"Chest": 1.0}],
	[1.36, 0.15, 0.096, -0.01, {&"Chest": 0.4, &"UpperChest": 0.6}],
	[1.43, 0.158, 0.085, -0.02, {&"UpperChest": 1.0}],
	[1.49, 0.1, 0.065, -0.04, {&"UpperChest": 0.7, &"Neck": 0.3}],
]
## Her head, relative to the Head bone: height, half-width, half-depth, centre z, front flatness (2 = round, more =
## flatter across the face). After the owner's portrait: full cheeks narrowing to a small, soft chin.
const HEAD_PROFILE := [
	[-0.062, 0.005, 0.005, 0.068, 2.0],
	[-0.059, 0.018, 0.013, 0.066, 2.0],
	[-0.053, 0.031, 0.021, 0.062, 2.1],
	[-0.044, 0.046, 0.031, 0.057, 2.2],
	[-0.032, 0.061, 0.043, 0.051, 2.3],
	[-0.017, 0.075, 0.056, 0.044, 2.4],
	[0.0, 0.087, 0.068, 0.037, 2.5],
	[0.016, 0.096, 0.08, 0.03, 2.7],
	[0.033, 0.102, 0.09, 0.023, 2.9],
	[0.052, 0.105, 0.1, 0.015, 3.0],
	[0.075, 0.107, 0.106, 0.009, 3.0],
	[0.1, 0.108, 0.112, 0.002, 2.8],
	[0.13, 0.109, 0.116, -0.004, 2.4],
	[0.16, 0.107, 0.118, -0.01, 2.0],
	[0.19, 0.1, 0.115, -0.015, 2.0],
	[0.215, 0.088, 0.106, -0.018, 2.0],
	[0.237, 0.068, 0.088, -0.021, 2.0],
	[0.252, 0.04, 0.056, -0.022, 2.0],
	[0.26, 0.01, 0.014, -0.022, 2.0],
]
const HEAD_SCALE := 1.1
const HAIR_CAP_C := Vector3(0, 0.148, -0.022)
const HAIR_CAP_R := Vector3(0.126, 0.132, 0.136)
const EYE_CENTER := Vector2(0.062, 0.084)    ## her left eye, in face coordinates
const EYE_SIZE := Vector2(0.034, 0.0222)    ## half-width; half-height of the opening
const IRIS_SIZE := Vector2(0.0206, 0.0218)
const IRIS_SHIFT := -0.0024                 ## the iris sits a little towards her nose
const EYE_TILT := 0.03                      ## outer corners lifted a touch
const BROW_Y := 0.128
const NOSE_Y := 0.037
const MOUTH_Y := -0.003
const HAIR_SHINE_Y := 0.212                 ## height of the shine band on her hair
## Fringe strands: x at the root (by the parting on her right), x and height of the tip, half-width, extra lift
## (so neighbouring strands overlap instead of cutting through each other).
const BANGS := [
	[-0.05, -0.106, 0.092, 0.017, 0.0],
	[-0.049, -0.094, 0.112, 0.016, 0.004],
	[-0.048, -0.081, 0.13, 0.017, 0.001],
	[-0.046, -0.068, 0.138, 0.016, 0.005],
	[-0.044, -0.056, 0.126, 0.015, 0.002],
	[-0.041, -0.043, 0.136, 0.015, 0.006],
	[-0.038, -0.03, 0.13, 0.014, 0.003],
	[-0.035, -0.016, 0.098, 0.01, 0.008],
	[-0.032, -0.003, 0.118, 0.013, 0.004],
	[-0.03, 0.009, 0.104, 0.009, 0.009],
	[-0.029, 0.022, 0.132, 0.016, 0.005],
	[-0.026, 0.036, 0.14, 0.017, 0.001],
	[-0.023, 0.05, 0.13, 0.017, 0.006],
	[-0.019, 0.064, 0.137, 0.016, 0.002],
	[-0.014, 0.077, 0.124, 0.016, 0.007],
	[-0.009, 0.09, 0.11, 0.016, 0.003],
	[-0.004, 0.102, 0.094, 0.015, 0.0],
]
## Face-framing locks (physics chains) from the temple down past her chin; her right one is tied with a gold cuff.
const LOCK_LEFT := [Vector3(0.11, 0.12, 0.062), Vector3(0.105, 0.045, 0.07), Vector3(0.09, -0.035, 0.074),
		Vector3(0.1, -0.105, 0.076)]
const LOCK_RIGHT := [Vector3(-0.112, 0.12, 0.06), Vector3(-0.108, 0.04, 0.068), Vector3(-0.098, -0.045, 0.074),
		Vector3(-0.108, -0.125, 0.076)]
## Hair panels over the sides of her head, front to back.
const SIDE_HAIR := [[0.046, -0.06], [0.026, -0.085], [0.006, -0.07], [-0.016, -0.095], [-0.04, -0.08]]  ## depth, end height
## The crown braid along the right of her head, and the beaded braid it becomes behind her ear (a physics chain).
const CROWN_BRAID := [Vector3(-0.04, 0.276, 0.03), Vector3(-0.08, 0.258, 0.024), Vector3(-0.112, 0.214, 0.006),
		Vector3(-0.127, 0.158, -0.026), Vector3(-0.12, 0.102, -0.062), Vector3(-0.1, 0.066, -0.09)]
const BRAID_CHAIN := [Vector3(-0.106, 0.066, -0.075), Vector3(-0.138, -0.05, -0.1), Vector3(-0.155, -0.18, -0.12),
		Vector3(-0.165, -0.31, -0.13), Vector3(-0.17, -0.43, -0.13)]
const CROWN_STRANDS := 13  ## strands from the crown down the back and sides
const HAIR_ANGLES := [110.0, 130.0, 155.0, 180.0, 205.0, 230.0, 250.0]  ## degrees around her head, 0 = front
const HAIR_DROP := [0.0, 0.14, 0.3, 0.46, 0.62]
const HAIR_BACK := [0.126, 0.15, 0.11, 0.09, 0.09]  ## how far each row hangs behind her (close to the back)
const CAPE_COLUMNS := [-1.0, -0.5, 0.0, 0.5, 1.0]
const CAPELET_ROWS := [0.0, 0.3, 0.55, 0.8, 1.0, 1.06]  ## neck to hem, then the gold trim
const TUNIC_CHAINS := 8   ## spread from 35° to 325°: open at the front
const SKIRT_CHAINS := 5   ## the cream front panel showing through the tunic's opening, from -60° to 60°


static func dress(visual: HumanoidVisual) -> void:
	if visual.skeleton == null:
		return
	Tailor.new(visual.skeleton).sew()


class Tailor:
	var sk: Skeleton3D
	var head := Vector3.ZERO
	var hair_chains: Array[PackedInt32Array] = []
	var lock_chains: Array[PackedInt32Array] = []
	var braid := PackedInt32Array()
	var cape_chains: Array[PackedInt32Array] = []
	var tunic_chains: Array[PackedInt32Array] = []
	var skirt_chains: Array[PackedInt32Array] = []
	var satchel := PackedInt32Array()
	var _builders := {}
	var _strands := 0  ## hair clumps made so far (each gets its own streak and shine placement)

	func _init(skeleton: Skeleton3D) -> void:
		sk = skeleton
		head = sk.get_bone_global_rest(bone(&"Head")).origin

	func sew() -> void:
		for child in sk.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = false  # the mannequin's own body
		_add_chains()
		_body()
		_face()
		_hair()
		_upper_clothes()
		_cape()
		_skirts()
		_belts_and_gear()
		_finish()
		_physics()

	# --- Helpers ------------------------------------------------------------------------------------------

	func bone(bone_name: StringName) -> int:
		return sk.find_bone(bone_name)

	func side_bone(s: float, base: String) -> int:
		return bone(StringName(("Left" if s > 0.0 else "Right") + base))

	## {&"Hips": 0.5, ...} or {bone_index: 0.5, ...} -> {bone_index: weight}
	func w(pairs: Dictionary) -> Dictionary:
		var out := {}
		for key: Variant in pairs:
			out[bone(key) if key is StringName else int(key)] = pairs[key]
		return out

	## The mesh for one colour and outline (or a named one, e.g. the face paint).
	func mesh(color: Color, outline := OUTLINE, key := "") -> SkinnedMeshBuilder:
		var id := key if not key.is_empty() else "%s|%s" % [color.to_html(), outline]
		if not _builders.has(id):
			_builders[id] = [SkinnedMeshBuilder.new(), color, outline]
		return _builders[id][0]

	func ring(center: Vector3, axis: Vector3, radius: Vector2, front: Vector3, weights: Variant,
			ring_color: Variant = null, power := 2.0) -> Dictionary:
		return SkinnedMeshBuilder.ring(center, axis, radius, front, weights, ring_color, power)

	func rest(b: int) -> Vector3:
		return sk.get_bone_global_rest(b).origin

	func torso_at(y: float) -> Array:
		for i in TORSO.size() - 1:
			var a: Array = TORSO[i]
			var b: Array = TORSO[i + 1]
			if y <= b[0] or i == TORSO.size() - 2:
				var t := clampf(inverse_lerp(a[0], b[0], y), 0.0, 1.0)
				return [lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t),
						ClothRig.mix(w(a[4]), w(b[4]), t)]
		return []

	## Point on the torso surface at height y and side position x (front if `front`, else back), lifted by `lift`.
	func torso_surface(y: float, x: float, front: bool, lift: float) -> Vector3:
		var t := torso_at(y)
		var k := sqrt(maxf(0.0, 1.0 - pow(x / t[0], 2.0)))
		return Vector3(x, y, t[2] + (t[1] * k + lift) * (1.0 if front else -1.0))

	## Position `s` segments down a chain (extrapolates past the tip).
	func chain_pos(chain: PackedInt32Array, s: float) -> Vector3:
		var segments := chain.size() - 1
		var j := clampi(floori(s), 0, segments - 1)
		return rest(chain[j]).lerp(rest(chain[j + 1]), s - j)

	## Point between chains (u = chain index, fractions go round towards the next chain) `s` segments down.
	func cloth_point(chains: Array, u: float, s: float, center: Vector3) -> Vector3:
		var n := chains.size()
		var c := posmod(floori(u), n)
		var a := u - floorf(u)
		var p0 := chain_pos(chains[c], s)
		var p1 := chain_pos(chains[mini(c + 1, n - 1) if u < n - 1 else posmod(c + 1, n)], s)
		var d0 := Vector2(p0.x - center.x, p0.z - center.z)
		var d1 := Vector2(p1.x - center.x, p1.z - center.z)
		var angle := lerp_angle(atan2(d0.x, d0.y), atan2(d1.x, d1.y), a)
		var r := lerpf(d0.length(), d1.length(), a)
		return Vector3(center.x + sin(angle) * r, lerpf(p0.y, p1.y, a), center.z + cos(angle) * r)

	func cloth_weights(chains: Array, u: float, s: float, parent: int) -> Dictionary:
		var n := chains.size()
		var c := posmod(floori(u), n)
		var c1 := mini(c + 1, n - 1) if u < n - 1 else posmod(c + 1, n)
		var a := u - floorf(u)
		return ClothRig.mix(ClothRig.chain_weights(chains[c], s, parent),
				ClothRig.chain_weights(chains[c1], s, parent), a)

	## A sheet over chains, sampled at columns `us` and rows `ss`. `jag` lengthens every other column's last row.
	## `tint` (optional): Callable(point: Vector3, across: float) -> Color for vertex colours.
	func chain_sheet(b: SkinnedMeshBuilder, chains: Array, parent: int, center: Vector3, us: Array, ss: Array,
			outward_from: Vector3, jag := 0.0, ridge := 0.0, tint: Variant = null) -> void:
		var points := []
		var weights := []
		var colors := []
		for r in ss.size():
			var row_p := []
			var row_w := []
			var row_c := []
			for ci in us.size():
				var s: float = ss[r]
				if r == ss.size() - 1 and ci % 2 == 0:
					s += jag
				var p := cloth_point(chains, us[ci], s, center)
				if ridge != 0.0 and ci % 2 == 1:  # strands: every other column stands out a little
					p += Vector3(p.x - center.x, 0.0, p.z - center.z).normalized() * ridge
				row_p.append(p)
				row_w.append(cloth_weights(chains, us[ci], s, parent))
				if tint is Callable:  # colour by position and by place across the sheet (0..1)
					row_c.append((tint as Callable).call(p, float(ci) / maxf(us.size() - 1.0, 1.0)))
			points.append(row_p)
			weights.append(row_w)
			colors.append(row_c)
		b.add_sheet(points, weights, outward_from, true, colors if tint is Callable else [])

	## A thin strip lying on a surface along `uv` points (band coordinates: u along 0..1, v across -1..1), mapped by
	## `at` (Callable(u: float, v: float) -> [position, outward normal, weights]) and lifted off it a little: thread,
	## seams and trim. `widths`: one width, or an Array with a width per point.
	func stitch(b: SkinnedMeshBuilder, at: Callable, uv: Array, widths: Variant, lift := 0.0035) -> void:
		var n := uv.size()
		var samples := []
		for q: Vector2 in uv:
			samples.append(at.call(q.x, q.y))
		var rows := [[], []]
		var ws := [[], []]
		var mid := Vector3.ZERO
		var out := Vector3.ZERO
		for i in n:
			var p: Vector3 = samples[i][0]
			var normal: Vector3 = samples[i][1]
			var along: Vector3 = (samples[mini(i + 1, n - 1)][0] as Vector3) - (samples[maxi(i - 1, 0)][0] as Vector3)
			var half: float = (float(widths[i]) if widths is Array else float(widths)) * 0.5
			var side := along.cross(normal).normalized() * half
			rows[0].append(p + normal * lift + side)
			rows[1].append(p + normal * lift - side)
			ws[0].append(samples[i][2])
			ws[1].append(samples[i][2])
			mid += p
			out += normal
		b.add_sheet(rows, ws, mid / n - out.normalized() * 0.5, false)

	## Gold scrollwork along a band of cloth, like the embroidery on her design sheet: a fine border along each side
	## and a running vine between them with a curl at every turn. `at` maps band coordinates onto the cloth, as for
	## stitch(); the band's length and width are measured from it, so curls stay round on any band.
	func embroider(at: Callable, borders := true, lift := 0.0035) -> void:
		var b := mesh(THREAD, 0.0)
		var length := 0.0
		var last: Vector3 = at.call(0.0, 0.0)[0]
		for k in range(1, 21):
			var q: Vector3 = at.call(k / 20.0, 0.0)[0]
			length += q.distance_to(last)
			last = q
		var width: float = (at.call(0.5, -1.0)[0] as Vector3).distance_to(at.call(0.5, 1.0)[0])
		var thread := clampf(width * 0.07, 0.0016, 0.0035)
		if borders:
			for v: float in [-0.95, 0.95]:
				var line := []
				for u: float in steps(0.0, 1.0, 1.0 / maxf(ceilf(length / 0.025), 2.0)):
					line.append(Vector2(u, v))
				stitch(b, at, line, thread * 0.8, lift)
		var waves := maxi(roundi(length / (width * 1.5)), 1)
		var vine := []
		for i in waves * 12 + 1:
			var u := float(i) / (waves * 12)
			vine.append(Vector2(u, 0.4 * sin(u * waves * TAU)))
		stitch(b, at, vine, thread, lift)
		var radius := width * 0.17
		for k in waves * 2:  # a curl at every crest of the vine, turning in towards the middle of the band
			var up := 1.0 if k % 2 == 0 else -1.0
			var u0 := (floorf(k / 2.0) + (0.25 if up > 0.0 else 0.75)) / waves
			var crest := Vector2(u0 * length, up * 0.4 * width * 0.5)
			var center := crest + Vector2(0.35 * radius, -up * 0.95 * radius)
			var d0 := center.distance_to(crest)
			var a0 := (crest - center).angle()
			var curl := []
			var curl_w := []
			for j in 13:
				var f := j / 12.0
				var q := center + Vector2.from_angle(a0 - up * f * 1.7 * PI) * d0 * (1.0 - 0.62 * f)
				curl.append(Vector2(q.x / length, q.y / (width * 0.5)))
				curl_w.append(thread * lerpf(1.0, 0.45, f))
			stitch(b, at, curl, curl_w, lift)

	## Band coordinates on a chain sheet: along the columns u0..u1, across the rows s0..s1; or (`down`) along the rows
	## s0..s1, across the columns u0..u1.
	func sheet_band(chains: Array, parent: int, center: Vector3, u0: float, u1: float, s0: float, s1: float,
			down := false) -> Callable:
		return func(bu: float, bv: float) -> Array:
			var a := (bv + 1.0) * 0.5
			var u := lerpf(u0, u1, a if down else bu)
			var sv := lerpf(s0, s1, bu if down else a)
			var q := cloth_point(chains, u, sv, center)
			return [q, Vector3(q.x - center.x, 0.0, q.z - center.z).normalized(), cloth_weights(chains, u, sv, parent)]

	## Band coordinates on the front of her torso: along y0..y1, across x0..x1.
	func torso_band(x0: float, x1: float, y0: float, y1: float) -> Callable:
		return func(bu: float, bv: float) -> Array:
			var y := lerpf(y0, y1, bu)
			var x := lerpf(x0, x1, (bv + 1.0) * 0.5)
			var info := torso_at(y)
			var q := torso_surface(y, x, true, 0.0)
			return [q, Vector3(x / pow(info[0], 2.0), 0.0, (q.z - info[2]) / pow(info[1], 2.0)).normalized(), info[3]]

	## A steel buckle facing `normal`: an open frame (`size` wide and tall) with a prong across it.
	func buckle(center: Vector3, normal: Vector3, up: Vector3, size: Vector2, weights: Variant) -> void:
		var m := mesh(METAL, FINE_OUTLINE)
		var side := up.cross(normal).normalized()
		var basis := Basis(side, normal.cross(side).normalized(), normal)
		var bar := 0.0045
		var c := center + normal * 0.002
		m.add_box(c + basis.y * (size.y - bar) * 0.5, Vector3(size.x, bar, 0.004), weights, basis)
		m.add_box(c - basis.y * (size.y - bar) * 0.5, Vector3(size.x, bar, 0.004), weights, basis)
		m.add_box(c + side * (size.x - bar) * 0.5, Vector3(bar, size.y, 0.004), weights, basis)
		m.add_box(c - side * (size.x - bar) * 0.5, Vector3(bar, size.y, 0.004), weights, basis)
		m.add_box(c + side * size.x * 0.08, Vector3(size.x * 0.62, bar * 0.6, 0.003), weights, basis)  # prong

	## A small steel stud.
	func stud(center: Vector3, weights: Variant, size := 0.005) -> void:
		mesh(METAL, 0.0).add_ellipsoid(center, Vector3.ONE * size, weights, Basis(), 4)

	static func steps(from: float, to: float, step: float) -> Array:
		var out := []
		var v := from
		while v < to - 0.0001:
			out.append(v)
			v += step
		out.append(to)
		return out

	# --- Physics chains -----------------------------------------------------------------------------------

	func _add_chains() -> void:
		var head_bone := bone(&"Head")
		for i in HAIR_ANGLES.size():
			var a := deg_to_rad(HAIR_ANGLES[i])
			var points := []
			for k in HAIR_DROP.size():
				var y: float = head.y + 0.12 * HEAD_SCALE - HAIR_DROP[k]
				if k == 0:  # on the hair cap, at its widest
					points.append(Vector3(sin(a) * 0.12, 0.0, (HAIR_CAP_C.z + cos(a) * 0.128)) * HEAD_SCALE + Vector3(0, y, head.z))
				else:
					points.append(Vector3(sin(a) * (0.19 + 0.015 * k), y, head.z - 0.03 + cos(a) * HAIR_BACK[k]))
			hair_chains.append(ClothRig.add_chain(sk, head_bone, "Hair%d" % i, points))
		for s: float in [1.0, -1.0]:
			var pts := []
			for q: Vector3 in (LOCK_LEFT if s > 0.0 else LOCK_RIGHT):
				pts.append(head + q * HEAD_SCALE)
			lock_chains.append(ClothRig.add_chain(sk, head_bone, "Lock%s" % ("L" if s > 0.0 else "R"), pts))
		var braid_pts := []
		for q: Vector3 in BRAID_CHAIN:
			braid_pts.append(head + q * HEAD_SCALE)
		braid = ClothRig.add_chain(sk, head_bone, "Braid", braid_pts)
		var upper_chest := bone(&"UpperChest")
		for i in CAPE_COLUMNS.size():
			var u: float = CAPE_COLUMNS[i]
			var points := []
			for k in 5:
				var t := k / 4.0
				points.append(Vector3(u * (0.17 + 0.16 * t), 1.45 - t * 1.07, -0.125 + 0.04 * u * u - 0.22 * t))
			cape_chains.append(ClothRig.add_chain(sk, upper_chest, "Cape%d" % i, points))
		var hips := bone(&"Hips")
		for i in TUNIC_CHAINS:
			var a := deg_to_rad(lerpf(35.0, 325.0, float(i) / (TUNIC_CHAINS - 1)))
			var points := []
			for k in 4:
				var t := k / 3.0
				points.append(Vector3(sin(a) * (0.172 + 0.135 * t), 0.98 - 0.58 * t, -0.02 + cos(a) * (0.13 + 0.125 * t)))
			tunic_chains.append(ClothRig.add_chain(sk, hips, "Tunic%d" % i, points))
		for i in SKIRT_CHAINS:
			var a := deg_to_rad(lerpf(-60.0, 60.0, float(i) / (SKIRT_CHAINS - 1)))
			var points := []
			for k in 3:
				var t := k / 2.0
				points.append(Vector3(sin(a) * (0.158 + 0.075 * t), 0.95 - 0.42 * t, -0.02 + cos(a) * (0.118 + 0.07 * t)))
			skirt_chains.append(ClothRig.add_chain(sk, hips, "Skirt%d" % i, points))
		satchel = ClothRig.add_chain(sk, hips, "Satchel", [Vector3(0.205, 0.97, 0.075), Vector3(0.245, 0.86, 0.09),
				Vector3(0.25, 0.75, 0.092)])

	# --- Body ---------------------------------------------------------------------------------------------

	func _body() -> void:
		var rings := []
		for row: Array in TORSO:
			rings.append(ring(Vector3(0, row[0], row[3]), Vector3.UP, Vector2(row[1], row[2]), Vector3.BACK, w(row[4])))
		mesh(COAT).add_tube(rings, true, true)
		mesh(SKIN_BODY).add_tube([
				ring(Vector3(0, 1.45, -0.055), Vector3.UP, Vector2(0.037, 0.036), Vector3.BACK,
						w({&"UpperChest": 0.4, &"Neck": 0.6})),
				ring(Vector3(0, 1.6, -0.07), Vector3.UP, Vector2(0.035, 0.034), Vector3.BACK, w({&"Neck": 0.3, &"Head": 0.7}))])
		for s: float in [1.0, -1.0]:
			_arm(s)
			_leg(s)

	func _arm(s: float) -> void:
		var axis := Vector3(s, 0, 0)
		var sh := side_bone(s, "Shoulder")
		var ua := side_bone(s, "UpperArm")
		var la := side_bone(s, "LowerArm")
		var hand := side_bone(s, "Hand")
		var y := 1.474
		var z := 0.024
		var f := Vector3.BACK
		mesh(DRESS).add_tube([  # puffed cream sleeve
				ring(Vector3(s * 0.16, y - 0.03, z), axis, Vector2(0.045, 0.055), f, {sh: 0.6, ua: 0.4}),
				ring(Vector3(s * 0.24, y - 0.016, z), axis, Vector2(0.056, 0.062), f, {ua: 1.0}),
				ring(Vector3(s * 0.33, y - 0.004, z), axis, Vector2(0.073, 0.075), f, {ua: 1.0}),
				ring(Vector3(s * 0.43, y, z), axis, Vector2(0.06, 0.062), f, {ua: 1.0}),
				ring(Vector3(s * 0.5, y, z), axis, Vector2(0.047, 0.05), f, {ua: 0.55, la: 0.45})], true, false)
		mesh(LEATHER).add_tube([  # leather bracer at the sleeve's end, studded with steel
				ring(Vector3(s * 0.478, y, z), axis, Vector2(0.05, 0.053), f, {ua: 0.6, la: 0.4}),
				ring(Vector3(s * 0.518, y, z), axis, Vector2(0.05, 0.053), f, {ua: 0.45, la: 0.55})], true, true, 12, 0.0, 0.0)
		for k in 4:
			var a := lerpf(0.35, 2.4, k / 3.0)  # round the outer side of the arm
			stud(Vector3(s * 0.498, y + cos(a) * 0.051, z + sin(a) * 0.054), {ua: 0.5, la: 0.5}, 0.0045)
		mesh(SKIN_BODY).add_tube([
				ring(Vector3(s * 0.5, y, z), axis, Vector2(0.041, 0.043), f, {ua: 0.5, la: 0.5}),
				ring(Vector3(s * 0.61, y, z), axis, Vector2(0.037, 0.039), f, {la: 1.0})])
		var fingers_base := w({StringName(("Left" if s > 0.0 else "Right") + "MiddleProximal"): 0.4,
				StringName(("Left" if s > 0.0 else "Right") + "IndexProximal"): 0.2,
				StringName(("Left" if s > 0.0 else "Right") + "RingProximal"): 0.25,
				StringName(("Left" if s > 0.0 else "Right") + "LittleProximal"): 0.15})
		mesh(GLOVE).add_tube([  # fingerless glove with a cuff
				ring(Vector3(s * 0.6, y, z), axis, Vector2(0.042, 0.044), f, {la: 1.0}),
				ring(Vector3(s * 0.62, y, z), axis, Vector2(0.049, 0.051), f, {la: 1.0}),
				ring(Vector3(s * 0.64, y, z), axis, Vector2(0.041, 0.043), f, {la: 1.0}),
				ring(Vector3(s * 0.76, y, z + 0.004), axis, Vector2(0.033, 0.037), f, {la: 0.8, hand: 0.2}),
				ring(Vector3(s * 0.79, y + 0.002, 0.033), axis, Vector2(0.03, 0.042), f, {hand: 1.0}),
				ring(Vector3(s * 0.86, y + 0.004, 0.034), axis, Vector2(0.025, 0.047), f, {hand: 1.0}),
				ring(Vector3(s * 0.925, y + 0.006, 0.033), axis, Vector2(0.02, 0.043), f, fingers_base)])
		mesh(STRAP_LIGHT).add_tube([  # strap round the glove's wrist, with a stud
				ring(Vector3(s * 0.735, y, z + 0.003), axis, Vector2(0.037, 0.041), f, {la: 0.9, hand: 0.1}),
				ring(Vector3(s * 0.752, y, z + 0.003), axis, Vector2(0.037, 0.041), f, {la: 0.85, hand: 0.15})], true, true, 12, 0.0, 0.0)
		stud(Vector3(s * 0.744, y + 0.03, z + 0.03), {la: 0.9, hand: 0.1}, 0.004)
		var side := "Left" if s > 0.0 else "Right"
		mesh(SKIN_BODY).add_tube([
				ring(Vector3(s * 0.915, y + 0.006, 0.033), axis, Vector2(0.018, 0.041), f, fingers_base),
				ring(Vector3(s * 0.955, y + 0.005, 0.032), axis, Vector2(0.016, 0.039), f,
						w({StringName(side + "MiddleIntermediate"): 0.4, StringName(side + "IndexIntermediate"): 0.2,
						StringName(side + "RingIntermediate"): 0.25, StringName(side + "LittleIntermediate"): 0.15})),
				ring(Vector3(s * 0.99, y + 0.004, 0.03), axis, Vector2(0.013, 0.035), f,
						w({StringName(side + "MiddleDistal"): 0.4, StringName(side + "IndexDistal"): 0.2,
						StringName(side + "RingDistal"): 0.25, StringName(side + "LittleDistal"): 0.15}))], false, true)
		var meta := bone(StringName(side + "ThumbMetacarpal"))
		var prox := bone(StringName(side + "ThumbProximal"))
		var dist := bone(StringName(side + "ThumbDistal"))
		var thumb_dir := Vector3(0.82 * s, 0, 0.58)
		mesh(GLOVE).add_tube([
				ring(rest(meta), thumb_dir, Vector2(0.018, 0.018), Vector3.UP, {meta: 1.0}),
				ring(rest(prox) + thumb_dir * 0.01, thumb_dir, Vector2(0.017, 0.017), Vector3.UP, {prox: 1.0})], true, false)
		mesh(SKIN_BODY).add_tube([
				ring(rest(prox), thumb_dir, Vector2(0.016, 0.016), Vector3.UP, {prox: 1.0}),
				ring(rest(dist), thumb_dir, Vector2(0.015, 0.015), Vector3.UP, {dist: 1.0}),
				ring(rest(dist) + thumb_dir * 0.03, thumb_dir, Vector2(0.012, 0.012), Vector3.UP, {dist: 1.0})], false, true)

	func _leg(s: float) -> void:
		var x := s * 0.089
		var ul := side_bone(s, "UpperLeg")
		var ll := side_bone(s, "LowerLeg")
		var foot := side_bone(s, "Foot")
		var toes := side_bone(s, "Toes")
		var hips := bone(&"Hips")
		var down := Vector3.DOWN
		var f := Vector3.BACK
		mesh(LEGGINGS).add_tube([
				ring(Vector3(x, 0.93, -0.01), down, Vector2(0.072, 0.085), f, {hips: 0.5, ul: 0.5}),
				ring(Vector3(x, 0.85, 0.0), down, Vector2(0.085, 0.088), f, {ul: 1.0}),
				ring(Vector3(x, 0.7, 0.0), down, Vector2(0.075, 0.078), f, {ul: 1.0}),
				ring(Vector3(x, 0.56, 0.0), down, Vector2(0.059, 0.061), f, {ul: 0.5, ll: 0.5}),
				ring(Vector3(x, 0.46, -0.006), down, Vector2(0.055, 0.061), f, {ll: 1.0}),
				ring(Vector3(x, 0.34, -0.01), down, Vector2(0.047, 0.049), f, {ll: 1.0})])
		mesh(BOOTS).add_tube([
				ring(Vector3(x, 0.375, -0.012), down, Vector2(0.06, 0.063), f, {ll: 1.0}),
				ring(Vector3(x, 0.33, -0.012), down, Vector2(0.064, 0.067), f, {ll: 1.0}),
				ring(Vector3(x, 0.315, -0.012), down, Vector2(0.053, 0.056), f, {ll: 1.0}),
				ring(Vector3(x, 0.2, -0.02), down, Vector2(0.049, 0.052), f, {ll: 1.0}),
				ring(Vector3(x, 0.12, -0.03), down, Vector2(0.05, 0.055), f, {ll: 0.5, foot: 0.5})], true, false)
		mesh(LEATHER).add_tube([  # buckled strap round the boot
				ring(Vector3(x, 0.255, -0.016), down, Vector2(0.053, 0.056), f, {ll: 1.0}),
				ring(Vector3(x, 0.235, -0.017), down, Vector2(0.053, 0.056), f, {ll: 1.0})], true, true, 12, 0.0, 0.0)
		buckle(Vector3(x + s * 0.053, 0.245, -0.016), Vector3(s, 0, 0), Vector3.UP, Vector2(0.022, 0.024), {ll: 1.0})
		mesh(LEATHER).add_tube([  # folded boot cuff
				ring(Vector3(x, 0.38, -0.012), down, Vector2(0.066, 0.069), f, {ll: 1.0}),
				ring(Vector3(x, 0.345, -0.012), down, Vector2(0.069, 0.072), f, {ll: 1.0})], true, true, 12, 0.0, 0.0)
		var fwd := Vector3.BACK  # +Z
		mesh(BOOTS).add_tube([
				ring(Vector3(x, 0.055, -0.095), fwd, Vector2(0.045, 0.045), Vector3.UP, {foot: 1.0}),
				ring(Vector3(x, 0.07, -0.04), fwd, Vector2(0.052, 0.065), Vector3.UP, {foot: 1.0}),
				ring(Vector3(x, 0.05, 0.06), fwd, Vector2(0.05, 0.047), Vector3.UP, {foot: 0.7, toes: 0.3}),
				ring(Vector3(x, 0.04, 0.14), fwd, Vector2(0.045, 0.036), Vector3.UP, {toes: 1.0}),
				ring(Vector3(x, 0.035, 0.19), fwd, Vector2(0.032, 0.026), Vector3.UP, {toes: 1.0})], true, true)

	# --- Head ---------------------------------------------------------------------------------------------

	# After the owner's portrait of her (2026-11-07): a soft round face narrowing to a small chin, big amber eyes,
	# silver hair with a side-swept fringe, a crown braid on her right, a gold-cuffed lock and long elf ears.
	# Coordinates are relative to the Head bone (at the top of the neck), in skeleton units before HEAD_SCALE; hp()
	# places them. Face coordinates (x, y) name points on the front of her face (face_surface()). The features are
	# painted there as one mesh with vertex-colour gradients (paint()), so blush and shading fade into the skin.

	func hp(v: Vector3) -> Vector3:
		return head + v * HEAD_SCALE

	## (half-width, half-depth, centre z, front flatness) of the head at height y.
	func head_ring(y: float) -> Vector4:
		for i in HEAD_PROFILE.size() - 1:
			var a: Array = HEAD_PROFILE[i]
			var b: Array = HEAD_PROFILE[i + 1]
			if y <= b[0] or i == HEAD_PROFILE.size() - 2:
				var t := clampf(inverse_lerp(a[0], b[0], y), 0.0, 1.0)
				return Vector4(lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t), lerpf(a[4], b[4], t))
		return Vector4.ZERO

	## Depth of the front of her face at (x, y): a superellipse across, flatter than a circle over eyes and cheeks.
	func face_z(x: float, y: float) -> float:
		var r := head_ring(y)
		var u := minf(absf(x) / r.x, 1.0)
		return r.z + r.y * pow(1.0 - pow(u, r.w), 1.0 / r.w)

	## Point on the front of her face at (x, y), lifted by `lift`.
	func face_surface(x: float, y: float, lift := 0.0) -> Vector3:
		return hp(Vector3(x, y, face_z(x, y) + lift))

	## Pushes a point out onto the hair cap or the face, whichever is further, plus `lift`.
	func on_head(p: Vector3, lift: float) -> Vector3:
		var d := (p - HAIR_CAP_C).normalized()
		var t := 1.0 / sqrt(pow(d.x / HAIR_CAP_R.x, 2.0) + pow(d.y / HAIR_CAP_R.y, 2.0) + pow(d.z / HAIR_CAP_R.z, 2.0))
		var q := HAIR_CAP_C + d * (t + lift)
		if q.z > 0.0 and absf(q.x) < head_ring(q.y).x:
			q.z = maxf(q.z, face_z(q.x, q.y) + lift)
		return hp(q)

	## The face paint: one mesh of painted features coloured per vertex.
	func paint() -> SkinnedMeshBuilder:
		var b := mesh(Color.WHITE, 0.0, "paint")
		b.vertex_colors = true
		return b

	## A filled shape painted on the face: `boundary` points around `center`, in the shape's own coordinates, which
	## `to_face` (a Callable, or null for none) maps to face coordinates. Filled in rings from the centre (0) to the
	## edge (1). `color`: a Color, or a Callable(point: Vector2, ring: float) -> Color for gradients.
	func paint_shape(boundary: Array, center: Vector2, color: Variant, lift: float, to_face: Variant = null,
			rings: Array = [0.0, 0.3, 0.55, 0.75, 0.9, 1.0]) -> void:
		var h := {bone(&"Head"): 1.0}
		var points := []
		var weights := []
		var colors := []
		for r: float in rings:
			var row := []
			var row_w := []
			var row_c := []
			for i in boundary.size() + 1:
				var q: Vector2 = center.lerp(boundary[i % boundary.size()], maxf(r, 0.03))
				var f: Vector2 = (to_face as Callable).call(q) if to_face is Callable else q
				row.append(face_surface(f.x, f.y, lift))
				row_w.append(h)
				row_c.append((color as Callable).call(q, r) if color is Callable else color)
			points.append(row)
			weights.append(row_w)
			colors.append(row_c)
		paint().add_sheet(points, weights, hp(Vector3(0, 0.12, -0.05)), false, colors)

	## A painted line along `pts` (face coordinates) with a width at each point. `color`: a Color, or a
	## Callable(t: float) -> Color along the line (t from 0 to 1).
	func paint_line(pts: Array, widths: Array, color: Variant, lift: float) -> void:
		var h := {bone(&"Head"): 1.0}
		var upper := []
		var lower := []
		var ws := []
		var cs := []
		var n := pts.size()
		for i in n:
			var p: Vector2 = pts[i]
			var dir: Vector2 = ((pts[mini(i + 1, n - 1)] as Vector2) - (pts[maxi(i - 1, 0)] as Vector2)).normalized()
			var side := Vector2(-dir.y, dir.x) * float(widths[i]) * 0.5
			upper.append(face_surface(p.x + side.x, p.y + side.y, lift))
			lower.append(face_surface(p.x - side.x, p.y - side.y, lift))
			ws.append(h)
			cs.append((color as Callable).call(float(i) / (n - 1)) if color is Callable else color)
		paint().add_sheet([upper, lower], [ws, ws], hp(Vector3(0, 0.12, -0.05)), false, [cs, cs])

	## A small solid ellipse (sparkles, highlights).
	func paint_dot(center: Vector2, size: Vector2, color: Color, lift: float, tilt := 0.0) -> void:
		paint_shape(ellipse(center, size, tilt, 16), center, color, lift, null, [0.0, 1.0])

	## A four-pointed sparkle.
	func paint_star(center: Vector2, size: float, color: Color, lift: float) -> void:
		var pts := []
		for k in 8:
			var a := TAU * k / 8.0 + PI / 2.0
			pts.append(center + Vector2(cos(a), sin(a)) * (size if k % 2 == 0 else size * 0.24))
		paint_shape(pts, center, color, lift, null, [0.0, 1.0])

	static func ellipse(center: Vector2, size: Vector2, tilt := 0.0, n := 24) -> Array:
		var out := []
		for k in n:
			var a := TAU * k / n
			out.append(center + Vector2(cos(a) * size.x, sin(a) * size.y).rotated(tilt))
		return out

	## A colour that fades from `inner` to `outer` towards the edge of a painted shape (from ring `from` outwards).
	static func fade_to(inner: Color, outer: Color, from := 0.35) -> Callable:
		return func(_p: Vector2, r: float) -> Color: return inner.lerp(outer, smoothstep(from, 1.0, r))

	## Eye-local point -> face coordinates (lx > 0 towards the outer corner, tilted so the outer corner lifts).
	func eye_pt(s: float, lx: float, ly: float) -> Vector2:
		var p := Vector2(lx, ly).rotated(EYE_TILT)
		return Vector2(s * (EYE_CENTER.x + p.x), EYE_CENTER.y + p.y)

	## Top and bottom of the eye opening at eye-local x: rounded, tall and steep at the outer side, narrowing to a
	## point at the inner corner (like the portrait).
	static func eye_top(lx: float) -> float:
		var u := clampf((lx / EYE_SIZE.x + 1.0) * 0.5, 0.0, 1.0)  # 0 = inner corner, 1 = outer corner
		var v := pow(u, 1.25)
		return EYE_SIZE.y * pow(maxf(4.0 * v * (1.0 - v), 0.0), lerpf(0.75, 0.32, u))

	static func eye_bottom(lx: float) -> float:
		var u := clampf((lx / EYE_SIZE.x + 1.0) * 0.5, 0.0, 1.0)
		var v := pow(u, 1.1)
		return -EYE_SIZE.y * 0.95 * pow(maxf(4.0 * v * (1.0 - v), 0.0), lerpf(0.9, 0.38, u))

	## The eye opening, in eye-local coordinates around (0, 0).
	static func eye_outline() -> Array:
		var out := []
		for i in 21:
			var lx := -cos(PI * i / 20.0) * EYE_SIZE.x
			out.append(Vector2(lx, eye_top(lx)))
		for i in range(19, 0, -1):
			var lx := -cos(PI * i / 20.0) * EYE_SIZE.x
			out.append(Vector2(lx, eye_bottom(lx)))
		return out

	## Silver hair colour at a point on a strand (skeleton space), like the painted hair of her portrait: deeper
	## towards the tips; fine darker streaks along each strand and softly darker edges (`across` -1..1 over its
	## width); and a broken ring of shine round the upper head on the strand's outer side (`out` > 0), a little higher
	## or lower on each strand (`seed` 0..1), so it reads as separate glints.
	func hair_color(p: Vector3, across: float, out: float, seed: float) -> Color:
		var l := (p - head) / HEAD_SCALE
		var c := HAIR.lerp(HAIR_SHADE, (1.0 - smoothstep(-0.1, 0.24, l.y)) * 0.6)
		var streak := 0.5 + 0.5 * cos(across * PI * 2.4 + seed * TAU)
		c = c.lerp(HAIR_STREAK * Color(c.r / HAIR.r, c.g / HAIR.g, c.b / HAIR.b), 0.5 * streak * streak)
		c = c.darkened(0.16 * pow(absf(across), 3.0) + 0.14 * maxf(-out, 0.0))
		var band := HAIR_SHINE_Y + 0.014 * (seed - 0.5)
		var shine := (1.0 - smoothstep(0.003, 0.018, absf(l.y - band))) * clampf(out * 1.5, 0.0, 1.0) * (1.0 - across * across * across * across)
		return c.lerp(HAIR_SHINE, clampf(shine * 1.5, 0.0, 1.0))

	## A soft hair clump along `pts` (skeleton space): a flat, tapering lock lying against the head (its flat side
	## faces away from `center`). `widths` per point; weights per point (default: the head). Coloured by
	## hair_color(), mixed towards the shade by `darken` (locks further back).
	func clump(b: SkinnedMeshBuilder, pts: Array, widths: Array, thick: float, center: Vector3, weights := [],
			darken := 0.0) -> void:
		var h := {bone(&"Head"): 1.0}
		_strands += 1
		var seed := fposmod(_strands * 0.618, 1.0)
		var rings := []
		var n := pts.size()
		for i in n:
			var t := float(i) / (n - 1)
			var p: Vector3 = pts[i]
			var axis: Vector3 = (pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)
			var tint := func(across: float, out: float) -> Color:
				return hair_color(p, across, out, seed).lerp(HAIR_SHADE, darken)
			rings.append(ring(p, axis, Vector2(widths[i], thick * lerpf(1.0, 0.45, t) * (1.0 - 0.75 * smoothstep(0.7, 1.0, t))),
					(p - center).normalized(), weights[i] if i < weights.size() else h, tint))
		b.add_tube(rings, true, true, 12, 0.0, 0.2)

	## Width along a lock: narrow where it starts, full by a third, tapering to a soft point.
	static func lock_width(w: float, t: float) -> float:
		return w * lerpf(0.5, 1.0, smoothstep(0.0, 0.3, t)) * (1.0 - 0.9 * smoothstep(0.45, 1.0, t))

	## Points along a smooth curve through control points (Catmull-Rom), `per` samples per span.
	static func curve(controls: Array, per: int) -> Array:
		var out := []
		for i in controls.size() - 1:
			var p0: Vector3 = controls[maxi(i - 1, 0)]
			var p1: Vector3 = controls[i]
			var p2: Vector3 = controls[i + 1]
			var p3: Vector3 = controls[mini(i + 2, controls.size() - 1)]
			for k in per:
				var t := float(k) / per
				out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
						+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
		out.append(controls[controls.size() - 1])
		return out

	func _face() -> void:
		var h := {bone(&"Head"): 1.0}
		var skin := mesh(SKIN, FACE_OUTLINE)
		var start := skin.mark()
		var rings := []
		for row: Array in HEAD_PROFILE:
			rings.append(ring(hp(Vector3(0, row[0], row[3])), Vector3.UP, Vector2(row[1], row[2]) * HEAD_SCALE,
					Vector3.BACK, h, null, row[4]))
		skin.add_tube(rings, true, true, 28)
		skin.smooth_normals(start)
		mesh(SKIN, 0.0).add_ellipsoid(face_surface(0.0, NOSE_Y + 0.004, -0.0036),  # the small tip of her nose
				Vector3(0.0042, 0.0085, 0.0045) * HEAD_SCALE, h, Basis(Vector3.RIGHT, -0.3), 6)
		for s: float in [1.0, -1.0]:
			_eye(s)
			_brow(s)
			_cheek(s)
			_ear(s)
		# Soft shadows the hair casts on her face, as in the portrait: under the fringe and beside the side locks.
		var forehead := Vector2(0, BROW_Y + 0.012)
		paint_shape(ellipse(forehead, Vector2(0.104, 0.017)), forehead, fade_to(SKIN_SHADOW, SKIN, 0.25), 0.0005, null,
				[0.0, 0.4, 0.7, 1.0])
		for s: float in [1.0, -1.0]:
			var side := Vector2(s * 0.1, 0.055)
			paint_shape(ellipse(side, Vector2(0.014, 0.07), s * 0.12), side, fade_to(SKIN_SHADOW, SKIN, 0.2), 0.0005, null,
					[0.0, 0.4, 0.7, 1.0])
		var bridge := Vector2(0, EYE_CENTER.y - 0.04)
		paint_shape(ellipse(bridge, Vector2(0.05, 0.011)), bridge, fade_to(NOSE_TINT, SKIN, 0.15), 0.0006, null,
				[0.0, 0.4, 0.75, 1.0])
		# Nose: a soft pink tip, a tiny shadow stroke on one side and a highlight.
		paint_shape(ellipse(Vector2(0, NOSE_Y), Vector2(0.0085, 0.0065)), Vector2(0, NOSE_Y), fade_to(NOSE_TINT, SKIN, 0.1),
				0.0012, null, [0.0, 0.5, 1.0])
		paint_line([Vector2(0.0036, NOSE_Y + 0.016), Vector2(0.0048, NOSE_Y + 0.008), Vector2(0.006, NOSE_Y + 0.0012),
				Vector2(0.0036, NOSE_Y - 0.0026)], [0.0002, 0.0008, 0.0015, 0.0004],
				func(t: float) -> Color: return NOSE_TINT.lerp(NOSE_LINE, smoothstep(0.0, 0.7, t)), 0.0016)
		paint_dot(Vector2(-0.0006, NOSE_Y + 0.0014), Vector2(0.0013, 0.0013), NOSE_LIGHT, 0.002)
		# A small closed smile, a soft pink lower lip with a glint.
		var my := MOUTH_Y
		paint_line([Vector2(-0.024, my + 0.0046), Vector2(-0.015, my + 0.001), Vector2(-0.005, my - 0.0003),
				Vector2(0.006, my - 0.0002), Vector2(0.016, my + 0.0012), Vector2(0.024, my + 0.0044)],
				[0.0006, 0.0014, 0.0017, 0.0016, 0.0011, 0.0005], MOUTH, 0.0016)
		var lip := Vector2(0.002, my - 0.0043)
		paint_shape(ellipse(lip, Vector2(0.0088, 0.003), 0.0, 20), lip, fade_to(LIPS, SKIN, 0.3), 0.001, null,
				[0.0, 0.4, 0.75, 1.0])
		paint_dot(lip + Vector2(0.002, -0.0003), Vector2(0.0019, 0.0006), LIP_LIGHT, 0.0013)

	## A big anime eye after the portrait: a white greyed under the lid; a large iris, dark violet-brown under the
	## lid, warm amber in the middle and glowing gold at the bottom, with a soft ring round the pupil; a brown pupil
	## with a darker edge; sparkles; a thick upper lid ending in a wing with lashes; a fine lower line and a crease.
	func _eye(s: float) -> void:
		var w := EYE_SIZE.x
		var hh := EYE_SIZE.y
		var to_face := func(p: Vector2) -> Vector2: return eye_pt(s, p.x, p.y)
		# A soft warm shadow on the lid above the eye.
		paint_shape(ellipse(Vector2(w * 0.1, hh + 0.003), Vector2(w * 1.05, 0.0068)), Vector2(w * 0.1, hh + 0.003),
				fade_to(LID_SHADOW, SKIN, 0.2), 0.0007, to_face, [0.0, 0.4, 0.75, 1.0])
		var white_color := func(p: Vector2, _r: float) -> Color:
			return EYE_WHITE.lerp(EYE_SHADOW, smoothstep(0.0, 0.9, p.y / hh))
		paint_shape(eye_outline(), Vector2(0, -hh * 0.2), white_color, 0.001, to_face)
		var ic := Vector2(IRIS_SHIFT, 0.0003)
		var iris := []
		for k in 36:
			var a := TAU * k / 36.0
			var p := ic + Vector2(cos(a) * IRIS_SIZE.x, sin(a) * IRIS_SIZE.y)
			p.y = clampf(p.y, eye_bottom(p.x) + 0.0003, eye_top(p.x))
			iris.append(p)
		var iris_color := func(p: Vector2, r: float) -> Color:
			var v := (p.y - ic.y) / IRIS_SIZE.y
			var c := IRIS_MID.lerp(IRIS_LOW, 1.0 - smoothstep(-0.8, 0.05, v))
			c = c.lerp(IRIS_TOP, smoothstep(0.0, 0.62, v))
			var glow := maxf(0.0, 1.0 - absf(r - 0.6) / 0.14) * (1.0 - smoothstep(-0.3, 0.35, v))
			c = c.lerp(IRIS_GLOW, glow * 0.55)
			return c.lerp(IRIS_RIM, smoothstep(0.82, 0.98, r))
		paint_shape(iris, ic, iris_color, 0.0016, to_face, [0.0, 0.25, 0.45, 0.52, 0.6, 0.68, 0.8, 0.9, 1.0])
		var pupil := ic + Vector2(0, IRIS_SIZE.y * 0.14)
		paint_shape(ellipse(pupil, Vector2(IRIS_SIZE.x * 0.25, IRIS_SIZE.y * 0.39), 0.0, 20), pupil,
				fade_to(PUPIL, PUPIL_RING, 0.55), 0.0021, to_face, [0.0, 0.5, 0.75, 1.0])
		# Sparkles, lit from her right (the viewer's left) on both eyes, like the portrait.
		var ci: Vector2 = to_face.call(ic)
		var rx := IRIS_SIZE.x
		var ry := IRIS_SIZE.y
		paint_dot(ci + Vector2(-0.4 * rx, 0.58 * ry), Vector2(0.27 * rx, 0.19 * ry), SPARKLE, 0.0028, -0.2)
		paint_dot(ci + Vector2(-0.04 * rx, 0.36 * ry), Vector2(0.075 * rx, 0.075 * rx), SPARKLE, 0.0028)
		paint_star(ci + Vector2(0.52 * rx, 0.6 * ry), 0.19 * rx, SPARKLE, 0.0028)
		paint_dot(ci + Vector2(0.55 * rx, 0.38 * ry), Vector2(0.035 * rx, 0.035 * rx), SPARKLE, 0.0028)
		paint_dot(ci + Vector2(0.68 * rx, 0.16 * ry), Vector2(0.03 * rx, 0.03 * rx), SPARKLE, 0.0028)
		paint_dot(ci + Vector2(-0.78 * rx, -0.35 * ry), Vector2(0.12 * rx, 0.095 * ry), SPARKLE, 0.0028)
		paint_dot(ci + Vector2(0.76 * rx, -0.36 * ry), Vector2(0.11 * rx, 0.09 * ry), SPARKLE, 0.0028)
		# Upper lid: thin at the inner corner, thick over the outer half, then a wing out past the corner.
		var lid := []
		var lid_w := []
		for i in 15:
			var u := i / 14.0
			var lx := lerpf(-w, w * 0.9, u)
			var width := lerpf(0.0012, 0.0062, smoothstep(0.0, 0.8, u))
			lid.append(eye_pt(s, lx, eye_top(lx) + width * 0.3))
			lid_w.append(width)
		for e: Array in [[w * 1.02, hh * 0.4, 0.0058], [w + 0.0048, hh * 0.12, 0.0034], [w + 0.0095, -hh * 0.06, 0.0004]]:
			lid.append(eye_pt(s, e[0], e[1]))
			lid_w.append(e[2])
		paint_line(lid, lid_w, func(t: float) -> Color: return LID_INNER.lerp(EYE_LINE, smoothstep(0.0, 0.35, t)), 0.0036)
		for k in 3:  # lashes flicking up from the outer half of the lid
			var lx := w * (0.3 + 0.27 * k)
			var base := Vector2(lx, eye_top(minf(lx, w * 0.9)) + 0.0042)
			var tip := base + Vector2(0.0042 + 0.0022 * k, 0.0056 - 0.0012 * k)
			var mid := base.lerp(tip, 0.5) + Vector2(-0.0009, 0.0012)
			paint_line([eye_pt(s, base.x, base.y), eye_pt(s, mid.x, mid.y), eye_pt(s, tip.x, tip.y)],
					[0.0017, 0.0011, 0.0002], EYE_LINE, 0.004)
		paint_line([eye_pt(s, -w + 0.0006, 0.0012), eye_pt(s, -w - 0.0012, -0.0012), eye_pt(s, -w - 0.0018, -0.0034)],
				[0.0011, 0.0008, 0.0002], LID_INNER, 0.0036)  # the little hook at the inner corner
		# Fine line down the outer side and along the bottom, with two small lower lashes.
		var low := [eye_pt(s, w, hh * 0.34)]
		var low_w := [0.0017]
		for i in 9:
			var u := i / 8.0
			var lx := lerpf(w * 0.985, w * 0.05, u)
			low.append(eye_pt(s, lx, eye_bottom(lx) - 0.0004))
			low_w.append(lerpf(0.0015, 0.0004, u))
		paint_line(low, low_w, LOWER_LID, 0.0024)
		for k in 2:
			var lx := w * (0.78 - 0.2 * k)
			var base := Vector2(lx, eye_bottom(lx) - 0.0006)
			paint_line([eye_pt(s, base.x, base.y), eye_pt(s, base.x + 0.0012, base.y - 0.0028)], [0.0009, 0.0002],
					LOWER_LID, 0.0024)
		var crease := []
		var crease_w := []
		for i in 9:
			var u := i / 8.0
			var lx := lerpf(-w * 0.5, w * 1.02, u)
			crease.append(eye_pt(s, lx, eye_top(clampf(lx, -w, w * 0.9)) + 0.0088 - 0.0024 * u))
			crease_w.append(0.0003 + 0.0007 * sin(PI * u))
		paint_line(crease, crease_w, CREASE, 0.0014)

	## A thin, light brow high above the eye (the fringe hides most of it).
	func _brow(s: float) -> void:
		var brow := []
		var brow_w := []
		for i in 9:
			var t := i / 8.0
			brow.append(Vector2(s * lerpf(0.03, 0.099, t), BROW_Y + 0.0062 * sin(PI * pow(t, 0.8)) - 0.0042 * t))
			brow_w.append(lerpf(0.003, 0.0011, t))
		paint_line(brow, brow_w, BROW, 0.0012)

	## Soft blush with a few hatch strokes, and a little highlight on the cheek.
	func _cheek(s: float) -> void:
		var c := Vector2(s * 0.074, EYE_CENTER.y - 0.043)
		paint_shape(ellipse(c, Vector2(0.04, 0.02), s * 0.08, 28), c, fade_to(BLUSH, SKIN, 0.1), 0.0007, null,
				[0.0, 0.25, 0.5, 0.7, 0.85, 1.0])
		for k in 5:
			var x := c.x + s * lerpf(-0.018, 0.018, k / 4.0)
			var y := c.y + 0.0018 * sin(k * 1.7)
			paint_line([Vector2(x + 0.0026, y + 0.0055), Vector2(x, y), Vector2(x - 0.0026, y - 0.0055)],
					[0.0004, 0.001, 0.0003], BLUSH_LINE, 0.0011)
		paint_dot(Vector2(s * 0.085, EYE_CENTER.y - 0.027), Vector2(0.0026, 0.0024), CHEEK_LIGHT, 0.0013)

	## Long elf ears like leaves, pointing out and a little up, with a pink inner fold.
	func _ear(s: float) -> void:
		var h := {bone(&"Head"): 1.0}
		var base := hp(Vector3(s * 0.098, 0.076, -0.022))
		var tip := hp(Vector3(s * 0.222, 0.132, -0.062))
		var axis := tip - base
		var k := HEAD_SCALE
		var front := Vector3(s * 0.25, 0.0, 1.0).normalized()  # the inner side faces forward and a little out
		var rings := []
		for e: Array in [[0.0, 0.036, 0.0085], [0.25, 0.034, 0.008], [0.5, 0.024, 0.0068], [0.75, 0.012, 0.005],
				[0.92, 0.005, 0.0032], [1.0, 0.0012, 0.0012]]:
			var t: float = e[0]
			rings.append(ring(base.lerp(tip, t) + Vector3(0, -0.004 * sin(PI * t), 0) * k, axis, Vector2(e[1], e[2]) * k,
					front, h))
		var skin := mesh(SKIN, FACE_OUTLINE)
		var start := skin.mark()
		skin.add_tube(rings, true, true, 12)
		skin.smooth_normals(start)
		var y := axis.normalized()
		var x := y.cross(front).normalized()
		var z := x.cross(y)
		mesh(EAR_INNER, 0.0).add_ellipsoid(base.lerp(tip, 0.36) + z * 0.0066 * k + Vector3(0, -0.003, 0) * k,
				Vector3(0.011, 0.032, 0.0018) * k, h, Basis(x, y, z), 6)

	func _hair() -> void:
		var h := {bone(&"Head"): 1.0}
		var head_bone := bone(&"Head")
		var hair := mesh(HAIR, FACE_OUTLINE)
		hair.vertex_colors = true
		hair.color = HAIR
		var cap_center := hp(HAIR_CAP_C)
		hair.add_ellipsoid(cap_center, HAIR_CAP_R * HEAD_SCALE, h, Basis(), 8, HAIR_SHADE.darkened(0.08))
		# Soft clumps from the crown down the back and sides: what the high camera sees most.
		var crown := Vector3(0, 0.272, -0.035)
		for i in CROWN_STRANDS:
			var a := deg_to_rad(lerpf(72.0, 288.0, float(i) / (CROWN_STRANDS - 1)))
			var out := Vector3(sin(a), 0.0, cos(a))
			var controls := [crown + out * 0.025, HAIR_CAP_C + (out * 0.75 + Vector3(0, 0.66, 0)).normalized() * 0.15,
					HAIR_CAP_C + (out + Vector3(0, 0.05, 0)).normalized() * 0.15,
					HAIR_CAP_C + (out + Vector3(0, -0.4, 0)).normalized() * 0.15,
					HAIR_CAP_C + (out + Vector3(0, -0.85, 0)).normalized() * 0.15]
			var pts := []
			var widths := []
			var samples := curve(controls, 5)
			for j in samples.size():
				pts.append(on_head(samples[j], 0.006))
				var t := float(j) / (samples.size() - 1)
				widths.append(0.046 * HEAD_SCALE * lerpf(0.5, 1.0, smoothstep(0.0, 0.25, t)) * (1.0 - 0.85 * smoothstep(0.6, 1.0, t)))
			clump(hair, pts, widths, 0.013 * HEAD_SCALE, cap_center)
		_bangs(hair, cap_center)
		_side_locks(hair, head_bone)
		_side_hair(hair)
		_wisps(hair, head_bone)
		_braids(cap_center, head_bone)
		# The long hair down her back.
		var back := mesh(HAIR_SHADE, FACE_OUTLINE)
		back.vertex_colors = true
		back.color = HAIR_SHADE
		var hair_center := Vector3(0, 0, head.z + HAIR_CAP_C.z * HEAD_SCALE)
		for g in HAIR_ANGLES.size() - 1:  # one soft lock between each pair of chains, rounded, ending in a point
			var seed := fposmod(g * 0.618, 1.0)
			var tint := func(q: Vector3, across: float) -> Color:
				return hair_color(q, across * 2.0 - 1.0, 1.0, seed).lerp(HAIR_SHADE, 0.15)
			chain_sheet(back, hair_chains, head_bone, hair_center, steps(g, g + 1.0, 0.125),
					steps(0.0, HAIR_DROP.size() - 1.0, 0.5), head + Vector3(0, -0.3, 0.05), -0.3 - 0.08 * (g % 2), 0.012, tint)

	## The fringe: thin pointed strands from a parting on her right, falling to her brows; a few longer ones between
	## her eyes, the rest swept across her forehead.
	func _bangs(hair: SkinnedMeshBuilder, cap_center: Vector3) -> void:
		for k in 3:  # from the parting over the top of her head to her left side
			var z := 0.03 - 0.022 * k
			var controls := [Vector3(-0.034 + 0.006 * k, 0.277, z), Vector3(0.025, 0.268, z + 0.004),
					Vector3(0.08, 0.235, z), Vector3(0.116, 0.18, z - 0.008)]
			var samples := curve(controls, 4)
			var pts := []
			var widths := []
			for j in samples.size():
				var t := float(j) / (samples.size() - 1)
				pts.append(on_head(samples[j], 0.006 + 0.002 * k))
				widths.append(0.03 * HEAD_SCALE * lerpf(0.6, 1.0, smoothstep(0.0, 0.2, t)) * (1.0 - 0.85 * smoothstep(0.6, 1.0, t)))
			clump(hair, pts, widths, 0.008 * HEAD_SCALE, cap_center)
		for b: Array in BANGS:
			var x_root: float = b[0]
			var x_tip: float = b[1]
			var y_tip: float = b[2]
			var controls := [Vector3(x_root, 0.274, -0.012), Vector3(lerpf(x_root, x_tip, 0.08), 0.258, 0.06),
					Vector3(lerpf(x_root, x_tip, 0.32), 0.212, 0.102), Vector3(lerpf(x_root, x_tip, 0.8), y_tip + 0.03, 0.112),
					Vector3(x_tip, y_tip, 0.112)]
			var samples := curve(controls, 4)
			var pts := []
			var widths := []
			for j in samples.size():
				var t := float(j) / (samples.size() - 1)
				pts.append(on_head(samples[j], lerpf(0.005, 0.011, smoothstep(0.0, 0.5, t)) + float(b[4])))
				widths.append(float(b[3]) * 1.18 * HEAD_SCALE * lerpf(0.8, 1.0, smoothstep(0.0, 0.15, t))
						* (1.0 - 0.94 * smoothstep(0.5, 1.0, t)))
			clump(hair, pts, widths, 0.007 * HEAD_SCALE, cap_center)

	## How far out the side of her head (hair cap or face) is at height y and depth z.
	func side_x(y: float, z: float) -> float:
		var k := 1.0 - pow((y - HAIR_CAP_C.y) / HAIR_CAP_R.y, 2.0) - pow((z - HAIR_CAP_C.z) / HAIR_CAP_R.z, 2.0)
		return maxf(HAIR_CAP_R.x * sqrt(maxf(k, 0.0)), head_ring(y).x)

	## Hair over the sides of her head, from behind the face-framing locks to behind the ears, falling to her jaw:
	## the fuller sides of the portrait. Her ears poke out through it.
	func _side_hair(hair: SkinnedMeshBuilder) -> void:
		var center := hp(Vector3(0, 0.1, -0.03))
		for s: float in [1.0, -1.0]:
			for panel: Array in SIDE_HAIR:
				var z: float = panel[0]
				var pts := []
				var widths := []
				var ys := [0.25, 0.2, 0.14, 0.08, 0.02, -0.03, float(panel[1])]
				for j in ys.size():
					var y: float = ys[j]
					var t := float(j) / (ys.size() - 1)
					var bob := 0.034 * sin(PI * clampf(inverse_lerp(0.2, -0.1, y), 0.0, 1.0))  # rounded like a bob
					var x := side_x(maxf(y, 0.03), z) + 0.014 + bob
					pts.append(hp(Vector3(s * x, y, z - 0.06 * maxf(0.03 - y, 0.0))))
					widths.append(0.025 * HEAD_SCALE * lerpf(0.6, 1.0, smoothstep(0.0, 0.25, t)) * (1.0 - 0.9 * smoothstep(0.65, 1.0, t)))
				clump(hair, pts, widths, 0.008 * HEAD_SCALE, center, [], 0.1)  # a touch deeper than the locks in front

	## Long locks framing her face in front of the ears, down past her chin (with physics). Two layers on each side;
	## her right lock is gathered in a gold cuff at the chin and ends in a few loose strands.
	func _side_locks(hair: SkinnedMeshBuilder, head_bone: int) -> void:
		var h := {bone(&"Head"): 1.0}
		var face_center := hp(Vector3(0, 0.08, -0.04))
		for s: float in [1.0, -1.0]:
			var chain: PackedInt32Array = lock_chains[0 if s > 0.0 else 1]
			var tied := s < 0.0
			for layer in 2:
				var o := Vector3(s * 0.006, 0.003, -0.02) * layer * HEAD_SCALE  # behind the front lock, not level with it
				var pts := []
				var weights := []
				for q: Vector3 in curve([Vector3(s * (0.062 + 0.02 * layer), 0.262, 0.004 - 0.02 * layer),
						Vector3(s * (0.086 + 0.014 * layer), 0.228, 0.072 - 0.022 * layer),
						Vector3(s * (0.106 + 0.012 * layer), 0.172, 0.068 - 0.02 * layer)], 3):
					pts.append(on_head(q, lerpf(0.002, 0.01, smoothstep(0.0, 0.17, q.y * -1.0 + 0.264))))  # from under the fringe
					weights.append(h)
				var end := 2.1 if tied else 2.95 - 0.25 * layer
				for k in 9:
					var sv := lerpf(0.25, end, k / 8.0)
					pts.append(chain_pos(chain, sv) + o * (1.0 - 0.7 * smoothstep(1.4, 2.1, sv) if tied else 1.0))
					weights.append(ClothRig.chain_weights(chain, sv, head_bone))
				var widths := []
				for j in pts.size():
					var t := float(j) / (pts.size() - 1)
					var width := (0.027 - 0.003 * layer) * HEAD_SCALE
					if tied:  # full width down the cheek, gathered into the cuff
						widths.append(width * lerpf(0.15, 1.0, smoothstep(0.0, 0.25, t)) * lerpf(1.0, 0.36, smoothstep(0.55, 1.0, t)))
					else:
						widths.append(width * lerpf(0.15, 1.0, smoothstep(0.0, 0.25, t)) * lerpf(1.0, 1.35, smoothstep(0.3, 0.7, t))
								* (1.0 - 0.92 * smoothstep(0.72, 1.0, t)))
				clump(hair, pts, widths, 0.009 * HEAD_SCALE, face_center, weights, 0.06 * layer)
			if tied:
				for k in 3:  # loose strands below the cuff
					var spread := Vector3(s * (k - 1) * 0.011, 0.0, (1 - k) * 0.004) * HEAD_SCALE
					var pts := []
					var weights := []
					var widths := []
					for j in 7:
						var sv := lerpf(2.05, 3.05 + 0.1 * (k % 2), j / 6.0)
						pts.append(chain_pos(chain, sv) + spread * smoothstep(2.1, 3.0, sv))
						weights.append(ClothRig.chain_weights(chain, sv, head_bone))
						widths.append(lock_width((0.013 - 0.0015 * k) * HEAD_SCALE, j / 6.0))
					clump(hair, pts, widths, 0.01 * HEAD_SCALE, face_center, weights)
				var c0 := chain_pos(chain, 1.98)
				var c1 := chain_pos(chain, 2.24)
				var cw := ClothRig.chain_weights(chain, 2.1, head_bone)
				var gold := mesh(GOLD, FINE_OUTLINE)
				gold.add_tube([ring(c0, c1 - c0, Vector2(0.0128, 0.0118), Vector3.BACK, cw),
						ring(c1, c1 - c0, Vector2(0.0128, 0.0118), Vector3.BACK, cw)], true, true)
				for e: Vector3 in [c0, c1]:  # raised rims
					gold.add_tube([ring(e - (c1 - c0) * 0.06, c1 - c0, Vector2(0.0146, 0.0136), Vector3.BACK, cw),
							ring(e + (c1 - c0) * 0.06, c1 - c0, Vector2(0.0146, 0.0136), Vector3.BACK, cw)], true, true)

	## Thin loose strands from the temples down past her cheeks, in front of the face-framing locks (with physics).
	func _wisps(hair: SkinnedMeshBuilder, head_bone: int) -> void:
		var h := {bone(&"Head"): 1.0}
		var face_center := hp(Vector3(0, 0.08, -0.04))
		for s: float in [1.0, -1.0]:
			var chain: PackedInt32Array = lock_chains[0 if s > 0.0 else 1]
			var pts := []
			var weights := []
			var top := curve([Vector3(s * 0.075, 0.228, 0.08), Vector3(s * 0.092, 0.17, 0.1),
					Vector3(s * 0.103, 0.118, 0.09)], 3)
			for j in top.size():
				pts.append(on_head(top[j], lerpf(0.003, 0.013, float(j) / (top.size() - 1))))
				weights.append(h)
			for k in 6:
				var sv := lerpf(0.35, 1.9 if s < 0.0 else 2.3, k / 5.0)
				pts.append(chain_pos(chain, sv) + Vector3(-s * 0.004, 0.0, 0.02) * HEAD_SCALE)
				weights.append(ClothRig.chain_weights(chain, sv, head_bone))
			var widths := []
			for j in pts.size():
				var t := float(j) / (pts.size() - 1)
				widths.append(0.0075 * HEAD_SCALE * smoothstep(0.0, 0.2, t + 0.03) * (1.0 - 0.9 * smoothstep(0.55, 1.0, t)))
			clump(hair, pts, widths, 0.004 * HEAD_SCALE, face_center, weights)

	## A crown braid along the right of her head from the parting to behind her ear, where it continues as the
	## beaded braid hanging down her back.
	func _braids(cap_center: Vector3, head_bone: int) -> void:
		var h := {bone(&"Head"): 1.0}
		var plaits := mesh(BRAID, FINE_OUTLINE)
		plaits.vertex_colors = true
		plaits.color = BRAID
		var plait_color := func(t: float, across: float, out: float) -> Color:  # shaded where the plaits tuck under
			var mid := 1.0 - absf(2.0 * t - 1.0)
			var c := HAIR.lerp(HAIR_SHADE, 0.7 * (1.0 - mid) + 0.25 * maxf(-out, 0.0))
			c = c.lerp(HAIR_STREAK, 0.35 * (0.5 + 0.5 * cos(across * PI * 2.0)))
			return c.lerp(HAIR_SHINE, 0.55 * mid * mid * clampf(out, 0.0, 1.0) * (1.0 - across * across))
		var path := []
		var controls := curve(CROWN_BRAID, 4)
		for j in controls.size():  # rides higher down the side, over the fuller side hair
			path.append(on_head(controls[j], lerpf(0.025, 0.04, smoothstep(0.2, 0.7, float(j) / (controls.size() - 1)))))
		for i in path.size() - 1:
			var p: Vector3 = path[i]
			var y: Vector3 = ((path[i + 1] as Vector3) - p).normalized()
			var z := (p - cap_center).normalized()
			var x := y.cross(z).normalized()
			var side := 1.0 if i % 2 == 0 else -1.0
			plaits.add_ellipsoid(p + x * 0.0085 * side, Vector3(0.0115, 0.026, 0.0072) * HEAD_SCALE, h,
					Basis(x, y, x.cross(y)) * Basis(Vector3.BACK, 0.9 * side), 6, plait_color)
		for k in 11:
			var sv := k * 0.36
			var dir := (chain_pos(braid, sv + 0.1) - chain_pos(braid, sv)).normalized()
			var basis := Basis(dir.cross(Vector3.BACK).normalized(), dir, Vector3.BACK).orthonormalized()
			basis = basis * Basis(Vector3.UP, 0.5 * (1 if k % 2 == 0 else -1))
			plaits.add_ellipsoid(chain_pos(braid, sv), Vector3(0.019, 0.022, 0.016),
					ClothRig.chain_weights(braid, sv, head_bone), basis, 6, plait_color)
		for k in 7:
			var sv := 1.0 + k * 0.42
			var color := BEAD if k >= 5 else (PEARL if k % 2 == 0 else PEARL_GREY)
			mesh(color, FINE_OUTLINE).add_ellipsoid(chain_pos(braid, sv), Vector3(0.017, 0.013, 0.017),
					ClothRig.chain_weights(braid, sv, head_bone), Basis(), 6)
		var tuft := []
		for sv: float in [3.65, 3.9, 4.2]:
			tuft.append(ring(chain_pos(braid, sv), chain_pos(braid, sv + 0.1) - chain_pos(braid, sv),
					Vector2(0.018, 0.015) * (1.0 if sv < 4.0 else 0.15), Vector3.BACK, ClothRig.chain_weights(braid, sv, head_bone)))
		plaits.add_tube(tuft, false, true)

	# --- Clothes ------------------------------------------------------------------------------------------

	func _upper_clothes() -> void:
		var neck := bone(&"Neck")
		var uc := bone(&"UpperChest")
		mesh(COLLAR).add_tube([  # dark high collar under her chin, as in her portrait
				ring(Vector3(0, 1.45, -0.05), Vector3.UP, Vector2(0.064, 0.06), Vector3.BACK, {uc: 0.6, neck: 0.4}),
				ring(Vector3(0, 1.5, -0.058), Vector3.UP, Vector2(0.054, 0.051), Vector3.BACK, {uc: 0.2, neck: 0.8}),
				ring(Vector3(0, 1.522, -0.06), Vector3.UP, Vector2(0.051, 0.048), Vector3.BACK, {neck: 1.0})], false, true,
				12, 0.0, 0.0)
		# The cream dress shows in a V at the tunic's neck, edged in gold (like the portrait).
		var v_points := [[], [], [], [], []]
		var v_weights := [[], [], [], [], []]
		for i in 7:
			var t := i / 6.0
			var y := lerpf(1.452, 1.372, t)
			for k in 5:  # across the V, following the curve of her chest
				var x := lerpf(-0.031, 0.031, k / 4.0) * (1.0 - t)
				v_points[k].append(torso_surface(y, x, true, 0.0042))
				v_weights[k].append(torso_at(y)[3])
		mesh(DRESS, 0.0).add_sheet(v_points, v_weights, Vector3(0, 1.4, -0.05), false)
		for k: float in [-1.0, 1.0]:
			var edge := func(bu: float, _bv: float) -> Array:
				var y := lerpf(1.452, 1.372, bu)
				var x := k * 0.031 * (1.0 - bu)
				var info := torso_at(y)
				var q := torso_surface(y, x, true, 0.0)
				return [q, Vector3(x / pow(info[0], 2.0), 0.0, (q.z - info[2]) / pow(info[1], 2.0)).normalized(), info[3]]
			stitch(mesh(GOLD, 0.0), edge, [Vector2(0, 0), Vector2(0.5, 0), Vector2(1, 0)], 0.006, 0.0055)
			embroider(torso_band(k * 0.045, k * 0.072, 1.3, 1.0))  # embroidered borders down the tunic's front
		for x: float in [-0.035, 0.035]:  # gold trim down the tunic's front
			var rings := []
			for y: float in [1.44, 1.34, 1.24, 1.12, 1.0]:
				var t := torso_at(y)
				rings.append(ring(torso_surface(y, x, true, 0.003), Vector3.DOWN, Vector2(0.008, 0.004), Vector3.BACK, t[3]))
			mesh(GOLD, 0.0).add_tube(rings)
		_capelet(uc, neck)
		mesh(GOLD).add_ellipsoid(Vector3(0, 1.49, 0.018), Vector3(0.017, 0.017, 0.009), {uc: 0.4, neck: 0.6}, Basis(), 6)  # clasp
		for k: float in [-1.0, 1.0]:  # gold toggles holding the capelet at her neck
			mesh(GOLD).add_box(Vector3(k * 0.024, 1.478, 0.017), Vector3(0.022, 0.007, 0.007), {uc: 0.5, neck: 0.5},
					Basis(Vector3.BACK, k * 0.25))
		mesh(CAPE).add_ellipsoid(Vector3(0, 1.47, -0.14), Vector3(0.15, 0.072, 0.085), {uc: 0.7, neck: 0.3})      # hood
		mesh(CAPE).add_ellipsoid(Vector3(0, 1.41, -0.17), Vector3(0.11, 0.06, 0.06), {uc: 1.0})
		mesh(GOLD).add_tube([
				ring(Vector3(0, 1.505, -0.14), Vector3.UP, Vector2(0.135, 0.07), Vector3.BACK, {uc: 0.7, neck: 0.3}),
				ring(Vector3(0, 1.52, -0.14), Vector3.UP, Vector2(0.12, 0.06), Vector3.BACK, {uc: 0.7, neck: 0.3})], false, false)

	## Hooded capelet: a flat shelf over her shoulders that falls to mid-chest, open at the front in a V (as on her
	## design sheet) and edged in gold, with a band of gold scrollwork round its hem and up the opening; its edge
	## follows the arms a little.
	func _capelet(uc: int, neck: int) -> void:
		var at_row := func(values: Array, t: float) -> float:
			for i in CAPELET_ROWS.size() - 1:
				if t <= CAPELET_ROWS[i + 1] or i == CAPELET_ROWS.size() - 2:
					return lerpf(values[i], values[i + 1], clampf(inverse_lerp(CAPELET_ROWS[i], CAPELET_ROWS[i + 1], t), 0.0, 1.0))
			return values[values.size() - 1]
		var shape := func(t: float, a: float) -> Vector3:
			var side := pow(sin(a), 2.0)
			var rx: float = at_row.call([0.075, 0.2, 0.28, 0.31, 0.315, 0.322], t)
			var rz: float = at_row.call([0.068, 0.13, 0.17, 0.19, 0.2, 0.205], t)
			var y_side: float = at_row.call([1.53, 1.525, 1.48, 1.4, 1.33, 1.31], t)
			var y_front: float = at_row.call([1.505, 1.47, 1.42, 1.36, 1.31, 1.29], t)
			var cz := lerpf(-0.056, -0.01, t)
			return Vector3(sin(a) * rx, lerpf(y_front, y_side, side), cz + cos(a) * rz)
		var weights := func(t: float, a: float) -> Dictionary:
			if t < 0.001:
				return {uc: 0.4, neck: 0.6}
			var follow := clampf((absf(sin(a)) - 0.6) / 0.4, 0.0, 1.0) * clampf((t - 0.4) / 0.6, 0.0, 1.0) * 0.35
			return ClothRig.mix({uc: 1.0}, {side_bone(1.0 if sin(a) >= 0.0 else -1.0, "UpperArm"): 1.0}, follow)
		var opening := func(t: float) -> float:  # half-angle of the V at the front, closed at the neck
			return lerpf(0.1, 0.42, clampf(t, 0.0, 1.0))
		var columns := 28
		for part: Array in [[CAPE, CAPELET_ROWS.slice(0, 5)], [GOLD, CAPELET_ROWS.slice(4, 6)]]:
			var points := []
			var ws := []
			for t: float in part[1]:
				var row_p := []
				var row_w := []
				var o: float = opening.call(t)
				for c in columns + 1:
					var a := lerpf(o, TAU - o, float(c) / columns)
					row_p.append(shape.call(t, a))
					row_w.append(weights.call(t, a))
				points.append(row_p)
				ws.append(row_w)
			mesh(part[0]).add_sheet(points, ws, Vector3(0, 1.3, -0.03))
		for sgn: float in [1.0, -1.0]:  # gold edges down the opening
			var points := []
			var ws := []
			for t: float in steps(0.0, 1.06, 0.106):
				var row_p := []
				var row_w := []
				for d: float in [0.0, 0.075]:
					var a: float = opening.call(t) + d
					a = a if sgn > 0.0 else TAU - a
					row_p.append(shape.call(t, a) + Vector3(sin(a), 0.0, cos(a)) * 0.0025)
					row_w.append(weights.call(t, a))
				points.append(row_p)
				ws.append(row_w)
			mesh(GOLD).add_sheet(points, ws, Vector3(0, 1.3, -0.03))
			var edge_band := func(bu: float, bv: float) -> Array:
				var t := lerpf(0.06, 0.72, bu)
				var a: float = opening.call(t) + lerpf(0.1, 0.22, (bv + 1.0) * 0.5)
				a = a if sgn > 0.0 else TAU - a
				return [shape.call(t, a), Vector3(sin(a), 0.0, cos(a)), weights.call(t, a)]
			embroider(edge_band, true, 0.0045)
		var hem_band := func(bu: float, bv: float) -> Array:
			var t := lerpf(0.75, 0.94, (bv + 1.0) * 0.5)
			var o: float = opening.call(t) + 0.1
			var a := lerpf(o, TAU - o, bu)
			return [shape.call(t, a), Vector3(sin(a), 0.0, cos(a)), weights.call(t, a)]
		embroider(hem_band, true, 0.0045)

	func _cape() -> void:
		var uc := bone(&"UpperChest")
		var center := Vector3(0, 0, 0.05)
		var front := Vector3(0, 0.95, 0.2)
		var cols := steps(0.0, CAPE_COLUMNS.size() - 1.0, 0.5)
		chain_sheet(mesh(CAPE), cape_chains, uc, center, cols, steps(0.0, 3.82, 0.5), front)
		chain_sheet(mesh(GOLD), cape_chains, uc, center, cols, [3.82, 4.0], front)
		var last := CAPE_COLUMNS.size() - 1.0
		for u: Array in [[0.0, 0.06], [last - 0.06, last]]:  # gold side edges
			chain_sheet(mesh(GOLD), cape_chains, uc, center, u, steps(0.4, 3.82, 0.5), front)
		embroider(sheet_band(cape_chains, uc, center, 0.16, last - 0.16, 3.4, 3.72))  # gold scrollwork along the hem
		for u: Array in [[0.1, 0.34], [last - 0.1, last - 0.34]]:  # ... and up both edges
			embroider(sheet_band(cape_chains, uc, center, u[0], u[1], 3.3, 0.55, true))

	func _skirts() -> void:
		var hips := bone(&"Hips")
		var center := Vector3(0, 0, -0.02)
		var inside := Vector3(0, 0.7, -0.02)
		var skirt_cols := steps(0.0, SKIRT_CHAINS - 1.0, 0.25)
		chain_sheet(mesh(DRESS, 0.0), skirt_chains, hips, center, skirt_cols, steps(0.0, 1.9, 0.5), inside)
		chain_sheet(mesh(DRESS_HEM, 0.0), skirt_chains, hips, center, skirt_cols, [1.9, 2.0], inside)
		var last := TUNIC_CHAINS - 1.0
		var cols := steps(0.0, last, 1.0 / 3.0)
		chain_sheet(mesh(COAT), tunic_chains, hips, center, cols, steps(0.0, 2.85, 0.5), inside)
		chain_sheet(mesh(GOLD), tunic_chains, hips, center, cols, [2.85, 3.0], inside)
		for u: Array in [[0.0, 0.12], [last - 0.12, last]]:  # gold edges along the front opening
			chain_sheet(mesh(GOLD), tunic_chains, hips, center, u, steps(0.1, 2.85, 0.5), inside)
		embroider(sheet_band(tunic_chains, hips, center, 0.2, last - 0.2, 2.45, 2.76))  # gold scrollwork along the hem
		for u: Array in [[0.15, 0.45], [last - 0.15, last - 0.45]]:  # ... and down the front edges
			embroider(sheet_band(tunic_chains, hips, center, u[0], u[1], 0.25, 2.38, true))
		for sv: float in [1.7, 1.8]:  # two woven lines near the cream dress's hem
			var line := sheet_band(skirt_chains, hips, center, 0.0, SKIRT_CHAINS - 1.0, sv, sv)
			var uv := []
			for u: float in steps(0.0, 1.0, 0.05):
				uv.append(Vector2(u, 0.0))
			stitch(mesh(DRESS_LINE, 0.0), line, uv, 0.005 if sv < 1.75 else 0.0025, 0.002)

	func _belts_and_gear() -> void:
		var hips := bone(&"Hips")
		var spine := bone(&"Spine")
		var belt_w := {hips: 0.6, spine: 0.4}
		var b := mesh(LEATHER)
		b.add_tube([ring(Vector3(0, 0.968, -0.02), Vector3.UP, Vector2(0.17, 0.13), Vector3.BACK, belt_w),
				ring(Vector3(0, 0.99, -0.02), Vector3.UP, Vector2(0.174, 0.134), Vector3.BACK, belt_w),
				ring(Vector3(0, 1.013, -0.02), Vector3.UP, Vector2(0.17, 0.13), Vector3.BACK, belt_w)], true, true, 12, 0.0, 0.0)
		var tilt := Vector3(sin(-0.2), cos(-0.2), 0.0)
		b.add_tube([ring(Vector3(0, 0.905, -0.02) - tilt * 0.016, tilt, Vector2(0.2, 0.16), Vector3.BACK, {hips: 1.0}),
				ring(Vector3(0, 0.905, -0.02) + tilt * 0.016, tilt, Vector2(0.2, 0.16), Vector3.BACK, {hips: 1.0})],
				true, true, 12, 0.0, 0.0)
		buckle(Vector3(0, 0.99, 0.114), Vector3.BACK, Vector3.UP, Vector2(0.046, 0.04), belt_w)
		var low_front := Vector3(sin(0.4), 0.0, cos(0.4))
		buckle(Vector3(0.068, 0.919, 0.128), low_front, tilt, Vector2(0.036, 0.032), {hips: 1.0})
		for deg: float in [-62.0, -40.0, -20.0, 20.0, 40.0, 62.0]:  # studs round the belt
			var a := deg_to_rad(deg)
			stud(Vector3(sin(a) * 0.177, 0.99, -0.02 + cos(a) * 0.137), belt_w)
		for side_front: bool in [true, false]:  # strap from the right shoulder to the left hip
			var rings := []
			for i in 9:
				var t := i / 8.0
				var y := lerpf(1.42, 1.0, t)
				var x := lerpf(-0.11, 0.14, t)
				var p := torso_surface(y, x, side_front, 0.008)
				var info := torso_at(y)
				var normal := Vector3(x / pow(info[0], 2.0), 0.0, (p.z - info[2]) / pow(info[1], 2.0)).normalized()
				rings.append(ring(p, Vector3(0.25, -0.42, 0.0), Vector2(0.016, 0.004), normal, info[3]))
			b.add_tube(rings, true, true, 12, 0.0, 0.0)
		var strap_y := 1.25  # a steel buckle on the strap, on her chest
		var strap_x := lerpf(-0.11, 0.14, inverse_lerp(1.42, 1.0, strap_y))
		var strap_at := torso_surface(strap_y, strap_x, true, 0.012)
		var strap_info := torso_at(strap_y)
		var strap_n := Vector3(strap_x / pow(strap_info[0], 2.0), 0.0, (strap_at.z - strap_info[2]) / pow(strap_info[1], 2.0)).normalized()
		buckle(strap_at, strap_n, Vector3(-0.25, 0.42, 0.0).normalized(), Vector2(0.03, 0.026), strap_info[3])
		var turn := Basis(Vector3.UP, -0.9)
		b.add_box(Vector3(-0.19, 0.875, 0.07), Vector3(0.07, 0.08, 0.045), {hips: 1.0}, turn)  # pouch, right hip
		mesh(SATCHEL).add_box(Vector3(-0.19, 0.9, 0.07) + turn.z * 0.025, Vector3(0.074, 0.035, 0.008), {hips: 1.0}, turn)
		var sat := {satchel[0]: 1.0}
		var face := Basis(Vector3.UP, deg_to_rad(70.0))
		var c := Vector3(0.245, 0.85, 0.09)
		mesh(SATCHEL).add_box(c, Vector3(0.15, 0.13, 0.05), sat, face)
		b.add_box(c + face.z * 0.027 + Vector3(0, 0.03, 0), Vector3(0.155, 0.072, 0.008), sat, face)  # flap
		b.add_box(c + face.z * 0.03 + Vector3(0, -0.02, 0), Vector3(0.026, 0.07, 0.006), sat, face)  # front strap
		buckle(c + face.z * 0.034 + Vector3(0, -0.032, 0), face.z, Vector3.UP, Vector2(0.03, 0.024), sat)
		mesh(METAL, FINE_OUTLINE).add_box(c + face.z * 0.034 + Vector3(0, 0.03, 0), Vector3(0.026, 0.026, 0.004), sat,
				face * Basis(Vector3.BACK, PI / 4.0))  # diamond plate on the flap
		mesh(STRAP_LIGHT, 0.0).add_box(c + face.z * 0.0315 + Vector3(0, -0.0045, 0), Vector3(0.15, 0.003, 0.002), sat, face)  # stitched edge
		stud(Vector3(-0.19, 0.9, 0.07) + turn.z * 0.03, {hips: 1.0}, 0.006)  # button on the pouch
		var strap_top := rest(satchel[0])
		var strap_end := c + Vector3(0, 0.06, 0)
		var strap_dir := (strap_end - strap_top).normalized()
		b.add_box((strap_top + strap_end) * 0.5, Vector3(0.02, strap_top.distance_to(strap_end), 0.006), sat,
				Basis(strap_dir.cross(face.z).normalized(), strap_dir, face.z).orthonormalized())

	# --- Finishing ----------------------------------------------------------------------------------------

	func _finish() -> void:
		var skin := SkinnedMeshBuilder.make_skin(sk)
		for key: String in _builders:
			var entry: Array = _builders[key]
			var builder: SkinnedMeshBuilder = entry[0]
			if builder.is_empty():
				continue
			var color: Color = entry[1]
			var outline: float = entry[2]
			var mi := MeshInstance3D.new()
			mi.name = "Aurelia_" + (key if key == "paint" else color.to_html(false))
			mi.mesh = builder.commit()
			mi.skin = skin
			mi.extra_cull_margin = 1.0
			var albedo := Color.WHITE if builder.vertex_colors else color
			var shade_key := SKIN if key == "paint" else color  # the paint lies on her skin: shade it the same
			var material: ShaderMaterial
			if SOFT_SHADES.has(shade_key):
				material = ToonMaterials.soft(albedo, SOFT_RIM, outline, {"use_vertex_color": builder.vertex_colors,
						"shade_tint": SOFT_SHADES[shade_key], "light_amount": SOFT_LIGHT, "light_tint": SOFT_TINT,
						"shade_amount": SOFT_SHADE})
			else:
				material = ToonMaterials.toon(albedo, RIM_OVERRIDES.get(color, 0.35), outline)
			if material.next_pass:
				var line := material.next_pass as ShaderMaterial
				line.set_shader_parameter(&"thickness", CLOSE_LINES.get(outline, outline * 0.35))
				line.set_shader_parameter(&"min_pixels", outline / GAME_PIXEL)
				if OUTLINE_TINTS.has(color):
					line.set_shader_parameter(&"outline_color", OUTLINE_TINTS[color])
			mi.material_override = material
			sk.add_child(mi)
			mi.skeleton = NodePath("..")

	func _physics() -> void:
		var hair_sim := _simulator("HairPhysics")
		for chain in hair_chains:
			ClothRig.simulate(hair_sim, sk, chain, CLOTH.hair)
		for chain in lock_chains:
			ClothRig.simulate(hair_sim, sk, chain, CLOTH.side_locks)
		ClothRig.simulate(hair_sim, sk, braid, CLOTH.braid)
		var head_ball := SpringBoneCollisionSphere3D.new()
		head_ball.bone_name = &"Head"
		head_ball.position_offset = Vector3(0, 0.11, 0)
		head_ball.radius = 0.13
		hair_sim.add_child(head_ball)
		ClothRig.add_capsule(hair_sim, &"UpperChest", Vector3(0, 0.0, -0.01), 0.16, 0.5)
		var cape_sim := _simulator("CapePhysics")
		for chain in cape_chains:
			ClothRig.simulate(cape_sim, sk, chain, CLOTH.cape)
		ClothRig.add_capsule(cape_sim, &"Spine", Vector3(0, 0.1, -0.01), 0.12, 0.5)
		ClothRig.add_capsule(cape_sim, &"UpperChest", Vector3(0, 0.0, -0.01), 0.12, 0.35)
		var skirt_ball := SpringBoneCollisionSphere3D.new()  # the flared skirts behind her
		skirt_ball.bone_name = &"Hips"
		skirt_ball.position_offset = Vector3(0, -0.3, -0.02)
		skirt_ball.radius = 0.24
		cape_sim.add_child(skirt_ball)
		var skirt_sim := _simulator("SkirtPhysics")
		for chain in tunic_chains:
			ClothRig.simulate(skirt_sim, sk, chain, CLOTH.tunic)
		for chain in skirt_chains:
			ClothRig.simulate(skirt_sim, sk, chain, CLOTH.skirt)
		ClothRig.simulate(skirt_sim, sk, satchel, CLOTH.satchel)
		for sim: SpringBoneSimulator3D in [cape_sim, skirt_sim]:
			for s in ["Left", "Right"]:
				ClothRig.add_capsule(sim, StringName(s + "UpperLeg"), Vector3(0, 0.2, 0), 0.1, 0.5)
				ClothRig.add_capsule(sim, StringName(s + "LowerLeg"), Vector3(0, 0.2, 0), 0.07, 0.45)

	func _simulator(sim_name: String) -> SpringBoneSimulator3D:
		var sim := SpringBoneSimulator3D.new()
		sim.name = sim_name
		sk.add_child(sim)
		return sim
