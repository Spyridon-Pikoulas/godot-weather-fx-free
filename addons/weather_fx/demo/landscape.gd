extends Node2D
## A pixel-art landscape to show the weather on, drawn from shapes into an image `art_size`
## pixels big and shown `zoom` times bigger: sky, mountains, hills, trees, ground, a lake. The
## "meadow" mood is seen from above instead, for top-down games.

const ART := "res://addons/weather_fx/demo/art/%s.png"
## Colours per mood. sky: top, middle, horizon.
const MOODS := {
	"day": {sky = ["#3b7dd8", "#6fa8e8", "#c4e3f6"], far = "#8fa5cc", cap = "#eef4ff",
		hill = "#5f9e6e", hill2 = "#43805a", tree = "#2a5a3d", grass = "#6cbf4a", grass_hi = "#a2e070",
		dirt = "#6b4a35", dirt2 = "#523827", lake = "#3a78b0", sun = "#fff4c0", trees = "round"},
	"dawn": {sky = ["#56689e", "#c795ae", "#f6d7ba"], far = "#a197bd", cap = "#f4e6f0",
		hill = "#7c7f9e", hill2 = "#5a5f80", tree = "#363b5a", grass = "#5f7a62", grass_hi = "#7f9c78",
		dirt = "#4a4250", dirt2 = "#3a3442", lake = "#5a6a94", sun = "#fff0d8", trees = "pine"},
	"dusk": {sky = ["#231d48", "#a44e6c", "#f6a45e"], far = "#5d3f70", cap = "#c89ab0",
		hill = "#3e2d55", hill2 = "#2c2143", tree = "#1b1432", grass = "#3b3a5a", grass_hi = "#55527a",
		dirt = "#2a2238", dirt2 = "#1f1a2c", lake = "#3a3468", sun = "#ffcf7a", trees = "pine"},
	"night": {sky = ["#060918", "#121a3c", "#2a3464"], far = "#1f2650", cap = "#8d9ac8",
		hill = "#18223e", hill2 = "#111a30", tree = "#0a1122", grass = "#1d3440", grass_hi = "#2c4a56",
		dirt = "#131828", dirt2 = "#0d111e", lake = "#1a2448", moon = "#e8ecff", stars = true, trees = "pine"},
	"storm": {sky = ["#1c2029", "#323845", "#56606e"], far = "#383f4e", cap = "#687082",
		hill = "#34483f", hill2 = "#263630", tree = "#16221d", grass = "#3f5e44", grass_hi = "#587c5a",
		dirt = "#2d2620", dirt2 = "#221c18", lake = "#2c3846", trees = "pine"},
	"snow": {sky = ["#18214a", "#364a82", "#8196c4"], far = "#5d6d9e", cap = "#e8efff",
		hill = "#b9c6e6", hill2 = "#98a8d2", tree = "#1d3048", grass = "#e3ebfb", grass_hi = "#ffffff",
		dirt = "#aebcdc", dirt2 = "#98a8cc", lake = "#3a4c80", moon = "#f4f6ff", stars = true,
		trees = "snowpine"},
	"autumn": {sky = ["#4a82c6", "#8cb6df", "#f2ddb8"], far = "#9c9cbc", cap = "#f2f0f6",
		hill = "#b27a48", hill2 = "#8c5a36", tree = "#d8641e", grass = "#a19a42", grass_hi = "#c8bc5a",
		dirt = "#6b4a35", dirt2 = "#523827", lake = "#3a78b0", sun = "#fff0c0", trees = "autumn"},
	"desert": {sky = ["#4e98d6", "#9fcbe8", "#f6e6c4"], far = "#d6a377", cap = "#e6b88a",
		hill = "#e8c283", hill2 = "#d6a66a", tree = "#4f8a4a", grass = "#ecd08e", grass_hi = "#f8e4ac",
		dirt = "#d2a466", dirt2 = "#bf8f55", lake = "#3a78b0", sun = "#fffbe8", trees = "cactus"},
	"forest": {sky = ["#1c3a34", "#3f6a50", "#8fae78"], far = "#2a4a40", cap = "#2a4a40",
		hill = "#22382e", hill2 = "#182a22", tree = "#0f1c17", grass = "#2f4a2c", grass_hi = "#46663c",
		dirt = "#1e1a16", dirt2 = "#16120f", lake = "#1c3a44", trees = "trunks"},
	"underwater": {sky = ["#0d6f8a", "#0b4f78", "#0a2f58"], far = "#0f3a60", cap = "#0f3a60",
		hill = "#14466a", hill2 = "#0e3558", tree = "#2f8a5a", grass = "#b8a272", grass_hi = "#ccb886",
		dirt = "#9c8458", dirt2 = "#9c8258", lake = "#0a2f58", trees = "kelp"},
	"meadow": {sky = ["#3b7dd8", "#6fa8e8", "#c4e3f6"], far = "#8fa5cc", cap = "#eef4ff",
		hill = "#4f9a48", hill2 = "#3f8440", tree = "#2f6e3a", grass = "#5eae4c", grass_hi = "#7cc85c",
		dirt = "#c49a64", dirt2 = "#a67e4e", lake = "#3a86c0", trees = "round"},
}

