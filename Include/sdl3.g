
#define SDL3_EVENT_SIZE 128
#define SDL3_EVENT_TYPE_OFFSET 0
#define SDL3_EVENT_SCANCODE_OFFSET 24

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
dll sdl3 function SDL_GetMouseState(ptr x, ptr y) : u32;
dll sdl3 function SDL_PumpEvents();
dll sdl3 function SDL_HasMouse();

dll sdl3_image function IMG_Load(string filename) : ptr;  //SDL_Surface* as result
