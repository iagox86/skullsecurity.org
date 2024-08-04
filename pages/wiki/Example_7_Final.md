---
title: 'Wiki: Example 7 Final'
author: ron
layout: wiki
permalink: "/wiki/Example_7_Final"
date: '2024-08-04T15:51:38-04:00'
---

    #include <stdio.h>
    #include <stdlib.h>
    #include <windows.h>

    /* This function displays a message on the screen for the specified number of seconds. */
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

    /* This function is called whenever a player spends money. */
    void __stdcall HackFunction(int player, int spent, int remaining)
    {
        char buffer[200];
        /* This address is an array of names. Recall that the player is left-shifted 
             * twice in the "SpendMoney" function, so the shift here ends up with the same 
             * number. */
        char *name = (char*) 0x6509e3 + ((player >> 2) * 36); 

        /* Create a string to display, then display it. */
        sprintf_s(buffer, 200, "\x04%s spent \x02%d \x04minerals, leaving him with %d", 
                      name, spent, remaining);
        DisplayMessage(buffer, 5);
    }

    BOOL APIENTRY DllMain( HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved)
    {
        /* This is the address in the game where the patch is going */
        int intAddressToPatch = 0x0040208F;

        /* This creates the wrapper, leaving an "????" where the call distance will be inserted. */
        static char strWrapper[] = "\x89\x90\x58\xee\x4f\x00\x60\x52\x51\x50\xe8????\x61\xc3";

        /* This sets the "????" in the string to equal the distance between HackFunction and from the byte immediately
         * after the ????, which is 12 bytes from the beginning of the string (that's where the relative distance
         * begins) */
        *((int*)(strWrapper + 11)) = ((int) &HackFunction) - ((int) strWrapper + 15); 

        /* This is the actual patch */
        char strPatch[] = "\xe8????\x90";

        /* This replaces the ???? with the distance from the patch to the wrapper. 5 is added because that's 
         * the length of the call instruction (e8 xx xx xx xx xx) and the distance is relative to the byte 
         * after the call. */
        *((int*)(strPatch + 1)) = ((int) &strWrapper) - (intAddressToPatch + 5);

        /* This is the original buffer, used when the .dll is removed (to restore the program's original 
         * functionality) */
        char *strUnPatch = "\x29\x90\x88\xee\x4f\x00";

        /* The process handle is required to write */
        HANDLE hProcess = GetCurrentProcess();

        switch(ul_reason_for_call)
        {
        case DLL_PROCESS_ATTACH:
            WriteProcessMemory(hProcess, (void*) intAddressToPatch, strPatch, 6, NULL);
            DisplayMessage("\x03 Demo Plugin Attached!", 10);
            break;

        case DLL_PROCESS_DETACH:
            WriteProcessMemory(hProcess, (void*) intAddressToPatch, strUnPatch, 6, NULL);
            DisplayMessage("\x03 Demo Plugin Removed!", 10);
            break;
        }
        return TRUE;
    }

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink") [Category: Assembly Guide](Category:_Assembly_Guide "wikilink")
