// bloom intensity
0.9 => float BLOOM_INTENSITY;

// camera
GOrbitCamera cam --> GG.scene();
cam.posZ(4.);
cam.lookAt(@(0, 0, 0));
GG.scene().camera(cam);

// GWindow.fullscreen();

// remove light
GG.scene().light() @=> GLight light;
0. => light.intensity;

// global blooming effect
GG.outputPass() @=> OutputPass output_pass;
GG.renderPass() --> BloomPass bloom_pass --> output_pass;
bloom_pass.intensity(BLOOM_INTENSITY);
bloom_pass.input(GG.renderPass().colorOutput());
output_pass.input(bloom_pass.colorOutput());

// create the custom shader description
ShaderDesc shader_desc;
me.dir() + "blackhole.wgsl" => shader_desc.vertexPath;
me.dir() + "blackhole.wgsl" => shader_desc.fragmentPath;
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
// GMesh mesh(new SuzanneGeometry, custom_material) --> GG.scene();
PlaneGeometry plane_geo;
GMesh mesh(plane_geo, custom_material) --> GG.scene();
6.6 => mesh.sca;
// 1.8 => mesh.scaY;

Texture.load(me.dir() + "assets/stars_e_l_c.png") @=> Texture bg_texture;
// Texture.load(me.dir() + "assets/me.jpg") @=> Texture bg_texture;
<<< bg_texture.width(), bg_texture.height() >>>;

@(-0.8, 0.2, -10.) => vec3 pos;
custom_material.texture(0, bg_texture);
custom_material.uniformFloat3(1, pos);

// audio
Gain input => dac;

1. => input.gain;
fun void addVoice(dur offset, float midi, dur note_dur, dur loop_dur)
{
    NRev rev => input;
    rev => Pan2 pan => dac;
    .50 => rev.mix;

    Mandolin mdl => Envelope env => rev;
    Std.mtof(midi) => mdl.freq;
    .2 => mdl.gain;
    1::ms => env.duration;

    offset => now;
    int instr;
    while (true) {
        Math.random2f(-0.6, 0.6) => pan.pan;
        mdl.noteOn(1);
        env.keyOn();
        note_dur/2 => now;
        env.keyOff();
        note_dur/2 => now;
        mdl.noteOff(1);
        (loop_dur - note_dur) => now;
    }
}

spork ~ addVoice(1::second 0.0::second, 58+12, 7.7::second, 20.1::second); // C
spork ~ addVoice(1::second + 1.9::second, 60+12, 7.1::second, 16.2::second); // Eb
spork ~ addVoice(1::second + 6.5::second, 65+12, 8.5::second, 19.6::second); // F
spork ~ addVoice(1::second + 6.7::second, 53+12, 9.1::second, 24.7::second); // low F
spork ~ addVoice(1::second + 8.2::second, 68+12, 9.4::second, 17.8::second); // Ab
spork ~ addVoice(1::second + 9.6::second, 56+12, 7.9::second, 21.3::second); // low Ab
spork ~ addVoice(1::second + 15.0::second, 61+12, 9.2::second, 31.8::second); // Db

vec3 v;
while (true) {
    GG.nextFrame() => now;
    // cam.posZ() - GG.dt() * 0.2 => cam.posZ;
    if (UI.isKeyPressed(UI_Key.A, true)) {
        GG.dt() +=> v.x;
    } else if (UI.isKeyPressed(UI_Key.D, true)) {
        GG.dt() -=> v.x;
    }
    if (UI.isKeyPressed(UI_Key.LeftShift, true)) {
        GG.dt() -=> v.y;
    } else if (UI.isKeyPressed(UI_Key.LeftCtrl, true)) {
        GG.dt() +=> v.y;
    }
    if (UI.isKeyPressed(UI_Key.W, true)) {
        GG.dt() +=> v.z;
    } else if (UI.isKeyPressed(UI_Key.S, true)) {
        GG.dt() -=> v.z;
    }
    v*0.05 +=> pos;
    custom_material.uniformFloat3(1, pos);
}
