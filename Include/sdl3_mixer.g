
dll sdl3_mixer function MIX_Init() : int;
dll sdl3_mixer function MIX_Quit();
dll sdl3_mixer function MIX_CreateMixerDevice(int devid, ptr audiospec) : ptr;
dll sdl3_mixer function MIX_LoadAudio(ptr mixer, string filepath, bool predecode) : ptr;
dll sdl3_mixer function MIX_CreateTrack(ptr mixer) : ptr;
dll sdl3_mixer function MIX_SetTrackAudio(ptr track, ptr audio) : bool;
dll sdl3_mixer function MIX_PlayTrack(ptr track, int properties) : bool;
dll sdl3_mixer function MIX_DestroyTrack(ptr track);
dll sdl3_mixer function MIX_DestroyAudio(ptr audio);
dll sdl3_mixer function MIX_DestroyMixer(ptr mixer);
dll sdl3_mixer function MIX_SetTrackLoops(ptr track, int nrLoops) : bool;
dll sdl3_mixer function MIX_SetTrackPlaybackPosition(ptr track, int frames) : bool;
