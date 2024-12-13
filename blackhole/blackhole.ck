// constants & setups =========================================================
0.9 => float BLOOM_INTENSITY;
0.02 => float ACC;
0.01 => float ROTATION_ACC;

// camera
GG.scene().camera() @=> GCamera cam;
cam.posZ(4.);
cam.lookAt(@(0, 0, 0));
// GG.scene().camera(cam);

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

// shader =====================================================================
// create the custom shader description
ShaderDesc shader_desc;
me.dir() + "blackhole.wgsl" => shader_desc.vertexPath;
me.dir() + "blackhole.wgsl" => shader_desc.fragmentPath;
// default vertex layout (each vertex has a float3 position, float3 normal, float2 uv)
[ VertexFormat.Float3, VertexFormat.Float3, VertexFormat.Float2 ] @=> shader_desc.vertexLayout; 

// compile the shader
Shader universe_shader(shader_desc);

// assign shader to a material
Material universe_mat;
universe_mat.shader(universe_shader);

PlaneGeometry plane_geo;
// apply our custom material to a mesh
GMesh universe(plane_geo, universe_mat) --> GG.scene();
6.6 => universe.sca;

// Texture.load(me.dir() + "./assets/me.jpg") @=> Texture universe_txt;
Texture.load(me.dir() + "./assets/stars_e_l_c.png") @=> Texture universe_txt;
Texture.load(me.dir() + "./assets/noise.jpg") @=> Texture noise_txt;
<<< universe_txt.width(), universe_txt.height() >>>;

@(0.8, 0.2, 10.) => vec3 pos;
@(0., 0.) => vec2 rotation;
@(0., 0.) => vec2 view_turn;
universe_mat.texture(0, universe_txt);
universe_mat.uniformFloat3(1, pos);
universe_mat.uniformFloat2(2, rotation);
universe_mat.uniformFloat2(3, view_turn);
universe_mat.texture(4, noise_txt);

// audio ======================================================================
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

spork ~ addVoice(7::second + 0.0::second, 58+12, 7.7::second, 20.1::second); // C
spork ~ addVoice(7::second + 1.9::second, 60+12, 7.1::second, 16.2::second); // Eb
spork ~ addVoice(7::second + 6.5::second, 65+12, 8.5::second, 19.6::second); // F
spork ~ addVoice(7::second + 6.7::second, 53+12, 9.1::second, 24.7::second); // low F
spork ~ addVoice(7::second + 8.2::second, 68+12, 9.4::second, 17.8::second); // Ab
spork ~ addVoice(7::second + 9.6::second, 56+12, 7.9::second, 21.3::second); // low Ab
spork ~ addVoice(7::second + 15.0::second, 61+12, 9.2::second, 31.8::second); // Db

fun mouse_move() {
    vec2 init_mousePos, mousePos;
    while (true) {
        GG.nextFrame() => now;
        if (GWindow.mouseLeftDown()) {
            GWindow.mousePos() => init_mousePos;
            init_mousePos => mousePos;
        }
        if (GWindow.mouseLeft()) {
            // mouse is down
            GWindow.mousePos() => mousePos;
            0.0005 * (mousePos - init_mousePos) +=> view_turn;
            universe_mat.uniformFloat2(3, view_turn);
        }
    }
} spork ~ mouse_move();

// graphics ===================================================================
vec3 vel;
@(0.02, 0.) => vec2 rot_vel;
while (true) {
    GG.nextFrame() => now;

    // hide mouse cursor
    UI.setMouseCursor(UI_MouseCursor.None);

    // cam.posZ() - GG.dt() * 0.2 => cam.posZ;
    if (UI.isKeyPressed(UI_Key.A, true)) {
        GG.dt() -=> vel.x;
    } else if (UI.isKeyPressed(UI_Key.D, true)) {
        GG.dt() +=> vel.x;
    }
    if (UI.isKeyPressed(UI_Key.LeftShift, true)) {
        GG.dt() +=> vel.y;
    } else if (UI.isKeyPressed(UI_Key.LeftCtrl, true)) {
        GG.dt() -=> vel.y;
    }
    if (UI.isKeyPressed(UI_Key.W, true)) {
        GG.dt() -=> vel.z;
    } else if (UI.isKeyPressed(UI_Key.S, true)) {
        GG.dt() +=> vel.z;
    }
    vel*ACC +=> pos;
    universe_mat.uniformFloat3(1, pos);

    if (UI.isKeyPressed(UI_Key.LeftArrow, true)) {
        GG.dt() -=> rot_vel.x;
    } else if (UI.isKeyPressed(UI_Key.RightArrow, true)) {
        GG.dt() +=> rot_vel.x;
    }
    if (UI.isKeyPressed(UI_Key.UpArrow, true)) {
        GG.dt() +=> rot_vel.y;
    } else if (UI.isKeyPressed(UI_Key.DownArrow, true)) {
        GG.dt() -=> rot_vel.y;
    }
    rot_vel * ROTATION_ACC +=> rotation;
    Math.fmod(rotation.x, 1.) => rotation.x;
    Math.fmod(rotation.y, 1.) => rotation.y;
    universe_mat.uniformFloat2(2, rotation);
}
