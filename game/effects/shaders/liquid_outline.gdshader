shader_type canvas_item;

uniform vec2 canvas_size = vec2(1.0, 1.0);
uniform vec2 card_size = vec2(200.0, 280.0);
uniform vec4 outline_color : source_color = vec4(0.24, 1.0, 0.88, 1.0);
uniform float corner_radius = 6.0;
uniform float outline_width = 6.0;
uniform float edge_feather = 0.25;
uniform float liquid_amplitude = 3.0;
uniform float liquid_frequency = 12.0;
uniform float liquid_speed = 2.0;


float rounded_rect_sdf(vec2 point, vec2 half_size, float radius) {
	vec2 safe_half_size = max(half_size - vec2(radius), vec2(0.0));
	vec2 q = abs(point) - safe_half_size;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}


void fragment() {
	vec2 safe_canvas_size = max(canvas_size, vec2(1.0));
	vec2 safe_card_size = max(card_size, vec2(1.0));
	vec2 pixel_position = UV * safe_canvas_size;
	vec2 centered_position = pixel_position - (safe_canvas_size * 0.5);

	float safe_radius = max(corner_radius, 0.0);
	float signed_distance = rounded_rect_sdf(centered_position, safe_card_size * 0.5, safe_radius);
	float angle = atan(centered_position.y, centered_position.x);
	float moving_time = TIME * liquid_speed;

	float edge_wave = sin((angle * liquid_frequency) + moving_time);
	edge_wave += sin((angle * liquid_frequency * 1.73) - (moving_time * 1.31)) * 0.45;
	edge_wave += sin(((centered_position.x * 0.075) - (centered_position.y * 0.045)) + (moving_time * 0.82)) * 0.30;
	edge_wave /= 1.75;

	float liquid_width = max(outline_width + (edge_wave * liquid_amplitude), 0.0);
	float safe_feather = max(edge_feather, fwidth(signed_distance));
	float outer_alpha = 1.0 - smoothstep(liquid_width - safe_feather, liquid_width + safe_feather, signed_distance);
	float outside_alpha = smoothstep(-safe_feather, safe_feather, signed_distance);
	float stroke_alpha = outer_alpha * outside_alpha;

	COLOR = vec4(outline_color.rgb, outline_color.a * stroke_alpha);
}
