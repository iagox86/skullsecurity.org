---
title: 'Wiki: Example 5'
author: ron
layout: wiki
permalink: "/wiki/Example_5"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_5"
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


This example is going to cover the steps I took to crack a not-very-popular computer game. Rather than showing all the trial-and-error, I\'m going to demonstrate the strategy that worked. Note that there are probably many ways to go about this, the way I\'ll demonstrate is only one way.

## The Game {#the_game}

For fear of legal issues, I\'m not going to name the game I use in this thread. If you wish to know which game, talk to me privately.

The reason I chose this game is twofold:

1.  Its protection is fairly simple, providing a useful tutorial.
2.  It\'s a really good game made by a fantastic company that I like a lot. So encouraging people who\'ve never heard of it to try it can only be positive.

In other words, if you think this game is interesting, buy it! This demonstration is for educational purposes only.

If you believe this is your game, and you don\'t wish this information to be here, please send me an email and I will remove this page (if indeed it is yours).

## Tools

All you need for this is IDA and TSearch. They can be found on the tools page. A hex editor can be substituted for TSearch to permanently patch the game instead of patching it in memory.

## Getting Started {#getting_started}

If this is your first time using IDA, you might want to take some time getting used to it. I\'m going to be using IDA 5 for this demonstration, but any version technically works.

First, you\'ll probably want to run the game to familiarize yourself with the protection scheme. In the bottom-right corner you\'ll see a \"registration code\", and if you press \"register\" you\'ll be prompted for a registration key. Try a couple keys, maybe you\'ll get lucky. Hint: all codes are integers between 10000 and 19999.

When you get bored, load up IDA and load the game\'s .exe file. At the bottom left, you\'ll see the analysis status. You can look around all you want while it\'s analyzing, but once it says \"idle\" we can start poking around.

If this is your first time in IDA, take some time to familiarize yourself with it. I won\'t pretend that IDA is an easy program to use, I haven\'t even scratched the surface of what I know it is capable of. But some of the commands you might want to try are:

-   Renaming variables/arguments/addresses (click on a variable and press \'n\').
-   Setting a prototype for a function (click on the function header and press \'y\' \-- note that you can define a \_\_cdecl, \_\_stdcall, or \_\_fastcall function this way).
-   Adding a comment to a function (click on the function header and press \';\').
-   Adding a comment to a line (click on the line and press \':\').
-   Finding function cross references (click on the function header and press \'ctrl x\')
-   Following cross references (double click on a variable, function, address, etc)
-   Experiment with highlighting (whenever you click or highlight something, everything that matches highlights)

Those are the features I use most frequently. They can all be accessed via menus, so you don\'t have to memorize those hotkeys, but knowing the hotkeys will speed things up a lot.

## Finding the Validation {#finding_the_validation}

Finding the validation is the most difficult part, but if you follow these steps it shouldn\'t be terribly difficult. This section will cover the steps used to find the proper address. I\'m omitting any trial-and-error steps from this.

If you have any ideas of your own, feel free to try this on your own! If you find another way to crack this game, I\'ll include it here.

### Step 1 {#step_1}

In the \"Strings\" window of IDA, search for \"Unregistered\". Do this by bringing up the strings tab/window, and typing the word. You should see a string that will warn the user that the game is unregistered, which is the string that is used on the main window. Double-click it.

### Step 2 {#step_2}

You will see the string in the data section now. Press ctrl-x to bring up the cross references (ie, where the string is used).

### Step 3 {#step_3}

There should only be one. Double-click it. You should see the following code (addresses removed to protect the innocent (me)):

`   cmp     ds:byte_AAAAAA, 0`\
`   jnz     short loc_BBBBBB`\
`   mov     edx, ds:dword_CCCCCC`\
`   push    edx             ; HGDIOBJ`\
`   mov     eax, ds:dword_DDDDDD`\
`   push    eax             ; HDC`\
`   call    ds:SelectObject`\
`   movsx   eax, word_EEEEEE`\
`   push    eax`\
`   push    offset aUnregisteredCo ; "Unregistered Copy...`\
`   lea     eax, [ebp+var_188]`\
`   push    eax`\
`   call    sub_FFFFFF`

Let\'s look at the steps:

-   byte_AAAAAA is being compared to 0
-   If it\'s non-zero, a jump away from here is made
-   Otherwise, call a function, sub_FFFFFF, where one of the parameters is \"Unregistered Copy\...\"

It seems like a good theory that byte_AAAAAA is the variable, \"IsRegistered\", so click on it, press \'n\', and give it that name. Then double-click on it.

### Step 4 {#step_4}

Press ctrl-x on the variable to get a list of cross references. IsRegistered is used all over the place!

Luckily, our goal is to find out where the registration code is accepted. There are only three lines with \"mov IsRegistered, 1\" so those are probably good places to start. Funnily enough, all three functions are identical. Apparently, the developers copied/pasted code?

On the plus side, we can look at one of the functions and apply the same logic to the other two, if it doesn\'t work. So take a guess and double-click on the first function that does \"mov IsRegistered, 1\"

### Step 5 {#step_5}

Once you follow a cross reference, you should end up in this function (on the line I indicated with an arrow)

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

So this function does the following:

-   Move a variable (word_111111) into eax
-   Call sub_222222 with word_111111 as the only parameter
-   \"pop ecx\" clears the stack (same as sub esp, 4)
-   Compare ax (the right-most 16-bits of the return value) to word_333333
-   If they don\'t match, set IsRegistered to 0; otherwise, set it to 1

A reasonable guess as to what the variables mean would be:

-   Move the registration code into eax
-   Call a function that converts the code into the key
-   Compare the key to the key that the user entered
-   If it\'s the same, set IsRegistered

So what it comes down to is this important line:

`   jnz     short registerfail`

Note that the other two functions I mentioned above have an identical jump. So if patching this one doesn\'t work, the other ones should be patched.

## Cracking the game {#cracking_the_game}

Now that you know the address of the verification, we can test it.

The first thing you should do is enable the machine code display in IDA. To do it, follow these steps (this works for IDA 5, for other versions your mileage may vary):

-   Under the *Options* menu, select *General\...*
-   On the right, near the middle, there\'s a box for \"Number of opcode bytes\". Set that box to 6 (you may occasionally need to change this to 8 or higher, depending on what you\'re doing).
-   Press ok

Now look at the important \"jnz\" we found earlier:

`   75 09    jnz     short registerfail`

Recall from the machine code section that 75 09 means \"jnz 9 bytes ahead\". However, we want this jump to never occur, which means we want to replace this jnz with \"nop\". Because there are two bytes, we want to replace each byte with 90, making it:

`   90       nop`\
`   90       nop`

Here\'s how to do it (in a non-permanent way):

-   Run the game
-   Minimize it
-   Run TSearch
-   Use \"Open Process\" in TSearch to open the game
-   Enable TSearch\'s \"Hex Editor\"
-   Click on the left-most icon on the hex editor, and type in the address of the *jnz* instruction
-   Change \"75 09\" to \"90 90\"
-   Go back to the game, enter any registration code
-   Any code should now be accepted!

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
