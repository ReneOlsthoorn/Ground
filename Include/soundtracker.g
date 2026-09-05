
int mixInitResult = sdl3_mixer.MIX_Init();
if (mixInitResult == 0)
   return;

ptr soundtrackerMixer = null;
ptr mod_audio = null;
ptr soundtrackerTrack = null;

SDL_AudioSpec modulePlayerSpec;
modulePlayerSpec.format = 0x8020;   // SDL_AUDIO_S32LE 32 bit integer samples
modulePlayerSpec.channels = 4;
modulePlayerSpec.freq = 48000;  // 0xbb80

i32 playerProps = sdl3.SDL_CreateProperties();

function SoundtrackerInit(string path) {
    soundtrackerMixer = sdl3_mixer.MIX_CreateMixerDevice(g.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &modulePlayerSpec);
    mod_audio = sdl3_mixer.MIX_LoadAudio(soundtrackerMixer, path, false);
    soundtrackerTrack = sdl3_mixer.MIX_CreateTrack(soundtrackerMixer);
    sdl3_mixer.MIX_SetTrackAudio(soundtrackerTrack, mod_audio);
    sdl3.SDL_SetNumberProperty(playerProps, "SDL_mixer.play.loops", -1);
    //sdl3.SDL_SetNumberProperty(playerProps, "SDL_mixer.play.start_order", 2);  // start from other pattern: did not work
    //sdl3.SDL_SetNumberProperty(playerProps, "SDL_mixer.play.start_frame", 2);  // start from other pattern: did not work
    sdl3_mixer.MIX_PlayTrack(soundtrackerTrack, playerProps);
    //sdl3_mixer.MIX_SetTrackPlaybackPosition(soundtrackerTrack, 2);  // start from other pattern: did not work
}

function SoundtrackerFree() {
    sdl3.SDL_DestroyProperties(playerProps);
    sdl3_mixer.MIX_DestroyTrack(soundtrackerTrack);
    sdl3_mixer.MIX_DestroyAudio(mod_audio);
    sdl3_mixer.MIX_DestroyMixer(soundtrackerMixer);
    sdl3_mixer.MIX_Quit();
}
