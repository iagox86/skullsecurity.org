---
title: 'Wiki: Simple Instructions'
author: ron
layout: wiki
permalink: "/wiki/Simple_Instructions"
date: '2024-08-04T15:51:38-04:00'
---

## Pointers and Dereferencing

First, we will start with the hard stuff. If you understood the pointers section, this shouldn't be too bad. If you didn't, you should probably go back and refresh your memory.

Recall that a pointer is a data type that stores an address as its value. Since registers are simply 32-bit values with no actual types, any register may or may not be a pointer, depending on what is stored. It is the responsibility of the program to treat pointers as pointers and to treat non-pointers as non-pointers.

If a value is a pointer, it can be dereferenced. Recall that dereferencing a pointer retrieves the value stored at the address being pointed to. In assembly, this is generally done by putting square brackets ("[" and "]") around the register. For example:

- eax -- is the value stored in eax
- [eax] -- is the value pointed to by eax

This will be thoroughly discussed in upcoming sections.

## Doing Nothing

The _nop_ instruction is probably the simplest instruction in assembly. nop is short for "no operation" and it does nothing. This instruction is used for padding.

## Moving Data Around

The instructions in this section deal with relocating numbers and pointers.

### mov, movsx, movzx

_mov_ is the instruction used for assignment, analogous to the "=" sign in most languages. mov can move data between a register and memory, two registers, or a constant to a register. Here are some examples:

```
mov eax, 1     ; set eax to 1 (eax = 1)
mov edx, ecx   ; set edx to whatever ecx is (edx = ecx)
mov eax, 18h   ; set eax to 0x18
mov eax, [ebx] ; set eax to the value in memory that ebx is pointing at
mov [ebx], 3   ; move the number 3 into the memory address that ebx is pointing at
```

_movsx_ and _movzx_ are special versions of mov which are designed to be used between signed (movsx) and unsigned (movzx) registers of different sizes.

_movsx_ means _move with sign extension_. The data is moved from a smaller register into a bigger register, and the sign is preserved by either padding with 0's (for positive values) or F's (for negative values). Here are some examples:

- **0x1000** becomes **0x00001000**, since it was positive
- **0x7FFF** becomes **0x00007FFF**, since it was positive
- **0xFFFF** becomes **0xFFFFFFFF**, since it was negative (note that 0xFFFF is -1 in 16-bit signed, and 0xFFFFFFFF is -1 in 32-bit signed)
- **0x8000** becomes **0xFFFF8000**, since it was negative (note that 0x8000 is -32768 in 16-bit signed, and 0xFFFF8000 is -32768 in 32-bit signed)

_movzx_ means _move with zero extension_. The data is moved from a smaller register into a bigger register, and the sign is ignored. Here are some examples:

- **0x1000** becomes **0x00001000**
- **0x7FFF** becomes **0x00007FFF**
- **0xFFFF** becomes **0x0000FFFF**
- **0x8000** becomes **0x00008000**

### lea

_lea_ is very similar to mov, except that math can be done on the original value before it is used. The "[" and "]" characters always surround the second parameter, but in this case they _do not indicate dereferencing_, it is easiest to think of them as just being part of the formula.

lea is generally used for calculating array offsets, since the address of an element of the array can be found with [arraystart + offset*datasize]. lea can also be used for quickly doing math, often with an addition and a multiplication. Examples of both uses are below.

Here are some examples of using lea:

```
lea     eax, [eax+eax]   ; Double the value of eax -- eax = eax * 2
lea     edi, [esi+0Bh]   ; Add 11 to esi and store the result in edi
lea     eax, [esi+ecx*4] ; This is generally used for indexing an array of integers. esi is a 
                           pointer to the beginning of an array, and ecx is the index of the  
                           element that is to be retrieved. The index is multiplied by 4  
                           because Integers are 4 bytes long. eax will end up storing the 
                           address of the ecx'th element of the array. 

lea     edi, [eax+eax*2] ; Triple the value of eax -- eax = eax * 3
lea     edi, [eax+ebx*2] ; This likely indicates that eax stores an array of 16-bit (2 byte) 
                           values, and that ebx is an offset into it. Note the similarities  
                           between this and the previous example: the same math is being done, 
                           but for a different reason. 
```

## Math and Logic

The instructions in this section deal with math and logic. Some are simple, and others (such as multiplication and division) are pretty tricky.

