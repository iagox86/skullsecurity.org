---
title: 'Wiki: Example 2b'
author: ron
layout: wiki
permalink: "/wiki/Example_2b"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_2b"
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


This is the third (and, basically, final) part of the Starcraft CDKey Decode. I\'m going to present the code and the final answer, but not the interim steps. This may cover things we haven\'t talked about (like a function call and local variables, for example).

As usual, esi is a pointer to the cdkey.

        mov     ebp, 13AC9741h
        mov     ebx, 0Bh

    top:
        movsx   eax, byte ptr [ebx+esi]
        push    eax             ; Parameter to toupper()
        call    _toupper        ; Call toupper()
        add     esp, 4          ; Fix the stack (don't worry about this)
        cmp     al, 37h
        mov     byte ptr [ebx+esi], al
        jg      short body1
        mov     ecx, ebp
        mov     dl, cl
        and     dl, 7
        xor     dl, al
        shr     ecx, 3
        mov     byte ptr [ebx+esi], dl
        mov     ebp, ecx
        jmp     short body2

    body1:
        cmp     al, 41h
        jge     short body2
        mov     cl, bl
        and     cl, 1
        xor     cl, al
        mov     byte ptr [ebx+esi], cl

    body2:
        dec     ebx
        jns     short top

## C Code {#c_code}

    void getFinalValue(char *key) {
         char *esi;
         int eax, ebp, ebx, ecx, edx;
         
         esi = key;
         ebp = 0x13AC9741;
         ebx = 0x0b;

         for(ebx = 0x0b; ebx > 0; ebx--)
         {
                  eax = *(ebx+esi);
                 *(ebx+esi) = eax;
                 if(eax <= 0x37)
                 {
                     ecx = ebp;
                     edx = ecx & 0xFF;
                     edx = edx & 7;
                     edx = edx ^ eax;
                     ecx = ecx >> 3;
                     *(ebx+esi) = edx;
                     ebp = ecx;
                 }          
                 else if (eax < 0x41)
                 {
                     ecx = ebx;
                     ecx = ecx & 1;
                     ecx = ecx ^ eax;
                     *(ebx+esi) = ecx;
                 }
         }
    }

## Cleaned up C Code {#cleaned_up_c_code}

    void getFinalValue(char *key) {
         int eax, ebp, ebx;
         
         ebp = 0x13AC9741;

         for(ebx = 0x0b; ebx > 0; ebx--)
         {
                 eax = key[ebx];

                 if(eax <= 0x37)
                 {
                     key[ebx] = (ebp & 7) ^ eax;
                     ebp = ebp >> 3;
                 }          
                 else if (eax < 0x41)
                 {
                     key[ebx] = (ebx & 1) ^ eax;
                 }
         }
    }

## Finished Code {#finished_code}

Here is the resulting code, in Java

        /** Gets the final CDKey values. */    
        protected void getFinalValue()
        {
            int hashKey = 0x13AC9741;

            byte[] key = cdkey.getBytes();
                
            for (int i = (cdkey.length() - 2); i >= 0; i--) 
            { 
                if (key[i] <= '7') 
                { 
                    key[i] ^= (byte) (hashKey & 7); 
                    hashKey = hashKey >>> 3; 
                } 
                else if (key[i] < 'A') 
                { 
                    key[i] ^= (byte)(i & 1); 
                } 
            }
        }

This will produce a new numeric string, sub-strings of which are sent to Battle.net as integers (the first two characters are the product, the next 7 are \"Val1\", and the next three are \"Val2\".

I\'m afraid I don\'t have any sample values for this one.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