@export var mood := "day"
@export var art_size := Vector2i(320, 180)
@export var zoom := 4
## Where the ground starts, as a fraction of the height.
@export var ground := 0.8
## Where a lake starts, as a fraction of the height; 0 for none.
@export var lake := 0.0
## A cliff with a notch in the middle for a waterfall, its top as a fraction of the height; 0 for none.
@export var cliff := 0.0
@export var seed := 1
## [[sprite name, x as a fraction of the width], ...] standing on the ground.
@export var sprites: Array = []

var img: Image
var pal := {}
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()


func _ready() -> void:
	build()


func build() -> void:
	for c in get_children():
		c.queue_free()
	pal = {}
	for k in MOODS[mood]:
		var v: Variant = MOODS[mood][k]
		pal[k] = Color(v) if v is String and v.begins_with("#") else v
	rng.seed = seed
	noise.seed = seed
	noise.frequency = 0.08
	var w := art_size.x
	var h := art_size.y
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var gy := int(h * ground)
	if mood == "meadow":
		_meadow()
	else:
		var horizon := gy if mood != "underwater" else h
		_sky(horizon)
		if pal.get("stars", false):
			_stars(int(horizon * 0.7))
		if pal.has("sun"):
			var low := mood in ["dusk", "dawn"]
			_disc(Vector2(w * (0.78 if not low else 0.7), h * (0.2 if not low else ground - 0.22)),
					h * (0.07 if not low else 0.1), pal.sun, low)
		if pal.has("moon"):
			_moon(Vector2(w * 0.8, h * 0.17), h * 0.055)
		if mood == "forest":
			_forest(gy)
		elif mood == "underwater":
			_seabed(gy)
		else:
			_mountains(int(h * (ground - 0.14)), h * 0.24, pal.far, pal.cap)
			_hills(int(h * (ground - 0.07)), h * 0.07, pal.hill, 1.3, pal.trees != "cactus")
			_hills(int(h * (ground - 0.015)), h * 0.035, pal.hill2, 2.9, true)
			if cliff > 0.0:
				_cliff(int(h * cliff), gy)
			_ground(gy)
	if lake > 0.0:
		_lake(int(h * lake))
	for s in sprites:
		var tex: Texture2D = load(ART % s[0])
		var si := tex.get_image()
		si.convert(Image.FORMAT_RGBA8)
		var pos := Vector2i(int(w * s[1]) - si.get_width() / 2, gy - si.get_height() + 3)
		img.blend_rect(si, Rect2i(Vector2i.ZERO, si.get_size()), pos)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = false
	sprite.scale = Vector2(zoom, zoom)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)


