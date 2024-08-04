---
title: 'Wiki: Warden Packets'
author: ron
layout: wiki
permalink: "/wiki/Warden_Packets"
date: '2024-08-04T15:51:38-04:00'
---

This is about how to encrypt/decrypt the Warden packets, and what they mean.

## Generating encryption keys {#generating_encryption_keys}

Generating the keys used for encrypting Warden packets is a somewhat convoluted algorithm, but it is fairly simple to implement. Here are the basic steps:

1.  Create a source of shared random data based on a seed
2.  Generate the outgoing key from the first 0x10 bytes, using the generation code in [Crypto_and_Hashing#Xor_Encryption](Crypto_and_Hashing#Xor_Encryption "wikilink")
3.  Generate the incoming key from the next 0x10 bytes using that code

The random source is basically a struct with 4 fields, which are initialized as such:

-   Current position \[0x04 bytes\]: 0
-   Data 1 \[0x14 bytes\]: 00 00 00 \....
-   Data 2 \[0x14 bytes\]: WardenSHA1(first half of seed)
-   Data 3 \[0x14 bytes\]: WardenSHA1(second half of seed)

\"Data 1\" is read one byte at a time, and Current position is incremented. Immediately after being created, and when Current position reaches 0x14, an update is performed:

-   Current position = 0
-   Data 1 = SHA1(Data 2, Data 1, Data 3)
-   Data 2 and Data 3 aren\'t changed

That\'s it! All that\'s left is to read 0x10 bytes, generate the outgoing key (using the key generation function in [Crypto_and_Hashing#Xor_Encryption](Crypto_and_Hashing#Xor_Encryption "wikilink")), read 0x10 more bytes, and generate the incoming key.

Here is the code [in C](Key_Generation_in_C "wikilink") and [in Java](Key_Generation_in_Java "wikilink").

### The Key {#the_key}

On Starcraft, the first 4 bytes of the CDKey hash are used. That\'s the actual CDKey hash that\'s sent over the wire as part of SID_AUTH_CHECK.

On Diablo 2, the 4-byte GameHash value is used.

Other clients are currently unknown (to me).

## Packet Codes {#packet_codes}

The packet structure for Warden is very simple. The received packets, once decrypted, are in the form: \[1 byte\] code (0, 1, or 2) \[array\] data

And the response is usually a single encrypted byte, either 0 (for \"fail\") or 1 (for \"success\"). The exception is the response to the 0x02 packet.

### 0x00

0x00 is a request sent from the server asking if you have the current warden module. It is in the following form:

-   \[1 byte\] code (0)
-   \[16 bytes\] name of the current module
-   \[16 bytes\] decryption key for the current module
-   \[4 bytes\] length of the current module

A response of 0 will tell Battle.net to send you the current module, and you\'ll receive a slew of 0x01 packets. 1 will tell Battle.net you already have the module, and you\'ll receive a 0x02 packet.

#### Example

-   Server
    -   00 a2 d4 d6 4c 46 8e 56 4f 42 c6 s4 68 e4 5d 6a 46 5f 46 b4 5c 24 d5 46 e4 56 a6 4d 75 2d 21 f8 79 05 0b 00 00
-   Client
    -   00

### 0x01

0x01 packets have the form:

-   \[1 byte\] code (0x01)
-   \[2 bytes\] length (without the 3-byte header)
-   \[array\] data

You will receive many 0x01 packets, until the total length of \"data\" received is equal to the length sent in packet 0x00.

After the packet is received, it\'s validated (see [Warden Modules](Warden_Modules "wikilink")). If it was received without error, a response of 1 (encrypted) is sent. If there\'s an error, 0 (encrypted) is sent.

### 0x02

This packet is a request to validate the running game to verify it\'s legit.

I haven\'t reversed it yet, and don\'t plan to in the near future.

### 0x03

This packet is used to initialize functions to read information from the MPQ files.

0x03 packets have the form:

-   \[1 byte\] code (0x03)
-   \[2 bytes\] length (without the 7-byte header)
-   \[4 bytes\] checksum of the packet data (the checksum does not include the header)
-   \[1 byte\] Unknown flag (this has to be 1 otherwise Warden will exit the initialize function)
-   \[1 byte\] Unknown flag (usually 0)
-   \[1 byte\] Unknown flag (usually 1)
-   \[nullstring\] Library Name
-   \[4 bytes\] function offset #1
-   \[4 bytes\] function offset #2
-   \[4 bytes\] function offset #3
-   \[4 bytes\] function offset #4

### Packet Checksums {#packet_checksums}

Warden uses a modified version of the SHA1 algo and Xor\'s the result of it.

Warden_SHA1 can be found here: [SHA1_in_C](SHA1_in_C "wikilink")

        DWORD dwBuffer[5], DWORD dwHash;
        warden_sha1_hash(dwBuffer, (CHAR*)bPacket, sizeof(bPacket));
        for(INT i = 0; i < 5; i++)
            dwHash = dwBuffer[i] ^ dwHash;
