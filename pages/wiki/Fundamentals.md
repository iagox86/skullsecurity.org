---
title: 'Wiki: Fundamentals'
author: ron
layout: wiki
permalink: "/wiki/Fundamentals"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Fundamentals"
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


This page is going to be about the fundamentals that you have to understand before you can make any sense out of assembly. Most of this stuff you\'ll learn if you learn to program in C. If this is old or boring stuff to you, feel free to skip this section entirely.

The topics here are going to be a short overview of each section. If you want a more complete explanation, you should find an actual reference, or look it up on the Internet. This is only meant to be a quick and dirty primer.

## Hexadecimal

To work in assembly, you have to be able to read hexadecimal fairly comfortably. Converting to decimal in your mind isn\'t necessary, but being able to do some simple arithmetic is.

Hex can be denoted in a number of ways, but the two most common are:

-   Prefixed with a 0x, eg. 0x1ef7
-   Postfixed with a h, eg. 1ef7h

The characters 0 - f represent the decimal numbers 0 - 15:

-   0 = 0
-   1 = 1
-   \...
-   9 = 9
-   a = 10
-   b = 11
-   c = 12
-   d = 13
-   e = 14
-   f = 15

To convert from hex to decimal, multiply each digit, starting with the right-most, with 16^0^, 16^1^, 16^2^, etc. So in the example of 0x1ef7, the conversion is this:

-   (7 \* 16^0^) + (f \* 16^1^) + (e \* 16^2^) + (1 \* 16^3^)
-   = (7 \* 16^0^) + (15 \* 16^1^) + (14 \* 16^2^) + (1 \* 16^3^)
-   = (7 \* 1) + (15 \* 16) + (14 \* 256) + (1 \* 4096)
-   = 7 + 240 + 3584 + 4096
-   = 7927

It isn\'t necessary to do that constantly, that\'s why we have calculators. But you should be fairly familiar with the numbers 00 - FF (0 - 255), they will come up often and you will spend a lot of time looking them up.

## Binary

Binary, as we all know, is a number system using only 0\'s and 1\'s. The usage is basically the same as hex, but change powers of 16 to powers of 2.

1011 to decimal:

-   (1 \* 2^0^) + (1 \* 2^1^) + (0 \* 2^2^) + (1 \* 2^3^)
-   = (1 \* 1) + (1 \* 2) + (0 \* 4) + (1 \* 8)
-   = 1 + 2 + 0 + 8
-   = 11

Conversion between decimal and binary is rare, it\'s much more common to convert between hexadecimal and binary. This conversion is common because it\'s so easy: every 4 binary digits is converted to a single hex digit. So all you really need to know are the first 16 binary to hex conversions:

-   0x0 = 0000
-   0x1 = 0001
-   0x2 = 0010
-   0x3 = 0011
-   0x4 = 0100
-   0x5 = 0101
-   0x6 = 0110
-   0x7 = 0111
-   0x8 = 1000
-   0x9 = 1001
-   0xa = 1010
-   0xb = 1011
-   0xc = 1100
-   0xd = 1101
-   0xe = 1110
-   0xf = 1111

So take the binary number 100101101001110, for example.

1.  Pad the front with zeros to make its length a multiple of 4: 0100101101001110
2.  Break it into 4-digit groups: 0100 1011 0100 1110
3.  Look up each set of 4-digits on the table: 0x4 0xb 0x4 0xe
4.  Put them all together 0x4b4e

To go the other way is even easier, using 0x469e for example:

1.  Separate the digits: 0x4 0x6 0x9 0xe
2.  Convert each of them to binary, by the table: 0100 0110 1001 1110
3.  Put them together, and leading zeros on the first group can be removed: 100011010011110

## Datatypes

A datatype basically refers to how digits in hex are partitioned off and divided into numbers. Datatypes are typically measures by two factors: the number of bits (or bytes), and whether or not negative numbers are allowed.

The number of bits (or bytes) refers to the length of the number. An 8-bit (or 1-byte) number is made up of two hexadecimal digits. For example, 0x03, 0x34, and 0xFF are all 8-bit, while 0x1234, 0x0001, and 0xFFFF are 16-bit.

The signed or unsigned property refers to whether or not the number can have negative values. If it can, then the maximum number is half of what it could have, with the other half being negatives. The way sign is determined is by looking at the very first bit. If the first bit is a 1, or the first hex digit is 8 - F, then it\'s negative and the rest of the number, inverted plus one, is used for the magnitude.

