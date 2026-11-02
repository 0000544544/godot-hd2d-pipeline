shader_type canvas_item;

// Shader Post-Processing HD-2D / Étalonnage Colorimétrique
// Harmonise l'éclairage 3D moderne avec la palette rétro des sprites 2D

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float saturation_boost : hint_range(0.5, 2.0) = 1.15;
uniform vec4 tint_color : source_color = vec4(1.02, 0.98, 0.92, 1.0); // Chaleur cinématique

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	
	// Teinte cinématique
	col.rgb *= tint_color.rgb;

	// Saturation
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(vec3(gray), col.rgb, saturation_boost);

	// Vignettage doux (focus central Octopath Traveler style)
	vec2 uv = SCREEN_UV * (1.0 - SCREEN_UV.yx);
	float vig = uv.x * uv.y * 15.0;
	vig = clamp(pow(vig, vignette_intensity), 0.0, 1.0);
	col.rgb *= vig;

	COLOR = col;
}
