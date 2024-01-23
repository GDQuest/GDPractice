// 2D-perspective by Hei
// source: https://godotshaders.com/shader/2d-perspective/

shader_type canvas_item;
uniform sampler2D parts_sampler;
// Camera FOV
uniform float field_of_view : hint_range(1, 179) = 90;
uniform float rotation_y : hint_range(-180, 180) = 0.0;
uniform float rotation_x : hint_range(-180, 180) = 0.0;
// At 0, the image retains its size when unrotated.
// At 1, the image is resized so that it can do a full
// rotation without clipping inside its rect.
uniform float inset : hint_range(0, 1) = 0.0;
// Consider changing this to a uniform and changing it from code

uniform float line_thickness : hint_range(0, 10) = 1.0;

const vec2 OFFSETS[12] = { vec2(-1, 0), vec2(0, -1), vec2(0, 1), vec2(1, 0), vec2(-0.85, 0.5), vec2(-0.5, 0.85), vec2(0.85, 0.5), vec2(0.5, 0.85), vec2(-0.85, -0.5), vec2(-0.5, -0.85), vec2(0.85, -0.5), vec2(0.5, -0.85)
};

// When called for each fragment, draws an outline around a sprite
float outline(vec2 size, vec2 uv, sampler2D color){
	float outline = 0.0;
	for(int i = 0; i < OFFSETS.length(); i++){
		outline += texture(color, uv + size * OFFSETS[i]).a;
	}
	return min(outline, 1.0);
}


varying flat vec2 o;
varying vec3 p;

// Creates rotation matrix
void vertex() {
	float sin_b = sin(rotation_y / 180.0 * PI);
	float cos_b = cos(rotation_y / 180.0 * PI);
	float sin_c = sin(rotation_x / 180.0 * PI);
	float cos_c = cos(rotation_x / 180.0 * PI);
	
	mat3 inv_rot_mat;
	inv_rot_mat[0][0] = cos_b;
	inv_rot_mat[0][1] = 0.0;
	inv_rot_mat[0][2] = -sin_b;
	
	inv_rot_mat[1][0] = sin_b * sin_c;
	inv_rot_mat[1][1] = cos_c;
	inv_rot_mat[1][2] = cos_b * sin_c;
	
	inv_rot_mat[2][0] = sin_b * cos_c;
	inv_rot_mat[2][1] = -sin_c;
	inv_rot_mat[2][2] = cos_b * cos_c;
	
	float t = tan(field_of_view / 360.0 * PI);
	p = inv_rot_mat * vec3((UV - 0.5), 0.5 / t);
	float v = (0.5 / t) + 0.5;
	p.xy *= v * inv_rot_mat[2].z;
	o = v * inv_rot_mat[2].xy;

	VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - inset);
}

void fragment() {
	vec2 uv = (p.xy / p.z).xy - o;
	uv.x /= 3.0;
	
	COLOR = vec4(0.0);
	float outline_alpha = 0.0;
	
	for(int i = 0; i < 3; i++){
		vec2 uv_offset = uv + vec2((0.5 + float(i)) / 3.0, 0.5) + vec2(-o.x * 0.04 * float(i), 0.0);
		vec4 color = texture(parts_sampler, uv_offset);
		
		COLOR.rgb = mix(COLOR, color, color.a).rgb;
		COLOR.a += color.a;
		
		outline_alpha += outline(
			vec2(0.01, 0.03) * line_thickness,
			uv_offset,
			parts_sampler
		);
		
		outline_alpha *= step(-0.154, uv.x) * step(uv.x, 0.154);
	}
	
	COLOR.a = outline_alpha;
}