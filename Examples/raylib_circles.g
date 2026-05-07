
// This is the GPU version of the circles demo effect.

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
void main() {
    vec2 coord = fragCoord.xy;
    vec2 center = iResolution.xy * 0.5;
    vec2 delta = center - coord;
    float dist = length(delta);
    float theAngle = atan(delta.y, delta.x);
    float c = sin(dist*0.25 + iTime*5.0) + sin(theAngle*2.0 + iTime*5.0) + 0.5;
	fragColor = vec4(c, c, c, 1.0);
}`;

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Shader circles");
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
f32[2] resolution = [SCREEN_WIDTH, SCREEN_HEIGHT];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.SetTargetFPS(60);

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0xffffffff);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
