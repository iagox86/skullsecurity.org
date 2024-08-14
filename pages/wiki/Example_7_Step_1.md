---
title: 'Wiki: Example 7 Step 1'
author: ron
layout: wiki
permalink: "/wiki/Example_7_Step_1"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_7_Step_1"
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


    #include <stdio.h>
    #include <windows.h>

    void __stdcall DisplayMessage(char *strMessage, int intDurationInSeconds)
    {
        int intDisplayUntil = GetTickCount() + (intDurationInSeconds * 1000);
        int fcnDisplayMessage = 0x469380;

        __asm
        {
            push 0
            push intDisplayUntil
            mov  edx, 0
            mov  ecx, strMessage
            call fcnDisplayMessage
        }
    }

    BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
    {
        switch(ul_reason_for_call)
        {
        case DLL_PROCESS_ATTACH:
            DisplayMessage("\x03Loading test plugin", 30);
            break;

        case DLL_PROCESS_DETACH:
            DisplayMessage("\x03Unloading test plugin", 30);
            break;
        }

        return TRUE;
    }

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
