/*
  T09 Shader — glow/bloom via a simple horizontal+vertical blur.

  How sokol-shdc works:
    - One file holds ALL shader stages: @vs, @fs, @program.
    - You annotate uniform blocks and image slots with @block / @image.
    - sokol-shdc compiles this to GLSL / MSL / HLSL and wraps it in an
      Odin file with typed helpers (shader_desc, apply_uniforms, etc.).

  HOW THIS SHADER WORKS:
    Pass 1: draw scene geometry to an offscreen render target (texture).
    Pass 2: fullscreen quad, sample the scene texture + several nearby
            samples blended together → bloom glow effect.

    For simplicity we do both in one pass here: the fragment shader
    samples the scene texture at the pixel's UV and at offsets, blending
    the bright parts to fake bloom.  A real bloom needs two passes
    (horizontal blur then vertical blur) but this single-pass version is
    good enough to understand the concept.

  UNIFORM BLOCK:
    - time       : used for a subtle pulse on the glow intensity.
    - resolution : screen size in pixels (for pixel-size offsets).
*/

@header package t09
@header import sg "../../sauce/sokol/gfx"

@ctype mat4 Mat4
@ctype vec2 [2]f32
@ctype vec4 [4]f32

// ---- vertex shader ----
@vs vs
in vec2 position;
in vec2 uv0;
out vec2 uv;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = uv0;
}
@end

// ---- fragment shader ----
@fs fs
layout(binding=0) uniform texture2D scene_tex;
layout(binding=0) uniform sampler scene_smp;

layout(binding=0) uniform fs_params {
    vec2 resolution;
    float time;
    float _pad;
};

in vec2 uv;
out vec4 frag_color;

void main() {
    vec2 pixel = 1.0 / resolution;

    // sample center + 8 neighbours at increasing radius
    vec4 col = texture(sampler2D(scene_tex, scene_smp), uv);

    // accumulate nearby samples (fake bloom)
    vec4 glow = vec4(0.0);
    float total = 0.0;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            if (i == 0 && j == 0) continue;
            vec2 offset = vec2(float(i), float(j)) * pixel * 3.0;
            vec4 s = texture(sampler2D(scene_tex, scene_smp), uv + offset);
            // only bright pixels contribute to glow
            float brightness = dot(s.rgb, vec3(0.2126, 0.7152, 0.0722));
            float w = max(0.0, brightness - 0.4);
            glow += s * w;
            total += w;
        }
    }
    if (total > 0.0) glow /= total;

    // pulse the glow over time
    float pulse = 0.6 + 0.4 * sin(time * 2.0);
    frag_color = col + glow * 0.8 * pulse;
    frag_color.a = 1.0;
}
@end

@program bloom vs fs
