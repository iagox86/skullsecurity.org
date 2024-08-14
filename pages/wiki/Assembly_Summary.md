---
title: 'Wiki: Assembly Summary'
author: ron
layout: wiki
permalink: "/wiki/Assembly_Summary"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Assembly_Summary"
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


This pretty much concludes the tutorial of assembly language. The commands and important information to do reverse engineering lies behind, the rest of the sections are more advanced topics that aren\'t necessarily required. This makes a good spot to stop and reflect on what has been explained.

If there is anything here that is confusing, going back to the section and re-read it, look at the examples (which should, more or less, cover everything taught), and if you still don\'t understand then post a question at the bottom of one of the pages, and I will attempt to clarify. I have attempted not to make assumptions on knowledge, but because I\'ve done so much of this I may take some things for granted, so feel free to question anything that\'s unclear!

## Fundamentals

To understand assembly well, you must have a firm understanding of the C language, especially the datatypes and pointers. Memory management is also very important!

## Tools

The following sections will use:

-   IDA
-   WinDbg
-   TSearch
-   Visual Studio .net

Additionally, for some examples (mostly hacking stuff, because hacking is more interesting/easier to demonstrate on Linux) I will use these Linux programs:

-   gcc
-   gdb

You don\'t necessarily need all of those, but they will make it easiest to follow.

## Registers

By now, you should hopefully be comfortable with registers. Remember that any general purpose register can be used for anything (with the exception of esp), but they each have common uses.

## Simple Instructions {#simple_instructions}

The instructions from this section are extremely important. They are by far the most common instructions, so knowing them without a reference is vital. For details on all instructions, you can download Intel\'s free manuals [here](http://www.intel.com/content/www/us/en/contentlibrary.html) by searching for \'Architectures Software Developer Manuals\'.

## The Stack {#the_stack}

Remember that the stack is used for storing temporary data, and is always growing and shrinking. All data below the stack pointer is assumed to be \"free\", even though it may contain data. The data below the stack is liable to be overwritten and destroyed, though.

## Functions

The main calling conventions are \_\_cdecl, \_\_stdcall, \_\_fastcall, and \_\_thiscall. Often all four are seen in any program.

An addition convention, \_\_declspec(naked), is used while writing hacks to tell the compiler to allow the programmer to write raw code.
