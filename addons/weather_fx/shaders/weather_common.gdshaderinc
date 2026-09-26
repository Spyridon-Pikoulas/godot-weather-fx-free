// Shared by every Weather FX shader. Positions are in world pixels (wfx_pos), so patterns stay put
// under a moving camera and pixel_size blocks line up with pixel art.

uniform float intensity : hint_range(0.0, 2.0) = 1.0;  // strength; stop() and fade_in() drive it
uniform float speed : hint_range(0.0, 4.0) = 1.0;
uniform float seed = 0.0;
uniform float pixel_size : hint_range(0.0, 16.0, 1.0) = 0.0;
uniform float color_steps : hint_range(0.0, 16.0, 1.0) = 0.0;
uniform vec2 rect_size = vec2(1280.0, 720.0);          // set by WeatherFX
uniform vec2 world_origin = vec2(0.0);                 // set by WeatherFX: the rect's top-left

const float WFX_TAU = 6.2831853;

// Integer hash: a float hash of large coordinates rounds differently at each call site on some
// GPUs, which tears the noise into steps.
float wfx_hash_i(ivec2 i) {
	uvec2 q = uvec2(i) * uvec2(1597334673u, 3812015801u);
	uint n = (q.x ^ q.y) * 1597334673u;
	return float(n) * (1.0 / 4294967295.0);
}

// Two independent 0..1 values for a lattice cell.
vec2 wfx_hash2_i(ivec2 i) {
	return vec2(wfx_hash_i(i), wfx_hash_i(i + ivec2(7919, 104729)));
}

float wfx_noise(vec2 p) {
	vec2 fl = floor(p);
	ivec2 i = ivec2(fl);
	vec2 f = p - fl;
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(wfx_hash_i(i), wfx_hash_i(i + ivec2(1, 0)), u.x),
			mix(wfx_hash_i(i + ivec2(0, 1)), wfx_hash_i(i + ivec2(1, 1)), u.x), u.y);
}

// 0..1, spread to cover the range.
float wfx_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * wfx_noise(p);
		p = p * 2.03 + 17.0;
		a *= 0.5;
	}
	return clamp((v - 0.15) / 0.7, 0.0, 1.0);
}

// UV snapped to the centre of its pixel_size block, the blocks aligned to the world.
vec2 wfx_uv(vec2 uv) {
	if (pixel_size < 1.0) {
		return uv;
	}
	vec2 p = world_origin + uv * rect_size;
	p = (floor(p / pixel_size) + 0.5) * pixel_size;
	return (p - world_origin) / rect_size;
}

// World position of a (snapped) UV, in pixels.
vec2 wfx_pos(vec2 uv) {
	return world_origin + uv * rect_size;
}

// One pixel, or one pixel_size block: keeps thin lines visible.
float wfx_px() {
	return max(pixel_size, 1.0);
}

// Colour steps, and in pixel mode alpha in eight flat bands: crisp pixel-art edges, and a thin
// veil (fog, a flash) stays a veil instead of a dither pattern.
vec4 wfx_finish(vec4 c, vec2 uv) {
	c.a = clamp(c.a * intensity, 0.0, 1.0);
	if (color_steps >= 1.0) {
		c.rgb = floor(c.rgb * color_steps + 0.5) / color_steps;
	}
	if (pixel_size >= 1.0) {
		c.a = floor(c.a * 8.0 + 0.5) / 8.0;
	}
	return c;
}
