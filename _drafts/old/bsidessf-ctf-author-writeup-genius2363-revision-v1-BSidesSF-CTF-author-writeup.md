---
id: 2364
title: 'BSidesSF CTF author writeup'
date: '2019-03-09T15:54:13-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2019/2363-revision-v1'
permalink: '/?p=2364'
---

Hey all,

This is going to be an author's writeup of the BSidesSF 2019 CTF challenge: <tt>genius</tt>!

<tt>genius</tt> is probably my favourite challenge from the year, and I'm thrilled that it was solved by 6 teams! It was inspired by a few other challenges I wrote in the past, including [Nibbler](http://karabut.com/bsides-ctf-2017-nibbler-writeup.html).

It is actually implemented as a pair of programs: [loader](https://blogdata.skullsecurity.org/loader.bz2) and [genius. I only provide the binaries to the players, so it's up to the player to reverse engineer them. Fortunately, for this writeup, we'll have source to reference as needed!](https://blogdata.skullsecurity.org/genius.bz2)

Ultimately, the player is expected to gain code execution by tricking <tt>genius</tt> into running <tt>system("sh;");</tt>, with the help of <tt>loader</tt> (at least, that's how I solved it and that's how others I talked to solved it). A hint to that is given when the game is initially started:

```

$ ./genius 
In case it helps or whatever, system() is at 0x80485e0 and the game object is at 0x804b1a0. :)
```

After that, it starts displaying a Tetris-like commandline game, with the controls 'a' and 'd' to move, 'q' and 'e' to rotate, and 's' to drop the piece to the bottom.

Here's what the game board looks like with the first block (an 'O') falling:

```

+----------+
|          |
|          |
|          |
|          |
|          |
|   **     |
|   **     |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
+----------+
Score: 0
```

And after some blocks fall:

```

+----------+
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|          |
|        * |
|        * |
|       ** |
|   #      |
|   ##     |
|    #     |
|   ##   # |
|   ##  ###|
+----------+
Score: 3000
```

Simple enough! No obvious paths to code execution yet! But... that's where <tt>loader</tt> comes in.

## Loader

When <tt>loader</tt> runs, it asks for a "Game Genius code":

```

$ ./loader
Welcome to the Game Genius interface!
Loading game...
...
Loaded!

Please enter your first Game Genius code, or press <enter> to
continue!
</enter>
```

Some players may guess by the name and format, and others may reverse engineer it, but the codes it wants are classic NES Game Genie codes.

I found an [online code generator written in JavaScript](https://web.archive.org/web/20180803050959/http://www.d.umn.edu/~bold0070/projects/game_genie_codes/javascript_game_genie_encoders-decoders.html) (it's not even online anymore so I linked to the archive.org version) that can generate codes. I only support the 6-character code - no "Key" value.

Interestingly, the code modifies the game *on disk* rather than in-memory. That means that the player has access to change basically anything, including read-only data, ELF headers, import table, and so on. After all, it wouldn't be NES if it had memory protection, right?

So the question is, what do we modify, and to what?

## The code

We're going to look at a bit of assembly now. In particular, the printf-statement at the start where the address of <tt>system</tt> is displayed looks like this:

`<br></br>.text:08049462                 push    offset dword_804B1A0<br></br>.text:08049467                 push    offset _system<br></br>.text:0804946C                 push    offset aInCaseItHelpsO ; "In case it helps or whatever, system() "...<br></br>.text:08049471                 call    _printf<br></br>`

<tt>dword\_804B1A0</tt> is a bit array representing the game board, where each bit is 1 for a piece, and 0 for no piece. <tt>set\_square</tt> and <tt>get\_square</tt> are implemented like this, in the original C:

```

void set_square(int x, int y, int on) {
  int byte = ((y * BOARD_WIDTH) + x) / 8;
  int bit  = ((y * BOARD_WIDTH) + x) % 8;

  if(on) {
    game.board[byte] = game.board[byte] | (1 
<p>As you can see, <tt>game.board</tt> (which is simply <tt>dword_804B1A0</tt>, which we saw earlier) starts are the upper-left, and encodes the board left to right. So the board we saw earlier:</p>

...
|   #      |
|   ##     |
|    #     |
|   ##   # |
|   ##  ###|
+----------+

<p>Is essentially ...0000010000000001100000000010000000011000100001100111 or 0x00...00401802018867. That's not entirely accurate, because each byte is encoded backwards, so we'd have to flip each set of 8 bits to get the actual value, but you get the idea (we won't encode by hand).</p>
<p>After the game ends, the board is cleared out with <tt>memset()</tt>:</p>

.text:08049547                 push    1Ah             ; n
.text:08049549                 push    0               ; c
.text:0804954B                 push    offset dword_804B1A0 ; s
.text:08049550                 call    _memset

<p>There's that board variable again, <tt>dword_804B1A0</tt>!</p>
<p>That _memset call is where we're going to take control. But how?</p>
<h2>The exploit, part 1</h2>
<p>First off, when <tt>memset</tt> is called, it jumps to this little stub in the .plt section:</p>

.plt:08048620                   ; void *memset(void *s, int c, size_t n)
.plt:08048620                   _memset         proc near               ; CODE XREF: main+57p
.plt:08048620                                                           ; main+150p
.plt:08048620 FF 25 30 B0 04 08                 jmp     ds:off_804B030
.plt:08048620                   _memset         endp

<p>That's the .plt section - the Procedure Linkage Table. It's an absolute jump to the address stored at 0x804B030, which is the address of the real <tt>_memset</tt> function once the dynamic library is loaded.</p>
<p>Just above that is <tt>_system()</tt>:</p>
<p>.plt:080485E0                   ; int system(const char *command)<br></br>
.plt:080485E0                   _system         proc near               ; DATA XREF: main+67o<br></br>
.plt:080485E0 FF 25 20 B0 04 08                 jmp     ds:off_804B020<br></br>
.plt:080485E0                   _system         endp</p>
<p>It looks very similar to <tt>_memset()</tt>, except one byte of the address is different - the instruction <tt>FF25<strong>30</strong>B00408</tt> becomes <tt>FF25<strong>20</strong>B00408!</tt></p>
<p>With the first Game Genius code, I change the 0x30 in <tt>memset()</tt> to 0x20 for <tt>system</tt>. The virtual address is 0x08048620, which maps to the in-file address of 0x620 (IDA displays the real address in the bottom-left corner). Since we're changing the third byte, we need to change 0x620 + 2 => 0x622 from 0x30 to 0x20, which effectively changes every call to <tt>memset</tt> to instead call <tt>system</tt>.</p>
<p>Entering 622 and 20 into the online game genie code generator gives us our first code, <strong>AZZAZT</strong>.</p>
<h2>The exploit, part 2
</h2><p>So now, every time the game attempts to call <tt>memset(board)</tt> it calls <tt>system(board)</tt>. The problem is that the first few bits of <tt>board</tt> are quite hard to control (possibly impossible, unless you found another way to use the Game Genius codes to do it).</p>
<p>However, we can change one byte of the instruction <tt>push offset dword_804B1A0</tt>, we can somewhat change the address. That means we can shift the address to somewhere <em>inside</em> the board instead of the start!</p>
<p>Since I have sourcecode access, I can be lazier than players and just set them to see what it'd look like. That way, I can look at putting "sh;" at each offset in the board to see which one would be easiest to build in-game. When I started working on this, I honestly didn't even know if this could work, but it did!</p>
<p>I'll start with the furthest possible value to the right (at the end of the board):</p>

  game.board[BOARD_SIZE-3] = 's';
  game.board[BOARD_SIZE-2] = 'h';
  game.board[BOARD_SIZE-1] = ';';

<p>That creates a board that looks like:</p>

...
|          |
|    ##  ##|
|#    # ## |
|## ###    |
+----------+

<p>That looks like an awfully hard shape to make! So let's try setting the next three bytes towards the start:</p>

  game.board[BOARD_SIZE-4] = 's';
  game.board[BOARD_SIZE-3] = 'h';
  game.board[BOARD_SIZE-2] = ';';
...
|          |
|      ##  |
|###    # #|
|# ## ###  |
|          |
+----------+

<p>That's still a pretty bad shape. How about third from the end?</p>

  game.board[BOARD_SIZE-5] = 's';
  game.board[BOARD_SIZE-4] = 'h';
  game.board[BOARD_SIZE-3] = ';';
...

|          |
|        ##|
|  ###    #|
| ## ## ###|
|          |
|          |
+----------+

<p>That's starting to look like Tetris shapes! I chose that one, and tried to build it.</p>
<p>First, let's see which bytes "matter" - anything before "sh;" will be ignored, and anything after will run after "sh" exits, thanks to the ";" (you can also use "#" or "\0", but fortunately I didn't have to):</p>

...
|          |
|        ##|
|##########|
|##########|
|##        |
|          |
+----------+

<p>All we really care about is setting the 1 and 0 values within that block properly.. nothing else before or after matters at all.:</p>

|          |
|        11|
|0011100001|
|0110110111|
|00        |
|          |
+----------+

<p>If we do a bit of math, we'll know that that value starts 0x15 bytes from the start of board. That means we want to change <tt>push offset dword_804B1A0</tt> to <tt>push offset dword_804B1A0+0x15</tt>, aka <tt>push offset dword_804B1B5</tt></p>
<p>In the binary, here is the instruction (including code bytes):</p>

.text:0804954B 68 A0 B1 04 08                    push    offset dword_804B1A0 ; s
.text:08049550 E8 CB F0 FF FF                    call    _memset

<p>In the first line, we simply want to change 0xA0 to 0xB5. That instruction starts at in-file address 0x154B, and the 0xA0 is one byte from the start, so we want to change 0x154B+1 = 0x154C to 0xB5.</p>
<p>Throwing that address and value into the Game Genie calculator, we get our second code: <strong>SLGOGI</strong></p>
<h2>Playing the game</h2>
<p>All that's left is to play the game. Easy, right?</p>
<p>Fortunately for players (and myself!), I set a static random seed, which means you'll always get the same Tetris blocks in the same order. I literally wrote down the first 20 or so blocks, using <a href="https://tetris.wiki/Tetromino">standard Tetris names</a>. These are the ones that I ended up using, in order: O, S, T, J, O, Z, Z, T, O, Z, T, J, and L</p>
<p>Then I took a pencil and paper, and literally started drawing where I wanted pieces to go. We basically want to have a block where you see a '1' and a space where you see a '0'. Blank spaces can be either, since they're ignored.</p>
<p>Here's our starting state, once again:</p>

|          |
|        <strong>11|
|0011100001|
|0110110111|
|00</strong>        |
|          |
+----------+

<p>Then we get a O block. I'll notate it as "a", since it's the first block to fall:</p>

|          |
|        <strong>11|
|0011100001|
|0110110111|
|00</strong>aa      |
|  aa      |
+----------+

<p>So far, we're just filling in blanks. The next piece to fall is an S piece, which fits absolutely perfectly (and we label as 'b'):</p>

|          |
|        <strong>11|
|00bb100001|
|0bb0110111|
|00</strong>aa      |
|  aa      |
+----------+

<p>Then a T block, 'c', which touches a 1:</p>

|          |
|        <strong>11|
|00bb100001|
|0bb0110c11|
|00</strong>aa   cc |
|  aa   c  |
+----------+

<p>Then J ('d'):</p>

|          |
|        <strong>1d|
|00bb10000d|
|0bb0110cdd|
|00</strong>aa   cc |
|  aa   c  |
+----------+

<p>Then O ('e'):</p>

|          |
|        <strong>1d|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then Z ('f'), which fills in the tip:</p>

|          |
|         f|
|        ff|
|        <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then Z ('g') - here we're starting to throw away pieces, all we need is an L:</p>

|          |
|         f|
| gg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then T ('h'), still throwing away pieces:</p>

|          |
|h         |
|hh       f|
|hgg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then O ('i'), throw throw throw:</p>

|          |
|h ii      |
|hhii     f|
|hgg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then Z ('j'), thrown away:</p>

|          |
|         j|
|h ii    jj|
|hhii    jf|
|hgg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then T ('k'), thrown away:</p>

|          |
|        k |
|        kk|
|        kj|
|h ii    jj|
|hhii    jf|
|hgg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>Then J ('m'):</p>

|          |
| m      k |
| m      kk|
|mm      kj|
|h ii    jj|
|hhii    jf|
|hgg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>And finally, the L we needed to finish the last part of the puzzle ('o'):</p>

|          |
| m      k |
| m      kk|
|mm      kj|
|h ii    jj|
|hhii    jf|
|hgg     ff|
|  ggo   <strong>fd|
|00bbo0000d|
|0bb0oo0cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+

<p>I literally drew all that <a href="https://lh3.googleusercontent.com/XP_NGHWbr6rxMZIf_sXePMzNOPj_fMq5Gs22GBtgkfUcUJmqQAZj9CUgFNVefQ2LOzEktQw-O5gY_deSk0-k6IXD8uGQnClvOtakz5A0NyzcxFNQYoE70CzVsVoxg3Uw6vsn5rGIZKXGjFFhtKKH6GvAMzc_vbB8DulmfXCpjNwsM8gu2LG6KGD0AHPF3HhdqyyTs5EH5C9EUeFgphtI-4-lzWjEdbYUbm5YzH6EfSqMs3h7lfBeArDF-cIBomXrlpoix9ox0BTKlCAS4Ygnox458YD74ECoTXpvCC0jAPE0Vq-KnpK81pjaXWQdYUgyorJ3xIho2EQJ724K9Xk3OpfZgYTeHAtzKRcy8EXB3tU0vsdvS-GY5kbEl38N7Qnx1f20nxCwEHmCEVmDGtvPlJOwvXVhTJbql_en8PCzsgIY5Ctix__9YVpRGx-F3iJOfQUvxVuNw6P8TQmpAV7UpDgAK7ipRh7tr__B7BFtFsrcOj1XQzUpctnebxGAmWk30aekgrXskkfiQ-dxexjj7U29KrHhpv3KZzUOQEtKPSgorIukE3mZ65cBvVDeNl7CsEPyYJ_tkTSIyFPJp7RQMGckk-0N2oSKZ-hMIvRdX-UxHHMeBHGv9ZWeEB0w68EwnbiPpvXzJqdB2ytUVQ1PtClF8givdWNr=w974-h1297-no">on paper</a>, erasing and moving stuff as needed to get the shape right. Once I had the shape, I figured out the inputs that would be required by literally playing:</p>
```

- as
- qaas
- eddds
- qdddds
- ds
- ddddds
- qaas
- eaaaas
- as
- ddddds
- edddds
- aaaaas
- eas

Followed by 's' repeated to drop every piece straight down until the board fills up and the game ends.

## To summarize

So here is the exploit, in brief!

Run <tt>./loader</tt> in the same folder as <tt>genius</tt> (or user the Dockerfile).

Enter code 1, AZZAZT, which changes <tt>memset</tt> into <tt>system</tt>

Enter code 2, SLGOGI, which changes <tt>system(board)</tt> to <tt>system(board+0x15)</tt>

Play the game, and enter the list of inputs shown just above.

When the game ends, like magic, a shell appears!

```

+----------+
|    *     |
|   *#*    |
|   ###    |
|   ##     |
|   ##     |
|    #     |
|   ##     |
|   #      |
|   ####   |
|     #    |
|   ###  # |
|#  #    ##|
|#####   ##|
|# ###   ##|
|####    ##|
|###     ##|
|  ###   ##|
|  ###    #|
| ## ## ###|
|  #### ## |
|  #### #  |
+----------+
$ pwd
/home/ron/projects/ctf-2019/challenges/genius/challenge/src
$ ls
blocks.h  genius  genius.c  genius.o  loader  loader.c  loader.o  Makefile
```

And there you have it!