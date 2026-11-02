shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;

// Shader Eau Stylisée HD-2D — Axe 6
// Ondulations sinusoïdales, calcul analytique de normales, caustiques animées,
// dégradé de profondeur et écume de contact / crêtes.

uniform vec4 shallow_color : source_color = vec4(0.2, 0.65, 0.85, 0.82);
uniform vec4 deep_color : source_color = vec4(0.04, 0.22, 0.48, 0.96);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);

uniform float wave_speed : hint_range(0.1, 5.0) = 1.3;
uniform float wave_height : hint_range(0.0, 0.5) = 0.06;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.4;
uniform float foam_threshold : hint_range(0.01, 0.8) = 0.22;
uniform float caustics_speed : hint_range(0.1, 5.0) = 0.8;
uniform float caustics_scale : hint_range(1.0, 30.0) = 14.0;

uniform sampler2D depth_texture : hint_depth_texture;

varying vec3 v_world_pos;
varying float v_wave_disp;

void vertex() {
	// Ondulations croisées avec modulation temporelle
	float w1 = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height;
	float w2 = cos(VERTEX.z * (wave_frequency * 0.85) + TIME * (wave_speed * 0.92)) * (wave_height * 0.75);
	float w3 = sin((VERTEX.x + VERTEX.z) * (wave_frequency * 0.5) + TIME * (wave_speed * 1.15)) * (wave_height * 0.35);
	
	v_wave_disp = w1 + w2 + w3;
	VERTEX.y += v_wave_disp;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Dérivation analytique des normales pour que la lumière reflète les vagues
	float dw_dx = cos(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height * wave_frequency
	            + cos((VERTEX.x + VERTEX.z) * (wave_frequency * 0.5) + TIME * (wave_speed * 1.15)) * (wave_height * 0.35) * (wave_frequency * 0.5);
	float dw_dz = -sin(VERTEX.z * (wave_frequency * 0.85) + TIME * (wave_speed * 0.92)) * (wave_height * 0.75) * (wave_frequency * 0.85)
	            + cos((VERTEX.x + VERTEX.z) * (wave_frequency * 0.5) + TIME * (wave_speed * 1.15)) * (wave_height * 0.35) * (wave_frequency * 0.5);
	
	NORMAL = normalize(vec3(-dw_dx, 1.0, -dw_dz));
}

void fragment() {
	// 1. Échantillonnage de la profondeur de la scène pour la mousse de contact
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	// En espace vue (view space), Z est négatif (caméra orientée vers -Z)
	// La profondeur d'eau est la distance entre la surface de l'eau et le fond de la scène
	float water_depth = VERTEX.z - view.z;

	// 2. Dégradé de teinte selon la profondeur
	float depth_factor = clamp(water_depth * 0.65, 0.0, 1.0);
	vec4 col = mix(shallow_color, deep_color, depth_factor);

	// 3. Mousse de contact sur les bords du bassin
	if (water_depth < foam_threshold && water_depth > 0.0) {
		float foam_factor = 1.0 - (water_depth / foam_threshold);
		foam_factor = pow(foam_factor, 1.4);
		col = mix(col, foam_color, foam_factor * 0.92);
	}

	// 4. Écume sur les crêtes de vagues
	float crest_foam = smoothstep(wave_height * 0.45, wave_height * 1.05, v_wave_disp);
	col = mix(col, foam_color, crest_foam * 0.45);

	// 5. Caustiques de surface animées (double réseau UV croisé basé sur coordonnées monde)
	vec2 uv_scaled = v_world_pos.xz * (caustics_scale * 0.15);
	vec2 c_uv1 = uv_scaled + vec2(TIME * (caustics_speed * 0.35), TIME * (caustics_speed * 0.28));
	vec2 c_uv2 = uv_scaled * 1.25 - vec2(TIME * (caustics_speed * 0.24), TIME * (caustics_speed * 0.38));
	
	float pat1 = sin(c_uv1.x + sin(c_uv1.y * 1.4)) * cos(c_uv1.y + cos(c_uv1.x * 1.4));
	float pat2 = sin(c_uv2.x + cos(c_uv2.y * 1.2)) * cos(c_uv2.y + sin(c_uv2.x * 1.2));
	float caustics = clamp((pat1 + pat2) * 0.5 + 0.35, 0.0, 1.0);
	caustics = pow(caustics, 3.2);
	
	col.rgb += caustics * 0.32 * foam_color.rgb;

	ALBEDO = col.rgb;
	ALPHA = col.a;
	ROUGHNESS = 0.06;
	METALLIC = 0.05;
	SPECULAR = 0.85;
}