### add, sub

A register can have either another register, a constant value, or a pointer added to or subtracted from it. The syntax of addition and subtraction is fairly simple:

```
add eax, 3   ; Adds 3 to eax -- eax = eax + 3
add ebx, eax ; Adds the value of eax to ebx -- ebx = ebx + eax
sub ecx, 3   ; Subtracts 3 from ecx -- ecx = ecx - 3
```

### inc, dec

These instructions simply increment and decrement a register.

```
inc eax   ; eax++
dec ecx   ; ecx--
```

### and, or, xor, neg

All logical instructions are bitwise. If you don't know what "bitwise arithmetic" means, you should probably look it up. The simplest way of thinking of this is that each bit in the two operands has the operation done between them, and the result is stored in the first one.

The instructions are pretty self-explanatory: and does a bitwise 'and', or does a bitwise 'or', xor does a bitwise 'xor', and neg does a bitwise negation.

Here are some examples:

```
and eax, 7         ; eax = eax & 7          -- because 7 is 000..000111, this clears all bits 
                                               except for the last three. 
or  eax, 16        ; eax = eax | 16         -- because 16 is 000..00010000, this sets the 5th 
                                               bit from the right to "1". 
xor eax, 1         ; eax = eax ^ 1          -- this toggles the right-most bit in eax, 0=>1 or 
                                               1=>0.
xor eax, FFFFFFFFh ; eax = eax ^ 0xFFFFFFFF -- this toggles every bit in eax, which is 
                                               identical to a bitwise negation.
neg eax            ; eax = ~eax             -- inverts every bit in eax, same as the previous.
xor eax, eax       ; eax = 0                -- this clears eax quickly, and is extremely 
                                               common.
```

### mul, imul, div, idiv, cdq

Multiplication and division are the trickiest operations commonly used, because of how they deal with overflow issues. Both multiplication and division make use of the 64-bit register edx:eax.

_mul_ multiplies the unsigned value in eax with the operand, and stores the result in the 64-bit pointer edx:eax. _imul_ does the same thing, except the value is signed. Here are some examples of mul:

```
mul  ecx ; edx:eax = eax * ecx (unsigned)
imul edx ; edx:eax = eax * edx (signed)
```

When used with two parameters, _mul_ instead multiplies the first by the second as expected:

```
mul  ecx, 10h ; ecx = ecx * 0x10 (unsigned)
imul ecx, 20h ; ecx = ecx * 0x20 (signed)
```

_div_ divides the 64-bit value in edx:eax by the operand, and stores the quotient in eax. The remainder (modulus) is stored in edx. In other words, div does both division and modular division, at the same time. Typically, a program will only use one or the other, so you will have to check which instructions follow to see whether eax or edx is saved. Here are some examples:

```
div ecx  ; eax = edx:eax / ecx (unsigned)
         ; edx = edx:eax % ecx (unsigned)

idiv ecx ; eax = edx:eax / ecx (signed)
         ; edx = edx:eax % ecx (signed)
```

_cdq_ is generally used immediately before idiv. It stands for "convert double to quad." In other words, convert the 32-bit value in eax to the 64-bit value in edx:eax, overwriting anything in edx with either 0's (if eax is positive) or F's (if eax is negative). This is very similar to movsx, above.

_xor edx, edx_ is generally used immediately before div. It clears edx to ensure that no leftover data is divided.

Here is a common use of cdq and idiv:

```
mov eax, 1007 ; 1007 will be divided
mov ecx, 10   ; .. by 10
cdq           ; extends eax into edx
idiv ecx      ; eax will be 1007/10 = 100, and edx will be 1007%10 = 7
```

Here is a common use of xor and div (the results are the same as the previous example):

```
mov eax, 1007
mov ecx, 10
xor edx, edx
div ecx
```

## shl, shr, sal, sar

shl - shift left, shr - shift right.

sal - shift arithmetic left, sar - shift arithmetic right.

These are used to do a binary shift, equivalent to the C operations << and >>. They each take two operations: the register to use, and the number of places to shift the value in the register. As computers operate in base 2, these commands can be used as a faster replacement for multiplication/division operations involving powers of 2.

Divide by 2 (unsigned):

```
mov eax, 16    ; eax = 16
shr eax, 1     ; eax = 8
```

Multiply by 4 (signed):

