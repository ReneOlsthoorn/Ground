
int mixInitResult = sdl3_mixer.MIX_Init();
if (mixInitResult == 0)
   return;

ptr soundtrackerMixer = null;
ptr mod_audio = null;
ptr soundtrackerTrack = null;

function SoundtrackerInit(string path) {
    soundtrackerMixer = sdl3_mixer.MIX_CreateMixerDevice(-1, null);
    mod_audio = sdl3_mixer.MIX_LoadAudio(soundtrackerMixer, path, false);
    soundtrackerTrack = sdl3_mixer.MIX_CreateTrack(soundtrackerMixer);
    sdl3_mixer.MIX_SetTrackAudio(soundtrackerTrack, mod_audio);
    sdl3_mixer.MIX_PlayTrack(soundtrackerTrack, 0);
}

function SoundtrackerFree() {
    sdl3_mixer.MIX_DestroyTrack(soundtrackerTrack);
    sdl3_mixer.MIX_DestroyAudio(mod_audio);
    sdl3_mixer.MIX_DestroyMixer(soundtrackerMixer);
    sdl3_mixer.MIX_Quit();
}
