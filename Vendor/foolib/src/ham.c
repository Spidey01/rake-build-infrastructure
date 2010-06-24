#include <stdio.h>

void
#ifdef _MSC_VER
__declspec(dllexport)
#endif
ham(const char *p) {

	printf("Ham and %s\n", p);
}

