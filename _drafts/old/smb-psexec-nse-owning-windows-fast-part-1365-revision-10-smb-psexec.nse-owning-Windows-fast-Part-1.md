---
id: 375
title: 'smb-psexec.nse: owning Windows, fast (Part 1)'
date: '2009-12-14T12:28:23-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=375'
permalink: '/?p=375'
---

Posts in this series (I'll add links as they're written):

1. **[What does smb-psexec do?](/blog/?p=365)**
2. Sample configurations ("sample.lua")
3. Default configuration ("default.lua")
4. Advanced configuration ("pwdump.lua" and "backdoor.lua")
5. Conclusions

## Getting started

If any of you saw my [Toorcon talk](http://svn.skullsecurity.org:81/ron/security/2009-10-toorcon/2009-10%20Toorcon.pdf) (and if you did, please post a comment or email me -- I'd love to know if those cards I printed were actually worthwhile), you saw me go ontalk a bit about my [smb-psexec.nse script (](http://nmap.org/nsedoc/scripts/smb-psexec.html)[source](http://nmap.org/svn/scripts/smb-psexec.nse)) for Nmap. It's a fairly new script, but as I use it and play with it, I'm getting more confident in its usefulness/stability. I like it enough that I intend to do a series of posts on it, so check back soon!

So anyway, let's start off simple. Today's post will be, what does smb-psexec.nse do?

## What does it do?

Well, simply enough, it runs programs somewhere else. Specfically, on a remote Windows machine. It uses the same concepts as Microsoft Sysinternals' [psexec tool](http://technet.microsoft.com/en-us/sysinternals/bb897553.aspx), which does essentially the same thing (but in a more limited sense). It also uses the same techniques as the [Metasploit Framework's](http://www.metasploit.com/framework/) psexec module. These tools are great, and do the job perfectly, so why did I bother writing my own?

## Why should I care?

I'll get deeper into some of these points in later blog postings, but for now here's a quick list::

- Multi-platform -- smb-psexec.nse, including its required SMB/MSRPC libraries, is implemented from scratch in Lua, and therefore can run on any operating system that Nmap runs on. That means it'll run on nearly ever platform, including Linux, Windows, BSD, OSX, etc.
- Multiple executables -- While other tools are designed to run a single remote service, smb-psexec, is designed to run any number of executables in a single execution.
- Multiple targets -- Nmap's scanning capabilities are leveraged here; with Nmap scanning, a wide range of hosts is as easy as scanning a single host.
- Local or remote executables -- The executable files can be stored locally on the attacker system (say, fgdump.exe) or can already be on the target system (say, ping.exe or tracert.exe).
- Configuration-based -- Each scan uses a configuration file to set its options. As a result, scans are easily configurable and repeatable.
- Output formatting -- The configuration files make it easy to format the output from each remote process, allowing you to filter out excess output.

The biggest downside with smb-psexec.nse is the loss of interactivity. Because Nmap is written as a scanner, and these scripts are run in parallel, there is no opportunity for user input. But we aren't focusing on the bad stuff today!

## What do you need?

So, that's what the script does. Now, before you can run it, what do you need? You'll need the following:

- Administrator account on the remote system
- TCP port 139 **or** 445 open on the remote system
- The ability to create services on the remote system

### Admin account

So, the first requirement is easy. You need an administrator account to run services on the machine. Thank $favourite\_deity for that; if *anybody* could run a process on *any* machine, things would beThe most obvious way is to pass the username and password on the commandline:

```
nmap -p139,445 --script=smb-psexec --script-args=smbuser=ron,smbpass=Password1 <target>
```

But, if you either don't know the username/password, or you have many machines with different accounts, you can combine smb-psexec.nse with [smb-brute.nse](http://nmap.org/nsedoc/scripts/smb-brute.html):

```
nmap -p139,445 --script=smb-brute,smb-psexec <target>
```

Obviously, when you're performing a bruteforce, there's the possibility of locking out accounts. For that reason, only do that on your own machine(s) if you know the policies!

### Ports

The second requirement is that port 139 or 445 has to be open. These ports are functionally equivalent for our purposes; TCP/445 is raw SMB, and TCP/139 is SMB over NetBIOS -- Nmap will autodetect and function accordingly.

Anyway, as I'm sure you all know, modern versions of Windows (Windows XP SP2, Windows 2003 SP1, Windows Vista, etc) enable the Windows firewall by default. Likewise, many organizations have software firewalls, hardware firewalls, or both. These will obviously block your SMB traffic, and rightly so. Would you want an external entity running smb-psexec.nse?

### Service creation

The final requirement is the ability to create services. It sounds simple, but the problem is twofold. The first problem is, the appropriate services have to be enabled; starting with Vista, they're disabled by default. From a quick look, I didn't find the specific services, but a link below will tell you how to enable them.

The second problem is that User Account Control (UAC) has to be turned off. Starting on Vista, administrators are treated as ordinary users until UAC has been turned off. In an odd way, this makes sense, because Windows refuses to grant elevated privileges to any accounts without a user explicitly allowing it.

If you want to run smb-psexec.nse against a modern Windows version, [here's a guide for setting it up](http://forum.sysinternals.com/forum_posts.asp?TID=9139).

### Running on Windows

It came to my attention this weekend that, up to Nmap 5.10BETA1, the Windows version of Nmap is missing some of the required files for smb-psexec.nse to run. Your best bet is to download the Linux version found [here](http://nmap.org/dist/nmap-5.10BETA1.tar.bz2), grab the folder <tt>nselib/data/psexec</tt>, and place it in <tt>c:\\program files\\Nmap\\nselib\\data</tt>. This will be resolved in any version newer than 5.10BETA1.

## Conclusion

So, that's what the smb-psexec.nse script does. Check back soon for new posts!