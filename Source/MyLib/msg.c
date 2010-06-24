#include <stdio.h>

void
#ifdef _MSC_VER
__declspec(dllexport)
#endif
mylib_msg(const char *p) {

	printf(p);
}
