@import "mouse.ck"
@import "play.ck"

// Various object class for painting ==========================================

public class Shape extends GGen {
    GG.camera() @=> GCamera @ cam;
    16.0 / 9.0 => float ASPECT;
    cam.viewSize() => float HEIGHT;
    cam.viewSize() * ASPECT => float WIDTH;

    fun void stop() {
        // stop playing, useful when erasing shapes
    }

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
    LinePlay play;

    fun Line(vec2 start, vec2 end, vec3 color, float width, float depth) {
        start => this.start;
        end => this.end;
        end - start => this.dd;
        (start.y - end.y) / (start.x - end.x) => slope;
        Math.sqrt(dd.x * dd.x + dd.y * dd.y) => this.length;
        dd.x / length => this.cos;
        dd.y / length => this.sin;

        width => g.width;
        color => g.color;
        play.setColor(color);
        g.positions([start, end]);
        depth => this.posZ;
    }

    fun void stop() {
        play.stop();
    }

    fun void updatePos(vec2 start, vec2 end) {
        g.positions([start, end]);
    }

    fun vec3 color() {
        return g.color();
    }

    fun void color(vec3 c) {
        g.color(c);
        play.setColor(c);
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

    fun int touchX(float x) {
        if (x >= Math.min(start.x, end.x) && x <= Math.max(start.x, end.x)) {
            // calculate the intersection's y
            getY(x) => float y;
            play.play(y2pan(y));
            return true;
        } else {
            play.stop();
            return false;
        }
    }

    fun int touchY(float y) {
        return (y >= Math.min(start.y, end.y) && y <= Math.max(start.y, end.y));
    }
}

public class Circle extends Shape {
    GCircle g --> this;
    FlatMaterial mat;
    g.mat(mat);
    CircleGeometry geo(.5, 96, 0., 2 * Math.pi);
    g.geo(geo);

    CirclePlay play;

    vec2 center;
    float r;

    fun Circle(vec2 center, float r, vec3 color, float depth) {
        center => this.center;
        r => this.r;
        @(center.x, center.y, depth) => this.pos;
        r * 2. => this.sca;
        color => mat.color;
        play.setColor(color);
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
        play.setColor(c);
    }

    fun void stop() {
        play.stop();
    }

    fun int isHovered(Mouse @ mouse) {
        mouse.pos - center => vec2 dd;
        return dd.x * dd.x + dd.y * dd.y <= r * r;
    }

    fun int touchX(float x) {
        if (x >= center.x - r && x <= center.x + r) {
            // calculate chord length
            Math.sqrt(r * r - (x - center.x) * (x - center.x)) / r => float amount;
            play.play(y2pan(center.y), amount);
            return true;
        } else {
            play.stop();
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

    PlanePlay play;

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

    fun void stop() {
        play.stop();
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
    }

    fun int isHovered(Mouse @ mouse) {
        scaX() / 2. => float halfWidth;
        scaY() / 2. => float halfHeight;
        return (mouse.pos.x > pos().x - halfWidth && mouse.pos.x < pos().x + halfWidth &&
                mouse.pos.y > pos().y - halfHeight && mouse.pos.y < pos().y + halfHeight);
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