For example (use a calculator to convert to binary):

-   0x10 in binary is 0001 0000, so it\'s positive 16
-   0xFF in binary is 1111 1111, so it\'s negative. The rest of the number is the 7-bits, 1111111, inverted to 0000000, plus one is 0000001, or -1 in decimal.
-   0x80 in binary is 1000 0000, so it\'s negative. The rest of the number is the 7-bits, 0000000, inverted to 1111111, plus one is 10000000, or -128 in decimal.
-   0x7F in binary is 0111 1111, so it\'s positive 127.

Although different data lengths are called different things, here are some common ones by their usual name:

-   8-bit (1 byte) = char (or BYTE)
    -   In hex, can be 0x00 to 0xFF
    -   Signed: ranges from -128 to 127
    -   Unsigned: ranges from 0 to 255

-   16-bit (2 bytes) = short int (often referred to as a WORD)
    -   In hex, can be 0x0000 to 0xFFFF
    -   Signed: ranges from -32768 to 32767
    -   Unsigned: ranges from 0 to 65535

-   32-bit (4 bytes) = long int (often referred to as a DWORD or double-WORD)
    -   In hex, can be 0x00000000 to 0xFFFFFFFF
    -   Signed: ranges from -2147483648 to 2147483647
    -   Unsigned: ranges from 0 to 4294967295

-   64-bit (8 bytes) = long long (often referred to as a QWORD or quad-WORD)
    -   In hex, can be from 0x0000000000000000 to 0xFFFFFFFFFFFFFFFF
    -   Signed: -9223372036854775808 to 9223372036854775807
    -   Unsigned: 0 to 18446744073709551615

## Memory

Each running program has its own space of memory that isn\'t shared with any other process. Within this memory can be found everything the program needs to be able to run, including the program\'s code, variables, loaded .dll\'s, and the program stack.

When a program runs, the code from the .exe file is loaded into memory, and the instructions are executed from this memory image. This will become important, since we can modify the image loaded in memory without touching the .exe on the physical disk.

In addition to the program, any .dll files are loaded into the process\'s memory space. Each of the .dlls have a chunk of memory that may or may not be the same every time they\'re loaded. Each .dll also has its own section for its variables.

All variables in memory are stored in a certain byte order, which can be either little endian or big endian format. This is constant across the architecture, so every Intel x86 processor uses little endian, and every PowerPC uses big endian. Since this guide is about Intel x86, we won\'t worry about big endian.

In little endian, the bytes are stored in reverse order. So for example:

-   0x12345678 (4 bytes) is stored as 78 56 34 12
-   0x00001234 (4 bytes) is stored as 34 12 00 00
-   0xaabb (2 bytes) is stored as bb aa

This will be confusing at first, but you\'ll get used to seeing numbers backwards.

## Pointers

This is quite possibly the most difficult part of the C language to understand, and I won\'t pretend that I\'m such an amazing teacher that you\'ll understand this completely after reading my blurb. You HAVE to know this to get by in assembly, so if it isn\'t perfectly clear after you read this, find a tutorial and make sure you understand!

A pointer is, simply, a variable that stores a memory address as its value. The memory address it stores can be anything. The value of the referenced memory address can be obtained by \"dereferencing\" the pointer. Dereferencing means retrieving the value being pointed to, rather than the pointer itself.

This is the C code to declare a variable that will point to an integer:

`int *i;`

And here is the C code to declare a pointer to a character:

`char *c;`

These are declared like any other variable, except for the asterisk. When declaring variables, the asterisk simply means it\'s a pointer, and nothing else.

The address of any variable (pointer or otherwise) can be obtained with the \"address of\" operator, \'&\'. By putting \'&\' in front of a variable, its address is returned. This address can then be stored by a pointer. In other words, the pointer can point to some variable. Here\'s an example of using the \"address of\" operator:

     int *i; /* Declare i as a pointer. */
     int somevar = 7; /* Declare a variable called somevar, and set it to 7. */

     i = &somevar; /* Set the value of i (which is the address) to the address of somevar. */

The final use of a pointer is \"dereferencing\", as discussed before. To dereference a pointer, an asterisk (\"\*\") is put before it. This should not be confused with the asterisk used to declare a pointer, which is completely different. Here is an example of dereferencing, be sure you fully understand this (note that I\'m using a function called \'print()\' which doesn\'t actually exist to illustrate the point):

     int *i; /* Declare i as a pointer. */
     int somevar = 7; /* Declare a variable called somevar, and set it to 7. */

     i = &somevar; /* Set the value of i (which is the address) to the address of somevar. */

     print(i); /* This will print out the ADDRESS stored in i, which is the address of somevar. */
     print(*i); /* This dereferences i, and prints out 7, because i points to the address of somevar and somevar is 7. */

     *i = 10; /* This sets the value that i points to (somevar) to 10. */
     print(somevar); /* This will print out 10, because its memory has just been changed via the pointer i. */ 

