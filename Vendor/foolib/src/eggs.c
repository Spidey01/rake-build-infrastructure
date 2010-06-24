#include <stdio.h>

void
#ifdef _MSC_VER
__declspec(dllexport)
#endif
eggs(const char *p) {

	printf("eggs and %s\n", p);
}

