

#template raylib
//#template console
#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library raylib raylib.dll
#library soloud soloud_x64.dll
#library mikmod libmikmod-3.dll


class ScrollCharacter {
    raylib_Vector2 position;
    bool visible;
    u8 theChar;

    function Init() {
        this.theChar = 'a';
        this.visible = false;
        this.position.x = 0.0f;
        this.position.y = 340.0f;
    }

    function MoveLeft() {
        this.position.x = this.position.x - 2.0f;
    }

    function CheckBounds() {
        if (this.position.x < 160.0f) {
            this.visible = false;
        }
    }
}


#define NR_LETTERS 35
ScrollCharacter[NR_LETTERS] scrollChars = [];
int scrollTextNeedle = 0;
byte* scrollText = `      Als je vroeger in Nederland een Commodore 64 starterspakket kocht bij Vroom en Dreesmann, dan kreeg je een \
computer, cassette recorder, joystick en wat software.      \
Het idee overheerste toendertijd dat je een computer kocht om wat te leren.       \
Dus kreeg je educatieve software erbij, zoals Tempo Typen.        \
Dat was een educatief spel waarmee je kon leren typen.      \
Toendertijd liet ik het links liggen, want ik wilde schieten en actie, geen educatie.      \
Tempo Typen was gemaakt door het softwarebedrijf radarsoft met een postadres in Alphen aan de Rijn.        \
Anno 2026 is dit mijn variant op Tempo Typen.      \
De muziek is een bekende soundtracker module van de Amiga.      \
De visuals worden gedaan door een pixelshader op de GPU.       \
Ik gebruik Raylib ervoor, waarbij ik merk dat het veel schokkeriger is dan SDL3.      \
Groet, Rene Olsthoorn.                        `;


function GetNewScrollLetter() : u8 {
	u8 c = scrollText[scrollTextNeedle];
    c = msvcrt.tolower(c);
	scrollTextNeedle++;
	if (scrollText[scrollTextNeedle] == 0)
		scrollTextNeedle = 0;
	return c;
}


/*   Precalculation   */
int* fontXOffsets = msvcrt.calloc(sizeof(int), 256);
int* fontYOffsets = msvcrt.calloc(sizeof(int), 256);
function setupFontOffsetsLine(string fontString, int offsetY) {
	for (i in 0..7) {
		fontXOffsets[fontString[i]] = i * 40;
		fontYOffsets[fontString[i]] = offsetY;
	}
}
setupFontOffsetsLine("abcdefgh", 0);
setupFontOffsetsLine("ijklmnop", 1*41);
setupFontOffsetsLine("qrstuvwx", 2*41);
setupFontOffsetsLine(`yz!"#$'(`, 3*41);
setupFontOffsetsLine(").+,-/01", 4*41);
setupFontOffsetsLine("23456789", 5*41);
setupFontOffsetsLine(";>=<? !@", 6*41);
setupFontOffsetsLine("ABCDEFGH", 0);
setupFontOffsetsLine("IJKLMNOP", 1*41);
setupFontOffsetsLine("QRSTUVWX", 2*41);
setupFontOffsetsLine(`YZ!"#$'(`, 3*41);



byte* vertexShader = `
#version 330
in vec3 vertexPosition;
in vec2 vertexTexCoord;
out vec2 fragTexCoord;
uniform mat4 mvp;
void main()
{
    fragTexCoord = vertexTexCoord;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
`;



