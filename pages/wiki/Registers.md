---
title: 'Wiki: Registers'
author: ron
layout: wiki
permalink: "/wiki/Registers"
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


This section is the first section specific to assembly. So if you\'re reading through the full guide, get ready for some actual learning!

A register is like a variable, except that there are a fixed number of registers. Each register is a special spot in the CPU where a single value is stored. A register is the only place where math can be done (addition, subtraction, etc). Registers frequently hold pointers which reference memory. Movement of values between registers and memory is very common.

Intel assembly has 8 general purpose 32-bit registers: eax, ebx, ecx, edx, esi, edi, ebp, esp. Although any data can be moved between any of these registers, compilers commonly use the same registers for the same uses, and some instructions (such as multiplication and division) can only use the registers they\'re designed to use.

Different compilers may have completely different conventions on how the various registers are used. For the purposes of this document, I will discuss the most common compiler, Microsoft\'s.

## Volatility

Some registers are typically volatile across functions, and others remain unchanged. This is a feature of the compiler\'s standards and must be looked after in the code, registers are not preserved automatically (although in some assembly languages they are \-- but not in x86). What that means is, when a function is called, there is no guarantee that volatile registers will retain their value when the function returns, and it\'s the function\'s responsibility to preserve non-volatile registers.

The conventions used by Microsoft\'s compiler are:

-   **Volatile**: ecx, edx
-   **Non-Volatile**: ebx, esi, edi, ebp
-   **Special**: eax, esp (discussed later)

## General Purpose Registers {#general_purpose_registers}

This section will look at the 8 general purpose registers on the x86 architecture.

### eax

eax is a 32-bit general-purpose register with two common uses: to store the return value of a function and as a special register for certain calculations. It is technically a volatile register, since the value isn\'t preserved. Instead, its value is set to the return value of a function before a function returns. Other than esp, this is probably the most important register to remember for this reason. eax is also used specifically in certain calculations, such as multiplication and division, as a special register. That use will be examined in the instructions section.

Here is an example of a function returning in C:

`return 3;  // Return the value 3`

Here\'s the same code in assembly:

`mov eax, 3 ; Set eax (the return value) to 3`\
`ret        ; Return`

### ebx

ebx is a non-volatile general-purpose register. It has no specific uses, but is often set to a commonly used value (such as 0) throughout a function to speed up calculations.

### ecx

ecx is a volatile general-purpose register that is occasionally used as a function parameter or as a loop counter.

Functions of the \"\_\_fastcall\" convention pass the first two parameters to a function using ecx and edx. Additionally, when calling a member function of a class, a pointer to that class is often passed in ecx no matter what the calling convention is.

Additionally, ecx is often used as a loop counter. *for* loops generally, although not always, set the accumulator variable to ecx. *rep-* instructions also use ecx as a counter, automatically decrementing it till it reaches 0. This class of function will be discussed in a later section.

### edx

edx is a volatile general-purpose register that is occasionally used as a function parameter. Like ecx, edx is used for \"\_\_fastcall\" functions.

Besides fastcall, edx is generally used for storing short-term variables within a function.

### esi

esi is a non-volatile general-purpose register that is often used as a pointer. Specifically, for \"rep-\" class instructions, which require a source and a destination for data, esi points to the \"source\". esi often stores data that is used throughout a function because it doesn\'t change.

### edi

edi is a non-volatile general-purpose register that is often used as a pointer. It is similar to esi, except that it is generally used as a destination for data.

### ebp

ebp is a non-volatile general-purpose register that has two distinct uses depending on compile settings: it is either the frame pointer or a general purpose register.

If compilation is not optimized, or code is written by hand, ebp keeps track of where the stack is at the beginning of a function (the stack will be explained in great detail in a later section). Because the stack changes throughout a function, having ebp set to the original value allows variables stored on the stack to be referenced easily. This will be explored in detail when the stack is explained.

If compilation is optimized, ebp is used as a general register for storing any kind of data, while calculations for the stack pointer are done based on the stack pointer moving (which gets confusing \-- luckily, IDA automatically detects and corrects a moving stack pointer!)

### esp

esp is a special register that stores a pointer to the top of the stack (the top is actually at a lower virtual address than the bottom as the stack grows downwards in memory towards the heap). Math is rarely done directly on esp, and the value of esp must be the same at the beginning and the end of each function. esp will be examined in much greater detail in a later section.

## Special Purpose Registers {#special_purpose_registers}

