@import "constant.ck"
@import "mouse.ck"
// @import "play.ck"

// Various object class for painting ==========================================

public class Shape extends GGen {
    Shred @ playShred;

    fun void _play() {}

    fun void play() {
        <<< "play sporked" >>>;
        spork ~ _play() @=> playShred;
    }

    fun void stop() {
        if (playShred != null)
            playShred.exit();
    }

    fun int touchX(float x) {
        return false;
    }

    fun int touchY(float y) {
        return false;
    }

    fun float x2pan(float x) {
        return x / C.WIDTH;
    }

    fun float y2pan(float y) {
        return Math.map2(y, C.UP, C.DOWN, -1., 1.);
        // TODO: specify play direction
    }

    fun int isHovered(Mouse @ mouse) {
        return false;
    }
}

public class Line extends Shape {
    GLines g --> this;
    vec2 start, end, dd;
    float cos, sin;
    float length;
    float slope;

    FrencHrn a => NRev rev => Pan2 pan => dac;
    0.2 => a.gain;
    0.1 => rev.mix;

    fun Line(vec2 start, vec2 end, vec3 color, float width, float depth) {
        start => this.start;
        end => this.end;
        end - start => this.dd;
        (start.y - end.y) / (start.x - end.x) => slope;
        Math.sqrt(dd.x * dd.x + dd.y * dd.y) => this.length;
        dd.x / length => this.cos;
        dd.y / length => this.sin;

        width => g.width;
        this.color(color);
        g.positions([start, end]);
        depth => this.posZ;
    }

    fun void updatePos(vec2 start, vec2 end) {
        g.positions([start, end]);
    }

    fun vec3 color() {
        return g.color();
    }

    fun void color(vec3 c) {
        g.color(c);

        Color.rgb2hsv(c) => vec3 hsv;
        // map value(brightness) to pitch
        Std.mtof(Math.map2(hsv.z, 0., 1., 30, 100)) => a.freq;
        // map saturation to loudness
        Math.map2(hsv.y, 0., 1., .1, 0.7) => a.gain;
    }

    fun float width() {
        return g.width();
    }

    fun void width(float w) {
        g.width(w);
    }

    fun float getX(float y) {
        return (1./slope) * (y - start.y) + start.x;
    }

    fun float getY(float x) {
        return slope * (x - start.x) + start.y;
    }

    fun int isHovered(Mouse @ mouse) {
        // transform mouse position to line coordinate
        mouse.pos.x - start.x => float x_tr;
        mouse.pos.y - start.y => float y_tr;
        x_tr * cos + y_tr * sin => float x_prime;
        -x_tr * sin + y_tr * cos => float y_prime;

        return (0 <= x_prime && x_prime <= length && -width() / 2. <= y_prime && y_prime <= width() / 2.);
    }

    fun void _proceed(dur t) {
        now => time t0;
        while (now - t0 < t) {
            GG.nextFrame() => now;
        }
    }

    fun void _play() {
        Math.min(start.x, end.x) => float left;
        Math.max(start.x, end.x) => float right;
        (left / C.SPEED) * 1::second + C.TX / 2. => dur left_t;
        (right / C.SPEED) * 1::second + C.TX / 2. => dur right_t;
        // current playline time
        now % C.TX => dur t;
        if (t > left_t)  // passed, next cycle
            _proceed(C.TX - t + left_t);
        else  // this cycle
            _proceed(left_t - t);
        while (true) {
            // TODO: can perhaps be further optimized
            // now playline touches the left side
            left => float x;
            // touching the shape
            1 => a.noteOn;
            // <<< "on" >>>;
            while (left <= x && x < right) {
                pan.pan(getY(x));
                GG.nextFrame() => now;
                (now % C.TX) / 1::second * C.SPEED - C.WIDTH / 2. => x;
            }
            // <<< "off" >>>;
            1 => a.noteOff;
            // skip to next cycle
            _proceed(C.TX - right_t + left_t);
        }
    }

    fun void stop() {
        1 => a.noteOff;
        if (playShred != null)
            playShred.exit();
    }

