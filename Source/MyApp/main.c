/*
 * super simple program
 */

#include "util.h"

#include <stdlib.h>
#include <stdio.h>

#include <foolib/ham.h>
#include <foolib/spam.h>
#include <foolib/eggs.h>

#include <MyLib/msg.h>

int
main(int argc, char *argv[]) {
	int i;

	if (argc < 2)
		usage();

	for (i=0; i < argc; ++i) {
		char *p = argv[i];

		mylib_msg("Here is a little message...\n");
		print_banner();
		ham(p);
		spam(p);
		eggs(p);
		print_banner();
	}

	return EXIT_SUCCESS;
}
