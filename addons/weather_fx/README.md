# Weather FX

12 animated 2D weather and water effects for Godot 4.3+ (Forward+, Mobile, Compatibility). Each is
one shader drawn by one `WeatherFX` node: no textures, no particles.

**The full pack:** **[Weather FX](https://heyheythere.itch.io/weather-fx)** has all 12: lightning, a lake that reflects your scene, a waterfall,
falling leaves, cloud shadows, god rays, heat haze, underwater caustics and a day-night cycle on top of
these three. Same node, same code: install it over this one.

## Add one

```gdscript
var rain := WeatherFX.add(self, "rain")                   # covers the view, follows the camera
WeatherFX.add(self, "fog", {density = 0.8}).fade_in(3.0)
WeatherFX.add(self, "water", {position = Vector2(0, 500), size = Vector2(1280, 220)})
var storm := WeatherFX.add(self, "lightning", {frequency = 0.0})
storm.strike()                                            # a strike, now
rain.stop(2.0)                                            # fades out, then frees itself
```

Or add a WeatherFX node to a scene and pick `effect`. It previews in the editor, and its material
holds the uniforms.

## Effects

`WeatherFX.effects()` lists them all.

- Cover the view: rain, snow, fog, cloud_shadows, god_rays, heat_haze, lightning, leaves,
  caustics, day_night
- Rects: water, waterfall (top-left corner at the node)

Give any effect a `size` to draw it as a rect instead. Patterns are anchored to the world, so they
stay put when the camera moves.

## Options

Options go to `add()` or `set_option()`. A key that names a property of the node sets it, any other
key sets the shader uniform: see the material in the inspector for each effect's own (`density`,
`wind`, `color`, `fall_speed`, `time_of_day`...).

| option | | |
|---|---|---|
| `size` | node | rect in pixels; zero covers the view (water and waterfall have a default rect) |
| `pixel_size` | node | pixel-art mode: size of a pixel; -1 follows `WeatherFX.default_pixel_size` |
| `position`, `z_index`... | node | any Node2D property |
| `intensity` | shader | strength, 0..2; `fade_in()` and `stop()` drive it |
| `speed` | shader | animation speed |
| `seed` | shader | variation; `add()` picks a random one |
| `color_steps` | shader | posterize to N levels per channel |

## Layering

Draw order is node order: add water before rain, and day_night last. Put your UI on a CanvasLayer
above the weather so day_night doesn't tint it.

Water and heat_haze read the screen, and see what was drawn before them on a lower CanvasLayer
(or the same layer, before the first screen reader on it). Keep the level on layer 0 and put them on
a CanvasLayer at 1; heat_haze over water needs a layer of its own above the water.

Rain splashes where it meets the `ground` uniform (0..1 down the view, 1 is off), lightning strikes
down to its own `ground`.

## Pixel art

```gdscript
WeatherFX.default_pixel_size = 4   # once, before adding effects
```

Effects then draw in 4x4 pixel blocks aligned to the world, with hard-edged alpha. Combine with
`color_steps` for a limited palette.
