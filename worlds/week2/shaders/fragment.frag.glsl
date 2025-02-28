# version 300 es        // NEWER VERSION OF GLSL
precision highp float; // HIGH PRECISION FLOATS

uniform float uTime;   // TIME, IN SECONDS
in vec3 vPos;          // POSITION IN IMAGE
out vec4 fragColor;    // RESULT WILL GO HERE

const int NS = 2; // Number of spheres in the scene
const int NL = 2; // Number of light sources in the scene
const float eps = 1.0e-7;
const vec3 eye = vec3(0.0, 0.0, 5.);
const vec3 screen_center = vec3(0.0, 0.0, 2.5);


struct Sphere {
    vec3 center;
    float r;
    vec3 ambiance;
    vec3 diffuse;
    vec4 specular;
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
    spheres[0].center = vec3(0.5, 0.5, -1.0);
    spheres[0].r = 0.6;
    spheres[0].ambiance  = vec3(0.,.1,.1);
    spheres[0].diffuse  = vec3(0.,.5,.5);
    spheres[0].specular = vec4(0.,1.,1.,10.); // 4th value is specular power

    spheres[1].center = vec3(-0.5, 1.2, -0.4);
    spheres[1].r = 0.7;
    spheres[1].ambiance  = vec3(.1,.1,0.);
    spheres[1].diffuse  = vec3(.5,.5,0.);
    spheres[1].specular = vec4(1.,1.,1.,20.);


    lights[0].rgb = vec3(1., 1., 1.);
    lights[0].src = vec3(0., 2.*cos(uTime), -0.5);
    lights[1].rgb = vec3(1., 1., 1.);
    lights[1].src = vec3(-1.*sin(1.*uTime), 0., -2.*sin(uTime));
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
    if (delta < 0.) {
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
            return -1.;
        }
    }
    else {
        // one intersect
        t = dc_s / d2;
        return t;
    }  
}

bool hidden_by_sphere(Light l){
    Ray ray=get_ray(eye,l.src);
    for(int i=0;i<NS;i++){
        if(dot(l.src-spheres[i].center,l.src-spheres[i].center)<pow(spheres[i].r,2.)){
            return true;
        }
        
        float t=intersect(ray,spheres[i]);
        if(t > 0. && t < length(l.src-eye)){
            return true;
        }
        
    }
    return false;
}

Ray reflect_ray(Ray rin, vec3 norm) {
    Ray ret;
    ret.src = rin.src;
    ret.dir = normalize(2.*dot(norm, rin.dir)*norm - rin.dir);
    return ret;
}


bool is_in_shadow(vec3 pos, vec3 norm, Light light) {

    pos = pos + 0.0001 * norm;
    bool ret = false;
    Ray ray_l = get_ray(pos, light.src);
    for (int j = 0; j < NS; j++) {
        if (intersect(ray_l, spheres[j]) > 0.00001) {
            return true;
        }
    }
    return ret;
}

vec3 ray_tracing() {
    vec3 color = vec3(0., 0., 0.);
    Ray ray = get_ray(eye, screen_center+vec3(vPos.xy, 0));
    for (int i = 0; i < NL; i++) {
        // show lights
        if(dot(normalize(lights[i].src - ray.src), ray.dir) > 0.99999) {
            if(hidden_by_sphere(lights[i])) continue;
            color = lights[i].rgb;
            return color;
        }
    } 
    
    float t_min = 10000.;
    int index = -1;

    for (int i = 0; i < NS; i++) {
        float t = intersect(ray, spheres[i]);
        if (t > 0.) {            
            if (t < t_min) {
                t_min = t;
                index = i;
            }
        }
    }
    if(index > -1) {
        vec3 inter_point = ray.src + t_min*ray.dir;
        vec3 N = get_normal(spheres[index], inter_point);
        color = spheres[index].ambiance;
        for (int j = 0; j < NL; j++) {
            if(!is_in_shadow(inter_point, N, lights[j])) {
                Ray L = get_ray(inter_point, lights[j].src);
                Ray E = get_ray(inter_point, eye);
                Ray R = reflect_ray(L, N);
                color += lights[j].rgb * (spheres[index].diffuse * max(0., dot(N, L.dir)));
                // That is where the bug is.
                // Something in Pow. If specular >= 10., it will overflow.
                // float s = max(0., pow(dot(E.dir, R.dir), spheres[index].specular[3]) );
                float s;
                float er = dot(E.dir, R.dir);
                if (er > 0.) {
                    s = max(0., exp(spheres[index].specular[3] * log(er) ) );
                }
                else {
                    s = 0.;
                }
                color += lights[j].rgb * spheres[index].specular.xyz * s ;
            }
        }
    }

    return color;
}

void main() {
    init();
    vec3 color = ray_tracing();
    fragColor = vec4(color, 1.0);
}