```
mov eax, 5     ; eax = 5
sal eax, 2     ; eax = 20
```

Visualising the bits moving:

```
mov eax, 7     ; = 0000 0111  (7)
shl eax, 1     ; = 0000 1110 (14)
shl eax, 2     ; = 0011 1000 (56)
shr eax, 1     ; = 0001 1100 (28)
```

## Jumping Around

Instructions in this section are used to compare values and to make jumps. These jumps are used for calls, if statements, and every type of loop. The operand for most jump instructions is the address to jump to.

### jmp

_jmp_, or jump, sends the program execution to the specified address no matter what. Here is an example:

```
jmp 1400h ; jump to the address 0x1400
```

### call, ret

_call_ is similar to jump, except that in addition to sending the program to the specified address, it also saves ("pushes") the address of the executable instruction onto the stack. This will be explained more in a later section.

_ret_ removes ("pops") the first value off of the stack, and jumps to it. In almost all cases, this value was placed onto the stack by the call instruction. If the stack pointer is at the wrong location, or the saved address was overwritten, ret attempts to jump to an invalid address which usually crashes the program. In some cases, it may jump to the wrong place where the program will almost inevitably crash.

_ret_ can also have a parameter. This parameter is added to the stack immediately after ret executes its jump. This addition allows the function to remove values that were pushed onto the stack. This will be discussed in a later section.

The combination of _call_ and _ret_ are used to implement functions. Here is an example of a simple function:

```
 call 4000h
 ...... ; any amount of code
 4000h:
  mov eax, 1
  ret         ; Because eax represents the return value, this function would return 1, and                 
                nothing else would happen
```

### cmp, test

_cmp_, or compare, compares two operands and sets or unsets flags in the [flags](https://wiki.skullsecurity.org/index.php/Registers#flags "Registers") register based on the result. Specialized jump commands can check these flags to jump on certain conditions. One way of remembering how _cmp_ works is to think of it as subtracting the second parameter from the first, comparing the result to 0, and throwing away the result.

_test_ is very similar to _cmp_, except that it performs a bitwise 'and' operation between the two operands. _test_ is most commonly used to compare a variable to itself to check if it's zero.

### jz/je, jnz/jne, jl/jb, jg, jle, jge

- _jz_ and _je_ (which are synonyms) will jump to the address specified if and only if the 'zero' flag is set, which indicates that the two values were equal. In other words, "jump if equal".
- _jnz_ and _jne_ (which are also synonyms) will jump to the address specified if and only if the 'zero' flag is not set, which indicates that the two values were not equal. In other words, "jump if different".
- _jl_ and _jb_ (which are synonyms) jumps if the first parameter is less than the second.
- _jg_ jumps if the first parameter is greater than the second.
- _jle_ jumps if the 'less than' or the 'zero' flag is set, so "less than or equal to".
- _jge_ jumps if the first is "greater than or equal to" the second.

These jumps are all used to implement various loops and conditions. For example, here is some C code:

```
if(a == 3)
  b;
else
  c;
```

And here is how it might look in assembly (not exactly assembly, but this is an example):

```
10 cmp a, 3
20 jne 50
30 b
40 jmp 60
50 c
60
```

Here is an example of a loop in C:

```
for(i = 0; i < 5; i++)
{
  a;
  b;
}
```

And here is the equivalent loop in assembly:

```
10 mov ecx, 0
20 a
30 b
40 inc ecx
50 cmp ecx, 5
60 jl 20
```

## Manipulating the Stack

Functions in this section are used for adding and removing data from the stack. The stack will be examined in detail in a later section; this section will simply show some commonly used commands.

### push, pop

_push_ decrements the stack pointer by the size of the operand, then saves the operand to the new address. This line:

```
push ecx
```

Is functionally equivalent to:

```
sub esp, 4
mov [esp], ecx
```

_pop_ sets the operand to the value on the stack, then increments the stack pointer by the size of the operand. This assembly:

```
pop ecx
```

Is functionally equivalent to:

```
mov ecx, [esp]
add esp, 4
```

This will be examined in detail in the Stack section of this tutorial.

### pushaw, pushad, popaw, popad

_pushaw_ and _pushad_ save all 16-bit or 32-bit registers (respectively) onto the stack.

_popaw_ and _popad_ restore all 16-bit or 32-bit registers from the stack.