byte* fragmentShader = `
#version 330
in vec2 fragTexCoord;
out vec4 fragColor;
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D texture0;
uniform vec2 iPoints[4];
uniform vec2 explosion;
uniform float explosionTime;

vec2 Hash12(float t) {
    float x = fract(sin(t*674.3) * 453.2);
    float y = fract(sin((t+x)*714.3) * 263.2);
    return vec2(x,y);
}

#define NUM_LAYERS 3.
#define TAU 6.28318
#define PI 3.141592
#define Velocity .010 //modified value to increse or decrease speed, negative value travel backwards
#define StarGlow 0.025
#define StarSize 02.
#define CanvasView 20.

float Star(vec2 uv, float flare){
    float d = length(uv);
  	float m = sin(StarGlow*1.2)/d;  
    float rays = max(0., .5-abs(uv.x*uv.y*1000.)); 
    m += (rays*flare)*2.;
    m *= smoothstep(1., .1, d);
    return m;
}

float Hash21(vec2 p){
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+45.32);
    return fract(p.x*p.y);
}

vec3 StarLayer(vec2 uv){
    vec3 col = vec3(0);
    vec2 gv = fract(uv);
    vec2 id = floor(uv);
    for(int y=-1;y<=1;y++){
        for(int x=-1; x<=1; x++){
            vec2 offs = vec2(x,y);
            float n = Hash21(id+offs);
            float size = fract(n);
            float star = Star(gv-offs-vec2(n, fract(n*34.))+.5, smoothstep(.1,.9,size)*.46);
            vec3 color = sin(vec3(.2,.2,.2)*fract(n*2345.2)*TAU)*.25+.75;
            color = color*vec3(0.9,0.9,0.9+size);
            star *= sin(iTime*.6+n*TAU)*.5+.5;
            col += star*size*color;
        }
    }
    return col;
}

float random3_1(vec3 point) 
{
    return fract(sin(dot(point, vec3(12.9898,78.233,45.5432)))*43758.5453123);
}

float thunder(vec2 uv, float time, float seed, float segments, float amplitude)
{
    float h = uv.x+0.3;
    float s = uv.y*segments;
    float t = time*20.0;
    
    vec2 fst = floor(vec2(s,t));
    vec2 cst = ceil(vec2(s,t));
    
    float h11 = h + (random3_1(vec3(fst.x, fst.y, seed)) - 0.5) * amplitude;
    float h12 = h + (random3_1(vec3(cst.x, fst.y, seed)) - 0.5) * amplitude;
    float h21 = h + (random3_1(vec3(fst.x, cst.y, seed)) - 0.5) * amplitude;
    float h22 = h + (random3_1(vec3(cst.x, cst.y, seed)) - 0.5) * amplitude;
    
    float h1 = mix(h11, h12, fract(s));
    float h2 = mix(h21, h22, fract(s));
    float alpha = mix(h1, h2, fract(t));
    
    return 1.0 - abs(alpha - 0.5);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 center = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 frontUV = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    vec2 backUV = frontUV;

    vec2 point = iPoints[0];
    vec2 pointCenter = (fragCoord - point) / iResolution.y;
    vec2 explosionCenter = (fragCoord - explosion) / iResolution.y;

    float wave = sin(frontUV.x * 3.0 + iTime * 3.0) * 0.10 + (sin(frontUV.x * -7.0 + iTime * -2.0) * 0.10);
    frontUV.y += wave;

    pointCenter.y += wave;
    explosionCenter.y += wave;

    vec4 col2 = vec4(0.0);
    if (point != vec2(0.0,0.0))
    {
        vec3 col = vec3(0.0);
        float d = length(pointCenter);
        float mask2 = step(0.038, d); 
        col += 0.010/d;
        col *= mask2;
        col2 = vec4(col, 1.0); //step(0.9, col)); //step(0.1, col));
    }

    //Explosion
    vec4 expColor = vec4(0.0);
    if (explosion != vec2(0.0, 0.0))
    {
        float explVerschil = iTime - explosionTime;
        if (explVerschil < 0.8f) {

            //vec3 tmpCol = vec3(0.0);
            float tmpCol = 0.0;
            for (float i=0.;i<8;i++) {
                vec2 dir = Hash12(explosionTime+i)-0.5;
                //float t = fract(explVerschil);
                float d = length(explosionCenter+(dir*explVerschil*2.8));
                tmpCol += 0.02/d;
                tmpCol *= 1.0-(explVerschil*2.0);
                expColor = vec4(tmpCol, tmpCol, tmpCol, 1.0);
            }
        }
    }

    //Bliksem
    vec2 uvBliksem = gl_FragCoord.xy / iResolution.y;
    float bliksemAlpha = 0.0;
    for(int i = 0; i < 3; ++i)
    {
        float f = float(i) + 0.0;
        float a = thunder(uvBliksem, iTime, f, 10.0 * pow(1.25, f), 0.125 * pow(1.25, f));
        a = pow(a, f + 2.0); 
        bliksemAlpha = max(bliksemAlpha, a);
    }
    bliksemAlpha = max((bliksemAlpha-0.9)/0.1, 0.0);
    vec4 bliksemColor = vec4(bliksemAlpha, bliksemAlpha, bliksemAlpha, 1.0);

    // stars
    vec4 starsColor = vec4(0.0);
    vec2 uv3 = (fragCoord -.5 * iResolution.xy) / iResolution.y;
	vec2 M = vec2(0);
    //M -= vec2(M.x+sin(iTime*0.22), M.y-cos(iTime*0.22));
    float t = iTime*Velocity; 
    vec3 col = vec3(0);  
    for(float i=0.; i<1.; i+=1./NUM_LAYERS){
        float depth = fract(i+t);
        float scale = mix(CanvasView, .5, depth);
        float fade = depth*smoothstep(1.,.9,depth);
        col += StarLayer(uv3*scale+i*453.2-iTime*.05+M)*fade;}   
    starsColor = vec4(col,1.0);


    vec2 ndc = (fragCoord - iResolution.xy / 2.0) / min(iResolution.x, iResolution.y);
    vec3 lens = normalize(vec3(ndc, 0.05));
	vec3 location = lens * 15.0 + vec3(0.0, 0.0, iTime);
	vec3 cellId = floor(location);
	vec3 relativeToCell = fract(location);
    vec3 locationOfStarInCell = fract(cross(cellId, vec3(2.154, -6.21, 0.42))) * 0.5 + 0.25;
	float star = max(0.0, 10.0 * (0.1 - distance(relativeToCell, locationOfStarInCell)));
	vec4 starsColor2 = vec4(star, star, star, 1.0);


    vec4 front  = texture(texture0, frontUV);
    vec4 back = col2 + bliksemColor + expColor + starsColor + starsColor2;
    float mask = step(0.1, max(max(front.r, front.g), front.b));  

    vec4 tmpColor = mix(back, front, mask);
    fragColor = tmpColor;
}
`;


