@tool
class_name WeatherFX
extends Node2D
## 2D weather drawn by a shader: no textures, no particles, one node.
##
##     WeatherFX.add(self, "rain")                             # covers the view
##     WeatherFX.add(self, "fog", {density = 0.8, color = Color.LAVENDER}).fade_in(3.0)
##     WeatherFX.add(self, "water", {position = Vector2(0, 500), size = Vector2(1280, 220)})
##     $Storm.strike()                                         # lightning, now
##     rain.stop(2.0)                                          # fades out, then frees itself
##
## With size at zero, rain, snow, fog and the other screen-wide effects cover the whole view and
## follow the camera, while their patterns stay put in the world. Give a size to place an effect
## as a rect with its top-left corner at the node. Options set a property of the node (size,
## pixel_size, position...) or else a uniform of the shader; the uniforms are in its material.

signal finished

const SHADERS := "res://addons/weather_fx/shaders/%s.gdshader"
## size: zero covers the view; water and waterfall default to a rect.
const EFFECTS := {
	"rain": {"size": Vector2.ZERO},
	"snow": {"size": Vector2.ZERO},
	"fog": {"size": Vector2.ZERO},
	"cloud_shadows": {"size": Vector2.ZERO},
	"god_rays": {"size": Vector2.ZERO},
	"heat_haze": {"size": Vector2.ZERO},
	"water": {"size": Vector2(640, 160)},
	"waterfall": {"size": Vector2(96, 256)},
	"lightning": {"size": Vector2.ZERO},
	"leaves": {"size": Vector2.ZERO},
	"caustics": {"size": Vector2.ZERO},
	"day_night": {"size": Vector2.ZERO},
}

## Chunky pixels for every WeatherFX whose pixel_size is -1: set once, before adding any, for a
## pixel-art game.
static var default_pixel_size := 0

@export_enum("rain", "snow", "fog", "cloud_shadows", "god_rays", "heat_haze", "water", "waterfall",
		"lightning", "leaves", "caustics", "day_night")
var effect := "rain":
	set(v):
		effect = v
		_setup()
## Zero uses the effect's size: the whole view for most, a rect for water and waterfall.
@export var size := Vector2.ZERO:
	set(v):
		size = v
		_sync()
## Size of a pixel in pixels, 0 smooth; -1 follows WeatherFX.default_pixel_size.
@export_range(-1, 16, 1) var pixel_size := -1:
	set(v):
		pixel_size = v
		_sync()

var _rect := Rect2()
var _fading: Tween
var _strike_age := 100.0
var _strikes := 0


## The effects whose shader is installed.
static func effects() -> PackedStringArray:
	return PackedStringArray(EFFECTS.keys().filter(func(e: String) -> bool:
		return ResourceLoader.exists(SHADERS % e)))


## Adds an effect to `parent` and returns it. Options as in set_option().
static func add(parent: Node, name: String, options := {}) -> WeatherFX:
	var w := WeatherFX.new()
	w.effect = name
	w.set_param(&"seed", randf() * 10.0)
	for key in options:
		w.set_option(key, options[key])
	parent.add_child(w)
	return w


func set_option(key: StringName, value: Variant) -> void:
	if key in self:
		set(key, value)
	else:
		set_param(key, value)


func set_param(uniform: StringName, value: Variant) -> void:
	(material as ShaderMaterial).set_shader_parameter(uniform, value)


func get_param(uniform: StringName) -> Variant:
	return (material as ShaderMaterial).get_shader_parameter(uniform)


func get_size() -> Vector2:
	return size if size != Vector2.ZERO else EFFECTS.get(effect, EFFECTS["rain"])["size"]


## True when the effect covers the whole view.
func covers_view() -> bool:
	return get_size() == Vector2.ZERO


## The drawn rect, in the node's own coordinates.
func get_rect() -> Rect2:
	return _rect


## Fades in from nothing to its current intensity over `seconds`. Returns itself for chaining.
func fade_in(seconds := 1.0) -> WeatherFX:
	if _fading:
		_fading.kill()
	var to: Variant = get_param(&"intensity")
	set_param(&"intensity", 0.0)
	_fading = create_tween() if is_inside_tree() else null
	if _fading:
		_fading.tween_method(func(v: float) -> void: set_param(&"intensity", v), 0.0,
				1.0 if to == null else to, seconds)
	else:
		set_param(&"intensity", 1.0 if to == null else to)
	return self


## Fades out over `fade` seconds, then emits finished and frees itself.
func stop(fade := 1.0) -> void:
	if not is_inside_tree():
		return
	if _fading:
		_fading.kill()
	var from: Variant = get_param(&"intensity")
	_fading = create_tween()
	_fading.tween_method(func(v: float) -> void: set_param(&"intensity", v),
			1.0 if from == null else from, 0.0, fade)
	_fading.finished.connect(func() -> void:
		finished.emit()
		queue_free())


## Lightning: strikes now, on top of the strikes that come on their own (see `frequency`).
func strike() -> void:
	_strike_age = 0.0
	_strikes += 1
	set_param(&"strike_seed", float(_strikes) + randf() * 100.0)
	set_param(&"strike_age", 0.0)


func _init() -> void:
	_setup()


func _enter_tree() -> void:
	_sync()


func _process(delta: float) -> void:
	if effect == "lightning" and _strike_age < 100.0:
		_strike_age += delta
		set_param(&"strike_age", _strike_age)
	_sync()


func _setup() -> void:
	if effect not in EFFECTS or not ResourceLoader.exists(SHADERS % effect):
		push_error("WeatherFX: unknown effect %s, pick one of %s" % [effect, effects()])
		return
	var shader: Shader = load(SHADERS % effect)
	if not (material is ShaderMaterial and material.shader == shader):
		var m := ShaderMaterial.new()
		m.shader = shader
		m.resource_local_to_scene = true
		material = m
	_sync()


## Tracks the view (for effects that cover it) and tells the shader where the rect is.
func _sync() -> void:
	if not material is ShaderMaterial:
		return
	var rect := Rect2(Vector2.ZERO, get_size())
	if covers_view() and is_inside_tree():
		if Engine.is_editor_hint():
			# In the editor: the game's window, where the scene's origin is.
			rect = get_global_transform().affine_inverse() * Rect2(Vector2.ZERO, Vector2(
					ProjectSettings.get_setting("display/window/size/viewport_width"),
					ProjectSettings.get_setting("display/window/size/viewport_height")))
		else:
			rect = get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	var s := rect.size * get_global_transform().get_scale().abs()
	set_param(&"rect_size", s if s != Vector2.ZERO else Vector2.ONE)
	set_param(&"world_origin", get_global_transform() * rect.position)
	set_param(&"pixel_size", float(pixel_size if pixel_size >= 0 else default_pixel_size))
	if rect != _rect:
		_rect = rect
		queue_redraw()


func _draw() -> void:
	draw_rect(_rect, Color.WHITE)
