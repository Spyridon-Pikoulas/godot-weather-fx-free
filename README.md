# Weather FX Free

**3 animated 2D weather effects for Godot 4, free, one line of code each.** Every effect is a single
shader on a single node: no textures, no particle setup, sharp at any size.

```gdscript
var rain := WeatherFX.add(self, "rain", {density = 0.8})
WeatherFX.add(self, "fog", {color = Color.LAVENDER}).fade_in(3.0)
rain.stop(2.0)
```

### What's inside

- **rain**, with splashes where it meets the ground, **snow** and **fog**: they cover the screen
  and follow the camera, while the patterns stay put in the world.
- Colour, strength, speed and wind on every effect, plus density, drop length, flake size, fog
  height and more.
- **Pixel-art mode:** `WeatherFX.default_pixel_size = 4` and the effects draw in crisp pixels that
  match your art.
- `fade_in()` and `stop()` for weather that comes and goes.
- Drop a WeatherFX node in a scene and it previews itself in the editor.

### Want more?

**[Weather FX](https://heyheythere.itch.io/weather-fx)** has all 12: lightning, a lake that reflects your scene, a waterfall,
falling leaves, cloud shadows, god rays, heat haze, underwater caustics and a day-night cycle on top of
these three. Same node, same code: install it over this one.

### Compatibility

- Godot **4.3 to 4.7**, tested on both ends.
- **Forward+, Mobile and Compatibility** renderers: desktop, mobile and web.
- GDScript only: no C#, no GDExtension.

### Install

Copy `addons/weather_fx/` into your project. Open `demo/demo.tscn` to try the effects.

### License

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/): use it in any game, commercial or not,
change it and share it, as long as you credit it. The credit line, for your game's credits:

`Weather FX Free by heyheythere - https://heyheythere.itch.io/weather-fx-free - CC BY 4.0`

*Made with AI assistance (code, text, demo art), tested in Godot 4.3 and 4.7 on every renderer.*
