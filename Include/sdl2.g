
dll sdl2 function SDL_Init(int flags);
dll sdl2 function SDL_Quit();
dll sdl2 function SDL_CreateWindow(string title, int x, int y, int w, int h, int flags);
dll sdl2 function SDL_GetWindowSurface(ptr window);
dll sdl2 function SDL_ConvertSurface(ptr src_surface, ptr pixelFormat, int flags);
dll sdl2 function SDL_CreateTextureFromSurface(ptr renderer, ptr surface);
dll sdl2 function SDL_CreateRenderer(ptr window, int index, int flags);
dll sdl2 function SDL_CreateTexture(ptr renderer, int format, int access, int w, int h);
dll sdl2 function SDL_PollEvent(ptr event);
dll sdl2 function SDL_LockTexture(ptr texture, ptr rect, ptr pixels, ptr pitch);
dll sdl2 function SDL_UnlockTexture(ptr texture);
dll sdl2 function SDL_RenderCopy(ptr renderer, ptr texture, ptr srcrect, ptr dstrect);
dll sdl2 function SDL_RenderCopyEx(ptr renderer, ptr texture, ptr srcrect, ptr dstrect, float angle, ptr center, int flip);
dll sdl2 function SDL_RenderPresent(ptr renderer);
dll sdl2 function SDL_DestroyTexture(ptr texture);
dll sdl2 function SDL_DestroyRenderer(ptr renderer);
dll sdl2 function SDL_DestroyWindow(ptr window);
dll sdl2 function SDL_GetTicks();
dll sdl2 function SDL_GetTicks64();
dll sdl2 function SDL_FreeSurface(ptr surface);

dll sdl2_image function IMG_Load(string filename) : ptr;  //SDL_Surface* as result
dll sdl2_image function IMG_Init(int flags);
dll sdl2_image function IMG_Quit();
