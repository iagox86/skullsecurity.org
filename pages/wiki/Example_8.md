---
title: 'Wiki: Example 8'
author: ron
layout: wiki
permalink: "/wiki/Example_8"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_8"
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


This is going to be a fairly short tutorial, but it will explain how to grab The IX86\...dll files used by Starcraft (and other games) to perform version checking. This will be done on the latest version of Starcraft, since it\'s the only one that can authenticate to the server.

The most common way to get the files is by downloading them directly from the Battle.net FTP server, but that involves either an external program or reverse engineering. This method will let the game download them for us!

## Finding the Deletion {#finding_the_deletion}

First, load battle.snp in IDA. battle.snp is the library that takes care of battle.net connectivity. Click on the \"Names\" window and search for \"LoadLibraryA\". Double-click it, the press ctrl-x to view cross references.

Go through each of the cross references and look for one that loads a variable dll name.

I found the proper one on the fifth cross reference. The code is pretty obvious (although IDA makes some mistakes in this function, we\'ll talk about that at another time):

`.text:19021A02                 push    edx             ; lpLibFileName`\
`.text:19021A03                 call    ds:LoadLibraryA`\
`.text:19021A09                 mov     esi, eax`\
`.text:19021A0B                 cmp     esi, ebx`\
`.text:19021A0D                 mov     [ebp+hLibModule], esi`\
`.text:19021A10                 jz      loc_19021AEE`\
`.text:19021A16                 push    offset aCheckrevision ; "CheckRevision"`\
`.text:19021A1B                 push    esi             ; hModule`\
`.text:19021A1C                 call    ds:GetProcAddress`

A variable library is loaded (edx), then the address for a function called CheckRevision is found.

So at this point, the physical file exists. One option is to load this into a debugger and break here, then make a copy of the .dll. But that\'s no fun, I\'d prefer to stop it from being deleted altogether!

Scroll down for awhile, and eventually you\'ll see this:

    .text:19021AFB                 push    32h             ; dwMilliseconds
    .text:19021AFD                 call    ds:Sleep
    .text:19021B03                 mov     esi, ds:DeleteFileA
    .text:19021B09                 push    offset byte_1903C108 ; lpFileName
    .text:19021B0E                 call    esi ; DeleteFileA
    .text:19021B10                 cmp     [ebp+NumberOfBytesWritten], bl
    .text:19021B16                 jz      short loc_19021B21
    .text:19021B18                 lea     ecx, [ebp+NumberOfBytesWritten]
    .text:19021B1E                 push    ecx             ; lpFileName
    .text:19021B1F                 call    esi ; DeleteFileA

Two files are being deleted here. Presumably, one of them is the .mpq and the other is the .dll. We\'re going to want to skip over both of those calls.

So here\'s what we have to do:

-   Remove those calls (*including the push, otherwise the stack will break*)
-   Connect to Battle.net

## Removing the Calls {#removing_the_calls}

Run Starcraft, and open it in a debugger (I\'ve found that TSearch can\'t find this version of Starcraft in memory). Search for the address 0x19021b09.

Not there? Uh oh!

The problem we\'ve run into is that battle.snp isn\'t loaded until Starcraft connects to Battle.net. Loading it with the \"Injector\" program doesn\'t even work \-- Blizzard\'s tried hard to break hacks!

But that\'s fine, we can go one step further and just disable DeleteFileA altogether. It\'s not like Starcraft really needs to be deleting my files anyways!

Ensuring the game\'s execution is stopped, go to the disassembly window on your debugger and type \"DeleteFileA\". It should show you a kernel32 function. Open the memory window and do the same. In the memory window, replace the first three bytes with C2 04 00 (which is \"ret 4\"). Add 90\'s to pad it if you end up with weird instructions, although it doesn\'t really matter.

Once the DeleteFileA call has been removed, go back to the game, and log into Battle.net. The login should succeed (since our patch wasn\'t in any of the actual Starcraft files). Alt-tab and go into Starcraft\'s folder. The .mpq and .dll file should be there!

In theory, it\'s possible to force Starcraft to download the .dll file of your choice, by editing incoming traffic or getting a breakpoint in Battle.snp, but just connecting to Battle.net until you have them all is probably the easiest way.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
