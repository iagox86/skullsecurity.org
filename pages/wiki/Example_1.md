---
title: 'Wiki: Example 1'
author: ron
layout: wiki
permalink: "/wiki/Example_1"
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


Welcome to the first assembly example! If you have read and understood all the sections up to here, there will not be any surprises.

The code shown below verifies that a CDKey is valid to install the game with. If the CDKey fails to pass this check, the CDKey may not be used to install the game. Whether this succeeds or fails has no bearing on whether the CDKey is valid to log onto Battle.net with.

The way one should approach this is to to do the following:

1.  Copy all the assembly code to your IDE or somewhere safe.
2.  Go through each line, and make a note of what it does (typically, putting a ; at the end and adding a comment works well). Try and understand what the code is doing.
3.  Go through each line, and convert it to the equivalent C code (or Java, if you\'re more comfortable with that).
4.  Try and combine and reduce the code to make it as simple as possible.

I\'ll go through those steps here, hopefully to give an idea of how to approach a function such as this. I highly recommend you try it yourself first, though.

## Code

       ; Note: ecx is a pointer to a 13-digit Starcraft cdkey
       ; This is a function that returns 1 if it's a valid key, or 0 if it's invalid
       mov     eax, 3
       mov     esi, ecx
       xor     ecx, ecx
     Top:
       movsx   edx, byte ptr [ecx+esi]
       sub     edx, 30h
       lea     edi, [eax+eax]
       xor     edx, edi
       add     eax, edx
       inc     ecx
       cmp     ecx, 0Ch
       jl      short Top

       xor     edx, edx
       mov     ecx, 0Ah
       div     ecx

       movsx   eax, byte ptr [esi+0Ch]
       add     edx, 30h
       cmp     eax, edx
       jnz     bottom

       mov     eax, 1
       ret

     bottom:
       xor     eax, eax
       ret

## Annotated Code {#annotated_code}

Please, try this yourself first!

I\'ve been over this code a dozen times, so I know it very well. I\'ve tried to annotate it as clearly as possible.

       ; Note: ecx is a pointer to a 13-digit Starcraft cdkey
       ; This is a function that returns 1 if it's a valid key, or 0 if it's invalid
       mov     eax, 3                  ; Set eax to 3
       mov     esi, ecx                ; Move the cdkey pointer to esi. It'll likely stay there, since esi is non-volatile
       xor     ecx, ecx                ; Clear ecx. Since a loop is coming up, this might be a loop counter
     Top:
       movsx   edx, byte ptr [ecx+esi] ; ecx is a loop counter, and esi is the cdkey. This takes the ecx'th .
                                       ; character (dereferenced, because of the square brackets [ ]) and moves
                                       ; it into edx. Since it's a character array (string), there is no multiplier
                                       ; for the array index. 

       sub     edx, 30h                ; Subtract 0x30 from the character. This converts the ascii character '0', 
                                       ; '1', '2', etc. to the integer 0, 1, 2, etc.
       lea     edi, [eax+eax]          ; Double eax. This is likely an accumulator, which stores a result. 
       xor     edx, edi                ; Xor the current digit by the current checksum.
       add     eax, edx                ; Add the value in eax back into the checksum.
       inc     ecx                     ; Increment the loop counter, ecx.
       cmp     ecx, 0Ch                ; Compare the loop counter to 0x0c, or 12. 
       jl      short Top               ; Go back to the top until the 12th character (note that the last character
                                       ; is skipped

       xor     edx, edx                ; Clear edx
       mov     ecx, 0Ah                ; Set ecx to 0x0a (10)
       div     ecx                     ; Remember division? edx is cleared above, so this basically does eax / ecx
                                       ; We don't know yet whether it will use the quotient (eax) or remainder (edx)

       movsx   eax, byte ptr [esi+0Ch] ; Move the last character in the cdkey to eax. Note that this used move with 
                                       ; sign extension, which means the character is signed. Because it's an ascii 
                                       ; number (between 0x30 and 0x39), it'll never be negative so this doesn't
                                       ; matter. 
       add     edx, 30h                ; Convert edx (which is the remainder from the division -- the checksum % 10)
                                       ; back to an ascii character. From the integer 0, 1, 2, etc. to the characters
                                       ; '0', '1', '2', etc.

       cmp     eax, edx                ; Compare the last digit of the cdkey to the checksum result. 
       jnz     bottom                  ; If they aren't equal, jump to the bottom, which returns 0

       mov     eax, 1                  ; Return 1
       ret

     bottom:
       xor     eax, eax                ; Clear eax, and return 0
       ret

## C Code {#c_code}

Please, try this yourself first!

This is an absolutely direct conversion from the annotated assembly to C. I added a main function that sends a bunch of test keys through the function to print out the results.

Now that a driver function can test the CDKey validator, the code can be reduced and condensed.

    #include <stdio.h>

    /* Prototype */
    int checkCDKey(char *key);

    int main(int argc, char *argv[])
    {
        /* A series of test cases (I'm using fake keys here obviously, but real ones work even better) */
        char *keys[] = { "1212121212121", /* Valid */
                         "3781030596831", /* Invalid */
                         "3748596030203", /* Invalid */
                         "1234567890123", /* Valid */
                         "4962883551538", /* Valid */
                         "0000000000000", /* Invalid */
                         "1111111111111", /* Invalid */
                         "2222222222222", /* Invalid */
                         "3333333333333", /* Valid */
                         "4444444444444", /* Invalid */
                         "5555555555555", /* Invalid */
                         "6666666666666", /* Invalid */
                         "7777777777777", /* Invalid */
                         "8888888888888", /* Invalid */
                         "9999999999999"  /* Invalid */
                       };
        int valid[]  = { 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 };
        int i;

        for(i = 0; i < 15; i++)
            printf("%s: %d == %d\n", keys[i], valid[i], checkCDKey(keys[i]));

        return 0;
    }

    int checkCDKey(char *key)
    {
        int eax, ebx, ecx, edx, edi;
        char *esi;

            // This is C code, written and tested on the gcc computer, under Linux. However, this should universally work. 
            //   ; Note: ecx is a pointer to a 13-digit Starcraft cdkey
            //   ; This is a function that returns 1 if it's a valid key, or 0 if it's invalid
            //   mov     eax, 3    ; Set eax to 3
        eax = 3;
            //   mov     esi, ecx  ; Move the cdkey pointer to esi. It'll likely stay there, since esi is non-volatile
        esi = key;
            //   xor     ecx, ecx  ; Clear ecx. Since a loop is coming up, this might be a loop counter
        ecx = 0;
            // Top:
        do
        {
                //   movsx   edx, byte ptr [ecx+esi] ; ecx is a loop counter, and esi is the cdkey. This takes the ecx'th .
                //                                   ; character (dereferenced, because of the square brackets [ ]) and moves
                //                                   ; it into ecx. Since it's a character array (string), there is no multiplier
                //                                   ; for the array index. 
            edx = *(ecx + esi);
                //
                //   sub     edx, 30h                ; Subtract 0x30 from the character. This converts the ascii character '0', 
                //                                   ; '1', '2', etc. to the integer 0, 1, 2, etc.
            edx = edx - 0x30;
                //   lea     edi, [eax+eax]          ; Double eax. This is likely an accumulator, which stores a result. 
            edi = eax + eax;
                //   xor     edx, edi                ; Xor the current digit by the current checksum.
            edx = edx ^ edi;
                //   add     eax, edx                ; Add the value in eax back into the checksum.
            eax = eax + edx;
                //   inc     ecx                     ; Increment the loop counter, ecx.
            ecx++;
                //   cmp     ecx, 0Ch                ; Compare the loop counter to 0x0c, or 12. 
                //   jl      short Top               ; Go back to the top until the 12th character (note that the last character
        }
        while(ecx < 0x0c);
            //                                   ; is skipped
            //
            //   xor     edx, edx                ; Clear edx
        edx = 0;
            //   mov     ecx, 0Ah                ; Set edx to 0x0a (10)
        ecx = 0x0a;
            //   div     ecx                     ; Remember division? edx is cleared above, so this basically does eax / ecx
            //                                   ; We don't know yet whether it will use the quotient (eax) or remainder (edx)
        edx = eax % ecx;
            //
            //   movsx   eax, byte ptr [esi+0Ch] ; Move the last character in the cdkey to eax. Note that this used move with 
            //                                   ; sign extension, which means the character is signed. Because it's an ascii 
            //                                   ; number (between 0x30 and 0x39), it'll never be negative so this doesn't
            //                                   ; matter. 
        eax = *(esi + 0x0c);
            //   add     edx, 30h                ; Convert edx (which is the remainder from the division -- the checksum % 10)
            //                                   ; back to an ascii character. From the integer 0, 1, 2, etc. to the characters
            //                                   ; '0', '1', '2', etc.
        edx = edx + 0x30;
            //
            //   cmp     eax, edx                ; Compare the last digit of the cdkey to the checksum result. 
        if(eax == edx)
        {
                //   jnz     bottom                  ; If they aren't equal, jump to the bottom, which returns 0
                //
                //   mov     eax, 1                  ; Return 1
                //   ret
            return 1;
        }
        else
        {
                //
                // bottom:
                //   xor     eax, eax                ; Clear eax, and return 0
                //   ret
            return 0;
        }
    }

Here is the output:

        1212121212121: 1 == 1
        3781030596831: 0 == 0
        3748596030203: 0 == 0
        1234567890123: 1 == 1
        4962883551538: 1 == 1
        0000000000000: 0 == 0
        1111111111111: 0 == 0
        2222222222222: 0 == 0
        3333333333333: 1 == 1
        4444444444444: 0 == 0
        5555555555555: 0 == 0
        6666666666666: 0 == 0
        7777777777777: 0 == 0
        8888888888888: 0 == 0
        9999999999999: 0 == 0

## Cleaned up C Code {#cleaned_up_c_code}

Here\'s the same code with the assembly removed and some minor cleanups. After every change, the program should be run again to ensure that the code still works as expected. The driver function is unchanged, so here\'s the cleaned up C function:

    int checkCDKey(char *key)
    {           
        int eax, ebx, ecx, edx, edi; 
        char *esi;
                
        eax = 3;
        esi = key;
        ecx = 0;

        do
        {
            edx = *(ecx + esi);
            edx = edx - 0x30;
            edi = eax + eax;
            edx = edx ^ edi;
            eax = eax + edx;
            ecx++;
        }
        while(ecx < 0x0c);

        edx = 0;
        ecx = 0x0a;
        edx = eax % ecx;
        eax = *(esi + 0x0c);
        edx = edx + 0x30;
        if(eax == edx)
            return 1;
        else
            return 0;
    }

## Reduced C Code {#reduced_c_code}

In this section the code will be reduced and cleaned up to be as friendly as possible. Technically, the above function can be left the way it is, but it\'s a good exercise to learn.

First, the variables are renamed, unused variables are removed, and the return is condensed:

    int checkCDKey(char *key)
    {
        int accum = 3;
        int i;
        int temp, temp2; 

        accum = 3;
        i = 0;

        do
        {
            temp = *(i + key);
            temp = temp - 0x30;
            temp2 = accum + accum;
            temp = temp ^ temp2;
            accum = accum + temp;
            i++;
        }
        while(i < 0x0c);

        temp = 0;
        i = 0x0a;
        temp = accum % i;
        accum = *(key + 0x0c);
        temp = temp + 0x30;

        return accum == temp;
    }

Replace the pointers with array indexing, which looks a lot nicer:

    int checkCDKey(char *key)
    {
        int accum = 3;
        int i;
        int temp, temp2; 

        accum = 3;
        i = 0;

        do
        {
            temp = key[i];
            temp = temp - 0x30;
            temp2 = accum + accum;
            temp = temp ^ temp2;
            accum = accum + temp;
            i++;
        }
        while(i < 0x0c);

        temp = 0;
        i = 0x0a;
        temp = accum % i;
        accum = key[12];
        temp = temp + 0x30;

        return accum == temp;
    }

Substitute some variables with their values:

    int checkCDKey(char *key)
    {
        int accum = 3;
        int i;
        int temp, temp2; 

        accum = 3;
        i = 0;

        do
        {
            temp = key[i] - 0x30;
            temp = temp ^ (accum + accum);
            accum = accum + temp;
            i++;
        }
        while(i < 0x0c);

        temp = (accum % 10) + 0x30;
        accum = key[12];

        return accum == temp;
    }

Substitute some more variables, and replace the do..while loop with a for loop:

    int checkCDKey(char *key)
    {
        int accum = 3;
        int i;
        int temp;

        accum = 3;
        i = 0;

        for(i = 0; i < 12; i++)
        {
            temp = (key[i] - 0x30) ^ (accum + accum);
            accum = accum + temp;
        }


        return key[12] == ((accum % 10) + 0x30);
    }

## Finished Code {#finished_code}

And finally, substitute the last of the variables:

    int checkCDKey(char *key)
    {
        int accum = 3;
        int i;

        for(i = 0; i < 12; i++)
            accum += (key[i] - 0x30) ^ (accum + accum);

        return key[12] == ((accum % 10) + 0x30);
    }

That\'s as reduced as it gets. And running it through the driver function still works.

That\'s all for example 1, the next example will demonstrate the way in which the Starcraft CDKey is shuffled before it is encoded.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
