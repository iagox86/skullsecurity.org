---
id: 2455
title: 'BSidesSF CTF: Hard reversing challenge: Chameleon'
date: '2020-02-26T13:11:20-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2455
permalink: "/2020/bsidessf-ctf-hard-reversing-challenge-chameleon"
categories:
- conferences
- crypto
- ctfs
- re
comments_id: '109638378881689926'

---

For my third and final blog post about the BSidesSF CTF, I wanted to cover the solution to Chameleon. Chameleon is loosely based on a <a href="https://2019.kringlecon.com/">KringleCon challenge I wrote</a> (<a href="https://www.youtube.com/watch?v=obJdpKDpFBA">video guide</a>), which is loosely based on a real-world penetration test from a long time ago. Except that Chameleon is much, much harder than either.
<!--more-->
Chameleon (<a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/chameleon/challenge/client/src/chameleon.cpp">source</a>), at its core, is a file encryption / decryption utility with an escrow component.

To encrypt a file, the client generates a cryptographic key based on the current time (uh oh!), encrypts the document, then sends the key to an escrow server, which returns an id. To decrypt the file, you send the id to the escrow server, and it returns the encryption key.

The challenge provides an encrypted document with no id, and it's up to the player to find the flaw and decrypt it.

There are really two challenges here (not counting finding a Windows box to run this on):

<ol>
<li>Reverse engineer the key generation code to determine how keys are generated</li>
<li>Bruteforce the key quickly enough to actually discover the key - non-trivial, since the file is large!</li>
</ol>

The key generation code uses a variation of the Mersenne Twister that I like to call, "bad Mersenne Twister". It's created by taking a <a href="http://www.ai.mit.edu/courses/6.836-s03/handouts/sierra/random.c">Mersenne Twister I found online</a>, and changing some constants to make it harder to Google (and probably also making it less secure). Here's my implementation:

<pre>
#define N 351
#define M 175
#define R 19
#define TEMU 11
#define TEMS 7
#define TEMT 15
#define TEML 17
#define MATRIX_A 0xE4BD75F5
#define TEMB     0x655E5280
#define TEMC     0xFFD58000
static unsigned long mt[N];                 // state vector
static int mti=N;

void mysrand (int seed) {
  unsigned long s = (unsigned long)seed;
  for (mti=0; mti<N; mti++) {
    s = s * 29945647 - 1;
    mt[mti] = s;
  }
  return;
}

int myrand () {
  // generate 32 random bits
  unsigned long y;

  if (mti >= N) {
    // generate N words at one time
    const unsigned long LOWER_MASK = (1u << R) - 1; // lower R bits
    const unsigned long UPPER_MASK = -1 << R;       // upper 32-R bits
    int kk, km;
    for (kk=0, km=M; kk < N-1; kk++) {
      y = (mt[kk] & UPPER_MASK) | (mt[kk+1] & LOWER_MASK);
      mt[kk] = mt[km] ^ (y >> 1) ^ (-(signed long)(y & 1) & MATRIX_A);
      if (++km >= N) km = 0;}

    y = (mt[N-1] & UPPER_MASK) | (mt[0] & LOWER_MASK);
    mt[N-1] = mt[M-1] ^ (y >> 1) ^ (-(signed long)(y & 1) & MATRIX_A);
    mti = 0;}

  y = mt[mti++];

  // Tempering (May be omitted):
  y ^=  y >> TEMU;
  y ^= (y << TEMS) & TEMB;
  y ^= (y << TEMT) & TEMC;
  y ^=  y >> TEML;

  return y & 0x0ff;
}
</pre>

That's just a pure reversing challenge, so I don't really have much else to say.

The next bit is what I find interesting: I very intentionally a) made the file quite large, but also with an obvious header (a 3.5mb PNG image), and b) didn't tell the player when the file was encrypted. As a result, if you assumed that the file was encrypted in the last 3-4 months, you're looking at 10,000,000+ possible keys. That's a bit much, if you're decrypting 3.5mb each time!

The trick is, you only have to decrypt the first block (and ignore padding errors), then check for the PNG header. That means you can have a reasonable chance of validating the decrypted file by only decrypting 16 bytes! I called that <tt>sample</tt> in my solution.

I'm somewhat embarrassed of <a href="https://github.com/BSidesSF/ctf-2020-release/tree/master/chameleon/solution">my solution</a>.. I generated 86,400 keys, for the full day, using a <a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/chameleon/solution/solve.cpp">CPP file where I copied over the PRNG code</a>, then tried each one using a <a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/chameleon/solution/solve.rb">Ruby script</a>. I can check a day's worth of keys in less than a second, so I concluded that a person could reasonably bruteforce a year's worth in just a few minutes.

(It looks like I hardcoded the correct key in the release - oops! Just disable the line that sets the key statically if you want to solve it for real)

Once it has the correct key, it outputs the PNG file:

<pre>
$ ruby ./solve.rb ../distfiles/flag.png.enc ./keys-for-today.txt | file -
Key: a051b8a16f8542da
/dev/stdin: PNG image data, 4000 x 884, 8-bit/color RGBA, non-interlaced
</pre>

Note that it's intentionally created in such a way to make a very large file. That wasn't an accident!
