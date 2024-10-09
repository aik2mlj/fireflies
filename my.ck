//-----------------------------------------------------------------------------
// name: sndpeek.ck
// desc: sndpeek in ChuGL!
// 
// author: Ge Wang (https://ccrma.stanford.edu/~ge/)
//         Andrew Zhu Aday (https://ccrma.stanford.edu/~azaday/)
//         Kunwoo Kim (https://https://kunwookim.com/)
// date: Fall 2023
//-----------------------------------------------------------------------------

// window size
256 => int WINDOW_SIZE;
// y position of spectrum
-2.5 => float SPECTRUM_Y;
// y offset of firefly and waveform
-1 => float FIREFLY_Y;
// width of waveform and spectrum display
5 => float WAVEFORM_WIDTH;
// waveform rotation angle along Y
-1.5 => float WAVEFORM_ROT_Y;
// waterfall depth
640 => int WATERFALL_DEPTH;
// interpolation constant
0.5 => float FLEX;
// colors
@(255, 230, 109)/255.0 => vec3 FIREFLY_COLOR;
@(218, 232, 241)/255.0 => vec3 MOON_COLOR;
@(2, 48, 32)/255.0 => vec3 FOREST_COLOR;
// bloom intensity
0.8 => float BLOOM_INTENSITY;
// firefly color intensity
3 => float INTENSITY;
// POW CRISP
0.8 => float CRISP;
// waterfall
40 => float DISPLAY_WIDTH;

// window title
GWindow.title( "firefly" );
// uncomment to fullscreen
GWindow.fullscreen();

GOrbitCamera cam --> GG.scene();
cam.posZ(8.0);
cam.lookAt(@(0,0,0));
GG.scene().camera(cam);

// firefly
// TODO: tweak params
SphereGeometry sphere_geo(0.05, 32, 16, 0., 2*Math.pi, 0., Math.pi);
FlatMaterial mat;
mat.color(FIREFLY_COLOR * INTENSITY);
GMesh firefly(sphere_geo, mat) --> GG.scene();
@(0, FIREFLY_Y, 0) => firefly.translate;

// waveform renderer
GLines waveform --> GG.scene();
waveform.rotZ(- Math.pi / 2);
// waveform.rotX(1);
waveform.rotY(WAVEFORM_ROT_Y);
waveform.translate(@(0, -WAVEFORM_WIDTH/2 * Math.cos(WAVEFORM_ROT_Y) + FIREFLY_Y, -WAVEFORM_WIDTH/2 * Math.sin(WAVEFORM_ROT_Y)));
// waveform.posZ()
// waveform.posY(FIREFLY_Y - WAVEFORM_WIDTH / 2);
waveform.width(.04);
waveform.color(FIREFLY_COLOR);

// many fireflies out there
60 => int FIREFLY_NUM;
SphereGeometry sphere_geo_many(0.02, 32, 16, 0., 2*Math.pi, 0., Math.pi);
FlatMaterial mat_many;
mat_many.color(FIREFLY_COLOR);
GMesh fireflies[FIREFLY_NUM];
for (int i; i < FIREFLY_NUM; i++) {
    GMesh sphere(sphere_geo_many, mat_many) @=> fireflies[i];
    fireflies[i] --> GG.scene();
    @(Math.random2f(-5, 5), Math.random2f(-5, 1), Math.random2f(-5, 5)) => fireflies[i].translate;
}

// moon
// SphereGeometry sphere_moon(0.4, 32, 16, 0., 2*Math.pi, 0., Math.pi/2);
// FlatMaterial mat_moon;
// mat_moon.color(MOON_COLOR * 0.5);
// GMesh moon(sphere_moon, mat_moon) --> GG.scene();
// @(3, 3, -2) => moon.translate;
// -Math.pi / 2 => moon.rotZ;
// -1 => moon.rotX;

