shader_type spatial;

uniform float decay_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 dust_color : source_color = vec4(0.3, 0.35, 0.4, 1.0);
uniform sampler2D crack_overlay;
uniform float crack_scale = 2.0;

void fragment() {
	// Base albedo — lerp toward desaturated dust color
	vec3 color = mix(base_color.rgb, dust_color.rgb, decay_amount * 0.8);

	// Crack overlay: blend in when decay > 0.3, using UV
	vec2 crack_uv = UV * crack_scale;
	vec4 crack = texture(crack_overlay, crack_uv);
	float crack_blend = smoothstep(0.3, 0.6, decay_amount) * crack.a;
	color = mix(color, crack.rgb * 0.3, crack_blend);

	ALBEDO = color;

	// Emission dims with decay
	EMISSION = base_color.rgb * 0.15 * (1.0 - decay_amount);
}
