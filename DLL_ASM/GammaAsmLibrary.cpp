#include "pch.h"
#include "GammaLibrary.h"

GAMMALIBRARY_API void __cdecl gammaAVX(unsigned char* tab, double gammaVal, int it)
{
	gammaAVXasm(tab, gammaVal, it);
}



