
function msys_frand(u32* seed) : float
{
	seed[0] = seed[0] * 0x343FD + 0x269EC3;
	u32 a = (seed[0] >> 9) or 0x3f800000;

	float floatedA;
	asm {
		movss    xmm0, dword [a@msys_frand]
		cvtss2sd xmm1, xmm0
		movq     qword [floatedA@msys_frand], xmm1
	}
	float res = floatedA - 1.0;
	return res;
}

function msys_rand(int* seed) : u32
{
	seed[0] = (seed[0] * 0x343FD) + 0x269EC3;
	u32 result = (seed[0] >> 16) and 32767;
	return result;
}
