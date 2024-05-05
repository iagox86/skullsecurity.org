---
id: 429
title: 'DNS Backdoors (for fun and profit?)'
date: '2010-01-29T17:09:01-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=429'
permalink: '/?p=429'
---

Hey all,

I'm really excited to announce the first release of a tool I've put a lot of hard work into: **dnscat** (it's released as part of nbtool 0.10 -- more on that later!)

dnscat was designed in the tradition of [Netcat](http://netcat.sourceforge.net/) and, more recently, [Ncat](http://nmap.org/ncat). Two hosts can communicate with each other via the DNS protocol.

Communicating by DNS is great because the client only talks to a single DNS server, any DNS server on the Internet (with recursion allowed). And everybody can talk to DNS, otherwise the Internet would never work (how would anybody get to their Facebook pages without it?). Firewalls aren't going to stop you from talking to your local DNS server, right? And I don't know about the average network, but on ours there are thousands of DNS queries every minute, so a little bit of extra traffic just gets lost in the flow.

In brief, it works by taking advantage of DNS recursion. The server has to be the authoritative nameserver for a domain, the way I'm the authoritative server for skullseclabs.org. Any requests that end with skullseclabs.org, no matter where they originate, will eventually connect to 208.81.2.52 (my current address).

If you want more details, check out the wiki page (TODO: link!)

## Where do I get it?

TODO

**Nbtool 0.10 (please see the wiki page (TODO) for newer releases)  
Your best bet is to compile from source. I've tested it on every system I can get my hands on, and it compiles and works great. I've also created a few binary packages for good measure.**

- Source gzip | bz2 (Windows, Linux, FreeBSD, Mac OS X)
- Linux 32-bit gzip | bz2 static (compiled on Slackware 13)
- Linux 64-bit gzip | bz2 static (compiled on Slackware 13-64)
- Windows 32-bit .zip (Windows 2000 or newer)

## How do I use it?

I thought you'd never ask!

The biggest hurdle to using dnscat is becoming an authoritative nameserver. You have to register a domain and point its nameservers at your own address. That takes some effort and money, but the payback, in my opinion, is great! Full two-way communication from anywhere on the Internet?

If you think you have the authoritative nameserver but aren't sure, you can use dnscat's --test command: