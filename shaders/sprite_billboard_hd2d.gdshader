shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Shader HD-2D pour Sprite3D / Billboard
// Combine alignement caméra (Y-Billboard), ombres 3D dynamiques et contour pixel-art

uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float outline_thickness : hint_range(0.0, 5.0) = 1.0;
uniform bool enable_outline = true;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	// Mode Y-Billboard : pivote vers la caméra sur l'axe horizontal Y tout en restant droit
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 size = vec2(textureSize(texture_albedo, 0));
	vec2 pixel_size = 1.0 / size;
	vec4 col = texture(texture_albedo, UV);

	if (enable_outline && col.a < alpha_scissor_threshold) {
		float a_up = texture(texture_albedo, UV + vec2(0.0, -pixel_size.y * outline_thickness)).a;
		float a_down = texture(texture_albedo, UV + vec2(0.0, pixel_size.y * outline_thickness)).a;
		float a_left = texture(texture_albedo, UV + vec2(-pixel_size.x * outline_thickness, 0.0)).a;
		float a_right = texture(texture_albedo, UV + vec2(pixel_size.x * outline_thickness, 0.0)).a;

		if (max(max(a_up, a_down), max(a_left, a_right)) >= alpha_scissor_threshold) {
			col = outline_color;
		}
	}

	ALBEDO = col.rgb;
	ALPHA = col.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
}
