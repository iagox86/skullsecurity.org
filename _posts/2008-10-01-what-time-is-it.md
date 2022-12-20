---
id: 76
title: 'What time IS it?'
date: '2008-10-01T10:20:25-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=76'
permalink: /2008/what-time-is-it
categories:
    - hacking
    - smb
---

How synced up are the clocks on your servers? Ignoring your system times may give an important clue to attackers. Read on to find out more!
<!--more-->
My first script addition to Nmap was, as you'll recall if you read my <a href='http://www.skullsecurity.org/blog/?p=64'>previous post</a>, an addition to the SMB script that would pull the system time over SMB. While testing other scripts today, I had an idea -- scan a random subnet and see how synchronized the clocks are. 

Well, I only tried it with one class C, and here are my results:

<pre>$ ./nmap --script=smb-os-discovery.nse xxx.xxx.xxx.xxx/24 -p 139,445 \
        | grep "System time" \
        | sort -r
|_ System time: 2008-10-01 11:32:37 UTC-5
|_ System time: 2008-10-01 11:29:24 UTC-5
|_ System time: 2008-10-01 10:09:19 UTC-5
|_ System time: 2008-10-01 10:04:45 UTC-5
|_ System time: 2008-10-01 10:04:28 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-7
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:25 UTC-5
|_ System time: 2008-10-01 10:04:23 UTC-7
|_ System time: 2008-10-01 10:04:20 UTC-5
|_ System time: 2008-10-01 00:37:41 UTC-5
|_ System time: 2008-06-01 17:13:33 UTC-7
</pre>

To summarize: 11 servers out of 17 that responded came back with roughly the proper time, and 14 were in the proper timezone. A couple are off by an hour or so, one thought it was midnight, and one thought it was June. Maybe it misses the summer? 

Now, if I'm an attacker, which server would have the highest priority? The ones that are synced up to the proper time, or the one that thinks it's June? Which one do you think is watched more carefully by administrators, or used more frequently by users?

Of course, I took the obvious choice. From a quick look, the system turned out to be Windows 2003 SP0. No service packs. And I'm willing to put money that if I loaded up Metasploit and threw a couple oldschool exploits at it (MS04-011 anybody?), I'd be in in no time.

So there you have it -- if you're looking for a way to prioritize targets on a network, take a look at the system time. The further out of sync it is, the more likely you've found a server that's been forgotten. And forgotten servers often aren't monitored or updated as frequently as others. 
