shader_type canvas_item;
render_mode unshaded;

uniform vec4 shine_color : source_color = vec4(1.0);
uniform float shine_position : hint_range(0.0, 1.0) = 0.0;
uniform float shine_width : hint_range(0.01, 0.5) = 0.10;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.015;
uniform float brightness : hint_range(0.0, 4.0) = 1.0;
uniform float rotation_degrees : hint_range(-90.0, 90.0) = -28.0;
uniform vec2 overlay_size = vec2(1.0);
uniform vec4 card_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float card_radius = 9.0;
uniform vec4 title_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float title_radius = 6.0;
uniform vec3 attack_circle = vec3(0.0);
uniform vec3 temporary_attack_circle = vec3(0.0, 0.0, -1.0);
uniform vec3 health_circle = vec3(0.0);
uniform vec3 poison_circle = vec3(0.0, 0.0, -1.0);
uniform vec3 cooldown_circle = vec3(0.0);

vec2 rotate_uv(vec2 uv, vec2 center, float degrees) {
	float angle = radians(degrees);
	mat2 rotation = mat2(
		vec2(cos(angle), -sin(angle)),
		vec2(sin(angle), cos(angle))
	);
	return rotation * (uv - center) + center;
}

float rounded_rect_mask(vec2 point, vec4 rect, float radius) {
	vec2 rect_center = rect.xy + rect.zw * 0.5;
	vec2 half_size = rect.zw * 0.5;
	vec2 corner = abs(point - rect_center) - (half_size - vec2(radius));
	float distance = length(max(corner, vec2(0.0))) + min(max(corner.x, corner.y), 0.0) - radius;
	return 1.0 - smoothstep(0.0, 1.0, distance);
}

float circle_mask(vec2 point, vec3 circle) {
	float distance = length(point - circle.xy) - circle.z;
	return 1.0 - smoothstep(0.0, 1.0, distance);
}

void fragment() {
	vec2 point = UV * overlay_size;
	float shape_mask = rounded_rect_mask(point, card_rect, card_radius);
	shape_mask = max(shape_mask, rounded_rect_mask(point, title_rect, title_radius));
	shape_mask = max(shape_mask, circle_mask(point, attack_circle));
	shape_mask = max(shape_mask, circle_mask(point, temporary_attack_circle));
	shape_mask = max(shape_mask, circle_mask(point, health_circle));
	shape_mask = max(shape_mask, circle_mask(point, poison_circle));
	shape_mask = max(shape_mask, circle_mask(point, cooldown_circle));

	vec2 rotated_uv = rotate_uv(UV, vec2(0.5), rotation_degrees);
	float sweep_center = mix(-0.35, 1.35, shine_position);
	float distance_to_line = abs(rotated_uv.x - sweep_center);
	float sharp_line = 1.0 - smoothstep(shine_width, shine_width + edge_softness, distance_to_line);
	float shine = clamp(sharp_line * shape_mask * brightness, 0.0, 1.0);

	COLOR = vec4(shine_color.rgb, shine_color.a * shine);
}
