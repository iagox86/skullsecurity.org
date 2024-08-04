---
title: 'Wiki: Stack Example'
author: ron
layout: wiki
permalink: "/wiki/Stack_Example"
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


This code should compile and run in Visual Studio (I\'ve tested it):

    #include <stdio.h>

    void __declspec(naked) swap(int *a, int *b)
    {
        __asm
        {
            push ebp             ; Preserve ebp.
            mov ebp, esp         ; Set up the frame pointer.
            sub esp, 8           ; Make room for two local variables.
            push esi             ; Preserve esi on the stack.
            push edi             ; Preserve edi on the stack.

            mov ecx, [ebp+8]     ; Put the first parameter (a pointer) into ecx.
            mov edx, [ebp+12]    ; Put the second parameter (a pointer) into edx.

            mov esi, [ecx]       ; Dereference the pointer to get the first parameter.
            mov edi, [edx]       ; Dereference the pointer to get the second parameter.

            mov [ebp-4], esi     ; Store the first as a local variable
            mov [ebp-8], edi     ; Store the second as a local variable
            
            mov esi, [ebp-8]     ; Retrieve them in reverse
            mov edi, [ebp-4]

            mov [ecx], esi       ; Put the second value into the first address.
            mov [edx], edi       ; Put the first value into the second address.
            
            pop edi              ; Restore the edi register
            pop esi              ; Restore the esi register
            add esp, 8           ; Remove the local variables from the stack
            pop ebp              ; Restore ebp
            ret                  ; Return (eax isn't set, so there's no return value)
        }
    }

    int main(int argc, char* argv[])
    {
        int a = 3; 
        int b = 4;

        printf("a = %d, b = %d\n", a, b);
        swap(&a, &b);
        printf("a = %d, b = %d\n", a, b);

        while(1)
            ;

        return 0;
    }

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
