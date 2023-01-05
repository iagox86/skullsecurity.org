---
id: 315
title: Scanning for Microsoft FTP with Nmap
date: '2009-09-02T11:51:09-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=315
permalink: "/2009/scanning-for-microsoft-ftp-with-nmap"
categories:
- nmap
- tools
comments_id: '109638336720575688'

---

Hi all,

It's been awhile since my last post, but don't worry! I have a few lined up, particularly about scanning HTTP servers with Nmap. More on that soon! 

In the meantime, I wanted to direct your attention to <a href='http://blog.rootshell.be/2009/09/01/detecting-vulnerable-iis-ftp-hosts-using-nmap/''>This post (<a href='http://blog.rootshell.be/2009/09/01/updated-iis-ftp-nmap-script/'>update here</a>) about finding potentially vulnerable Microsoft FTP servers. 
<!--more-->
This is, of course, related to the currently <a href=http://www.microsoft.com/technet/security/advisory/975191.mspx'>unpatched vulnerability in Microsoft FTP</a>. 

While this is great advice, and a useful script, we've taken the opportunity to put a scorched earth policy in place: tracking down every FTP server (especially Microsoft ones), and decide if they're <em>needed</em>. In many cases, I expect we're going to discover that somebody enabled FTP a long time ago, and never disabled it. 

I asked one of my minions to come up with an Nmap command to find all FTP servers, and this seems to be working nicely:
<pre>./nmap -T4 -PS21 -p21 -O --max-rtt-timeout 200 --initial-rtt-timeout 150 \
--min-hostgroup 100 -oG /tmp/WindowsFTP.grep -iL ../WindowsServers24</pre>

If anybody has any better commands, we'd love to hear it! 
