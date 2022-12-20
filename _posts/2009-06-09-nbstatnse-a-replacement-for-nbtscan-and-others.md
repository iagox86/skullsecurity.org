---
id: 298
title: 'nbstat.nse: just like nbtscan'
date: '2009-06-09T21:10:36-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=298'
permalink: /2009/nbstatnse-a-replacement-for-nbtscan-and-others
categories:
    - NetBIOS/SMB
    - Tools
---

Hey all,

With the upcoming release of Nmap 4.85, Brandon Enright <a href='http://seclists.org/nmap-dev/2009/q2/0647.html'>posted some comments</a> on random Nmap thoughts. One of the things he pointed out was that people hadn't heard of <strong>nbstat.nse</strong>! Since I love showing off what I write, this blog was in order. 
<!--more-->
<h2>How do I scan a single host?</h2>
Simply initiate an Nmap scan against a Windows or Samba target, and either run the 'default' scripts or specifically nbstat.nse. For example:
<pre>nmap --script=nbstat &lt;target&gt;
or
nmap --script=default &lt;target&gt;</pre>

The result is simple to interpret:
<pre>|_ nbstat: NetBIOS name: BASEWIN2K3, NetBIOS user: <unknown>, NetBIOS MAC: 00:0c:29:03:8f:64</pre>

This will run against any system that has Windows or Samba ports open (tcp/139 or tcp/445). 

The NetBOIS name in the result is, obviously, the name given to the target machine. The NetBIOS user is the name of the user who's logged into the target's console, if it's returned (frequently, it isn't). And finally, if the MAC address is given by the host (it's always given on Windows, never on Samba), it's displayed. 

This is a very quick check (a single UDP packet) and gives a decent amount of information about the host. For more information, check out the page for the very nice <a href='http://www.inetcat.net/software/nbtscan.html'>nbtscan tool</a>. 

<h2>How to scan a large network</h2>
Thanks to Brandon Enright for providing this! It's a fast way to scan your network for Windows hosts, and run nbscan against them (note: requires a good connection, and requires Windows hosts to have port 445 open):

<pre>sudo nmap -T5 -PN -p 445 -sS -n --min-hostgroup 8192 --min-rtt-timeout 1000 \
--min-parallelism 4096 --script=nbstat &lt;target&gt;
</pre>

This scan took about 2 minutes on a /16 when Brandon tried. 

<h2>How does it work?</h2>
Talking about how my scripts work... always my favourite part! But prepare for some technical details...

The easy answer is this: <strong>nbstat.nse</strong> sends a request to a Windows machine on port 137. It's a static request and can be hardcoded. The server responds with its name, MAC address, and other details. 

<h3>Request</h3>
The header of the packet looks like this:
<pre>
  --------------------------------------------------
  |  15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0 |
  |                  NAME_TRN_ID                    |
  | R |   OPCODE  |      NM_FLAGS      |   RCODE    | (FLAGS)
  |                    QDCOUNT                      |
  |                    ANCOUNT                      |
  |                    NSCOUNT                      |
  |                    ARCOUNT                      |
  --------------------------------------------------
</pre>
The TRN_ID, or transaction ID, is a random 2-byte value that identifies a request or response. In <strong>nbstat.nse</strong>, I use 0x1337. 

For our purposes, the flags and COUNT fields, except QDCOUNT, are unnecessary and set to 0. QDCOUNT refers to the number of questions we're asking the host. Since we're asking only a single question ("who are you?"), this is set to 1. 

When all's said and done, this is our encoded header:
<pre>13 37 00 00 00 01 00 00 00 00 00 00</pre>

The body of the packet is a list of names to check for in the following format:
<ul>
<li>(string) encoded name</li>
<li>(2 bytes)  query type (0x0021 = NBSTAT)</li>
<li>(2 bytes)  query class (0x0001 = IN)</li>
</ul>

The encoded name is the name we're looking up -- '*' in our case (matches any name). It's encoded through a somewhat complicated function that changes any arbitrary binary data to a string of uppercase characters preceded by a length byte (check out 'netbios.lua' in 'nselib', included with Nmap, if you're interested). The string '*' translates to ' CKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' (the initial space is 0x20, or 32 -- the length of the encoded string). 

The query type and query class are constant values. The final body is:
<pre> 20 43 4b 41 41 41 41 41 41 41 41 41 41 41 41 41 
 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 
 41 00 00 21 00 01</pre>

The full packet is this:
<pre>00000000 13 37 00 00 00 01 00 00 00 00 00 00 20 43 4b 41    .7.......... CKA
00000010 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41    AAAAAAAAAAAAAAAA
00000020 41 41 41 41 41 41 41 41 41 41 41 41 41 00 00 21    AAAAAAAAAAAAA..!
00000030 00 01                                              ..</pre>

For fun, you can send this string with netcat to any system listening on 137, and you'll probably get a good response:
<pre>echo -ne "\x13\x37\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x20\x43\x4b\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x00\x00\x21\x00\x01" | nc -u 192.168.200.128 137 | hexdump -C
00000000  13 37 84 00 00 00 00 01  00 00 00 00 20 43 4b 41  |.7.......... CKA|
00000010  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000020  41 41 41 41 41 41 41 41  41 41 41 41 41 00 00 21  |AAAAAAAAAAAAA..!|
00000030  00 01 00 00 00 00 00 9b  06 42 41 53 45 57 49 4e  |.........BASEWIN|
00000040  32 4b 33 20 20 20 20 20  00 04 00 42 41 53 45 57  |2K3     ...BASEW|
00000050  49 4e 32 4b 33 20 20 20  20 20 20 04 00 57 4f 52  |IN2K3      ..WOR|
00000060  4b 47 52 4f 55 50 20 20  20 20 20 20 00 84 00 57  |KGROUP      ...W|
00000070  4f 52 4b 47 52 4f 55 50  20 20 20 20 20 20 1e 84  |ORKGROUP      ..|
00000080  00 57 4f 52 4b 47 52 4f  55 50 20 20 20 20 20 20  |.WORKGROUP      |
00000090  1d 04 00 01 02 5f 5f 4d  53 42 52 4f 57 53 45 5f  |.....__MSBROWSE_|
000000a0  5f 02 01 84 00 00 0c 29  03 8f 64 00 00 00 00 00  |_......)..d.....|
000000b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
</pre>

Note the list of names in the response, and also note the MAC address toward the end (00:0C:29:03:8F:64). 

<h3>Response</h3>
The response has the identical header, except it sets the first flag (0x8000), and sets ANCOUNT to 1 instead of QDCOUNT (an answer instead of a question). The format of the answer is:

<ul>
<li>(string) requested name, encoded</li>
<li>(2 bytes)  query type</li>
<li>(2 bytes)  query class</li>
<li>(2 bytes)  time to live</li>
<li>(2 bytes)  record length</li>
<li>(1 byte)   number of names</li>
<li>[for each name]</li>
<ul>
<li>(16 bytes) padded name, with a 1-byte suffix (not encoded)</li>
<li>(2 bytes)  flags</li>
</ul>
<li>(variable) statistics (usually mac address)</li>
</ul>

Basically, a list of the host's names are returned, with some flags. The last byte in the name, which I call the 'suffix', represents the type of name. I don't know what all the types represent, just that 0x20 represents the server's name and 0x03 represents the current user. 

So there you have it -- performing an nbstat call is actually very simple: build (or just hardcode) the static packet, send it on UDP/137, and parse the response. 

Happy hacking! :)
