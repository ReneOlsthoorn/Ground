
import	sdl3_image,\
		sdl3_image_IMG_FreeAnimation,'IMG_FreeAnimation',\
		sdl3_image_IMG_Init,'IMG_Init',\
		sdl3_image_IMG_Linked_Version,'IMG_Linked_Version',\
		sdl3_image_IMG_Load,'IMG_Load',\
		sdl3_image_IMG_LoadAVIF_RW,'IMG_LoadAVIF_RW',\
		sdl3_image_IMG_LoadAnimation,'IMG_LoadAnimation',\
		sdl3_image_IMG_LoadAnimationTyped_RW,'IMG_LoadAnimationTyped_RW',\
		sdl3_image_IMG_LoadAnimation_RW,'IMG_LoadAnimation_RW',\
		sdl3_image_IMG_LoadBMP_RW,'IMG_LoadBMP_RW',\
		sdl3_image_IMG_LoadCUR_RW,'IMG_LoadCUR_RW',\
		sdl3_image_IMG_LoadGIFAnimation_RW,'IMG_LoadGIFAnimation_RW',\
		sdl3_image_IMG_LoadGIF_RW,'IMG_LoadGIF_RW',\
		sdl3_image_IMG_LoadICO_RW,'IMG_LoadICO_RW',\
		sdl3_image_IMG_LoadJPG_RW,'IMG_LoadJPG_RW',\
		sdl3_image_IMG_LoadJXL_RW,'IMG_LoadJXL_RW',\
		sdl3_image_IMG_LoadLBM_RW,'IMG_LoadLBM_RW',\
		sdl3_image_IMG_LoadPCX_RW,'IMG_LoadPCX_RW',\
		sdl3_image_IMG_LoadPNG_RW,'IMG_LoadPNG_RW',\
		sdl3_image_IMG_LoadPNM_RW,'IMG_LoadPNM_RW',\
		sdl3_image_IMG_LoadQOI_RW,'IMG_LoadQOI_RW',\
		sdl3_image_IMG_LoadSVG_RW,'IMG_LoadSVG_RW',\
		sdl3_image_IMG_LoadSizedSVG_RW,'IMG_LoadSizedSVG_RW',\
		sdl3_image_IMG_LoadTGA_RW,'IMG_LoadTGA_RW',\
		sdl3_image_IMG_LoadTIF_RW,'IMG_LoadTIF_RW',\
		sdl3_image_IMG_LoadTexture,'IMG_LoadTexture',\
		sdl3_image_IMG_LoadTextureTyped_RW,'IMG_LoadTextureTyped_RW',\
		sdl3_image_IMG_LoadTexture_RW,'IMG_LoadTexture_RW',\
		sdl3_image_IMG_LoadTyped_RW,'IMG_LoadTyped_RW',\
		sdl3_image_IMG_LoadWEBPAnimation_RW,'IMG_LoadWEBPAnimation_RW',\
		sdl3_image_IMG_LoadWEBP_RW,'IMG_LoadWEBP_RW',\
		sdl3_image_IMG_LoadXCF_RW,'IMG_LoadXCF_RW',\
		sdl3_image_IMG_LoadXPM_RW,'IMG_LoadXPM_RW',\
		sdl3_image_IMG_LoadXV_RW,'IMG_LoadXV_RW',\
		sdl3_image_IMG_Load_RW,'IMG_Load_RW',\
		sdl3_image_IMG_Quit,'IMG_Quit',\
		sdl3_image_IMG_ReadXPMFromArray,'IMG_ReadXPMFromArray',\
		sdl3_image_IMG_ReadXPMFromArrayToRGB888,'IMG_ReadXPMFromArrayToRGB888',\
		sdl3_image_IMG_SaveJPG,'IMG_SaveJPG',\
		sdl3_image_IMG_SaveJPG_RW,'IMG_SaveJPG_RW',\
		sdl3_image_IMG_SavePNG,'IMG_SavePNG',\
		sdl3_image_IMG_SavePNG_RW,'IMG_SavePNG_RW',\
		sdl3_image_IMG_isAVIF,'IMG_isAVIF',\
		sdl3_image_IMG_isBMP,'IMG_isBMP',\
		sdl3_image_IMG_isCUR,'IMG_isCUR',\
		sdl3_image_IMG_isGIF,'IMG_isGIF',\
		sdl3_image_IMG_isICO,'IMG_isICO',\
		sdl3_image_IMG_isJPG,'IMG_isJPG',\
		sdl3_image_IMG_isJXL,'IMG_isJXL',\
		sdl3_image_IMG_isLBM,'IMG_isLBM',\
		sdl3_image_IMG_isPCX,'IMG_isPCX',\
		sdl3_image_IMG_isPNG,'IMG_isPNG',\
		sdl3_image_IMG_isPNM,'IMG_isPNM',\
		sdl3_image_IMG_isQOI,'IMG_isQOI',\
		sdl3_image_IMG_isSVG,'IMG_isSVG',\
		sdl3_image_IMG_isTIF,'IMG_isTIF',\
		sdl3_image_IMG_isWEBP,'IMG_isWEBP',\
		sdl3_image_IMG_isXCF,'IMG_isXCF',\
		sdl3_image_IMG_isXPM,'IMG_isXPM',\
		sdl3_image_IMG_isXV,'IMG_isXV'

