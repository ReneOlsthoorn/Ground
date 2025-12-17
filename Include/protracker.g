

asm data {
ProtrackerNotePeriods:
	dq 856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453
	dq 428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226
	dq 214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113
}

#define PROTRACKER_NUMCHANNELS 4

string ProtrackerMod_Title;
string ProtrackerMod_Signature;  //must be M.K.

Class ProtrackerMod {
	byte* mod;					// ptr to all the data
	int	numSongPos;				// number of elements in the songlist
	byte* patternTable;			// this is the songlist. 128 elements that index the patternData.
	byte* patternData;

	byte* activeRow;			// ptr to active row in patternData.
	int nrPatterns;				// calculated total nr of patterns available in patterndata
	int speed;					// speed default or received from patterndata.

	int activeRowNr;
	int songPos;
	int tickCounter;

	int voice1Note;
	int voice1Sample;

	int nextRowNr;				// when a new activeRowNr is requested, this is the next activeRowNr.
	int nextSongPos;			// when a new activeRowNr is requested, this is the next songPos.


	// result: note index. 0 = no note. 1 = C-1, 2 = C#1, etc.
	function GetNote(int voiceData) : int {
		int note;
asm {
  push	rcx rsi rdx
  mov	rax, [voiceData@GetNote@ProtrackerMod]
  bswap eax		; bigendian reshuffle
  shr	rax, 16
  and	eax, 0x0fff
  xor	rcx, rcx
  cmp	eax, 0
  je	.exit
  mov	rcx, 0
  lea	rsi, [ProtrackerNotePeriods]
.loop:
  mov	rdx, [rsi+rcx*8]
  inc	rcx
  cmp	rdx, rax
  je	.exit
  cmp	rcx, 12*3
  jne	.loop
  xor	rcx, rcx
.exit:
  mov	[note@GetNote@ProtrackerMod], rcx
  pop	rdx rsi rcx
}
		return note;
	}


	function GetSample(int voiceData) : int {
		int sample;
asm {
  push	rcx rsi rdx
  mov	rax, [voiceData@GetSample@ProtrackerMod]
  bswap eax		; bigendian reshuffle

  mov	rcx, rax
  mov	rsi, 0xf000f000
  and	rcx, rsi
  shr	rcx, 12 ; 0x000f000f
  mov	rdx, rcx
  and	rdx, 0xf0000
  shr	rdx, 12
  or	rdx, rcx
  mov	[sample@GetSample@ProtrackerMod], rdx

  pop	rdx rsi rcx
}
		return sample;
	}


	function GetModuleTitle() {
		byte* behindTitle = this.mod + 20;
		byte backup = *behindTitle;			// this.mod[20] does not work, because it is a crap compiler
		*behindTitle = 0;
		// another bug: we cannot set the string in the own class, because the reference counting doesn't work correct for it.
		ProtrackerMod_Title = gc.cstr_convert(this.mod, gc.cstr_len(this.mod));
		*behindTitle = backup;
	}

	function GetSignature() {
		ptr location = this.mod + 0x438;
		ProtrackerMod_Signature = gc.cstr_convert(location, 4);
	}

	function GetNumSongPos() {
		byte* numSongPos = this.mod + 0x3b6;  //20+(31*30)
		this.numSongPos = *numSongPos;
	}

	function GetPatternTable() {
		this.patternTable = this.mod + 0x3b8;  // 128 entries
		int highest = 0;
		for (i in 0 ..< 128) {
			int patNr = *(this.patternTable+i);
			if (patNr > highest)
				highest = patNr;
		}
		this.nrPatterns = highest + 1;
	}

	function GetPatternData() {
		this.patternData = this.mod + 0x43c;  // 256 * 4 * ProtrackerMod_NrPatterns
	}

	function Load(string soundFilepath) {
		this.mod = null;

		int stFile = msvcrt.fopen(soundFilepath, "rb");
		if (stFile != 0) {
			msvcrt.fseek64(stFile, 0, g.msvcrt_SEEK_END);
			int stSize = msvcrt.ftell(stFile);
			this.mod = msvcrt.calloc(1, stSize);
			msvcrt.fseek64(stFile, 0, g.msvcrt_SEEK_SET);
			msvcrt.fread(this.mod, stSize, 1, stFile);
			msvcrt.fclose(stFile);
			this.GetModuleTitle();
			this.GetSignature();
			this.GetNumSongPos();
			this.GetPatternTable();
			this.GetPatternData();
		}
	}

	function ActivePatternNr() : int {
		return *(this.patternTable + this.songPos);
	}

	function GetNextPatternNr() : int {
		if ((this.songPos+1) >= this.numSongPos) {
			return 0;
		} else {
			return this.songPos+1;
		}
	}

	function CalculateActiveRow() {
		int currentPatternNr = this.ActivePatternNr();
		this.activeRow = this.patternData + (currentPatternNr * 256 * PROTRACKER_NUMCHANNELS) + (this.activeRowNr * 4 * PROTRACKER_NUMCHANNELS);
	}

	function AnalyseActiveMusicRow() {
		u32* aRow = this.activeRow;
		for (i in 0..3) {
			int channelValue = gc.bswap32(aRow[i]);
			int effect = (channelValue & 0xf00) >> 8;		// isolate the effect
			int effectPar = channelValue & 0x0ff;
			// Position Jump?
			if (effect == 11) {
				this.nextSongPos = effectPar;
				this.nextRowNr = 0;
			}
			// Pattern Break?
			if (effect == 13) {
				int first10 = ((effectPar & 0xf0) >> 4) * 10;
				this.nextRowNr = first10 + (effectPar & 0x0f);
				this.nextSongPos = this.GetNextPatternNr();
			}
			// Set speed?
			if (effect == 15)
				this.speed = effectPar;
		}
		this.voice1Note = this.GetNote(aRow[0]);
		this.voice1Sample = this.GetSample(aRow[0]);
	}

	function Activate() {
		if (this.tickCounter > 0) {
			this.tickCounter = this.tickCounter - 1;
			return;
		}

		// Correct when we go too fast.
		if (*mikmodModule.sngpos == this.songPos) {
			if (*mikmodModule.patpos <= (this.activeRowNr + 3))
				return;
		}
		this.tickCounter = this.speed;

		// Correct when we go too slow.
		if (*mikmodModule.sngpos == this.songPos) {
			if (*mikmodModule.patpos > (this.activeRowNr + 6))
				this.tickCounter = this.speed - 1;
		}

		// bepalen of we een positional jump hebben, of een andere jump.
		if (this.nextSongPos != -1 and this.nextRowNr != -1) {
			this.songPos = this.nextSongPos;
			this.activeRowNr = this.nextRowNr;
			this.nextSongPos = -1;
			this.nextRowNr = -1;
		}
		else {
			this.activeRowNr = this.activeRowNr + 1;
		}
		if (this.activeRowNr >= 64) {
			this.activeRowNr = 0;
			this.songPos = this.GetNextPatternNr();
		}
		this.CalculateActiveRow();
		this.AnalyseActiveMusicRow();
	}


	function StartPlay() {
		this.activeRow = null;
		this.activeRowNr = 0;
		this.songPos = 0;
		this.tickCounter = 0;
		this.nextRowNr = -1;
		this.nextSongPos = -1;
		this.speed = 6;

		this.CalculateActiveRow();
		this.AnalyseActiveMusicRow();
	}

	function Free() {
		if (this.mod != null)
			msvcrt.free(this.mod);
	}
}
