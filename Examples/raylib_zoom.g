
// Quasi Infinite Zoom Voronoi
// https://www.shadertoy.com/view/XlBXWw

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

vec2 hash22(vec2 p) { 
    float n = sin(dot(p, vec2(41, 289)));
    return fract(vec2(262144, 32768)*n); 
}

float Voronoi(vec2 p)
{	
    vec2 ip = floor(p);
    p -= ip;
    float d = 1.;
    for (int i = -1; i <= 1; i++){
	    for (int j = -1; j <= 1; j++) {
     	    vec2 cellRef = vec2(i, j);
            vec2 offset = hash22(ip + cellRef);
            vec2 r = cellRef + offset - p; 
            float d2 = dot(r, r);            
            d = min(d, d2);
        }
    }    
    return sqrt(d); 
}

void main()
{
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	float t = iTime, s, a, b, e;
    float th = sin(iTime*.1)*sin(iTime*.13)*4.;
    float cs = cos(th), si = sin(th);
    uv *= mat2(cs, -si, si, cs);
    
    vec3 sp = vec3(uv, 0);
    vec3 ro = vec3(0, 0, -1);
    vec3 rd = normalize(sp - ro);
    vec3 lp = vec3(cos(iTime)*.375, sin(iTime)*0.1, -1);
    
    const float L = 8.;
    const float gFreq = .5;
    float sum = 0.;  
    
    th = 3.14159265*.7071/L;
    cs = cos(th), si = sin(th);
    mat2 M = mat2(cs, -si, si, cs);
    
    vec3 col = vec3(0);
    float f = 0., fx = 0., fy = 0.;
    vec2 eps = vec2(4./iResolution.y, 0);    
    vec2 offs = vec2(.1);  
	
	for (float i = 0.; i<L; i++){
		s = fract((i - t*2.)/L);
        e = exp2(s*L)*gFreq; // Range (approx): [ 1, pow(2., L)*gFreq ]
        a = (1. - cos(s*6.2831))/e;  // Smooth transition.

        f += Voronoi(M*sp.xy*e + offs)*a;
        fx += Voronoi(M*(sp.xy - eps.xy)*e + offs)*a;
        fy += Voronoi(M*(sp.xy - eps.yx)*e + offs)*a;
        
        sum += a;
        M *= M;
	}
    
    sum = max(sum, .001);
    
    f /= sum;
    fx /= sum;
    fy /= sum;
   
    float bumpFactor = .2;
    fx = (fx - f)/eps.x; // Change in X
    fy = (fy - f)/eps.x; // Change in Y.
    vec3 n = normalize( vec3(0, 0, -1) + vec3(fx, fy, 0)*bumpFactor );           
   
	vec3 ld = lp - sp;
	float lDist = max(length(ld), .001);
	ld /= lDist;
      
    float atten = 1.25/(1. + lDist*0.15 + lDist*lDist*0.15);
	float diff = max(dot(n, ld), 0.);  
    diff = pow(diff, 2.)*.66 + pow(diff, 4.)*.34; 
    float spec = pow(max(dot( reflect(-ld, n), -rd), 0.), 16.); 
	vec3 objCol = vec3(f*f, pow(f, 5.)*.05, f*f*.36);
    col = (objCol*(diff + .5) + vec3(.4, .6, 1)*spec*1.5)*atten;
	fragColor = vec4(sqrt(min(col, 1.)), 1);
}`;


f32[2] resolution = [SCREEN_WIDTH, SCREEN_HEIGHT];

raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Quasi Infinite Zoom Voronoi");
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
