shader_type canvas_item;
// Rolling fog: three layers of billowing noise drifting with the wind, thicker near the ground.

#include "weather_common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.87, 0.9, 0.97, 0.85);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float wind : hint_range(-1.0, 1.0) = 0.3;
uniform float fog_scale : hint_range(0.25, 4.0) = 1.0;   // size of the billows
uniform float ground_fog : hint_range(0.0, 1.0) = 0.6;   // 0 even, 1 pooled at the bottom

void fragment() {
	vec2 uv = wfx_uv(UV);
	vec2 local = uv * rect_size;
	float time = TIME * speed;
	float lo = mix(0.85, -0.25, density);
	float clear = 1.0;
	float lit = 0.0;
	for (int i = 0; i < 3; i++) {
		float depth = 0.5 + 0.25 * float(i);
		vec2 p = (local + world_origin * depth) / (220.0 * fog_scale * (0.6 + 0.4 * depth)) * vec2(0.45, 1.0);
		p += vec2(-time * wind * 0.06 * (0.4 + depth), time * 0.01) + float(i) * vec2(5.3, 9.1) + seed;
		vec2 warp = vec2(wfx_fbm(p * 0.6 + vec2(time * 0.015, 3.0)), wfx_fbm(p * 0.6 + vec2(7.0, time * 0.02)));
		float n = wfx_fbm(p + (warp - 0.5) * vec2(0.8, 0.5));
		float f = smoothstep(lo, lo + 0.35, n);
		clear *= 1.0 - f * 0.6;
		lit = max(lit, n * f);
	}
	float a = 1.0 - clear;
	float m = mix(1.0, smoothstep(-0.1, 1.0, uv.y), ground_fog);
	vec3 rgb = color.rgb * (0.88 + 0.18 * lit);
	COLOR = wfx_finish(vec4(rgb, color.a * a * m), uv);
}
