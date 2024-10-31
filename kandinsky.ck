//-----------------------------------------------------------------------------
// name: kandinsky.ck
// desc: abstract painting sonified
//
// author: Lejun Min  (https://aik2.site)
// date: Fall 2024
//-----------------------------------------------------------------------------

// Initialize Mouse Manager ===================================================
Mouse mouse;
spork ~ mouse.selfUpdate(); // start updating mouse position

// Scene setup ================================================================
GG.scene() @=> GScene @ scene;
GG.windowed(1600, 900);
GG.camera() @=> GCamera @ cam;
cam.orthographic();  // Orthographic camera mode for 2D scene

// light
GG.scene().light() @=> GLight light;
0. => light.intensity;

16.0 / 9.0 => float ASPECT;
cam.viewSize() => float HEIGHT;
cam.viewSize() * ASPECT => float WIDTH;
-WIDTH / 2 => float LEFT;
WIDTH / 2 => float RIGHT;
-HEIGHT / 2 => float DOWN;
HEIGHT / 2 => float UP;
0.4 => float TOOLBAR_SIZE;
0.1 => float TOOLBAR_PADDING;

// colors
@(242., 169., 143.) / 255. * 3 => vec3 COLOR_ICONBG_ACTIVE;
@(2, 2, 2) => vec3 COLOR_ICONBG_NONE;
@(.2, .2, .2) => vec3 COLOR_ICON;

// white background
Plane background --> scene;
WIDTH => background.scaX;
HEIGHT => background.scaY;
-90 => background.posZ;
@(1., 1., 1.) * 5 => background.color;

DrawEvent drawEvent;
// polymorphism
Draw @ draws[2];
LineDraw lineDraw(mouse) @=> draws[0];
CircleDraw circleDraw(mouse) @=> draws[1];
for (auto draw : draws) {
    draw --> GG.scene();
}
spork ~ select_drawtool(mouse, draws, drawEvent);

ColorPicker colorPicker(mouse, drawEvent) --> scene;
spork ~ colorPicker.pick();

PlayLine playline --> scene;
spork ~ playline.play();

// simplified Mouse class from examples/input/Mouse.ck  =======================
class Mouse {
    vec2 pos;

    // update mouse world position
    fun void selfUpdate() {
        while (true) {
            GG.nextFrame() => now;
            // calculate mouse world X and Y coords
            GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1.0) => vec3 worldPos;
            worldPos.x => this.pos.x;
            worldPos.y => this.pos.y;
        }
    }
}

// good global functions ======================================================

// returns true if mouse is hovering over a GGen
fun int isHoveredGGen(Mouse @ mouse, GGen @ g) {
    g.scaWorld() => vec3 worldScale;  // get dimensions
    worldScale.x / 2.0 => float halfWidth;
    worldScale.y / 2.0 => float halfHeight;
    g.posWorld() => vec3 pos;   // get position

    if (mouse.pos.x > pos.x - halfWidth && mouse.pos.x < pos.x + halfWidth &&
        mouse.pos.y > pos.y - halfHeight && mouse.pos.y < pos.y + halfHeight) {
        return true;
    }
    return false;
}

// Various object class for painting ==========================================

class Plane extends GGen {
    GPlane g --> this;
    FlatMaterial mat;
    g.mat(mat);

    fun Plane(vec2 pos, float scale, vec3 color, float depth) {
        @(pos.x, pos.y, depth) => g.pos;
        scale => g.sca;
        color => mat.color;
        depth => this.posZ;
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
    }
}

class Line extends GGen {
    GLines g --> this;
    vec2 start, end;

    fun Line(vec2 start, vec2 end, vec3 color, float width, float depth) {
        start => this.start;
        end => this.end;
        width => g.width;
        color => g.color;
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
    }
}

class Circle extends GGen {
    GCircle g --> this;
    FlatMaterial mat;
    g.mat(mat);
    CircleGeometry geo(.5, 96, 0., 2 * Math.pi);
    g.geo(geo);

    vec2 center;
    float r;

    fun Circle(vec2 center, float r, vec3 color, float depth) {
        center => this.center;
        r => this.r;
        center.x => g.posX;
        center.y => g.posY;
        r * 2. => g.sca;
        color => mat.color;
        depth => this.posZ;
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
    }
}

// Toolbar: Drawing tools and color picker =============================================
class ColorPicker extends GGen {
    // color picker
    Plane g --> this;
    [Color.SKYBLUE, Color.BEIGE, Color.MAGENTA, Color.LIGHTGRAY] @=> vec3 presets[];
    int idx;

    Mouse @ mouse;
    DrawEvent @ drawEvent;

    fun ColorPicker(Mouse @ m, DrawEvent @ d) {
        m @=> this.mouse;
        d @=> this.drawEvent;

        TOOLBAR_SIZE => g.sca;
        0 => idx;
        this.color() => g.color;
        this.color() => this.drawEvent.color;
        @(0, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => g.pos;
    }

    fun vec3 color() {
        return presets[idx];
    }

    fun void nextColor() {
        (idx + 1) % presets.size() => idx;
        presets[idx] => g.color;
        this.color() => this.drawEvent.color;
    }

    fun int isHovered() {
        return isHoveredGGen(mouse, g);
    }

    fun void pick() {
        while (true) {
            GG.nextFrame() => now;
            if (GWindow.mouseLeftDown() && this.isHovered()) {
                this.nextColor();
            }
        }
    }
}

class Draw extends GGen {
    0 => static int NONE;  // not clicked
    1 => static int ACTIVE;   // clicked

