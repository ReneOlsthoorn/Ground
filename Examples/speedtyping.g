
//#template raylib
#template console
#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library raylib raylib.dll

#define NUMBER_OF_STARS 700


class ScrollCharacter {
    raylib_Vector2 position;
    bool visible;
    u8 theChar;

    function Init() {
        this.theChar = 'a';
        this.visible = false;
        this.position.x = 0.0f;
        this.position.y = 260.0f;
    }

    function MoveLeft() {
        this.position.x = this.position.x - 2.0f;
    }

    function CheckBounds() {
        if (this.position.x < -40.0f) {
            this.visible = false;
        }
    }
}

#define NR_LETTERS 35
ScrollCharacter[NR_LETTERS] scrollChars = [];
int scrollTextNeedle = 0;
byte* scrollText = `Dit is een scrolltekst geschreven met de Ground Language. Het is een tekst om te leren typen. Het gaat wat shader effecten gebruiken.`;

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
void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 center = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    float wave = sin(uv.x * 10.0 + iTime * 3.0) * 0.05 + (sin(uv.x * 20.0 + iTime * -3.0) * 0.05);
    uv.y += wave;
    fragColor = texture(texture0, uv);
}
`;


/*   Init   */
ScrollCharacter* sc;
ScrollCharacter* sc2;
for (i in 0 ..< NR_LETTERS) {
    sc = &scrollChars[i];
    sc.Init();
}







ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, KERNEL32_HIGH_PRIORITY_CLASS);
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

raylib.SetConfigFlags(CONFIG_FLAG_VSYNC_HINT);
raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Speed Typing");      //raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);    //raylib.InitWindow(0, 0, "-");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();

raylib_Texture2D fontTexture = raylib.LoadTexture(GC_CurrentExeDir + "image/thefont_rgba_outline.png");

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = msvcrt.calloc(1, screenWidth * screenHeight * sizeof(u32));
raylib_Image img;
img.data = pixels;
img.width = screenWidth;
img.height = screenHeight;
img.mipmaps = 1;
img.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
raylib_Texture2D screenTexture = raylib.LoadTextureFromImage(img);
f32[2] screenTextureResolution = [ screenWidth, screenHeight ];



int SeedStarfield = 123123;
float[NUMBER_OF_STARS] star_x = []; //van -500 tot 500
float[NUMBER_OF_STARS] star_y = []; //van -500 tot 500
float[NUMBER_OF_STARS] star_z = []; //van 100 tot 1000
float[NUMBER_OF_STARS] star_zv = []; //speed: from .5 to 5
int[NUMBER_OF_STARS] star_screenx = [];
int[NUMBER_OF_STARS] star_screeny = [];
int bertusRandomSeed = 123123;

function msys_frand(u32* seed) : float
{
	seed[0] = seed[0] * 0x343FD + 0x269EC3;
	u32 a = (seed[0] >> 9) or 0x3f800000;

	float floatedA;
	asm {
		movss    xmm0, dword [a@msys_frand]
		cvtss2sd xmm1, xmm0
		movq     qword [floatedA@msys_frand], xmm1
	}
	float res = floatedA - 1.0;
	return res;
}

function InitStarField()
{
	for (i in 0 ..< NUMBER_OF_STARS)
	{
		float starX = (msys_frand(&SeedStarfield) - 0.5) * 100.0;
		float starY = (msys_frand(&SeedStarfield) - 0.5) * 100.0;
		float starZ = (msys_frand(&SeedStarfield) * 900.0) + 100.0;
		float starZV = (msys_frand(&SeedStarfield) * 4.5) + 0.5;
		star_x[i] = starX;
		star_y[i] = starY;
		star_z[i] = starZ;
		star_zv[i] = starZV;
	}
}
InitStarField();

function SetPixel(int x, int y, u32 color)
{
	if ((x > SCREEN_WIDTH-5) or (x < 5) or (y > SCREEN_HEIGHT-5) or (y < 5))
		return;

	pixels[x,y] = color;
	pixels[x+1,y] = color;
	pixels[x,y+1] = color;
	pixels[x+1,y+1] = color;
}
function StarField()
{
	for (i in 0 ..< NUMBER_OF_STARS)
	{
		SetPixel(star_screenx[i], star_screeny[i], 0xff000000);
		star_z[i] = star_z[i] - star_zv[i];
		star_screenx[i] = ((star_x[i] / star_z[i]) * 6000.0) + SCREEN_WIDTH_D2_F;
		star_screeny[i] = ((star_y[i] / star_z[i]) * 4000.0) + SCREEN_HEIGHT_D2_F;

		int x = star_screenx[i];
		int y = star_screeny[i];

		int brightness = 255 - (star_z[i] * 0.255);
		u32 pixelColor = 0xff000000 or brightness or brightness << 8 or brightness << 16;
		SetPixel(x, y, pixelColor);

		if ((x > SCREEN_WIDTH-5) or (x < 5) or (y > SCREEN_HEIGHT-5) or (y < 5) or (star_z[i] < 0.0))
		{
			float starX = (msys_frand(&SeedStarfield)  - 0.5) * 100.0;
			float starY = (msys_frand(&SeedStarfield)  - 0.5) * 100.0;
			float starZ = (msys_frand(&SeedStarfield)  + 0.1) * 900.0;
			star_x[i] = starX;
			star_y[i] = starY;
			star_z[i] = starZ;
		}
	}
}





f32[16] iPoints = [ 
0.1f, 0.2f,
0.3f, 0.4f,
0.5f, 0.6f,
0.7f, 0.8f ];

ptr shader = raylib.LoadShaderFromMemory(vertexShader, fragmentShader);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int iPointsLocation = raylib.GetShaderLocation(shader, "iPoints");

raylib.SetShaderValue(shader, resolutionLocation, screenTextureResolution, SHADER_UNIFORM_VEC2);
raylib.SetShaderValueV(shader, iPointsLocation, iPoints, SHADER_UNIFORM_VEC2, 4);
raylib.HideCursor();


raylib_RenderTexture rt = raylib.LoadRenderTexture(screenWidth, screenHeight);
raylib_Texture2D rtTexture = &rt.texture_id;


function RandomBrightColor() : u32 {
    f32 h = raylib.GetRandomValue(0, 359);
    f32 s = 0.8f;
    f32 v = 0.9f;
    return raylib.ColorFromHSV(h, s, v);
}

u32 theColor = COLOR_WHITE;
raylib.SetTargetFPS(60);


raylib_Rectangle letterRect;
letterRect.x = 0.0f;
letterRect.y = 0.0f;
letterRect.width = 40.0f;
letterRect.height = 41.0f;

f32 mostRightX;
int mostRightIndex;

while (!raylib.WindowShouldClose()) {

	StarField();

    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.UpdateTexture(screenTexture, pixels);
    raylib.BeginDrawing();

    raylib.ClearBackground(COLOR_BLACK);
    raylib.DrawTexture(screenTexture, 0, 0, COLOR_WHITE);


    raylib.BeginTextureMode(rt);
    raylib.ClearBackground(COLOR_BLANK);

    mostRightX = 0.0f;
    mostRightIndex = 0;
    for (i in 0 ..< NR_LETTERS) {
        sc = &scrollChars[i];
        if (sc.visible) {
            sc.MoveLeft();
            sc.CheckBounds();
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

        if (sc.visible and needle == 0 and sc.theChar == '.')
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

    raylib.EndTextureMode();

    raylib.BeginShaderMode(shader);
    raylib.DrawTexture(rtTexture, 0, 0, COLOR_WHITE);
    raylib.EndShaderMode();


    raylib.DrawFPS(SCREEN_WIDTH-100, 20);

    raylib.EndDrawing();

    int theKey = raylib.GetCharPressed();
    sc = &scrollChars[0];
    if (theKey == sc.theChar) {
        sc.visible = false;
    }
}
raylib.UnloadShader(shader);
raylib.CloseWindow();

function FreeMemory() {
	msvcrt.free(fontXOffsets);
	msvcrt.free(fontYOffsets);
    msvcrt.free(pixels);
}

FreeMemory();
kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);