    // fun int touchX(float x) {
    //     if (x >= Math.min(start.x, end.x) && x <= Math.max(start.x, end.x)) {
    //         // calculate the intersection's y
    //         getY(x) => float y;
    //         play(y2pan(y));
    //         return true;
    //     } else {
    //         stop();
    //         return false;
    //     }
    // }
    //
    // fun int touchY(float y) {
    //     return (y >= Math.min(start.y, end.y) && y <= Math.max(start.y, end.y));
    // }
}

public class Circle extends Shape {
    GCircle g --> this;
    FlatMaterial mat;
    g.mat(mat);
    CircleGeometry geo(.5, 96, 0., 2 * Math.pi);
    g.geo(geo);

    vec2 center;
    float r;

    PercFlut a => Pan2 pan;
    NRev rev[2];
    for (int ch; ch < 2; ++ch)
        pan.chan(ch) => rev[ch] => dac.chan(ch);
    0.2 => rev[0].mix => rev[1].mix;

    fun Circle(vec2 center, float r, vec3 color, float depth) {
        center => this.center;
        r => this.r;
        @(center.x, center.y, depth) => this.pos;
        r * 2. => this.sca;
        this.color(color);
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);

        Color.rgb2hsv(c) => vec3 hsv;
        // map value(brightness) to pitch
        Std.mtof(Math.map2(hsv.z, 0., 1., 30, 50)) => a.freq;
        // map saturation to loudness
        Math.map2(hsv.y, 0., 1., .1, 1.2) => a.gain;
    }

    fun int isHovered(Mouse @ mouse) {
        mouse.pos - center => vec2 dd;
        return dd.x * dd.x + dd.y * dd.y <= r * r;
    }

    fun void play() {
    }

    fun void stop() {
        1 => a.noteOff;
        if (playShred != null)
            playShred.exit();
    }

    // fun int touchX(float x) {
    //     if (x >= center.x - r && x <= center.x + r) {
    //         // calculate chord length
    //         Math.sqrt(r * r - (x - center.x) * (x - center.x)) => float amount;
    //         play(y2pan(center.y), amount);
    //         return true;
    //     } else {
    //         stop();
    //         return false;
    //     }
    // }
    //
    // fun int touchY(float y) {
    //     return (y >= center.y - r && y <= center.y + r);
    // }
}

public class Plane extends Shape {
    GPlane g --> this;
    FlatMaterial mat;
    vec2 start, end;
    g.mat(mat);

    HevyMetl a => NRev rev => Pan2 pan => dac;
    0.1 => rev.mix;

    fun Plane(vec2 pos, float scale, vec3 color, float depth) {
        // might be useless, only square
        @(pos.x, pos.y, depth) => this.pos;
        scale => this.sca;
        @(pos.x - scale / 2., pos.y - scale / 2.) => this.start;
        @(pos.x + scale / 2., pos.y + scale / 2.) => this.end;
        this.color(color);
    }

    fun Plane(vec2 start, vec2 end, vec3 color, float depth) {
        // rectangular
        start => this.start;
        end => this.end;
        (start + end) / 2. => vec2 pos;
        @(pos.x, pos.y, depth) => this.pos;
        Math.fabs((start - end).x) => this.scaX;
        Math.fabs((start - end).y) => this.scaY;
        this.color(color);
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);

        Color.rgb2hsv(c) => vec3 hsv;
        // map value(brightness) to pitch
        Std.mtof(Math.map2(hsv.z, 0., 1., 30, 100)) => a.freq;
        // map saturation to loudness
        Math.map2(hsv.y, 0., 1., .1, 0.7) => a.gain;
    }

    fun int isHovered(Mouse @ mouse) {
        scaX() / 2. => float halfWidth;
        scaY() / 2. => float halfHeight;
        return (mouse.pos.x > pos().x - halfWidth && mouse.pos.x < pos().x + halfWidth &&
                mouse.pos.y > pos().y - halfHeight && mouse.pos.y < pos().y + halfHeight);
    }

    fun void play() {
    }

    fun void stop() {
        1 => a.noteOff;
        if (playShred != null)
            playShred.exit();
    }

    // fun int touchX(float x) {
    //     if (x >= Math.min(start.x, end.x) && x <= Math.max(start.x, end.x)) {
    //         play(y2pan(this.posY()), this.scaY());
    //         return true;
    //     } else {
    //         stop();
    //         return false;
    //     }
    // }
    //
    // fun int touchY(float y) {
    //     return false;
    // }
}

