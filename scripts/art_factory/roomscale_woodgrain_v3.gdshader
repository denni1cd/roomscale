shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 timber_color : source_color = vec4(0.55, 0.32, 0.16, 1.0);
uniform float tone_scale : hint_range(0.35, 1.0) = 0.68;

varying vec3 local_position;
varying vec3 local_normal;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise2(vec2 p) {
	vec2 cell = floor(p);
	vec2 part = fract(p);
	part = part * part * (3.0 - 2.0 * part);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, part.x), mix(c, d, part.x), part.y);
}

float wood_grain(float along, float across) {
	float broad_warp = noise2(vec2(along * 0.09 + 11.0, across * 0.17 + 3.0)) - 0.5;
	float broad = noise2(vec2(along * 0.10, across * 0.34 + broad_warp * 0.65));
	float fiber = noise2(vec2(along * 0.42 + 7.3, across * 1.9 + broad_warp * 0.30));
	float pores = noise2(vec2(along * 1.1 + 19.0, across * 6.5));
	float fleck = noise2(vec2(along * 4.4, across * 14.0));
	float line = sin(6.2831853 * (across * 0.72 + broad_warp * 0.22));
	return clamp(0.48 + broad * 0.40 + fiber * 0.18 + pores * 0.07 + line * 0.025 + (fleck - 0.5) * 0.035, 0.44, 0.98);
}

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec3 weights = pow(abs(normalize(local_normal)), vec3(6.0));
	weights /= max(weights.x + weights.y + weights.z, 0.0001);
	float horizontal_grain = wood_grain(local_position.x, local_position.z);
	float x_face_grain = wood_grain(local_position.y, local_position.z);
	float z_face_grain = wood_grain(local_position.y, local_position.x);
	float grain = horizontal_grain * weights.y + x_face_grain * weights.x + z_face_grain * weights.z;
	ALBEDO = timber_color.rgb * tone_scale * grain;
	ROUGHNESS = 0.52;
	SPECULAR = 0.34;
	METALLIC = 0.0;
}
