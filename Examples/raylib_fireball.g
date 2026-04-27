
// Ball Of Fire
// https://www.shadertoy.com/view/lsf3RH

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
vec2 fragCoord = gl_FragCoord.xy;             //vec2 fragCoord = fragTexCoord * iResolution; (doesn't work...?)

float snoise(vec3 uv, float res)
{
	const vec3 s = vec3(1e0, 1e2, 1e3);
	uv *= res;
	vec3 uv0 = floor(mod(uv, res))*s;
	vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
	vec3 f = fract(uv); f = f*f*(3.0-2.0*f);
	vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
		      	  uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);
	vec4 r = fract(sin(v*1e-1)*1e3);
	float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	r = fract(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
	float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	return mix(r0, r1, f.z)*2.-1.;
}

void main() {
	vec2 p = -.5 + fragCoord.xy / iResolution.xy;
	p.x *= iResolution.x/iResolution.y;	
	float color = 3.0 - (3.*length(2.*p));
	vec3 coord = vec3(atan(p.x,p.y)/6.2832+.5, length(p)*.4, .5);
	for(int i = 1; i <= 7; i++)
	{
		float power = pow(2.0, float(i));
		color += (1.5 / power) * snoise(coord + vec3(0.,-iTime*.05, iTime*.01), power*16.);
	}
	fragColor = vec4( color, pow(max(color,0.),2.)*0.4, pow(max(color,0.),3.)*0.15 , 1.0);
}`;


f32[2] resolution = [SCREEN_WIDTH, SCREEN_HEIGHT];

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Ball Of Fire");
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
