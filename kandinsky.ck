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

16.0 / 9.0 => float ASPECT;
cam.viewSize() => float HEIGHT;
cam.viewSize() * ASPECT => float WIDTH;
-WIDTH / 2 => float LEFT;
WIDTH / 2 => float RIGHT;
-HEIGHT / 2 => float DOWN;
HEIGHT / 2 => float UP;
0.4 => float TOOLBAR_SIZE;
0.1 => float TOOLBAR_PADDING;


// white background
GPlane background --> scene;
WIDTH => background.scaX;
HEIGHT => background.scaY;
-10 => background.posZ;
@(1., 1., 1.) * 5 => background.color;

LineDraw linedraw(mouse);
// spork ~ linedraw.draw();
CircleDraw circledraw(mouse);

PlayLine playline --> scene;
spork ~ playline.play();

// simplified Mouse class from examples/input/Mouse.ck  =======================
class Mouse {
    vec3 worldPos;

    // update mouse world position
    fun void selfUpdate() {
        while (true) {
            GG.nextFrame() => now;
            // calculate mouse world X and Y coords
            GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1.0) => worldPos;
        }
    }
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
        r => g.sca;
        color => g.color;
    }
}

class Draw {
    0 => static int NONE;  // not clicked
    1 => static int ACTIVE;   // clicked

    Mouse @ mouse;

    GPlane icon_bg --> GG.scene();

    fun @construct(Mouse @ m) {
        m @=> this.mouse;

        TOOLBAR_SIZE => icon_bg.sca;
        @(2, 2, 2) => icon_bg.color;
    }

    // polymorphism placeholder
    fun void draw() {
        return;
    }
}

class LineDraw extends Draw {
    GLines icon --> GG.scene();
    -0.25 => float icon_offset;

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        0.03 => icon.width;
        @(.2, .2, .2) => icon.color;
        [@(icon_offset-(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_PADDING),
            @(icon_offset+(TOOLBAR_SIZE-TOOLBAR_PADDING)/2, DOWN+TOOLBAR_SIZE)] => icon.positions;

        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => icon_bg.pos;
    }

    fun void draw() {
        vec2 start, end;
        0 => int state; // current state
        while (true) {
            GG.nextFrame() => now;
            if (state == NONE) {
                if (GWindow.mouseLeftDown()) {
                    ACTIVE => state;
                    this.mouse.worldPos.x => start.x;
                    this.mouse.worldPos.y => start.y;
                }
            }
            if (state == ACTIVE) {
                if (GWindow.mouseLeftUp()) {
                    NONE => state;
                    this.mouse.worldPos.x => end.x;
                    this.mouse.worldPos.y => end.y;

                    // generate a new line
                    Line line(start, end, Color.YELLOW, 0.1) --> GG.scene();
                }
            }
        }
    }
}


class CircleDraw extends Draw {
    GCircle icon --> GG.scene();
    0.25 => float icon_offset;

    fun @construct(Mouse @ mouse) {
        Draw(mouse);

        @(.4, .4, .4) => icon.color;
        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, 0) => icon.pos;
        TOOLBAR_SIZE - TOOLBAR_PADDING => icon.sca;

        @(icon_offset, DOWN+(TOOLBAR_PADDING+TOOLBAR_SIZE)/2, -1) => icon_bg.pos;
    }

    fun void draw() {

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
