//#template raylib
#template console
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

#define NUM_EXPLOSIONS 5.0
#define NUM_PARTICLES 75.0

vec2 Hash12(float t) {
    float x = fract(sin(t*674.3) * 453.2);
    float y = fract(sin((t+x)*714.3) * 263.2);
    return vec2(x,y);
}

vec2 Hash12_Polar(float t) {
    float a = fract(sin(t*674.3) * 453.2) * 6.2832;
    float d = fract(sin((t+a)*714.3) * 263.2);
    return vec2(sin(a), cos(a)) * d;
}

float Explosion(vec2 uv, float t) {
    float sparks = 0.0;
    for (float i=0.0; i<NUM_PARTICLES; i++) {
        vec2 dir = Hash12_Polar((i+1.0)) * 0.5;
        float d = length(uv - dir * t);
        float brightness = mix(0.0005, 0.001, smoothstep(0.05, 0.0, t));
        brightness *= (sin(t*20.0 + i) * 0.5) + 0.5;
        brightness *= smoothstep(1.0, 0.75, t);
        sparks += brightness/d;
    }
    return sparks;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    vec3 col = vec3(0.0);

    for (float i=0.0; i<NUM_EXPLOSIONS; i++) {
        float t = iTime+i/NUM_EXPLOSIONS;
        float ft = floor(t);
        vec3 color = sin(4. * (vec3(.34,.54,.43) * ft)) *.25 +.75;
        vec2 offs = Hash12(i+1.+ft) - 0.5;
        offs *= vec2(1.77,1.);
        //col += 0.001/length(uv-offs);
        col += Explosion(uv - offs, fract(t)) * color;
    }
    col *= 2.0;

	fragColor = vec4(col, 1.0);
}`;

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib shader");
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
f32[2] resolution = [SCREEN_WIDTH, SCREEN_HEIGHT];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.HideCursor();

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_WHITE);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
