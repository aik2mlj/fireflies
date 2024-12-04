// bloom intensity
0.9 => float BLOOM_INTENSITY;

// camera
GFlyCamera cam --> GG.scene();
cam.posZ(8.0);
cam.lookAt(@(0, 0, 0));
GG.scene().camera(cam);

// GWindow.fullscreen();

// remove light
GG.scene().light() @=> GLight light;
0. => light.intensity;

// global blooming effect
GG.outputPass() @=> OutputPass output_pass;
GG.renderPass() --> BloomPass bloom_pass --> output_pass;
bloom_pass.intensity(BLOOM_INTENSITY);
bloom_pass.input(GG.renderPass().colorOutput());
output_pass.input(bloom_pass.colorOutput());

300 => int STAR_NUM;
// @(255, 230, 109) / 255.0 => vec3 STAR_COLOR;
SphereGeometry sphere_geo_many(0.02, 32, 16, 0., 2 * Math.pi, 0., Math.pi);
FlatMaterial mat_many[STAR_NUM];
float init_time[STAR_NUM];   // the initial time offset for each firefly
float fade_freq[STAR_NUM];   // fade in/out frequency of each firefly
float intensities[STAR_NUM]; // randomized brightness of each firefly
for (int i; i < STAR_NUM; i++) {
    Math.random2f(0.1, 3.) => fade_freq[i];
    Math.random2f(0., 2.) => init_time[i];
    Math.random2f(0.1, 0.5) => intensities[i];
}
for (auto x : mat_many) {
    x.color(@(Math.random2f(150, 255), Math.random2f(150, 255), Math.random2f(150, 255)) / 255 * Math.random2f(1., 10.));
}

GMesh stars[STAR_NUM];
-50 => float minX => float minY;
-50 => float minZ;
50 => float maxX => float maxZ;
50 => float maxY;
for (int i; i < STAR_NUM; i++) {
    GMesh sphere(sphere_geo_many, mat_many[i]) @=> stars[i];
    stars[i] --> GG.scene();
    @(Math.random2f(minX, maxX), Math.random2f(minY, maxY), Math.random2f(minZ, maxZ)) => stars[i].translate;
}

// blackhole
// GSphere hole --> GG.scene();
// SphereGeometry geo(1., 96, 96, 0., 2 * Math.pi, 0., Math.pi);
// hole.geo(geo);
// hole.mat().topology(Material.Topology_LineList);

GTorus torus --> GG.scene();
FlatMaterial torus_mat;
TorusGeometry torus_geo(1, 0.07, 96, 96, 2*Math.pi);
torus.geo(torus_geo);
torus.mat(torus_mat);
@(239, 61, 27)/255 * 5 => torus_mat.color;
GTorus torus_2 --> GG.scene();
TorusGeometry torus_geo_2(1.4, 0.4, 96, 96, 2*Math.pi);
torus_2.geo(torus_geo_2);
torus_2.mat(torus_mat);
Math.pi / 2 => torus_2.rotX;
0.2=> torus_2.scaZ;

while (true) {
    GG.nextFrame() => now;
}
