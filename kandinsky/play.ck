class Play {
    0 => static int NONE;  // not played
    1 => static int ACTIVE;   // playing
    0 => int state;

    fun void setColor(vec3 color) {}
    fun void play() {}
    fun void stop() {}
}

public class LinePlay extends Play {
    HevyMetl a => NRev rev => Pan2 pan => dac;
    0.1 => rev.mix;

    fun setColor(vec3 color) {
        Color.rgb2hsv(color) => vec3 hsv;
        // map value(brightness) to pitch
        Std.mtof(Math.map2(hsv.z, 0., 1., 30, 100)) => a.freq;
        // map saturation to loudness
        Math.map2(hsv.y, 0., 1., .1, 0.7) => a.gain;
    }

    fun void play(float p) {
        // <<< "play" >>>;
        // map pan
        p => pan.pan;

        if (state == NONE) {
            ACTIVE => state;
            1 => a.noteOn;
        }
    }

    fun void stop() {
        // <<< "stop" >>>;
        if (state == ACTIVE) {
            NONE => state;
            1 => a.noteOff;
        }
    }
}

public class CirclePlay extends Play {
    PercFlut a => NRev rev => Pan2 pan => dac;
    0.1 => rev.mix;

    fun setColor(vec3 color) {
        Color.rgb2hsv(color) => vec3 hsv;
        // map value(brightness) to pitch
        Std.mtof(Math.map2(hsv.z, 0., 1., 30, 50)) => a.freq;
        // map saturation to loudness
        Math.map2(hsv.y, 0., 1., .1, 1.2) => a.gain;
    }

    fun void play(float p, float amount) {
        // <<< "play" >>>;
        // map pan
        p => pan.pan;
        // map chord length to reverb
        amount => rev.mix;

        if (state == NONE) {
            ACTIVE => state;
            1 => a.noteOn;
        }
    }

    fun void stop() {
        // <<< "stop" >>>;
        if (state == ACTIVE) {
            NONE => state;
            1 => a.noteOff;
        }
    }
}

public class PlanePlay extends Play {

}
