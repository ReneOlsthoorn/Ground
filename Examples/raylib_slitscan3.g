
#template raylib

#include graphics_defines960x560.g
#library raylib raylib.dll raylib


byte* vsCode = `#version 330
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;
uniform mat4 mvp;
out vec2 fragTexCoord;
out vec4 fragColor;
void main()
{
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}`;


byte* fsCode = `#version 330
in vec2 fragTexCoord;
in vec4 fragColor;
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D texture0;
out vec4 finalColor;
void main()
{
    vec2 pt = gl_FragCoord.xy;
    pt = 3.0*(pt.xy / iResolution.xy - 0.5)*vec2(iResolution.x/iResolution.y,1);
    float rInv = 1./length(pt);
    pt = pt * rInv - vec2(rInv + iTime,0.5);
    finalColor = texture(texture0,pt)*rInv/2.;
}`;


raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib shader");
raylib.HideCursor();
if (gc.linux)
    raylib.SetTargetFPS(60);
	
raylib_Texture2D tex = raylib.LoadTexture(GC_CurrentExeDir + "/image/slitscan.png");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
raylib_Shader shader = raylib.LoadShaderFromMemory(vsCode, fsCode);

int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int texture0Location = raylib.GetShaderLocation(shader, "texture0");

f32[2] resolution = [screenWidth, screenHeight];

f32[4] src = [0.0f, 0.0f, 1.0f, 1.0f];
f32[4] dst = [0.0f, 0.0f, screenWidth, screenHeight];
f32[2] origin = [0.0f, 0.0f];

while (!raylib.WindowShouldClose()) {
    raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.SetShaderValueTexture(shader, texture0Location, tex);
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, COLOR_WHITE);
    raylib.DrawTexturePro(tex, src, dst, origin, 0.0, COLOR_WHITE);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
