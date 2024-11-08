// Various object class for painting ==========================================

public class Shape extends GGen {
    GG.camera() @=> GCamera @ cam;
    16.0 / 9.0 => float ASPECT;
    cam.viewSize() => float HEIGHT;
    cam.viewSize() * ASPECT => float WIDTH;

    fun int touchX(float x) {
        return false;
    }

    fun int touchY(float y) {
        return false;
    }

    fun float x2pan(float x) {
        return x / WIDTH;
    }

    fun float y2pan(float y) {
        return -y / HEIGHT;
        // TODO: specify play direction
    }
}

class LinePlay {
    0 => static int NONE;  // not played
    1 => static int ACTIVE;   // playing
    0 => int state;

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

public class Line extends Shape {
    GLines g --> this;
    vec2 start, end;
    float slope;
    LinePlay lp;

    fun Line(vec2 start, vec2 end, vec3 color, float width, float depth) {
        start => this.start;
        end => this.end;
        (start.y - end.y) / (start.x - end.x) => slope;
        width => g.width;
        color => g.color;
        lp.setColor(color);
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
        lp.setColor(c);
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

    fun int touchX(float x) {
        if (x >= Math.min(start.x, end.x) && x <= Math.max(start.x, end.x)) {
            // calculate the intersection's y
            getY(x) => float y;
            lp.play(y2pan(y));
            return true;
        } else {
            lp.stop();
            return false;
        }
    }

    fun int touchY(float y) {
        return (y >= Math.min(start.y, end.y) && y <= Math.max(start.y, end.y));
    }
}

class CirclePlay {
    0 => static int NONE;  // not played
    1 => static int ACTIVE;   // playing
    0 => int state;

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

public class Circle extends Shape {
    GCircle g --> this;
    FlatMaterial mat;
    g.mat(mat);
    CircleGeometry geo(.5, 96, 0., 2 * Math.pi);
    g.geo(geo);

    CirclePlay cp;

    vec2 center;
    float r;

    fun Circle(vec2 center, float r, vec3 color, float depth) {
        center => this.center;
        r => this.r;
        @(center.x, center.y, depth) => this.pos;
        r * 2. => this.sca;
        color => mat.color;
        cp.setColor(color);
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
        cp.setColor(c);
    }

    fun int touchX(float x) {
        if (x >= center.x - r && x <= center.x + r) {
            // calculate chord length
            Math.sqrt(r * r - (x - center.x) * (x - center.x)) / r => float amount;
            cp.play(y2pan(center.y), amount);
            return true;
        } else {
            cp.stop();
            return false;
        }
    }

    fun int touchY(float y) {
        return (y >= center.y - r && y <= center.y + r);
    }
}


public class Plane extends Shape {
    GPlane g --> this;
    FlatMaterial mat;
    vec2 start, end;
    g.mat(mat);

    fun Plane(vec2 pos, float scale, vec3 color, float depth) {
        // might be useless, only square
        @(pos.x, pos.y, depth) => this.pos;
        scale => this.sca;
        @(pos.x - scale / 2., pos.y - scale / 2.) => this.start;
        @(pos.x + scale / 2., pos.y + scale / 2.) => this.end;
        color => mat.color;
    }

    fun Plane(vec2 start, vec2 end, vec3 color, float depth) {
        // rectangular
        start => this.start;
        end => this.end;
        (start + end) / 2. => vec2 pos;
        @(pos.x, pos.y, depth) => this.pos;
        Math.fabs((start - end).x) => this.scaX;
        Math.fabs((start - end).y) => this.scaY;
        color => mat.color;
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
    }

    fun int touchX(float x) {
        if (x >= Math.min(start.x, end.x) && x <= Math.max(start.x, end.x)) {
            return true;
        }
        return false;
    }

    fun int touchY(float y) {
        return false;
    }
}

