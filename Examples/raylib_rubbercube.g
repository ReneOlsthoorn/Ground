
#template raylib
//#template console
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
vec3 cubevec;
// Sinus bars function
vec3 calcSine(vec2 uv, float frequency, float amplitude, float shift, float offset, vec3 color, float width, float exponent)
{
    float y = sin(iTime * frequency + shift + uv.x) * amplitude + offset;
    float d = distance(y, uv.y);
    float scale = smoothstep(width, 0.0, distance(y, uv.y));
    return color * scale;
}
// Render the bars calling 3 CalcSines() and adding rgb componants
vec3 Bars(vec2 f)
{
    vec2 uv = f / iResolution.xy;
    vec3 color = vec3(0.0);
    color += calcSine(uv, 2.0, 0.25, 0.0, 0.5, vec3(0.0, 0.0, 1.0), 0.1, 3.0);
    color += calcSine(uv, 2.6, 0.15, 0.2, 0.5, vec3(0.0, 1.0, 0.0), 0.1, 1.0);
    color += calcSine(uv, 0.9, 0.35, 0.4, 0.5, vec3(1.0, 0.0, 0.0), 0.1, 1.0);
    return color;
}
// Classic iq twist function
vec3 Twist(vec3 p)
{
    float f = sin(iTime/3.)*1.45;
    float c = cos(f*p.y);
    float s = sin(f/2.*p.y);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}
// The distance function which generate a rotating twisted rounded cube 
// and we save its pos into cubevec
float Cube( vec3 p )
{
    p=Twist(p);
    cubevec.x = sin(iTime);
    cubevec.y = cos(iTime);
    mat2 m = mat2( cubevec.y, -cubevec.x, cubevec.x, cubevec.y );
    p.xy *= m;p.xy *= m;p.yz *= m;p.zx *= m;p.zx *= m;p.zx *= m;
    cubevec = p;
    return length(max(abs(p)-vec3(0.4),0.0))-0.08;
}
// Split the face in 4 triangles zones
// return color index 0 or 1 if color1 or color2
float Face( vec2 uv )
{
        uv.y = mod( uv.y, 1.0 );
        return ( ( uv.y < uv.x ) != ( 1.0 - uv.y < uv.x ) ) ? 1.0 : 0.0;
}
//Classic iq normal
vec3 getNormal( in vec3 p )
{
    vec2 e = vec2(0.005, -0.005);
    return normalize(
        e.xyy * Cube(p + e.xyy) +
        e.yyx * Cube(p + e.yyx) +
        e.yxy * Cube(p + e.yxy) +
        e.xxx * Cube(p + e.xxx));
}
void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    float x = fragCoord.x;						// Save x for shorter code
    float pat = iTime*5.0;				// Precalc 5time for later use				
    float Step = 1.0;							// For raymarching
    float Distance = 0.0;						// For raymarching
    float Near = -1.0;							// Near color index
    float Far = -1.0;							// Far color index
    vec3 lightPos = vec3(1.5, 0, 0);			// Light position
    vec2 kp = fragCoord.xy / iResolution.xy;	// Normalized coords
    vec2 p = -1.0 + 2.0*kp;						// Uv
    //vec4 m = iMouse / iResolution.xxxx;			// Mouse status
    vec4 m = vec4(iMouse, 0.0, 0.0) / vec4(iResolution.x);
    float hd=-1.;								// Hit Distance
    float ay=max(0.1,0.5-iTime/6.);		// For opening the screen
    // Non standard Raymarching
    // When we hit a face, we continue to march, so the ray goes into the cube
    // But we keep in Near the color index of the first face hit by the ray
    // We also keep in Far the last color index the ray hit
    // We break when 256 steps has been done or distance > 4
    // Finnaly we get in Near and Far vars the coloring values to simulate the transparency
    p.x *= iResolution.x / iResolution.y;
    vec3 ro = vec3( 0.0, 0.0, 2.1 );
    vec3 rd = normalize( vec3( p, -2. ) );
    for( int i = 0; i < 256; i++ )
        {
        	Step = Cube( ro + rd*Distance );
            Distance += Step*.5;

            if( Distance > 4.0 ) break;
            if( Step < 0.001 )
            	{
                    // Getting the color index of hit point
                 	Far = Face( cubevec.yx ) + Face( -cubevec.yx ) + Face( cubevec.xz ) + Face( -cubevec.xz ) + Face( cubevec.zy ) + Face( -cubevec.zy );
                    // save in hd the first hit distance for later lighting
            		if(hd<0.) hd=Distance;
                    // Save Far as Near on first hit
                    if( Near < 0.0 ) Near = Far;
                    // If transparency is not disabled lets keep walking into the cube
                    // Or maybe outside. Otherwise break
            		if(m.z<=0.0) Distance += 0.05; else break; // 0.05 is a magic number 
                }
        }
    // Initialize the background color to the sinus bars
    vec3 Color=Bars(fragCoord);
    // if we hit something
    if( Near > 0.0 )
    	{
          	// lighting stuff (taken from a Shane shader)
            vec3 sp = ro + rd*hd;
        	vec3 ld = lightPos - sp;
            float lDist = max(length(ld), 0.001);
            ld /= lDist;
            float atten = 1./(1. + lDist*.2 + lDist*.1); 
            float ambience = 0.7;
            vec3 sn = getNormal( sp);
            float diff = min(0.3,max( dot(sn, ld), 0.0));
            float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
            
            // Simulating transparency with mix() Near and Far
            if(m.z<=0.) Color = Color/5. + mix( vec3( 0.2, 0.0, 1.0 ), vec3( 1.0, 1.0, 1.0 ), vec3( ( Near*0.45 + Far*Far*0.04 ) ) );
            else Color = mix( vec3( 0.2, 0.0, 1.0 ), vec3( 1.0, 1.0, 1.0 ), vec3( ( Near*0.45 + Far*Far*0.04 ) ) );
            
            // Applying the lighting to color
            Color = Color*(diff+ambience)+vec3(0.78,0.5,1.)*spec/1.5;
        }
    // The bottom and top rainbow lines
    if (kp.y > ay && kp.y < ay+0.006 || kp.y > (1.-ay) && kp.y < 1.-ay+0.006 ) Color = vec3(0.5 + 0.5 * sin(x/120. + 3.14 + pat), 0.5 + 0.5 * cos (x/120. + pat), 0.5 + 0.5 * sin (x/120. + pat));
    // The bottom and top purple zones
    if(kp.y<ay || kp.y>1.-ay+0.006) Color=vec3(0.20,0.17,0.35);
    // Presenting color to the screen
    fragColor = vec4( Color, 1.0 );
}`;


raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib shader");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();
ptr shader = raylib.LoadShaderFromMemory(vsCode, fsCode);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int mouseLocation = raylib.GetShaderLocation(shader, "iMouse");
f32[2] resolution = [screenWidth, screenHeight];
raylib.SetShaderValue(shader, resolutionLocation, resolution, SHADER_UNIFORM_VEC2);
raylib.HideCursor();

while (!raylib.WindowShouldClose()) {
    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    ptr mouse = raylib.GetMousePosition();
    raylib.SetShaderValue(shader, mouseLocation, &mouse, SHADER_UNIFORM_VEC2);
    raylib.BeginDrawing();
    raylib.ClearBackground(COLOR_BLACK);
    raylib.BeginShaderMode(shader);
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, COLOR_WHITE);
    raylib.EndShaderMode();
    raylib.EndDrawing();
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
