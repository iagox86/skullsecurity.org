---
title: 'BSidesSF 2025: Miscellaneous challenges'
author: ron
layout: post
categories:
- bsidessf-2025
- ctfs
permalink: "/2025/bsidessf-2025-miscellaneous-challenges"
date: '2025-04-27T15:59:18-07:00'

---

In this post, I'm going to do write-ups for a few challenges that don't really meaningfully categorize.

As usual, you can find the code and complete solutions on our [GitHub repo](https://github.com/BSidesSF/ctf-2025-release)!

<!--more-->

## `your-browser-hates-you`

For this challenge, I created an SSL server with a certificate, then changed parts of the cert until the browser stopped being able to display it. That's it!

My original idea was supposed to use a self-signed cert and HSTS to block access, but I couldn't get that to work how I wanted.

The solution it to use something that doesn't validate certs, like `curl -k`:

```
$ curl -k 'https://your-browser-hates-you-4a61071d.challenges.bsidessf.net/'
[...]
        <p><font color="blue">Flag: CTF{shh-its-a-secret}</font></p>
```

## `goto-zero`

This challenge was a bit of a treat for people that read my blog, because I already [published a write-up](g/2024/goto-zero-a-fake-ctf-challenge-to-show-off-something).

I basically took that challenge, and made it work as a terminal challenge, rather than remote, so the user can find their own `libc` functions without me giving it to them.

Other than that, and some offsets changing, the solution is pretty much the same!

## `obscuratron`

Obscuratron is supposed to be a dirt-easy reversing challenge. Each character in the file is xored with the previous character, starting with a seed value.

The source code:

```c
  int current_character = fgetc(stdin) ^ KEY;
  int next_character;
  putchar(current_character);
  for(next_character = fgetc(stdin); next_character >= 0; current_character = next_character, next_character = fgetc(stdin)) {
    next_character = current_character ^ next_character;
    putchar(next_character);
  }
```

And the solution:

```
key = 0xab
decrypted = (encrypted.bytes.map do |i|
  decrypted = (i ^ key)
  key = i
  decrypted.chr
end).join
```

## `go-back`

`go-back` is one of my favourites, it's kind of a puzzle challenge! It's based on a challenge on Smash the Stack's `io` wargame from years ago, which doesn't see to exist anymore.

The code is dirt simple, but doesn't have any obvious issues:

```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
void main(int argc, char *argv[])
{
  FILE *f= fopen("flag.txt", "r");
  if(!f) {
    printf("Couldn't open flag file!\n");
    perror("fopen");
    exit(1);
  }
  char flag[32];
  fgets(flag, 32, f);
  fclose(f);
  if(argc != 2) {
    printf("Oops!\n");
    exit(1);
  }
  // no timing attacks!! seriously
  usleep(rand() % 1000);
  if(!strcmp(flag, argv[1])) {
    printf("Yay!\n");
  }
}
```

The issue is actually pretty nifty: since `main()` is a void function, the C compiler doesn't care what it returns, so it just ignores the return value.

The OS, however, *does* about the return value, so it will look at whatever happens to be in `rax` (the register that typically carries a return value). Since `main()` doesn't return anything, the behaviour is undefined (meaning the compiler washes its hands of it).

But what ends up happening is that the return value from the last function called - `strcmp()` - gets implicity returned, and the exit code for the process is the last byte of the exit code for `strcmp()`. Based on that exit code, you can recreate the `flag` string one character at a time.

Neat!
