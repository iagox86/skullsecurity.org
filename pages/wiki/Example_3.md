---
title: 'Wiki: Example 3'
author: ron
layout: wiki
permalink: "/wiki/Example_3"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_3"
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


This example is the implementation of strchr() found in Storm.dll, called SStrChr() (Storm_571).

Here is the prototype for this function:

`char *__stdcall SStrChr(const char *str, int c);`

And the summary of Linux\'s manpage for what strchr() does:

         The strchr() function locates the first occurrence of c (converted to a
         char) in the string pointed to by s.  The terminating null character is
         considered part of the string; therefore if c is `\0', the functions
         locate the terminating `\0'.

Below is the code, copied/pasted directly from IDA. The only thing different from IDA is that the addresses have been removed and the jump locations named. It would be a good exercise to use this opportunity to learn IDA a bit. Open \"storm.dll\" (any Blizzard game should have it) in IDA, go to the function list, and search for Storm_571.

                     push    ebp
                     mov     ebp, esp
                     mov     eax, [ebp+arg_0]
                     test    eax, eax
                     jnz     short loc_1

                     push    57h             ; dwErrCode
                     call    ds:SetLastError
                     xor     eax, eax
                     pop     ebp
                     retn    8
     ; ---------------------------------------------------------------------------

     loc_1:
                     mov     cl, [eax]
                     test    cl, cl
                     jz      short loc_3
                     mov     dl, [ebp+arg_4]
                     jmp     short loc_2
     ; ---------------------------------------------------------------------------

     loc_2:
                     cmp     cl, dl
                     jz      short loc_4
                     mov     cl, [eax+1]
                     inc     eax
                     test    cl, cl
                     jnz     short loc_2

     loc_3:
                     xor     eax, eax

     loc_4:
                     pop     ebp
                     retn    8

## Annotated Code {#annotated_code}

Please, try this yourself first!

Here, comments have been added explaining each line a little bit. These comments are added in an attempt to understand what the code\'s doing.

         push    ebp                ; Preserve ebp.
         mov     ebp, esp           ; Set up the frame pointer.
         mov     eax, [ebp+arg_0]   ; Move the first argument (that IDA has helpfully named) into eax. Recall that the first .
                                    ; argument is a pointer to the string. 
         test    eax, eax           ; Check if the string is 0. 
         jnz     short loc_1        ; Jump over the next section if eax is non-zero (presumably, a valid string).

         push    57h                ; dwErrCode = ERR_INVALID_PARAMETER.
         call    ds:SetLastError    ; This library function allows a program to set/retrieve the last error message. 
         xor     eax, eax           ; Clear eax (for a return 0).
         pop     ebp                ; Restore ebp.
         retn    8                  ; Return, removing both parameters from the stack.

     loc_1:
         mov     cl, [eax]          ; Recall that cl is a 1-byte value at the bottom of ecx. cl gets the character at [eax]
         test    cl, cl             ; Check if the character is '\0' (which indicates the end of the string).
         jz      short loc_3        ; If it's zero, then the character hasn't been found. Note that this differs from the
                                    ; actual strchr() command, since it won't detect the terminator '\0' if c is '\0'. 
         mov     dl, [ebp+arg_4]    ; Move the second parameter (named arg_4 by IDA, since it's 4-bytes into the parameter list
                                    ; list) into dl, which is the right-most byte of edx.
         jmp     short loc_2        ; Jump down to the next line (the compiler likely did something weird here, optimized 
                                    ; something out, perhaps).
     ; ---------------------------------------------------------------------------

     loc_2:
         cmp     cl, dl             ; Compare cl (the current character) to dl (the character being searched for).
         jz      short loc_4        ; If they're equal, jump down, returning eax (the remaining sub-string).
         mov     cl, [eax+1]        ; Move the next character into cl.
         inc     eax                ; Point ecx at the next character.
         test    cl, cl             ; Check if the string terminator has been found.
         jnz     short loc_2        ; Go to the top of this loop as long as the end of the string hasn't been reached. 

     loc_3:
         xor     eax, eax           ; Returns 0, indicating that the character was not found

     loc_4:
         pop     ebp                ; Restore ebp's previous value
         retn    8                  ; Return, removing 8 bytes (2 32-bit values) from the stack (the two parameters)

