---
title: 'Wiki: Example 10'
author: ron
layout: wiki
permalink: "/wiki/Example_10"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Example_10"
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


This example was inspired by the protection on Starcraft, which prevents external programs from accessing it. This will first show how to manually remove Starcraft\'s protection, and then a generic loader designed for any program.

## Removing Protection {#removing_protection}

While I was disassembling Starcraft.exe for a completely unrelated reason, I figured I\'d check out the main function to see what happens:

`.text:004DF940                   ; int __stdcall WinMain(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPSTR lpCmdLine,int nShowCmd)`\
`.text:004DF940                   _WinMain@16:                            ; CODE XREF: start+17F�p`\
`.text:004DF940 55                                push    ebp`\
`.text:004DF941 8B EC                             mov     ebp, esp`\
`.text:004DF943 56                                push    esi`\
`.text:004DF944 8B 75 08                          mov     esi, [ebp+8]`\
`.text:004DF947 89 35 8C AF 51 00                 mov     dword_51AF8C, esi`\
`.text:004DF94D E8 3E 00 FF FF                    call    sub_4CF990`\
`.text:004DF952 FF 15 F8 D1 4F 00                 call    ds:GetCurrentThreadId`\
`.text:004DF958 68 AC E8 4F 00                    push    offset aSwarclass ; "SWarClass"`\
`.text:004DF95D A3 B8 B9 6C 00                    mov     dword_6CB9B8, eax`\
`.text:004DF962 E8 A9 F8 FF FF                    call    sub_4DF210`\
`.text:004DF967 E8 C4 9E FF FF                    call    sub_4D9830`\
`.text:004DF96C E8 5F F9 FF FF                    call    sub_4DF2D0`\
`.text:004DF971 E8 0A D6 00 00                    call    sub_4ECF80`\
`.text:004DF976 E8 15 F7 FF FF                    call    sub_4DF090`\
`.text:004DF97B E8 30 FD FF FF                    call    loc_4DF6B0`

I thought I\'d kill time by checking what each of those calls do. The first few are boring, one ensures that you can\'t run more than one instance, another checks system requirements, and so on.

When I got to checking sub_4DF090, however, my interest was stirred up. It was a bunch of different ACL (access control list) functions, and setting authorizations, culminating in a call to SetSecurityInfo()! So I had a hunch, and disabled SetSecurityInfo() like this:

-   Run Starcraft through a debugger (Starcraft has to be immediately paused, which windbg does).
-   Search for the function \"advapi32!SetSecurityInfo\".
-   Disable it by setting the first three bytes to \"c2 1c 00\" (you can find the number of bytes to pop, 0x1c, by scrolling to the bottom of the function).
-   \"Run\" the program, and test it. TSearch can now find/modify data, and you can still log onto Battle.net!

## Loaders

A loader is fairly simple to write, it\'s a program that calls CreateProcess() with the dwFlags parameter set to CREATE_SUSPENDED. Once the program is loaded, changes can be made to the code (such as disabling SetSecurityInfo(), and the code can be resumed with ResumeThread().

Disabling the SetSecurityInfo function is somewhat tricky. Because advapi32.dll isn\'t loaded immediately, it has to be forced to load. The easiest way to do this is with a .dll injection function (see [.dll Injection and Patching](.dll_Injection_and_Patching "wikilink")).

## The Code {#the_code}