Hopefully that all makes sense. To summarize:

-   An asterisk (\"\*\") is used in declaration to show a variable is a pointer: int \*i
-   An ampersand (\"&\") is used in front of any variable to retrieve its address: i = &somevar
-   An asterisk (\"\*\") is used on a pointer to dereference it, to get the value it\'s pointing to: print(\*i)

Note that if a pointer without a valid address is dereferenced, the program will crash.

Some arithmetic can be done on pointers, such add addition and subtraction. Doing addition/subtraction on pointers is different than a normal variable because the size of the data type is taken into account. That is, instead of \"ptr + 1\" going to the next whole number, if ptr is an integer it goes to the next possible integer in memory, which is 4 bytes away. If the ptr was a short (2 bytes), \"ptr + 1\" goes ahead 2 bytes, to the next short in memory. The reason for this is so that arrays can be easily stepped through, which will be shown below.

## Ascii

Ascii is the way in which letters, numbers, and symbols are represented in memory.

A single ascii character is a 1-byte value. Typically, ascii characters fall between 0x00 and 0x7F. The important ones are:

-   0x00 or \'\\0\' signals the end of a string (a sequence of ascii characters)
-   0x0d and 0x0a are carriage return and linefeed, respectively. They are used to add a new-line within a string.
-   0x20 is space, \' \'
-   0x30 - 0x39 are \'0\' - \'9\' (0x30 = \'0\', 0x31 = \'1\', 0x32 = \'2\', etc)
-   0x41 - 0x5A are \'A\' - \'Z\'
-   0x61 - 0x7A are \'a\' - \'z\'

## Arrays

An array is a sequence of 1 or more values of the same type. In memory, all entries in an array are stored sequentially.

For example, an array of these five integers {1, 2, 3, 0xaabb, 0xccdd} will be stored like this:

`01 00 00 00 02 00 00 00 03 00 00 00 bb aa 00 00 dd cc 00 00`\
`           |           |           |           |`

Note that values stored are all expanded to the full size of integers, padded with zeros. Also note that the values are stored in little endian, so the order of the bytes are reversed.

An array in C is declared like this:

`int arr[5] = { 1, 2, 3, 0xaabb, 0xccdd }; `

This creates an array of 5 integers, which reserves 20 bytes (5 integers \* 4 bytes/integer) to store them. An array in C must have a static length, because the space is allocated before the program ever runs.

When an array is created this way, the array variable (\"arr\") is actually a *pointer* to the first element. Then when an array is accessed, an *addition* and a *dereference* occur.

This code:

`int arr[5] = { 1, 2, 3, 0xaabb, 0xccdd };`\
`print(arr[2]); `

Will display the third element in the array, the number 3. This code:

`int arr[5] = { 1, 2, 3, 0xaabb, 0xccdd };`\
`print( *(arr + 2) );`

Is identical. The address that is 2 past the first element will be dereferenced, and that address contains the third value. Recall that addition on a pointer increments based on the type, so \"arr + 2\" in this case goes ahead by 2 integers, or 8 bytes.

Here is a way to loop through an array using pointers:

     int arr[5] = { 1, 2, 3, 0xaabb, 0xccdd };
     int *ptr;
     int i;

     ptr = arr; // Point ptr at arr. Note that we don't use "address of" on arr, since arr is already a pointer and therefore already contains an address. 
     for(i = 0; i < 5; i++)
     {
      print(*ptr); // Print the value of the element, starting at 0, ending with 4
      ptr++; // Go to the next element in the array
     }

## Strings

After all that tough stuff, strings are actually pretty easy!

A string is an array of ascii characters, ended with a null \'\\0\' character.

This:

`char str[] = "Hello";`

creates an array of 6 characters, and copies in the string, creating the array shown here:

`{ 'H',  'e',  'l',  'l',  'o',  '\0' }`

Or:

`{ 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00 }`

This similar construct:

`char *str = "Hello";`

creates a pointer to a static string, \"Hello\", which can\'t be changed. Very similar, but not exactly the same. A string created in this way can\'t be changed.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.
