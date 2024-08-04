---
title: 'Wiki: Example 6'
author: ron
layout: wiki
permalink: "/wiki/Example_6"
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


The previous example demonstrates how to crack a game. This example goes one step further and demonstrates how to write a keygen for that game.

As with the previous example, if you want the name of the game, please contact me privately \-- if I know you, I\'ll let you know which game and where to find it. If I don\'t know you, I won\'t be able to tell you. I\'m not sure what the legality of this is, but I don\'t want to piss anybody off.

## Unregistering the Game {#unregistering_the_game}

To unregister the game, go into the \"data\" folder in the program\'s directory and delete the newest file.

## The Next Step {#the_next_step}

Recall this code from the previous example:

        push    ebp
        mov     ebp, esp
        movsx   eax, word_111111
        push    eax
        call    sub_222222
        pop     ecx
        cmp     word_333333, ax
        jnz     short registerfail
        mov     ds:IsRegistered, 1      ; <--------- You end up here
        jmp     short endfunction

    registerfail:
        mov     ds:IsRegistered, 0

    endfunction:
        mov     esp, ebp
        pop     ebp
        retn

We determined that \"call sub_222222\" likely converts the registration code to the key expected from the user. With this in mind, double-click on the function and have a look at the code. I\'ll post the exact code from the function here, and as usual I recommend you try and figure it out on your own. Can you write a keygen without peaking at my code?

When looking over this, note that it\'s just a series of divisions and multiplications of the parameter. The divisions all use \"edx\", which means that they\'re modular divisions. Note that the multiplications use two parameters, which means that the result is stored in the first one, not in edx:eax (see the section on instructions if you don\'t remember this \-- there\'s a good chance that you don\'t remember reading it because I just added it).

Here\'s the code:

        GenerateCode proc near

        arg_0= dword ptr  8

        push    ebx
        mov     edx, [esp+arg_0] ; edx gets the reg code
        xor     ebx, ebx
        mov     ebx, edx
        lea     eax, [edx+7]
        imul    ebx, eax
        lea     ebx, [ebx+33h]
        mov     ecx, 8085h
        mov     eax, ebx
        cdq
        idiv    ecx
        mov     ebx, edx
        imul    ebx, 4Fh
        mov     ecx, 702Fh
        mov     eax, ebx
        cdq
        idiv    ecx
        mov     ebx, edx
        shl     ebx, 5
        lea     eax, [edx+edx*2]
        sub     ebx, eax
        mov     ecx, 47A9h
        mov     eax, ebx
        cdq
        idiv    ecx
        mov     ebx, edx
        imul    ebx, 2DBh
        mov     ecx, 2710h
        mov     eax, ebx
        cdq
        idiv    ecx
        mov     ebx, edx
        lea     eax, [ebx+2710h]
        pop     ebx
        retn

        GenerateCode endp

## C Code {#c_code}

In previous examples, I documented every line. This code, however, is actually extremely simplistic, so I won\'t bother spending time going through every line. Instead, I\'ll go straight to C code:

    #include <stdio.h>

    int GenerateKey(int code)
    {
            //    push    ebx
            //    mov     edx, [esp+arg_0] ; edx gets the reg code
        int edx = code;
            //    xor     ebx, ebx
        int ebx = 0;
            //    mov     ebx, edx
        ebx = edx;
            //    lea     eax, [edx+7]
        int eax = edx + 7;
            //    imul    ebx, eax
        ebx = ebx * eax;
            //    lea     ebx, [ebx+33h]
        ebx = ebx + 0x33;
            //    mov     ecx, 8085h
        int ecx = 0x8085;
            //    mov     eax, ebx
        eax = ebx;
            //    cdq
            //    idiv    ecx
        edx = eax % ecx;
            //    mov     ebx, edx
        ebx = edx;
            //    imul    ebx, 4Fh
        ebx = ebx * 0x4f;
            //    mov     ecx, 702Fh
        ecx = 0x702f;
            //    mov     eax, ebx
        eax = ebx;
            //    cdq
            //    idiv    ecx
        edx = eax % ecx;
            //    mov     ebx, edx
        ebx = edx;
            //    shl     ebx, 5
        ebx = ebx << 5;
            //    lea     eax, [edx+edx*2]
        eax = edx + edx*2;
            //    sub     ebx, eax
        ebx = ebx - eax;
            //    mov     ecx, 47A9h
        ecx = 0x47a9;
            //    mov     eax, ebx
        eax = ebx;
            //    cdq
            //    idiv    ecx
        edx = eax % ecx;
            //    mov     ebx, edx
        ebx = edx;
            //    imul    ebx, 2DBh
        ebx = ebx * 0x2db;
            //    mov     ecx, 2710h
        ecx = 0x2710;
            //    mov     eax, ebx
        eax = ebx;
            //    cdq
            //    idiv    ecx
        edx = eax % ecx;
            //    mov     ebx, edx
        ebx = edx;
            //    lea     eax, [ebx+2710h]
        eax = ebx + 0x2710;
            //    pop     ebx
            //    retn
        return eax;
    }

    int main(int argc, char *argv[])
    {
        int code;
        int key;

        printf("Please enter your code --> ");
        scanf("%d", &code);
        key = GenerateKey(code);

        printf("\nYour code: %d\n\n", key);
    }

## Cleaned Up C Code {#cleaned_up_c_code}

    int GenerateKey(int code)
    {
        int edx = code;
        int ebx = 0;
        ebx = edx;
        int eax = edx + 7;
        ebx = ebx * eax;
        ebx = ebx + 0x33;
        int ecx = 0x8085;
        eax = ebx;
        edx = eax % ecx;
        ebx = edx;
        ebx = ebx * 0x4f;
        ecx = 0x702f;
        eax = ebx;
        edx = eax % ecx;
        ebx = edx;
        ebx = ebx << 5;
        eax = edx + edx*2;
        ebx = ebx - eax;
        ecx = 0x47a9;
        eax = ebx;
        edx = eax % ecx;
        ebx = edx;
        ebx = ebx * 0x2db;
        ecx = 0x2710;
        eax = ebx;
        edx = eax % ecx;
        ebx = edx;
        eax = ebx + 0x2710;
        return eax;
    }

## Reduced C Code {#reduced_c_code}

Basically, to reduce this code, just go from top to bottom and combine the variables, which will easily go this far:

    int GenerateKey(int code)
    {
        int edx = ((((code * (code + 7)) + 0x33) % 0x8085) * 0x4f) % 0x702f;
        int ebx = edx;
        int ecx, eax;

        ebx = ebx << 5;
        eax = edx + edx*2;
        ebx = ebx - eax;
        ecx = 0x47a9;
        eax = ebx;
        edx = eax % ecx;
        ebx = edx;
        ebx = ebx * 0x2db;
        ecx = 0x2710;
        eax = ebx;
        edx = eax % ecx;
        ebx = edx;
        eax = ebx + 0x2710;
        return eax;
    }

## Finished Code {#finished_code}

After reducing the code as far as possible, and using the \"code\" variable instead of registers, here is the final code:

    int GenerateKey(int code)
    {
        code = ((((code * (code + 7)) + 0x33) % 0x8085) * 0x4f) % 0x702f;
        return (((((code << 5) - (code * 3)) % 0x47a9) * 0x2db) % 0x2710) + 0x2710;
    }

I have verified that that code does indeed work.

As I said before, this was for educational purposes only, if you actually want to play the game, please buy it!

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
