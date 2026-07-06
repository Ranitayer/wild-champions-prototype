shader_type canvas_item;
render_mode unshaded;

uniform vec4 ray_color : source_color = vec4(1.0, 0.65, 0.0, 0.55);
uniform int ray_count = 6;
uniform float rotation = 0.0;
uniform float ray_width : hint_range(0.05, 0.95) = 0.38;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.02;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.08;
uniform float outer_radius : hint_range(0.0, 1.5) = 1.0;
uniform float fade_power : hint_range(0.1, 4.0) = 1.5;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered) * 2.0;
	float angle = atan(centered.y, centered.x) + rotation;
	float sector = 6.28318530718 / float(ray_count);
	float local_angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5) / (sector * 0.5);
	float side_mask = 1.0 - smoothstep(ray_width, ray_width + edge_softness, local_angle);
	float base_mask = smoothstep(inner_radius, inner_radius + 0.08, radius);
	float tip_fade = pow(clamp(1.0 - smoothstep(inner_radius, outer_radius, radius), 0.0, 1.0), fade_power);
	float alpha = side_mask * base_mask * tip_fade;
	COLOR = vec4(ray_color.rgb, ray_color.a * alpha);
}
