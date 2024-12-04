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

// begin fragment shader ----------------------------

// your custom material uniforms go in @group(1)
// @group(1) @binding(0) var<uniform> u_color : vec3f;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4f {
    return vec4f(abs(sin(u_frame.time)), 0.4, 0.5, 1.0);
}
