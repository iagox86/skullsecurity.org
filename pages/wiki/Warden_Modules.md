---
title: 'Wiki: Warden Modules'
author: ron
layout: wiki
permalink: "/wiki/Warden_Modules"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Warden_Modules"
---

Warden modules are received in a series of 0x01 packets, and processed in a variety of different steps.

## Initial Validation {#initial_validation}

After the entire module has been received up to the length specified in the 0x00 packet, a standard MD5 is calculated. The result is compared to the name of the module, which was also sent in 0x00. If they match, the module is processed and a response of 1 (encrypted) is sent back to the server. If the module doesn\'t match, a response of 0 (encrypted) is sent back to the server. The server then tries to send the module again (series of 0x01 packets).

## Decryption

After verifying the MD5, the packet is decrypted using the simple xor encryption algorithm defined here: [Crypto_and_Hashing#Xor_Encryption](Crypto_and_Hashing#Xor_Encryption "wikilink"). The key used for decryption was sent in the 0x00 packet.

## Second Validation {#second_validation}

After decryption, the module is in this form:\
\[4 bytes\] \-- length of uncompressed data\
\[size - 0x108 bytes\] \-- data\
\[0x04 bytes\] \-- An integer representing \"SIGN\" (or the string \"NGIS\")\
\[0x100 bytes\] \-- A cryptographic signature\
The \"SIGN\" string is checked first, and is a simple string match.

The signature is checked next.

### RSA Signature {#rsa_signature}

The signature is checked using RSA with the algorithm defined in [Crypto_and_Hashing#RSA](Crypto_and_Hashing#RSA "wikilink") with the following variables:

-   c =\> the 0x100 byte signature
-   d =\> a constant 4-byte value { 0x01, 0x00, 0x01, 0x00 }
-   n =\> a constant 256-byte value { 0x6B, 0xCE, 0xF5, 0x2D, 0x2A, 0x7D, 0x7A, 0x67, 0x21, 0x21, 0x84, 0xC9, 0xBC, 0x25, 0xC7, 0xBC, 0xDF, 0x3D, 0x8F, 0xD9, 0x47, 0xBC, 0x45, 0x48, 0x8B, 0x22, 0x85, 0x3B, 0xC5, 0xC1, 0xF4, 0xF5, 0x3C, 0x0C, 0x49, 0xBB, 0x56, 0xE0, 0x3D, 0xBC, 0xA2, 0xD2, 0x35, 0xC1, 0xF0, 0x74, 0x2E, 0x15, 0x5A, 0x06, 0x8A, 0x68, 0x01, 0x9E, 0x60, 0x17, 0x70, 0x8B, 0xBD, 0xF8, 0xD5, 0xF9, 0x3A, 0xD3, 0x25, 0xB2, 0x66, 0x92, 0xBA, 0x43, 0x8A, 0x81, 0x52, 0x0F, 0x64, 0x98, 0xFF, 0x60, 0x37, 0xAF, 0xB4, 0x11, 0x8C, 0xF9, 0x2E, 0xC5, 0xEE, 0xCA, 0xB4, 0x41, 0x60, 0x3C, 0x7D, 0x02, 0xAF, 0xA1, 0x2B, 0x9B, 0x22, 0x4B, 0x3B, 0xFC, 0xD2, 0x5D, 0x73, 0xE9, 0x29, 0x34, 0x91, 0x85, 0x93, 0x4C, 0xBE, 0xBE, 0x73, 0xA9, 0xD2, 0x3B, 0x27, 0x7A, 0x47, 0x76, 0xEC, 0xB0, 0x28, 0xC9, 0xC1, 0xDA, 0xEE, 0xAA, 0xB3, 0x96, 0x9C, 0x1E, 0xF5, 0x6B, 0xF6, 0x64, 0xD8, 0x94, 0x2E, 0xF1, 0xF7, 0x14, 0x5F, 0xA0, 0xF1, 0xA3, 0xB9, 0xB1, 0xAA, 0x58, 0x97, 0xDC, 0x09, 0x17, 0x0C, 0x04, 0xD3, 0x8E, 0x02, 0x2C, 0x83, 0x8A, 0xD6, 0xAF, 0x7C, 0xFE, 0x83, 0x33, 0xC6, 0xA8, 0xC3, 0x84, 0xEF, 0x29, 0x06, 0xA9, 0xB7, 0x2D, 0x06, 0x0B, 0x0D, 0x6F, 0x70, 0x9E, 0x34, 0xA6, 0xC7, 0x31, 0xBE, 0x56, 0xDE, 0xDD, 0x02, 0x92, 0xF8, 0xA0, 0x58, 0x0B, 0xFC, 0xFA, 0xBA, 0x49, 0xB4, 0x48, 0xDB, 0xEC, 0x25, 0xF3, 0x18, 0x8F, 0x2D, 0xB3, 0xC0, 0xB8, 0xDD, 0xBC, 0xD6, 0xAA, 0xA6, 0xDB, 0x6F, 0x7D, 0x7D, 0x25, 0xA6, 0xCD, 0x39, 0x6D, 0xDA, 0x76, 0x0C, 0x79, 0xBF, 0x48, 0x25, 0xFC, 0x2D, 0xC5, 0xFA, 0x53, 0x9B, 0x4D, 0x60, 0xF4, 0xEF, 0xC7, 0xEA, 0xAC, 0xA1, 0x7B, 0x03, 0xF4, 0xAF, 0xC7 }

The output is the result of an SHA1, hashing the module and a static string, padded with 0xBB values to the proper length:

-   checksum = StandardSHA1(data \[including length\] without signature, \"MAIEV.MOD\")

Here\'s the validation code in Java:

        private static boolean verifySignature(byte []signature, byte []data, String keyString) throws Exception /* TODO: Fix */
        {
            BigIntegerEx power = new BigIntegerEx(BigIntegerEx.LITTLE_ENDIAN, new byte[]{ 0x01, 0x00, 0x01, 0x00 });
            BigIntegerEx mod   = new BigIntegerEx(BigIntegerEx.LITTLE_ENDIAN, new byte[] { (byte)0x6B, (byte)0xCE, (byte)0xF5, (byte)0x2D, (byte)0x2A, (byte)0x7D, (byte)0x7A, (byte)0x67, (byte)0x21, (byte)0x21, (byte)0x84, (byte)0xC9, (byte)0xBC, (byte)0x25, (byte)0xC7, (byte)0xBC, (byte)0xDF, (byte)0x3D, (byte)0x8F, (byte)0xD9, (byte)0x47, (byte)0xBC, (byte)0x45, (byte)0x48, (byte)0x8B, (byte)0x22, (byte)0x85, (byte)0x3B, (byte)0xC5, (byte)0xC1, (byte)0xF4, (byte)0xF5,  (byte)0x3C, (byte)0x0C, (byte)0x49, (byte)0xBB, (byte)0x56, (byte)0xE0, (byte)0x3D, (byte)0xBC, (byte)0xA2, (byte)0xD2, (byte)0x35, (byte)0xC1, (byte)0xF0, (byte)0x74, (byte)0x2E, (byte)0x15, (byte)0x5A, (byte)0x06, (byte)0x8A, (byte)0x68, (byte)0x01, (byte)0x9E, (byte)0x60, (byte)0x17, (byte)0x70, (byte)0x8B, (byte)0xBD, (byte)0xF8, (byte)0xD5, (byte)0xF9, (byte)0x3A, (byte)0xD3, (byte)0x25, (byte)0xB2, (byte)0x66, (byte)0x92, (byte)0xBA, (byte)0x43, (byte)0x8A, (byte)0x81, (byte)0x52, (byte)0x0F, (byte)0x64, (byte)0x98, (byte)0xFF, (byte)0x60, (byte)0x37, (byte)0xAF, (byte)0xB4, (byte)0x11, (byte)0x8C, (byte)0xF9, (byte)0x2E, (byte)0xC5, (byte)0xEE, (byte)0xCA, (byte)0xB4, (byte)0x41, (byte)0x60, (byte)0x3C, (byte)0x7D, (byte)0x02, (byte)0xAF, (byte)0xA1, (byte)0x2B, (byte)0x9B, (byte)0x22, (byte)0x4B, (byte)0x3B, (byte)0xFC, (byte)0xD2, (byte)0x5D, (byte)0x73, (byte)0xE9, (byte)0x29, (byte)0x34, (byte)0x91, (byte)0x85, (byte)0x93, (byte)0x4C, (byte)0xBE, (byte)0xBE, (byte)0x73, (byte)0xA9, (byte)0xD2, (byte)0x3B, (byte)0x27, (byte)0x7A, (byte)0x47, (byte)0x76, (byte)0xEC, (byte)0xB0, (byte)0x28, (byte)0xC9, (byte)0xC1, (byte)0xDA, (byte)0xEE, (byte)0xAA, (byte)0xB3, (byte)0x96, (byte)0x9C, (byte)0x1E, (byte)0xF5, (byte)0x6B, (byte)0xF6, (byte)0x64, (byte)0xD8, (byte)0x94, (byte)0x2E, (byte)0xF1, (byte)0xF7, (byte)0x14, (byte)0x5F, (byte)0xA0, (byte)0xF1, (byte)0xA3, (byte)0xB9, (byte)0xB1, (byte)0xAA, (byte)0x58, (byte)0x97, (byte)0xDC, (byte)0x09, (byte)0x17, (byte)0x0C, (byte)0x04, (byte)0xD3, (byte)0x8E, (byte)0x02, (byte)0x2C, (byte)0x83, (byte)0x8A, (byte)0xD6, (byte)0xAF, (byte)0x7C, (byte)0xFE, (byte)0x83, (byte)0x33, (byte)0xC6, (byte)0xA8, (byte)0xC3, (byte)0x84, (byte)0xEF, (byte)0x29, (byte)0x06, (byte)0xA9, (byte)0xB7, (byte)0x2D, (byte)0x06, (byte)0x0B, (byte)0x0D, (byte)0x6F, (byte)0x70, (byte)0x9E, (byte)0x34, (byte)0xA6, (byte)0xC7, (byte)0x31, (byte)0xBE, (byte)0x56, (byte)0xDE, (byte)0xDD, (byte)0x02, (byte)0x92, (byte)0xF8, (byte)0xA0, (byte)0x58, (byte)0x0B, (byte)0xFC, (byte)0xFA, (byte)0xBA, (byte)0x49, (byte)0xB4, (byte)0x48, (byte)0xDB, (byte)0xEC, (byte)0x25, (byte)0xF3, (byte)0x18, (byte)0x8F, (byte)0x2D, (byte)0xB3, (byte)0xC0, (byte)0xB8, (byte)0xDD, (byte)0xBC, (byte)0xD6, (byte)0xAA, (byte)0xA6, (byte)0xDB, (byte)0x6F, (byte)0x7D, (byte)0x7D, (byte)0x25, (byte)0xA6, (byte)0xCD, (byte)0x39, (byte)0x6D, (byte)0xDA, (byte)0x76, (byte)0x0C, (byte)0x79, (byte)0xBF, (byte)0x48, (byte)0x25, (byte)0xFC, (byte)0x2D, (byte)0xC5, (byte)0xFA, (byte)0x53, (byte)0x9B, (byte)0x4D, (byte)0x60, (byte)0xF4, (byte)0xEF, (byte)0xC7, (byte)0xEA, (byte)0xAC, (byte)0xA1, (byte)0x7B, (byte)0x03, (byte)0xF4, (byte)0xAF, (byte)0xC7 });
            
            byte []result = new BigIntegerEx(BigIntegerEx.LITTLE_ENDIAN, signature).modPow(power, mod).toByteArray();
            
            byte []digest;
            byte []properResult = new byte[0x100];
           
            /* Fill the proper result with 0xBB */
            for(int i = 0; i < properResult.length; i++)
                properResult[i] = (byte)0xBB;
            
            /* Do a SHA1 of the data and the string (for some reason). */
            MessageDigest md = MessageDigest.getInstance("SHA1");
            md.update(data);
            md.update(keyString.toUpperCase().getBytes());
            digest = md.digest();
            
            /* Copy the digest over the proper result. */
            System.arraycopy(digest, 0, properResult, 0, digest.length);
           
            /* Finally, check the array against the signature. */
            for(int i = 0; i < result.length; i++)
                if(result[i] != properResult[i])
                    return false;
            
            return true;
        }
        

## Decompression

The \"data\" part of that decrypted data is then run through zlib\'s \"inflate\" function, as I mentioned here: [Crypto_and_Hashing#Inflate](Crypto_and_Hashing#Inflate "wikilink").

## Preperation

The final way in which the data is modified is when it\'s prepared for being loaded. I have reversed this code, although I haven\'t spent time to figure out how it actually works. What essentially happens is that the uncompressed code is copied to a new buffer, absolute addresses are updated, required modules are loaded (kernel32.dll and user.dll, for example), and function calls to those modules are mapped properly.

The decompressed code is in what seem to be a standard form these days:

-   \[4 bytes\] size of final code
-   \[array\] data

I will demonstrate how to prepare this through Java code (I haven\'t written C code for it) (requires [IntFromByteArray](IntFromByteArray "wikilink")):

       private static byte []prepareModule(byte []original, int base_address)
        {
            IntFromByteArray ifba = IntFromByteArray.LITTLEENDIAN;
            int counter;
            
            int length = ifba.getInteger(original, 0);
            byte []module = new byte[length];
            
            System.out.printf("Allocated %d (0x%x) bytes for new module.\n\n", length, length);
            
            /* Copy 40 bytes from the original module to the new one. */
            System.arraycopy(original, 0, module, 0, 40);
            
            int source_location = 0x28 + (ifba.getInteger(module, 0x24)*12);
            int destination_location = ifba.getInteger(original, 0x28);
            int limit = ifba.getInteger(original, 0);
            
            boolean skip = false;
            
            System.out.println("Copying code sections to module.");
            while(destination_location < limit)
            {
                int count = ((original[source_location] & 0x0FF) << 0) | 
                            ((original[source_location + 1] & 0x0FF) << 8);
                
                source_location += 2;
                
                if(!skip)
                {
                    System.arraycopy(original, source_location, module, destination_location, count);
                    source_location += count;
                }           
                skip = !skip;
                destination_location += count;
            }

            System.out.println("Adjusting references to global variables...");
            source_location = ifba.getInteger(original, 8);
            destination_location = 0;

            counter = 0;
            while(counter < ifba.getInteger(module, 0x0c))
            {
                if(module[source_location] < 0)
                {
                    /* This code is never used, so I am not 100% sure that it works. */
                    destination_location =   
                            ((module[source_location + 0] & 0x07F) << 24) |
                            ((module[source_location + 1] & 0x0FF) << 16) |
                            ((module[source_location + 2] & 0x0FF) << 8)  |
                            ((module[source_location + 3] & 0x0FF) << 0);
                    
                    source_location += 4;
                }
                else
                {
                    destination_location = destination_location + (module[source_location + 1] & 0x0FF) + (module[source_location] << 8);
                    
                    source_location += 2;
                }
                
    //          System.out.printf("Offset %04x (was %08x)\n", edx, ifba.getInteger(module, edx));
                ifba.insertInteger(module, destination_location, ifba.getInteger(module, destination_location) + base_address);
                counter++;
            }
            
            
            System.out.println("Updating API library references...");
            counter = 0;
            limit = ifba.getInteger(module, 0x20);
            String library;
            
            for(counter = 0; counter < limit; counter++)
            {
                int proc_start = ifba.getInteger(module, 0x1c) + (counter * 8);
                
                library = WardenModule.getNTString(module, ifba.getInteger(module, proc_start));
                
                int proc_offset = ifba.getInteger(module, proc_start + 4);
                
                while(ifba.getInteger(module, proc_offset) != 0)
                {
                    int proc = ifba.getInteger(module, proc_offset);
                    int addr = Modules.ERROR;
                    
                    if(proc > 0)
                    {
                        String strProc = WardenModule.getNTString(module, proc);
                        addr = Modules.get(library, strProc);
                        
                        if(addr != Modules.ERROR)
                            System.out.printf("Module %s!%s found @ 0x%08x\n", library, strProc, addr);
                    }
                    else
                    {
                        proc = proc & 0x7FFFFFFF;
                        System.out.printf("Proc: ord(0x%x)\n", proc);
                    }
                    ifba.insertInteger(module, proc_offset, addr); /* TODO: Fix this. */
                    /* Note: real code increments [ebx+8] here, which is used for unloading the libraries. */
                    
                    proc_offset += 4;
                }
            }
            
            return module;
        }

C Version, converted by Matt.

    DWORD getInteger(BYTE* pArray, DWORD dwLocation)
    {
        return *(DWORD*)&pArray[dwLocation];
    }

    VOID insertInteger(BYTE* pArray, DWORD dwLocation, DWORD dwValue)
    {
        *(DWORD*)&pArray[dwLocation] = dwValue;
    }

    //http://www.skullsecurity.org/wiki/index.php/Warden_Modules#Preperation
    //this is the implementation from iago in C
    BYTE* PrepareModule(BYTE* pModule)
    {
        DWORD dwModuleSize = getInteger(pModule, 0);
        BYTE* pNewModule = (BYTE*)malloc(dwModuleSize);

        printf("Allocated %d (0x%x) bytes for new module.\n", dwModuleSize, dwModuleSize);

        /* Copy 40 bytes from the original module to the new one. */
        memcpy(pNewModule, pModule, 40);

        DWORD dwSrcLocation = 0x28 + (getInteger(pNewModule, 0x24)*12);
        DWORD dwDestLocation = getInteger(pModule, 0x28);
        DWORD dwLimit = getInteger(pModule, 0);

        BOOL bSkip = FALSE;

        printf("Copying code sections to module.\n");

        while(dwDestLocation < dwLimit)
        {
            DWORD dwCount = ((pModule[dwSrcLocation] & 0x0FF) << 0) |
                                ((pModule[dwSrcLocation + 1] & 0x0FF) << 8);

            dwSrcLocation += 2;

            if(!bSkip)
            {
                memcpy(pNewModule + dwDestLocation, pModule + dwSrcLocation, dwCount);
                dwSrcLocation += dwCount;
            }

            bSkip = !bSkip;
            dwDestLocation += dwCount;
        }
        
        printf("Adjusting references to global variables...\n");
        dwSrcLocation = getInteger(pModule, 8);
        dwDestLocation = 0;

        INT nCounter = NULL;

        while(nCounter < getInteger(pNewModule, 0x0C))
        {
            if(pNewModule[dwSrcLocation] < 0)
            {
                dwDestLocation =   
                        ((pNewModule[dwSrcLocation + 0] & 0x07F) << 24) |
                        ((pNewModule[dwSrcLocation + 1] & 0x0FF) << 16) |
                        ((pNewModule[dwSrcLocation + 2] & 0x0FF) << 8)  |
                        ((pNewModule[dwSrcLocation + 3] & 0x0FF) << 0);

                dwSrcLocation += 4;
            }
            else {
                dwDestLocation = dwDestLocation + (pNewModule[dwSrcLocation +1] & 0x0FF) + (pNewModule[dwSrcLocation] << 8);

                dwSrcLocation += 2;
            }
            
            
            insertInteger(pNewModule, dwDestLocation, getInteger(pNewModule, dwDestLocation) + (DWORD)pNewModule);
            nCounter++;
        }

        printf("Updating API library references...\n");

        dwLimit = getInteger(pNewModule, 0x20);

        for(nCounter = 0; nCounter < dwLimit; nCounter++)
        {
            DWORD dwProcStart = getInteger(pNewModule, 0x1C) + (nCounter*8);
            CHAR* szLib = (CHAR*)pNewModule + getInteger(pNewModule, dwProcStart);
            DWORD dwProcOffset = getInteger(pNewModule, dwProcStart + 4);

            printf("Lib: %s\n", szLib);

            HMODULE hModule = LoadLibrary(szLib);

            while(getInteger(pNewModule, dwProcOffset))
            {
                DWORD dwProc = getInteger(pNewModule, dwProcOffset);

                if(dwProc > 0)
                {
                    CHAR* szFunc = (CHAR*)pNewModule + dwProc;
                    printf("\tFunction: %s\n", szFunc);

                    insertInteger(pNewModule, dwProcOffset, (DWORD)GetProcAddress(hModule, szFunc));
                }
                else
                {
                    dwProc = dwProc & 0x7FFFFFFF;
                    printf("\tOrdinary: 0x%x\n", dwProc);
                }

                dwProcOffset += 4;
            }
        }

        return pNewModule;
    }

## Initialization Function {#initialization_function}

Once the module is loaded, an initialization function within it is called. I\'ll show you how to get the pointer to the function and how to call it.

    typedef WardenFuncList** (__fastcall *fnInitializeModule)(DWORD* lpPtr2Table);

    WardenFuncList** InitializeWarden(BYTE* pModule)
    {
        DWORD ECX, EDX, EBP;

        EBP = getInteger(pModule, 0x18);
        EDX = 1 - EBP;

        if(EDX > getInteger(pModule, 0x14))
            return FALSE;

        ECX = getInteger(pModule, 0x10); // offsetWardenSetup
        ECX = getInteger(pModule, ECX + (EDX * 4)) + (DWORD)pModule;

        fnInitializeModule fpInitializeModule = (fnInitializeModule)ECX;

        memset(&aList, NULL, sizeof(FuncList));

        aList.fpSendPacket = mySendPacket;
        aList.fpCheckModule = myCheckModule;
        aList.fpLoadModule = myLoadModule;
        aList.fpAllocateMemory = myAllocateMemory;
        aList.fpReleaseMemory = myReleaseMemory;
        aList.fpSetRC4Data = mySetRC4Keys;
        aList.fpGetRC4Data = myGetRC4Keys;
        
        WardenFuncList** ppFuncList = fpInitializeModule(&dwTable);

        return ppFuncList;
    }

Warden imports some Diablo II/Starcraft/Warcraft 3 functions, this is the full list along with the type definitions:

    typedef VOID (__stdcall *fnSendPacket)(BYTE* pPacket, DWORD dwSize);
    typedef BOOL (__stdcall *fnCheckModule)(BYTE* pModName, DWORD _2);
    typedef WardenFuncList** (__stdcall *fnLoadModule)(BYTE* pRC4Key, BYTE* pModule, DWORD dwModSize);
    typedef LPVOID (__stdcall *fnAllocateMemory)(DWORD dwSize);
    typedef VOID (__stdcall *fnReleaseMemory)(LPVOID lpMemory);
    typedef VOID (__stdcall *fnSetRC4Data)(LPVOID lpKeys, DWORD dwSize);
    typedef DWORD (__stdcall *fnGetRC4Data)(LPVOID lpBuffer, LPDWORD dwSize);

    struct FuncList
    {
        fnSendPacket fpSendPacket; //0x00
        fnCheckModule fpCheckModule; //0x04
        fnLoadModule fpLoadModule; //0x08
        fnAllocateMemory fpAllocateMemory;//0xC
        fnReleaseMemory fpReleaseMemory;//0x10
        fnSetRC4Data fpSetRC4Data;//0x14
        fnGetRC4Data fpGetRC4Data;//0x18
    };

When you call the InitializeWarden function it returns a pointer to the pointer of the pointer to the expored function list. However, here is the struct and the type definitions:

    typedef VOID (__thiscall *fnGenerateRC4Keys)(WardenFuncList** ppFncList, LPVOID lpData, DWORD dwSize);
    typedef VOID (__thiscall *fnUnloadModule)(WardenFuncList** ppFncList);
    typedef VOID (__thiscall *fnPacketHandler)(WardenFuncList** ppFncList, BYTE* pPacket, DWORD dwSize, DWORD* dwBuffer);
    typedef VOID (__thiscall *fnTick)(WardenFuncList** ppFncList, DWORD _2); // _2 is sum dwOldTick - GetTickCount(); shit ..

    struct WardenFuncList
    {
        fnGenerateRC4Keys fpGenerateRC4Keys;//0x00
        fnUnloadModule fpUnload;//0x04 - Before it frees everything it will call FuncList:fpSetRC4Data and store the RC4 key
        fnPacketHandler fpPacketHandler;//0x8
        fnTick fpTick;//0xC
    };

## Warden and the 0x05 Packet {#warden_and_the_0x05_packet}

Once the 0x05 packet is received Warden generates new RC4 keys. To get ahold of these keys \...
