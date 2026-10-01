shader_type spatial;
uniform vec4 timber_color : source_color = vec4(0.475, 0.357, 0.263, 1.0);
varying vec3 surface_world;
void vertex() {
	surface_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float board = floor(surface_world.x / 8.0);
	float grain = sin(surface_world.x * 3.5 + sin(surface_world.z * 0.12) * 0.65 + sin(surface_world.z * 0.035) * 1.2);
	float detail = sin(surface_world.x * 17.0 + sin(surface_world.z * 0.19) * 1.1);
	float board_tint = fract(sin(board * 17.13) * 43758.5453);
	float joint_distance = min(fract(surface_world.x / 8.0), 1.0 - fract(surface_world.x / 8.0)) * 8.0;
	float aa = max(fwidth(surface_world.x), 0.012);
	float joint = 1.0 - smoothstep(0.018, 0.018 + aa, joint_distance);
	float fade = 1.0 - smoothstep(30.0, 100.0, length(CAMERA_POSITION_WORLD - surface_world));
	ALBEDO = timber_color.rgb * (0.965 + grain * 0.003 + detail * 0.001 + board_tint * 0.012 - joint * 0.035 * fade);
	ROUGHNESS = 0.91 + grain * 0.025;
}
