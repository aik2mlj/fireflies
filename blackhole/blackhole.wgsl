#include FRAME_UNIFORMS
// will include the following:
// struct FrameUniforms {
//     projection: mat4x4f,                     // 4x4 projection matrix, used to transform from camera space to clip space.
//     view: mat4x4f,                           // 4x4 view matrix, used to transform from world space to camera space.
//     projection_view_inverse_no_translation: mat4x4f, // Inverse of the combined projection and view matrices, but without translation. Useful for certain non-world-space calculations (e.g., ray casting).
//     camera_pos: vec3f,                       // Position of the camera in world space.
//     time: f32,                               // Time elapsed (likely in seconds), useful for animations or time-dependent effects.
//     ambient_light: vec3f,                    // RGB color for the ambient light in the scene.
//     num_lights: i32,                         // Number of active lights in the scene.
//     background_color: vec4f,                 // RGBA color of the background.
// };
// @group(0) @binding(0) var<uniform> u_frame: FrameUniforms;

#include DRAW_UNIFORMS
// will include the following:
// struct DrawUniforms {
//     model: mat4x4f,                          // 4x4 model matrix, transforms from object space to world space for this instance.
//     id: u32                                  // Unique identifier for the draw instance, often used for object-specific effects or picking.
// };
// Each instance of a drawable object gets its own DrawUniforms entry.
// @group(2) @binding(0) var<storage> u_draw_instances: array<DrawUniforms>;

#include STANDARD_VERTEX_INPUT
// struct VertexInput {
//     @location(0) position : vec3f,           // Vertex position in object space, read from vertex buffer at location 0.
//     @location(1) normal : vec3f,             // Vertex normal vector, used for lighting calculations, read from vertex buffer at location 1.
//     @location(2) uv : vec2f,                 // Texture coordinates (UV mapping), read from vertex buffer at location 2.
//     @builtin(instance_index) instance : u32, // Built-in variable for the instance index, identifying which instance of the object is being rendered.
// };

#include STANDARD_VERTEX_OUTPUT
// struct VertexOutput {
//     @builtin(position) position : vec4f,     // Built-in variable for the clip-space position of the vertex, used for rasterization.
//     @location(0) v_worldpos : vec3f,         // World-space position of the vertex, passed to the fragment shader for effects like lighting.
//     @location(1) v_normal : vec3f,           // World-space normal vector, passed to the fragment shader for lighting calculations.
//     @location(2) v_uv : vec2f,               // Interpolated texture coordinates, passed to the fragment shader for sampling textures.
// };

const PI: f32 = 3.1415926538;

@group(1) @binding(0) var u_texture : texture_2d<f32>;  // background texture
@group(1) @binding(1) var<uniform> u_pos : vec3f;       // camera position
@group(1) @binding(2) var<uniform> u_rotation : vec2f;  // blackhole rotation

// standard vertex shader that applies mvp transform to input position,
// and passes interpolated world_position, normal, and uv data to fragment shader
@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    var u_Draw: DrawUniforms = u_draw_instances[in.instance];

    let worldpos = u_Draw.model * vec4f(in.position, 1.0f);

    out.position = (u_frame.projection * u_frame.view) * worldpos;
    out.v_worldpos = worldpos.xyz;
    out.v_normal = (u_Draw.model * vec4f(in.normal, 0.0)).xyz;
    out.v_uv = in.uv;

    return out;
}


// Function to compute an anti-aliased checkerboard pattern.
fn checkerAA(p: vec2f) -> f32 {
    let q = sin(PI * p * vec2f(10.0, 10.0));  // Create a sine pattern with periodicity in x and y directions.
    let m = q.x * q.y;                       // Combine the sine waves to create a checkerboard effect.
    // return 0.5 - m / fwidth(m);              // Apply anti-aliasing using the derivative of the function.
    // return step(0., m);
    return smoothstep(0., fwidth(m), m);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4f {
    // Transform fragCoord to normalized UV coordinates (-1 to 1).
    // let iResolution = vec2f(u_frame.projection_view_inverse_no_translation[0].xy); // Assume resolution in the first column of matrix.
    // let uv = (2.0 * fragCoord.xy - iResolution) / iResolution.x; // Normalize coordinates relative to resolution.
    let uv = 2. * in.v_uv - 1;

    // Parameters for the scene.
    let hfov = 2.;                           // Horizontal field of view.
    let radius = 1.0;

    // this is the vel of the ray shooting from the camera to the fragment
    var vel = normalize(vec3f(-1.0, uv * tan(hfov / 2.0)));

    // Initialize the position of the particle or camera.
    // let dist = 5.;
    // var pos = vec3f(-dist, 1.0, 0.0);
    let dist = abs(u_pos.z);
    var pos = vec3f(u_pos.z, u_pos.xy);
    var r = length(pos);                      // Distance from the origin.
    let dtau = 0.05;                           // Step size for iteration.

    // Iterative physics-based motion.
    while (r < dist * 2. || r < 500.) && r > radius {
        let ddtau = dtau * r;                 // Step size scales with the current radius.
        pos += vel * ddtau;                   // Update position.
        r = length(pos);                      // Update radius.
        let er = pos / r;                     // Unit vector in the radial direction.
        let c = cross(vel, er);               // Perpendicular vector for angular momentum.
        vel -= ddtau * dot(c, c) * er / (r * r); // Update velocity based on angular momentum.
    }

    // Calculate spherical coordinates for texture mapping.
    let phi1 = 0.5 - (atan2(vel.y, vel.x) / (PI)) ; // Azimuthal angle, normalized to (0,1)
    let theta1 = atan2(length(vel.xy), vel.z) / PI; // Polar angle., normalized to (0,1)

    // UV coordinates for the texture.
    let UV = fract(vec2f(phi1, theta1) + u_rotation); // rotate with time
    // let UV = fract(vec2f(phi1, theta1) + u_rotation * 0.); // rotate with time

    // load texture
    let dim: vec2u = textureDimensions(u_texture);
    let coords = vec2i(UV * vec2f(dim));
    var rgb = textureLoad(u_texture, coords, 0).rgb;
    // rgb += 0.3 * (rgb.xxx + rgb.yyy + rgb.zzz);
    // rgb /= 1.3;
    rgb = pow(rgb, vec3f(2.4));

    // default background: checkerboard pattern
    // rgb = vec3f(checkerAA(UV * 180.0 / PI / 30.0));
    let rgb_final = rgb * f32(r > radius);      // Apply visibility based on radius condition.

    // Return the final color.
    return vec4f(rgb_final, 1.0);            // Output the color with alpha = 1.0.
}
