---
title: 'Wiki: Tools'
author: ron
layout: wiki
permalink: "/wiki/Tools"
date: '2024-08-04T15:51:38-04:00'
---

Please choose a tutorial page:

-   [Fundamentals](Fundamentals "wikilink") \-- Information about C
-   [Tools](Tools "wikilink")
-   [Registers](Registers "wikilink")
-   [Simple Instructions](Simple_Instructions "wikilink")
-   [Example 1](Example_1 "wikilink") \-- SC CDKey Initial Verification
-   [Example 2](Example_2 "wikilink") \-- SC CDKey Shuffle
-   [Example 2b](Example_2b "wikilink") \-- SC CDKey Final Decode
-   [The Stack](The_Stack "wikilink")
    -   [Stack Example](Stack_Example "wikilink")
-   [Functions](Functions "wikilink")
-   [Example 3](Example_3 "wikilink") \-- Storm.dll SStrChr
-   [Assembly Summary](Assembly_Summary "wikilink")
-   [Machine Code](Machine_Code "wikilink")
-   [Example 4](Example_4 "wikilink") \-- Smashing the Stack
-   [Cracking a Game](Cracking_a_Game "wikilink")
-   [Example 5](Example_5 "wikilink") \-- Cracking a game
-   [Example 6](Example_6 "wikilink") \-- Writing a keygen
-   [.dll Injection and Patching](.dll_Injection_and_Patching "wikilink")
-   [Memory Searching](Memory_Searching "wikilink")
-   [Example 7](Example_7 "wikilink") \-- Writing a cheat for Starcraft (1.05)
    -   [Example 7 Step 1](Example_7_Step_1 "wikilink") \-- Displaying Messages
    -   [Example 7 Step 1b](Example_7_Step_1b "wikilink") \-- Above, w/ func ptrs
    -   [Example 7 Final](Example_7_Final "wikilink")
-   [Example 8](Example_8 "wikilink") \-- Getting IX86.dll files
-   [16-bit Assembly](16-bit_Assembly "wikilink")
-   [Example 9](Example_9 "wikilink") \-- Keygen for a 16-bit game
-   [Example 10](Example_10 "wikilink") \-- Writing a loader

---


This page will discuss some important and recommended tools for reverse engineering and hack-writing. Some of these are free, and others are commercial. The only way to get commercial tools is by buying them, don\'t even think of finding a torrent.

If you know of any other tools that belong here, you\'re free to edit this page and add them.

## Disassemblers

-   [IDA - Interactive Disassembler](http://www.datarescue.com)

IDA is definitely the best disassembler around. Unfortunately it has a high price-tag, but it\'s well worth it. It\'s the program I\'ll be using throughout the guides here. It does a ton of analysis on the code, including naming variables used for library functions. It also keeps track of stack and local variables for you, with reasonable accuracy. Additionally, you can add your own comments and name variables yourself. It\'s really an amazing program, I highly recommend it.

-   [W32Dasm](http://www.javaop.com/~ron/programs/w32dsm.zip)

W32Dasm is free to download, and works well for a basic disassembler. The more difficult part about using W32Dasm is keeping track of stack variables. But if you can\'t afford IDA, it might be helpful.

-   [objdump](http://www.die.net/doc/linux/man/man1/objdump.1.html)

objdump is a very simple disassembler that generally comes with Linux. The command \"objdump -d \[filename\]\" outputs the assembly for the function:

    ron@slayer:~$ objdump -d test | head

    test:     file format elf32-i386

    Disassembly of section .init:

    08048278 <_init>:
     8048278:       55                      push   %ebp
     8048279:       89 e5                   mov    %esp,%ebp
     804827b:       83 ec 08                sub    $0x8,%esp
     804827e:       e8 61 00 00 00          call   80482e4 <call_gmon_start>

## Debuggers

-   [Debugging Tools for Windows](http://www.microsoft.com/whdc/devtools/debugging/default.mspx)

This is the debugger that I typically use, although I\'m not a huge fan of it. The interface is non-intuitive and difficult to use, and it\'s often a hassle. However, that being said, it\'s the best free debugger, and it\'s very powerful.

-   [IDA - Interactive Disassembler](http://www.datarescue.com)

In addition to being a first-class disassembler, IDA also has a built-in debugger. I haven\'t really used it, so I can\'t really say much.

-   [gdb](http://bama.ua.edu/cgi-bin/man-cgi?gdb)

gdb is the free GNU debugger that normally comes with Linux. It will be used for some examples here.

-   [OllyDbg](http://www.ollydbg.de)

Probably one of the most used debugger in Windows, OllyDbg has a very intuitive user interface.

-   [SoftICE](http://en.wikipedia.org/wiki/SoftICE)

Probably the best and most known kernel mode debugger, SoftICE provides a machine level debugging, but unfortunately, it isn\'t user friendly and is now discontinued.

-   [Immunity Debugger](http://www.immunityinc.com/products-immdbg.shtml)

An OllyDbg look with python scripting, made by and for the security oriented people (Fuzzer\'s + Exploits). Simple to use and comes with a graphical engine, and is free.

## Memory Editors {#memory_editors}

-   [TSearch](http://www.javaop.com/~ron/programs/tsearch.zip)

TSearch is a nice, free program to search and edit memory. It also has a very limited built-in debugger. Unfortunately, the official site is dead and it\'s no longer being maintained, which is unfortunate because it is such a nice program.

-   [ArtMoney](http://www.artmoney.ru/)

Same as above but just is a little bit different.

## Compilers

-   Microsoft Visual Studio

Although I don\'t like it, I develop hack-type programs in Visual Studio. Using special Windows functions is required, and I haven\'t figured out how to do that in any other compiler.

-   [gcc](http://bama.ua.edu/cgi-bin/man-cgi?gcc)

gcc is the free compiler that generally comes with Linux. I use this to compile most examples that I don\'t indicate as Visual Studio-specific. However, the code I write for gcc should also compile in Visual Studio, I just use gcc because it\'s quicker and more comfortable for me.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.
