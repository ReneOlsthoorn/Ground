
// Onderwater
// https://www.shadertoy.com/view/MdlXz8

#template raylib

#include graphics_defines1280x720.g
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
uniform vec2 iResolution;
uniform float iTime;
in vec2 fragTexCoord;
out vec4 fragColor;
vec2 fragCoord = gl_FragCoord.xy;

#define TAU 6.28318530718
#define MAX_ITER 5

void main() 
{
	float time = iTime * .5+23.0;
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 p = mod(uv*TAU, TAU)-250.0;
	vec2 i = vec2(p);
	float c = 1.0;
	float inten = .005;

	for (int n = 0; n < MAX_ITER; n++) 
	{
		float t = time * (1.0 - (3.5 / float(n+1)));
		i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1.0/length(vec2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
	}
	c /= float(MAX_ITER);
	c = 1.17-pow(c, 1.4);
	vec3 colour = vec3(pow(abs(c), 8.0));
    colour = clamp(colour + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
	fragColor = vec4(colour, 1.0);
}`;


f32[2] resolution = [SCREEN_WIDTH, SCREEN_HEIGHT];

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Onderwater");
int glVersion = raylib.rlGetVersion();   // Call this after InitWindow()
if (glVersion < 3)
    return;

ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
bool isOK = raylib.IsShaderValid(shader);
raylib.SetTargetFPS(60);

while (!raylib.WindowShouldClose() && isOK) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_RAYWHITE);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0xffffffff);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
