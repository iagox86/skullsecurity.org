---
id: 1986
title: 'dnscat2 beta release!'
date: '2015-03-26T09:26:49-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=1986'
permalink: /2015/dnscat2-beta-release
categories:
    - DNS
    - Tools
---

As I promised during my 2014 Derbycon talk (amongst other places), this is an initial release of my complete re-write/re-design of the dnscat service / protocol. It's now a standalone tool instead of being bundled with nbtool, among other changes. :)

I'd love to have people testing it, and getting feedback is super important to me! Even if you don't try this version, hearing that you're excited for a full release would be awesome. The more people excited for this, the more I'm encouraged to work on it! In case you don't know it, my email address is listed below in a couple places.

## Where can I get it?

Here are some links:

5. [Sourcecode on github](https://github.com/iagox86/dnscat2/tree/v0.01) ([HEAD sourcecode](https://github.com/iagox86/dnscat2))
6. [Downloads](https://downloads.skullsecurity.org/dnscat2/) (you'll find [signed](https://downloads.skullsecurity.org/ron.pgp) Linux 32-bit, Linux 64-bit, Win32, and source code versions of the client, plus an archive of the server—keep in mind that that signature file is hosted on the same server as the files, so if you're worried, please verify :) )
7. [User documentation](https://github.com/iagox86/dnscat2/blob/v0.01/README.md)
8. [Protocol](https://github.com/iagox86/dnscat2/blob/v0.01/doc/protocol.md) and [command protocol](https://github.com/iagox86/dnscat2/blob/v0.01/doc/command_protocol.md) documents (as a user, you probably don't need these)
9. [Issue tracker](https://github.com/iagox86/dnscat2/issues) (you can also email me issues, just put my first name (ron) in front of my domain name (skullsecurity.net))
## Wait, what happened to dnscat1?

I designed dnscat1 to be similar to netcat; the client and server were the same program, and you could tunnel both ways. That quickly became complex and buggy and annoying to fix. It's had unresolved bugs for years! I've been promising a major upgrade for years, but I wanted it to be reasonably stable/usable before I released anything!

Since generic TCP/IP DNS tunnels have been done (for example, by [iodine](http://code.kryo.se/iodine/)), I decided to make dnscat2 a little different. I target penetration testers as users, and made the server more of a command & control-style service. For example, an old, old version of dnscat2 had the ability to proxy data through the client and out the server. I decided to remove that code because I want the server to be runnable on a trusted network.

Additionally, unlike dnscat1, dnscat2 uses a separate client and server. The client is still low-level portable C code that should run anywhere (tested on 32- and 64-bit Linux, Windows, FreeBSD, and OS X). The server is now higher-level Ruby code that requires Ruby and a few libraries (I regularly use it on Linux and Windows, but it should run anywhere that Ruby and the required gems runs). That means I can quickly and easily add functionality to the server while implementing relatively simple clients.

## How can I help?

The goal of this release is primarily to find bugs in compilation, usage, and documentation. Everything *should* work on all 32- and 64-bit versions of Linux, Windows, FreeBSD, and OS X. If you get it working on any other systems, let me know so I can advertise it!

I'd love to hear from anybody who successfully or unsuccessfully tried to get things going. Anything from what you liked, what you didn't like, what was intuitive, what was unintuitive, where the documentation was awesome, where the documentation sucked, what you like about my face, what you hate about my face—anything at all! Seriously, if you get it working, email me—knowing that people are using it is awesome and motivates me to do more. :)

For feedback, my email address is my first name (ron) at my domain (skullsecurity.net). If you find any bugs or have any feature requests, the best place to go is my [Issue tracker](https://github.com/iagox86/dnscat2/issues).

## What's the future hold?

I've spent a lot of time on stability and bugfixes recently, which means I haven't been adding features. The two major features that I plan to add are:

- TCP proxying - basically, creating a tunnel that exits through the client
- Shellcode - a x86/x64 implementation of dnscat for Linux and/or Windows

Once again, I'd love feedback on which you think is more important, and if you're excited to get shellcode, then which architecture/OS that I should prioritize. :)