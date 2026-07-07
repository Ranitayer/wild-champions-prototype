shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D dissolve_texture : source_color, repeat_enable;
uniform float dissolve_value : hint_range(0.0, 1.0) = 0.0;
uniform float burn_size : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform vec4 burn_color : source_color = vec4(0.870588, 0.619608, 0.254902, 1.0);
uniform float edge_softness : hint_range(0.0, 0.2, 0.001) = 0.025;
uniform float noise_strength : hint_range(0.0, 1.0, 0.01) = 0.28;
uniform float noise_scale : hint_range(0.1, 8.0, 0.1) = 1.8;
uniform float dissolve_direction = 1.0;

void fragment() {
	vec4 main_texture = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (main_texture.a > 0.0001) {
		main_texture.rgb /= main_texture.a;
	}
	float start_axis = mix(UV.y, 1.0 - UV.y, step(0.0, dissolve_direction));
	float noise_value = texture(dissolve_texture, UV * noise_scale).r;
	float dissolve_map = clamp(start_axis + ((noise_value - 0.5) * noise_strength), 0.0, 1.0);
	float safe_softness = max(edge_softness, 0.0001);
	float safe_burn_size = max(burn_size, 0.0001);
	float dissolve_threshold = mix(
		0.0,
		1.0 + safe_burn_size + safe_softness,
		dissolve_value
	);

	float active_burn = step(0.001, dissolve_value);
	float keep_alpha = mix(
		1.0,
		smoothstep(dissolve_threshold - safe_softness, dissolve_threshold + safe_softness, dissolve_map),
		active_burn
	);
	float burn_front = 1.0 - smoothstep(dissolve_threshold, dissolve_threshold + safe_burn_size, dissolve_map);
	float burn_alpha = clamp(burn_front * keep_alpha * active_burn, 0.0, 1.0);

	vec4 result = main_texture;
	result.rgb = mix(main_texture.rgb, burn_color.rgb, burn_alpha);
	result.a = main_texture.a * keep_alpha;
	COLOR *= result;
}
