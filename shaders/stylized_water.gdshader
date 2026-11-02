shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;

// Shader Eau Stylisée HD-2D — Rendu Sobre & Bassine Intégrée (Axe 6 Fix)
// - Opacité ajustée, translucide et crystalline
// - Caustiques douces et légères
// - Réfraction simplifiée
// - Masque de découpe radial adouci évitant tout débordement géométrique

uniform vec4 shallow_color : source_color = vec4(0.28, 0.68, 0.82, 0.65);
uniform vec4 deep_color : source_color = vec4(0.12, 0.38, 0.62, 0.82);
uniform vec4 foam_color : source_color = vec4(0.92, 0.96, 1.0, 0.75);

uniform float wave_speed : hint_range(0.1, 3.0) = 0.85;
uniform float wave_height : hint_range(0.0, 0.1) = 0.022;
uniform float wave_frequency : hint_range(0.1, 5.0) = 1.8;
uniform float foam_threshold : hint_range(0.01, 0.5) = 0.12;

uniform float caustics_speed : hint_range(0.1, 3.0) = 0.5;
uniform float caustics_scale : hint_range(1.0, 30.0) = 10.0;
uniform float caustics_intensity : hint_range(0.0, 1.0) = 0.14;

// Masque de découpe circulaire pour s'emboîter sans débordement dans la margelle
uniform float cutout_radius : hint_range(0.1, 0.5) = 0.485;
uniform float cutout_feather : hint_range(0.001, 0.1) = 0.025;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

varying vec3 v_world_pos;
varying float v_wave_disp;

void vertex() {
	// Ondulations calmes et douces
	float w1 = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height;
	float w2 = cos(VERTEX.z * (wave_frequency * 0.9) + TIME * (wave_speed * 0.8)) * (wave_height * 0.6);
	
	v_wave_disp = w1 + w2;
	VERTEX.y += v_wave_disp;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Dérivation des normales pour une brillance subtile
	float dw_dx = cos(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height * wave_frequency;
	float dw_dz = -sin(VERTEX.z * (wave_frequency * 0.9) + TIME * (wave_speed * 0.8)) * (wave_height * 0.6) * (wave_frequency * 0.9);
	NORMAL = normalize(vec3(-dw_dx, 1.0, -dw_dz));
}

void fragment() {
	// 1. Masque de découpe circulaire avec contour adouci
	vec2 center_uv = UV - vec2(0.5);
	float dist_from_center = length(center_uv);
	float edge_mask = 1.0 - smoothstep(cutout_radius - cutout_feather, cutout_radius, dist_from_center);
	
	if (edge_mask <= 0.001) {
		discard;
	}

	// 2. Échantillonnage de la profondeur de scène
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float water_depth = max(VERTEX.z - view.z, 0.0);

	// 3. Dégradé de teinte sobre selon la profondeur
	float depth_factor = clamp(water_depth * 0.85, 0.0, 1.0);
	vec4 col = mix(shallow_color, deep_color, depth_factor);

	// 4. Réfraction simplifiée du décor d'arrière-plan
	vec2 refr_offset = NORMAL.xz * 0.012;
	vec3 bg_refracted = texture(screen_texture, SCREEN_UV + refr_offset).rgb;
	col.rgb = mix(bg_refracted, col.rgb, col.a);

	// 5. Mousse de contact subtile contre les parois intérieures
	if (water_depth < foam_threshold && water_depth > 0.0) {
		float foam_factor = pow(1.0 - (water_depth / foam_threshold), 2.0);
		col.rgb = mix(col.rgb, foam_color.rgb, foam_factor * foam_color.a);
	}

	// 6. Caustiques douces et légères
	vec2 uv_scaled = v_world_pos.xz * (caustics_scale * 0.12);
	vec2 c_uv1 = uv_scaled + vec2(TIME * (caustics_speed * 0.25), TIME * (caustics_speed * 0.18));
	vec2 c_uv2 = uv_scaled * 1.15 - vec2(TIME * (caustics_speed * 0.15), TIME * (caustics_speed * 0.22));
	
	float pat1 = sin(c_uv1.x + sin(c_uv1.y * 1.2)) * cos(c_uv1.y + cos(c_uv1.x * 1.2));
	float pat2 = sin(c_uv2.x + cos(c_uv2.y * 1.1)) * cos(c_uv2.y + sin(c_uv2.x * 1.1));
	float caustics = clamp((pat1 + pat2) * 0.45 + 0.3, 0.0, 1.0);
	caustics = pow(caustics, 2.5);
	
	col.rgb += caustics * caustics_intensity * vec3(1.0, 1.0, 1.0);

	ALBEDO = col.rgb;
	ALPHA = clamp(col.a * edge_mask, 0.0, 1.0);
	ROUGHNESS = 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.55;
}