// ground
GPlane ground --> GG.scene();
@(5,5,5) => ground.color;
50 => float SCALE;
SCALE => ground.sca;
16./9. * SCALE => ground.scaX;
Math.pi => ground.rotX;
@(0, 0, -50) => ground.translate;

Texture.load(me.dir() + "./imgs/twilight.jpg" ) @=> Texture tex;
ground.colorMap(tex);

// remove light
GG.scene().light() @=> GLight light;
0. => light.intensity;

// global blooming effect
GG.outputPass() @=> OutputPass output_pass;
GG.renderPass() --> BloomPass bloom_pass --> output_pass;
bloom_pass.intensity(BLOOM_INTENSITY);
bloom_pass.input(GG.renderPass().colorOutput());
output_pass.input(bloom_pass.colorOutput());

// make a waterfall
Waterfall waterfall --> GG.scene();
// translate down
waterfall.posY( SPECTRUM_Y );

// which input?
adc => Gain input;
// SinOsc sine => Gain input => dac; .15 => sine.gain;
// estimate loudness
input => Gain gi => OnePole onepole => blackhole;
input => gi;
4 => gi.op;
0.999 => onepole.pole;
// accumulate samples from mic
input => Flip accum => blackhole;
// take the FFT
input => PoleZero dcbloke => FFT fft => blackhole;
// set DC blocker
.95 => dcbloke.blockZero;
// set size of flip
WINDOW_SIZE => accum.size;
// set window type and size
Windowing.hann(WINDOW_SIZE) => fft.window;
// set FFT size (will automatically zero pad)
WINDOW_SIZE*2 => fft.size;
// get a reference for our window for visual tapering of the waveform
Windowing.hann(WINDOW_SIZE*2) @=> float window[];

// sample array
float samples[WINDOW_SIZE];
// FFT response
complex response[0];
// a vector to hold positions
vec2 positions[WINDOW_SIZE];

// custom GGen to render waterfall
class Waterfall extends GGen
{
    // waterfall playhead
    0 => int playhead;
    // lines
    GLines wfl[WATERFALL_DEPTH];
    // color
    @(.01, .01, .01) => vec3 color;

    // iterate over line GGens
    for( GLines w : wfl )
    {
        // aww yea, connect as a child of this GGen
        w --> this;
        // line width
        w.width(0.1);
        // color
        w.color( color );
    }

    // copy
    fun void latest( vec2 positions[] )
    {
        // set into
        positions => wfl[playhead].positions;
        // advance playhead
        playhead++;
        // wrap it
        WATERFALL_DEPTH %=> playhead;
    }

    // update
    fun void update( float dt )
    {
        // position
        playhead => int pos;
        // so good
        for( int i; i < wfl.size(); i++ )
        {
            // start with playhead-1 and go backwards
            pos--; if( pos < 0 ) WATERFALL_DEPTH-1 => pos;
            // offset Z
            wfl[pos].posZ( -i );
            // set fade
            wfl[pos].color( color * Math.pow(1.0 - (i$float / WATERFALL_DEPTH), 4) );
        }
    }
}

// keyboard controls and getting audio from dac
fun void kbListener()
{
    SndBuf buf => input;
    .0 => buf.gain;
    "special:dope" => buf.read;
    while (true) {
        GG.nextFrame() => now;
        if (UI.isKeyPressed(UI_Key.Space, false)) {
            .3 => buf.gain;
            0 => buf.pos;
        }
    }
} 
spork ~ kbListener();

