
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
	float i, j;
	vec2 circ1, circ2;
	
	circ1.x = fragCoord.x-((sin(iTime)*iResolution.x)/4.0 + iResolution.x/2.0);
	circ1.y = fragCoord.y-((cos(iTime)*iResolution.x)/4.0 + iResolution.y/2.0);

	circ2.x = fragCoord.x-((sin(iTime*0.92+1.2)*iResolution.x)/4.0 + iResolution.x/2.0);
	circ2.y = fragCoord.y-((cos(iTime*0.43+0.3)*iResolution.x)/4.0 + iResolution.y/2.0);
	
	circ1.xy /= 8.0;
	circ2.xy /= 8.0;
	
	i = sin(sqrt(circ1.x*circ1.x+circ1.y*circ1.y))*0.5+0.5;
	j = sin(sqrt(circ2.x*circ2.x+circ2.y*circ2.y))*0.5+0.5;

	fragColor = vec4(j*1.5,i*1.5,(j+i)/4.0,1.0);
}`;

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib shader");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
f32[2] resolution = [screenWidth, screenHeight];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.SetTargetFPS(60);
raylib.HideCursor();

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, 0xffffffff);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
