---
title: 'Wiki: Nbtool'
author: ron
layout: wiki
permalink: "/wiki/Nbtool"
date: '2024-08-04T15:51:38-04:00'
---

## nbtool

-   Name: nbtool (netbios tool)
-   OS: Linux, BSD, Mac
-   Language: C
-   Path: <http://svn.skullsecurity.org:81/ron/security/nbtool>
-   Created: 2008-08-02
-   State: Stable

Some tools for NetBIOS and DNS investigation, attacks, and communication.

Features

-   DNS backdoor ([dnscat](dnscat "wikilink"))
    -   [v0.04](http://www.skullsecurity.org/wiki/index.php?title=Dnscat&oldid=2947)
-   NetBIOS queries, registrations, and releases ([nbquery](nbquery "wikilink"))
-   NetBIOS sniffing and poisoning ([nbsniff](nbsniff "wikilink"))
-   Cross-site scripting over DNS ([dnsxss](dnsxss "wikilink"))
-   DNS sniffer ([dnslogger](dnslogger "wikilink"))
-   DNS tester ([dnstest](dnstest "wikilink"))

See the individual tools for more information.

## Supports

Current version is tested on:

-   Linux 32 and 64-bit
-   Mac OS X Intel
-   Windows 2000, XP, 2003
-   iPhone (make iphone) \-- hasn\'t been tested lately
-   iPod Touch (make ipod) \-- hasn\'t been tested lately

(Let me know if it works on other operating systems)

## Downloads

-   Trunk
    -   svn co <http://svn.skullsecurity.org:81/ron/security/nbtool>
-   nbtool 0.05alpha2 (2010-07-06) (svn rev 876)
    -   Subversion: svn co <http://svn.skullsecurity.org:81/ron/security/nbtool-0.05alpha2>
    -   Source: <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2.tgz>
    -   Windows (32-bit): <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2-win32.zip>
    -   Linux (32-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2-bin.tgz>
    -   Linux (64-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2-bin64.tgz>
    -   Changelog: <http://svn.skullsecurity.org:81/ron/security/nbtool-0.05alpha2/CHANGELOG>
-   nbtool 0.05alpha1 (2010-07-06) (svn rev 870)
    -   Subversion: svn co <http://svn.skullsecurity.org:81/ron/security/nbtool-0.05alpha1>
-   nbtool 0.04 (2010-02-20) (svn rev 677)
    -   Subversion: svn co <http://svn.skullsecurity.org:81/ron/security/nbtool-0.04>
    -   Source: <http://www.skullsecurity.org/downloads/nbtool-0.04.tgz>
    -   Windows (32-bit): <http://www.skullsecurity.org/downloads/nbtool-0.04-win32.zip>
    -   Linux (32-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.04-bin.tgz>
    -   Linux (64-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.04-bin64.tgz>
    -   Changelog: Everything changed \-- total rewrite, new tools, etc.

-   nbtool 0.02 (2008-08-25) (svn rev 147)
    -   <http://www.skullsecurity.org/downloads/nbtool-0.02.tar.bz2>
    -   <http://www.skullsecurity.org/downloads/nbtool-0.02.tar.gz>
    -   <http://www.skullsecurity.org/downloads/nbtool-0.02.win32.zip>

-   nbtool 0.01 (2008-08-21)
    -   (note: don\'t remove -g from compile, since I\'m using asserts() in critical points. That\'ll be changed by the next version, it was a temporary measure I forgot about :) )
    -   <http://www.skullsecurity.org/downloads/nbtool-0.01.tar.bz2>
    -   <http://www.skullsecurity.org/downloads/nbtool-0.01.tar.gz>

## How to compile {#how_to_compile}

### Linux

Download the source, extract it, and run \'make\' then \'make install in its directory.

### BSD

Same as Linux (should be compatible with BSD\'s version of make)

### OS X {#os_x}

Same as BSD and Linux

### Windows

Double-click on the .sln file in the \'mswin32\' folder to load in Visual Studio, then compile.

## Hacking

If you want to help out with nbtool, that\'s great! Take a look at the TODO file in the source, or come up with your own ideas about how we can play with NetBIOS/DNS/other nameservers.

Right now, there\'s no mailing list or anything like that \-- the project is too young \-- but feel free to email me (ron -at- skullsecurity.net) with ideas or patches (against latest svn build).
