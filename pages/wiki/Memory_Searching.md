---
title: 'Wiki: Memory Searching'
author: ron
layout: wiki
permalink: "/wiki/Memory_Searching"
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


This is going to be a fairly quick introduction to memory searching, which is the process of finding a variable in memory.

The essential idea is to use a program (such as TSearch) to search memory for a specific value. Say, your health. There will be a million instances of most numbers in memory, which is expected. After the initial search, you do something that changes that value, and search again within the initial set for the new value. This process is repeated as many times as necessary until only a single or a couple values remain.

If a couple values remain and won\'t go away, it is likely that all the locations except for one are copies of the original data. For example, when your health is displayed, a copy might be made in the display buffer. In this case, trial and error must be used. Each value should be changed and tested until only one remains.

Once the actual value is found, the memory searching is done.

## TSearch

In TSearch, this process is simple. Here are the steps:

-   Load your game to where you want to be.
-   Remember the initial value that you\'re trying to find.
-   Minimize the game, and load TSearch.
-   Choose \"Open Process\" in TSearch, and select the game you want.
-   At the left, under \"Open Process\", you should see a magnifying glass; click it.
-   Type in the value, and take a guess at the datatype. If the number is small, and doesn\'t pass 200, pick \"1 byte\". If the number is always less than 65000, pick \"2 bytes\". Otherwise, pick \"4 bytes\" or \"8 bytes\". If you aren\'t sure, aim lower.
-   Press \"OK\" and wait until it\'s done searching.
-   Go back to the game and make the value change.
-   Click the magnifying glass with the \"\...\" and type in the new value.
-   Repeat as long as necessary.

## AutoHack

TSearch has a useful feature called \"AutoHack\". AutoHack can tell you where, in the assembly, the address is used. This can be done with an ordinary debugger, but is much more convenient with TSearch.

To use AutoHack on the value you\'ve found, do the following:

-   Select \"Enable Debugger\" under the \"AutoHack\" menu. Once this is enabled, the game must be restarted to disable it.
-   In the left pane, where the variables are displayed, double-click on the variable you wish to find. It should be copied to the right pane.
-   Right-click on the row in the right pane, and select \"AutoHack\".
-   Select \"AutoHack Window\" under the AutoHack menu.
-   Go into the game and do something to change the value.
-   Go back to the \"AutoHack Window\" and look in the bottom pane \-- unless the game does something to break TSearch, the address(es) in code where the data was modified should be shown.
