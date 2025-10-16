shader_type spatial;

uniform sampler2D base_texture : source_color;
uniform sampler2D hint_texture : source_color;
uniform float hint_visibility : hint_range(0.0, 1.0) = 0.0;
uniform float static_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform vec3 emission_color : source_color = vec3(0.7, 0.8, 1.0);
uniform float scan_line_speed : hint_range(0.0, 5.0) = 1.0;
uniform float scan_line_intensity : hint_range(0.0, 1.0) = 0.15;

// Random noise function
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Noise function that changes over time
float noise(vec2 uv, float time) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = random(i + vec2(0.0, 0.0) + floor(time));
    float b = random(i + vec2(1.0, 0.0) + floor(time));
    float c = random(i + vec2(0.0, 1.0) + floor(time));
    float d = random(i + vec2(1.0, 1.0) + floor(time));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    // Sample base texture
    vec4 base_color = texture(base_texture, UV);

    // Sample hint texture (if provided)
    vec4 hint_color = texture(hint_texture, UV);

    // Generate static noise
    float static_noise = noise(UV * 80.0, TIME * 10.0);
    static_noise = mix(static_noise, noise(UV * 200.0, TIME * 30.0), 0.5);

    // Add scanlines
    float scanline = sin((UV.y + TIME * scan_line_speed) * 200.0) * 0.5 + 0.5;
    scanline = pow(scanline, 8.0) * scan_line_intensity;

    // Combine base texture with static
    vec3 final_color = base_color.rgb;
    final_color = mix(final_color, vec3(static_noise), static_intensity);

    // Blend in hint texture if visible
    if (hint_visibility > 0.0) {
        // Mix hint with current color based on visibility
        final_color = mix(final_color, hint_color.rgb, hint_visibility * hint_color.a);
        // Reduce static when showing hint
        final_color = mix(final_color, vec3(static_noise), static_intensity * (1.0 - hint_visibility * 0.7));
    }

    final_color += scanline;

    // Apply slight blue tint for CRT effect
    final_color *= vec3(0.95, 0.95, 1.05);

    // Set albedo
    ALBEDO = final_color;

    // Make it emit light
    EMISSION = final_color * emission_color * emission_strength;

    // Slightly rough surface
    ROUGHNESS = 0.3;
    METALLIC = 0.0;
}
