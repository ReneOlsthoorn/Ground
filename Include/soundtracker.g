
mikmod.MikMod_RegisterAllDrivers();
if (mikmod.MikMod_Init("") != 0) return;
mikmod.MikMod_RegisterAllLoaders();
MikMod_Module* mikmodModule = null;

function SoundtrackerInit(string path, int volume) {
	mikmodModule = mikmod.Player_Load(path, 64, 0);
	*mikmodModule.wrap = 1;
	mikmod.Player_Start(mikmodModule);
	//*mikmodModule.volume = volume;    // volume will reset to full when song is restart
	mikmod.Player_SetVolume(volume);
}

function SoundtrackerUpdate() {
	if (mikmod.Player_Active())
		mikmod.MikMod_Update();
}

function SoundtrackerFree() {
	mikmod.Player_Stop();
	mikmod.Player_Free(mikmodModule);
	mikmod.MikMod_Exit();
}
