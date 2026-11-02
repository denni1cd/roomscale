shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 timber_color : source_color = vec4(0.55, 0.38, 0.25, 1.0);
uniform float tone_scale : hint_range(0.35, 1.0) = 0.86;

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
	float warp = noise2(vec2(along * 0.065 + 13.0, across * 0.19 + 4.0)) - 0.5;
	float broad = noise2(vec2(along * 0.11, across * 0.42 + warp * 0.9));
	float fiber = noise2(vec2(along * 0.46 + 5.0, across * 2.2 + warp * 0.35));
	float pores = noise2(vec2(along * 1.3 + 17.0, across * 7.0));
	float fleck = noise2(vec2(along * 3.2 + 29.0, across * 12.0));
	float pores_line = sin(6.2831853 * (across * 0.88 + warp * 0.26));
	return clamp(0.56 + (broad - 0.5) * 0.40 + (fiber - 0.5) * 0.26 + (pores - 0.5) * 0.12 + (fleck - 0.5) * 0.10 + pores_line * 0.025, 0.36, 1.0);
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
	ROUGHNESS = 0.38;
	SPECULAR = 0.48;
	METALLIC = 0.0;
}
