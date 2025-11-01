
#define SDL3_EVENT_SIZE 128
#define SDL3_EVENT_TYPE_OFFSET 0
#define SDL3_EVENT_SCANCODE_OFFSET 24

#define SDL3_KEYBOARDEVENT_TYPE_U32 0
#define SDL3_KEYBOARDEVENT_RESERVED_U32 4
#define SDL3_KEYBOARDEVENT_TIMESTAMP_U64 8
#define SDL3_KEYBOARDEVENT_WINDOWID_U32 16
#define SDL3_KEYBOARDEVENT_WHICH_U32 20
#define SDL3_KEYBOARDEVENT_SCANCODE_U32 24
#define SDL3_KEYBOARDEVENT_KEYCODE_U32 28
#define SDL3_KEYBOARDEVENT_KEYMOD_U16 32
#define SDL3_KEYBOARDEVENT_RAW_U16 34
#define SDL3_KEYBOARDEVENT_DOWN_U8 36
#define SDL3_KEYBOARDEVENT_REPEAT_U8 37

dll sdl3 function SDL_Init(int flags);
dll sdl3 function SDL_CreateWindow(string title, int w, int h, int flags);
dll sdl3 function SDL_CreateRenderer(ptr window, string name);
dll sdl3 function SDL_CreateTexture(ptr renderer, int format, int access, int w, int h);
dll sdl3 function SDL_SetRenderVSync(ptr renderer, int vsync);
dll sdl3 function SDL_PollEvent(ptr event);
dll sdl3 function SDL_LockTexture(ptr texture, ptr rect, ptr pixels, ptr pitch);
dll sdl3 function SDL_UnlockTexture(ptr texture);
dll sdl3 function SDL_GetTicks();
dll sdl3 function SDL_RenderTexture(ptr renderer, ptr texture, ptr srcrect, ptr dstrect);
dll sdl3 function SDL_RenderTextureRotated(ptr renderer, ptr texture, ptr srcrect, ptr dstrect, float angle, ptr center, int flip);
dll sdl3 function SDL_RenderPresent(ptr renderer);
dll sdl3 function SDL_DestroyTexture(ptr texture);
dll sdl3 function SDL_DestroyRenderer(ptr renderer);
dll sdl3 function SDL_DestroyWindow(ptr window);
dll sdl3 function SDL_Quit();
dll sdl3 function SDL_CreateTextureFromSurface(ptr renderer, ptr surface);
dll sdl3 function SDL_DestroySurface(ptr surface);
dll sdl3 function SDL_ShowCursor();
dll sdl3 function SDL_HideCursor();
dll sdl3 function SDL_RenderDebugText(ptr renderer, f32 x, f32 y, string str);
dll sdl3 function SDL_SetRenderDrawColor(ptr renderer, int r, int g, int b, int a);
dll sdl3 function SDL_RenderClear(ptr renderer);
dll sdl3 function SDL_SetRenderScale(ptr renderer, f32 scaleX, f32 scaleY);
dll sdl3 function SDL_LoadWAV(ptr path, ptr audiospec, ptr audio_buf, u32* audio_len) : bool;
dll sdl3 function SDL_OpenAudioDeviceStream(int devid, ptr audiospec, ptr callback, ptr userdata) : ptr;
dll sdl3 function SDL_ResumeAudioStreamDevice(ptr stream) : bool;
dll sdl3 function SDL_GetAudioStreamAvailable(ptr stream) : int;
dll sdl3 function SDL_PutAudioStreamData(ptr stream, ptr buf, int len) : bool;
dll sdl3 function SDL_free(ptr mem);
dll sdl3 function SDL_GetMouseState(ptr x, ptr y) : u32;  // result = mousestatemask
dll sdl3 function SDL_PumpEvents();
dll sdl3 function SDL_HasMouse();
dll sdl3 function SDL_GetKeyboardState(ptr numkeys) : ptr;
dll sdl3 function SDL_SetTextureScaleMode(ptr texture, int scalemode);
dll sdl3 function SDL_SetTextureAlphaMod(ptr texture, int alpha);
dll sdl3 function SDL_memcpy(ptr dst, ptr src, int len) : ptr;
dll sdl3 function SDL_ConvertSurface(ptr surface, int format) : ptr;

dll sdl3 function SDL_srand(int seed);
dll sdl3 function SDL_rand(i32 n) : i32;
dll sdl3 function SDL_randf() : f32;
dll sdl3 function SDL_rand_bits() : i32;
dll sdl3 function SDL_rand_r(ptr state, i32 n) : i32;
dll sdl3 function SDL_randf_r(ptr state) : f32;
dll sdl3 function SDL_rand_bits_r(ptr state) : i32;

dll sdl3 function SDL_cos(float value) : float;
dll sdl3 function SDL_sin(float value) : float;

dll sdl3 function SDL_RenderFillRect(ptr renderer, ptr rect);
dll sdl3 function SDL_RenderReadPixels(ptr renderer, ptr rect) : ptr;  // result = SDL_Surface*

dll sdl3_image function IMG_Load(string filename) : ptr;  // result = SDL_Surface*



class SDL_Surface {     //sizeof: 48 bytes
    u32 flags;
    u32 pixelformat;
    i32 width;
    i32 height;
    i32 pitch;
	ptr pixels;
	i32 refcount;
	u64 reserved;
}


class MouseState {
	bool LeftPressed;
	bool RightPressed;
	f32 x_f32;
	f32 y_f32;
	int x;
	int y;
    function GetMouseState() {
		u32 mouseState = sdl3.SDL_GetMouseState(&this.x_f32, &this.y_f32);
		this.LeftPressed = mouseState & g.SDL_BUTTON_LMASK;
		this.RightPressed = mouseState & g.SDL_BUTTON_RMASK;
		this.x = this.x_f32;
		this.y = this.y_f32;
    }
}
