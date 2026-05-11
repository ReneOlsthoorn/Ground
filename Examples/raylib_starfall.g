
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
void main()
{	
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / iResolution.y;
    vec4 tmpFrag = vec4(0.0, 0.0, 0.0, 1.0);
    for (float i = 0.1; i < 0.9; i += 0.04)
    {
        vec3 p = vec3(uv.xy + (iTime/i - i) / vec2(30,10), i);
        p = abs(1.0 - mod(p, vec3(2.0)));
        float a = length(p), b, c = 0.0;
        for (float j = 0.1; j < 0.9; j += 0.04) {
          p = ((abs(p) / a) / a) - 0.57;
          b = length(p);
          c = c + abs(a - b);
          a = b;
        }
        c = c * c;
        tmpFrag += c * vec4(i, 1, 2, 0) / 30000.0;
    }
    fragColor = tmpFrag;
}`;

raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);
raylib.InitWindow(0, 0, "-");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);

bool isOK = raylib.IsShaderValid(shader);
if (!isOK)
    return;

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