/*   Init   */
ScrollCharacter* sc;
ScrollCharacter* sc2;
for (i in 0 ..< NR_LETTERS) {
    sc = &scrollChars[i];
    sc.Init();
}


// Loading sounds...
ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr explosionSfxr = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(explosionSfxr, "sound/sfxr/explosion.sfs");
if (sfxrLoaded != 0) return;
soloud.Sfxr_setVolume(explosionSfxr, 0.5f);

function playExplosion() { soloud.Soloud_play(soloudObject, explosionSfxr); }

function deleteSoundObjects() {
	soloud.Sfxr_destroy(explosionSfxr);
	soloud.Soloud_deinit(soloudObject);
	soloud.Soloud_destroy(soloudObject);
}



ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, KERNEL32_HIGH_PRIORITY_CLASS);
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

raylib.SetConfigFlags(CONFIG_FLAG_VSYNC_HINT);
//raylib.ClearWindowState(CONFIG_FLAG_VSYNC_HINT); 
raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Tempo Typen");      //raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);    //raylib.InitWindow(0, 0, "-");
raylib.SetTargetFPS(0);   // turn off 60herz, because it is a sleep-loop. I rely on vsync which is smoother.

f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();

raylib_Texture2D fontTexture = raylib.LoadTexture(GC_CurrentExeDir + "image/thefont_rgba_outline.png");
f32[2] screenTextureResolution = [ screenWidth, screenHeight ];

f32[16] iPoints = [ 
700.0f, 300.0f,
0.3f, 0.4f,
0.5f, 0.6f,
0.7f, 0.8f ];

ptr shader = raylib.LoadShaderFromMemory(vertexShader, fragmentShader);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int iPointsLocation = raylib.GetShaderLocation(shader, "iPoints");
int explosionLocation = raylib.GetShaderLocation(shader, "explosion");
int explosionTimeLocation = raylib.GetShaderLocation(shader, "explosionTime");

raylib.SetShaderValue(shader, resolutionLocation, screenTextureResolution, SHADER_UNIFORM_VEC2);
raylib.SetShaderValueV(shader, iPointsLocation, iPoints, SHADER_UNIFORM_VEC2, 4);
raylib.HideCursor();

raylib_RenderTexture rt = raylib.LoadRenderTexture(screenWidth, screenHeight);
raylib_Texture2D rtTexture = &rt.texture_id;

raylib_Rectangle letterRect;
letterRect.x = 0.0f;
letterRect.y = 0.0f;
letterRect.width = 40.0f;
letterRect.height = 41.0f;