## The ground line in this node's coordinates.
func ground_y() -> float:
	return int(art_size.y * ground) * zoom


func lake_y() -> float:
	return int(art_size.y * lake) * zoom


func _bayer(x: int, y: int) -> float:
	const M := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	return (M[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0


func _gradient(stops: Array, t: float) -> Color:
	t = clampf(t, 0.0, 1.0) * (stops.size() - 1)
	var i := mini(int(t), stops.size() - 2)
	return Color(stops[i]).lerp(Color(stops[i + 1]), t - i)


func _put(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < art_size.x and y < art_size.y:
		img.set_pixel(x, y, c)


## Banded sky: flat bands with a dithered seam between them, like hand-made pixel art.
func _sky(horizon: int) -> void:
	var bands := 8.0
	for y in horizon:
		var t := float(y) / maxf(horizon - 1, 1) * bands
		var lo := floorf(t)
		var a := _gradient(pal.sky, lo / bands)
		var b := _gradient(pal.sky, (lo + 1.0) / bands)
		var seam := clampf((t - lo - 0.55) / 0.45, 0.0, 1.0)
		for x in art_size.x:
			img.set_pixel(x, y, b if seam > _bayer(x, y) else a)
	if horizon < art_size.y:
		img.fill_rect(Rect2i(0, horizon, art_size.x, art_size.y - horizon), Color(pal.sky[2]))


func _stars(bottom: int) -> void:
	for i in art_size.x * bottom / 90:
		var x := rng.randi_range(0, art_size.x - 1)
		var y := rng.randi_range(0, bottom)
		img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color.WHITE, rng.randf_range(0.35, 1.0)))
		if rng.randf() < 0.08:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if x + d.x >= 0 and x + d.x < art_size.x and y + d.y >= 0:
					img.set_pixel(x + d.x, y + d.y, img.get_pixel(x + d.x, y + d.y).lerp(Color.WHITE, 0.45))


func _disc(c: Vector2, r: float, color: Color, glow: bool) -> void:
	for y in range(int(c.y - r * 3), int(c.y + r * 3) + 1):
		for x in range(int(c.x - r * 3), int(c.x + r * 3) + 1):
			if x < 0 or y < 0 or x >= art_size.x or y >= art_size.y:
				continue
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r:
				img.set_pixel(x, y, color)
			elif d <= r * (1.9 if glow else 1.45) and _bayer(x, y) < 0.5 * (1.0 - (d - r) / (r * 0.9)):
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(color, 0.3))


func _moon(c: Vector2, r: float) -> void:
	_disc(c, r, pal.moon, false)
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(r * 0.45, -r * 0.2)) < r * 0.85:
				img.set_pixel(x, y, _gradient(pal.sky, float(y) / (art_size.y * ground)))


## Jagged ridges, each peak shaded to the right of a ridge line running down from it.
func _mountains(base: int, amp: float, color: Color, cap: Color) -> void:
	var o := rng.randf() * 10.0
	var tops := PackedInt32Array()
	for x in art_size.x:
		var m := 0.0
		for k: Array in [[97.0, 0.6], [41.0, 0.28], [17.0, 0.12]]:
			m += absf(fposmod(x / k[0] + o * k[1], 1.0) - 0.5) * 2.0 * k[1]
		tops.append(int(base - amp * (1.0 - m) * 1.2 + amp * 0.2))
	var shade := color.darkened(0.14)
	for x in art_size.x:
		var top := tops[x]
		# The main peak this column belongs to, and how far right of it the ridge line has got.
		var xp := int((roundf(x / 97.0 + o * 0.6 - 0.5) + 0.5 - o * 0.6) * 97.0)
		var peak := tops[clampi(xp, 0, art_size.x - 1)]
		for y in range(top, art_size.y):
			var ridge := xp + (y - peak) * 0.35 + noise.get_noise_2d(x, y * 3.0) * 2.0
			img.set_pixel(x, y, shade if x > ridge else color)
		if top < base - amp * 0.5:
			var capped := int((base - amp * 0.5 - top) * 0.55) + 1
			for y in range(top, top + capped + (1 if _bayer(x, top + capped) < 0.5 else 0)):
				var ridge := xp + (y - peak) * 0.35 + noise.get_noise_2d(x, y * 3.0) * 2.0
				img.set_pixel(x, y, cap.darkened(0.12) if x > ridge else cap)


