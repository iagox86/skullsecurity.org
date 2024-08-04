---
title: 'Wiki: 16-bit Assembly'
author: ron
layout: wiki
permalink: "/wiki/16-bit_Assembly"
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


Older software, before 32-bit was common, was written in 16-bit x86 assembly. Although it is rare to come across, it does happen. This section will talk about some of the challenges to cracking a 16-bit program.

Thankfully, IDA supports 16-bit programs as well as 32-bit programs. That means that, if nothing else, a friendly disassembler is available to assist with reverse engineering.

W32Dasm also works well on 16-bit programs.

## Challenges

There are many challenges with cracking a 16-bit game that aren\'t present in modern 32-bit programs. Some examples of issues are:

-   Debuggers don\'t work unless they\'re specially designed, since 16-bit programs run in a virtual machine.
-   Small segments means code is more spread out.
-   Different uses for registers/instructions.

This section will address the final point, since that\'s the only really necessary tool.

## Registers

The general purpose registers are similar, with one exception: the 32-bit registers no longer exist. That means that the registers available are:

-   ax
-   bx
-   cx
-   dx
-   si
-   di
-   bp
-   sp

Another change is in the instruction pointer, eip \-- the instruction pointer is now split into two parts, cs and ip. cs points to the current code segment and ip points to the current instruction within that segment.

The reason for this change is because a 16-bit register only has a 65536-value range, and most programs are more than 64k big.

(Technically, 32-bit code actually uses cs along with eip in the same way, but most of the time we don\'t care about this and always use the same segment for everything, unless we\'re writing a DPMI implementation or a win16 compatibility layer or the like, which \*must\* be concerned with such things.)

## Instructions

The main differences in instructions is that the instructions that operate on 64-bit values stored in register pairs (such as div and mul) now operate on 32-bit values. That means that any instruction that uses edx:eax now uses dx:ax.
