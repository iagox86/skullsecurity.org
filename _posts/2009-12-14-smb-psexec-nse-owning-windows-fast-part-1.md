---
id: 365
title: 'smb-psexec.nse: owning Windows, fast (Part 1)'
date: '2009-12-14T12:38:09-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=365
permalink: "/2009/smb-psexec-nse-owning-windows-fast-part-1"
categories:
- hacking
- smb
- nmap
comments_id: '109638340364342592'

---

Posts in this series (I'll add links as they're written):
<ol>
<li><strong><a href='/blog/?p=365'>What does smb-psexec do?</a></strong></li>
<li><a href='/blog/?p=379'>Sample configurations ("sample.lua")</a></li>
<li><a href='/blog/?p=404 '>Default configuration ("default.lua")</a></li>
<li>Advanced configuration ("pwdump.lua" and "backdoor.lua")</li>
</ol>
<!--more-->
<h2>Getting started</h2>
If any of you saw my <a href='http://svn.skullsecurity.org:81/ron/security/2009-10-toorcon/2009-10%20Toorcon.pdf'>Toorcon talk</a> (and if you did, please post a comment or email me -- I'd love to know if those cards I printed were actually worthwhile), you saw me go ontalk a bit about my <a href='http://nmap.org/nsedoc/scripts/smb-psexec.html'>smb-psexec.nse</script> script (<a href='http://nmap.org/svn/scripts/smb-psexec.nse'>source</a>) for Nmap. It's a fairly new script, but as I use it and play with it, I'm getting more confident in its usefulness/stability. I like it enough that I intend to do a series of posts on it, so check back soon!

So anyway, let's start off simple. Today's post will be, what does smb-psexec.nse do?

<h2>What does it do?</h2>
Well, simply enough, it runs programs somewhere else. Specfically, on a remote Windows machine. It uses the same concepts as Microsoft Sysinternals' <a href='http://technet.microsoft.com/en-us/sysinternals/bb897553.aspx'>psexec tool</a>, which does essentially the same thing (but in a more limited sense). It also uses the same techniques as the <a href='http://www.metasploit.com/framework/'>Metasploit Framework's</a> psexec module. These tools are great, and do the job perfectly, so why did I bother writing my own?

<h2>Why should I care?</h2>
I'll get deeper into some of these points in later blog postings, but for now here's a quick list::
<ul>
<li>Multi-platform -- smb-psexec.nse, including its required SMB/MSRPC libraries, is implemented from scratch in Lua, and therefore can run on any operating system that Nmap runs on. That means it'll run on nearly ever platform, including Linux, Windows, BSD, OSX, etc.</li>
<li>Multiple executables -- While other tools are designed to run a single remote service, smb-psexec, is designed to run any number of executables in a single execution.</li>
<li>Multiple targets -- nmap's scanning capabilities are leveraged here; with Nmap scanning, a wide range of hosts is as easy as scanning a single host.</li>
<li>Local or remote executables -- The executable files can be stored locally on the attacker system (say, fgdump.exe) or can already be on the target system (say, ping.exe or tracert.exe). </li>
<li>Configuration-based -- Each scan uses a configuration file to set its options. As a result, scans are easily configurable and repeatable.</li>
<li>Output formatting -- The configuration files make it easy to format the output from each remote process, allowing you to filter out excess output.</li>
</ul>

The biggest downside with smb-psexec.nse is the loss of interactivity. Because Nmap is written as a scanner, and these scripts are run in parallel, there is no opportunity for user input. But we aren't focusing on the bad stuff today! 

<h2>What do you need?</h2>
So, that's what the script does. Now, before you can run it, what do you need? You'll need the following:
<ul>
<li>Administrator account on the remote system</li>
<li>TCP port 139 <strong>or</strong> 445 open on the remote system</li>
<li>The ability to create services on the remote system</li>
</ul>

<h3>Admin account</h3>
So, the first requirement is easy. You need an administrator account to run services on the machine. Thank $favourite_deity for that; if <em>anybody</em> could run a process on <em>any</em> machine, things would be a lot easier for the bad guys. 

The most obvious way to provide credentials is to pass them on the commandline:
<pre>nmap -p139,445 --script=smb-psexec --script-args=smbuser=ron,smbpass=Password1 &lt;target&gt;</pre>

But, if you either don't know the username/password, or you have many machines with different accounts, you can combine smb-psexec.nse with <a href='http://nmap.org/nsedoc/scripts/smb-brute.html'>smb-brute.nse</a>:
<pre>nmap -p139,445 --script=smb-brute,smb-psexec &lt;target&gt;</pre>

Obviously, when you're performing a bruteforce, there's the possibility of locking out accounts. For that reason, only do that on machine(s) that either you own, or you know the policies on!

<h3>Ports</h3>
The second requirement is that TCP port 139 or 445 has to be open. These ports are functionally equivalent for our purposes, so it doesn't matter which one is open; TCP/445 is raw SMB, and TCP/139 is SMB over NetBIOS -- nmap will autodetect and function accordingly. For what it's worth, TCP/445 is preferred because it has less overhead.

Anyway, as I'm sure you all know, modern versions of Windows (Windows XP SP2, Windows 2003 SP1, Windows Vista, etc) enable the Windows firewall by default. Likewise, many organizations have software firewalls, hardware firewalls, or both. These will obviously block your SMB traffic, and rightly so. Would you want an external entity running smb-psexec.nse?

So, if you're going to run smb-psexec.nse, double check that those ports are open. 

<h3>Service creation</h3>
The final requirement is the ability to create services on the remote system. It sounds simple, but the problem is twofold. The first problem is, the appropriate services have to be enabled; starting with Vista, they're disabled by default. From a quick look, I didn't find the specific services, but there is a generic way to enable them. See the link at the bottom of this section. 

The second problem is that User Account Control (UAC) has to be turned off. Starting on Vista, administrators are treated as ordinary users as long as UAC is enabled. In an odd way this makes sense because the point of UAC is that Windows refuses to grant elevated privileges to any accounts without a user explicitly allowing it. 

If you want to run smb-psexec.nse against a modern Windows version, <a href='http://forum.sysinternals.com/forum_posts.asp?TID=9139'>here's a guide for setting it up</a>.

<h3>Running this script from Windows</h3>
It came to my attention this weekend that, up to and including Nmap 5.10BETA1, the Windows version of Nmap is missing some of the required files for smb-psexec.nse to run. Your best bet is to download the Linux version found <a href='http://nmap.org/dist/nmap-5.10BETA1.tar.bz2'>here</a>, grab the folder <tt>nselib/data/psexec</tt>, and place it in <tt>c:\program files\Nmap\nselib\data</tt>. This will be resolved in any version newer than 5.10BETA1. 

<h2>Conclusion</h2>
So, that's what the smb-psexec.nse script does. Check back soon for new posts!
