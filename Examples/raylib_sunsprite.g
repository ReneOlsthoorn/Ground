
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
void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec4 colA = vec4(1.0, 0.0, 0.0, 1.0);
    vec4 colB = vec4(2.0, 1.5, 0.8, 1.0);
	vec2 uv0 = ((fragCoord.xy - iResolution.xy * .5) / iResolution.y) * 2.0;
    float angle = 0.79;
    mat2 rot = mat2(
        sin(angle), -cos(angle),
        cos(angle), sin(angle)
    );
    vec2 uv1 = uv0 * rot;
    vec2 uv2 = rot * uv0;
    vec3 enlarge = 2. - fract(vec3(0., 0.333, 0.667) + iTime*0.5);
    
    float r = dot(uv0,uv0);
    float p = (pow(r, 3.) + 0.3);
    uv0 *= p;
    uv1 *= p;
    uv2 *= p;
    float fire = dot(vec3(
        texture(iChannel0, uv0 * enlarge.x).x,
        texture(iChannel0, uv1 * enlarge.y).y,
        texture(iChannel0, uv2 * enlarge.z).z
    ), smoothstep(vec3(0.5), vec3(0.0), abs(fract(enlarge)-0.5)));
    fragColor = mix(colA, colB, fire) - r*r * 1.75;
}`;


raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib shader");
//raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);
//raylib.InitWindow(0, 0, "-");
ptr tex = raylib.LoadTexture(GC_CurrentExeDir + "image/slitscan.png");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int iChannelLocation = raylib.GetShaderLocation(shader, "iChannel0");
f32[2] resolution = [screenWidth, screenHeight];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.SetTargetFPS(60);
raylib.HideCursor();
f32[4] src = [0.0f, 0.0f, 1.0f, 1.0f];
f32[4] dst = [0.0f, 0.0f, screenWidth, screenHeight];
f32[2] origin = [0.0f, 0.0f];

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

