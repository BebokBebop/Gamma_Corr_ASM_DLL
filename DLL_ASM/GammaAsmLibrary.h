#pragma once

#ifdef GAMMALIBRARY_EXPORTS
#define GAMMALIBRARY_API __declspec(dllexport)
#else
#define GAMMALIBRARY_API __declspec(dllimport)
#endif

extern "C" GAMMALIBRARY_API void __cdecl gammaAVX(unsigned char* tab, double gammaVal, int it);

extern "C" void gammaAVXasm(unsigned char*, double, int);