## Rolling hills with a lit top edge and trees along them.
func _hills(base: int, amp: float, color: Color, freq: float, with_trees: bool) -> void:
	var o := rng.randf() * 10.0
	var tops := PackedInt32Array()
	for x in art_size.x:
		var top := int(base - amp * (0.6 * sin(x * 0.02 * freq + o) + 0.4 * sin(x * 0.047 * freq + o * 2.0)))
		tops.append(top)
		img.fill_rect(Rect2i(x, top, 1, art_size.y - top), color)
		img.set_pixel(x, top, color.lightened(0.15))
		if noise.get_noise_2d(x * 2.0, top * 3.0 + o) > 0.35:
			img.fill_rect(Rect2i(x, top + 2, 1, 2), color.darkened(0.08))
	if not with_trees:
		return
	var x := rng.randi_range(2, 12)
	while x < art_size.x:
		_tree(x, tops[x] + 1, rng.randi_range(7, 13))
		x += rng.randi_range(5, 22) if rng.randf() < 0.7 else rng.randi_range(25, 50)


func _tree(x: int, y: int, h: int) -> void:
	var kind: String = pal.trees
	var c: Color = pal.tree
	match kind:
		"pine", "snowpine":
			var tier := maxi(h / 3, 2)
			for r in h:
				var half := int((r % tier) * 0.55 + r * 0.22)
				img.fill_rect(Rect2i(x - half, y - h + r, half + 1, 1), c.lightened(0.08))
				img.fill_rect(Rect2i(x + 1, y - h + r, half, 1), c)
				if kind == "snowpine" and r % tier == 0:
					img.fill_rect(Rect2i(x - half, y - h + r, half * 2 + 1, 1), pal.grass)
			img.fill_rect(Rect2i(x, y - 1, 1, 2), c.darkened(0.3))
		"round", "autumn":
			var leaf := c
			if kind == "autumn":
				leaf = [Color("#d8641e"), Color("#b83c1c"), Color("#e8a030")][rng.randi() % 3]
			img.fill_rect(Rect2i(x, y - 3, 1, 4), Color("#4a3325"))
			_blob(x, y - 3 - h * 0.32, h * 0.32, leaf)
		"cactus":
			if rng.randf() < 0.5:
				return
			img.fill_rect(Rect2i(x, y - h, 2, h), c)
			img.fill_rect(Rect2i(x - 2, y - h + 3, 1, 3), c)
			img.fill_rect(Rect2i(x - 2, y - h + 5, 2, 1), c)
			img.fill_rect(Rect2i(x + 3, y - h + 2, 1, 3), c)
			img.fill_rect(Rect2i(x + 2, y - h + 4, 2, 1), c)
			img.fill_rect(Rect2i(x, y - h, 1, h), c.lightened(0.2))


## A round canopy lit from the top left.
func _blob(x: float, cy: float, r: float, leaf: Color) -> void:
	for yy in range(int(cy - r) - 1, int(cy + r) + 2):
		for xx in range(int(x - r) - 1, int(x + r) + 2):
			var d := Vector2(xx - x, (yy - cy) * 1.1).length()
			if d <= r:
				var lit := Vector2(xx - x + r * 0.3, yy - cy + r * 0.3).length() < r * 0.5
				var dark := Vector2(xx - x + r * 0.2, yy - cy + r * 0.2).length() > r * 0.95
				_put(xx, yy, leaf.lightened(0.16) if lit else (leaf.darkened(0.2) if dark else leaf))


