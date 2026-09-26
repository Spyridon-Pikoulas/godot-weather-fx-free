shader_type canvas_item;
// Angled rain in three depths, splashing where it meets the ground line.

#include "weather_common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.74, 0.82, 0.96, 0.7);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float wind : hint_range(-1.0, 1.0) = 0.25;          // slant; + blows to the right
uniform float drop_length : hint_range(4.0, 80.0) = 26.0;   // pixels, nearest layer
uniform float fall_speed : hint_range(0.2, 3.0) = 1.0;
uniform float ground : hint_range(0.0, 1.0) = 1.0;          // splash line, fraction of the height; 1 = none
uniform float splashes : hint_range(0.0, 1.0) = 0.8;

// Streak alpha of one layer; depth 1 is nearest.
float streaks(vec2 p, float depth, float time, int layer) {
	float slant = wind * 0.6;
	float w = 10.0 + 14.0 * depth;
	float len = drop_length * (0.4 + 0.6 * depth);
	float h = len * 2.2 + 30.0;
	vec2 q = p + vec2(float(layer) * 137.0 + seed * 97.0, 0.0);
	q.x -= q.y * slant;                       // skewed: drops fall straight down in q
	float col = floor(q.x / w);
	q.y -= time * (520.0 + 780.0 * depth) * fall_speed;
	q.y += wfx_hash_i(ivec2(int(col), layer * 7 + 3)) * h;
	ivec2 cell = ivec2(int(col), int(floor(q.y / h))) + ivec2(0, layer * 100003);
	vec2 r = wfx_hash2_i(cell);
	if (wfx_hash_i(cell + ivec2(911, 0)) > density * (1.3 - 0.3 * depth)) {
		return 0.0;
	}
	vec2 f = q - vec2(col * w, floor(q.y / h) * h);
	float x0 = (0.2 + 0.6 * r.x) * w;
	float y0 = r.y * (h - len);
	float along = (f.y - y0) / len;
	float body = step(0.0, along) * step(along, 1.0) * pow(clamp(along, 0.0, 1.0), 1.3);
	float half_w = (0.35 + 0.45 * depth) * wfx_px() * (1.0 + abs(slant) * 0.3);
	float aa = pixel_size >= 1.0 ? 0.01 : 0.9;
	float across = 1.0 - smoothstep(half_w, half_w + aa, abs(f.x - x0));
	return body * across * (0.35 + 0.65 * depth);
}

// A crown and two droplets popping up from the ground line.
float splash(vec2 local, vec2 p, float gy, float time) {
	float cw = 26.0;
	float cellx = floor(p.x / cw);
	float rate = 1.6 * fall_speed;
	float a = 0.0;
	for (int k = 0; k < 2; k++) {
		float ph = wfx_hash_i(ivec2(int(cellx), 17 + k));
		float cyc = floor(time * rate + ph);
		ivec2 id = ivec2(int(cellx), int(cyc) * 2 + k);
		if (wfx_hash_i(id + ivec2(0, 5003)) > density * 1.2) {
			continue;
		}
		float age = fract(time * rate + ph);
		float cx = (cellx + 0.2 + 0.6 * wfx_hash_i(id)) * cw - world_origin.x;
		vec2 d = local - vec2(cx, gy);
		float r = 1.5 + age * 7.0;
		float e = length(d / vec2(r, r * 0.45)) - 1.0;
		float ring = (1.0 - smoothstep(0.0, 1.6 / r, abs(e))) * step(d.y, 0.5);
		float drops = 0.0;
		for (int s = -1; s <= 1; s += 2) {
			vec2 dp = vec2(float(s) * (2.0 + age * 10.0), -age * (1.0 - age) * 26.0);
			drops += 1.0 - smoothstep(0.6, 1.5, length(d - dp) / wfx_px());
		}
		a = max(a, (ring * 0.8 + drops) * pow(1.0 - age, 1.5));
	}
	return clamp(a, 0.0, 1.0);
}

void fragment() {
	vec2 uv = wfx_uv(UV);
	vec2 local = uv * rect_size;
	float time = mod(TIME, 300.0) * speed;
	float gy = ground * rect_size.y;
	float a = 0.0;
	for (int i = 0; i < 3; i++) {
		float depth = 0.35 + 0.325 * float(i);
		vec2 p = local + world_origin * depth;
		float s = streaks(p, depth, time, i);
		a = max(a, s * step(local.y, gy + 1.0));
	}
	vec3 rgb = color.rgb;
	if (ground < 1.0) {
		float sp = splash(local, wfx_pos(uv), gy, time) * splashes;
		rgb = mix(rgb, mix(color.rgb, vec3(1.0), 0.35), step(a, sp));
		a = max(a, sp);
	}
	COLOR = wfx_finish(vec4(rgb, color.a * a), uv);
}
