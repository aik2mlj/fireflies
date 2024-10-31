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
// 0. => light.intensity;

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

// white background
GPlane background --> scene;
WIDTH => background.scaX;
HEIGHT => background.scaY;
-10 => background.posZ;
@(1., 1., 1.) * 5 => background.color;

DrawEvent drawEvent;
spork ~ select_drawtool(mouse, drawEvent);

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
class Line extends GGen {
    GLines g --> this;

    fun Line(vec2 start, vec2 end, vec3 color, float width) {
        width => g.width;
        color => g.color;
        g.positions([start, end]);
    }

    fun void updatePos(vec2 start, vec2 end) {
        g.positions([start, end]);
    }
}

class Circle extends GGen {
    GCircle g --> this;

    fun Circle(vec2 center, float r, vec3 color) {
        center.x => g.posX;
        center.y => g.posY;
        r * 2. => g.sca;
        color => g.color;
    }
}

// Toolbar: Drawing tools and color picker =============================================
class ColorPicker extends GGen {
    // color picker
    GPlane g --> this;
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

    GPlane icon_bg --> this;

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

    fun void test_deactivate_exit_shred() {
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

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        0.03 => icon.width;
        @(.2, .2, .2) => icon.color;
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

            this.test_deactivate_exit_shred();

            if (state == NONE && GWindow.mouseLeftDown()) {
                ACTIVE => state;
                this.mouse.pos => start;
            } else if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;
                this.mouse.pos => end;

                // generate a new line
                Line line(start, end, drawEvent.color, 0.1) --> GG.scene();
            }
        }
    }
}


class CircleDraw extends Draw {
    GCircle icon --> this;
    0.5 => float icon_offset;

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        @(.4, .4, .4) => icon.color;
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

            this.test_deactivate_exit_shred();

            if (state == NONE && GWindow.mouseLeftDown()) {
                ACTIVE => state;
                this.mouse.pos => center;
            }
            if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;
                (this.mouse.pos - center) => vec2 r;
                Math.sqrt(r.x * r.x + r.y * r.y) => float radius;

                // generate a new line
                Circle circle(center, radius, drawEvent.color) --> GG.scene();
            }
        }
    }
}

class DrawEvent extends Event {
    0 => static int NONE;  // no drawtool selected
    1 => static int ACTIVE;  // drawtool selected
    0 => int state;
    Draw @ draw;  // reference to the selected drawtool
    vec3 color;

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
}

fun void select_drawtool(Mouse @ m, DrawEvent @ drawEvent) {
    // polymorphism
    Draw @ draws[2];
    new LineDraw(m) @=> draws[0];
    new CircleDraw(m) @=> draws[1];
    for (auto draw : draws) {
        draw --> GG.scene();
    }
    <<< me.id() >>>;

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
            GG.nextFrame() => now;
            GG.dt() * 0.5 => float t;
            t => line.translateX;
        }
    }
}


// Line line(@(-3.3,3), @(1,0), Color.YELLOW, 0.3) --> GG.scene();

while (true) {
    GG.nextFrame() => now;
}