    Mouse @ mouse;

    Plane icon_bg --> this;

    fun @construct(Mouse @ m) {
        m @=> this.mouse;

        TOOLBAR_SIZE => icon_bg.sca;
        COLOR_ICONBG_NONE => icon_bg.color;
    }

    fun int isHovered() {
        return isHoveredGGen(mouse, icon_bg);
    }

    fun void activate() {
        // change icon_bg color
        COLOR_ICONBG_ACTIVE => this.icon_bg.color;
    }

    fun void test_deactivate_exit_shred(DrawEvent @ drawEvent) {
        // when stop drawing / switch to other drawtools, exit this shred
        if (drawEvent.isNone() || drawEvent.isActive() && drawEvent.draw != this) {
            // <<< "exit..." >>>;
            COLOR_ICONBG_NONE => this.icon_bg.color;
            me.exit();
        }
    }

    // polymorphism placeholder
    fun void draw(DrawEvent @ drawEvent) {
        return;
    }
}

class LineDraw extends Draw {
    GLines icon --> this;
    -0.5 => float icon_offset;

    Line @ lines[1000];
    0 => int length;

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        0.03 => icon.width;
        COLOR_ICON => icon.color;
        [@(icon_offset-(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_PADDING),
            @(icon_offset+(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_SIZE)] => icon.positions;

        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => icon_bg.pos;
    }

    fun void draw(DrawEvent @ drawEvent) {
        // <<< "LineDraw", me.id() >>>;
        vec2 start, end;
        0 => int state; // current state

        this.activate();

        while (true) {
            GG.nextFrame() => now;

            this.test_deactivate_exit_shred(drawEvent);

            if (state == NONE && GWindow.mouseLeftDown()) {
                ACTIVE => state;
                drawEvent.incDepth();
                this.mouse.pos => start;
            } else if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;
                this.mouse.pos => end;

                // generate a new line
                Line line(start, end, drawEvent.color, 0.1, drawEvent.depth) @=> lines[length++];
                lines[length - 1] --> GG.scene();
            }
        }
    }
}


class CircleDraw extends Draw {
    Circle icon --> this;
    0.5 => float icon_offset;

    Circle @ circles[1000];
    0 => int length;

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        COLOR_ICON => icon.color;
        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, 0) => icon.pos;
        TOOLBAR_SIZE - TOOLBAR_PADDING => icon.sca;

        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => icon_bg.pos;
    }

    fun void draw(DrawEvent @ drawEvent) {
        // <<< "CircleDraw", me.id() >>>;
        vec2 center;
        float radius;
        0 => int state;

        this.activate();

        while (true) {
            GG.nextFrame() => now;

            this.test_deactivate_exit_shred(drawEvent);

            if (state == NONE && GWindow.mouseLeftDown()) {
                ACTIVE => state;
                drawEvent.incDepth();
                this.mouse.pos => center;
            }
            if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;
                (this.mouse.pos - center) => vec2 r;
                Math.sqrt(r.x * r.x + r.y * r.y) => float radius;

                // generate a new line
                Circle circle(center, radius, drawEvent.color, drawEvent.depth) @=> circles[length++];
                circles[length - 1]  --> GG.scene();
            }
        }
    }
}

class DrawEvent extends Event {
    0 => static int NONE;  // no drawtool selected
    1 => static int ACTIVE;  // drawtool selected
    0 => int state;
    Draw @ draw;  // reference to the selected drawtool
    vec3 color;  // selected color
    -50 => float depth;  // current depth of the drawed object

    fun int isNone() {
        return state == NONE;
    }

    fun int isActive() {
        return state == ACTIVE;
    }

    fun void setNone() {
        NONE => this.state;
        null @=> draw;
    }

    fun void setActive(Draw @ d) {
        ACTIVE => this.state;
        d @=> draw;
    }

    fun void incDepth() {
        depth + 0.001 => depth;
    }
}

fun void select_drawtool(Mouse @ m, Draw draws[], DrawEvent @ drawEvent) {
    while (true) {
        GG.nextFrame() => now;
        for (auto draw : draws) {
            if (GWindow.mouseLeftDown() && draw.isHovered()) {
                // clicked on this drawtool
                if (drawEvent.isNone() || drawEvent.isActive() && drawEvent.draw != draw) {
                    // was inactive / switch activation
                    <<< "activate" >>>;
                    drawEvent.setActive(draw);
                    drawEvent.broadcast();
                    spork ~ draw.draw(drawEvent);
                } else if (drawEvent.isActive() && drawEvent.draw == draw) {
                    // deactivate
                    <<< "deactivate" >>>;
                    drawEvent.setNone();
                    drawEvent.broadcast();
                }
                break;
            }
        }
    }
}

class PlayLine extends GGen {
    GLines line --> this;
    @(0, 0, 0) => line.color;
    0.01 => line.width;

    // place line
    line.positions([@(LEFT, DOWN), @(LEFT, UP)]);

    fun play() {
        while (true) {
            if (line.posX() > WIDTH) {
                0 => line.posX;
            }

            line.posX() - WIDTH / 2 => float x;

            GG.nextFrame() => now;
            GG.dt() * 2 => float t;
            t => line.translateX;
        }
    }
}


while (true) {
    GG.nextFrame() => now;
}
