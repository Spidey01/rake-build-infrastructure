#include <stdio.h>

void
#ifdef _MSC_VER
__declspec(dllexport)
#endif
spam(const char *p) {

	printf("spam and %s\n", p);
}

