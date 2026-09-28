extends Node2D
## Turn effects on and off over a pixel-art landscape; they stack. Click to strike lightning.

const LANDSCAPE := preload("res://addons/weather_fx/demo/landscape.gd")
const ZOOM := 4
const GROUND := 0.66
const LAKE := 0.69
const START := ["water", "fog", "god_rays", "snow"]   # the first three installed are on

var land: Node2D
var mood := "dusk"
var active := {}
var buttons := {}
var weather := CanvasLayer.new()
var haze := CanvasLayer.new()


func _ready() -> void:
	# Water and heat haze read the screen as it was when the first of them drew on their layer:
	# the landscape goes below them, and heat haze on a layer of its own, to see the water too.
	weather.layer = 1
	add_child(weather)
	haze.layer = 2
	add_child(haze)
	var ui := CanvasLayer.new()
	ui.layer = 10      # above the weather, so day_night doesn't tint it
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	ui.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var moods := OptionButton.new()
	for m in LANDSCAPE.MOODS:
		moods.add_item(m)
	moods.select(LANDSCAPE.MOODS.keys().find(mood))
	moods.item_selected.connect(func(i: int) -> void:
		mood = moods.get_item_text(i)
		_build_land())
	box.add_child(moods)
	for name in WeatherFX.effects():
		var b := CheckButton.new()
		b.text = name
		b.custom_minimum_size = Vector2(190, 0)
		b.toggled.connect(func(on: bool) -> void: _toggle(name, on))
		box.add_child(b)
		buttons[name] = b
	var pixel := CheckBox.new()
	pixel.text = "pixel art"
	pixel.toggled.connect(func(on: bool) -> void: WeatherFX.default_pixel_size = ZOOM if on else 0)
	box.add_child(pixel)
	if "lightning" in WeatherFX.effects():
		var hint := Label.new()
		hint.text = "Click to strike lightning."
		hint.position = Vector2(230, 16)
		hint.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.12))
		hint.add_theme_constant_override("outline_size", 8)
		ui.add_child(hint)
	_build_land()
	for name in START.filter(func(e: String) -> bool: return e in buttons).slice(0, 3):
		buttons[name].button_pressed = true


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and "lightning" in buttons:
		buttons["lightning"].button_pressed = true
		active["lightning"].strike()


func _build_land() -> void:
	if land:
		land.queue_free()
	land = LANDSCAPE.new()
	land.mood = mood
	land.art_size = Vector2i(get_viewport_rect().size) / ZOOM
	land.zoom = ZOOM
	land.ground = GROUND
	land.lake = LAKE if "water" in buttons else 0.0   # no bare lake without water
	land.cliff = 0.2 if "waterfall" in active else 0.0
	land.sprites = [["bush", 0.36], ["mushroom", 0.5], ["slime", 0.66], ["chest", 0.88]]
	add_child(land)
	move_child(land, 0)


func _toggle(name: String, on: bool) -> void:
	if not on:
		if name in active:
			active[name].stop(0.4)
			active.erase(name)
		if name == "waterfall":
			_build_land()
		return
	var size := get_viewport_rect().size
	var options := {}
	match name:
		"water":
			options = {position = Vector2(0, land.lake_y()), size = Vector2(size.x, size.y - land.lake_y())}
		"waterfall":
			var top := int(land.art_size.y * 0.2) * ZOOM - 4.0
			options = {position = Vector2(size.x * 0.5 - 48, top), size = Vector2(96, land.lake_y() - top + 24)}
		"lightning":
			options = {ground = GROUND}
		"rain":
			options = {ground = 1.0 if "water" in buttons else GROUND + 0.01}
	active[name] = WeatherFX.add(haze if name == "heat_haze" else weather, name, options).fade_in(0.4)
	if name == "waterfall":
		_build_land()
	# Keep the drawing order of WeatherFX.EFFECTS: water under the rain, day_night over all.
	var i := 0
	for e in WeatherFX.EFFECTS:
		if e in active and e != "heat_haze":
			weather.move_child(active[e], i)
			i += 1
