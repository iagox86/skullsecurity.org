---
id: 368
title: 'smb-psexec.nse: owning Windows, fast'
date: '2009-12-04T14:59:48-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=368'
permalink: '/?p=368'
---

If any of you saw my [Toorcon talk](http://svn.skullsecurity.org:81/ron/security/2009-10-toorcon/2009-10%20Toorcon.pdf) (and if you did, please post a comment -- I'd love to know who decided to check me out), you saw me talk a bit about smb-psexec.nse. It's a fairly new script, but as I use it and play with it, I'm getting more confident in its usefulness/stability. I like it enough that I intend to do a series of blogs on it, so check back soon!

So anyway, let's start off simple. Today's post will be, what does smb-psexec.nse do?

Well, simply enough, it runs programs somewhere else. It uses the same concepts as Microsoft Sysinternals' [psexec tool](http://technet.microsoft.com/en-us/sysinternals/bb897553.aspx), which does essentially the same thing (but in a more limited sense). It also uses the same idea as the [Metasploit Framework's](http://www.metasploit.com/framework/) psexec module. These tools are great, and do the job perfectly, so why did I bother writing my own?

I'll get deeper into some of these advantages in later blog postings, but for now here's a quick list::

- Multi-platform -- Unlike Sysinternals' tool, which uses built-in Windows libraries, I implemented SMB from scratch in Nmap. That means it'll run on nearly ever platform, including Linux, Windows, BSD, OSX, etc.
- Multiple services -- Sysinternals' tool is designed to run a single program, and Metasploit is designed to run its own payloads (although you aren't limited to those). My tool, on the other hand, is designed for running a number of services at the same time.
- Multiple targets -- Since this is part of Nmap, scanning a wide range of hosts is as easy as scanning a single host.
- Local or remote executables -- The executables to run can be stored locally on the attacker system (say, fgdump.exe) or can already be on the target system (say, ping.exe or traceroute.exe).
- Configuration-based -- Each scan uses a configuration file to set its options. So it's easily configurable and repeatable.
- Output formatting -- The configuration files make it easy to format the output from each remote process

What you require:

- Administrator account
- Port 139 or 445
- The ability to create services

Future posts in this series:

- How to write a configuration file
- A closer look at the default configuration files