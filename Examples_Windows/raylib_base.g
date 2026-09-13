
#template raylib
#include graphics_defines1280x720.g
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

    gl_Position = mvp*vec4(vertexPosition, 1.0);
}`;



byte* fsCode2 = `#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);
    //finalColor = vec4(1.0, 0.5, 0.5, 1.0); //texelColor; //*colDiffuse*fragColor;
    finalColor = texelColor * fragColor;
}`;



byte* fsCode = `#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;

out vec4 finalColor;

vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);
    return a + b*cos( 6.28318*(c*t+d) );
}
void main() {
    //vec2 uv = (gl_FragCoord.xy * 2.0 - iResolution.xy) / iResolution.y;
    vec2 uv = fragTexCoord * 2.0 - 1.0;

    //vec2 uv = fragTexCoord * 2.0 - 1.0;
    vec2 uv0 = uv;
    vec3 finalColorTmp = vec3(0.0);
    for (float i = 0.0; i < 2.0; i++) {
        uv = fract(uv * 1.5) - 0.5;
        float d = length(uv) * exp(-length(uv0));
        vec3 col = palette(length(uv0) + i * 0.4 + iTime * 0.4);
        d = sin(d * 8.0 + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2);
        finalColorTmp += col * d;
    }       
    finalColor = vec4(finalColorTmp, 1.0);
}`;



raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib GLSL");
if (gc.linux)
    raylib.SetTargetFPS(60);
	
raylib_Texture2D tex = raylib.LoadTexture(GC_CurrentExeDir + "/image/slitscan.png");
if (tex == null)
    return;
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
raylib_Shader shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int texture0Location = raylib.GetShaderLocation(shader, "texture0");

f32[2] resolution = [screenWidth, screenHeight];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
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
    raylib.SetShaderValueTexture(shader, texture0Location, tex);
    //raylib.DrawRectangle(0, 0, screenWidth, screenHeight, COLOR_WHITE);
    raylib.DrawTexturePro(tex, src, dst, origin, 0.0, COLOR_WHITE);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
