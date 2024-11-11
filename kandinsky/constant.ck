public class C {
    16.0 / 9.0 => static float ASPECT;
    6.6 => static float HEIGHT;
    HEIGHT * ASPECT => static float WIDTH;
    -WIDTH / 2 => static float LEFT;
    WIDTH / 2 => static float RIGHT;
    -HEIGHT / 2 => static float DOWN;
    HEIGHT / 2 => static float UP;

    // playback speed
    2 => static float SPEED;

    // toolbar
    0.4 => static float TOOLBAR_SIZE;
    0.1 => static float TOOLBAR_PADDING;

    // color
    @(242., 169., 143.) / 255. * 3 => static vec3 COLOR_ICONBG_ACTIVE;
    @(2, 2, 2) => static vec3 COLOR_ICONBG_NONE;
    @(.2, .2, .2) => static vec3 COLOR_ICON;
}

<<< C.SPEED >>>;
C con;
<<< C.SPEED >>>;
// <<< con.HEIGHT >>>;
