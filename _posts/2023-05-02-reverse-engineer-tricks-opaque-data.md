---
title: 'Reverse engineering tricks: identifying opaque network protocols'
author: ron
layout: post
categories:
- re
permalink: "/2023/reverse-engineering-tricks-identifying-opaque-network-protocols"
date: '2023-05-02T15:37:26-07:00'

---

Lately, I've been reverse engineering a reasonably complex network protocol, and I ran into a mystery - while the protocol is generally an unencrypted binary protocol, one of the messages was large and random. In an otherwise unencrypted protocol, why is one of the messages unreadable? It took me a few hours to accomplish what should have been a couple minutes of effort, and I wanted to share the trick I ultimately used!

I'm going to be intentionally vague on the software, and even modify a few things to make it harder to identify; I'll probably publish a lot more on my [work blog](https://blog.rapid7.com) once I'm finished this project!

<!--more-->

## Binary protocols

Let's take a look at the binary protocol! If you're familiar with protocols and just want to see the "good stuff", feel free to skip down to the next header.

A "binary protocol" is a network protocol that uses unprintable characters (as opposed to a protocol like HTTP, which is something you can type on your keyboard). Often, you'll use a tool like Wireshark to grab a sample of network traffic (a "packet capture", or "PCAP") and, if it's not encrypted, you can start drawing conclusions about what the client and server expect. In a PCAP, you might see requests / responses that look like this:

```
Outbound:

08 00 00 00 2c 00 00 00                            ....,... 

Inbound:

40 00 00 00 2c 00 00 00  55 53 52 53 05 00 00 00   @...,... USRS....
2c 00 00 00 02 00 00 00  55 38 f9 ed 21 59 47 f5   ,....... U8..!YG.
8f 9d 43 59 33 5c 2e 92  00 00 00 00 c4 54 f4 01   ..CY3\.. .....T..
8d b4 43 e7 9e 9f ea db  4e 76 1a 7a 00 00 00 00   ..C..... Nv.z....
```

I don't want to get too buried in the weeds on how this protocol actually works, but when you work with unknown binary protocols a lot, certain things start to stand out.

First, let's talk about [endianness](https://en.wikipedia.org/wiki/Endianness)! The way integers are encoded into protocols vary based on the protocol, but a very common way to encode a 4-byte (32-bit) number is either big endian (`8` => `00 00 00 08`) or little endian (`8` => `08 00 00 00`). There are historic reasons both exist, and both are common to see, but based on the structure of those messages, we can guess that the first 4 bytes are either a big-endian integer with the value 0x08000000 or a little-endian integer with the value 0x00000008. The latter seems more likely, because that would make a great length value; speaking of lengths...

Second, let's talk about TCP - TCP is a streaming protocol, which means there is no guarantee that if you send 100 bytes, the receiver will receive those 100 bytes all at once. You ARE guaranteed that if you received data, it'll be the correct bytes in the correct order; however, you might get 50 now and 50 later, or 99 now and 1 later, or maybe the next 50 bytes will be attached and you'll get 150 bytes all at once. As a result, TCP-based services nearly always encode a length value near the start, allowing protocols to unambiguously receive complete messages.

Because of all that, one of the first things I do when approaching a new protocol is try to identify the length field. In this case, you'll note that the packet that starts with 0x08 is 8 bytes long, and the packet that starts with 0x40 is 0x40 bytes long. That looks promising! And, as it turns out, is correct.

Once we have a length field, the next thing to consider is how the client and server multiplex messages. In an HTTP protocol, there's a URI, which tells the server where to direct the request. In a binary protocol, there isn't typically a free-form string like that; instead, you commonly see a "message id" field (or packet id, or any number of other names). Typically, these will be near the start of a message, and typically, the structure of the remainder of the message will be based on that value. So finding similar looking messages with the same identifier near the start is one way to identify the message id. Another way - not necessarily super reliable, mind you - is to look for a request and response that appear to go together and that have the same integer near the start; often, responses have the same message id as requests.  In the request/response above, the 0x2c value seems like a great candidate for a message id, and it is!

If you have access to the binary - and it'll be awfully hard to reverse an unknown protocol without one! - you can often validate that sort of guess by finding an enormous `switch` statement close to a `recv` - this is from disassembling the binary in IDA:

```
.text:00007FF77741B624 loc_7FF77741B624:                       ; CODE XREF: switches_msg_id+89↑j
.text:00007FF77741B624 mov     [rbp+50h+var_A0], r15
.text:00007FF77741B628 mov     [rbp+50h+var_98], 7
.text:00007FF77741B630 mov     word ptr [rbp+50h+str_adminsupport], r15w
.text:00007FF77741B635 mov     eax, [rsi+10h]
.text:00007FF77741B638 dec     eax                             ; switch 490 cases <-- 490 options!
.text:00007FF77741B63A cmp     eax, 1E9h
.text:00007FF77741B63F ja      def_7FF77741B65E                ; jumptable 00007FF77741B65E default case, cases 13-15,25,[.......way way way more.......]
.text:00007FF77741B645 lea     rcx, unk_7FF776FD0000
.text:00007FF77741B64C movzx   eax, ds:(byte_7FF77741D5EC - 7FF776FD0000h)[rcx+rax]
.text:00007FF77741B654 mov     edx, ds:(jpt_7FF77741B65E - 7FF776FD0000h)[rcx+rax*4]
.text:00007FF77741B65B add     rdx, rcx
.text:00007FF77741B65B ;   } // starts at 7FF77741B5E1
.text:00007FF77741B65E jmp     rdx                             ; switch jump
```

I used a debugger to put a breakpoint on that `switch` jump (at `00007FF77741B65E`), then replayed the initial 8-bit message message. When execution reached that `jmp`, it breaks into debug mode. I go to the next statement (ie, tell the program to perform the `jmp rdx` instruction), and wind up at this piece of code:

```
.text:00007FF77741BC23 loc_7FF77741BC23:                       ; CODE XREF: switches_msg_id+FE↑j
.text:00007FF77741BC23                                         ; DATA XREF: switches_msg_id:jpt_7FF77741B65E↓o
.text:00007FF77741BC23 mov     r9, r14                         ; jumptable 00007FF77741B65E case 44
.text:00007FF77741BC26 mov     r8, rsi
.text:00007FF77741BC29 mov     rdx, rdi
.text:00007FF77741BC2C mov     rcx, rbx
.text:00007FF77741BC2F call    sub_7FF777411F20                ; I believe this just returns the site_id
.text:00007FF77741BC34 jmp     loc_7FF77741D190
```

Case 44, in hex, is case 0x2c - the message id! That pretty much confirms the message id.

The rest of message 0x2c isn't super interesting - the response is an array of 20-byte identifiers that don't really matter. I chose it as an example because it's pretty short.

Now that we've talked a bit about reversing a protocol, let's look at the mystery!

## The mystery blob!

While working on this project, I noticed one packet that stands out: immediately after authenticating, the client sends an 8-byte request with id 0x0c, and the server responds with an enormous response (0x17ba bytes!) with the message type 0xff7f:

```
Outbound:

08 00 00 00 0c 00 00 00                            ........ 

Inbound:

ba 17 00 00 7f ff 00 00  78 9c ed 9c 07 78 14 d5   ........ x....x..
da c7 4f 68 4a a4 08 2a  8a 08 ac 41 ba 09 09 04   ..OhJ..* ...A....
08 a1 98 0e 01 52 c8 86  be 10 36 9b dd 64 c9 6e   .....R.. ..6..d.n
36 6c 09 04 01 47 34 08  88 02 a1 08 5e 01 95 26   6l...G4. ....^..&
20 52 04 11 01 11 09 58  10 50 04 41 b0 d1 91 22    R.....X .P.A..."
d2 94 26 f9 ce bc ff 9d  24 b3 99 4d a2 72 ef e3   ..&..... $..M.r..
77 ef 2c 4f f2 cb fb 9e  33 a7 cd 99 99 ff 79 f7   w.,O.... 3.....y.
30 f7 4c 64 ac 06 63 4c  db 5b 9b 7c 2f a7 0f ff   0.Ld..cL .[.|/...
b9 f8 02 63 df 16 16 16  46 b2 50 a6 63 89 cc ce   ...c.... F.P.c...
6c 2c 9d ff d6 33 2b 8b  e2 bf 9d fc 47 c7 ba 33   l,...3+. ....G..3
[.........]
```

My first (incorrect) instinct is that it's encrypted, which raises the obvious question: if it's encrypted, what *is* it??? It's gotta be pretty interesting if it's a gigantic, encrypted blob, right? That was my logic as I excitedly dove into the weeds!

So I set off to figure out what it actually is. The function that handles message 0x0c is large and complex. Some debugging revealed strings like "Default settings" and "all users" and stuff, which made me think it's configuration. Why would they encrypt configuration? Maybe it has passwords? Maybe this is exciting!

Unfortunately, it's C++, and it's a complex function. Like really complex. I could have spent a week reversing the whole thing, with all the objects involved, and I don't have time for that! Hoping for an easy victory (identifying what, exactly, is encrypted), I spent a couple hours tracing through the various interesting-looking function calls, looking for something that looks encryptiony to me. At one point I noticed code that looks like:

```
.text:00007FF7776FFEBA mov     rax, 4924924924924925h
.text:00007FF7776FFEC4 sub     rcx, [r14+10h]
.text:00007FF7776FFEC8 mov     r8d, 4
.text:00007FF7776FFECE imul    rcx
.text:00007FF7776FFED1 mov     rcx, [rdi]
.text:00007FF7776FFED4 sar     rdx, 4
.text:00007FF7776FFED8 mov     rax, rdx
.text:00007FF7776FFEDB shr     rax, 3Fh
.text:00007FF7776FFEDF add     rdx, rax
```

I googled the constant `0x4924924924924925` (I can do a whole other post about googling constants!), and found some [mentions of encryption](https://github.com/NationalSecurityAgency/ghidra/issues/1263), some [CTF challenges](https://1ce0ear.github.io/2017/09/14/ZCTF-Challenge-3/), stuff like that. It looked promising, but the code around it didn't feel like encryption to me - it kinda looked like it could be a hashtable. I didn't really know.

Eventually, at the bottom of one of the functions, I noticed an exception being thrown:

```
.text:00007FF7777000A2 loc_7FF7777000A2:                       ; CODE XREF: sub_7FF7776FFE80+70↑j
.text:00007FF7777000A2 lea     rcx, [rbp+pExceptionObject]
.text:00007FF7777000A6 call    sub_7FF77709D600
.text:00007FF7777000AB lea     rdx, __TI3?AVCArchiveException@io@Shared@@ ; pThrowInfo
.text:00007FF7777000B2 lea     rcx, [rbp+pExceptionObject]     ; pExceptionObject
.text:00007FF7777000B6 call    _CxxThrowException
```

`AVCArchiveException`? Wait, Archive? Does that mean....?

## Solving the mystery

As part of my normal process, I was building a client in Ruby, implementing the protocol as I go. Here's the code I used to generate message 0x0c with a blank body:

```rb
encrypted = send_recv(s, 0x0c, '')
```

I had tried different techniques to decrypt the response; since the size (0x17ba or 6074) isn't a multiple of 8 or 16, I knew it wasn't a block cipher. But I was otherwise stuck.

After seeing that exception, I realized that, what I *should* have done, was write the response to a file:

```rb
File.write("/tmp/test", encrypted)
```

Then use the Linux `file` command to tell me what the message actually was:

```
$ hexdump -C /tmp/test | head -n3
00000000  78 9c ed 9c 07 78 14 d5  da c7 4f 68 4a a4 08 2a  |x....x....OhJ..*|
00000010  8a 08 ac 41 ba 09 09 04  08 a1 98 0e 01 52 c8 86  |...A.........R..|
00000020  be 10 36 9b dd 64 c9 6e  36 6c 09 04 01 47 34 08  |..6..d.n6l...G4.|

$ file /tmp/test
/tmp/test: zlib compressed data
```

Zlib! It's compressed, not encrypted! D'oh!! I did a bit of reading, and realized that 0x78 (or "x") is the most character for a Zlib-compressed string to begin with, so that's something to remember!

Once you know it's Zlib, you can decompress it with a variety of tools, including `openssl`:

```
$ openssl zlib -d < /tmp/test | hexdump -C | head -n4
00000000  07 88 00 00 0c 00 00 00  53 4c 53 54 08 00 00 00  |........SLST....|
00000010  01 00 00 00 ef 87 00 00  d9 ff ff ff 43 00 3a 00  |............C.:.|
00000020  5c 00 50 00 72 00 6f 00  67 00 72 00 61 00 6d 00  |\.P.r.o.g.r.a.m.|
00000030  44 00 61 00 74 00 61 00  5c 00 61 00 62 00 63 00  |D.a.t.a.\.a.b.c.|
[...]
```

As you can see, it's now plaintext - it was never encrypted at all! Just compressed! The worst part is, this isn't even close to the first time I've run into this situation - I just got excited and wasn't thinking!

In the end, it turned out to be a big blob of settings - nothing exciting. Presumably, they wanted to save some bandwidth. Or maybe, they knew that, some day, they'd waste my time - who knows?

## Conclusion

When faced with an unknown data type, try the `file` command - it's identified `gzip`, `bzip2`, `zlib`, and other stuff for me. It can save you a whole lot of trouble!
