---
title: 'Wiki: The Stack'
author: ron
layout: wiki
permalink: "/wiki/The_Stack"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/The_Stack"
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


The stack is, at best, a difficult concept to understand. However, understanding the stack is essential to reverse engineering code.

The stack register, esp, is basically a register that points to an arbitrary location in memory called \"the stack\". The stack is just a really big section of memory where temporary data can be stored and retrieved. When a function is called, some stack space is allocated to the function, and when a function returns the stack should be in the same state it started in.

The stack always grows downwards, towards lower values. The esp register always points to the lowest value on the stack. Anything below esp is considered free memory that can be overwritten.

The stack stores function parameters, local variables, and the return address of every function.

## Function Parameters

When a function is called, its parameters are typically stored on the stack before making the call. Here is an example of a function call in C:

```
func(1, 2, 3); 
```

And here is the equivalent call in assembly:

```
push 3
push 2
push 1
call func
add esp, 0Ch
```

The parameters are put on the stack, then the function is called. The function has to know it's getting 3 parameters, which is why function parameters have to be declared in C.

After the function returns, the stack pointer is still 12 bytes ahead of where it started. In order to restore the stack to where it used to be, 12 (0x0c) has to be added to the stack pointer. The three pushes, of 4 bytes each, mean that a total of 12 was subtracted from the stack.