## C Code {#c_code}

This is the assembly directly converted to C. Because of some funny business with jumps, I had to move the loc_4 code up to the \"jz loc_4\" line. If somebody can think of a more direct way to convert this (without using a goto), I\'d like to hear it.

Note the driver function at the top \-- it\'s always important to do whatever you can to test the code, that way, it can be reduced and optimized and tested to ensure it still works.

    #include <stdio.h>

    /* Prototype */
    char *SStrChr(char *str, int c);

    int main(int argc, char *argv[])
    {
        char *test1 = "abcdefg";
        char *test2 = "Hellow World!";
        char *test3 = "Final Test!";

        printf("%s: '%s' == '%s'\n", test1, SStrChr(test1, 'c'), "cdefg");
        printf("%s: '%s' == '%s'\n", test1, SStrChr(test1, 'a'), "abcdefg");

        printf("%s: '%s' == '%s'\n", test2, SStrChr(test2, 'w'), "w World!");
        printf("%s: '%s' == '%s'\n", test2, SStrChr(test2, 'W'), "World!");

        printf("%s: '%s' == '%s'\n", test3, SStrChr(test3, ' '), " Test!");
        printf("%s: '%s' == '%s'\n", test3, SStrChr(test3, '!'), "!");

        return 0;
    }

    char *SStrChr(char *str, int c)
    {
        char *eax;
        int ebx, ecx, edx, esi, edi, ebp;

            //     push    ebp                ; Preserve ebp.
            //     mov     ebp, esp           ; Set up the frame pointer.
            //     mov     eax, [ebp+arg_0]   ; Move the first argument (that IDA has helpfully named) into eax. Recall that the first .
            //                                ; argument is a pointer to the string.
        eax = str;
            //     test    eax, eax           ; Check if the string is 0.
            //     jnz     short loc_1        ; Jump over the next section if eax is non-zero (presumably, a valid string).
        if(!eax)
        {
                //     push    57h                ; dwErrCode = ERR_INVALID_PARAMETER.
                //     call    ds:SetLastError    ; This library function allows a program to set/retrieve the last error message.
            /* No point in setting last error */
                //     xor     eax, eax           ; Clear eax (for a return 0).
                //     pop     ebp                ; Restore ebp.
                //     retn    8                  ; Return, removing both parameters from the stack.
            return 0;
                // loc_1:

## Cleaned up C Code {#cleaned_up_c_code}

As usual, this is the code with the comments removed and variable names cleaned up (the next example will be interesting, I promise!)

    char *SStrChr(char *str, int c)
    {
        char *eax;
        int ecx, edx;

        eax = str;
        if(!eax)
            return 0;

        ecx = (char) *eax;

        if(ecx)
        {
            edx = (char) c;

            do
            {
                if(ecx == edx)
                    return eax;

                ecx = *(eax + 1);
                eax++;
            }
            while(ecx);
        }

        return 0;
    }

## Reduced C Code {#reduced_c_code}

I\'m going to reduce this code faster than usual, since this code is actually shorter and simpler than other examples. Why wasn\'t this the first example then? Not sure!

First, rename variables, and remove some useless variable assignments:

    char *SStrChr(char *str, int c)
    {
        int thischar;

        if(!str)
            return 0;

        thischar = (char) *str;

        if(thischar)
        {
            do
            {
                if(thischar == c)
                    return str;

                str++;
                thischar = *str;
            }
            while(thischar);
        }

        return 0;
    }

## Finished Code {#finished_code}

Finally, an \"if\" outside of a \"do..while\" loop is identical to a \"while\" loop, so do that replacement. At the same time, move the assignment into the loop condition (rather than having it in two places). That leaves this function pretty clean:

    char *SStrChr(char *str, int c)
    {
        char thischar;

        if(!str)
            return 0;

        while(thischar = *str)
        {
            if(thischar == c)
                return str;

            str++;
        }

        return 0;
    }

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
