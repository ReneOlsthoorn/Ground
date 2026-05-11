
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
	float time=iTime*1.0;
	vec2 uv = (fragCoord.xy / iResolution.xx-0.5)*8.0;
    vec2 uv0=uv;
	float i0=1.0;
	float i1=1.0;
	float i2=1.0;
	float i4=0.0;
	for(int s=0;s<7;s++)
	{
		vec2 r;
		r=vec2(cos(uv.y*i0-i4+time/i1),sin(uv.x*i0-i4+time/i1))/i2;
        r+=vec2(-r.y,r.x)*0.3;
		uv.xy+=r;
        
		i0*=1.93;
		i1*=1.15;
		i2*=1.7;
		i4+=0.05+0.1*time*i1;
	}
    float r=sin(uv.x-time)*0.5+0.5;
    float b=sin(uv.y+time)*0.5+0.5;
    float g=sin((uv.x+uv.y+sin(time*0.5))*0.5)*0.5+0.5;
	fragColor = vec4(r,g,b,1.0);
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
