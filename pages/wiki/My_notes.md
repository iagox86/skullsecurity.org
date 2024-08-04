---
title: 'Wiki: My notes'
author: ron
layout: wiki
permalink: "/wiki/My_notes"
date: '2024-08-04T15:51:38-04:00'
---

These are the notes I made while taking apart the module stuff. Most of it is probably nonsensical, and a lot of it is outdated or inaccurate now, or even just plain insane. But if you\'ve worked on it yourself, or are planning on taking my work further, you might find some valuable information, particularly on the data structures used.

Mostly, I recommend ignoring this, I just post it here for historical value. :)

    Note: All this is against Starcraft 1.15.2

    Note: Throughout this document and my decrypted code and, pretty much everywhere, I use the string "Maive.mod" to decrypt
     the built-in module. There are two important things to keep in mind:
     1) There's no guarantee that this is actually the name, the place where the string in question is used is near
        the module, so I think it's a reasonable guess. 
     2) I've been spelling it wrong the whole time, it's supposed to be "Maiev.mod". Oops. :)

    0x00400000 = Starcraft.exe
    0x15000000 = storm.dll
    0x19000000 = battle.snp
    0x02e30000 = Maive.mod (the built-in module) [this address changes on each run, but the
                 run when I captured it used this address]

    ----------------------------------
    To set breakpoints in the module at specific points, run this in Windbg:

    e SetThreadContext 0xc2 0x08 0x00
    ba e1 19018461 "bd *; ba e1 eax+0x264C; g"

    (Replace the offset with whichever offset you want)
    ----------------------------------
    To inspect the Warden packets:

    e SetThreadContext 0xc2 0x08 0x00
    ba e1 19018461 "bd *; ba e1 eax+0x248b \".echo Sent SID_WARDEN Data:; d poi(esp+4) poi(esp+4)+poi(esp+8)-1; g\"; ba e1 eax+0x2730 \".echo Received SID_WARDEN Data:; d eax eax+esi-1; g\"; g"
    ----------------------------------
    To load a module into IDB:

    File->Load File->Additional Binary File
        Pick the .bin file
        Set:
            Loading segment: 0x0
            Loading offset: The base address you want
            File offset in bytes: 0x0
            Number of bytes: 0x0
            Create segments: yes
            Code segment: yes
    View->Open Subviews->Segments
        Right-click on the new segment (seg000), edit segment
        Set:
            "Segment name" to something useful
            Select "32-bit segment"
    Options->general
        Tab: Analysis
        Reanalyze program

    Any code that's left, you can fiddle with using Create Function (p)
    or Convert to Code (c). 


    =============
    = FUNCTIONS =
    =============
    sub_19037450 -- unknown simple crypto function [fully reversed]
    sub_19001020 -- unknown simple crypto function [fully reversed]

    ----------------------------
    ValidateSignature @ 19033240
    ----------------------------
    Cryptographically verifies a decrypted module, using signature_power and signature_mod 
    (below). 

    ----------------------------
    zlib_test_deflate @ 19037830
    ----------------------------
    Code that's directly ripped from the zlib 1.1.4 library. It's a potentially-vulnerable
    function that uncompresses the given buffer. 

    ------------------------------
    prepare_loaded_code @ 19018410
    ------------------------------
    This is a pretty long, nasty function. It takes newly uncompressed code with specific
    header data, copies it to a temporary buffer, and does the following:
    * Spaces out some sections
    * Fixes absolute references by adding the base address of the code
    * Loads requires libraries, and maps function calls within those libraries
    * Changes the protection type on the memory (ie, to make it executable)
    * Flushes the cache to make sure it's actually updated

    ---------------------------------
    DecryptCodeFromBNCache @ 19033680
    ---------------------------------
    * Passed the module version number and the decryption string as parameters
    * Checks if a constant verion number is being used, if so, extract it 
      from a static array (never happens)
    * Is called twice/login if BNCache isn't present:
      -> From 19033750 initially, where it discovers the file isn't cached
      -> From 19033680 after it's cached
      

    =============
    = VARIABLES =
    =============

    --------------------------
    signature_power @ 1903D3E0 [0x00, 0x01, 0x00, 0x01]
    signature_mod   @ 1903D2E0 [0x6B, 0xCE, 0xF5, 0x2D, 0x2A, 0x7D, 0x7A, 0x67, 0x21, 0x21, 0x84, 0xC9, 0xBC, 0x25, 0xC7, 0xBC, 0xDF, 0x3D, 0x8F, 0xD9, 0x47, 0xBC, 0x45, 0x48, 0x8B, 0x22, 0x85, 0x3B, 0xC5, 0xC1, 0xF4, 0xF5, 0x3C, 0x0C, 0x49, 0xBB, 0x56, 0xE0, 0x3D, 0xBC, 0xA2, 0xD2, 0x35, 0xC1, 0xF0, 0x74, 0x2E, 0x15, 0x5A, 0x06, 0x8A, 0x68, 0x01, 0x9E, 0x60, 0x17, 0x70, 0x8B, 0xBD, 0xF8, 0xD5, 0xF9, 0x3A, 0xD3, 0x25, 0xB2, 0x66, 0x92, 0xBA, 0x43, 0x8A, 0x81, 0x52, 0x0F, 0x64, 0x98, 0xFF, 0x60, 0x37, 0xAF, 0xB4, 0x11, 0x8C, 0xF9, 0x2E, 0xC5, 0xEE, 0xCA, 0xB4, 0x41, 0x60, 0x3C, 0x7D, 0x02, 0xAF, 0xA1, 0x2B, 0x9B, 0x22, 0x4B, 0x3B, 0xFC, 0xD2, 0x5D, 0x73, 0xE9, 0x29, 0x34, 0x91, 0x85, 0x93, 0x4C, 0xBE, 0xBE, 0x73, 0xA9, 0xD2, 0x3B, 0x27, 0x7A, 0x47, 0x76, 0xEC, 0xB0, 0x28, 0xC9, 0xC1, 0xDA, 0xEE, 0xAA, 0xB3, 0x96, 0x9C, 0x1E, 0xF5, 0x6B, 0xF6, 0x64, 0xD8, 0x94, 0x2E, 0xF1, 0xF7, 0x14, 0x5F, 0xA0, 0xF1, 0xA3, 0xB9, 0xB1, 0xAA, 0x58, 0x97, 0xDC, 0x09, 0x17, 0x0C, 0x04, 0xD3, 0x8E, 0x02 ,0x2C, 0x83, 0x8A, 0xD6, 0xAF, 0x7C, 0xFE, 0x83, 0x33, 0xC6, 0xA8, 0xC3, 0x84, 0xEF, 0x29, 0x06, 0xA9, 0xB7, 0x2D, 0x06, 0x0B, 0x0D, 0x6F, 0x70, 0x9E, 0x34, 0xA6, 0xC7, 0x31, 0xBE, 0x56, 0xDE, 0xDD, 0x02, 0x92, 0xF8, 0xA0, 0x58, 0x0B, 0xFC, 0xFA, 0xBA, 0x49, 0xB4, 0x48, 0xDB, 0xEC, 0x25, 0xF3, 0x18, 0x8F, 0x2D, 0xB3, 0xC0, 0xB8, 0xDD, 0xBC, 0xD6, 0xAA, 0xA6, 0xDB, 0x6F, 0x7D, 0x7D, 0x25, 0xA6, 0xCD, 0x39, 0x6D, 0xDA, 0x76, 0x0C, 0x79, 0xBF, 0x48, 0x25, 0xFC, 0x2D, 0xC5, 0xFA, 0x53, 0x9B, 0x4D, 0x60, 0xF4, 0xEF, 0xC7, 0xEA, 0xAC, 0xA1, 0x7B, 0x03, 0xF4, 0xAF, 0xC7]


    --------------------------
    Used to cryptographically verify a decrypted module. Both are constant values. 

    ---------------------------------------
    WardenUnknownPointer1_source @ 1904560C
    ---------------------------------------
    This variable is checked by a function during login and then again whenever the SID_WARDEN 
    handler finishes. If it has changed, the current module is unloaded and the new one is loaded
    and moved to WardenUnknownPointer1. 

    ----------------------------------
    WardenUnknownPointer1 @ 0x19045608
    ----------------------------------
    I know exactly what this does now, but I've used this name in so many places that I can't 
    really replace it now. 

    Basically, it's a dynamic code object. It is initialized with an array of encrypted code
    and a key. The code is decrypted and uncompressed, then stored. The libraries required
    by the code are loaded and the absolute addresses are updated. Pointers to the standard
    exported are kept in here as well. 


     -> Created at 0x19033582, 0x24 bytes
     +0x00
       * Allocated @ 1901845B
       * Stores decrypted/uncompressed code
        * [+0x1000] start of actual executable code
     +0x04
       * Size of the allocated data (originally read from the first 4 bytes of uncompressed code)
     +0x08
       * The number of DLL libraries that have been loaded
     +0x0c
       * Is a pointer to WardenFunctionList (defined below)
       * Saved at 19032EB4
       * Initialized at 0x02E32460, which is in Warden's initialize function (see +0x10 below):
        * 0x214 bytes of memory allocated
        * [+0x00] => ptrWardenFunctionsBuiltin @ 0x2e33000 (a constant)
        * [+0x04] => ptrWardenFunctionsBattle
     +0x10 
       * Pointer to Warden's initialize function
       * Initialize function returns the function pointers stored in +0x0c
       * Set @ 19033620
     +0x14
       * Gets set to the length of the data, rounded up to power of 2
     +0x18
       * Gets set to the length of the data (possibly accounts for multiple packets)
     +0x1c
       * Contains pointer to allocated memory
     +0x20
       * Occasionally set to 0x100 (?)
     
    --------------------------------------------
    WardenFunctionList @ WardenUnknownPtr1[0x10]
    --------------------------------------------
    Contains 0x224 bytes of allocated memory, allocated @ 0x02E3246A

     +0x00
       * Contains dword_2E33000, which has pointers to some static functions
        * +0x00: int __stdcall Maive_InitializeRandomData(int ptrSeedData,int seed_length) [2e32893]
        * +0x04: sub_2E32416 [2e32416]
        * +0x08: int __stdcall Maive_HandleWardenPacket(int PacketData,int Length,int ptrOriginalData) [2e326f6]
        * +0x0c: nullsub_4 [2e32413]            
     +0x04
       * Contains a *pointer* to WardenFunctionsBattle, which contains this list:
        * +0x00: int __stdcall DoSendWardenResponse(int buffer,int length)
        * +0x04: int __stdcall DoDecryptWardenModule(int ModuleNumber,int KeyString)
        * +0x08: int __stdcall DoWriteModuleToCache(int ModuleNumber,LPCVOID module,DWORD nNumberOfBytesToWrite)
        * +0x0c: int __stdcall DoMallocWrapper(int amount)
        * +0x10: int __stdcall DoFreeWrapper(int mem)
        * +0x14: int __stdcall DoCopyDataToVariable(void *src,int amount) ; Copies _amount_ bytes from _src_ to some newly allocated memory, stored in a global variable
        * +0x18: int __stdcall DoRetrieveDataFromVariable(void *dest,int ptr_max_length)
      +0x08
        * Set to allocated memory (WardenDownloadState) (size of module +0x80 extra bytes for header):
            * +0x00: Warden module number
            * +0x10: Warden decryption key
            * +0x20: MD5_CTX
            * +0x78: Length
            * +0x7C: Position
      +0x0c - 0x10d
        * Contains some not-very-random data (is all based on the 4-byte cdkey key, so not only is it public, but it can be 
          bruteforced easily -- used to encrypt outgoing packets
      +0x10e - 0x20F
        * Contains some more not-very-random data -- used to decrypt incoming packets
      +0x210
        * Initialized to 0x00
        * Increased by the number of bytes of data (starting at 0x10e) that are used in the incoming packets

    ------------------
    random_data_source
    ------------------
    * Passed to get_random_bytes (0x02E310E1)
    * First 4 bytes are a count, the current byte that is being pointed to (0 - 0x14)
    * After the 15th byte is read, the data is re-SHA1ed and the counter is reset to 0
        * The re-SHA1 SHA1s the following offsets, then stores it in 0x04 - 0x17:
            * 0x18 - 0x2B
            * 0x04 - 0x17
            * 0x2c - 0x3F
     [0x00 - 0x03] Current position
     [0x04 - 0x17] SHA1ed data
     [0x18 - 0x2B] Is equal to the value of the first two bytes of the CDKey hash, SHA1ed
     [0x2C - 0x3F] Is equal to the value of the third and fourth bytes of the CDKey hash, SHA1ed
