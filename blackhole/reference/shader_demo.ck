// create the custom shader description
ShaderDesc shader_desc;
me.dir() + "shader_demo.wgsl" => shader_desc.vertexPath;
me.dir() + "shader_demo.wgsl" => shader_desc.fragmentPath;
// default vertex layout (each vertex has a float3 position, float3 normal, float2 uv)
[ VertexFormat.Float3, VertexFormat.Float3, VertexFormat.Float2 ] @=> shader_desc.vertexLayout; 

// compile the shader
Shader custom_shader(shader_desc);

// assign shader to a material
Material custom_material;
custom_material.shader(custom_shader);
// initialize material uniforms
// custom_material.uniformFloat3(0, Color.RED);

// apply our custom material to a mesh
GMesh mesh(new SuzanneGeometry, custom_material) --> GG.scene();

while (true) {
    GG.nextFrame() => now;
}
