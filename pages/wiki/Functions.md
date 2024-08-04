---
title: 'Wiki: Functions'
author: ron
layout: wiki
permalink: "/wiki/Functions"
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


The previous section about the stack has shown how to call a standard function with parameters. This section will go over some other \"calling conventions\" besides the standard.

A \"calling convention\" is the way in which a function is called. The standard convention, *\_\_cdecl*, is what has been used up until now. Some other common ones are *\_\_stdcall*, *\_\_fastcall*, and *\_\_thiscall*.

A less common declaration used when writing hacks is *\_\_declspec(naked)*.

## \_\_cdecl

*\_\_cdecl* is the default calling convention on most C compilers. The properties are as follows:

-   The caller places all the parameters on the stack
-   The caller removes the parameters from the stack (often by adding the total size added to the stack pointer)

Throughout previous sections, *\_\_cdecl* has been the calling convention used. However, here is an example to help illustrate it:

      push param3
      push param2
      push param1   ; Parameters are pushed onto the stack
      call func     ; The function is called
      add esp, 0Ch  ; Parameters are removed from the stack
      ...
     func:
      ...
      ret

## \_\_stdcall

*\_\_stdcall* is another common calling convention. The properties of *\_\_stdcall* are:

-   The caller places parameters on the stack
-   The called function removes the parameters from the stack, often by using the return instruction with a parameter equal to the number of parameters, \"ret xx\"

Here\'s an example of a *\_\_stdcall* function (note that if no parameters are passed, *\_\_stdcall* is indistinguishable from *\_\_cdecl*.

      push param3
      push param2
      push param1   ; Parameters are pushed onto the stack
      call func     ; The function is called
      ... 
     func:
      ...
      ret 0c;       ; The function cleans up the stack

The most useful part about *\_\_stdcall* is that it tells a reverse engineer how many parameters are passed to any given function. In cases where no examples of the function being called may be found (possibly because it\'s an exported .dll function), it is easier to check the return than to enumerate local variables (of course, IDA looks after that automatically if that\'s an option).

## \_\_fastcall

*\_\_fastcall* is the final common calling convention seen. All implementations of *\_\_fastcall* pass parameters in registers, although Microsoft and Borland, for example, use different registers. Here are the properties of Microsoft\'s *\_\_fastcall* implementation:

-   First two parameters are passed in ecx and edx, respectively
-   Third parameter and on are passed on the stack, as usual
-   Functions clean up their own stack, if necessary

Recognizing a *\_\_fastcall* function is easy: look for ecx and edx being used without being initialized in a function.

A *\_\_fastcall* with no parameters is identical to *\_\_cdecl* and *\_\_stdcall* with no parameters, and a *\_\_fastcall* with a single parameter looks like *\_\_thiscall*.

Here are some \_\_fastcall examples:

      mov ecx, 7
      call func
      ...
     func:
      ...
      ret

      mov ecx, 7
      mov edx, 8
      call func
      ...
     func:
      ...
      ret

      mov ecx, 7
      mov edx, 8
      push param4
      push param3
      call func
      ...
     func:
      ...
      ret 8       ; Note that the function cleans up the stack. 

## \_\_thiscall

Seen only in object-oriented programming, *\_\_thiscall* is very similar to *\_\_stdcall*, except that a pointer to the class whose member is being called is passed in ecx.

-   ecx is assigned a pointer to the class whose member is being called
-   The parameters are placed on the stack, the same as \'\'\_\_stdcall\'
-   The function cleans itself up, the same as *\_\_stdcall*

Here is an example of \_\_thiscall:

      push param3
      push param2
      push param1
      mov ecx, this
      call func
      ...
     func:
      ...
      ret 12

## \_\_declspec(naked)

*\_\_declspec(naked)*, a Visual Studio-specific convention, can\'t really be identified in assembly, since it\'s identical to \_\_cdecl once it reaches assembly. However, the special property of this convention is that the compiler will generate no code in a function. This allows the program, in a \_\_asm{} block, to write everything from preserving registers to allocating local variables and returning. This is useful when patching a jump in the middle of code, since it prevents the function from changing registers without the programmer\'s knowledge.

This C function:

`void __declspec(naked) test()`\
`{`\
`}`

Would translate to this in assembly:

Since no code is generated.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.