f32 mostRightX;
int mostRightIndex;
f32[2] explosionArray = [ 0.0f, 0.0f ];
f32 explosionTime = 0.0f;

#include soundtracker.g
SoundtrackerInit("sound/mod/back on earth.mod", 50);

while (!raylib.WindowShouldClose()) {
	SoundtrackerUpdate();

    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.SetShaderValueV(shader, iPointsLocation, iPoints, SHADER_UNIFORM_VEC2, 4);
    raylib.SetShaderValue(shader, explosionTimeLocation, &explosionTime, SHADER_UNIFORM_FLOAT);
    raylib.SetShaderValue(shader, explosionLocation, explosionArray, SHADER_UNIFORM_VEC2);

    raylib.BeginDrawing();

    raylib.BeginTextureMode(rt);
    raylib.ClearBackground(COLOR_BLACK);

    mostRightX = 0.0f;
    mostRightIndex = 0;
    for (i in 0 ..< NR_LETTERS) {
        sc = &scrollChars[i];
        if (sc.visible) {
            sc.MoveLeft();
            sc.CheckBounds();
            if (sc.visible == false) {
                explosionArray[0] = sc.position.x+40.0f;
                explosionArray[1] = sc.position.y+40.0f;
                explosionTime = t;
                //playExplosion();
            }
        }
        if (sc.visible) {
            letterRect.x = fontXOffsets[sc[0].theChar];
            letterRect.y = fontYOffsets[sc[0].theChar];
            if (sc.position.x > mostRightX) {
                mostRightX = sc.position.x;
                mostRightIndex = i;
            }
            raylib.DrawTextureRec(fontTexture,  &letterRect, sc[0].position, COLOR_WHITE);
        }
    }

    // rage quit if the NR_LETTERS is exceeded.
    if (mostRightIndex >= (NR_LETTERS-1))
        raylib.CloseWindow();


    // insert new character
    if (mostRightX < 1280.0f) {
        sc = &scrollChars[NR_LETTERS-1];
        sc.visible = true;
        sc.theChar = GetNewScrollLetter();
        sc.position.x = 1320.0f;
        for (i in 0 .. NR_LETTERS-2) {
            sc = &scrollChars[i];
            if (sc.theChar == ' ')
                sc.visible = false;
        }
    }

    // cleanup the array
    int needle = 0;
    for (i in 0 ..< NR_LETTERS) {
        sc = &scrollChars[i];
        sc2 = &scrollChars[needle];

        if (sc.visible and needle == 0 and (sc.theChar == '.' or sc.theChar == '?' or sc.theChar == '!' or sc.theChar == ','))
            continue;

        if (sc.visible) {
            if (needle != i) {
                sc2.theChar = sc.theChar;
                sc2.position.x = sc.position.x;
                sc2.position.y = sc.position.y;
                sc2.visible = sc.visible;
            }
            needle = needle + 1;
        }
    }
    for (i in needle ..< NR_LETTERS) {
        sc = &scrollChars[i];
        sc.visible = false;
    }

    sc = &scrollChars[0];
    if (sc.theChar == ' ') {
       iPoints[0] = 0.0f;
       iPoints[1] = 0.0f;
    } else if (sc.visible and sc.theChar != ' ') {
       iPoints[0] = sc.position.x+18.0f;
       iPoints[1] = sc.position.y+20.0f;
    }
    raylib.EndTextureMode();


    raylib.BeginShaderMode(shader);
    raylib.DrawTexture(rtTexture, 0, 0, COLOR_WHITE);
    raylib.EndShaderMode();


    //raylib.DrawFPS(SCREEN_WIDTH-100, 20);

    raylib.EndDrawing();

    int theKey = raylib.GetCharPressed();
    theKey = msvcrt.tolower(theKey);
    sc = &scrollChars[0];
    if (theKey == sc.theChar) {
        sc.visible = false;
        explosionArray[0] = sc.position.x+40.0f;
        explosionArray[1] = sc.position.y+40.0f;
        explosionTime = t;
        playExplosion();
    }
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
SoundtrackerFree();
deleteSoundObjects();

function FreeMemory() {
	msvcrt.free(fontXOffsets);
	msvcrt.free(fontYOffsets);
}
FreeMemory();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);