func _ground(gy: int) -> void:
	var h := art_size.y - gy
	img.fill_rect(Rect2i(0, gy, art_size.x, h), pal.dirt)
	for x in art_size.x:
		var g := 3 + int(noise.get_noise_2d(x * 3.0, 0.0) * 2.0 + 1.0)
		img.fill_rect(Rect2i(x, gy, 1, g), pal.grass)
		img.set_pixel(x, gy, pal.grass_hi)
		if rng.randf() < 0.3:
			img.set_pixel(x, gy - 1, pal.grass)
		for y in range(gy + g, art_size.y):
			if noise.get_noise_2d(x * 1.5, y * 4.0) > 0.3:
				img.set_pixel(x, y, pal.dirt2)


func _lake(ly: int) -> void:
	img.fill_rect(Rect2i(0, ly, art_size.x, art_size.y - ly), pal.lake)
	img.fill_rect(Rect2i(0, ly - 1, art_size.x, 1), Color(pal.grass).darkened(0.25))
	for i in art_size.x / 6:
		var x := rng.randi_range(0, art_size.x - 8)
		var y := rng.randi_range(ly + 2, art_size.y - 1)
		img.fill_rect(Rect2i(x, y, rng.randi_range(2, 7), 1), Color(pal.lake).lightened(0.15))


## A rock wall across the width with a notch in the middle for the water to pour through.
func _cliff(top: int, gy: int) -> void:
	var tones := [Color("#5a5048"), Color("#7a6e62"), Color("#968a7a"), Color("#aea290")]
	var cx := art_size.x / 2
	for x in art_size.x:
		var notch := maxf(0.0, 1.0 - absf(x - cx) / (art_size.x * 0.1))
		var t := top + int(notch * 4.0) + int(2.0 * sin(x * 0.3) + noise.get_noise_2d(x * 4.0, 50.0) * 2.0)
		for y in range(t, gy + 2):
			var n := noise.get_noise_2d(x * 0.45, y * 0.9) + noise.get_noise_2d(x * 2.0, y * 2.0) * 0.2
			var edge := noise.get_noise_2d(x * 0.45 - 1.5, y * 0.9 - 1.5)
			var tone := 1
			if n > 0.25:
				tone = 2 if edge < n else 3
			elif n < -0.3:
				tone = 0
			img.set_pixel(x, y, tones[tone])
		img.fill_rect(Rect2i(x, t - 1, 1, 3), pal.grass)
		img.set_pixel(x, t - 1, pal.grass_hi)


## Dark woods: trunks in two depths under a leafy canopy.
func _forest(gy: int) -> void:
	var w := art_size.x
	for depth: Array in [[Color(pal.hill), 4, 7], [Color(pal.tree), 7, 12]]:
		var x := rng.randi_range(0, 10)
		while x < w:
			var tw: int = rng.randi_range(depth[1], depth[2])
			img.fill_rect(Rect2i(x, 0, tw, gy), depth[0])
			img.fill_rect(Rect2i(x, 0, 1, gy), Color(depth[0]).lightened(0.08))
			x += tw + rng.randi_range(14, 40)
	for i in w / 3:
		var cx := rng.randi_range(-10, w + 10)
		var cy := rng.randi_range(-8, int(art_size.y * 0.16))
		var r := rng.randi_range(8, 16)
		for y in range(cy - r, cy + r + 1):
			for x in range(cx - r, cx + r + 1):
				if Vector2(x - cx, y - cy).length() <= r:
					var speck := noise.get_noise_2d(x * 3.0, y * 3.0) > 0.45
					_put(x, y, Color(pal.tree).lightened(0.07) if speck else Color(pal.tree))
	img.fill_rect(Rect2i(0, gy, w, art_size.y - gy), pal.grass)
	img.fill_rect(Rect2i(0, gy, w, 1), pal.grass_hi)
	for i in w / 4:
		img.set_pixel(rng.randi_range(0, w - 1), gy - 1, pal.grass)
		img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(gy + 2, art_size.y - 1), pal.dirt)


