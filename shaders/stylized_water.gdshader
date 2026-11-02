shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : hint_default_white, repeat_enable;

uniform vec4 shallow_color : source_color = vec4(0.25, 0.65, 0.85, 0.5);
uniform vec4 deep_color : source_color = vec4(0.08, 0.25, 0.45, 0.85);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.15;
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 0.8);

uniform vec2 wave_speed = vec2(0.02, 0.04);
uniform float wave_scale = 3.0;

void fragment() {
	// Animation des ondulations
	vec2 wave_uv = UV * wave_scale + TIME * wave_speed;
	float noise = texture(noise_texture, wave_uv).r;
	
	// Calcul de la profondeur réelle sous le plan d'eau
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.z /= view.w;
	float linear_depth = -view.z;
	float surface_depth = -VERTEX.z;
	float water_depth = max(0.0, linear_depth - surface_depth);
	
	// Gradient de couleur selon la profondeur
	float depth_factor = clamp(water_depth * 2.0, 0.0, 1.0);
	vec4 water_col = mix(shallow_color, deep_color, depth_factor);
	
	// Ligne d'écume le long des bords du sol/murs
	float foam_line = clamp((foam_amount - water_depth) / foam_amount, 0.0, 1.0);
	foam_line *= step(0.2, noise);
	
	// Distortion légère du fond (réfraction)
	vec2 refr_uv = SCREEN_UV + (noise - 0.5) * 0.01;
	vec3 background_col = texture(screen_texture, refr_uv).rgb;
	
	vec3 final_rgb = mix(background_col, water_col.rgb, water_col.a);
	final_rgb = mix(final_rgb, foam_color.rgb, foam_line * foam_color.a);
	
	ALBEDO = final_rgb;
	ALPHA = clamp(water_col.a + foam_line, 0.0, 1.0);
	METALLIC = 0.05;
	ROUGHNESS = 0.1;
}
