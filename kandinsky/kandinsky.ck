//-----------------------------------------------------------------------------
// name: kandinsky.ck
// desc: abstract painting sonified
//
// author: Lejun Min  (https://aik2.site)
// date: Fall 2024
//-----------------------------------------------------------------------------
@import "ChuGL.chug"
@import "shapes.ck"

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
TPlane background --> scene;
WIDTH => background.scaX;
HEIGHT => background.scaY;
-90 => background.posZ;
@(1., 1., 1.) * 5 => background.color;

DrawEvent drawEvent;
// polymorphism
Draw @ draws[3];
LineDraw lineDraw(mouse) @=> draws[0];
CircleDraw circleDraw(mouse) @=> draws[1];
Eraser eraser(mouse) @=> draws[2];
for (auto draw : draws) {
    draw --> GG.scene();
    spork ~ draw.draw(drawEvent);
}
spork ~ select_drawtool(mouse, draws, drawEvent);

ColorPicker colorPicker(mouse, drawEvent) --> scene;
spork ~ colorPicker.pick();

PlayLine playline --> scene;
spork ~ playline.play(drawEvent);

// good global functions ======================================================

// returns true if mouse is hovering over a GGen
fun int isHoveredGGen(Mouse @ mouse, GGen @ g) {
    g.scaWorld() => vec3 worldScale;  // get dimensions
    worldScale.x / 2.0 => float halfWidth;
    worldScale.y / 2.0 => float halfHeight;
    g.posWorld() => vec3 pos;   // get position

    return (mouse.pos.x > pos.x - halfWidth && mouse.pos.x < pos.x + halfWidth &&
            mouse.pos.y > pos.y - halfHeight && mouse.pos.y < pos.y + halfHeight);
}

// Toolbar: Drawing tools and color picker =============================================

class TPlane extends GGen {
    // a convenient plane class for toolbar setup
    GPlane g --> this;
    FlatMaterial mat;
    g.mat(mat);

    fun TPlane(vec2 pos, float scale, vec3 color, float depth) {
        @(pos.x, pos.y, depth) => this.pos;
        scale => this.sca;
        color => mat.color;
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
    }
}

class ColorPicker extends GGen {
    // color picker
    TPlane g --> this;
    vec3 color;
    // [Color.SKYBLUE, Color.BEIGE, Color.MAGENTA, Color.LIGHTGRAY] @=> vec3 presets[];
    // int idx;

    Mouse @ mouse;
    DrawEvent @ drawEvent;

