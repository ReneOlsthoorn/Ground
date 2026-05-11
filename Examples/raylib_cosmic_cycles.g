
#template raylib
#include graphics_defines1280x720.g
#library raylib raylib.dll

byte* vsCode = `#version 330
in vec3 vertexPosition;
uniform mat4 mvp;
void main() { gl_Position = mvp * vec4(vertexPosition, 1.0); }`;

byte* fsCode = `#version 330
out vec4 fragColor;
uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iMouse;
vec2 fragCoord = gl_FragCoord.xy;
#define BURST
#define NUM_LAYERS 5.

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c,-s,s,c);
}

float Star(vec2 uv, float a, float sparkle) {
    vec2 av1 = abs(uv);
 	vec2 av2 = abs(uv*Rot(a));
    vec2 av = min(av1, av2);
    
    vec3 col = vec3(0);
    float d = length(uv);
    float star = av1.x*av1.y;
    star = max(av1.x*av1.y, av2.x*av2.y);
    star = max(0., 1.-star*1e3);
    
    float m = min(5., 1e-2/d);
    
    return m+pow(star, 4.)*sparkle;
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,145.54));
    p += dot(p, p+45.23);
    return fract(p.x*p.y);
}

vec3 StarLayer(vec2 uv, float t, float sparkle) {
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
	vec3 col = vec3(0);
    
    #ifndef BURST
    t = 0.;
    #endif
    
    for(int y=-1; y<=1; y++) {
        for(int x=-1; x<=1; x++) {
            vec2 offs = vec2(x, y);
            float n = Hash21(id-offs);
			vec3 N = fract(n*vec3(10,100,1000));
            vec2 p = (N.xy-.5)*.7;
            
            float brightness = Star(gv-p+offs, n*6.2831+t, sparkle);
            vec3 star = brightness*vec3(.6+p.x, .4, .6+p.y)*N.z*N.z;
            
            
            
            star *= 1.+sin((t+n)*20.)*smoothstep(sin(t)*.5+.5, 1., fract(10.*n));
            
            float d = length(gv+offs);
            
            col += star*smoothstep(1.5, .8, d);
        }
    }
    return col;
}

void main()
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 M = iMouse.xy/iResolution.xy;
    
    M *= 10.;
    
	float t = -iTime*.3;
	
    float twirl = sin(t*.1);
    twirl *= twirl*twirl*sin(dot(uv,uv));
    uv *= Rot(-t*.2);
    
    uv *= 2.+sin(t*.05);
    
    vec3 col = vec3(0);
    float speed = -.2;
    #ifdef BURST
    speed = .1;
    float bla = sin(t+sin(t+sin(t)*.5))*.5+.5;
    float d = dot(uv,uv);
    
    float a = atan(uv.x, uv.y);
    uv /= d;
    float burst = sin(iTime*.05);
    uv *= burst+.2;
    #endif
    
    float stp = 1./NUM_LAYERS;
        
    for(float i=0.; i<1.; i+=stp) {
    	float lt = fract(t*speed+i);
        float scale = mix(10., .25, lt);
        float fade = smoothstep(0., .4, lt)*smoothstep(1., .95, lt); 
        vec2 sv = uv*scale+i*134.53-M;
        //sv.x += t;
        col += StarLayer(sv, t, fade)*fade;
    }
    
    #ifdef BURST
    //t = iTime*.5;
    float burstFade = smoothstep(0., .02, abs(burst));
    float size = .9*sin(t)+1.;
    size = max(size, sqrt(size));
    float fade = size/d;
    col *= mix(1., fade, burstFade);
    col += fade*.2*vec3(1., .5, .1)*bla*burstFade;
    
    t*=1.5;
    
    a -= M.x*.1;
    float rays = sin(a*5.+t*3.)-cos(a*7.-t);
    rays *= sin(a+t+sin(a*4.)*10.)*.5+.5;
    col += rays*bla*.1*burstFade;
    col += 1.-burstFade;
    #else
    col *= 4.;
    #endif
    
    fragColor = vec4(col,1.0);
}`;

raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);
raylib.InitWindow(0, 0, "-");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int mouseLocation = raylib.GetShaderLocation(shader, "iMouse");
f32[2] resolution = [screenWidth, screenHeight];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.SetTargetFPS(60);
raylib.HideCursor();

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    ptr mouse = raylib.GetMousePosition();
    raylib.SetShaderValue(shader, mouseLocation, &mouse, SHADER_UNIFORM_VEC2);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, 0xffffffff);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