float magwf[WINDOW_SIZE];
float pre_magwf[WINDOW_SIZE];
// map audio buffer to 3D positions
fun void map2waveform( float in[], vec2 out[] )
{
    if( in.size() != out.size() )
    {
        <<< "size mismatch in map2waveform()", "" >>>;
        return;
    }
    
    // mapping to xyz coordinate
    WAVEFORM_WIDTH => float width;
    0.05 => float neg_flex;
    0.2 => float pos_flex;
    for( 0 => int i; i < in.size(); i++ )
    {
        // space evenly in X
        -width/2 + width/WINDOW_SIZE*i => out[i].x;
        in[i] * 10 * window[i+20] => magwf[i];
        // interpolation
        if (pre_magwf[i] > magwf[i])
            pre_magwf[i] + (magwf[i] - pre_magwf[i]) * neg_flex => magwf[i];
        else
            pre_magwf[i] + (magwf[i] - pre_magwf[i]) * pos_flex => magwf[i];
        // map y, using window function to taper the ends
        magwf[i] => out[i].y;
        magwf[i] => pre_magwf[i];
    }
}

float magspec[WINDOW_SIZE];
float pre_magspec[WINDOW_SIZE];
// map FFT output to 3D positions
fun void map2spectrum( complex in[], vec2 out[] )
{
    if( in.size() != out.size() )
    {
        <<< "size mismatch in map2spectrum()", "" >>>;
        return;
    }

    // mapping to xyz coordinate
    DISPLAY_WIDTH => float width;
    0.02 => float neg_flex;
    0.04 => float pos_flex;
    for( 0 => int i; i < in.size(); i++ )
    {
        // space logarithmically in X
        -width/2 + width * Math.log(i + 1) / Math.log(WINDOW_SIZE) => out[i].x;
        // map frequency bin magnitide in Y
        15 * Math.sqrt( (in[i]$polar).mag * 25 ) => magspec[i];
        // interpolation
        if (pre_magspec[i] > magspec[i])
            pre_magspec[i] + (magspec[i] - pre_magspec[i]) * neg_flex => magspec[i];
        else
            pre_magspec[i] + (magspec[i] - pre_magspec[i]) * pos_flex => magspec[i];
        // map y, using window function to taper the ends
        magspec[i] => out[i].y;
        magspec[i] => pre_magspec[i];
    }

    waterfall.latest( out );
}

// do audio stuff
fun void doAudio()
{
    while( true )
    {
        // upchuck to process accum
        accum.upchuck();
        // get the last window size samples (waveform)
        accum.output( samples );
        // upchuck to take FFT, get magnitude reposne
        fft.upchuck();
        // get spectrum (as complex values)
        fft.spectrum( response );
        // jump by samples
        WINDOW_SIZE::samp/2 => now;
    }
}
spork ~ doAudio();

fun void controlSine( Osc s )
{
    while( true )
    {
        100 + (Math.sin(now/second*1)+1)/2*20000 => s.freq;
        10::ms => now;
    }
}
// spork ~ controlSine( sine );

fun void brightness_change() {  
    float prev;
    float curr;
    0.6 => float slewUp;
    0.05 => float slewDown;
    while (true) {
        GG.nextFrame() => now;
        // get current signal strength
        Math.pow(onepole.last(), CRISP) => curr;
        
        // interpolate
        if (prev < curr)
            prev + (curr - prev) * slewUp => curr;
        else
            prev + (curr - prev) * slewDown => curr;
        
        // change color of circle
        curr * FIREFLY_COLOR * INTENSITY => mat.color;
        curr * FIREFLY_COLOR => mat_many.color;
        Math.map(Math.atan(curr), 0, 1.3, 0.3, 0.6) => bloom_pass.radius;
        
        // update previous value
        curr => prev;
    }
}
spork ~ brightness_change();

// graphics render loop
while( true )
{
    // map to interleaved format
    map2waveform( samples, positions );
    // set the mesh position
    waveform.positions( positions );
    // map to spectrum display
    map2spectrum( response, positions );

    // next graphics frame
    GG.nextFrame() => now;
    // draw UI
    if (UI.begin("Firefly")) {  // draw a UI window called "Tutorial"
        // scenegraph view of the current scene
        UI.scenegraph(GG.scene()); 
    }
    UI.end(); // end of UI window, must match UI.begin(...)

}

