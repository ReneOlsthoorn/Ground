
#template raylib

#include graphics_defines960x560.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library raylib raylib.dll


byte* vsCode = `#version 330
in vec3 vertexPosition;
in vec2 vertexTexCoord;
out vec2 fragTexCoord;
uniform mat4 mvp;
void main()
{
    fragTexCoord = vertexTexCoord;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}`;


byte* fsCode = `#version 330
in vec2 fragTexCoord;
out vec4 fragColor;
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;
vec2 fragCoord = gl_FragCoord.xy;
void main()
{
    vec2 pt = gl_FragCoord.xy;
    pt = 3.0 * (pt.xy / iResolution.xy - 0.5) * vec2(iResolution.x/iResolution.y, 1.0);
    float rInv = 1.0 / length(pt);
    pt = pt * rInv - vec2(rInv + iTime, 0.5);
    fragColor = mix(texture(iChannel0, pt * 0.5) * rInv * 0.8, vec4(1.0, 1.0, 1.0, 1.0), smoothstep(4.5, 6.0, rInv));
    fragColor.rgb = pow(fragColor.rgb, vec3(0.5));
}`;


f32[2] resolution = [SCREEN_WIDTH, SCREEN_HEIGHT];

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Slitscan");
int glVersion = raylib.rlGetVersion();
if (glVersion < 3)
    return;

ptr tex = raylib.LoadTexture(GC_CurrentExeDir + "image/slitscan.png");

ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int iChannelLocation = raylib.GetShaderLocation(shader, "iChannel0");
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
bool isOK = raylib.IsShaderValid(shader);
raylib.SetTargetFPS(60);

f32[4] src = [0.0, 0.0, 1.0, 1.0];
f32[4] dst = [0, 0, SCREEN_WIDTH, SCREEN_HEIGHT];
f32[2] origin = [0.0, 0.0];

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.SetShaderValueTexture(shader, iChannelLocation, tex);
    raylib.DrawTexturePro(tex, src, dst, origin, 0.0, COLOR_WHITE);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
