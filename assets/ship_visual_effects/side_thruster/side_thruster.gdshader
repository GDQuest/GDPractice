shader_type canvas_item;

uniform sampler2D base_color;
uniform sampler2D band_gradient: repeat_enable;
uniform float deformation = 0.4;


void fragment() {
	vec4 flame_color = texture(base_color, vec2(UV.y, 0.0));
	COLOR.rgb = (
		flame_color.rgb +
		texture(
			band_gradient,
			vec2(UV.y * 2.0 - TIME * 2.0, 0.0)
		).x * 0.25 * (1.0 - UV.y)
	);

	float deformation_inverted = 1.0 - deformation;
	float sine = (1.0 + sin(UV.y * PI * 4.0 - TIME * 20.0)) / 2.0;
	float signed_distance_field = texture(TEXTURE, UV).a;
	COLOR.a *= smoothstep(0.48, 0.5, signed_distance_field * (sine * deformation + deformation_inverted)) * flame_color.a;
}
