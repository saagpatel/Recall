shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo_color : source_color = vec4(0.4, 0.6, 1.0, 1.0);
uniform float decay_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture;
uniform float emission_energy = 0.3;

void vertex() {
	// Vertex displacement — objects warp as they decay
	float noise_val = texture(noise_texture, UV + TIME * 0.01).r;
	VERTEX += NORMAL * noise_val * decay_amount * 0.05;
}

void fragment() {
	// Desaturation toward gray-blue
	vec3 gray = vec3(dot(albedo_color.rgb, vec3(0.299, 0.587, 0.114)));
	vec3 desaturated = mix(gray, vec3(0.3, 0.35, 0.45), 0.5);
	vec3 color = mix(albedo_color.rgb, desaturated, decay_amount * 0.8);

	// Dissolve: noise threshold mask
	float noise = texture(noise_texture, UV * 3.0).r;

	ALBEDO = color;

	// Emission: pulse at low decay, dim at high decay
	float pulse = 1.0 + sin(TIME * 2.0) * 0.2 * (1.0 - decay_amount);
	EMISSION = albedo_color.rgb * emission_energy * (1.0 - decay_amount * 0.8) * pulse;

	// Dissolve edge glow at high decay
	float dissolve_threshold = 1.0 - decay_amount;
	float edge_glow = smoothstep(dissolve_threshold - 0.05, dissolve_threshold, noise)
					* step(dissolve_threshold, noise) * decay_amount;
	EMISSION += vec3(1.0, 0.8, 0.3) * edge_glow * 2.0;

	// Alpha dissolve at high decay (only kicks in above 0.5 decay)
	float dissolve_alpha = step(decay_amount * 0.5, noise);
	ALPHA = dissolve_alpha;
}
