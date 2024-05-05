---
id: 505
title: 'DNS Backdoors with dnscat'
date: '2010-02-22T14:24:37-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=505'
permalink: '/?p=505'
---

Hey all,

I'm really excited to announce the first release of a tool I've put a lot of hard work into: **[dnscat](/wiki/index.php/dnscat)** (I'm releasing it, along with a bunch of other tools, as part of [nbtool 0.04](/wiki/index.php/nbtool) -- more on that later!)

## What can it do?

dnscat was designed in the tradition of [Netcat](http://netcat.sourceforge.net/) and, more recently, [Ncat](http://nmap.org/ncat). Two hosts can communicate with each other via the DNS protocol.

Communicating by DNS is great because the client only talks to a single DNS server, any DNS server on the Internet (with recursion enabled). And everybody can talk to DNS, otherwise the Internet would never work (how would anybody get to their Facebook pages without it?). Firewalls aren't going to stop you from talking to your local DNS server, right? And I don't know about the average network, but on ours there are thousands of DNS queries every minute, so a little bit of extra traffic just gets lost in the flow.

In brief, it works by taking advantage of DNS recursion. The server has to be the authoritative nameserver for a domain, the way I'm the authoritative server for skullseclabs.org. Any requests that end with skullseclabs.org, no matter where they originate, will eventually connect to 208.81.2.52 (my current address).

If you want more details, check out the wiki pages:

- [dnscat](/wiki/index.php/dnscat)
- [nbtool](/wiki/index.php/nbtool)

## Where do I get it?

For complete instructions on how to download and install it, check out the [nbtool wiki page](/wiki/index.php/nbtool).

Your best bet is to compile from source. I've tested it on every system I can get my hands on, and it compiles and works great. I've also created a few binary packages for good measure (Windows, Slackware 32-bit, Slackware 64-bit).

## Which operating systems does it support?

I have compiled and tested it on:

- Slackware 13 (32- and 64-bit)
- Windows 2000, XP, 2003 (Visual Studio)
- FreeBSD 7.2 and 8 (32- and 64-bit)
- Mac OS X (10.6, I think)

I expect it'll compile on any modern Linux or Windows system with either gcc or Visual Studio.

## How do I use it?

I thought you'd never ask!

The biggest hurdle to using dnscat is becoming an authoritative nameserver. You have to register a domain and point its nameservers at your own address. That takes some effort and money, but the payback, in my opinion, is great! Full two-way communication from anywhere on the Internet?

If you think you have the authoritative nameserver but aren't sure, you can use dnscat's --test command (or run dnstest):

```
dnstest --domain <yourdomain></yourdomain>
```

or

```
dnscat --test <yourdomain></yourdomain>
```

If you want a bunch of examples of what you can do, take a look at [the examples/usage](/wiki/index.php/Dnscat#Examples.2Fusage) section of the documentation. If you'd like to contribute your own examples or use cases, please do!

## Can I implement my own client/server?

Yes for clients! Currently, I have my C implementation (built into dnscat), and my friend Stef wrote a Javascript implementation (included in the samples/ folder of the source install). If you want to implement a client in any other language, and you're ok with releasing it under dnscat's permission license, you're welcome to! I went into gory detail about [the dnscat protocol](/wiki/index.php/Dnscat#Protocol) in the documentation.

You're also welcome to implement a server, but I don't know why you would. If you write a good, working, and compatible server in another language, I'd be happy to add it to the tree!

## How else can I help?

The best thing you can do right now is to help me test it and develop the use cases/documentation.