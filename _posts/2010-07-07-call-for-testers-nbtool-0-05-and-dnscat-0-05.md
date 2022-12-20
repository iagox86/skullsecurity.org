---
id: 876
title: 'Call for testers: nbtool-0.05 and dnscat-0.05'
date: '2010-07-07T09:17:34-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=876'
permalink: /2010/call-for-testers-nbtool-0-05-and-dnscat-0-05
categories:
    - DNS
    - Tools
---

Hey all,

I just released the second alpha build of nbtool (0.05alpha2), and I'm hoping to get a few testers to give me some feedback before I release 0.05 proper. I'm pretty happy with the 0.05 release, but it's easy for me to miss things as the developer. 

I'm hoping for people to test:
<ul>
<li>Through different DNS servers (requires an authoritative DNS server)</li>
<li>With different operating systems (doesn't require an authoritative server) -- I've tested it on Slackware 32-bit, Slackware 64-bit, FreeBSD 8 64-bit, and Windows 2003, those or others would be great!</li>
<li>With different commandline options (also doesn't require authoritative server)</li>
</ul>
<!--more-->
First off, grab the latest dnscat build from either the <a href='/wiki/index.php/Nbtool#Downloads'>nbtool</a> or the <a href='/wiki/index.php/Dnscat#Downloads'>dnscat</a> pages (it's the same file). Whether you build it from the source tarball, use the svn, or use the compiled versions, it's all good and let me know which you choose. 

You can use the same machine for client/server, or put them on separate machines. Here are the important commands:
<ul>
<li>Start the server: dnscat --listen</li>
<li>Start the server that can handle multiple clients: dnscat --listen --multi</li>
<li>Start a client with an authoritative nameserver: dnscat --domain &lt;yourdomainname&gt;</li>
<li>Start a client without an authoritative nameserver: dnscat --dns &lt;dnscatserver&gt;</li>
<li>Finally, check if you have an authoritative server: dnscat --test &lt;yourdomainname&gt;</li>
</ul>
Use the --help argument to find the different options. Although all the options could use a workout, I'm particularly interested in how well --exec and --multi function across different operating systems. You can also get a ton more documentation on the <a href='/wiki/index.php/Dnscat'>wiki page</a>. 

Things you can help me out with:
<ul>
<li>Does it compile without warnings? Which OS?</li>
<li>Does it run?</li>
<li>Can the client/server communicate properly?</li>
<li>Does running --exec /bin/sh (or --exec cmd.exe) on the client give you a shell on the server</li>
<li>Does redirecting a bigger file (for example, dnscat --domain skullseclabs.org < /etc/passwd) work properly?</li>
<li>Do different options you find with --help work the way they're described?</li>
<li>Any other unexplained weirdness?</li>
</ul>

Feedback on any or all of those points would be awesome! Also, I'd love to hear any other feedback, bad news, good news, complaints, compliments, or anything of the sort. Either send me an email (my address is on the right) or leave a comment on this post. 

Thanks for helping out!
