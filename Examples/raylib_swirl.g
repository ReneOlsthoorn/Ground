
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

float factor = 1.0;
vec3 color = vec3(0.2, 0.5, 1.0);

vec4 t(vec2 uv)
{
    float j = sin(uv.y * 3.14 + iTime * 5.0);
    float i = sin(uv.x * 15.0 - uv.y * 2.0 * 3.14 + iTime * 3.0);
    float n = -clamp(i, -0.2, 0.0) - 0.0 * clamp(j, -0.2, 0.0);
    
    return 3.5 * (vec4(color, 1.0) * n);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    vec2 uv;
    
    float r = sqrt(dot(p, p));
    float a = atan(
        p.y * (0.3 + 0.1 * cos(iTime * 2.0 + p.y)),
        p.x * (0.3 + 0.1 * sin(iTime + p.x))
    ) + iTime;
    
    uv.x = iTime + 1.0 / (r + .01);
    uv.y = 4.0 * a / 3.1416;
    
    fragColor = mix(vec4(0.0), t(uv) * r * r * 2.0, factor);
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
