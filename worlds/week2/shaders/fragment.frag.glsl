#version 300 es        // NEWER VERSION OF GLSL
precision highp float; // HIGH PRECISION FLOATS

uniform float uTime;   // TIME, IN SECONDS
in vec3 vPos;          // POSITION IN IMAGE
out vec4 fragColor;    // RESULT WILL GO HERE

const int NS = 3; // Number of spheres in the scene
const int NL = 2; // Number of light sources in the scene

struct Sphere {
    vec3 center;
    vec3 rgb;
    float r;
};

struct Ray {
    vec3 src;
    vec3 dir;
};

struct Light {
    vec3 rgb;
};

bool is_in_shadow(vec3 pos) {
    ret = false;
    return ret;
}

Ray ref_ray(Ray r) {

}

void main() {
    vec3 color = cos(100. * vPos);
    fragColor = vec4(sqrt(color), 1.0);
}
