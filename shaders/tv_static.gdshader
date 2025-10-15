shader_type spatial;

// Static TV effect with emission and camera texture
uniform sampler2D base_texture : filter_linear_mipmap, repeat_disable;
uniform float static_speed : hint_range(0.0, 10.0) = 5.0;
uniform float static_density : hint_range(0.0, 1.0) = 0.8;
uniform vec3 emission_color : source_color = vec3(0.7, 0.8, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform float scan_line_speed : hint_range(0.0, 5.0) = 1.0;
uniform float scan_line_intensity : hint_range(0.0, 1.0) = 0.1;

// Random function for noise
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Sample the base camera texture
    vec4 base_color = texture(base_texture, uv);

    // Animated static noise
    float noise = random(uv + TIME * static_speed);

    // Add vertical scan lines (higher frequency = thinner lines)
    float scan_line = sin(uv.y * 1000.0 - TIME * scan_line_speed * 10.0) * scan_line_intensity;

    // Combine noise with scan lines
    float static_value = noise * static_density + (1.0 - static_density) * 0.5;
    static_value += scan_line;

    // Add slight color variation for more realistic static
    vec3 static_color = vec3(static_value);
    static_color.r *= 1.0 + random(uv + TIME * 0.1) * 0.1;
    static_color.b *= 1.0 + random(uv - TIME * 0.1) * 0.1;

    // Mix base texture with static overlay
    vec3 final_color = mix(base_color.rgb, static_color, static_density * .001);

    // Set albedo
    ALBEDO = final_color;

    // Add emission for glow effect (mix base image emission with static)
    vec3 emission = mix(base_color.rgb * 0.5, static_color * emission_color * emission_strength, 0.5);
    EMISSION = emission;

    // Make it unaffected by lighting
    ROUGHNESS = 1.0;
    METALLIC = 0.0;
}
