# version 300 es        // NEWER VERSION OF GLSL
precision highp float; // HIGH PRECISION FLOATS

uniform float uTime;   // TIME, IN SECONDS
in vec3 vPos;          // POSITION IN IMAGE
out vec4 fragColor;    // RESULT WILL GO HERE

const int NS = 3; // Number of spheres in the scene
const int NL = 2; // Number of light sources in the scene
const float eps = 1.0e-7;
const vec3 eye = vec3(0.0, 0.0, 5.);
const vec3 screen_center = vec3(0.0, 0.0, 2.5);

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
    vec3 src;
};

Sphere spheres[NS];
Light lights[NL];

Ray get_ray(vec3 p_src, vec3 p_dest) {
    Ray ret;
    ret.src = p_src;
    ret.dir = normalize(p_dest - p_src);
    return ret;
}

// Setting the parameters of spheres and lights
void init() {
    // x, y: -2 ~ 2, z: 0~4
    spheres[0].center = vec3(1., 1., -1.);
    spheres[0].rgb = vec3(0., 0.75, 0.5);
    spheres[0].r = 0.6;

    spheres[1].center = vec3(-1., 1.2, -0.4);
    spheres[1].rgb = vec3(0.7098, 0.7451, 0.2);
    spheres[1].r = 0.7;


    spheres[2].center = vec3(0., -0.2, -1.);
    spheres[2].rgb = vec3(0.498, 0.2471, 0.3725);
    spheres[2].r = 1.0;


    lights[0].rgb = vec3(1., 1., 1.);
    lights[0].src = vec3(0., 2., -2.1);
    lights[1].rgb = vec3(1., 1., 1.);
    lights[1].src = vec3(0., 2., -1.9);
}

vec3 get_normal(Sphere s, vec3 pos) {
    return normalize(pos - s.center);
}

float intersect(Ray r, Sphere s) {
    float t;
    // d = direction of ray, s = source of ray, c = center of sphere
    vec3 c_s = s.center - r.src;
    float dc_s = dot(r.dir, c_s);
    float d2 = dot(r.dir, r.dir); // should be 1
    float r2 = s.r*s.r;
    float delta = pow(dc_s, 2.) - d2*(dot(c_s, c_s) - r2);
    if (delta < -1.*eps) {
        // no intersect
        return -1.;
    } 
    else if (delta > eps) {
        // two intersect
        float t1 = (dc_s - sqrt(delta)) / d2;
        float t2 = (dc_s + sqrt(delta)) / d2;
        if (t1 > 0.) {
            return t1;
        }
        else {  // maybe inside the sphere
            return t2;
        }
    }
    else {
        // one intersect
        t = dc_s / d2;
        return t;
    }  
}

Ray reflect_ray(Ray rin, vec3 norm) {
    Ray ret;
    ret.src = rin.src;
    ret.dir = normalize(2.*dot(norm, rin.dir)*norm - rin.dir);
    return ret;
}


bool is_in_shadow(vec3 pos, vec3 norm) {
    pos = pos + 0.0001 * norm;
    bool ret = false;
    for (int i = 0; i < NL; i++) {
        Ray ray_l = get_ray(pos, lights[i].src);
        for (int j = 0; j < NS; j++) {
            if (intersect(ray_l, spheres[j]) > 0.) {
                return true;
            }
        }
    }
    return ret;
}

vec3 ray_tracing() {
    Ray ray = get_ray(eye, screen_center+vec3(vPos.xy, 0));
    vec3 color = vec3(0., 0., 0.);
    for (int i = 0; i < NS; i++) {
        float t = intersect(ray, spheres[i]);
        if (t > 0.) {
            color += spheres[i].rgb;
        }
        else {
            
        }
    }
    return color;
}

void main() {
    init();
    vec3 color = ray_tracing();
    fragColor = vec4(color, 1.0);
}
