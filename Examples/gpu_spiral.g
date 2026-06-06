// This is the GPU version of the spiral demo effect.
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
void main() {
    vec2 center = iResolution.xy * 0.5;
    vec2 delta = center - gl_FragCoord.xy;
    float dist = length(delta);
    float theAngle = atan(delta.y, delta.x) * 3.0;
    //float c = step(0.5, sin(dist*(sin(iTime*0.5)*0.05) + theAngle + iTime*10.0) + 0.5);
    //float c = step(0.5, sin(dist*0.035 + theAngle + iTime*10.0) + 0.5);
    float c = step(0.5, sin(dist*0.007 + theAngle + iTime*10.0) + 0.5);
	fragColor = vec4(1.0, c, c, 1.0);
}`;

raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED | CONFIG_FLAG_WINDOW_MAXIMIZED);
raylib.InitWindow(0, 0, "-");
//raylib.InitWindow(screenWidth, screenHeight, "Raylib shader");
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
