shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Shader Eau Stylisée HD-2D — Bassin Arrondi & Rendu Fluide
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : hint_default_white, repeat_enable;

uniform vec4 shallow_color : source_color = vec4(0.18, 0.58, 0.82, 0.75);
uniform vec4 deep_color : source_color = vec4(0.05, 0.24, 0.50, 0.92);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.08;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 0.9);

uniform vec2 wave_speed = vec2(0.02, 0.035);
uniform float wave_scale = 3.0;

// Découpe circulaire adoucie
uniform float cutout_radius : hint_range(0.1, 0.5) = 0.485;
uniform float cutout_feather : hint_range(0.001, 0.1) = 0.02;

void fragment() {
	// 1. Masque de découpe circulaire (bassin arrondi)
	vec2 center_uv = UV - vec2(0.5);
	float dist = length(center_uv);
	float circle_mask = 1.0 - smoothstep(cutout_radius - cutout_feather, cutout_radius, dist);
	
	if (circle_mask <= 0.001) {
		discard;
	}

	// 2. Animation des ondulations
	vec2 wave_uv = UV * wave_scale + TIME * wave_speed;
	float noise = texture(noise_texture, wave_uv).r;
	
	// 3. Calcul de la profondeur réelle sous le plan d'eau
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.z /= view.w;
	float linear_depth = -view.z;
	float surface_depth = -VERTEX.z;
	float water_depth = max(0.0, linear_depth - surface_depth);
	
	// 4. Gradient de couleur : azur translucide vers bleu profond au centre
	float depth_factor = clamp(water_depth * 2.5 + (1.0 - dist * 2.0) * 0.45, 0.0, 1.0);
	vec4 water_col = mix(shallow_color, deep_color, depth_factor);
	
	// 5. Ligne d'écume fine et délicate sur le pourtour arrondi
	float depth_foam = clamp((foam_amount - water_depth) / foam_amount, 0.0, 1.0);
	float perimeter_foam = smoothstep(cutout_radius - 0.03, cutout_radius - 0.005, dist);
	float foam_line = max(depth_foam * 0.5, perimeter_foam);
	foam_line *= step(0.12, noise);
	
	// 6. Réfraction subtile du fond
	vec2 refr_uv = SCREEN_UV + (noise - 0.5) * 0.008;
	vec3 background_col = texture(screen_texture, refr_uv).rgb;
	
	vec3 final_rgb = mix(background_col, water_col.rgb, water_col.a);
	final_rgb = mix(final_rgb, foam_color.rgb, foam_line * foam_color.a);
	
	ALBEDO = final_rgb;
	ALPHA = clamp((water_col.a + foam_line * 0.3) * circle_mask, 0.0, 1.0);
	METALLIC = 0.05;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
}
