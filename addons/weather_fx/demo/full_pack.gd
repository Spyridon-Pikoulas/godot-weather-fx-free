extends CanvasLayer
## The free sampler's line to its full pack, along the foot of the demo. Store captures leave it out.

const TEXT := "Weather FX has all 12: lightning, a lake that reflects your scene, a waterfall, falling leaves, cloud shadows, god rays, heat haze, underwater caustics and a day-night cycle on top of these three."
const NAME := "Weather FX"
const URL := "https://heyheythere.itch.io/weather-fx"


func _ready() -> void:
	layer = 100
	if Engine.get_write_movie_path() != "":
		return
	await get_tree().process_frame
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	if main.begins_with("uid://"):
		main = ResourceUID.get_id_path(ResourceUID.text_to_id(main))
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != main:
		return
	var bar := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.08, 0.86)
	bg.content_margin_left = 12
	bg.content_margin_right = 12
	bg.content_margin_top = 6
	bg.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", bg)
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	var label := Label.new()
	label.text = TEXT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.92))
	row.add_child(label)
	var link := Button.new()
	link.text = "Get " + NAME
	link.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	link.pressed.connect(func() -> void: OS.shell_open(URL))
	row.add_child(link)