import sdl3,\
       sdl3_SDL_Init,'SDL_Init',\
       sdl3_SDL_CreateWindow,'SDL_CreateWindow',\
       sdl3_SDL_CreateRenderer,'SDL_CreateRenderer',\
       sdl3_SDL_CreateTexture,'SDL_CreateTexture',\
       sdl3_SDL_SetRenderVSync,'SDL_SetRenderVSync',\
       sdl3_SDL_PollEvent,'SDL_PollEvent',\
       sdl3_SDL_LockTexture,'SDL_LockTexture',\
       sdl3_SDL_UnlockTexture,'SDL_UnlockTexture',\
       sdl3_SDL_GetTicks,'SDL_GetTicks',\
       sdl3_SDL_RenderTexture,'SDL_RenderTexture',\
       sdl3_SDL_RenderTextureRotated,'SDL_RenderTextureRotated',\
       sdl3_SDL_RenderPresent,'SDL_RenderPresent',\
       sdl3_SDL_DestroyTexture,'SDL_DestroyTexture',\
       sdl3_SDL_DestroyRenderer,'SDL_DestroyRenderer',\
       sdl3_SDL_DestroyWindow,'SDL_DestroyWindow',\
       sdl3_SDL_Quit,'SDL_Quit',\
       sdl3_SDL_CreateTextureFromSurface,'SDL_CreateTextureFromSurface',\
	   sdl3_SDL_ShowCursor,'SDL_ShowCursor',\
	   sdl3_SDL_HideCursor,'SDL_HideCursor',\
	   sdl3_SDL_RenderDebugText, 'SDL_RenderDebugText',\
	   sdl3_SDL_SetRenderDrawColor, 'SDL_SetRenderDrawColor',\
	   sdl3_SDL_RenderClear, 'SDL_RenderClear',\
	   sdl3_SDL_SetRenderScale, 'SDL_SetRenderScale',\
	   sdl3_SDL_LoadWAV, 'SDL_LoadWAV',\
	   sdl3_SDL_OpenAudioDeviceStream, 'SDL_OpenAudioDeviceStream',\
	   sdl3_SDL_ResumeAudioStreamDevice, 'SDL_ResumeAudioStreamDevice',\
	   sdl3_SDL_GetAudioStreamAvailable, 'SDL_GetAudioStreamAvailable',\
	   sdl3_SDL_PutAudioStreamData, 'SDL_PutAudioStreamData',\
	   sdl3_SDL_free, 'SDL_free',\
	   sdl3_SDL_GetMouseState, 'SDL_GetMouseState',\
	   sdl3_SDL_PumpEvents, 'SDL_PumpEvents',\
	   sdl3_SDL_HasMouse, 'SDL_HasMouse',\
	   sdl3_SDL_SetTextureScaleMode, 'SDL_SetTextureScaleMode',\
	   sdl3_SDL_GetKeyboardState, 'SDL_GetKeyboardState',\
	   sdl3_SDL_memcpy, 'SDL_memcpy',\
	   sdl3_SDL_srand, 'SDL_srand',\
	   sdl3_SDL_rand, 'SDL_rand',\
	   sdl3_SDL_randf, 'SDL_randf',\
	   sdl3_SDL_rand_bits, 'SDL_rand_bits',\
	   sdl3_SDL_rand_r, 'SDL_rand_r',\
	   sdl3_SDL_randf_r, 'SDL_randf_r',\
	   sdl3_SDL_rand_bits_r, 'SDL_rand_bits_r',\
	   sdl3_SDL_cos, 'SDL_cos',\
	   sdl3_SDL_sin, 'SDL_sin',\
	   sdl3_SDL_SetTextureAlphaMod, 'SDL_SetTextureAlphaMod',\
	   sdl3_SDL_ConvertSurface, 'SDL_ConvertSurface',\
	   sdl3_SDL_RenderLine, 'SDL_RenderLine',\
	   sdl3_SDL_RenderFillRect, 'SDL_RenderFillRect',\
	   sdl3_SDL_RenderReadPixels, 'SDL_RenderReadPixels',\
       sdl3_SDL_DestroySurface,'SDL_DestroySurface'
