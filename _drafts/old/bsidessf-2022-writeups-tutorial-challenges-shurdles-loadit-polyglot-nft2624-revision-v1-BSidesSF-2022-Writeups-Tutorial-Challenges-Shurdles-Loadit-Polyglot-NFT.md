---
id: 2645
title: 'BSidesSF 2022 Writeups: Tutorial Challenges (Shurdles, Loadit, Polyglot, NFT)'
date: '2022-06-17T15:19:00-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/?p=2645'
permalink: '/?p=2645'
---

Hey folks,

This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything [on github](https://github.com/bsidessf/ctf-2022-release). Most have either a Dockerfile or instructions on how to run locally. Enjoy!

Here are the four BSidesSF CTF blogs:

- [shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft)
- [mod\_ctfauth, refreshing](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh)
- [turtle, guessme](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme)
- [loca, reallyprettymundane](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane)

## Shurdles - Shellcode Hurdles

The [*Shurdles*](https://github.com/BSidesSF/ctf-2022-release/tree/main/shurdles-1) challenges are loosely based on a challenge from last year, `Hurdles`, as well as a [Holiday Hack Challenge 2021](https://www.holidayhackchallenge.com/2021/) challenge I wrote called *Shellcode Primer*. It uses a tool I wrote called [Mandrake](https://github.com/iagox86/mandrake) to instrument shellcode to tell the user what's going on. It's helpful for debugging, but even more helpful as a teaching tool!

The difference between this and the Holiday Hack version was that this time, I didn't bother to sandbox it, so you could pop a shell and inspect the box. I'm curious if folks did that.. probably they couldn't damage anything, and there's no intellectual property to steal. :)

I'm not going to write up the solutions, but I did include solutions in [the repository](https://github.com/BSidesSF/ctf-2022-release).

Although I don't work for Counter Hack anymore, a MUCH bigger version of this challenge that I wrote is included in the SANS NetWars version launching this year. It covers a huge amount, including how to write bind- and reverse-shell shellcode from scratch. It's super cool! Unfortunately, I don't think SANS is doing hybrid events anymore, but if you find yourself at a SANS event be sure to check out NetWars!

## Loadit - Learning how to use `LD_PRELOAD`

I wanted to make a few challenges that can be solved with `LD_PRELOAD`, which is where [loadit](https://github.com/BSidesSF/ctf-2022-release/tree/main/loadit1) came from! These are designed to be tutorial-style, so I think [the solutions](https://github.com/BSidesSF/ctf-2022-release/tree/main/loadit1/solution) mostly speak for themselves.

One interesting tidbit is that the third `loadit` challenge requires some state to be kept - `rand()` needs to return several different values. I had a few folks ask me about that, so I'll show off my solution here:

```c
#include <unistd.h>

int rand(void) {
  int answers[] = { 20, 22, 12, 34, 56, 67 };
  static int count = 0;

  return answers[count++];
}

// Just for laziness
unsigned int sleep(unsigned int seconds) {
  return 0;
}
```

I use the [static variable type](https://www.geeksforgeeks.org/static-variables-in-c/) to keep track of how many times rand() has been called. When you declare something as `static` inside a function, it means that the variable is initialized the first time the function is called, but changes are maintained as if it's a global variable (at least conceptually - in reality, it's initialized when the program is loaded, even if the function is never called).

Ironically, this solution actually has an overflow - the 7th time and onwards `rand()` is called, it will start manipulating random memory. Luckily, we know that'll never happen. :)

## Polyglot - Technically correct!

Polyglot claims to be a polyglot. It's distributed as a .exe file. It runs fine-ish under `wine`:

```
$ wine ./polyglot.exe
Figure out the polyglot and enter the key here --> hello
?YCd;??x?'B???)1???R7?e-?8????*#?????R?w
```

If you look at the source, it'll be pretty obvious that it's XORing a 40-character key, provided by the user, with a 40-character "encrypted" string. If you make the logical assumption that the flag is `CTF{...36 characters…}`, you will find that the key is, `This????????????????????????????????????.`. That might be a hint!

So it turns out that every PE file (`*.exe`) is actually a Polyglot - it's an [MZ executable](https://en.wikipedia.org/wiki/DOS_MZ_executable) with a [PE executable](https://en.wikipedia.org/wiki/Portable_Executable) glued on. When you run the executable on Windows, it runs the PE portion, but when you run on DOS (or [DOSBox](https://www.dosbox.com/)), it runs on the MZ portion.

If you run it in DOS mode, you'll instantly see the answer:

```
c:\> POLYGLOT.EXE
The password is: "This program cannot be run in DOS mode."
```

It's a bit of a troll, but easy enough to solve. :)

In case you're curious, here's the header:

```asm
$ cat stub.asm 
ORG 0h ;# Offset 0, for NASM

push cs
pop ds

call thepasswordis
  ; db "The password is: '$"
  db 0xab, 0x97, 0x9a, 0xdf, 0x8f, 0x9e, 0x8c, 0x8c, 0x88, 0x90, 0x8d, 0x9b, 0xdf, 0x96, 0x8c, 0xc5, 0xdf, 0xdd, 0xdb, 0

thepasswordis:
pop dx
mov cx, dx

decoder_top:
  cmp byte [ecx], 0
  je decoder_bottom
  xor byte [ecx], 0xff
  inc cx
  jmp decoder_top

decoder_bottom:
mov ah, 09
int 0x21

call cannotberun
  db "This program cannot be run in DOS mode.$", 0

cannotberun:
pop dx
mov ah, 09
int 0x21

dec cx
dec cx
mov dx, cx
mov ah, 09
int 0x21

; # terminate the program
mov ax,0x4c01
int 0x21
```

If you did Shurdles (see above), some of that will be familiar! Then I just used a [small Ruby script](https://github.com/BSidesSF/ctf-2022-release/blob/main/shurdles-1/challenge/src/app.rb) to replace the start of the executable.

If you're interested in the PE format, be sure to check out [the writeup for Loca](TODO)!

## Not for taking

*Not for taking* - or *NFT* - is just a joke challenge. It's a photo of my bird, with the flag embedded in the image like a caption. But! - the image is cropped by CSS so you can't see the flag, AND right clicking is disabled. So you have to view source (ctrl-u) or use developer tools (F12) or.. like 100 other ways to get it.