For special purpose and floating point registers not listed here, have a look at the [Wikipedia Article](http://en.wikipedia.org/wiki/IA-32) or other reference sites.

### eip

*eip*, or the instruction pointer, is a special-purpose register which stores a pointer to the address of the instruction that is currently executing. Making a jump is like adding to or subtracting from the instruction pointer.

After each instruction, a value equal to the size of the instruction is added to eip, which means that eip points at the machine code for the next instruction. This simple example shows the automatic addition to eip at every step:

`eip+1      53                push    ebx`\
`eip+4      8B 54 24 08       mov     edx, [esp+arg_0]`\
`eip+2      31 DB             xor     ebx, ebx`\
`eip+2      89 D3             mov     ebx, edx`\
`eip+3      8D 42 07          lea     eax, [edx+7]`\
`.....`

### flags

In the flags register, each bit has a specific meaning and they are used to store meta-information about the results of previous operations. For example, whether the last calculation overflowed the register or whether the operands were equal. Our interest in the flags register is usually around the *cmp* and *test* operations which will commonly set or unset the zero, carry and overflow flags. These flags will then be tested by a conditional jump which may be controlling program flow or a loop.

## 16-bit and 8-bit Registers {#bit_and_8_bit_registers}

In addition to the 8 32-bit registers available, there are also a number of 16-bit and 8-bit registers. The confusing thing about these registers it that they use the same storage space as the 32-bit registers. In other words, every 16-bit register is half of one of the 32-bit registers, so that changing the 16-bit also changes the 32-bit. Furthermore, the 8-bit registers are part of the 16-bit registers.

For example, eax is a 32-bit register. The lower half of eax is ax, a 16-bit register. ax is divided into two 8-bit registers, ah and al (a-high and a-low).

-   There are 8 32-bit registers: eax, ebx, ecx, edx, esi, edi, ebp, esp.
-   There are 8 16-bit registers: ax, bx, cx, dx, si, di, bp, sp.
-   There are 8 8-bit registers: ah, al, bh, bl, ch, cl, dh, dl.

The relationships of these registers is shown in the table below:

```{=html}
<table border='1px' cellspacing='0' cellpadding='0' width='485'>
```
```{=html}
<tr>
```
```{=html}
<td colspan='1' width='25' align='left'>
```
32-bit

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
eax

```{=html}
</td>
```
```{=html}
<td colspan='1' rowspan='3' width='15'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
ebx

```{=html}
</td>
```
```{=html}
<td colspan='1' rowspan='3' width='15'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
ecx

```{=html}
</td>
```
```{=html}
<td colspan='1' rowspan='3' width='15'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
edx

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td colspan='1' width='25' align='left'>
```
16-bit

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
ax

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
bx

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
cx

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
dx

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td colspan='1' width='25' align='left'>
```
8-bit

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
ah

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
al

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
bh

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
bl

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
ch

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
cl

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
dh

```{=html}
</td>
```
```{=html}
<td colspan='1' width='25' align='center'>
```
dl

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td colspan='20'>
```
 

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td colspan='1' width='25' align='left'>
```
32-bit

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
esi

```{=html}
</td>
```
```{=html}
<td colspan='1' rowspan='2' width='15'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
edi

```{=html}
</td>
```
```{=html}
<td colspan='1' rowspan='2' width='15'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
ebp

```{=html}
</td>
```
```{=html}
<td colspan='1' rowspan='2' width='15'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='4' width='100' align='center'>
```
esp

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td colspan='1' width='25' align='left'>
```
16-bit

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
si

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
di

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
bp

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
 

```{=html}
</td>
```
```{=html}
<td colspan='2' width='50' align='center'>
```
sp

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
</table>
```
Here are two examples:

```{=html}
<table border='1px' cellspacing='0' cellpadding='0'>
```
```{=html}
<tr>
```
```{=html}
<td width='50'>
```
eax

```{=html}
</td>
```
```{=html}
<td width='100'>
```
0x12345678

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
ax

```{=html}
</td>
```
```{=html}
<td>
```
0x5678

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
ah

```{=html}
</td>
```
```{=html}
<td>
```
0x56

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
al

```{=html}
</td>
```
```{=html}
<td>
```
0x78

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
</table>
```
```{=html}
<table border='1px' cellspacing='0' cellpadding='0'>
```
```{=html}
<tr>
```
```{=html}
<td width='50'>
```
ebx

```{=html}
</td>
```
```{=html}
<td width='100'>
```
0x00000025

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
bx

```{=html}
</td>
```
```{=html}
<td>
```
0x0025

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
bh

```{=html}
</td>
```
```{=html}
<td>
```
0x00

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
bl

```{=html}
</td>
```
```{=html}
<td>
```
0x25

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
</table>
```
## 64-bit Registers {#bit_registers}

A 64-bit register is made by concatenating a pair of 32-bit registers. This is shown by putting a colon between them.

The most common 64-bit register (used for operations such as division and multiplication) is edx:eax. This means that the 32-bits of edx are put in front of the 32-bits of eax, creating a double-long register, so to speak.

Here is a simple example:

```{=html}
<table border='1px' cellspacing='0' cellpadding='0'>
```
```{=html}
<tr>
```
```{=html}
<td width='80'>
```
edx

```{=html}
</td>
```
```{=html}
<td width='200'>
```
0x11223344

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
eax

```{=html}
</td>
```
```{=html}
<td>
```
0xaabbccdd

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
edx:eax

```{=html}
</td>
```
```{=html}
<td>
```
0x11223344aabbccdd

```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
</table>
```
## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.
