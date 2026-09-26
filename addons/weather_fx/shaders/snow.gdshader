shader_type canvas_item;
// Snowflakes in four parallax depths, swaying as they drift down.

#include "weather_common.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.95);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float wind : hint_range(-1.0, 1.0) = 0.2;
uniform float flake_size : hint_range(1.0, 10.0) = 3.5;   // pixels, nearest layer
uniform float fall_speed : hint_range(0.2, 3.0) = 1.0;
uniform float drift : hint_range(0.0, 1.0) = 0.5;         // side to side sway

// Flake alpha of one layer; depth 1 is nearest.
float flakes(vec2 p, float depth, float time, int layer) {
	float cell = 24.0 + 40.0 * depth;
	float fall = (22.0 + 50.0 * depth) * fall_speed;
	vec2 q = p - vec2(wind * fall * 1.5, fall) * time + vec2(float(layer) * 71.3 + seed * 53.0, float(layer) * 37.1);
	vec2 id = floor(q / cell);
	vec2 f = q - id * cell;
	ivec2 ii = ivec2(id) + ivec2(layer * 10007, 0);
	vec2 h = wfx_hash2_i(ii);
	float h3 = wfx_hash_i(ii + ivec2(31, 17));
	if (h3 > density * (1.2 - 0.25 * depth)) {
		return 0.0;
	}
	float r = max(flake_size * (0.35 + 0.65 * depth) * (0.7 + 0.5 * h.x) * 0.5, 0.5 * wfx_px());
	float room = cell * 0.5 - r - 1.0;
	float sway = drift * room * 0.5;
	float swing = sin(time * (0.8 + 0.8 * h.y) * fall_speed + h.y * WFX_TAU);
	vec2 c = vec2(cell * 0.5 + (h.x - 0.5) * 2.0 * (room - sway) + swing * sway,
			cell * (0.5 + (h.y - 0.5) * 0.7));
	float soft = pixel_size >= 1.0 ? 0.01 : 0.6 + 0.4 * depth;
	float a = 1.0 - smoothstep(r - soft * 0.5, r + soft * 0.5, length(f - c));
	return a * (0.4 + 0.6 * depth);
}

void fragment() {
	vec2 uv = wfx_uv(UV);
	vec2 local = uv * rect_size;
	float time = mod(TIME, 600.0) * speed;
	float a = 0.0;
	for (int i = 0; i < 4; i++) {
		float depth = 0.25 + 0.25 * float(i);
		a = max(a, flakes(local + world_origin * depth, depth, time, i));
	}
	COLOR = wfx_finish(vec4(color.rgb, color.a * a), uv);
}
