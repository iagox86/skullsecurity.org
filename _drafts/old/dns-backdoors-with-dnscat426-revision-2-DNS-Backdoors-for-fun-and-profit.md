---
id: 428
title: 'DNS Backdoors (for fun and profit?)'
date: '2010-01-29T16:57:56-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=428'
permalink: '/?p=428'
---

Hey all,

I'm really excited to announce the first release of a tool I've put a lot of hard work into: **dnscat** (it's released as part of nbtool 0.10 -- more on that later!)

dnscat was designed in the tradition of [Netcat](http://netcat.sourceforge.net/) and, more recently, [Ncat](http://nmap.org/ncat). Two hosts can communicate with each other via the DNS protocol.

Communicating by DNS is great because the client only talks to a single DNS server, any DNS server on the Internet (with recursion allowed). And everybody can talk to DNS, otherwise the Internet would never work (how would anybody get to their Facebook pages without it?).