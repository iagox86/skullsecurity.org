---
id: 1550
title: 'CNOT Writeup'
date: '2013-04-24T23:06:27-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/2013/1512-revision-37'
permalink: '/?p=1550'
---

<style type="text/css">
<!--
pre { white-space: pre-wrap; font-family: monospace; color: #839496; background-color: #002b36; }
tt { font-family: monospace; color: #839496; background-color: #002b36; }
.lnr { color: #586e75; background-color: #073642; }
.Type { color: #b58900; }
.Comment { color: #586e75; font-style: italic; }
.Special { color: #dc322f; }
.Statement { color: #719e07; }
.Constant { color: #2aa198; }
.Identifier { color: #268bd2; }
.rubyDefine { color: #93a1a1; background-color: #002b36; font-weight: bold; }
-->
</style></head><body>When I was at Shmoocon, I saw a talk about how to write an effective capture-the-flag contest. One of their suggestions was to have a tar-pit challenge that would waste all the time of the best player, by giving him a complicated challenge he won't be able to resist. In my opinion, in [PlaidCTF](http://www.plaidctf.com/), I suspected that "cnot" was that challenge. And I was the sucker, even though I knew it all the way...

(It turns out, after reviewing writeups of other challenges, that most of the challenges were like this; even so, I'm proud to have been sucked in!)

If you want a writeup where you can learn something, I plan to post a writeup for "Ropasaurus" in the next day or two. If you want a writeup about me being tortured as I fought through inconceivable horrors to finish a level and capture the bloody flag, read on! This level wasn't a lot of learning, just brute-force persistence.

It's worthwhile to note that I'm not going to cover every piece or every line—maybe I'll do that as a novel in the future—this is mostly going to be a summary. Even so, this is going to be a *long* writeup. I'm trying to make it interesting and fun to read, and to break it into shorter sections. But heed this warning!

Also, I may switch between "I" and "we" throughout the writeup. This indicates when I was being helped by somebody, when I was alone, and when I was simply going insane. I'm pretty sure the voices in my head helping with a solution are a good enough reason to say "we" instead of "I", right?

Now that the contest is over, [the source](https://gist.github.com/5449611) has been released. Here's the command they used for compiling it, directly from that source:

```

<span class="lnr">1 </span><span class="Comment">// compile with:</span>
<span class="lnr">2 </span><span class="Comment">// isildur cnot.c0 -l l4rt.h0 -o test.s --obfuscate --anti-debug --confuse</span>
<span class="lnr">3 </span><span class="Comment">// gcc test.s obf.c -o cnot</span>
<span class="lnr">4 </span><span class="Comment">// strip cnot</span>
```

<tt>--obfuscate</tt>, <tt>--anti-debug</tt>, *and* <tt>--confuse</tt>? Awww, you shouldn't have! But, I digress. I didn't have this info back then...

Being that I fancy myself a reverse engineer, this level appealed to me right away. In fact, it's the first one I looked at, despite it being the highest point value. Go big or go home!

I spent about fifteen minutes poking around. I determined that the binary was ugly as sin, that the debugger didn't work, and that it was 64-bit Intel assembly. Well fuck, I don't even *know* x64 (well, I didn't when I started this CTF, at least). So I gave up and moved onto another level, Ropasaurus (which will have its own writeup).

After solving a some other levels with the help of HikingPete (Ropasaurus, Cyrpto, and charsheet), I came back to cnot late Friday night. [Mak](https://www.twitter.com/mogigoma) and [Nate](:https://www.twitter.com/nateloaf:) had put several hours into it and had given up. It was all up to me.

Let's start by summarizing the weekend...

Work on it till 6am. Wake up at 9am. Work on another problem for a couple hours, return to cnot by noon. Work solid—besides a meal—till 6am again. Getting so close, but totally stuck.

Wake up early again, go straight to it. 9am I think? Stuck, so stuck. Came up with ideas, failed, more ideas, failed failed failed. Finally, thought of something. Can it work...? IT DID! FLAG OBTAINED!! Hardest binary I've ever reversed, and I was suddenly an expert on x64! Done by 2pm, too! That means I only spent.. *thirty* hours? Is that right? Dear lord...

And you know what the kicker is? Even without the obfuscation, without the anti-debugging, and without the... confusion? This still would have been a goddamn hard binary! Hell, take a look at the [C version](https://gist.github.com/5449611). Even that would have been a huge pain!

But now I'm definitely getting ahead of myself. The rest of this document will be about what worked, I don't explore too many of the 'wrong paths' I took, except where it's pedagogical to do so.

## The setup

Basically, we had a 64-bit Linux executable file, and no hints of any kind. I fired up a Debian 6.0.7 machine with basically default everything, except that I installed my favourite dev/reversing tools that you'll see throughout this writeup. I also had a Windows machine with a modern version of [IDA Pro](https://www.hex-rays.com/products/ida/index.shtml). If you plan to do any reversing, you *need* IDA Pro. The free version works for most stuff, but modern versions are way faster and handle a lot more madness.

You run the program, it simply asks for a password. You type in something, and it generally says "Wrong!" and ends:

```

<span class="lnr">1 </span><span class="perlVarPlain">ron@debian-x86</span> ~<span class="Statement">/</span><span class="Constant">cnot </span><span class="perlVarPlain">$</span><span class="Constant"> </span><span class="Special">.</span><span class="Statement">/c</span>not
<span class="lnr">2 </span>Please enter your password: hello
<span class="lnr">3 </span>Wrong!
```

The goal was to figure out the password for this executable, which was the flag.

And that's our starting point. So far so good!

At this point, I had a lot of ideas. Sometimes, you start with the error message, work your way back to a comparison, and look at what's being compared to what. Sometimes, you start with the input and look at how it's being mangled. Or sometimes, you quietly sob in the corner. I tried the first two approaches at the start, and then steadily moved on to the last.

## Wasted effort

Mak and Nate had started working on the project without me, and Mak had started writing a timing-attack tool. Sometimes, if one letter is compared at a time, you can derive each letter individually by timing the comparisons and looking at which one is the fastest. That could save a ton of reversing time!

[If I'd known then what I know now](http://i.imgur.com/bj4TF0y.jpg), I wouldn't have bothered. This had no hope of working. But it was worth a shot!

I helped Mak finish a program that would:

- Choose a letter
- Write it to a file
- Start a high resolution timer (using [rdtsc](https://en.wikipedia.org/wiki/Time_Stamp_Counter), which counts the number of cycles since reset)
- Run the process
- Read the timer state
- Repeat for each letter, choose the best
- Go back to the top and choose another letter

This works exceptionally well, in some cases. This was not one of the cases. It turns out that the letters were validated with a checksum first, which instantly breaks it. Then they were validated out of order, and in various other ways, all of which would break this. So, long story short, it was a waste of our time.

Luckily, after an hour or two, I said "this isn't working" and we moved on without ever looking back.

## Anti-debugging

Our first step was anti-debugging, because this:

```

<span class="lnr">1 </span><span class="perlVarPlain">$</span> gdb ./cnot
<span class="lnr">2 </span>Reading symbols from <span class="Statement">/</span><span class="Constant">home</span><span class="Statement">/</span>ron/cnot/cnot...(<span class="Statement">no </span>debugging symbols found)...done.
<span class="lnr">3 </span>(gdb) run hello
<span class="lnr">4 </span>Starting program: <span class="Statement">/</span><span class="Constant">home</span><span class="Statement">/</span>ron/cnot/cnot hello
<span class="lnr">5 </span>
<span class="lnr">6 </span>Program received signal SIGSEGV, Segmentation fault.
<span class="lnr">7 </span><span class="Constant">0x00400b86</span> in ?? ()
<span class="lnr">8 </span>
```

You assholes! If you run it with strace, you'll see this:

```

<span class="lnr">1 </span>trace ./cnot <span class="Constant">2</span>>&<span class="Constant">1</span> | tail -n4
<span class="lnr">2 </span>  munmap(<span class="Constant">0x7f5cc9159000</span>, <span class="Constant">63692</span>)           = <span class="Constant">0</span>
<span class="lnr">3 </span>  ptrace(PTRACE_TRACEME, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>)         = -1 EPERM (Operation <span class="Statement">not</span> permitted)
<span class="lnr">4 </span>  --- SIGSEGV (Segmentation fault) @ <span class="Constant">0</span> (<span class="Constant">0</span>) ---
<span class="lnr">5 </span>  +++ killed by SIGSEGV (core dumped) +++
<span class="lnr">6 </span>
```

So it's calling [ptrace](https://en.wikipedia.org/wiki/Ptrace) right before dying, eh? Well, I know how to deal with that! Mak wrote a quick library:

```

<span class="lnr">1 </span>  ron@debian-x64 ~/cnot $ <span class="Statement">echo</span> <span class="Statement">'</span><span class="Constant">long ptrace(int a, int b, int c){return 0;}</span><span class="Statement">'</span> <span class="Statement">></span> override.c
<span class="lnr">2 </span>  ron@debian-x64 ~/cnot $ gcc <span class="Special">-shared</span> <span class="Special">-fPIC</span> <span class="Special">-o</span> override.so ./override.c
```

Add it to our gdbinit file:

```

<span class="lnr">1 </span>$ <span class="Statement">cat</span> gdbinit
<span class="lnr">2 </span><span class="Comment"># Set up the environment</span>
<span class="lnr">3 </span><span class="Statement">set</span> disassembly-flavor intel
<span class="lnr">4 </span><span class="Statement">set</span> confirm off
<span class="lnr">5 </span>
<span class="lnr">6 </span><span class="Comment"># Disable the anti-debugging</span>
<span class="lnr">7 </span><span class="Statement">set</span> environment LD_PRELOAD ./overload.so
```

And run the program with that gdbinit file:

```

<span class="lnr">1 </span><span class="perlVarPlain">$</span> gdb <span class="Statement">-x</span> ./gdbinit ./cnot
<span class="lnr">2 </span>Reading symbols from <span class="Statement">/</span><span class="Constant">home</span><span class="Statement">/</span>ron/cnot/cnot...(<span class="Statement">no </span>debugging symbols found)...done.
<span class="lnr">3 </span>(gdb) run
<span class="lnr">4 </span>Please enter your password: hello
<span class="lnr">5 </span>Wrong!
<span class="lnr">6 </span>
<span class="lnr">7 </span>Program exited normally.
<span class="lnr">8 </span>
```

Thankfully, that was the only anti-debugging measure taken. gdbinit files are actually something I learned from Mak while working on the [IO Wargame](http://io.smashthestack.org:84/), and are one of the most valuable tools in your debugging arsenal!

## First steps

First of all, let's take a look at the imports; this can be done more easily in IDA, but to avoid filling this writeup with screenshots, I'll use [objdump](https://en.wikipedia.org/wiki/Objdump) to get the equivalent information:

```

<span class="lnr"> 1 </span><span class="perlVarPlain">ron@debian-x86</span> ~<span class="Statement">/</span><span class="Constant">cnot </span><span class="perlVarPlain">$</span><span class="Constant"> objdump -R cnot</span>
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span><span class="Constant">cnot:     file format elf64-x86-64</span>
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span><span class="Constant">DYNAMIC RELOCATION RECORDS</span>
<span class="lnr"> 6 </span><span class="Constant">OFFSET           TYPE              VALUE</span>
<span class="lnr"> 7 </span><span class="Constant">006101b8 R_X86_64_GLOB_DAT   __gmon_start__</span>
<span class="lnr"> 8 </span><span class="Constant">00610240 R_X86_64_COPY       stdin</span>
<span class="lnr"> 9 </span><span class="Constant">00610250 R_X86_64_COPY       stdout</span>
<span class="lnr">10 </span><span class="Constant">006101d8 R_X86_64_JUMP_SLOT  __isoc99_fscanf</span>
<span class="lnr">11 </span><span class="Constant">006101e0 R_X86_64_JUMP_SLOT  exit</span>
<span class="lnr">12 </span><span class="Constant">006101e8 R_X86_64_JUMP_SLOT  __libc_start_main</span>
<span class="lnr">13 </span><span class="Constant">006101f0 R_X86_64_JUMP_SLOT  ungetc</span>
<span class="lnr">14 </span><span class="Constant">006101f8 R_X86_64_JUMP_SLOT  fputc</span>
<span class="lnr">15 </span><span class="Constant">00610200 R_X86_64_JUMP_SLOT  fgetc</span>
<span class="lnr">16 </span><span class="Constant">00610208 R_X86_64_JUMP_SLOT  ptrace</span>
<span class="lnr">17 </span><span class="Constant">00610210 R_X86_64_JUMP_SLOT  raise</span>
<span class="lnr">18 </span><span class="Constant">00610218 R_X86_64_JUMP_SLOT  calloc</span>
<span class="lnr">19 </span><span class="Constant">00610220 R_X86_64_JUMP_SLOT  feof</span>
<span class="lnr">20 </span><span class="Constant">00610228 R_X86_64_JUMP_SLOT  fprintf</span>
```

<tt>fputc()</tt> and <tt>fgetc()</tt> were the ones I was most interested in. To make a long story short, we put a breakpoint on <tt>fputc()</tt> to see when it was called. It was called twice for each character. Once—at offset 0x40F63B—it was in a function that checked for EOF (end of file) then used <tt>ungetc()</tt> to put it back. It was never actually returned. The other time—at offset 0x40F723—it was called then the function returned the character. That's where I focused.

I used a breakpoint to confirm that it was actually calling each of those functions for every character I entered. It was.

At that point, I tried to follow the logic onward from where the value was read. Me and Mak, together, followed the path that was then taken through the code. Essentially, checks were done for EOF, for NULL being returned from <tt>fgetc()</tt>, and for a newline. If it was any of those, it would jump to a label that I called found\_newline or something like that. We pushed our way through the obfuscated code, though, which IDA did a poor job of figuring out.

Eventually, we managed to get back to the <tt>fgetc()</tt> calls through the biiiig loop. When I tried to follow the other code path, to see how the program handles the completed string, I quickly became lost.

I then tried the other approach—starting from the "Wrong!" label and working backwards. I found all the calls to <tt>fputc()</tt> in gdb by doing the following:

Run the program until it requests password (recalling that "-x ./gdbinit" loads my init script, which loads override.so to fix the anti-debugging), then break by using ctrl-c:

```

<span class="lnr"> 1 </span><span class="perlVarPlain">$</span> gdb <span class="Statement">-x</span> ./gdbinit ./cnot
<span class="lnr"> 2 </span>Reading symbols from <span class="Statement">/</span><span class="Constant">home</span><span class="Statement">/</span>ron/cnot/cnot...(<span class="Statement">no </span>debugging symbols found)...done.
<span class="lnr"> 3 </span>(gdb) run
<span class="lnr"> 4 </span>Please enter your password: ^C
<span class="lnr"> 5 </span>Program received signal SIGINT, Interrupt.
<span class="lnr"> 6 </span><span class="Constant">0x00007ffff793f870</span> in <span class="perlStatementFileDesc">read</span> () from <span class="Statement">/</span><span class="Constant">lib</span><span class="Statement">/</span>libc.so<span class="Constant">.6</span>
<span class="lnr"> 7 </span>
```

Add a breakpoint at <tt>fputc()</tt>, then continue and enter "hello" for my password:

```

<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span>(gdb) b fputc
<span class="lnr">10 </span>Breakpoint <span class="Constant">1</span> at <span class="Constant">0x7ffff78e26d0</span>
<span class="lnr">11 </span>(gdb) cont
<span class="lnr">12 </span>hello
<span class="lnr">13 </span>
```

Once it breaks, run the "finish" command twice to exit two layers of function:

```

<span class="lnr">14 </span>
<span class="lnr">15 </span>Breakpoint <span class="Constant">1</span>, <span class="Constant">0x00007ffff78e26d0</span> in fputc () from <span class="Statement">/</span><span class="Constant">lib</span><span class="Statement">/</span>libc.so<span class="Constant">.6</span>
<span class="lnr">16 </span>(gdb) finish
<span class="lnr">17 </span><span class="Constant">0x0040f6c6</span> in ?? ()
<span class="lnr">18 </span>(gdb) finish
<span class="lnr">19 </span><span class="Constant">0x00400840</span> in ?? ()
```

Now we're at 0x400840. If you look at the function it's in, you'll see that it ends like this:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">00400</span><span class="Constant">851</span>     <span class="Identifier">pop</span>     <span class="Identifier">rdi</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">00400</span><span class="Constant">852</span>     <span class="Identifier">jmp</span>     <span class="Identifier">rdi</span>
```

As a result, gdb won't be able to "finish" properly since it never (technically) returns! Instead, we set a breakpoint on the last line then use the "stepi" command to step out:

```

<span class="lnr">1 </span>(gdb) <span class="Statement">break</span> *<span class="Constant">0x400852</span>
<span class="lnr">2 </span>Breakpoint <span class="Constant">2</span> at <span class="Constant">0x400852</span>
<span class="lnr">3 </span>(gdb) cont
<span class="lnr">4 </span>
<span class="lnr">5 </span>Breakpoint <span class="Constant">2</span>, <span class="Constant">0x00400852</span> in ?? ()
<span class="lnr">6 </span>(gdb) stepi
<span class="lnr">7 </span><span class="Constant">0x0040f149</span> in ?? ()
```

0x40f149! If you're following along in IDA, you'll see a ton of undefined code there. D'oh! You can use 'c' to define the code in IDA, just keep moving up and down and pressing 'c' (and occasionally 'u' when you see SSE instructions) in various places till stuff looks right. Eventually, you'll see:

```

<span class="lnr"> 1 </span><span class="Statement">.text</span>:<span class="Constant">0040F10F</span>     <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>], <span class="Constant">0</span>
<span class="lnr"> 2 </span><span class="Statement">.text</span>:<span class="Constant">0040F117</span>     <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>], '<span class="Identifier">W</span>'
<span class="lnr"> 3 </span><span class="Statement">.text</span>:<span class="Constant">0040F11E</span>     <span class="Identifier">push</span>    <span class="Identifier">r8</span>
<span class="lnr"> 4 </span><span class="Statement">.text</span>:<span class="Constant">0040F120</span>     <span class="Identifier">push</span>    <span class="Identifier">r9</span>
<span class="lnr"> 5 </span><span class="Statement">.text</span>:<span class="Constant">0040F122</span>     <span class="Identifier">push</span>    <span class="Identifier">rcx</span>
<span class="lnr"> 6 </span><span class="Statement">.text</span>:<span class="Constant">0040F123</span>     <span class="Identifier">xor</span>     <span class="Identifier">rcx</span>, <span class="Identifier">rcx</span>
<span class="lnr"> 7 </span><span class="Statement">.text</span>:<span class="Constant">0040F126</span>     <span class="Identifier">jz</span>      <span class="Identifier">short</span> <span class="Identifier">near</span> <span class="Identifier">ptr</span> <span class="Identifier">loc_40F128</span>+<span class="Constant">1</span>
<span class="lnr"> 8 </span><span class="Statement">.text</span>:<span class="Constant">0040F128</span>
<span class="lnr"> 9 </span><span class="Statement">.text</span>:<span class="Constant">0040F128</span> <span class="Identifier">loc_40F128</span>:
<span class="lnr">10 </span><span class="Statement">.text</span>:<span class="Constant">0040F128</span>     <span class="Identifier">mulps</span>   <span class="Identifier">xmm2</span>, <span class="Identifier">xmmword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rcx</span>+<span class="Constant">53h</span>]
<span class="lnr">11 </span><span class="Statement">.text</span>:<span class="Constant">0040F12C</span>     <span class="Identifier">push</span>    <span class="Identifier">rdx</span>
<span class="lnr">12 </span><span class="Statement">.text</span>:<span class="Constant">0040F12D</span>     <span class="Identifier">call</span>    $+<span class="Constant">5</span>
<span class="lnr">13 </span><span class="Statement">.text</span>:<span class="Constant">0040F132</span>     <span class="Identifier">pop</span>     <span class="Identifier">rdx</span>
<span class="lnr">14 </span><span class="Statement">.text</span>:<span class="Constant">0040F133</span>     <span class="Identifier">add</span>     <span class="Identifier">rdx</span>, <span class="Constant">8</span>
<span class="lnr">15 </span><span class="Statement">.text</span>:<span class="Constant">0040F137</span>     <span class="Identifier">push</span>    <span class="Identifier">rdx</span>
<span class="lnr">16 </span><span class="Statement">.text</span>:<span class="Constant">0040F138</span>     <span class="Identifier">retn</span>
<span class="lnr">17 </span><span class="Statement">.text</span>:<span class="Constant">0040F138</span>                <span class="Comment">; -------------</span>
<span class="lnr">18 </span><span class="Statement">.text</span>:<span class="Constant">0040F139</span>    <span class="Identifier">db</span>  0<span class="Identifier">Fh</span>
<span class="lnr">19 </span><span class="Statement">.text</span>:<span class="Constant">0040F13A</span>                <span class="Comment">; -------------</span>
<span class="lnr">20 </span><span class="Statement">.text</span>:<span class="Constant">0040F13A</span>     <span class="Identifier">pop</span>     <span class="Identifier">rdx</span>
<span class="lnr">21 </span><span class="Statement">.text</span>:<span class="Constant">0040F13B</span>     <span class="Identifier">pop</span>     <span class="Identifier">rbx</span>
<span class="lnr">22 </span><span class="Statement">.text</span>:<span class="Constant">0040F13C</span>     <span class="Identifier">pop</span>     <span class="Identifier">rcx</span>
<span class="lnr">23 </span><span class="Statement">.text</span>:<span class="Constant">0040F13D</span>     <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>]
<span class="lnr">24 </span><span class="Statement">.text</span>:<span class="Constant">0040F141</span>     <span class="Identifier">mov</span>     <span class="Identifier">r15</span>, <span class="Identifier">rax</span>
<span class="lnr">25 </span><span class="Statement">.text</span>:<span class="Constant">0040F144</span>     <span class="Identifier">call</span>    <span class="Identifier">sub_400824</span>
```

This isn't quite right, because of the <tt>jz</tt> and the <tt>call/push/ret</tt> in the middle, but we'll deal with that shortly. For now, look at 0x0040F117—<tt>push 'W'</tt>—and 0x40F144—call the function that calls <tt>fputc()</tt>! If you follow it down, you'll find the 'r', 'o', 'n', 'g', '!', newline, and then 'C', 'o', 'r', 'r', 'e', 'c', 't', '!'. That's great news! We found where it prints the two cases!

The problem is, it's ugly as sin. I can't even count the number of times I used 'u' to undefine bad instructions and 'c' to define better ones before I finally gave up and edited the binary...

## Anti-reversing

The best thing I ever did—and I wish I did it earlier!—was to fix the anti-reversing nonsense. There are long strings of the same thing that make analysis hard. In the previous example, everything from the <tt>push</tt> at 0x40F122 to the <tt>mov</tt> at 0x40F13D is totally worthless, and just confuses the disassembler, so let's get rid of it!

I loaded up the file in xvi32.exe—my favourite Windows hex editor—and did a find/replace on the sequence of bytes:

```

 51 48 31 C9 74 01 0F 59 51 53 52 E8 00 00 00 00 5A 48 83 C2 08 52 C3 0F 5A 5B 59
```

with NOPs:

```

 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90
```

936 occurrences replaced! Awesome! But there was still some obfuscation left that looked like this:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040F123</span>      <span class="Identifier">xor</span>     <span class="Identifier">rcx</span>, <span class="Identifier">rcx</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">0040F126</span>      <span class="Identifier">jz</span>      <span class="Identifier">short</span> <span class="Identifier">near</span> <span class="Identifier">ptr</span> <span class="Identifier">loc_40F128</span>+<span class="Constant">1</span>
<span class="lnr">3 </span><span class="Statement">.text</span>:<span class="Constant">0040F128</span>
<span class="lnr">4 </span><span class="Statement">.text</span>:<span class="Constant">0040F128</span> <span class="Identifier">loc_40F128</span>:
<span class="lnr">5 </span><span class="Statement">.text</span>:<span class="Constant">0040F128</span>      <span class="Identifier">mulps</span>   <span class="Identifier">xmm2</span>, <span class="Identifier">xmmword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rcx</span>+<span class="Constant">53h</span>]
<span class="lnr">6 </span><span class="Statement">.text</span>:<span class="Constant">0040F12C</span>      <span class="Identifier">push</span>    <span class="Identifier">rdx</span>
```

Note the <tt>jz</tt>—it actually jumps one byte, which means the instruction immediately following—the <tt>mulps</tt>—is an invalid instruction. The 0x0f is unused! This one is simple to fix—just replace 74 01 FF—the jump and the fake instruction—with NOPs:

```

  74 01 0F => 90 90 90
```

This fixes 290 more occurrences of code that confuses IDA!

And then there's this:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">00400C44</span>     <span class="Identifier">call</span>    $+<span class="Constant">5</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">00400C49</span>     <span class="Identifier">pop</span>     <span class="Identifier">rdx</span>
<span class="lnr">3 </span><span class="Statement">.text</span>:<span class="Constant">00400C4A</span>     <span class="Identifier">add</span>     <span class="Identifier">rdx</span>, <span class="Constant">8</span>
<span class="lnr">4 </span><span class="Statement">.text</span>:<span class="Constant">00400C4E</span>     <span class="Identifier">push</span>    <span class="Identifier">rdx</span>
<span class="lnr">5 </span><span class="Statement">.text</span>:<span class="Constant">00400C4F</span>     <span class="Identifier">retn</span>
<span class="lnr">6 </span><span class="Statement">.text</span>:<span class="Constant">00400C4F</span> <span class="Identifier">sub_400BD1</span>      <span class="Identifier">endp</span> <span class="Comment">; sp-analysis failed</span>
<span class="lnr">7 </span><span class="Statement">.text</span>:<span class="Constant">00400C4F</span>
<span class="lnr">8 </span><span class="Statement">.text</span>:<span class="Constant">00400C50</span>     <span class="Identifier">cvtps2pd</span> <span class="Identifier">xmm3</span>, <span class="Identifier">qword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbx</span>+<span class="Constant">59h</span>]
```

Which can be removed with this pattern:

```

  e8 00 00 00 00 5a 48 83 c2 08 52 c3 0f
```

74 of which were removed.

After all that, I loaded the executable back in IDA, and it was much nicer! I realized later that there was probably more code I could have removed—such as the <tt>pop edi / jmp edi</tt> that's used instead of returning—but I got too invested in my IDA database that I didn't want to mess it up.

## Tracking down the compare

All righty, now that we've cleaned up the code, we're starting to make some progress! By the time I got here, it was about 2am on Friday night, and I was still going strong (despite Mak being asleep behind me on a table). \[Editor's Note: I needed my beauty sleep, dammit!\]

Let's start by finding the 'Wrong' and 'Correct' strings again. You can breakpoint on <tt>fputc()</tt>, or you can just go to the definition of <tt>fputc()</tt> and keep jumping to cross references. Whatever you do, I want you to eventually wind up at the line that pushes the 'W' from 'Wrong!', which is here:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040F117</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>], '<span class="Identifier">W</span>'
```

Two lines above it, you'll see a conditional jump:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040F109</span>                 <span class="Identifier">jz</span>      <span class="Identifier">loc_40F359</span>
```

If you follow that jump, you'll see that if it jumps, it prints out 'Correct'; otherwise, it prints 'Wrong'. We can confirm this by forcing the jump, but first let's update our gdbinit file to break at the 'start' function:

```

<span class="lnr"> 1 </span>ron@debian-x64 ~/cnot $ cat gdbinit
<span class="lnr"> 2 </span><span class="Comment"># Set up the environment</span>
<span class="lnr"> 3 </span><span class="Statement">set</span> disassembly-flavor intel
<span class="lnr"> 4 </span><span class="Statement">set</span> <span class="Constant">confirm</span> off
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Comment"># Disable the anti-debugging</span>
<span class="lnr"> 7 </span><span class="Statement">set</span> <span class="Constant">environment</span> LD_PRELOAD ./overload.so
<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span><span class="Comment"># Put a breakpoint at the 'start' function</span>
<span class="lnr">10 </span><span class="Statement">break</span> *<span class="Constant">0x00400710</span>
<span class="lnr">11 </span>
<span class="lnr">12 </span><span class="Comment"># Run the program up to the breakpoint</span>
<span class="lnr">13 </span><span class="Statement">run</span>
```

Now we run the program, and change the <tt>jz</tt> at line 0x0040f109 to a <tt>jmp</tt>:

```

<span class="lnr"> 1 </span>$ gdb -x ./gdbinit ./cnot
<span class="lnr"> 2 </span>Reading symbols from /home/ron/cnot/cnot...(no debugging symbols found)...done.
<span class="lnr"> 3 </span>Breakpoint <span class="Constant">1</span> at <span class="Constant">0x400710</span>
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span>Breakpoint <span class="Constant">1</span>, <span class="Constant">0x00400710</span> in ?? ()
<span class="lnr"> 6 </span>(gdb) set {char}<span class="Constant">0x0040f109</span> = <span class="Constant">0x90</span>
<span class="lnr"> 7 </span>(gdb) set {char}<span class="Constant">0x0040f10a</span> = <span class="Constant">0xE9</span>
<span class="lnr"> 8 </span>(gdb) x/2i <span class="Constant">0x0040f109</span>
<span class="lnr"> 9 </span><span class="Constant">0x40f109</span>:       nop
<span class="lnr">10 </span><span class="Constant">0x40f10a</span>:       jmp    <span class="Constant">0x40f359</span>
<span class="lnr">11 </span>(gdb) cont
<span class="lnr">12 </span>Please enter your password: hello
<span class="lnr">13 </span>Correct!
```

So, we change 0x401109 to 0x90 (<tt>nop</tt>) and 0x0040f10a to 0xe9 (<tt>jmp long</tt>), verify the instructions, and run the program. Sure enough, my password now produces 'hello'. Success! Now I just have to backstep a little bit and find the comparison, and we're done! Simple! Haha!

## 13 steps to success

So, every variable is set in an ass-backwards way. You get pretty accustomed to seeing it in this level, and kind of just mentally pattern-match it. I'm sure there's a better way, but eh? I got pretty fast at it as time went on.

The decision whether or not to make the important jump comes from \[rbp-78h\], which comes from \[rbp-58h\] (via like ten other variables). The only way to get that variable set properly is right here:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040F08E</span>                <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">58h</span>], <span class="Constant">0</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">0040F096</span>                <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">58h</span>], <span class="Constant">1</span>
```

Right below that, I noticed this code:

```

<span class="lnr"> 1 </span><span class="Statement">.text</span>:<span class="Constant">0040F09D</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr"> 2 </span><span class="Statement">.text</span>:<span class="Constant">0040F09F</span>
<span class="lnr"> 3 </span><span class="Statement">.text</span>:<span class="Constant">0040F09F</span> <span class="Identifier">loc_40F09F</span>:      <span class="Comment">; CODE XREF: sub_40911F+5F6Dj</span>
<span class="lnr"> 4 </span><span class="Statement">.text</span>:<span class="Constant">0040F09F</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr"> 5 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A1</span>
<span class="lnr"> 6 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A1</span> <span class="Identifier">loc_40F0A1</span>:      <span class="Comment">; CODE XREF: sub_40911F+59EBj</span>
<span class="lnr"> 7 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A1</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr"> 8 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A3</span>
<span class="lnr"> 9 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A3</span> <span class="Identifier">loc_40F0A3</span>:      <span class="Comment">; CODE XREF: sub_40911F+53BAj</span>
<span class="lnr">10 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A3</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">11 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A5</span>
<span class="lnr">12 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A5</span> <span class="Identifier">loc_40F0A5</span>:      <span class="Comment">; CODE XREF: sub_40911F+47DAj</span>
<span class="lnr">13 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A5</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">14 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A7</span>
<span class="lnr">15 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A7</span> <span class="Identifier">loc_40F0A7</span>:      <span class="Comment">; CODE XREF: sub_40911F+3AB1j</span>
<span class="lnr">16 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A7</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">17 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A9</span>
<span class="lnr">18 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A9</span> <span class="Identifier">loc_40F0A9</span>:      <span class="Comment">; CODE XREF: sub_40911F+2D88j</span>
<span class="lnr">19 </span><span class="Statement">.text</span>:<span class="Constant">0040F0A9</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">20 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AB</span>
<span class="lnr">21 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AB</span> <span class="Identifier">loc_40F0AB</span>:      <span class="Comment">; CODE XREF: sub_40911F+21A8j</span>
<span class="lnr">22 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AB</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">23 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AD</span>
<span class="lnr">24 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AD</span> <span class="Identifier">loc_40F0AD</span>:      <span class="Comment">; CODE XREF: sub_40911F+2141j</span>
<span class="lnr">25 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AD</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">26 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AF</span>
<span class="lnr">27 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AF</span> <span class="Identifier">loc_40F0AF</span>:      <span class="Comment">; CODE XREF: sub_40911F+1DE9j</span>
<span class="lnr">28 </span><span class="Statement">.text</span>:<span class="Constant">0040F0AF</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">29 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B1</span>
<span class="lnr">30 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B1</span> <span class="Identifier">loc_40F0B1</span>:      <span class="Comment">; CODE XREF: sub_40911F+1D82j</span>
<span class="lnr">31 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B1</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">32 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B3</span>
<span class="lnr">33 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B3</span> <span class="Identifier">loc_40F0B3</span>:      <span class="Comment">; CODE XREF: sub_40911F+1CB4j</span>
<span class="lnr">34 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B3</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">35 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B5</span>
<span class="lnr">36 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B5</span> <span class="Identifier">loc_40F0B5</span>:      <span class="Comment">; CODE XREF: sub_40911F+1C04j</span>
<span class="lnr">37 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B5</span>     <span class="Identifier">jmp</span>     <span class="Identifier">short</span> $+<span class="Constant">2</span>
<span class="lnr">38 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B7</span>
<span class="lnr">39 </span><span class="Statement">.text</span>:<span class="Constant">0040F0B7</span> <span class="Identifier">loc_40F0B7</span>:      <span class="Comment">; CODE XREF: sub_40911F+1B9Dj</span>
```

Each of those lines bypasses the 'set the good value' line, and each of them is referred to earlier in this function. I immediately surmised that each of those locations were "bad" jumps—that is, there were thirteen or so checks that were happening, and that each one that failed would lead us back here. A thirteen character string seemed possible, where each letter was checked individually, so I started looking into it. Mak—awake once again&mdath;was not convinced.

## The easy start

The final thing I did Friday night was look at the first check (the last one on that list), which is located at this line:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040ACBC</span>                 <span class="Identifier">jz</span>      <span class="Identifier">loc_40F0B7</span>
```

What causes that jump to fail? Long story short, it's this:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040AC8E</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">r15d</span>, [<span class="Identifier">rbp</span>-<span class="Constant">78h</span>]
```

...where r15d is an unknown value, and \[rbp-78h\] is 0x18 (24). Let's break and see what r15 is:

```

<span class="lnr"> 1 </span>  ron@debian-x64 ~/cnot $ gdb -x ./gdbinit ./cnot
<span class="lnr"> 2 </span>  Reading symbols from /home/ron/cnot/cnot...(no debugging symbols found)...done.
<span class="lnr"> 3 </span>  Breakpoint <span class="Constant">1</span> at <span class="Constant">0x400710</span>
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span>  Breakpoint <span class="Constant">1</span>, <span class="Constant">0x00400710</span> in ?? ()
<span class="lnr"> 6 </span>  (gdb) b *<span class="Constant">0x0040ac8e</span>
<span class="lnr"> 7 </span>  Breakpoint <span class="Constant">2</span> at <span class="Constant">0x40ac8e</span>
<span class="lnr"> 8 </span>  (gdb) cont
<span class="lnr"> 9 </span>  Please enter your password: hello
<span class="lnr">10 </span>
<span class="lnr">11 </span>  Breakpoint <span class="Constant">2</span>, <span class="Constant">0x0040ac8e</span> in ?? ()
<span class="lnr">12 </span>  (gdb) <span class="Constant">print</span>/d <span class="Identifier">$r15</span>
<span class="lnr">13 </span>  $1 = <span class="Constant">5</span>
<span class="lnr">14 </span>  (gdb) run
<span class="lnr">15 </span>
<span class="lnr">16 </span>  Breakpoint <span class="Constant">1</span>, <span class="Constant">0x00400710</span> in ?? ()
<span class="lnr">17 </span>  (gdb) cont
<span class="lnr">18 </span>  Please enter your password: moo
<span class="lnr">19 </span>
<span class="lnr">20 </span>  Breakpoint <span class="Constant">2</span>, <span class="Constant">0x0040ac8e</span> in ?? ()
<span class="lnr">21 </span>  (gdb) <span class="Constant">print</span>/d <span class="Identifier">$r15</span>
<span class="lnr">22 </span>  $2 = <span class="Constant">3</span>
<span class="lnr">23 </span>
```

When I enter 'hello', it's 5, and when I enter 'moo', it's 3. It compares that value to 0x18 (24), and fails if it's anything else. We just found out the password length! And it was kind of easy!

By now it was about 5am on Friday night, and time for bed.

## Not as dumb as I look

First thing Saturday morning—after three hours of sleep—I started and finished another flag—securereader. Don't get me started on securereader. I fucked up badly, and it took wayyyyyy longer than it should have.

Anyway, by early afternoon, I was back to working on cnot. I was pretty sure those jumps were all the 'bad' jumps, so—in what I consider my #1 decision on this entire flag, at least tied with finding/replacing the 'bad code'—I added a bunch of nop-outs to my gdbinit file:

```

<span class="lnr"> 1 </span>ron@debian-x64 ~/cnot $ cat ./gdbinit
<span class="lnr"> 2 </span><span class="Comment"># Set up the environment</span>
<span class="lnr"> 3 </span><span class="Statement">set</span> disassembly-flavor intel
<span class="lnr"> 4 </span><span class="Statement">set</span> <span class="Constant">confirm</span> off
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Comment"># Disable the anti-debugging</span>
<span class="lnr"> 7 </span><span class="Statement">set</span> <span class="Constant">environment</span> LD_PRELOAD ./overload.so
<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span><span class="Comment"># Put a breakpoint at the 'start' function</span>
<span class="lnr">10 </span><span class="Statement">break</span> *<span class="Constant">0x00400710</span>
<span class="lnr">11 </span>
<span class="lnr">12 </span><span class="Comment"># Run the program up to the breakpoint</span>
<span class="lnr">13 </span><span class="Statement">run</span>
<span class="lnr">14 </span>
<span class="lnr">15 </span><span class="Comment"># Verify length</span>
<span class="lnr">16 </span><span class="Statement">set</span> {int}<span class="Constant">0x040ACBC</span> = <span class="Constant">0x90909090</span>
<span class="lnr">17 </span><span class="Statement">set</span> {short}<span class="Constant">0x040ACC0</span> = <span class="Constant">0x9090</span>
<span class="lnr">18 </span>
<span class="lnr">19 </span><span class="Statement">set</span> {int}<span class="Constant">0x040AD23</span> = <span class="Constant">0x90909090</span>
<span class="lnr">20 </span><span class="Statement">set</span> {short}<span class="Constant">0x040AD27</span> = <span class="Constant">0x9090</span>
<span class="lnr">21 </span>
<span class="lnr">22 </span><span class="Statement">set</span> {int}<span class="Constant">0x040ADD3</span> = <span class="Constant">0x90909090</span>
<span class="lnr">23 </span><span class="Statement">set</span> {short}<span class="Constant">0x040ADD7</span> = <span class="Constant">0x9090</span>
<span class="lnr">24 </span>
<span class="lnr">25 </span><span class="Statement">set</span> {int}<span class="Constant">0x040AEA1</span> = <span class="Constant">0x90909090</span>
<span class="lnr">26 </span><span class="Statement">set</span> {short}<span class="Constant">0x040AEA5</span> = <span class="Constant">0x9090</span>
<span class="lnr">27 </span>
<span class="lnr">28 </span><span class="Statement">set</span> {int}<span class="Constant">0x040AF08</span> = <span class="Constant">0x90909090</span>
<span class="lnr">29 </span><span class="Statement">set</span> {short}<span class="Constant">0x040AF0C</span> = <span class="Constant">0x9090</span>
<span class="lnr">30 </span>
<span class="lnr">31 </span><span class="Statement">set</span> {int}<span class="Constant">0x040B260</span> = <span class="Constant">0x90909090</span>
<span class="lnr">32 </span><span class="Statement">set</span> {short}<span class="Constant">0x040B264</span> = <span class="Constant">0x9090</span>
<span class="lnr">33 </span>
<span class="lnr">34 </span><span class="Statement">set</span> {int}<span class="Constant">0x040B2C7</span> = <span class="Constant">0x90909090</span>
<span class="lnr">35 </span><span class="Statement">set</span> {short}<span class="Constant">0x040B2CB</span> = <span class="Constant">0x9090</span>
<span class="lnr">36 </span>
<span class="lnr">37 </span><span class="Statement">set</span> {int}<span class="Constant">0x040BEA7</span> = <span class="Constant">0x90909090</span>
<span class="lnr">38 </span><span class="Statement">set</span> {short}<span class="Constant">0x040BEAB</span> = <span class="Constant">0x9090</span>
<span class="lnr">39 </span>
<span class="lnr">40 </span><span class="Statement">set</span> {int}<span class="Constant">0x040CBD0</span> = <span class="Constant">0x90909090</span>
<span class="lnr">41 </span><span class="Statement">set</span> {short}<span class="Constant">0x040CBD4</span> = <span class="Constant">0x9090</span>
<span class="lnr">42 </span>
<span class="lnr">43 </span><span class="Statement">set</span> {int}<span class="Constant">0x040D8F9</span> = <span class="Constant">0x90909090</span>
<span class="lnr">44 </span><span class="Statement">set</span> {short}<span class="Constant">0x040D8FD</span> = <span class="Constant">0x9090</span>
<span class="lnr">45 </span>
<span class="lnr">46 </span><span class="Statement">set</span> {int}<span class="Constant">0x040E4D9</span> = <span class="Constant">0x90909090</span>
<span class="lnr">47 </span><span class="Statement">set</span> {short}<span class="Constant">0x040E4DD</span> = <span class="Constant">0x9090</span>
<span class="lnr">48 </span>
<span class="lnr">49 </span><span class="Statement">set</span> {int}<span class="Constant">0x040EB0A</span> = <span class="Constant">0x90909090</span>
<span class="lnr">50 </span><span class="Statement">set</span> {short}<span class="Constant">0x040EB0E</span> = <span class="Constant">0x9090</span>
<span class="lnr">51 </span>
<span class="lnr">52 </span><span class="Statement">set</span> {short}<span class="Constant">0x040F08C</span> = <span class="Constant">0x9090</span>
<span class="lnr">53 </span>
<span class="lnr">54 </span>cont
```

After like two hours of troubleshooting that code because I forgot that 'long' = 8 bytes and 'int' = 4 bytes (which Aemelianus had the pleasure to watch me fight with), eventually it worked:

```

<span class="lnr">1 </span>$ gdb -x ./gdbinit ./cnot
<span class="lnr">2 </span>Reading symbols from /home/ron/cnot/cnot...(no debugging symbols found)...done.
<span class="lnr">3 </span>Breakpoint <span class="Constant">1</span> at <span class="Constant">0x400710</span>
<span class="lnr">4 </span>
<span class="lnr">5 </span>Breakpoint <span class="Constant">1</span>, <span class="Constant">0x00400710</span> in ?? ()
<span class="lnr">6 </span>Please enter your password: hello
<span class="lnr">7 </span>Correct!
<span class="lnr">8 </span>
<span class="lnr">9 </span>Program exited normally.
```

Excellent! I can easily test any of the checks without the others interfering!

From here on out, I did everything in a more or less random order, and each step took a *long* time. Ultimately, however, there were four main types of checks I found: character class (upper/lower/numeric), adjacent checks, shift checks (I'll explain these later), and checksums. I solved the first three on Saturday, and the last—the hardest, the checksum—on Sunday. Let's take each of them individually.

## Character class

The character class checks happen right here:

```

<span class="lnr"> 1 </span><span class="Statement">.text</span>:<span class="Constant">0040AD00</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, [<span class="Identifier">rbp</span>-<span class="Constant">70h</span>]
<span class="lnr"> 2 </span><span class="Statement">.text</span>:<span class="Constant">0040AD04</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r15</span>, <span class="Identifier">rax</span>        <span class="Comment">; both = pointers to my string</span>
<span class="lnr"> 3 </span><span class="Statement">.text</span>:<span class="Constant">0040AD07</span>                 <span class="Identifier">call</span>    <span class="Identifier">do_validation2</span>  <span class="Comment">; Validate a pattern (fully reversed)</span>
<span class="lnr"> 4 </span><span class="Statement">.text</span>:<span class="Constant">0040AD0C</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>], <span class="Identifier">rax</span>
<span class="lnr"> 5 </span><span class="Statement">.text</span>:<span class="Constant">0040AD10</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, <span class="Identifier">r15</span>
<span class="lnr"> 6 </span><span class="Statement">.text</span>:<span class="Constant">0040AD13</span>                 <span class="Identifier">add</span>     <span class="Identifier">rsp</span>, <span class="Constant">0</span>
<span class="lnr"> 7 </span><span class="Statement">.text</span>:<span class="Constant">0040AD17</span>                 <span class="Identifier">pop</span>     <span class="Identifier">r9</span>
<span class="lnr"> 8 </span><span class="Statement">.text</span>:<span class="Constant">0040AD19</span>                 <span class="Identifier">pop</span>     <span class="Identifier">r8</span>
<span class="lnr"> 9 </span><span class="Statement">.text</span>:<span class="Constant">0040AD1B</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r15d</span>, [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>]
<span class="lnr">10 </span><span class="Statement">.text</span>:<span class="Constant">0040AD1F</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">r15d</span>, <span class="Constant">0</span>
<span class="lnr">11 </span><span class="Statement">.text</span>:<span class="Constant">0040AD23</span>                 <span class="Identifier">jz</span>      <span class="Identifier">bad_place2</span>
```

<tt>do\_validation2()</tt> is about a million lines, and is actually a great place to get your feet wet with how the obfuscation works. By the end of it, I could move through pretty quickly. It calls three different functions, which are:

```

<span class="lnr">1 </span><span class="Constant">0x00402726</span> check_alphabetic(char c)
<span class="lnr">2 </span><span class="Constant">0x004028AC</span> check_lowercase(char c)
<span class="lnr">3 </span><span class="Constant">0x0040297E</span> check_numeric(char c)
```

I'm not going to dwell on how those work. Suffice to say, they're about as simple as anything is in this binary. One line in the source, and only about 150 lines in the binary!

Essentially, throughout this function, you'll see things like:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">00402AFD</span>                 <span class="Identifier">add</span>     <span class="Identifier">r11</span>, <span class="Identifier">rbx</span>        <span class="Comment">; add 0*8 to the offset</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">00402B1E</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rax</span>]       <span class="Comment">; rax = first character ("a")</span>
<span class="lnr">3 </span><span class="Statement">.text</span>:<span class="Constant">00402B40</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>
<span class="lnr">4 </span><span class="Statement">.text</span>:<span class="Constant">00402B43</span>                 <span class="Identifier">call</span>    <span class="Identifier">check_alphabetic</span> <span class="Comment">; Returns '1' if it's upper or lower case</span>
<span class="lnr">5 </span><span class="Statement">.text</span>:<span class="Constant">00402B50</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">eax</span>, <span class="Constant">0 </span>          <span class="Comment">; '1' is good</span>
<span class="lnr">6 </span><span class="Statement">.text</span>:<span class="Constant">00402B53</span>                 <span class="Identifier">jz</span>      <span class="Identifier">bad</span>
```

(note that I'm leaving out the extra 'obfuscating' lines)

This runs through every character, one by one, with similar checks. I did a ton of debugging to see what was going on, and was able to determine the 'possible' values of each character:

```

Character 1  :: Letter
Character 2  :: Letter
Character 3  :: Lowercase
Character 4  :: Lowercase
Character 5  :: Letter
Character 6  :: Symbol (not letter or number)
Character 7  :: Letter
Character 8  :: Symbol
Character 9  :: Number
Character 10 :: Lowercase
Character 11 :: Letter
Character 12 :: Letter
Character 13 :: Letter
Character 14 :: Uppercase
Character 15 :: Letter
Character 16 :: Letter
Character 17 :: Uppercase
Character 18 :: Letter
Character 19 :: Symbol
Character 20 :: Letter
Character 21 :: Letter (I originally had 'lowercase', that was wrong)
Character 22 :: Letter
Character 23 :: Uppercase
Character 24 :: Symbol
```

In addition to character classes, a couple properties were discovered here:

- The fourth character had to be one higher than the tenth character
- The twenty-first character was alphabetic, but if you subtract one it wasn't (therefore, it had to be a 'a' or 'A')

So now we have a lot of properties, and an actual letter! Progress! And we have one more check that'll pass; two down, eleven to go!

### Adjacent checks

After the character class checks, I was getting a little faster. There's a *ton* of code, but eventually you learn how it indexes arrays, and that makes it *much* easier, since you can skip by about 95% of the code.

This section starts here:

```

<span class="lnr"> 1 </span><span class="Statement">.text</span>:<span class="Constant">0040AEE5</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, [<span class="Identifier">rbp</span>-<span class="Constant">70h</span>]
<span class="lnr"> 2 </span><span class="Statement">.text</span>:<span class="Constant">0040AEE9</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r15</span>, <span class="Identifier">rax</span>
<span class="lnr"> 3 </span><span class="Statement">.text</span>:<span class="Constant">0040AEEC</span>                 <span class="Identifier">call</span>    <span class="Identifier">do_validation_5</span> <span class="Comment">; Validates adjacent letters, and their relationships to each other</span>
<span class="lnr"> 4 </span><span class="Statement">.text</span>:<span class="Constant">0040AEEC</span>                                         <span class="Comment">; rdi = pointer to string buffer</span>
<span class="lnr"> 5 </span><span class="Statement">.text</span>:<span class="Constant">0040AEF1</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>], <span class="Identifier">rax</span>  <span class="Comment">; rax shouldn't be 0</span>
<span class="lnr"> 6 </span><span class="Statement">.text</span>:<span class="Constant">0040AEF5</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, <span class="Identifier">r15</span>
<span class="lnr"> 7 </span><span class="Statement">.text</span>:<span class="Constant">0040AEF8</span>                 <span class="Identifier">add</span>     <span class="Identifier">rsp</span>, <span class="Constant">0</span>
<span class="lnr"> 8 </span><span class="Statement">.text</span>:<span class="Constant">0040AEFC</span>                 <span class="Identifier">pop</span>     <span class="Identifier">r9</span>
<span class="lnr"> 9 </span><span class="Statement">.text</span>:<span class="Constant">0040AEFE</span>                 <span class="Identifier">pop</span>     <span class="Identifier">r8</span>
<span class="lnr">10 </span><span class="Statement">.text</span>:<span class="Constant">0040AF00</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r15d</span>, [<span class="Identifier">rbp</span>-<span class="Constant">68h</span>]
<span class="lnr">11 </span><span class="Statement">.text</span>:<span class="Constant">0040AF04</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">r15d</span>, <span class="Constant">0</span>
<span class="lnr">12 </span><span class="Statement">.text</span>:<span class="Constant">0040AF08</span>                 <span class="Identifier">jz</span>      <span class="Identifier">bad_place5</span>
```

Note that I'm not doing this in order; I don't have to, since I disable the checks I'm not using!

Inside my stupidly named <tt>do\_validation\_5()</tt> (I didn't know what it was going to do when I named it!), you'll see the same pattern over and over and over; it loads a letter, then the next letter, and compares them with either <tt>jg</tt> (jump if greater) or <tt>jl</tt> (jump if less):

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">00404FE2</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r10</span>, [<span class="Identifier">r10</span>]       <span class="Comment">; first letter</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">004050</span><span class="Constant">87</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r11</span>, [<span class="Identifier">r11</span>]       <span class="Comment">; second letter</span>
<span class="lnr">3 </span><span class="Statement">.text</span>:<span class="Constant">004050</span><span class="Constant">8A</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">r10d</span>, <span class="Identifier">r11d</span>
<span class="lnr">4 </span><span class="Statement">.text</span>:<span class="Constant">004050</span><span class="Constant">8D</span>                 <span class="Identifier">jg</span>      <span class="Identifier">short</span> <span class="Identifier">loc_405096</span> <span class="Comment">; good jump</span>
<span class="lnr">5 </span><span class="Statement">.text</span>:<span class="Constant">004050</span><span class="Constant">8F</span>                 <span class="Identifier">mov</span>     <span class="Identifier">ebx</span>, <span class="Constant">0 </span>          <span class="Comment">; bad</span>
<span class="lnr">6 </span><span class="Statement">.text</span>:<span class="Constant">004050</span><span class="Constant">94</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">short</span> <span class="Identifier">loc_40509B</span>
```

If you go through this, you'll get the following relationships:

```

character[1]  > character[2]
character[2]  > character[3]
character[3]  < character[4]
character[4]  > character[5]
character[5]  > character[6]
character[6]  < character[7]
character[7]  > character[8]
character[8]  < character[9]
character[9]  < character[10]
character[10] < character[11]
character[11] > character[12]
character[12] < character[13]
character[13] > character[14]
character[14] < character[15]
character[15] < character[16]
character[16] > character[17]
character[17] < character[18]
character[18] > character[19]
character[19] < character[20]
character[20] > character[21]
character[21] < character[22]
character[22] > character[23]
character[23] > character[24]
```

When I got to this point, Mak started writing a Prolog and also a Python program so we could take these relationships and start deriving relationships. In the end, he started working on another flag, and I never actually used these relationships to solve anything...

On the plus side, after the first few, it was fast going! I did the first seven or eight carefully and with a debugger, and all the rest I just blew through in about a half hour!

### Shift checks

So, I purposely waited to work on these ones, because they called long functions, which called other long functions, which did crazy shifty stuff. After I actually started reversing, I realized that it was actually pretty easy—most of them did the same thing! Everything in this binary looks long and complicated, though.

Let's start with one of the innermost functions. Removing all the crap, it does this:

```

<span class="lnr"> 1 </span><span class="Statement">.text</span>:<span class="Constant">00400E75</span> <span class="Identifier">shift10</span>         <span class="Identifier">proc</span> <span class="Identifier">near</span>
<span class="lnr"> 2 </span><span class="Statement">.text</span>:<span class="Constant">00400EAA</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, <span class="Identifier">rdi</span>        <span class="Comment">; rax = arg</span>
<span class="lnr"> 3 </span><span class="Statement">.text</span>:<span class="Constant">00400EC8</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r10</span>, <span class="Identifier">rax</span>        <span class="Comment">; r10 = arg</span>
<span class="lnr"> 4 </span><span class="Statement">.text</span>:<span class="Constant">00400ECB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r11d</span>, 0<span class="Identifier">Ah</span>       <span class="Comment">; r11 = 10</span>
<span class="lnr"> 5 </span><span class="Statement">.text</span>:<span class="Constant">00400ED2</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r15d</span>, <span class="Identifier">r10d</span>      <span class="Comment">; r15 = arg</span>
<span class="lnr"> 6 </span><span class="Statement">.text</span>:<span class="Constant">00400ED5</span>                 <span class="Identifier">mov</span>     <span class="Identifier">ecx</span>, <span class="Identifier">r11d</span>       <span class="Comment">; ecx = 10</span>
<span class="lnr"> 7 </span><span class="Statement">.text</span>:<span class="Constant">00400ED8</span>                 <span class="Identifier">sar</span>     <span class="Identifier">r15d</span>, <span class="Identifier">cl</span>        <span class="Comment">; r15 = arg >> 10</span>
<span class="lnr"> 8 </span><span class="Statement">.text</span>:<span class="Constant">00400EDB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">ebx</span>, <span class="Identifier">r15d</span>       <span class="Comment">; ebx = rdi >> 10</span>
<span class="lnr"> 9 </span><span class="Statement">.text</span>:<span class="Constant">00400EDF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r10d</span>, <span class="Constant">1Fh</span>       <span class="Comment">; r10 = 0x1f</span>
<span class="lnr">10 </span><span class="Statement">.text</span>:<span class="Constant">00400F00</span>                 <span class="Identifier">and</span>     <span class="Identifier">ebx</span>, <span class="Identifier">r10d</span>       <span class="Comment">; ebx = (arg >> 10) & 0x1f</span>
<span class="lnr">11 </span><span class="Statement">.text</span>:<span class="Constant">00400F03</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, <span class="Identifier">rbx</span>
<span class="lnr">12 </span><span class="Statement">.text</span>:<span class="Constant">00400F1B</span>                 <span class="Identifier">pop</span>     <span class="Identifier">rdi</span>
<span class="lnr">13 </span><span class="Statement">.text</span>:<span class="Constant">00400F1C</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">rdi</span>
```

Which is basically:

```

<span class="lnr">1 </span><span class="Statement">return</span> (arg >> <span class="Constant">10</span>) & <span class="Constant">0x1F</span>
```

Easy! There are actually a bunch of functions that do almost the same thing:

```

<span class="lnr">1 </span><span class="rubyDefine">def</span> <span class="Identifier">shift0</span>(c)  <span class="Statement">return</span> (c >> <span class="Constant">0</span>) & <span class="Constant">0x1F</span>; <span class="rubyDefine">end</span>
<span class="lnr">2 </span><span class="Comment"># Oddly, there's no shift5()</span>
<span class="lnr">3 </span><span class="rubyDefine">def</span> <span class="Identifier">shift10</span>(c) <span class="Statement">return</span> (c >> <span class="Constant">0</span>) & <span class="Constant">0x1F</span>; <span class="rubyDefine">end</span>
<span class="lnr">4 </span><span class="rubyDefine">def</span> <span class="Identifier">shift15</span>(c) <span class="Statement">return</span> (c >> <span class="Constant">0</span>) & <span class="Constant">0x1F</span>; <span class="rubyDefine">end</span>
<span class="lnr">5 </span><span class="rubyDefine">def</span> <span class="Identifier">shift20</span>(c) <span class="Statement">return</span> (c >> <span class="Constant">0</span>) & <span class="Constant">0x1F</span>; <span class="rubyDefine">end</span>
<span class="lnr">6 </span><span class="rubyDefine">def</span> <span class="Identifier">shift25</span>(c) <span class="Statement">return</span> (c >> <span class="Constant">0</span>) & <span class="Constant">0x1F</span>; <span class="rubyDefine">end</span>
<span class="lnr">7 </span><span class="rubyDefine">def</span> <span class="Identifier">shift30</span>(c) <span class="Statement">return</span> (c >> <span class="Constant">0</span>) & <span class="Constant">0x03</span>; <span class="rubyDefine">end</span>
```

Then those functions are called from two others (actually, three, but the third is never used in the code we care about):

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">00401E96</span> <span class="Identifier">shifter</span>()
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">00402413</span> <span class="Identifier">shifter2</span>()
```

I'm not going to waste your time by reversing them. They're kinda long, but fairly simple. Here is what they end up as:

```

<span class="lnr">1 </span><span class="rubyDefine">def</span> <span class="Identifier">shifter</span>(c, i = <span class="Constant">0</span>)
<span class="lnr">2 </span>  <span class="Statement">return</span> i | (<span class="Constant">1</span> << shift10(c)) | (<span class="Constant">1</span> << shift5(c)) | (<span class="Constant">1</span> << shift0(c))
<span class="lnr">3 </span><span class="rubyDefine">end</span>
<span class="lnr">4 </span>
<span class="lnr">5 </span><span class="rubyDefine">def</span> <span class="Identifier">shifter2</span>(c, i = <span class="Constant">0</span>)
<span class="lnr">6 </span>  <span class="Statement">return</span> i | (<span class="Constant">1</span> << shift25(c)) | (<span class="Constant">1</span> << shift20(c)) | (<span class="Constant">1</span> << shift10(c)) | (<span class="Constant">1</span> << shift0(c))
<span class="lnr">7 </span><span class="rubyDefine">end</span>
```

Basically, take various sequences of five bytes within the string, and set those bits in another value!

Now, how are these used? The first use is easy, and is actually the second-simplest check (after the length check). It looks like this (once again, I've removed obfuscating lines):

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040B04B</span>      <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, [<span class="Identifier">rbp</span>-<span class="Constant">80h</span>]  <span class="Comment">; rsi = last character</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">0040B04F</span>      <span class="Identifier">mov</span>     <span class="Identifier">r15</span>, <span class="Identifier">rax</span>
<span class="lnr">3 </span><span class="Statement">.text</span>:<span class="Constant">0040B052</span>      <span class="Identifier">call</span>    <span class="Identifier">shifter</span>
<span class="lnr">4 </span><span class="Statement">.text</span>:<span class="Constant">0040B057</span>      <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>-<span class="Constant">70h</span>], <span class="Identifier">rax</span>
<span class="lnr">5 </span><span class="Statement">.text</span>:<span class="Constant">0040B066</span>      <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">78h</span>], <span class="Constant">0</span>
<span class="lnr">6 </span><span class="Statement">.text</span>:<span class="Constant">0040B06E</span>      <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">78h</span>], <span class="Constant">80000003h</span>
<span class="lnr">7 </span><span class="Statement">.text</span>:<span class="Constant">0040B075</span>      <span class="Identifier">mov</span>     <span class="Identifier">r15d</span>, [<span class="Identifier">rbp</span>-<span class="Constant">70h</span>]
<span class="lnr">8 </span><span class="Statement">.text</span>:<span class="Constant">0040B079</span>      <span class="Identifier">cmp</span>     <span class="Identifier">r15d</span>, [<span class="Identifier">rbp</span>-<span class="Constant">78h</span>]
<span class="lnr">9 </span><span class="Statement">.text</span>:<span class="Constant">0040B07D</span>      <span class="Identifier">jz</span>      <span class="Identifier">short</span> <span class="Identifier">loc_40B093</span> <span class="Comment">; Good jump</span>
```

So the last line of the string is the symbol that, when put through <tt>shifter()</tt>, produces 0x80000003? That's easy! Here's a quick Ruby program (I actually did it in a much more complicated way originally, by literally reversing the algorithm, but that was dumb):

```

<span class="lnr">1 </span><span class="Constant">0x20</span>.upto(<span class="Constant">0x7F</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr">2 </span><span class="Statement">if</span>(shifter(i) == <span class="Constant">0x80000003</span>)
<span class="lnr">3 </span>    puts(<span class="Special">"</span><span class="Constant">Character: </span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">"</span>)
<span class="lnr">4 </span><span class="Statement">end</span>
<span class="lnr">5 </span><span class="Statement">end</span>
```

Which prints out:

```

<span class="lnr">1 </span><span class="perlVarPlain">ron@debian-x86</span> ~<span class="perlVarPlain">$</span> ruby ./do_shift.rb
<span class="lnr">2 </span><span class="Statement">Character:</span> ?
```

The last character is a question mark! Awesome!

After that, there are a bunch of checks (all remaining checks but two, in fact!) that all sort of look the same (and are implemented inline, not in functions). One of them you can find starting at 0x0040BEAD, and the logic is something like this:

```

<span class="lnr"> 1 </span>c = second_character;
<span class="lnr"> 2 </span><span class="Statement">if</span>(shifter(c, c) == shifter2(c, c))
<span class="lnr"> 3 </span>{
<span class="lnr"> 4 </span>  <span class="Statement">if</span>(shifter(c - <span class="Constant">0x20</span>, c - <span class="Constant">0x20</span>) != shifter2(c - <span class="Constant">0x20</span>, c - <span class="Constant">0x20</span>))
<span class="lnr"> 5 </span>  {
<span class="lnr"> 6 </span>    <span class="Statement">if</span>(c < <span class="Special">'</span><span class="Constant">i</span><span class="Special">'</span> && c > <span class="Special">'</span><span class="Constant">d</span><span class="Special">'</span>)
<span class="lnr"> 7 </span>    {
<span class="lnr"> 8 </span>      acceptable_second_character(c);
<span class="lnr"> 9 </span>    }
<span class="lnr">10 </span>  }
<span class="lnr">11 </span>}
```

Implementing it in Ruby (this code will only work in 1.9 because of <tt>String.ord()</tt>) will look something like this:

```

<span class="lnr"> 1 </span><span class="Constant">?A</span>.upto(<span class="Constant">?Z</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr"> 2 </span>  i = i.ord
<span class="lnr"> 3 </span>  (set &lt;&lt; i) <span class="Statement">if</span>(shifter(i, i) == shifter2(i, i))
<span class="lnr"> 4 </span><span class="Statement">end</span>
<span class="lnr"> 5 </span><span class="Constant">?a</span>.ord.upto(<span class="Constant">?z</span>.ord) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr"> 6 </span>  i = i.ord
<span class="lnr"> 7 </span>  (set &lt;&lt; i) <span class="Statement">if</span>(shifter(i, i) == shifter2(i, i))
<span class="lnr"> 8 </span><span class="Statement">end</span>
<span class="lnr"> 9 </span>
<span class="lnr">10 </span>set.each <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr">11 </span>  <span class="Statement">if</span>(shifter(i - <span class="Constant">0x20</span>, i - <span class="Constant">0x20</span>) != shifter2(i - <span class="Constant">0x20</span>, i - <span class="Constant">0x20</span>))
<span class="lnr">12 </span>    <span class="Statement">if</span>(i &gt; <span class="Constant">?d</span>.ord &amp;&amp; i < <span class="Constant">?i</span>.ord)
<span class="lnr">13 </span>      puts(i.chr)
<span class="lnr">14 </span>    <span class="Statement">end</span>
<span class="lnr">15 </span>  <span class="Statement">end</span>
<span class="lnr">16 </span><span class="Statement">end</span>
```

And running it:

```

<span class="lnr">1 </span><span class="perlVarPlain">$</span> ruby do_shift.rb
<span class="lnr">2 </span>h
```

Tells us that the only possibility is 'h'! We just solved the second letter!

There are a ton of checks like this, and I'm not going to go over the rest of them. The only other noteworthy "shift" check is the function defined here:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">00406F32</span> <span class="Identifier">check_duplicates</span>
```

Which goes through a bunch of fields, and requires them to be equal to one another (eg, the sixth, eighth, and nineteenth characters are the same; the fourteenth and seventeenth letter are the same; etc).

When all's said and done, at the end of the 'shift' stuff, and including the character class checks, we have the following properties:

```

  Character 1  :: 'w'
  Character 2  :: 'h'
  Character 3  :: 'e'
  Character 4  :: Lowercase letter = the 10th character + 1
  Character 5  :: 'e'
  Character 6  :: Symbol, same as 8th and 19th characters
  Character 7  :: 'u', 'v', or 'w'
  Character 8  :: Symbol, same as 6th and 19th characters
  Character 9  :: Number
  Character 10 :: Lowercase
  Character 11 :: Letter
  Character 12 :: 'e'
  Character 13 :: 'n'
  Character 14 :: Uppercase, same as 17th
  Character 15 :: 'h', 'i', 'j', or 'k'
  Character 16 :: Letter, same as 18th
  Character 17 :: Uppercase, same as 14th
  Character 18 :: Letter, same as 16th
  Character 19 :: Symbol, same as 6th and 8th
  Character 20 :: 'n'
  Character 21 :: 'a' or 'A'
  Character 22 :: Letter
  Character 23 :: Uppercase
  Character 24 :: '?'
```

To put it another way:

```

  whe_e._.#__en_____.na__?
```

I reached this point... maybe 5am on Saturday night? The next hour me and Rylaan and others spent trying to make guesses. We were reasonably sure that the fourth letter was 'r', making the first word 'where'. That would make the tenth character a 'q' and the eleventh a 'u'. That worked out pretty well. And putting a 'u' in the seventh character (since it's much more likely than 'v' or 'w') and making the symbols into spaces made sense. That gave us:

```

  where u #quen_____ na__?
```

We also surmised that the last word was 'namE' or 'nAME' or something, but that turned out to be wrong so I won't show that part off. :)

[Here is what I had scribbled down](/blogdata/cnot.jpg) at this point.

Before bed, I wrote a quick Ruby script that would bruteforce guess all unknown characters, hoping to guess it by morning. That was also a failure. It barely got anywhere in the three hours I slept.

### Checksums

I went to sleep on the hackerspace couch at 6am Saturday night, and woke up at 9am with the idea: "quantum"! "where u quantum name" or something. So I jumped up, ran to the computer, and realized that that made no sense. Crap! But I was already up, may as well work on it more. I spent the next little while updating Mak on my progress and thinking through the next step.

I spent a few hours working on these four checksum values:

```

<span class="lnr">1 </span><span class="Statement">.text</span>:<span class="Constant">0040AD41</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">78h</span>], 0<span class="Identifier">FAF7F5FFh</span> <span class="Comment">; checksum1</span>
<span class="lnr">2 </span><span class="Statement">.text</span>:<span class="Constant">0040AD81</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">90h</span>], 0<span class="Identifier">A40121Fh</span>  <span class="Comment">; checksum2</span>
<span class="lnr">3 </span><span class="Statement">.text</span>:<span class="Constant">0040AE00</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">78h</span>], 0<span class="Identifier">FF77F7F6h</span> <span class="Comment">; checksum3</span>
<span class="lnr">4 </span><span class="Statement">.text</span>:<span class="Constant">0040AE4F</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">rbp</span>-<span class="Constant">90h</span>], 0<span class="Identifier">FD9E7F5Fh</span> <span class="Comment">; checksum4</span>
```

I spent hours trying to reverse how those were calculated before finally giving up. I was running out of ideas. I had eleven of the thirteen checks passing, with only the four checksums (in two checks) to go! Gah!

I noticed an interesting property in the checksums, though: the values I was generating were actually quite close to the real ones, compared to what they'd originally been! If I changed a known "good" character to a bad one, it got worse. All I had to do was figure out a way to either generate the checksums myself or pull them from memory! At this point in the game, generating them myself was pretty much outta the question, so I had to find a way to extract them, and quickly!

I won't bore you with the failed attempts, only the successful attempt. It's a Ruby program, and it looks something like this (check out the sweet syntax highlighting, I even highlighted the gdbinit file properly; that wasn't easy!):

```

<span class="lnr">  1 </span><span class="rubyDefine">def</span> <span class="Identifier">count_bits</span>(i)
<span class="lnr">  2 </span>  bits = <span class="Constant">0</span>
<span class="lnr">  3 </span>
<span class="lnr">  4 </span>  <span class="Statement">while</span>(i != <span class="Constant">0</span>) <span class="Statement">do</span>
<span class="lnr">  5 </span>    <span class="Statement">if</span>((i & <span class="Constant">1</span>) == <span class="Constant">1</span>)
<span class="lnr">  6 </span>      bits += <span class="Constant">1</span>
<span class="lnr">  7 </span>    <span class="Statement">end</span>
<span class="lnr">  8 </span>
<span class="lnr">  9 </span>    i >>= <span class="Constant">1</span>
<span class="lnr"> 10 </span>  <span class="Statement">end</span>
<span class="lnr"> 11 </span>
<span class="lnr"> 12 </span>  <span class="Statement">return</span> bits
<span class="lnr"> 13 </span><span class="rubyDefine">end</span>
<span class="lnr"> 14 </span>
<span class="lnr"> 15 </span><span class="rubyDefine">def</span> <span class="Identifier">go</span>(str)
<span class="lnr"> 16 </span>  puts(<span class="Special">"</span><span class="Constant"> String: '</span><span class="Special">#{</span>str<span class="Special">}</span><span class="Constant">'</span><span class="Special">"</span>)
<span class="lnr"> 17 </span>
<span class="lnr"> 18 </span>  <span class="Comment"># Write the current test string to a file called 'stdin'</span>
<span class="lnr"> 19 </span>  <span class="Type">File</span>.open(<span class="Special">"</span><span class="Constant">./stdin</span><span class="Special">"</span>, <span class="Special">"</span><span class="Constant">w</span><span class="Special">"</span>) <span class="Statement">do</span> |<span class="Identifier">f</span>|
<span class="lnr"> 20 </span>    f.write(str)
<span class="lnr"> 21 </span>  <span class="Statement">end</span>
<span class="lnr"> 22 </span>
<span class="lnr"> 23 </span>  <span class="Type">File</span>.open(<span class="Special">"</span><span class="Constant">./gdb</span><span class="Special">"</span>, <span class="Special">"</span><span class="Constant">w</span><span class="Special">"</span>) <span class="Statement">do</span> |<span class="Identifier">f</span>|
<span class="lnr"> 24 </span>  f.write <<<span class="Special">EOF</span>
<span class="lnr"> 25 </span><span class="Comment"># Set up the environment</span>
<span class="lnr"> 26 </span><span class="Statement">set</span> disassembly-flavor intel
<span class="lnr"> 27 </span><span class="Statement">set</span> <span class="Constant">confirm</span> off
<span class="lnr"> 28 </span>
<span class="lnr"> 29 </span><span class="Comment"># Disable the anti-debugging</span>
<span class="lnr"> 30 </span><span class="Statement">set</span> <span class="Constant">environment</span> LD_PRELOAD ./overload.so
<span class="lnr"> 31 </span>
<span class="lnr"> 32 </span><span class="Comment"># Read from the "stdin" file, which is where we're writing the data</span>
<span class="lnr"> 33 </span><span class="Statement">set</span> <span class="Constant">args</span> < ./stdin
<span class="lnr"> 34 </span>
<span class="lnr"> 35 </span><span class="Comment"># Break at the first check (the length)</span>
<span class="lnr"> 36 </span>b *<span class="Constant">0x040AC83</span>
<span class="lnr"> 37 </span><span class="Statement">run</span>
<span class="lnr"> 38 </span>
<span class="lnr"> 39 </span><span class="Comment"># Make all 4 checksums run by forcing jumps to happen</span>
<span class="lnr"> 40 </span><span class="Statement">set</span> {char}<span class="Constant">0x40AD50</span> = <span class="Constant">0xeb</span>
<span class="lnr"> 41 </span><span class="Statement">set</span> {char}<span class="Constant">0x40AE0F</span>  = <span class="Constant">0xeb</span>
<span class="lnr"> 42 </span>
<span class="lnr"> 43 </span><span class="Comment"># Checksum 1 and 2</span>
<span class="lnr"> 44 </span><span class="Statement">set</span> {int}<span class="Constant">0x040ADD3</span> = <span class="Constant">0x90909090</span>
<span class="lnr"> 45 </span><span class="Statement">set</span> {short}<span class="Constant">0x040ADD7</span> = <span class="Constant">0x9090</span>
<span class="lnr"> 46 </span>
<span class="lnr"> 47 </span><span class="Comment"># Checksum 3 and 4</span>
<span class="lnr"> 48 </span><span class="Statement">set</span> {int}<span class="Constant">0x040AEA1</span> = <span class="Constant">0x90909090</span>
<span class="lnr"> 49 </span><span class="Statement">set</span> {short}<span class="Constant">0x040AEA5</span> = <span class="Constant">0x9090</span>
<span class="lnr"> 50 </span>
<span class="lnr"> 51 </span><span class="Comment"># TODO: Test once mak finishes the python tool</span>
<span class="lnr"> 52 </span><span class="Comment"># Check adjacent characters</span>
<span class="lnr"> 53 </span><span class="Statement">set</span> {int}<span class="Constant">0x040AF08</span> = <span class="Constant">0x90909090</span>
<span class="lnr"> 54 </span><span class="Statement">set</span> {short}<span class="Constant">0x040AF0C</span> = <span class="Constant">0x9090</span>
<span class="lnr"> 55 </span>
<span class="lnr"> 56 </span><span class="Comment"># Checksum1</span>
<span class="lnr"> 57 </span>b *<span class="Constant">0x000000000040AD4C</span>
<span class="lnr"> 58 </span>
<span class="lnr"> 59 </span><span class="Comment"># Checksum2</span>
<span class="lnr"> 60 </span>b *<span class="Constant">0x000000000040AD92</span>
<span class="lnr"> 61 </span>
<span class="lnr"> 62 </span><span class="Comment"># Checksum3</span>
<span class="lnr"> 63 </span>b *<span class="Constant">0x000000000040AE0F</span>
<span class="lnr"> 64 </span>
<span class="lnr"> 65 </span><span class="Comment"># Checksum4</span>
<span class="lnr"> 66 </span>b *<span class="Constant">0x000000000040AE60</span>
<span class="lnr"> 67 </span>
<span class="lnr"> 68 </span>cont
<span class="lnr"> 69 </span>
<span class="lnr"> 70 </span><span class="Constant">print</span>/x <span class="Identifier">$r15</span>
<span class="lnr"> 71 </span>cont
<span class="lnr"> 72 </span>
<span class="lnr"> 73 </span><span class="Constant">print</span>/x <span class="Identifier">$r15</span>
<span class="lnr"> 74 </span>cont
<span class="lnr"> 75 </span>
<span class="lnr"> 76 </span><span class="Constant">print</span>/x <span class="Identifier">$r15</span>
<span class="lnr"> 77 </span>cont
<span class="lnr"> 78 </span>
<span class="lnr"> 79 </span><span class="Constant">print</span>/x <span class="Identifier">$r15</span>
<span class="lnr"> 80 </span>cont
<span class="lnr"> 81 </span>
<span class="lnr"> 82 </span><span class="Comment"># We continue before quitting so we can make sure 'Success!' is printed</span>
<span class="lnr"> 83 </span><span class="Statement">quit</span>
<span class="lnr"> 84 </span>
<span class="lnr"> 85 </span><span class="Special">EOF</span>
<span class="lnr"> 86 </span>  <span class="Statement">end</span>
<span class="lnr"> 87 </span>
<span class="lnr"> 88 </span>  checksums = []
<span class="lnr"> 89 </span>
<span class="lnr"> 90 </span>  <span class="Comment"># Our list of known-good checksums</span>
<span class="lnr"> 91 </span>  good_checksums = [<span class="Constant">0xFAF7F5FF</span>, <span class="Constant">0xA40121F</span>, <span class="Constant">0xFF77F7F6</span>, <span class="Constant">0xFD9E7F5F</span>]
<span class="lnr"> 92 </span>
<span class="lnr"> 93 </span>  <span class="Comment"># Run gdb with our new config file</span>
<span class="lnr"> 94 </span>  <span class="Type">IO</span>.popen(<span class="Special">"</span><span class="Constant">gdb -x ./gdb ./cnot</span><span class="Special">"</span>) {|<span class="Identifier">p</span>|
<span class="lnr"> 95 </span>    <span class="Statement">loop</span> <span class="Statement">do</span>
<span class="lnr"> 96 </span>      line = p.gets
<span class="lnr"> 97 </span>      <span class="Statement">if</span>(line.nil?)
<span class="lnr"> 98 </span>        <span class="Statement">break</span>
<span class="lnr"> 99 </span>      <span class="Statement">end</span>
<span class="lnr">100 </span>      <span class="Statement">if</span>(line =~ <span class="Special">/</span><span class="Constant"> = </span><span class="Special">/</span>)
<span class="lnr">101 </span>        checksums << line.gsub(<span class="Special">/</span><span class="Special">.</span><span class="Special">*</span><span class="Constant"> = </span><span class="Special">/</span>, <span class="Special">''</span>).chomp.to_i(<span class="Constant">16</span>)
<span class="lnr">102 </span>      <span class="Statement">end</span>
<span class="lnr">103 </span>
<span class="lnr">104 </span>      <span class="Statement">if</span>(line =~ <span class="Special">/</span><span class="Constant">Wrong</span><span class="Special">/</span>)
<span class="lnr">105 </span>        puts(line)
<span class="lnr">106 </span>        puts(<span class="Special">"</span><span class="Constant">ERROR!</span><span class="Special">"</span>)
<span class="lnr">107 </span>        <span class="Statement">exit</span>
<span class="lnr">108 </span>      <span class="Statement">end</span>
<span class="lnr">109 </span>    <span class="Statement">end</span>
<span class="lnr">110 </span>  }
<span class="lnr">111 </span>
<span class="lnr">112 </span>  puts(<span class="Special">"</span><span class="Constant"> Expected: %08x %08x %08x %08x</span><span class="Special">"</span> % [good_checksums[<span class="Constant">0</span>], good_checksums[<span class="Constant">1</span>], good_checksums[<span class="Constant">2</span>], good_checksums[<span class="Constant">3</span>]])
<span class="lnr">113 </span>  puts(<span class="Special">"</span><span class="Constant"> Received: %08x %08x %08x %08x</span><span class="Special">"</span> % [checksums[<span class="Constant">0</span>],      checksums[<span class="Constant">1</span>],      checksums[<span class="Constant">2</span>],      checksums[<span class="Constant">3</span>]])
<span class="lnr">114 </span>
<span class="lnr">115 </span>  <span class="Comment"># Count the different bits and print the difference</span>
<span class="lnr">116 </span>  diff = count_bits(good_checksums[<span class="Constant">0</span>] ^ checksums[<span class="Constant">0</span>]) + count_bits(good_checksums[<span class="Constant">2</span>] ^ checksums[<span class="Constant">2</span>]) + count_bits(good_checksums[<span class="Constant">1</span>] ^ checksums[<span class="Constant">1</span>]) + count_bits(good_checksums[<span class="Constant">3</span>] ^ checksums[<span class="Constant">3</span>])
<span class="lnr">117 </span>  puts(<span class="Special">"</span><span class="Constant"> Difference: %d</span><span class="Special">"</span> % diff)
<span class="lnr">118 </span>  puts()
<span class="lnr">119 </span>
<span class="lnr">120 </span>  <span class="Comment"># Return the difference so we can save the best one</span>
<span class="lnr">121 </span>  <span class="Statement">return</span> diff
<span class="lnr">122 </span><span class="rubyDefine">end</span>
<span class="lnr">123 </span>
<span class="lnr">124 </span>diffs = {}
<span class="lnr">125 </span>
<span class="lnr">126 </span><span class="Constant">?0</span>.upto(<span class="Constant">?9</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr">127 </span>  i = i.chr
<span class="lnr">128 </span>
<span class="lnr">129 </span>  str = <span class="Special">"</span><span class="Constant">where u </span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">quenTisTs naME?</span><span class="Special">"</span>
<span class="lnr">130 </span>    diff = go(str)
<span class="lnr">131 </span>
<span class="lnr">132 </span>    diffs[diff] = diffs[diff] || []
<span class="lnr">133 </span>    diffs[diff] << <span class="Special">"</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant"> :: </span><span class="Special">#{</span>str<span class="Special">}</span><span class="Special">"</span>
<span class="lnr">134 </span>  <span class="Statement">end</span>
<span class="lnr">135 </span>end
<span class="lnr">136 </span>
<span class="lnr">137 </span><span class="Comment"># Print the best option(s)</span>
<span class="lnr">138 </span>i = <span class="Constant">0</span>
<span class="lnr">139 </span><span class="Statement">loop</span> <span class="Statement">do</span>
<span class="lnr">140 </span>  <span class="Statement">if</span>(!diffs[i].nil?)
<span class="lnr">141 </span>    puts(<span class="Special">"</span><span class="Constant">== </span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant"> ==</span><span class="Special">\n</span><span class="Special">#{</span>diffs[i].join(<span class="Special">"</span><span class="Special">\n</span><span class="Special">"</span>)<span class="Special">}</span><span class="Special">"</span>)
<span class="lnr">142 </span>    <span class="Statement">exit</span>
<span class="lnr">143 </span>  <span class="Statement">end</span>
<span class="lnr">144 </span>
<span class="lnr">145 </span>  i += <span class="Constant">1</span>
<span class="lnr">146 </span><span class="Statement">end</span>
```

And in that particular configuration, the program attempts every possible number for the start of the third word:

```

<span class="lnr"> 1 </span><span class="perlVarPlain">$</span> ruby ./cs.rb
<span class="lnr"> 2 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 0quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr"> 3 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr"> 4 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f377f5e7 fd92ff7f
<span class="lnr"> 5 </span><span class="Statement"> Difference:</span> <span class="Constant">13</span>
<span class="lnr"> 6 </span>
<span class="lnr"> 7 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 1quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr"> 8 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr"> 9 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f377fde6 fd927fff
<span class="lnr">10 </span><span class="Statement"> Difference:</span> <span class="Constant">13</span>
<span class="lnr">11 </span>
<span class="lnr">12 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 2quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">13 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">14 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f377fde6 fd927f7f
<span class="lnr">15 </span><span class="Statement"> Difference:</span> <span class="Constant">12</span>
<span class="lnr">16 </span>
<span class="lnr">17 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 3quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">18 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">19 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f777f5f6 fd967f7f
<span class="lnr">20 </span><span class="Statement"> Difference:</span> <span class="Constant">8</span>
<span class="lnr">21 </span>
<span class="lnr">22 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 4quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">23 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">24 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f377f5ee ffd27f7f
<span class="lnr">25 </span><span class="Statement"> Difference:</span> <span class="Constant">14</span>
<span class="lnr">26 </span>
<span class="lnr">27 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 5quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">28 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">29 </span><span class="Statement"> Received:</span> fbfff5ff 1240021f f37ff5e6 fd927f7f
<span class="lnr">30 </span><span class="Statement"> Difference:</span> <span class="Constant">13</span>
<span class="lnr">31 </span>
<span class="lnr">32 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 6quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">33 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">34 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f377fde6 fd927f7f
<span class="lnr">35 </span><span class="Statement"> Difference:</span> <span class="Constant">12</span>
<span class="lnr">36 </span>
<span class="lnr">37 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 7quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">38 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">39 </span><span class="Statement"> Received:</span> fefff5ff 1240021f f377f5e6 fd927f7f
<span class="lnr">40 </span><span class="Statement"> Difference:</span> <span class="Constant">12</span>
<span class="lnr">41 </span>
<span class="lnr">42 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 8quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">43 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">44 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f3f7f5e6 fdd27f7f
<span class="lnr">45 </span><span class="Statement"> Difference:</span> <span class="Constant">13</span>
<span class="lnr">46 </span>
<span class="lnr">47 </span><span class="Statement"> String:</span> <span class="Constant">'</span><span class="Constant">where u 9quenTisTs naME?</span><span class="Constant">'</span>
<span class="lnr">48 </span><span class="Statement"> Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr">49 </span><span class="Statement"> Received:</span> fafff5ff 1240021f f377f5e6 fd927f7f
<span class="lnr">50 </span><span class="Statement"> Difference:</span> <span class="Constant">11</span>
<span class="lnr">51 </span>
<span class="lnr">52 </span>== <span class="Constant">8</span> ==
<span class="lnr">53 </span><span class="Constant">3</span> :: where u 3quenTisTs naME?
```

As you can see, the best result we got from this was eight bits different, and the number '3' (which tuned out to be correct)!

We did this over and over for different letters, occasionally repeating letters if we wound up getting bad results, getting closer. I considered writing an A\* search or something, I bet we could have optimized this pretty good, but that turned out to not be necessary. Eventually, I was reasonably sure everything was right except for the last two letters (in 'naME'), so I decided to try every possible pairing:

```

<span class="lnr"> 1 </span><span class="Constant">?a</span>.upto(<span class="Constant">?z</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr"> 2 </span>  i = i.chr
<span class="lnr"> 3 </span>  <span class="Constant">?A</span>.upto(<span class="Constant">?Z</span>) <span class="Statement">do</span> |<span class="Identifier">j</span>|
<span class="lnr"> 4 </span>    j = j.chr
<span class="lnr"> 5 </span>    str = <span class="Special">"</span><span class="Constant">where u 3quenTisTs na</span><span class="Special">#{</span>i<span class="Special">}#{</span>j<span class="Special">}</span><span class="Constant">?</span><span class="Special">"</span>
<span class="lnr"> 6 </span>    diff = go(str)
<span class="lnr"> 7 </span>
<span class="lnr"> 8 </span>    diffs[diff] = diffs[diff] || []
<span class="lnr"> 9 </span>    diffs[diff] &lt;&lt; <span class="Special">"</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant"> :: </span><span class="Special">#{</span>str<span class="Special">}</span><span class="Special">"</span>
<span class="lnr">10 </span>  <span class="Statement">end</span>
<span class="lnr">11 </span><span class="Statement">end</span>
```

And eventually, it printed out:

```

<span class="lnr"> 1 </span><span class="perlVarPlain">$</span> ruby cs.rb | tail
<span class="lnr"> 2 </span><span class="Statement">Received:</span> 7ef7f7ff 0240221f f7f7f5f6 fd96ffff
<span class="lnr"> 3 </span><span class="Statement">Difference:</span> <span class="Constant">13</span>
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span><span class="Statement">String:</span> <span class="Constant">'</span><span class="Constant">where u 3quenTisTs nazZ?</span><span class="Constant">'</span>
<span class="lnr"> 6 </span><span class="Statement">Expected:</span> faf7f5ff 0a40121f ff77f7f6 fd9e7f5f
<span class="lnr"> 7 </span><span class="Statement">Received:</span> 7ef7f5ff 0240421f f777f5fe fd977f7f
<span class="lnr"> 8 </span><span class="Statement">Difference:</span> <span class="Constant">11</span>
<span class="lnr"> 9 </span>
<span class="lnr">10 </span>== <span class="Constant">0</span> ==
<span class="lnr">11 </span>o :: where u 3quenTisTs naoW?
```

The answer! I punched it into the site, and it worked. omg!!! #bestfeelingever

## Conclusion

I realize this was an extremely long writeup, for an extremely elaborate level. It took a long time to solve, and I was exceptionally proud. Did I mention that, at 450 points, it was the most valuable flag in the entire competition?

Just to go over what I had to overcome:

- Anti-debugging
- Anti-reversing (obfuscation)
- More code obfuscation
- A series of "letter n is between x and y" type solutions, instead of actual "this letter is z" solutions
- Crazy checksums that, it turns out, used Fibonacci sequences (I never did reverse them)

And that's cnot in a nutshell. Thanks for reading!