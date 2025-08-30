
dll soloud function Soloud_create() : ptr;
dll soloud function Soloud_init(ptr soloud_p) : int;
dll soloud function Soloud_deinit(ptr soloud_p);
dll soloud function Soloud_destroy(ptr soloud_p);
dll soloud function Soloud_play(ptr soloud_p, ptr wav_p) : int;
dll soloud function Soloud_setVolume(ptr soloud_p, int handle, f32 volume);
dll soloud function Soloud_setRelativePlaySpeed(ptr soloud_p, int handle, f32 speed);
dll soloud function Wav_create() : ptr;
dll soloud function Wav_load(ptr wav_p, string filename) : int;
dll soloud function Wav_setVolume(ptr wav_p, f32 volume);
dll soloud function Wav_setLooping(ptr wav_p, int looping);
dll soloud function Wav_destroy(ptr wav_p);