## Sea floor: sand, rocks and kelp.
func _seabed(gy: int) -> void:
	var w := art_size.x
	_hills(int(art_size.y * (ground - 0.08)), art_size.y * 0.09, pal.hill, 1.2, false)
	for x in w:
		var top := gy + int(2.0 * sin(x * 0.05))
		img.fill_rect(Rect2i(x, top, 1, art_size.y - top), pal.grass)
		img.set_pixel(x, top, pal.grass_hi)
	for i in w / 10:
		img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(gy + 3, art_size.y - 1), pal.dirt)
	var x := rng.randi_range(4, 20)
	while x < w:
		var kh := rng.randi_range(int(art_size.y * 0.15), int(art_size.y * 0.4))
		for y in kh:
			var sx := x + int(2.0 * sin(y * 0.25 + x))
			img.fill_rect(Rect2i(sx, gy - y, 2, 1), Color(pal.tree).darkened(0.25 * float(y) / kh))
		x += rng.randi_range(12, 40)
	for i in 5:
		var rx := rng.randi_range(0, w)
		var rr := rng.randi_range(4, 9)
		for y in range(-rr, 1):
			for xx in range(-rr * 2, rr * 2 + 1):
				if Vector2(xx * 0.5, y).length() <= rr:
					_put(rx + xx, gy + 2 + y, Color("#4a5a6a") if y < -rr / 2 or xx < 0 else Color("#3a4858"))


## Seen from above: a meadow with a dirt path, a pond and trees.
func _meadow() -> void:
	var w := art_size.x
	var h := art_size.y
	var pond := Vector2(w * 0.74, h * 0.62)
	var pr := Vector2(w * 0.13, h * 0.17)
	for y in h:
		var px := w * 0.36 + sin(y * 0.045 + seed) * w * 0.08
		for x in w:
			var n := noise.get_noise_2d(x, y)
			var c: Color = pal.grass
			if n > 0.2 + _bayer(x, y) * 0.12:
				c = pal.grass_hi
			elif n < -0.25 - _bayer(x, y) * 0.12:
				c = pal.hill
			var d := absf(x - px)
			if d < w * 0.028:
				c = pal.dirt if d < w * 0.02 else pal.dirt2
			var e := ((Vector2(x, y) - pond) / pr).length() + noise.get_noise_2d(x * 2.0, y * 2.0) * 0.08
			if e < 1.0:
				c = Color(pal.lake).lightened(0.12) if e > 0.86 else pal.lake
			elif e < 1.12:
				c = pal.dirt
			img.set_pixel(x, y, c)
	for i in w * h / 60:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		if img.get_pixel(x, y) == Color(pal.grass):
			img.set_pixel(x, y, [Color.WHITE, Color("#ffe070"), Color("#ff9ab8")][rng.randi() % 3])
	var placed := 0
	for i in 60:
		if placed >= w * h / 900:
			break
		var at := Vector2(rng.randi_range(0, w), rng.randi_range(0, h))
		var r := rng.randf_range(5.0, 9.0)
		var px := w * 0.36 + sin(at.y * 0.045 + seed) * w * 0.08
		if absf(at.x - px) < r + w * 0.03 or ((at - pond) / (pr + Vector2(r, r))).length() < 1.2:
			continue
		placed += 1
		for yy in range(int(at.y - r), int(at.y + r) + 4):
			for xx in range(int(at.x - r), int(at.x + r) + 4):
				if Vector2(xx - at.x - 3, yy - at.y - 3).length() <= r:
					_put(xx, yy, Color(pal.hill).darkened(0.35))
		_blob(at.x, at.y, r, pal.tree)
