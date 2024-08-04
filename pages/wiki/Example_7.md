---
title: 'Wiki: Example 7'
author: ron
layout: wiki
permalink: "/wiki/Example_7"
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


This is what this entire tutorial has been building up to: writing a cheat for a game!

I have chosen the simplest cheat I can think of that demonstrates most of the concepts I\'ve attempted to teach: displaying a notification whenever a player spends minerals in Starcraft.

This demonstration will use Starcraft 1.05. There are two reasons:

-   So it can\'t easily be translated to modern versions, which should avoid pissing off Blizzard.
-   Because the newer versions break TSearch, and I don\'t really want to find/write another memory searcher.

Two locations need to be found:

-   The function that can be called to display messages on-screen.
-   The function that is called when minerals are spent.

## Creating the .dll {#creating_the_.dll}

This .dll will be written in Microsoft Visual Studio and injected with my [Injector](http://www.javaop.com/~ron/programs/Inject.zip).

Here\'s how to create the .dll (this works in Visual Studio 2005):

-   Run Visual Studio.
-   Create a new project.
-   Choose \"Win32 Console Application\" and give it a name.
-   In the wizard, set the application type to \"DLL\".
-   Disable \"Precompiled header\" (you don\'t have to, but I prefer to).

I generally start by removing all the crap that Visual Studio adds, then I add a switch over the two conditions I care about. Here\'s the starting code:

    #include <stdio.h>
    #include <windows.h>

    BOOL APIENTRY DllMain( HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
    {
        switch(ul_reason_for_call)
        {
        case DLL_PROCESS_ATTACH:
            break;

        case DLL_PROCESS_DETACH:
            break;
        }

        return TRUE;
    }

This should compile into a .dll file, which can be injected/ejected (though it does nothing).

## Displaying Messages {#displaying_messages}

Finding the function to call is always tricky. It goes back to the same principle as finding the place to crack a game: you have to find a starting point, and trace your way to the appropriate function. Depending on the game, this could be significantly difficult.

Some ways to do this might be:

-   Searching for messages you see on the screen.
-   Typing a message, searching in memory for it, and pressing enter.
-   Figuring out how events in Use Map Settings games work.

The first message I think of that\'s displayed on-screen is chat messages from other players, which look like \"player: message\". Another common chat message is \"\[team\] player: message\". That seems like a good place to start looking.

In IDA, load Starcraft.exe and wait till it finishes analysis. Then go to the strings window/tab and search (by typing it in) for \"\[\", and the first result is \"\[%s\] %s: %s\". Anybody who knows C format strings will know that, in a format specifier, %s indicates a string. Since we have a reasonable idea of how strings work, we can guess that \"%s: %s\" would be a normal message, so we search for that and double-click it.

The address of that string should be 0x004F2AE0. If it\'s not, you might be on the wrong version of Starcraft, which should be fine. Just remember that the addresses I provide may not be right.

On that address, press ctrl-x. There\'s only one cross reference, at sub_004696C0+105, so double-click that. We see that this string is a function call, shown here:

`push eax`\
`push offset aSS_2`\
`push 100h`\
`push ecx`\
`call sub_4D2820`

Anybody well-versed in C will likely recognize this as a call to snprintf(). The first variable, ecx, is the buffer. Then 100h is the length, aSS_2 (\"%s: %s\") is the format string, and the two string that are substituted for %s are eax and (not shown here) edi.

Since ecx is a volatile variable, it\'s likely going to change after the function call, which means that this code won\'t be reliant on the value. If we look above, we can find where ecx is loaded with the buffer:

`lea ecx, [esp+110h+var_100] `

Note that the frame pointer isn\'t being used here, but that IDA still managed to name the local variable. Click on var_100, press \'n\', and call it \'buffer\'.

On the line before, you should see:

`lea eax, dword_6509E3[esi]`

This is the first string parameter that will be substituted, which means it corresponds to the first %s, which is the player\'s name. Presumably \"esi\" is the player number. This will be important later.

Click on the \"buffer\" variable you defined to highlight all instances of it, then scroll down. You\'ll eventually see the buffer put into ecx right before a function call, which indicates a \_\_fastcall function. If you double-click on that function and scroll way down to the bottom, you\'ll find the return is:

`retn 8`

So now we know that it\'s a \_\_fastcall with two stack parameters, so a total of four parameters.

Press \"Esc\" to get back.

Looking at edx, we see that it gets its value from ebx, and involves a subtraction. If you follow ebx up the function, you\'ll see that esi is derived from it, so presumably ebx is or involves the player number. For now, we\'ll ignore that, and set it to 0.

The first stack parameter (that is, the last one pushed) is \"eax\". Remember that eax is the return variable. The function GetTickCount() is called just above the push, then 0x1B58 is added to the result. Right-click on the 0x1B58 to see the variable in different forms. In decimal, it\'s \"7000\". That\'s a much better number, so click on that.

GetTickCount() returns the number of milliseconds that Windows has been running. Adding 7000 milliseconds, or 7 seconds, creates the time it will be in 7 seconds. Messages in Starcraft stay on the screen for roughly 7 seconds, so presumably this parameter is the time for a message to stop displaying.

Finally, the last stack parameter is 0. That\'s nice and easy!

As for the return value, eax isn\'t used after the function call, so there may not be a return value. We won\'t worry about it.

So now we can define the function this way:

`void __fastcall DisplayMessage(char *strMessage, int unknown, DWORD dwDisplayUntil, int unknown0);`

It\'s not necessary here, but for education, do the following:

-   Double-click on the display function (sub_469380)
-   Scroll up, and click on the function\'s name
-   Press \'n\', and call it \'DisplayMessage\'
-   Press \'y\', and define it as shown above (don\'t forget the semicolon).
-   Press \'Esc\' to get back to where the function is called.

If you\'re using a modern version of IDA (support for \_\_fastcall started fairly late), you\'ll see that the parameters to this function are commented now.

Of course, we have to test it works, now. We already have a .dll that can be loaded, so we\'ll add a function to it. Here\'s the function:

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

Then to test, add a call to this function from DLL_PROCESS_ATTACH in DllMain(), and you\'re ready to test your first hack!

To test this:

-   Run Starcraft
-   Start a single player game (if you had the newest version, this would work in multiplayer too)
-   Alt-tab out
-   Run injector.exe
-   Tell it to inject in the \"Starcraft\" window, and give it the full path to the .dll file
-   Press \"Inject\"
-   Go back into the game
-   Hopefully your message will be waiting!

[Click here](Example_7_Step_1 "wikilink") for the full code.

Another option that I\'ve started using more recently is to use a function pointer:

    typedef void (__fastcall *fcnShowMessage) (const char* strMessage, int unk, int intDisplayUntil, int unk0);
    static const fcnShowMessage ShowMessage = (fcnShowMessage)    0x00469380;

[Click here](Example_7_Step_1b "wikilink") for the full code using a function pointer.

## Mineral Spending {#mineral_spending}

We\'re going to use TSearch to track down the function called when a user spends minerals.

This is very simple to do, and requires only a memory search (with TSearch) on the address of your minerals. That will lead you back to the code that can be patched, which means your hack will know every time minerals are spent. You should be able to do this on your own, based on what you learned in \"Memory Searching\", but here\'s the Starcraft-specific way:

-   Start a game of Starcraft against the computer, but don\'t start mining.
-   Alt-tab out, run TSearch, and attach it to Starcraft.
-   Search (in the left pane) for \"50\", 4 bytes (minerals can go over 65000).
-   Go back to the game, and mine one chunk of minerals.
-   Go back to TSearch, and search for \"58\".
-   Go to Starcraft and buy an SCV/Drone/Probe.
-   Go back to TSearch and search for \"8\"
-   Repeat until you\'re down to two or three results
-   Test the one at address 0x006xxxxx by changing it, go back to the game, and watch your minerals fall back to where they were. If you don\'t see one at this address, don\'t worry. It\'s only the display number.
-   Test the one at 0x004xxxxx, and watch your minerals stay constant.
-   Double-click on the good value
-   Under the \"AutoHack\" menu choose \"Enable Debugger\"
-   Right-click on the row in the right pane, and click \"AutoHack\"
-   Under the \"AutoHack\" menu, choose \"AutoHack Window\"
-   Go back into the game, and spend some minerals
-   Take a look at the \"AutoHack Window\", you should see exactly one result. If you harvested some money first, you\'ll see more, but use the last one.

By now, you should have determined that your minerals are stored at or near 0x004FEE5C, and the address where the minerals changed should be 0x0040208F.

So load up Starcraft.exe in IDA and jump down to 0x0040280F. You should see a function that looks like this (I\'ve indicated the line where your minerals are written):

    .text:00402070 51                                push    ecx
    .text:00402071 88 4C 24 00                       mov     byte ptr [esp+1+var_1], cl
    .text:00402075 8B 44 24 00                       mov     eax, [esp+1+var_1]
    .text:00402079 25 FF 00 00 00                    and     eax, 0FFh
    .text:0040207E C1 E0 02                          shl     eax, 2
    .text:00402081 8B 88 58 65 51 00                 mov     ecx, dword_516558[eax]
    .text:00402087 8B 90 58 EE 4F 00                 mov     edx, dword_4FEE58[eax]
    .text:0040208D 2B D1                             sub     edx, ecx
    .text:0040208F 89 90 58 EE 4F 00                 mov     dword_4FEE58[eax], edx   ; <-- This line
    .text:00402095 8B 90 B8 65 51 00                 mov     edx, dword_5165B8[eax]
    .text:0040209B 29 90 88 EE 4F 00                 sub     dword_4FEE88[eax], edx
    .text:004020A1 59                                pop     ecx
    .text:004020A2 C3                                retn

This function is pretty straight forward, although it does something weird: it preserves ecx. I don\'t know why that happens.

On the second line, cl (part of ecx) is used, so we know this is \_\_fastcall. edx is overwritten, so we know that this function has one parameter. Note that the one parameter is used as an array index into the array that stores your mineral count. It is pretty safe to assume that this is an array index.

To summarize this function:

-   Store ecx\'s lowest byte in var_1
-   Get rid of the top 3 bytes of eax (if the mov had been movzx, this would have automatically happened).
-   Shift eax two bits left. This has the same affect as multiplying by 4, which likely means it\'s an index into an array of 4-byte values
-   Use eax as an index into two arrays, and subtract them from each other. We know the first is our minerals, the second is unknown, but it should be obvious that the second is the amount you\'re spending.
-   Put the new value, after the subtraction, back into the array.
-   Move another variable into edx, and subtract it from yet another variable.

The usage of this function is pretty obvious, so we can go ahead and write the patch!

## The Wrapper {#the_wrapper}

The best place I see to patch is right after 0x0040208F. At this point, the variables all contain useful values:

-   eax = 4 \* player number
-   ecx = the amount spent
-   edx = the new mineral total

Here\'s the patch we want to make, and I\'ve assigned everything machine code from a handy dandy reference (IDA):

`   89 90 58 EE 4F 00    mov     dword_4FEE58[eax], edx        ; The overwritten code`\
`   60                   pushad                                ; Preserve`\
`   52                   push edx                              ; Push the three parameters`\
`   51                   push ecx`\
`   50                   push eax`\
`   e8 xx xx xx xx       call HackFunction                     ; Note that this is __stdcall`\
`   61                   popad`\
`   c3                   ret`

Or, in a C string:

`char *wrapper = "\x89\x90\x58\xee\x4f\x00\x60\x52\x51\x50\xe8AAAA\x61\xc3";    `

## The Patch {#the_patch}

This is mostly taken from the section on .dll injection, with a small modification to the machine code wrapper to add some pushes, and to the hack function to support the three parameters:

    #include <stdio.h>
    #include <stdlib.h>
    #include <windows.h>

    void __stdcall HackFunction(int player, int spent, int remaining)
    {
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
            break;

        case DLL_PROCESS_DETACH:
            WriteProcessMemory(hProcess, (void*) intAddressToPatch, strUnPatch, 6, NULL);
            break;
        }
        return TRUE;
    }

## Add the Display Function {#add_the_display_function}

I wrote the function to display text earlier on this page. Now would be a good time to add that to the project. At the same time, add a few calls to it that\'ll display what\'s going on:

    #include <stdio.h>
    #include <stdlib.h>
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

    void __stdcall HackFunction(int player, int spent, int remaining)
    {
        char buffer[200];

        player = player >> 2;
        sprintf_s(buffer, 200, "\x04Player %d spent \x02%d \x04minerals, leaving him with %d", player, spent, remaining);
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

## Finishing Touches {#finishing_touches}

That function will display a nice notification when a player spends minerals, but only the numeric player number is given, which isn\'t especially helpful.

Recall that, while looking for the display function, we found the array of player names. Here\'s the code that prepares the message:

`.text:004697BA 8D 86 E3 09 65 00                 lea     eax, dword_6509E3[esi]`\
`.text:004697C0 8D 4C 24 10                       lea     ecx, [esp+110h+buffer]`\
`.text:004697C4 50                                push    eax`\
`.text:004697C5 68 E0 2A 4F 00                    push    offset aSS_2    ; "%s: %s"`\
`.text:004697CA 68 00 01 00 00                    push    100h            ; size_t`\
`.text:004697CF 51                                push    ecx             ; char *`\
`.text:004697D0 E8 4B 90 06 00                    call    sub_4D2820`

The first parameter is ecx, which is an empty buffer. The second parameter, 0x100, is the size of the buffer. The third parameter is the format string, \"%s: %s\", indicating the the last two parameters are the username and the message.

The fourth parameter is eax. The eax comes from dword_6509E3\[esi\], which means that esi is indexing into an array in memory. So from there, we can look above and figure out where esi came from:

`.text:00469749 8D 34 DB                          lea     esi, [ebx+ebx*8]`\
`.text:0046974C C1 E6 02                          shl     esi, 2`

Going to the top of the function, we see that ebx was a parameter, and is compared to 8. Since a Starcraft game can have up to 8 players, it\'s reasonable to assume that ebx is the player number. Therefore, we need to emulate these three lines:

`.text:00469749 8D 34 DB                          lea     esi, [ebx+ebx*8]`\
`.text:0046974C C1 E6 02                          shl     esi, 2`\
`.text:004697BA 8D 86 E3 09 65 00                 lea     eax, dword_6509E3[esi]`

Which can easily be done like this:

`int esi = ebx + ebx*8;`\
`esi = esi << 2;`\
`char *player = (char*) 0x6509e3 + esi; `

Which reduces to simply:

`So the first line multiplies the player by 9, and the next line shifts it left by 2, which is the same as multiplying by 4. 9 * 4 = 36, so that's what we use:`\
`char *player = (char*) 0x6509e3 + (playernum * 36); `

Recall that, in the assembly function, the player number is shifted left twice. That means that, to get the proper number here, we have to right-shift it twice before we use it:

`char *player = (char*) 0x6509e3 + ((playernum >> 2) * 36); `

Adding that to our code, we get this completed hack:

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
        /* This address is an array of names. Recall that the player is left-shifted twice in the "SpendMoney" function, so
         * the shift here ends up with the same number. */
        char *name = (char*) 0x6509e3 + ((player >> 2) * 36); 

        /* Create a string to display, then display it. */
        sprintf_s(buffer, 200, "\x04%s spent \x02%d \x04minerals, leaving him with %d", name, spent, remaining);
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

## In Action! {#in_action}

Here\'s a screenshot of the plugin in action:

[image:screenshot.jpg](image:screenshot.jpg "wikilink")

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
