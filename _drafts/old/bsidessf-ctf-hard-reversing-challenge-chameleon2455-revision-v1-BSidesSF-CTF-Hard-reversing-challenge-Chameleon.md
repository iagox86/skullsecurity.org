---
id: 2464
title: 'BSidesSF CTF: Hard reversing challenge: Chameleon'
date: '2020-02-26T13:10:55-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2020/2455-revision-v1'
permalink: '/?p=2464'
---

For my third and final blog post about the BSidesSF CTF, I wanted to cover the solution to Chameleon. Chameleon is loosely based on a [KringleCon challenge I wrote](https://2019.kringlecon.com/) ([video guide](https://www.youtube.com/watch?v=obJdpKDpFBA)), which is loosely based on a real-world penetration test from a long time ago. Except that Chameleon is much, much harder than either.  
  
Chameleon ([source](https://github.com/BSidesSF/ctf-2020-release/blob/master/chameleon/challenge/client/src/chameleon.cpp)), at its core, is a file encryption / decryption utility with an escrow component.

To encrypt a file, the client generates a cryptographic key based on the current time (uh oh!), encrypts the document, then sends the key to an escrow server, which returns an id. To decrypt the file, you send the id to the escrow server, and it returns the encryption key.

The challenge provides an encrypted document with no id, and it's up to the player to find the flaw and decrypt it.

There are really two challenges here (not counting finding a Windows box to run this on):

1. Reverse engineer the key generation code to determine how keys are generated
2. Bruteforce the key quickly enough to actually discover the key - non-trivial, since the file is large!

The key generation code uses a variation of the Mersenne Twister that I like to call, "bad Mersenne Twister". It's created by taking a [Mersenne Twister I found online](http://www.ai.mit.edu/courses/6.836-s03/handouts/sierra/random.c), and changing some constants to make it harder to Google (and probably also making it less secure). Here's my implementation:

```

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
  for (mti=0; mti<n bits="" generate="" if="" int="" long="" mt="" mti="" myrand="" random="" return="" s="s" unsigned="" y="">= N) {
    // generate N words at one time
    const unsigned long LOWER_MASK = (1u > 1) ^ (-(signed long)(y & 1) & MATRIX_A);
      if (++km >= N) km = 0;}

    y = (mt[N-1] & UPPER_MASK) | (mt[0] & LOWER_MASK);
    mt[N-1] = mt[M-1] ^ (y >> 1) ^ (-(signed long)(y & 1) & MATRIX_A);
    mti = 0;}

  y = mt[mti++];

  // Tempering (May be omitted):
  y ^=  y >> TEMU;
  y ^= (y > TEML;

  return y & 0x0ff;
}
</n>
```

That's just a pure reversing challenge, so I don't really have much else to say.

The next bit is what I find interesting: I very intentionally a) made the file quite large, but also with an obvious header (a 3.5mb PNG image), and b) didn't tell the player when the file was encrypted. As a result, if you assumed that the file was encrypted in the last 3-4 months, you're looking at 10,000,000+ possible keys. That's a bit much, if you're decrypting 3.5mb each time!

The trick is, you only have to decrypt the first block (and ignore padding errors), then check for the PNG header. That means you can have a reasonable chance of validating the decrypted file by only decrypting 16 bytes! I called that <tt>sample</tt> in my solution.

I'm somewhat embarrassed of [my solution](https://github.com/BSidesSF/ctf-2020-release/tree/master/chameleon/solution).. I generated 86,400 keys, for the full day, using a [CPP file where I copied over the PRNG code](https://github.com/BSidesSF/ctf-2020-release/blob/master/chameleon/solution/solve.cpp), then tried each one using a [Ruby script](https://github.com/BSidesSF/ctf-2020-release/blob/master/chameleon/solution/solve.rb). I can check a day's worth of keys in less than a second, so I concluded that a person could reasonably bruteforce a year's worth in just a few minutes.

(It looks like I hardcoded the correct key in the release - oops! Just disable the line that sets the key statically if you want to solve it for real)

Once it has the correct key, it outputs the PNG file:

```

$ ruby ./solve.rb ../distfiles/flag.png.enc ./keys-for-today.txt | file -
Key: a051b8a16f8542da
/dev/stdin: PNG image data, 4000 x 884, 8-bit/color RGBA, non-interlaced
```

Note that it's intentionally created in such a way to make a very large file. That wasn't an accident!