Here is the code, which I have tried to make rather useful:

    #include <stdio.h>
    #include <stdlib.h>
    #include <windows.h>

    #include "Injection.h"
    #include "getopt.h"

    /** This prints the error message, then ends the program. */
    void error(char *message)
    {
        fprintf(stderr, "Fatal Error: %s\nTerminated.\n\n", message);

        system("pause");
        exit(1);
    }

    /** This creates the new process, and fills in the two HANDLEs with the handles of the newly 
     * created process. This also suspends the process, ResumeThread()  has to be called on hThread
     * to get it going.
     *  lpAppPath: The full path to the application. 
     *  lpCmdLine: The commandline. First parameter has to be the program name, or this has to be NULL.
     *  hThread:   The created thread is put in here. 
     *  hProcess:  The created process is put in here. 
     */
    void CreateProcessEx ( LPCSTR lpAppPath, LPCSTR lpCmdLine, HANDLE *hThread, HANDLE *hProcess) 
    {
        STARTUPINFO         startupInfo;
        PROCESS_INFORMATION processInformation;    

        printf("Attempting to load the program: %s\n", lpAppPath);
        if(lpCmdLine)
            printf(" -> Command Line: %s\n", lpCmdLine);

        /* Initialize the STARTUPINFO structure. */
        ZeroMemory( &startupInfo, sizeof( STARTUPINFO ));
        startupInfo.cb = sizeof( STARTUPINFO );

        /* Initialize the PROCESS_INFORMATION structure. */
        ZeroMemory( &processInformation, sizeof( PROCESS_INFORMATION ));

        /* Create the actual process with an overly-complicated CreateProcess function. */
        if(!CreateProcess(lpAppPath, lpCmdLine ? lpCmdLine : ",", 0, 0, FALSE, CREATE_NEW_CONSOLE | CREATE_SUSPENDED, 0, 0, &startupInfo, &processInformation))
            error("Failed to create the process");

        *hThread = processInformation.hThread;
        *hProcess = processInformation.hProcess;

        printf("Successfully created the process!\n\n");
    }

    /** This function overwrites the first bytes of a function with the specified bytes, 
     * with the intention of disabling a function. The first few bytes can be replaced with
     * a "ret" or a "mov eax, xxx / ret". This will be used to disable certain functions 
     * like SetSecurityInfo() and IsDebuggerPresent(). This will also load the .dll file 
     * that the function is contained in, if it's not already loaded. 
     *
     * Note that certain .dll functions may cause unpredictable results. For example, if
     * you try disabling a function in battle.snp, Battle.net won't connect. Most normal 
     * .dll functions should be ok, though. 
     * 
     *  hProcess:  The process to modify the data. 
     *  function:  The name of the function, such as "SetSecurityInfo"
     *  dll:       The name of the .dll file, such as "advapi32.dll". Has to be just the name, not the path. 
     *  code:      The code to replace the opening bytes with, see below for some examples
     *  length:    The number of bytes to replace (should be the same as the length of code)
     * 
     * Here are the most common ways to return early (be sure you match the function's 
     * real return size!):
     *  ret:    c3
     *  ret xx: c2 xx xx
     *
     * And here are some ways to set the value that's returned (be sure to follow with
     *  c3 or c2 xx xx:
     *
     * return 1:  b8 01 00 00 00 (mov eax, 1)
     * return 1:  6a 01 58       (push 1 / pop eax)
     * return 1+: 83 c8 01       (or eax, 1)
     * return 0:  33 c0
     * return -1: b8 ff ff ff ff (mov eax, -1)
     * return -1: 33 c0 83 e8 01 (xor eax, eax / sub eax, 1)
     * return -1: 83 c8 ff       (or eax, -1)
     * 
     * Here are some examples:
     *  return 1: "\x6a\x01\x58\xc3"
     *  return 0: "\x33\xc0\xc3"
     */
    void DisableFunction(HANDLE hProcess, char *function, char *dll, char *code, int length)
    {
        HMODULE addrModule = NULL;
        FARPROC addrFunction = NULL;

        printf(" -> Disabling %s!%s\n", dll, function);

        /* Try and get the module handle without loading it. */
        addrModule = GetModuleHandle(dll);
        if(!addrModule)
        {
            printf("    -> .dll doesn't seem to be loaded, attempting to load.\n");
            /* The module wasn't found, so we probably have to load it. This line loads it (into the current process). */
            addrModule = LoadLibrary(dll);
            if(!addrModule)
            {
                /* Apparently the library couldn't be loaded. */
                printf("    -> ERROR! Couldn't find library: %s\n", dll);
                return;
            }
        }
        printf("    -> Found %s: %p\n", dll, addrModule);

        /* Get the address of the function within the .dll file. */
        addrFunction = GetProcAddress(addrModule, function);
        if(!addrFunction)
        {
            printf("    -> ERROR! Couldn't find function: %s\n", function);
            return;
        }

        printf("    -> Found %s: %p\n", function, addrFunction);
        printf("    -> Attempting to overwrite with %d bytes of code\n", length);
        
        /* Attempt to write to the foreign process. */
        if(!WriteProcessMemory(hProcess, addrFunction, code, length, NULL))
        {
            printf("    -> Memory write failed, attempting to load the .dll into the process\n");
            /* If the write failed, it likely means that the .dll isn't loaded yet, so load it into the foreign process. */
            if(!InjectLibrary(hProcess, dll))
            {
                printf("    -> ERROR! Couldn't load the dll: %s\n", dll);
                return;
            }

            /* Try writing again. Hopefully it'll work this time. */
            if(!WriteProcessMemory(hProcess, addrFunction, code, length, NULL))
            {
                printf("    -> ERROR! Still couldn't disable the function!\n");
                return;
            }
        }
        printf("    -> Function %s!%s disabled successfully!\n", dll, function);
    }

    /** This function will probably be extended in the future to include more and more security functions. 
     * This prevents certain functions from running. These functions can prevent and detect things like 
     * debuggers and other tools. */
    void DisableSecurity(HANDLE hProcess)
    {
        DisableFunction(hProcess, "SetSecurityInfo",   "advapi32.dll", "\xc2\x1c\x00", 3);
        DisableFunction(hProcess, "IsDebuggerPresent", "kernel32.dll", "\x33\xc0\xc3", 3);
    }

    /** Print out the command-line usage. */
    void usage()
    {
        error("Proper usage:                                                 \n\
                                                                             \n\
      x86-loader.exe [-s <0/1>] [-c <commandline>] [-d <dll>] <program>      \n\
                                                                             \n\
       -s                                                                    \n\
       When -s is set to its default value of 1, certain security functions  \n\
       are disabled, which prevents the program from protecting itself from  \n\
       other tools, such as debuggers. Currently, the following security     \n\
       functions are disabled:                                               \n\
       - advapi32.dll!SetSecurityInfo()                                      \n\
       - kernel32.dll!IsDebuggerPresent()                                    \n\
                                                                             \n\
       -c                                                                    \n\
       The -c parameter provides a commandline to pass to the program. The   \n\
       first parameter must always be the name of the program (or            \n\
       something), the first real parameter passed to the program is the     \n\
       second parameter on -c. Use quotation marks to give more than one     \n\
       parameter.                                                            \n\
                                                                             \n\
       -d                                                                    \n\
       If -d is set, the given will be loaded into the program's address     \n\
       space immediately after the program is loaded.                        \n\
                                                                             \n\
       <program>                                                             \n\
       This is the program that will be run by this loader.                  \n\
       ");
    }

    int main(int argc, char *argv[], char **env)
    {
        HANDLE hThread;
        HANDLE hProcess;

        char *dll             = NULL;
        BOOL disable_security = TRUE;
        char *commandline     = NULL;
        char *program         = NULL;
        int c;

        opterr = 0;

        /* This big loop and switch() parse the command-line parameters. */
        while ((c = getopt (argc, argv, "s:c:d:")) != -1)
        {
            switch (c)
            {
            case 's':
                 disable_security = atoi(optarg);
                 break;

            case 'c':
                 commandline = optarg;
                 break;

            case 'd':
                 dll = optarg;
                 break;

            case '?':
                 fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                 usage();
                 return 1;

            default:
                 return 1;
            }
        }
        if(optind >= argc)
            usage();
        program = argv[optind];

        /* The process is always created. */
        CreateProcessEx(program, commandline, &hThread, &hProcess);

        /* If they opt to disable the security functions, do it. */
        if(disable_security)
            DisableSecurity(hProcess);

        /* If they provided a .dll file, inject it. */
        if(dll)
            InjectLibrary(hProcess, dll);

        /* Resume the thread. */
        ResumeThread(hThread);

        /* Pause before ending. */
        system("pause");

        return 0;
    }

This requires getopt() functions (which can be found under LGPL) and Injection functions. The full bunch of functions can be found [here](http://www.skullsecurity.org/~ron/code/x86-loader.zip).

NEW: You can now download an improved version of the loader, along with the Visual Studio project and a .dll with a bunch of example patches, [here](http://www.skullsecurity.org/~ron/code/x86%20Plugin.zip)!

[Category: Assembly Examples](Category:_Assembly_Examples "wikilink")
