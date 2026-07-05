shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform float outline_width : hint_range(1.0, 8.0, 1.0) = 4.0;

void fragment() {
	vec4 source = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (source.a > 0.0001) {
		source.rgb /= source.a;
	}

	vec2 radius = SCREEN_PIXEL_SIZE * outline_width;
	vec2 diagonal = radius * 0.70710678;
	float nearby_alpha = 1.0;
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV + vec2(radius.x, 0.0), 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV - vec2(radius.x, 0.0), 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV + vec2(0.0, radius.y), 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV - vec2(0.0, radius.y), 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV + diagonal, 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV - diagonal, 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV + vec2(diagonal.x, -diagonal.y), 0.0).a);
	nearby_alpha = min(nearby_alpha, textureLod(screen_texture, SCREEN_UV + vec2(-diagonal.x, diagonal.y), 0.0).a);

	float outer_outline = clamp((source.a - nearby_alpha) * 4.0, 0.0, 1.0);
	float replace_amount = flash_strength * (1.0 - outer_outline);
	source.rgb = mix(source.rgb, flash_color.rgb, replace_amount);
	COLOR *= source;
}
