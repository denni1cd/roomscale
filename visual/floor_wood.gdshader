shader_type spatial;
uniform vec4 timber_color : source_color = vec4(0.475, 0.357, 0.263, 1.0);
varying vec3 surface_world;
void vertex() {
	surface_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float board = floor(surface_world.x / 8.0);
	float grain = sin(surface_world.z * 3.5 + sin(surface_world.x * 0.12) * 0.65 + sin(surface_world.x * 0.035) * 1.2);
	float detail = sin(surface_world.z * 17.0 + sin(surface_world.x * 0.19) * 1.1);
	float board_tint = fract(sin(board * 17.13) * 43758.5453);
	float joint_distance = min(fract(surface_world.x / 8.0), 1.0 - fract(surface_world.x / 8.0)) * 8.0;
	float aa = max(fwidth(surface_world.x), 0.012);
	float joint = 1.0 - smoothstep(0.018, 0.018 + aa, joint_distance);
	float stagger = mod(abs(board), 2.0) * 16.0;
	float end_distance = min(fract((surface_world.z + stagger) / 32.0), 1.0 - fract((surface_world.z + stagger) / 32.0)) * 32.0;
	float end_aa = max(fwidth(surface_world.z), 0.035);
	float end_joint = 1.0 - smoothstep(0.055, 0.055 + end_aa, end_distance);
	float local_x = fract(surface_world.x / 8.0);
	float local_z = fract((surface_world.z + stagger) / 32.0);
	float knot_x = fract(sin(board * 41.7) * 8231.4);
	float knot_z = fract(sin(board * 13.9) * 2381.7);
	float knot = exp(-((local_x - knot_x) * (local_x - knot_x) * 16.0 + (local_z - knot_z) * (local_z - knot_z) * 2.2));
	float fade = 1.0 - smoothstep(30.0, 100.0, length(CAMERA_POSITION_WORLD - surface_world));
	float wear = sin(surface_world.x * 0.31 + sin(surface_world.z * 0.17)) * sin(surface_world.z * 0.23);
	float board_variation = (board_tint - 0.5) * 0.075;
	ALBEDO = timber_color.rgb * (0.95 + grain * 0.012 + detail * 0.002 + board_variation + wear * 0.018 - knot * 0.025 - max(joint, end_joint) * 0.042 * fade);
	ROUGHNESS = 0.88 + grain * 0.035 + wear * 0.025 + knot * 0.04;
}