    fun ColorPicker(Mouse @ m, DrawEvent @ d) {
        m @=> this.mouse;
        d @=> this.drawEvent;

        TOOLBAR_SIZE => g.sca;
        @(0, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => g.pos;
        nextColor();
    }

    fun void nextColor() {
        // (idx + 1) % presets.size() => idx;
        // presets[idx] => g.color;
        @(Math.random2f(0, 360), Math.random2f(0, 1), Math.random2f(0, 1)) => vec3 hsv;
        Color.hsv2rgb(hsv) => color;
        color => g.color;
        color => this.drawEvent.color;
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
    0 => int state;

    Mouse @ mouse;

    TPlane icon_bg --> this;

    fun @construct(Mouse @ m) {
        m @=> this.mouse;

        TOOLBAR_SIZE => icon_bg.sca;
        COLOR_ICONBG_NONE => icon_bg.color;
    }

    fun int isHovered() {
        return isHoveredGGen(mouse, icon_bg);
    }

    fun int isHoveredToolbar() {
        // if the mouse is hovered on toolbar
        return mouse.pos.y < DOWN + TOOLBAR_SIZE + TOOLBAR_PADDING;
    }

    fun void waitActivate() {
        // block if not activated
        while (drawEvent.isNone() || drawEvent.isActive() && drawEvent.draw != this) {
            GG.nextFrame() => now;
            COLOR_ICONBG_NONE => this.icon_bg.color;
            NONE => state;
        }
        // activated, change icon_bg color
        COLOR_ICONBG_ACTIVE => this.icon_bg.color;
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
        COLOR_ICON => icon.color;
        [@(icon_offset-(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_PADDING),
            @(icon_offset+(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_SIZE)] => icon.positions;

        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => icon_bg.pos;
    }

    fun void draw(DrawEvent @ drawEvent) {
        vec2 start, end;

        while (true) {
            GG.nextFrame() => now;

            this.waitActivate();

            if (state == NONE && GWindow.mouseLeftDown() && !isHoveredToolbar()) {
                ACTIVE => state;
                drawEvent.incDepth();
                this.mouse.pos => start;
            } else if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;
                this.mouse.pos => end;

                // generate a new line
                Line line(start, end, drawEvent.color, 0.1, drawEvent.depth) @=> drawEvent.shapes[drawEvent.length++];
                drawEvent.shapes[drawEvent.length - 1] --> GG.scene();
                <<< "line", drawEvent.length >>>;
            }
        }
    }
}


class CircleDraw extends Draw {
    Circle icon --> this;
    0.5 => float icon_offset;

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

        while (true) {
            GG.nextFrame() => now;

            this.waitActivate();

            if (state == NONE && GWindow.mouseLeftDown() && !isHoveredToolbar()) {
                ACTIVE => state;
                drawEvent.incDepth();
                this.mouse.pos => center;
            }
            if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;
                (this.mouse.pos - center) => vec2 r;
                Math.sqrt(r.x * r.x + r.y * r.y) => float radius;

                // generate a new line
                Circle circle(center, radius, drawEvent.color, drawEvent.depth) @=> drawEvent.shapes[drawEvent.length++];
                drawEvent.shapes[drawEvent.length - 1]  --> GG.scene();
                <<< "circle", drawEvent.length >>>;
            }
        }
    }
}

class Eraser extends Draw {
    GLines icon_0 --> this;
    GLines icon_1 --> this;
    1 => float icon_offset;

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        0.08 => icon_0.width;
        0.08 => icon_1.width;
        COLOR_ICON => icon_0.color;
        COLOR_ICON => icon_1.color;
        [@(icon_offset-(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_PADDING),
            @(icon_offset+(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_SIZE)] => icon_0.positions;
        [@(icon_offset-(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_SIZE),
            @(icon_offset+(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_PADDING)] => icon_1.positions;

        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => icon_bg.pos;
    }

    fun void draw(DrawEvent @ drawEvent) {
        vec2 pos;
        while (true) {
            GG.nextFrame() => now;

            this.waitActivate();

            if (state == NONE && GWindow.mouseLeftDown() && !isHoveredToolbar()) {
                ACTIVE => state;
                this.mouse.pos => pos;
            } else if (state == ACTIVE && GWindow.mouseLeftUp()) {
                NONE => state;

                for (drawEvent.length - 1 => int i; i >= 0; --i) {
                    if (drawEvent.shapes[i].isHovered(mouse)) {
                        // detached from scene
                        drawEvent.shapes[i] --< GG.scene();
                        // stop playing
                        drawEvent.shapes[i].stop();
                        // move forward
                        for (i => int j; j < drawEvent.length - 1; ++j) {
                            drawEvent.shapes[j + 1] @=> drawEvent.shapes[j];
                        }
                        // decrease length
                        drawEvent.length--;
                        // just erase one shape
                        break;
                    }
                }
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

    // all the drawed shapes
    Shape @ shapes[1000];
    0 => int length;

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

    fun int touchX(float x) {
        false => int touched;
        for (int i; i < length; ++i) {
            shapes[i].touchX(x) => int tmp;
            touched || tmp => touched;
        }
        return touched;
    }

    fun int touchY(float y) {
        false => int touched;
        for (int i; i < length; ++i) {
            shapes[i].touchY(y) => int tmp;
            touched || tmp => touched;
        }
        return touched;
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
                    // drawEvent.broadcast();
                } else if (drawEvent.isActive() && drawEvent.draw == draw) {
                    // deactivate
                    <<< "deactivate" >>>;
                    drawEvent.setNone();
                    // drawEvent.broadcast();
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

    fun play(DrawEvent @ drawEvent) {
        while (true) {
            GG.nextFrame() => now;
            GG.dt() * 2 => float t;
            t => line.translateX;

            if (line.posX() > WIDTH) {
                0 => line.posX;
            }

            line.posX() - WIDTH / 2 => float x;

            drawEvent.touchX(x);
        }
    }
}


while (true) {
    GG.nextFrame() => now;
}
