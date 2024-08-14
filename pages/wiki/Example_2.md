---
title: 'Wiki: Example 2'
author: ron
layout: wiki
permalink: "/wiki/Example_2"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_2"
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


This example is the first step in Starcraft\'s CDKey Decode. This shuffles the characters in the key in a predictable way. I made this the second example because it\'s a little trickier, but it\'s not terribly difficult.

As in the previous example, try figuring this out on your own first!

       lea     edi, [esi+0Bh]
       mov     ecx, 0C2h
    top:
       mov     eax, ecx
       mov     ebx, 0Ch
       cdq
       idiv    ebx
       mov     al, [edi]
       sub     ecx, 11h
       dec     edi
       cmp     ecx, 7
       mov     bl, [edx+esi]
       mov     [edi+1], bl
       mov     [edx+esi], al
       jge     top

## Annotated Code {#annotated_code}

Here, comments have been added explaining each line a little bit. These comments are added in an attempt to understand what the code\'s doing.

       ; This is actually continued from the last example, so esi contains the verified CDKey. 
       lea     edi, [esi+0Bh]   ; edi is a pointer to the 12th character in the cdkey (0x0b = 11, and arrays start at 0).
       mov     ecx, 0C2h        ; Set ecx to 0xC2. Recall that ecx is often a loop counter. 
    top:
       mov     eax, ecx         ; Move the loop counter to eax.
       mov     ebx, 0Ch         ; Set ebx to 0x0C (0x0C = 12, and arrays are indexed from 0, so the CDKey string goes from 0 to 12).
       cdq                      ; Get ready for a signed division.
       idiv    ebx              ; Divide the loop counter by 0x0C. It isn't clear yet whether this is division or modulus, but
                                ; because an accumulator is being divided by the CDKey length, it's logical to assume that 
                                ; this is modular division. edx will likely be used, and eax will likely be overwritten. 

       mov     al, [edi]        ; Move the value that edi points to (which is a character in the CDKey) to al. Recall that al is the
                                ; right-most byte in eax. This confirms two things: that edi points to a character in the CDKey
                                ; (since a character is 1 byte) and that the division above is modulus (because eax is overwritten). 
       sub     ecx, 11h         ; Subtract 0x11 from ecx. Recall that ecx is often a loop counter, and likely is in this case. 
       dec     edi              ; Decrement the pointer into the CDKey. edi started at the 12th character and is moving backwards. 
       cmp     ecx, 7           ; Compare ecx to 7, which confirms that ecx is the loop counter. The jump corresponding to this
                                ; comparison is a few lines below. 
       mov     bl, [edx+esi]    ; Recall that edx is the remainder from the above division, which is (accumulator % 12), and that 
                                ; esi points to the CDKey. So this takes the character corresponding to the accumulator and moves
                                ; it into bl, which is the right-most byte of ebx. 
       mov     [edi+1], bl      ; Overwrite the character that edi pointed to at the top of the loop. Recall that [edi] is moved 
                                ; into al, then decremented above, which is why this is +1 (to offset the decrement). 
       mov     [edx+esi], al    ; Move al into the string corresponding to the modular division. 
       jge     top              ; Jump as long as the ecx counter is greater than or equal to 7
                                ;
                                ; Note that the loop here is simply a swap. edi decrements, starting from the 12th character and
                                ; moving backwards. ecx is reduced by 0x11 each time, and the character at (ecx % 12) is swapped
                                ; with the character pointed at by edi. 

## C Code {#c_code}

Please, try this yourself first!

This is an absolutely direct conversion from the annotated assembly to C. I added a main function that sends a bunch of test keys through the function to print out the results.

