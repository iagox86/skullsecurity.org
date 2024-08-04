---
title: 'Wiki: Machine Code'
author: ron
layout: wiki
permalink: "/wiki/Machine_Code"
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


This section will discuss more detail about how an executable file full of hex becomes assembly, and what happens to that hex once it\'s loaded in memory.

## Machine Code {#machine_code}

Machine code is simply an encoding of assembly language. Every assembly instruction has one or more bytes of machine code instructions associated with it, and that sequence of bytes translates to exactly one assembly instruction. The relationship is 1:1, by definition.

This is different than the relationship between C and assembly. A sequence of C commands can translate to a variety of assembly instructions, and a sequence of assembly instructions can translate to C commands. There is no strong relationship.

Here is what some machine code might look like:

`53 8b 54 24 08 31 db 89 d3 8d 42 07`

Obviously, that\'s nothing that any normal human can read. However, when converted to assembly, it looks like this:

`53                push    ebx`\
`8B 54 24 08       mov     edx, [esp+arg_0]`\
`31 DB             xor     ebx, ebx`\
`89 D3             mov     ebx, edx`\
`8D 42 07          lea     eax, [edx+7]`

To show the machine code in IDA, in the settings tab find the \"opcode bytes\" setting and change it to 6 or 8.

Generally, if you need to find out the machine language opcodes for an instruction, either looking online or compiling/disassembling a program is the easiest way to go about it. A good reference book can be found [here](http://www.computer-books.us/assembler.php), which can also be ordered for free in hard copy.

Some opcodes, however, are so important that they should be committed to memory. These are listed below. Note that parameters for the jumps are signed, relative jumps. That is, \"74 10\", for example, would jump 0x10 bytes ahead of the current instruction, and 0xF0 would jump 0x10 bytes backwards.

<table border='1' cellspacing='0' cellpadding='2'>
<tr>
<td width='100'>
74 xx
</td>
<td>
je
</td>
</tr>
<tr>
<td>
75 xx
</td>
<td>
jnz
</td>
</tr>
<tr>
<td>
eb xx
</td>
<td>
jmp
</td>
</tr>
<tr>
<td>
e9 xx xx xx xx
</td>
<td>
jmp
</td>
</tr>
<tr>
<td>
e8 xx xx xx xx
</td>
<td>
call
</td>
</tr>
<tr>
<td>
c3
</td>
<td>
ret
</td>
</tr>
<tr>
<td>
c2 xx xx
</td>
<td>
ret xxxx
</td>
</tr>
<tr>
<td>
90
</td>
<td>
nop
</td>
</tr>
</table>

The section on cracking will explain why these opcodes are important.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.
