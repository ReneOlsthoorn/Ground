
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
vec2 fragCoord = gl_FragCoord.xy;

float A = 3.0, B = 2.0; // Rotation angle is atan(B,A)
//float K = 1.0;          // Extra subdivisions, should be >= 1.0
float scale = 1.5;
float PI = 3.14159;

// Complex functions
vec2 cmul(vec2 z, vec2 w) {
  return mat2(z,-z.y,z.x)*w;
}

vec2 cinv(vec2 z) {
  float t = dot(z,z);
  return vec2(z.x,-z.y)/t;
}

vec2 cdiv(vec2 z, vec2 w) {
  return cmul(z,cinv(w));
}

vec2 clog(vec2 z) {
  float r = length(z);
  return vec2(log(r),atan(z.y,z.x));
}

// Inverse hyperbolic tangent 
vec2 catanh(vec2 z) {
  return 0.5*clog(cdiv(vec2(1,0)+z,vec2(1,0)-z));
}

// Iq's hsv function, but just for hue.
vec3 h2rgb(float h ) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  return rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	
}

void main() {
  float X = sqrt(3.0);
  vec2 z = (2.0*fragCoord-iResolution.xy)/iResolution.y;
  z *= scale;

  //if (iMouse.x > 0.0) {
    // Get angle from mouse position
  //  vec2 m = (2.0*iMouse.xy-iResolution.xy)/iResolution.y;
  //  m *= 20.0;
  //  A = floor(m.x), B = floor(m.y);
  //}
  vec2 rot = vec2(X*A,B);
  //z = clog(z);
  z = 2.0*catanh(z)/PI;
  float eps = length(rot)*fwidth(z.x);
  z = cmul(rot,z);

  z.y /= X;
  z += iTime*vec2(0,1);
  vec2 index = round(z);
  z -= index;
  z.y *= X;

  if (mod(index.x + index.y, 2.0) == 0.0) z.x = -z.x;

  float hx = index.x/(B==0.0 ? 1.0 : B); // Color for column
  float hy = index.y/(A==0.0 ? 1.0 : A); // Color for row
  vec3 col = 0.2+0.8*h2rgb(0.5*hy);
  vec2 P = vec2(1,X);
  float r = min(distance(-0.5*P,z),distance(0.5*P,z));
  col = mix(col,vec3(0),smoothstep(-eps,eps,r-0.95));
  col = mix(col,vec3(1,0,0),smoothstep(-eps,+eps,r-1.0));
  z = 0.5*P-abs(z);
  col *= smoothstep(-eps,eps,min(z.x,z.y)-0.05);
  col = pow(col,vec3(0.4545));
  fragColor = vec4(col,1);
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
raylib.SetTargetFPS(60);
raylib.HideCursor();

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, 0xffffffff);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
