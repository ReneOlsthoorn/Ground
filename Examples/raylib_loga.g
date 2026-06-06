
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
#define TIME        iTime
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))
const float ExpBy = log2(2.24);
float forward(float l) {
  return exp2(ExpBy*l);
}
float reverse(float l) {
  return log2(l)/ExpBy;
}
float modPolar(inout vec2 p, float repetitions) {
  float angle = TAU/repetitions;
  float a = atan(p.y, p.x) + angle/2.;
  float r = length(p);
  float c = floor(a/angle);
  a = mod(a,angle) - angle/2.;
  p = vec2(cos(a), sin(a))*r;
  // For an odd number of repetitions, fix cell index of the cell in -x direction
  // (cell index would be e.g. -5 and 5 in the two halves of the cell):
  if (abs(c) >= (repetitions/2.0)) c = abs(c);
  return c;
}
vec3 effect(vec2 p) {
  float aa = 4.0/RESOLUTION.y;
  float ltm = 0.75*TIME;
  mat2 rot0 = ROT(-0.5*ltm); 
  float mtm = fract(ltm);
  float ntm = floor(ltm);
  float zz = forward(mtm);
  vec2 p0 = p;
  p0 *= rot0;
  p0 /= zz;
  float l0 = length(p0);
  float n0 = ceil(reverse(l0));
  float r0 = forward(n0);
  float r1 = forward(n0-1.0);
  float r = (r0+r1)/2.0;
  float w = r0-r1;
  float nn = n0;
  n0 -= ntm;
  vec2 p1 = p0;
  p1 *= ROT(3.0*n0*TAU/16.0);
  float n1 = modPolar(p1, 8.0);
  p1.x -= r;
  float a = 0.5*ltm+n1/8.0;
  a = fract(a);
  float d1 = length(p1)-0.5*w;
  float d2 = length(p1)-0.5*w*smoothstep(0.0, 0.45, mod(a, 0.5));
  d1 *= zz;
  d2 *= zz;
  vec3 col = vec3(0.2*smoothstep(-sqrt(0.5), sqrt(0.5), sin(0.5*TAU*p.y/aa)));
  vec3 ccol = vec3(1.0)*smoothstep(0.0, -aa, d2);
  if (a >= 0.5) ccol = 1.0-ccol;
  col = mix(col, ccol, smoothstep(0.0, -aa, d1));
  col = sqrt(col);
  return col;
}
void main() {
  vec2 fragCoord = gl_FragCoord.xy;
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p);
  fragColor = vec4(col, 1.0);
}`;


raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);
raylib.InitWindow(0, 0, "-");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
f32[2] resolution = [screenWidth, screenHeight];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.HideCursor();

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, COLOR_WHITE);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
