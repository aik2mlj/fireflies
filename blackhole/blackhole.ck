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
1. => float radius;
universe_mat.texture(0, universe_txt);
universe_mat.uniformFloat3(1, pos);
universe_mat.uniformFloat2(2, rotation);
universe_mat.uniformFloat2(3, view_turn);
universe_mat.texture(4, noise_txt);
universe_mat.uniformFloat(5, radius);

vec3 vel;
@(0.02, 0.) => vec2 rot_vel;

// audio ======================================================================
fun void addVoice(dur offset, float midi, dur note_dur, dur loop_dur)
{
    NRev rev => Pan2 pan => dac;
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

// spork ~ addVoice(7::second + 0.0::second, 58+12, 7.7::second, 20.1::second); // C
// spork ~ addVoice(7::second + 1.9::second, 60+12, 7.1::second, 16.2::second); // Eb
// spork ~ addVoice(7::second + 6.5::second, 65+12, 8.5::second, 19.6::second); // F
// spork ~ addVoice(7::second + 6.7::second, 53+12, 9.1::second, 24.7::second); // low F
// spork ~ addVoice(7::second + 8.2::second, 68+12, 9.4::second, 17.8::second); // Ab
// spork ~ addVoice(7::second + 9.6::second, 56+12, 7.9::second, 21.3::second); // low Ab
// spork ~ addVoice(7::second + 15.0::second, 61+12, 9.2::second, 31.8::second); // Db

fun void bh_sound() {
    SinOsc m => SinOsc a => JCRev rev => Pan2 pan => dac;
    2 => a.sync;  // FM synth

    0.1 => rev.mix;
    0 => a.gain;

    while (true) {
        // <<< rot_vel.magnitude() * ROTATION_ACC >>>;
        // Math.map2(rot_vel.magnitude() * ROTATION_ACC, 0., 0.1, 0.5, 10.) => float gap;
        // (100./gap)::ms => now;
        10::ms => now;

        // rot_vel.magnitude() * ROTATION_ACC => float spin;
        pos.magnitude() => float dist;
        1. / (dist + 1.) => a.gain;
        Math.map2(dist, 0., 15., 30., 500.) => a.freq;
        a.freq() / Math.random2f(1.1,9.) => m.freq;
        // Math.pow(radius, 10) => m.gain;
        Math.random2f(1, Math.pow(1. + radius, 8)) => m.gain;

        // pan
        Math.sin(-Math.atan2(pos.x, pos.z) - view_turn.x) => pan.pan;
    }
}
spork ~ bh_sound();

// mouse ======================================================================

fun void mouse_move() {
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

fun vec3 rotate(vec3 o, vec2 turn) {
    @(o.x, Math.cos(turn.y)*o.y-Math.sin(turn.y)*o.z, Math.sin(turn.y)*o.y+Math.cos(turn.y)*o.z) => vec3 o1;
    @(Math.cos(turn.x)*o1.x+Math.sin(turn.x)*o1.z, o1.y, -Math.sin(turn.x)*o1.x+Math.cos(turn.x)*o1.z) => vec3 o2;
    return o2;
}

fun float impulse( float k, float x ){
    k*x => float h;
    return h*Math.exp(1.0-h);
}

fun void radius_pumping() {
    now => time t0;
    while (now - t0 < 1::second) {
        GG.nextFrame() => now;
        (now - t0) / 1::second => float t;
        1 + impulse(8, t) => radius;
        universe_mat.uniformFloat(5, radius);
    }
}

while (true) {
    GG.nextFrame() => now;

    // hide mouse cursor
    UI.setMouseCursor(UI_MouseCursor.None);

    @(0,0,0) => vec3 acc_no_rot;
    // cam.posZ() - GG.dt() * 0.2 => cam.posZ;
    if (UI.isKeyPressed(UI_Key.A, true)) {
        GG.dt() -=> acc_no_rot.x;
    } else if (UI.isKeyPressed(UI_Key.D, true)) {
        GG.dt() +=> acc_no_rot.x;
    }
    if (UI.isKeyPressed(UI_Key.LeftShift, true)) {
        GG.dt() +=> acc_no_rot.y;
    } else if (UI.isKeyPressed(UI_Key.LeftCtrl, true)) {
        GG.dt() -=> acc_no_rot.y;
    }
    if (UI.isKeyPressed(UI_Key.W, true)) {
        GG.dt() -=> acc_no_rot.z;
    } else if (UI.isKeyPressed(UI_Key.S, true)) {
        GG.dt() +=> acc_no_rot.z;
    }
    if (UI.isKeyPressed(UI_Key.Space, true)) {
        // match velocity (credit: outer wilds)
        0.9 *=> vel;
    }
    rotate(acc_no_rot, -1. * view_turn) => vec3 acc;
    acc +=> vel;
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

    if (UI.isKeyPressed(UI_Key.Enter, false)) {
        // pumping the black hole
        spork ~ radius_pumping();
    }
}