Here is what the initial stack looked like (with ?'s representing unknown stack values):

|_**esp**_|?|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|

Note that the same 5 32-bit stack values are shown in all these examples, with the stack pointer at the left moved. The stack goes much further up and down, but that isn't shown here.

Here are the three pushes:

  
```
push 3
```

|esp + 4|?|
|_**esp**_|3|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|

  
```
push 2
```

|esp + 8|?|
|esp + 4|3|
|_**esp**_|2|
|esp - 4|?|
|esp - 8|?|

  
```
push 1
```

|esp + 12|?|
|esp + 8|3|
|esp + 4|2|
|_**esp**_|1|
|esp - 4|?|

Now all three values are on the stack, and esp is pointing at the 1. The function is called, and returns, leaving the stack the way it started. Now the final instruction runs:

  
```
add esp, 0Ch
```

|_**esp**_|?|
|esp + 4|3|
|esp + 8|2|
|esp - 12|1|
|esp - 16|?|

Note that the 3, 2, and 1 are still on the stack. However, they're below the stack pointer, which means that they are considered free memory and will be overwritten.

## call and ret Revisited

The _call_ instruction pushes the address of the next instruction onto the stack, then jumps to the specified function.

The _ret_ instruction pops the next value off the stack, which should have been put there by a call, and jumps to it.

Here is some example code:

```
0x10000000 push 3
0x10000001 push 2
0x10000002 push 1
0x10000003 call 0x10000020
0x10000007 add esp, 12
0x10000011 exit ; This isn't a real instruction, but pretend it is
0x10000020 mov eax, 1
0x10000024 ret
```

Now here is what the stack looks like at each step in this code:

  
```
0x10000000 push 3
```

|esp + 4|?|
|_**esp**_|3|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|
|esp - 20|?|

  
```
0x10000001 push 2
```

|esp + 8|?|
|esp + 4|3|
|_**esp**_|2|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|

  
```
0x10000002 push 1
```

|esp + 12|?|
|esp + 8|3|
|esp + 4|2|
|_**esp**_|1|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|

  
```
0x10000003 call 0x10000020
```

|esp + 16|?|
|esp + 12|3|
|esp + 8|2|
|esp + 4|1|
|_**esp**_|0x1000007|
|esp - 4|?|
|esp - 8|?|

  
```
0x10000020 mov eax, 1
```

|esp + 16|?|
|esp + 12|3|
|esp + 8|2|
|esp + 4|1|
|_**esp**_|0x1000007|
|esp - 4|?|
|esp - 8|?|

  
```
0x10000024 ret
```

|esp + 12|?|
|esp + 8|3|
|esp + 4|2|
|_**esp**_|1|
|esp - 4|0x1000007|
|esp - 8|?|
|esp - 12|?|

  
```
0x10000007 add esp, 12
```

|_**esp**_|?|
|esp - 4|3|
|esp - 8|2|
|esp - 12|1|
|esp - 16|0x1000007|
|esp - 20|?|
|esp - 24|?|

  
```
0x10000011 exit ; This isn't a real instruction, but pretend it is
```

|_**esp**_|?|
|esp - 4|3|
|esp - 8|2|
|esp - 12|1|
|esp - 16|0x1000007|
|esp - 20|?|
|esp - 24|?|

Note the return address being pushed onto the stack by call, and being popped off the stack by ret.

## Saved Registers

Some registers (ebx, edi, esi, ebp) are generally considered to be non-volatile. What that means is that when a function is called, those registers have to be saved. Typically, this is done by pushing them onto the stack at the start of a function, and popping them in reverse order at the end. Here is a simple example:

```
; function test()
push esi
push edi
.....
pop edi
pop esi
ret
```

## Local Variables

At the beginning of most functions, space to store local variables in is allocated. This is done by subtracting the total size of all local variables from the stack pointer at the start of the function, then referencing them based on the stack. An example of this will be demonstrated in the following section.

## Frame Pointer

The frame pointer is the final piece to the puzzle. Unless a program has been optimized, ebp is set to point at the beginning of the local variables. The reason for this is that throughout a function, the stack changes (due to saving variables, making function calls, and others reasons), so keeping track of where the local variables are relative to the stack pointer is tricky. The frame pointer, on the other hand, is stored in a non-volatile register, ebp, so it never changed during the function.

Here is an example of a swap function that uses two parameters passed on the stack and a local variable to store the interim result (if you don't fully understand this, don't worry too much -- I don't either. IDA tends to look after this kind of stuff for you automatically, so this is more theory than actual useful information. Please note that the virtual memory addresses have been modified for simplicity, in reality the addresses would increase based on the size of the previous operation):

```
0x400000 push ecx             ; A pointer to an integer in memory - second parameter (param2)
0x400001 push edx             ; Another integer pointer - first parameter (param1)
0x400002 call 0x401000        ; Call the swap function
0x400003 add esp, 8           ; Balance the stack
.....
0x401000 ; function swap(int *a, int *b)
0x401000 push ebp             ; Preserve ebp.
0x401001 mov ebp, esp         ; Set up the frame pointer.
0x401002 sub esp, 8           ; Make room for two local variables.
0x401003 push esi             ; Preserve esi on the stack.
0x401004 push edi             ; Preserve edi on the stack.

0x401005 mov ecx, [ebp+8]     ; Put param1 (a pointer) into ecx.
0x401006 mov edx, [ebp+12]    ; Put param2 (a pointer) into edx.

0x401007 mov esi, [ecx]       ; Dereference param1 to get the first value.
0x401008 mov edi, [edx]       ; Dereference param2 to get the second value.

0x401009 mov [ebp-4], esi     ; Store the first value as a local variable
0x40100a mov [ebp-8], edi     ; Store the second value as a local variable

0x40100b mov esi, [ebp-8]     ; Retrieve them in reverse
0x40100c mov edi, [ebp-4]

0x40100d mov [ecx], edi       ; Put the first value into the second address (param2 = param1)
0x40100e mov [edx], esi       ; Put the second value into the first address (param1 = param2)
		
0x40100f pop edi              ; Restore the edi register
0x401010 pop esi              ; Restore the esi register
0x401011 add esp, 8           ; Remove the local variables from the stack
0x401012 pop ebp              ; Restore ebp
0x401013 ret                  ; Return (eax isn't set, so there's no return value)
```

(You can download the complete code to test this example in Visual Studio [here](https://wiki.skullsecurity.org/index.php/Stack_Example "Stack Example").)

  

Because this is such a complicated example, it's valuable to go through it step by step, keeping track of the stack (again, if you use IDA, the stack variables will automatically be identified, but you should still understand how this works):

Initial stack:

|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|
|esp - 20|?|
|esp - 24|?|
|esp - 28|?|
|esp - 32|?|
|esp - 36|?|

  
```
0x400000 push ecx      ; A pointer to an integer in memory
0x400001 push edx      ; Another integer pointer
```

|esp + 4|param2|
|_**esp**_|param1|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|
|esp - 20|?|
|esp - 24|?|
|esp - 28|?|

  
```
0x400002 call 0x401000 ; Call the swap function
```

|esp + 8|param2|
|esp + 4|param1|
|_**esp**_|0x400003|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|
|esp - 20|?|
|esp - 24|?|

  
```
0x401000 ; function swap(int *a, int *b)
0x401000 push ebp      ; Preserve ebp.
```

|esp + 12|param2|
|esp + 8|param1|
|esp + 4|0x400003|
|_**esp**_|(ebp's value)|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|
|esp - 16|?|
|esp - 20|?|

  
```
0x401001 mov ebp, esp  ; Set up the frame pointer.
0x401002 sub esp, 8    ; Make room for two local variables.
```

|esp + 20|param2|
|esp + 16|param1|
|esp + 12|0x400003|
|esp + 8, _**ebp**_|(previous ebp)|
|esp + 4|(unused)|
|_**esp**_|(unused)|
|esp - 4|?|
|esp - 8|?|
|esp - 12|?|

  
```
0x401003 push esi      ; Preserve esi on the stack.
0x401004 push edi      ; Preserve edi on the stack.
```

|esp + 28, _ebp + 12_|param2|
|esp + 24, _ebp + 8_|param1|
|esp + 20, _ebp + 4_|0x400003|
|esp + 16, _**ebp**_|(previous ebp)|
|esp + 12, _ebp - 4_|(unused)|
|esp + 8, _ebp - 8_|(unused)|
|esp + 4, _ebp - 12_|(esi)|
|_**esp**_, _ebp - 16_|(edi)|
|esp - 4, _ebp - 20_|?|

  
Note how in the following section the variables are address based in the address of ebp. The first parameter is ebp + 8, which is 2 values above ebp on the stack, and the second is ebp + 12, which is 3 above ebp. Count them to confirm!

```
0x401005 mov ecx, [ebp+8]   ; Put the first parameter (a pointer) into ecx.
0x401006 mov edx, [ebp+12]  ; Put the second parameter (a pointer) into edx.
```

|esp + 28, _ebp + 12_|param2|
|esp + 24, _ebp + 8_|param1|
|esp + 20, _ebp + 4_|0x400003|
|esp + 16, _**ebp**_|(previous ebp)|
|esp + 12, _ebp - 4_|(unused)|
|esp + 8, _ebp - 8_|(unused)|
|esp + 4, _ebp - 12_|(esi)|
|_**esp**_, _ebp - 16_|(edi)|
|esp - 4, _ebp - 20_|?|

  

  
These lines don't use the stack, so the table will be omitted:

```
0x401007 mov esi, [ecx] ; Dereference param1 to get the first value.
0x401008 mov edi, [edx] ; Dereference param2 to get the second value.
0x401009 mov [ebp-4], esi ; Store the first value as a local variable
0x40100a mov [ebp-8], edi ; Store the second value as a local variable
```

|esp + 28, _ebp + 12_|param2|
|esp + 24, _ebp + 8_|param1|
|esp + 20, _ebp + 4_|0x400003|
|esp + 16, _**ebp**_|(previous ebp)|
|esp + 12, _ebp - 4_|esi (var1)|
|esp + 8, _ebp - 8_|edi (var2)|
|esp + 4, _ebp - 12_|(esi)|
|_**esp**_, _ebp - 16_|(edi)|
|esp - 4, _ebp - 20_|?|

  
```
0x40100b mov esi, [ebp-8] ; Retrieve them in reverse
0x40100c mov edi, [ebp-4]
```

|esp + 28, _ebp + 12_|param2|
|esp + 24, _ebp + 8_|param1|
|esp + 20, _ebp + 4_|0x400003|
|esp + 16, _**ebp**_|(previous ebp)|
|esp + 12, _ebp - 4_|esi (var1)|
|esp + 8, _ebp - 8_|edi (var2)|
|esp + 4, _ebp - 12_|(esi)|
|_**esp**_, _ebp - 16_|(edi)|
|esp - 4, _ebp - 20_|?|

  

  
```
0x40100d mov [ecx], edi ; Put the first value into the second address (param2 = param1)
0x40100e mov [edx], esi ; Put the second value into the first address (param1 = param2)
0x40100f pop edi        ; Restore the edi register
0x401010 pop esi        ; Restore the esi register
```

|esp + 20, _ebp + 12_|param2|
|esp + 16, _ebp + 8_|param1|
|esp + 12, _ebp + 4_|0x400003|
|esp + 8, _**ebp**_|(previous ebp)|
|esp + 4, _ebp - 4_|esi (var1)|
|_**esp**_ , _ebp - 8_|edi (var2)|
|esp - 4, _ebp - 12_|(esi)|
|esp - 8, _ebp - 16_|(edi)|
|esp - 12, _ebp - 20_|?|

  
```
0x401011 add esp, 8     ; Remove the local variables from the stack
```

|esp + 12, _ebp + 12_|param2|
|esp + 8, _ebp + 8_|param1|
|esp + 4, _ebp + 4_|0x400003|
|_**esp**_, _**ebp**_|(previous ebp)|
|esp - 4, _ebp - 4_|esi (var1)|
|esp - 8, _ebp - 8_|edi (var2)|
|esp - 12, _ebp - 12_|(esi)|
|esp - 16, _ebp - 16_|(edi)|
|esp - 20, _ebp - 20_|?|

  
```
0x401012 pop ebp        ; Restore ebp
```

|esp + 8|param2|
|esp + 4|param1|
|_**esp**_|0x400003|
|esp - 4|(previous ebp)|
|esp - 8|esi (var1)|
|esp - 12|edi (var2)|
|esp - 16|(esi)|
|esp - 20|(edi)|
|esp - 24|?|

  
```
0x401013 ret            ; Return (eax isn't set, so there's no return value)
```

|esp + 4|param2|
|_**esp**_|param1|
|esp - 4|0x400003|
|esp - 8|(previous ebp)|
|esp - 12|esi (var1)|
|esp - 16|edi (var2)|
|esp - 20|(esi)|
|esp - 24|(edi)|
|esp - 28|?|

```
0x400007 add esp, 8    ; Balance the stack
```

|esp - 4|param2|
|esp - 8|param1|
|esp - 12|0x400003|
|esp - 16|(previous ebp)|
|esp - 20|esi (var1)|
|esp - 24|edi (var2)|
|esp - 28|(esi)|
|esp - 32|(edi)|
|esp - 36|?|

## Balance

This should be rather obvious from the examples shown above, but it is worth paying special attention to.

Every function should leave the stack pointer in the exact place it received it. In other words, every amount subtracted from the stack (either by sub or push) _has to be added to the stack_ (either by add or pop). If it isn't, the return value won't be in the right place and the program will likely crash.
