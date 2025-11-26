
dll mikmod function MikMod_RegisterAllDrivers();
dll mikmod function MikMod_RegisterAllLoaders();
dll mikmod function MikMod_Init(string str) : int;
dll mikmod function Player_Load(string filename, int nrVoices, int unknown) : ptr;
dll mikmod function Player_Start(ptr smodule);
dll mikmod function Player_GetRow() : int;
dll mikmod function Player_Active() : bool;
dll mikmod function Player_Stop();
dll mikmod function Player_Free(ptr smodule);
dll mikmod function Player_SetPosition(int pos);
dll mikmod function Player_SetVolume(int volume);
dll mikmod function MikMod_Update();
dll mikmod function MikMod_Exit();

class MikMod_Module packed {
	byte* songname;
	byte* modtype;
	byte* comment;
	u16 flags;
	u8	numchn;
	u8	numvoices;
	u16	numpos;
	u16	numpat;
	u16	numins;
	u16	numsmp;

	byte4 _filler1;		// the instruments ptr is 8 bytes aligned, byte it is on 4, so we need to add 4
	ptr	instruments;
	ptr	samples;

	u8	realchn;
	u8	totalchn;
	u16	reppos;
	u8	initspeed;

	byte1 _filler2;
	u16	inittempo;
	u8	initvolume;

	byte1 _filler3;
	byte128 panning;
	byte64 chanvol;

	u16	bpm;
	u16	sngspd;
	i16 volume;
	byte4	extspd;      // extended speed flag (default enabled)
    byte4	panflag;     // panning flag (default enabled)
    byte4	wrap;        // wrap module ? (default disabled)
    byte4	loop;        // allow module to loop ? (default enabled)
    byte4	fadeout;     // volume fade out during last pattern

    u16		patpos;      // current row number
    i16		sngpos;      // current song position
    u32		sngtime;     // current song time in 2^-10 seconds

    i16		relspd;      // relative speed factor
}
