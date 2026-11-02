shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;

// Shader Eau Stylisée HD-2D
// Ondulations sinusoïdales, dégradé de profondeur et mousse de contact

uniform vec4 shallow_color : source_color = vec4(0.2, 0.65, 0.85, 0.8);
uniform vec4 deep_color : source_color = vec4(0.05, 0.25, 0.5, 0.95);
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);

uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_height : hint_range(0.0, 0.5) = 0.08;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.5;

uniform float foam_threshold : hint_range(0.01, 0.8) = 0.15;
uniform sampler2D depth_texture : hint_depth_texture;

void vertex() {
	float wave1 = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height;
	float wave2 = cos(VERTEX.z * (wave_frequency * 0.8) + TIME * (wave_speed * 0.9)) * (wave_height * 0.7);
	VERTEX.y += wave1 + wave2;
}

void fragment() {
	// Échantillonnage de la profondeur de la scène pour créer la mousse de contact
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float water_depth = linear_depth - VERTEX.z;

	// Dégradé haut / bas selon la profondeur
	vec4 col = mix(shallow_color, deep_color, clamp(water_depth * 0.4, 0.0, 1.0));

	// Bordure de mousse (écume)
	if (water_depth < foam_threshold && water_depth > 0.0) {
		float foam_factor = 1.0 - (water_depth / foam_threshold);
		col = mix(col, foam_color, foam_factor * 0.85);
	}

	ALBEDO = col.rgb;
	ALPHA = col.a;
	ROUGHNESS = 0.15;
	METALLIC = 0.05;
	SPECULAR = 0.5;
}