Now that a driver function can test the CDKey shuffler, the code can be reduced and condensed.

    #include <stdio.h>

    /* Prototype */
    void shuffleCDKey(char *key);

    int main(int argc, char *argv[])
    {
        /* A series of test cases (I'm using fake keys here obviously, but real ones work even better) */
        char keys[3][14] = { "1212121212121", /* Valid */
                            "1234567890123", /* Valid */
                            "4962883551538" /* Valid */
                       };
        char *results[]  = { "1112222221111",
                            "7130422865193",
                            "3461239588558" };


        int i;

        for(i = 0; i < 3; i++)
        {
            printf("Original:  %s\n", keys[i]);
            shuffleCDKey(keys[i]);
            printf("Shuffled:  %s\n", keys[i]);
            printf("Should be: %s\n\n", results[i]);
        }

        return 0;
    }

    void shuffleCDKey(char *key)
    {
        int  eax,  ebx, ecx, edx;
        char *esi;
        char *edi;

        esi = key;

            //   ; This is actually continued from the last example, so esi contains the verified CDKey.
            //   lea     edi, [esi+0Bh]   ; edi is a pointer to the 12th character in the cdkey (0x0b = 11, and arrays start at 0).
        edi = (esi + 0x0b);
            //   mov     ecx, 0C2h        ; Set ecx to 0xC2. Recall that ecx is often a loop counter.
        ecx = 0xc2;
            //top:
        do
        {
                //   mov     eax, ecx         ; Move the loop counter to eax.
            eax = ecx;
                //   mov     ebx, 0Ch         ; Set ebx to 0x0C (0x0C = 12, an arrays are indexed from 0, so the CDKey string goes from 0 to 12).
            ebx = 0x0c;
                //   cdq                      ; Get ready for a signed division.
                //   idiv    ebx              ; Divide the loop counter by 0x0C. It isn't clear yet whether this is division or modulus, but
                //                            ; because an accumulator is being divided by the CDKey length, it's logical to assume that
                //                            ; this is modular division. edx will likely be used, and eax will likely be overwritten.
            edx = eax % ebx;
                //
                //   mov     al, [edi]        ; Move the value that edi points to (which is a character in the CDKey) to al. Recall that al is the
                //                            ; right-most byte in eax. This confirms two things: that edi points to a character in the CDKey
                //                            ; (since a character is 1 byte) and that the division above is modulus (because eax is overwritten).
            eax = (char) *edi;

                //   sub     ecx, 11h         ; Subtract 0x11 from ecx. Recall that ecx is often a loop counter, and likely is in this case.
            ecx = ecx - 0x11;
                //   dec     edi              ; Decrement the pointer into the CDKey. edi started at the 12th character and is moving backwards.
            edi--;
                //   cmp     ecx, 7           ; Compare ecx to 7, which confirms that ecx is the loop counter. The jump corresponding to this
                //                            ; comparison is a few lines below.
            /* will handle this compare later */
                //   mov     bl, [edx+esi]    ; Recall that edx is the remainder from the above division, which is (accumulator % 12), and that
                //                            ; esi points to the CDKey. So this takes the character corresponding to the accumulator and moves
                //                            ; it into bl, which is the right-most byte of ebx.
            ebx = (char) *(edx + esi);
                //   mov     [edi+1], bl      ; Overwrite the character that edi pointed to at the top of the loop. Recall that [edi] is moved
                //                            ; into al, then decremented above, which is why this is +1 (to offset the decrement).
            *(edi + 1) = (char) ebx;
                //   mov     [edx+esi], al    ; Move al into the string corresponding to the modular division.
            *(edx + esi) = (char) eax;
                //   jge     top              ; Jump as long as the ecx counter is greater than or equal to 7
        }
        while(ecx >= 7);
                //                            ;
                //                            ; Note that the loop here is simply a swap. edi decrements, starting from the 12th character and
                //                            ; moving backwards. ecx is reduced by 0x11 each time, and the character at (ecx % 12) is swapped
                //                            ; with the character pointed at by edi.
                //
    }

## Cleaned up C Code {#cleaned_up_c_code}

Here\'s the code after removing the assembly, fixing up the variable declarations, and changing hex values to decimal:

    void shuffleCDKey(char *key)
    {
        char *esi = key;
        char *edi = esi + 11;

        int ecx = 0xc2;
        int  eax,  ebx, edx;

        do
        {
            eax = ecx;
            ebx = 12;
            edx = eax % ebx;
            eax = (char) *edi;
            ecx = ecx - 17;
            edi--;
            ebx = (char) *(edx + esi);
            *(edi + 1) = (char) ebx;
            *(edx + esi) = (char) eax;
        }
        while(ecx >= 7);
    }

## Reduced C Code {#reduced_c_code}

This code works, and can be used. However, for this exercise, reducing it all the way helps.

Some variables are substituted where they aren\'t necessary:

    void shuffleCDKey(char *key)
    {
        char *esi = key;
        char *edi = esi + 11;

        int ecx = 0xc2;
        int  eax,  ebx, edx;

        do
        {
            edx = ecx % 12;
            eax = (char) *edi;
            ecx = ecx - 17;
            edi--;
            *(edi + 1) = (char) *(edx + esi);
            *(edx + esi) = (char) eax;
        }
        while(ecx >= 7);
    }

Change the do loop to a for loop, rename ecx, and change the decrement of edi to the bottom of the loop:

    void shuffleCDKey(char *key)
    {
        char *esi = key;
        char *edi = esi + 11;

        int i;
        int  eax,  ebx, edx;

        for(i = 0xc2; i >= 7; i -= 17)
        {
            edx = i % 12;
            eax = (char) *edi;
            *edi = (char) *(edx + esi);
            *(edx + esi) = (char) eax;
            edi--;
        }
    }

Replace esi with key, change pointers to arrays, declare eax as a char (to remove typecasting):

    void shuffleCDKey(char *key)
    {
        char *edi = key + 11;

        int i;
        char eax;
        int  ebx, edx;

        for(i = 0xc2; i >= 7; i -= 17)
        {
            edx = i % 12;
            eax = *edi;
            *edi = key[edx];
            key[edx] = eax;
            edi--;
        }
    }

Replacing the variable swap with a swap() function cleans things up significantly:

    void swap (char *a, char *b)
    {
        char temp = *a;
        *a = *b;
        *b = temp;
    }

    void shuffleCDKey(char *key)
    {
        char *edi = key + 11;

        int i;
        char eax;
        int  ebx, edx;

        for(i = 0xc2; i >= 7; i -= 17)
        {
            edx = i % 12;
            swap(edi, key + edx);
            edi--;
        }
    }

## Finished Code {#finished_code}

Finally, rename some variables, eliminate unused variables, and combine where possible, leaving this slick little function:

    void shuffleCDKey(char *key)
    {
        char *position = key + 11;
        int i;
        for(i = 194; i >= 7; i -= 17)
            swap(position--, key + (i % 12));
    }

And that\'s it! Testing it with the driver function verifies that it still works.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
