
// How to run Connect Four:
// > Start your local Ollama. You can download Ollama at: https://ollama.com/
// > Unzip <GroundProjectFolder>/GroundResources/misc/ConnectFour.ai.zip somewhere. Open the solution and select an available downloaded Ollama Ai-model in the sourcecode, and Run the code.
// > In the GroundCompiler, compile and run connect4.g which will use LibCurl to communicate with the local ConnectFour.ai service.

#template sdl3

#include graphics_defines960x560.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll
#library libcurl libcurl-x64.dll

bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
f32[4] srcRect = [];
f32[4] destRect = [];
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;

int[7,6] board = [ ] asm;
string boardStr = "123456712345671234567123456712345671234567";

function BoardToString() {
	byte* p = &boardStr;
	for (y in 0 ..< 6)
		for (x in 0 ..< 7)
			p[(y*7)+x] = board[x,y]+48;
}

function StringToBoard() {
	byte* p = &boardStr;
	for (y in 0 ..< 6)
		for (x in 0 ..< 7)
			board[x,y] = p[(y*7)+x]-48;
}

//board[0,5] = 1;  board[1,5] = 2;
BoardToString();  // initially fill the boardStr with valid values.

function IsPointInCircle(float px, float py, float cx, float cy, float radius) : bool {
    float dx = px - cx;
    float dy = py - cy;
    bool result = (dx * dx + dy * dy) < (radius * radius);
	return result;
}


// The write_data procedure is a callback for LibCurl. Because Ground doesn't generate x64 ABI functions at this moment, this must be done manual in assembly.
asm procedures {
write_data:
;C function: size_t write_data(void *buffer, size_t size, size_t nmemb, void *userp);
; rcx = buffer *
; rdx = size
; r8  = nmemb
; r9  = userp
  push	rdi
  mov	r11, 0
  mov	rdi, [r9]

.next_block:
  mov	r10, 0
.next_byte:
  mov	al, [rcx+r11]
  mov	[rdi+r11], al
  inc	r10
  inc	r11
  cmp	r10, r8
  jne	.next_byte
  dec	rdx
  cmp	rdx, 0
  jne	.next_block

  mov	al, 0  ; Ensure trailing zero.
  mov	[rdi+r11], al

  lea	rax, [rdi+r11]
  mov	[r9], rax

  pop	rdi
  mov	rax, r11
  ret
}


ptr msgPtr = msvcrt.calloc(1, 50*1024);
asm data {msgNeedle dq 0}
int curlInitResult = libcurl.curl_global_init(CURL_GLOBAL_ALL);
ptr curlHandle = libcurl.curl_easy_init();


sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Connect Four against Ai", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
sdl3.SDL_SetRenderVSync(renderer, 1);

ptr surface = sdl3_image.IMG_Load("image/connect4_board.png");
if (surface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr convertedSurface = sdl3.SDL_ConvertSurface(surface, g.SDL_PIXELFORMAT_ARGB8888);
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);

SDL_Surface* psurface = convertedSurface;
ptr surfacePixels = *psurface.pixels;
sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
sdl3.SDL_memcpy(pixels, surfacePixels, SCREEN_HEIGHT * SCREEN_WIDTH * SCREEN_PIXELSIZE);

//for (m in 0..< 6) { for (n in 0..< 7) { for (y in 0..< SCREEN_HEIGHT) {  for (x in 0..< SCREEN_WIDTH) {
//		if (IsPointInCircle(x, y, (273.0 + (n * 70.5)), (117.0 + (m * 70.5)), 27.0)) pixels[x,y] = 0xffff0000;
//} } } }
sdl3.SDL_UnlockTexture(texture);

// ptr texture = sdl3.SDL_CreateTextureFromSurface(renderer, convertedSurface);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);
sdl3.SDL_DestroySurface(convertedSurface);

surface = sdl3_image.IMG_Load("image/connect4_p1.png");
ptr p1Texture = sdl3.SDL_CreateTextureFromSurface(renderer, surface);
sdl3.SDL_SetTextureScaleMode(p1Texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);
surface = sdl3_image.IMG_Load("image/connect4_p2.png");
ptr p2Texture = sdl3.SDL_CreateTextureFromSurface(renderer, surface);
sdl3.SDL_SetTextureScaleMode(p2Texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);


function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 3.0, 4.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+0.5, y+0.5, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function ShowPieceAdd(int pieceX, int pieceY) {
	writeText(renderer, 60.0, 80.0, "X: " + pieceX + " y: " + pieceY);
}


function DrawPieces() {
	for (y in 0 ..< 6) {
		for (x in 0 ..< 7) {
			int piece = board[x,y];

			if (piece != 0) {
				ptr thePlayerTexture = p1Texture;
				if (piece == 2)
					thePlayerTexture = p2Texture;

				srcRect[0] = 0;  srcRect[1] = 0; srcRect[2] = 60; srcRect[3] = 60;
				destRect[0] = 243 + (x * 70.5);  destRect[1] = 87 + (y * 70.5); destRect[2] = 60; destRect[3] = 60;
				sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
				sdl3.SDL_RenderTextureRotated(renderer, thePlayerTexture, srcRect, destRect, 0.0, null, g.SDL_FLIP_NONE);
			}
		}
	}
}


function AddPiece(int pieceX, int playerNr) {
	for (y in 0 ..< 6) {
		int checkY = 5 - y;
		if (board[pieceX, checkY] == 0) {
			board[pieceX, checkY] = playerNr;
			return;
		}
	}
}


function DoCurlThing() {
	string theCommand = "playfield";
	BoardToString();

	g.[msgNeedle] = msgPtr;
	string theUrl = "http://localhost:5138/ai/connectfour?command=" + theCommand + "&data=" + boardStr;
	libcurl.curl_easy_setopt(curlHandle, CURLOPT_URL, theUrl);
	libcurl.curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, g.write_data);
	libcurl.curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, g.msgNeedle);

	int success = libcurl.curl_easy_perform(curlHandle);

	if (success != 0) {
asm {
  jmp	ExitConnect4
}
	}
	else {
		byte* zetPtr = msgPtr;
		AddPiece((zetPtr[0]-48)-1, 2);
	}
}


bool pieceAdded = false;
while (StatusRunning)
{
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderClear(renderer);

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

	bool mouseLeftPressed = false;
	bool mouseRightPressed = false;
	f32 mouseX;
	f32 mouseY;
	u32 mouseState = sdl3.SDL_GetMouseState(&mouseX, &mouseY);
	mouseLeftPressed = mouseState & g.SDL_BUTTON_LMASK;

	DrawPieces();
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (mouseLeftPressed and (!pieceAdded)) {
		int newPieceX = (mouseX - 273) / 70.5;
		int newPieceY = (mouseY - 117) / 70.5;
		AddPiece(newPieceX, 1);
		pieceAdded = true;
	}

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;

	if (pieceAdded and (!mouseLeftPressed)) {
		pieceAdded = false;
		DoCurlThing();
	}

}
asm {
ExitConnect4:
}
libcurl.curl_easy_cleanup(curlHandle);
libcurl.curl_global_cleanup();
msvcrt.free(msgPtr);

sdl3.SDL_DestroyTexture(p1Texture);
sdl3.SDL_DestroyTexture(p2Texture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
