
#template sdl3

#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll
#library glm libcglm-0.dll


u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int screenpitch = SCREEN_LINESIZE;
f32[4] ballSrcRectVoetbal = [0,0,32,32];
f32[4] ballSrcRectTennisbal = [0,32,32,32];
f32[4] ballSrcRectKogel = [0,64,32,32];
f32[4] ballDestRect = [0,0,32,32];
//ptr ballSrc = &ballSrcRectVoetbal;
ptr ballSrc = &ballSrcRectKogel;


ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, 0x80); //HIGH_PRIORITY_CLASS
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("3D", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_SetRenderVSync(renderer, 1);


ptr ballSurface = sdl3_image.IMG_Load("image/3balls_32.png");
if (ballSurface == null) return;
ptr ballTexture = sdl3.SDL_CreateTextureFromSurface(renderer, ballSurface);
if (ballTexture == null) return;
sdl3.SDL_SetTextureScaleMode(ballTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(ballSurface);


#include screen.g


// Following 2 functions are also in utils.g
function DegreeToRadians(float angle_deg) : float {
	return angle_deg * MATH_PI / 180.0;
}
function ValidRadian_f32(f32 radian) : f32 {
	f32 valid = radian;
	while (valid >= MATH_2PI)
		valid = valid - MATH_2PI;
	f32 floorValue = 0.0;
	while (valid < floorValue)
		valid = valid + MATH_2PI;
	return valid;
}

#define CUBE_SIZE 24

f32[] cube = [ -0.5,-0.5,-0.5,1.0,  0.5,-0.5,-0.5,1.0,
			    0.5, 0.5,-0.5,1.0,  -0.5,0.5,-0.5,1.0,
               -0.5,-0.5, 0.5,1.0,  0.5,-0.5, 0.5,1.0,
                0.5, 0.5, 0.5,1.0, -0.5, 0.5, 0.5,1.0,

			   -0.4,-0.4,-0.4,1.0,  0.4,-0.4,-0.4,1.0,
			    0.4, 0.4,-0.4,1.0, -0.4, 0.4,-0.4,1.0,
               -0.4,-0.4, 0.4,1.0,  0.4,-0.4, 0.4,1.0,
                0.4, 0.4, 0.4,1.0, -0.4, 0.4, 0.4,1.0,

			   -0.2,-0.2,-0.2,1.0,  0.2,-0.2,-0.2,1.0,
			    0.2, 0.2,-0.2,1.0, -0.2, 0.2,-0.2,1.0,
               -0.2,-0.2, 0.2,1.0,  0.2,-0.2, 0.2,1.0,
                0.2, 0.2, 0.2,1.0, -0.2, 0.2, 0.2,1.0 ] asm; 


f32[CUBE_SIZE*VEC3] ndcCube = [ ] asm;


f32[16] model = [ ] asm;
f32[16] view = [ ] asm;
f32[16] proj = [ ] asm;
f32[16] mvp = [ ] asm;
ptr[3] matrixArray = [ proj, view, model ];

/*
Local -> Model -> World
World -> View  -> View/Eye
View  -> Proj  -> Clip
Clip  / w      -> NDC (Normalized Device Coordinates)
NDC  -> Viewport -> Screencoordinates

final_clip_pos   = proj x view x model x local_position;   ->  Clip Space
final_ndc        = final_clip_pos / final_clip_pos.w;      ->  NDC
final_screen_pos = viewport_transform(final_ndc);          ->  Screen Space
*/


// Model
//glm.glmc_mat4_identity(model);
//f32[3] vec3_1 = [ 1.0, 0.0, 0.0 ] asm;
//f32[3] vec3_2 = [ 0.0, 1.0, 0.0 ] asm;
//glm.glmc_rotate(model, DegreeToRadians(3.0), vec3_1);
//glm.glmc_rotate(model, DegreeToRadians(3.0), vec3_2);
//glm_translate(model, (vec3){0.0f, 0.0f, -3.0f});


// View
f32[3] vec3_eye = [ 0.0, 0.0, 4.0 ] asm;
f32[3] vec3_center = [ 0.0, 0.0, 0.0 ] asm;
f32[3] vec3_up = [ 0.0, 1.0, 0.0 ] asm;
glm.glmc_mat4_identity(view);
glm.glmc_lookat(vec3_eye, vec3_center, vec3_up, view);


// Projection
glm.glmc_mat4_identity(proj);
glm.glmc_perspective(DegreeToRadians(60.0), 1280.0 / 720.0, 0.1, 100.0, proj);


// mvp matrix is the multiplication of the proj, view and model matrices.
glm.glmc_mat4_mulN(matrixArray, 3, mvp);


// Below is the Compare function for the qsort of the ndcCube.
asm procedures {
ndcCube_Compare:
; rcx = ptr to element 1 (element is vec3) , rdx = pointer to element 2
  xor	eax, eax
  mov	eax, dword [rcx+8]	; retrieve the f32 Z in vec3
  sub	rsp, 8
  mov	[rsp], eax
  movss	xmm0, dword [rsp]
  mov	eax, dword [rdx+8]
  mov	[rsp], eax
  movss	xmm1, dword [rsp]
  add	rsp, 8
  ucomiss xmm0, xmm1		; compare the two z f32's.
  jb    .exitLess
  ja    .exitGreater
  xor	eax, eax        ; eax = 0
  ret
.exitLess:
  mov	eax, -1
  ret
.exitGreater:
  mov	eax, 1
  ret
}


f32[VEC4] tmpVec4 = [] asm;
f32 cube_XRotation = 0.0;
f32 cube_YRotation = 0.0;

function RenderCube() {
	
	cube_XRotation = cube_XRotation + 0.01;
	cube_XRotation = ValidRadian_f32(cube_XRotation);
	cube_YRotation = cube_YRotation + 0.02;
	cube_YRotation = ValidRadian_f32(cube_YRotation);

	glm.glmc_mat4_identity(model);
	glm.glmc_rotate_x(model, cube_XRotation, model);
	glm.glmc_rotate_y(model, cube_YRotation, model);

	glm.glmc_mat4_mulN(matrixArray, 3, mvp);

	for (i in 0 ..< CUBE_SIZE) {
		glm.glmc_mat4_mulv(mvp, &cube[i*VEC4], tmpVec4);

		float ndc_x = tmpVec4[0] / tmpVec4[3];
		float ndc_y = tmpVec4[1] / tmpVec4[3];
		float ndc_z = tmpVec4[2] / tmpVec4[3];   // depth

		ndcCube[i*VEC3] = ndc_x;
		ndcCube[i*VEC3+1] = ndc_y;
		ndcCube[i*VEC3+2] = ndc_z;
	}

	sdl3.SDL_qsort(ndcCube, CUBE_SIZE, 3*sizeof(f32), g.ndcCube_Compare);

	for (i in (CUBE_SIZE-1)..0) {
		float screen_x = (ndcCube[i*VEC3] + 0.5) * 1280.0;
		float screen_y = (1.0 - (ndcCube[i*VEC3+1] + 0.5)) * 720.0; // flip Y for screen space

		float ballSize = (0.99 - ndcCube[i*VEC3+2]) * 1500.0;

		ballDestRect[0] = screen_x - 32.0;
		ballDestRect[1] = screen_y;
		ballDestRect[2] = ballSize;
		ballDestRect[3] = ballSize;

		sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
		sdl3.SDL_RenderTextureRotated(renderer, ballTexture, ballSrc, &ballDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}
}


sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
g.[pixels_p] = pixels;
GC_ClearScreenPixels(0xff808080);
sdl3.SDL_UnlockTexture(texture);
sdl3.SDL_RenderTexture(renderer, texture, null, null);

string soundFile = "sound/mod/chinese dream.mod";
#include soundtracker.g
SoundtrackerInit(soundFile, 127);

#include protracker.g
ProtrackerMod ptMod;
ptMod.Load(soundFile);
ptMod.StartPlay();


string[] NoteMapping = [ "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" ];
string GetNoteResult;
function GetNoteInfo(int note, int sample) {
	if (note == 0) {
		GetNoteResult = "      ";
		return;
	}
	note = note - 1;
	int octaaf = note / 12;
	int noteWithin = note % 12;
	GetNoteResult = NoteMapping[noteWithin] + (octaaf+1) + " " + gc.hex$(sample,2);   // returning strings does not work at this moment.
}


function PrintMusicInfo() {
	gc.fill(g.[screentext_p], SCREEN_TEXTSIZE, ' ');
	g.[screen_cursor] = SCREEN_TEXTCOLUMNS;

	g.[screen_cursor] = g.[screen_cursor] + 21;
	print("Title:" + ProtrackerMod_Title + "  NumSongPos:" + ptMod.numSongPos + "\n");
	//print("  Pat.Table:");  for (i in 0 ..< ptMod.numSongPos) print(" " + *(ptMod.patternTable+i));

	g.[screen_cursor] = g.[screen_cursor] + 21;
	print("Active pattern:" + ptMod.ActivePatternNr() + "  songPos:" + ptMod.songPos +  "  speed:" + ptMod.speed + "\n");

	g.[screen_cursor] = g.[screen_cursor] + 21;
	print("Active rownr:" + ptMod.activeRowNr + "\n");

	g.[screen_cursor] = g.[screen_cursor] + 21;
	print("Mikmod patpos:" + *mikmodModule.patpos + "  sngpos:" + *mikmodModule.sngpos);

	g.[screen_cursor] = SCREEN_TEXTCOLUMNS*6;
	int currentPatternNr = ptMod.ActivePatternNr();

	g.[screen_cursor] = 0;
	for (i in 0..44) {
		int thisRow = ptMod.activeRowNr - 22 + i;
		if (thisRow < 0 or thisRow > 63) {
			g.[screen_cursor] = g.[screen_cursor] + SCREEN_TEXTCOLUMNS;
			continue;
		}
		u32* aRow = ptMod.patternData + (currentPatternNr * 256 * PROTRACKER_NUMCHANNELS) + (thisRow * 4 * PROTRACKER_NUMCHANNELS);
		// u32 channelValue = gc.bswap32(*(aRow+4));  // gc.hex$(channelValue, 8)

		for (v in 0..3) {
			int note = ptMod.GetNote(*(aRow+(v*4)));
			int sample = ptMod.GetSample(*(aRow+(v*4)));
			GetNoteInfo(note, sample);

			if (v == 0)
				g.[screen_cursor] = g.[screen_cursor] + 2;
			if (v == 1)
				g.[screen_cursor] = g.[screen_cursor] + 3;
			if (v == 2)
				g.[screen_cursor] = g.[screen_cursor] + 46;
			if (v == 3)
				g.[screen_cursor] = g.[screen_cursor] + 3;
			print(GetNoteResult);
		}
		print("\n");
	}
}


int loopStartTicks = 0;
int debugBestTicks = 0xffff;
gc.fill(g.[screentext_p], SCREEN_TEXTSIZE, ' ');
gc.fill(g.[screencolor_p], SCREEN_TEXTSIZE, 0xbf); //0xbf);
gc.rectfill(g.[screencolor_p], 19, 45, SCREEN_TEXTCOLUMNS, 0x6e);
gc.rectfill(g.[screencolor_p]+61, 19, 45, SCREEN_TEXTCOLUMNS, 0x6e);

gc.fill(g.[screencolor_p]+SCREEN_TEXTCOLUMNS*22, 19, 0xe6);
gc.fill(g.[screencolor_p]+SCREEN_TEXTCOLUMNS*22+61, 19, 0xe6);

while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	if (keyState[g.SDL_SCANCODE_UP]) { }
	if (keyState[g.SDL_SCANCODE_LEFT]) { }
	if (keyState[g.SDL_SCANCODE_RIGHT]) { }
	if (keyState[g.SDL_SCANCODE_DOWN]) { }

	loopStartTicks = sdl3.SDL_GetTicks();

	SoundtrackerUpdate();
	ptMod.Activate();

	sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
	g.[pixels_p] = pixels;
	PrintMusicInfo();
	ScreenDrawTextLines();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	RenderCube();

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}


sdl3.SDL_DestroyTexture(ballTexture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
FreeScreenBuffers();
ptMod.Free();
SoundtrackerFree();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
