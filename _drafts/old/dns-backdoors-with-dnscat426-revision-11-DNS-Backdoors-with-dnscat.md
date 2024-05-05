---
id: 508
title: 'DNS Backdoors with dnscat'
date: '2010-02-22T14:52:30-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=508'
permalink: '/?p=508'
---

Hey all,

I'm really excited to announce the first release of a tool I've put a lot of hard work into: **[dnscat](/wiki/index.php/dnscat)** (I'm releasing it, along with a bunch of other tools, as part of [nbtool 0.04](/wiki/index.php/nbtool) -- more on that later!)

## What can dnscat do?

dnscat was designed in the tradition of [Netcat](http://netcat.sourceforge.net/) and, more recently, [Ncat](http://nmap.org/ncat). Basically, it lets two hosts communicate with each other via the DNS protocol. One of my favourite features is the --exec flag, which lets you tunnel a shell (or a netcat socket) through the DNS protocol -- how awesome is that?

Communicating by DNS is great because the client only needs the ability to talk to a single DNS server, any DNS server on the Internet (with recursion enabled). dnscat will, by default, use the system DNS server, which should cover basically every case. Firewalls aren't going to stop you from talking to your local DNS server, right? And I don't know about the average network, but on ours there are thousands of DNS queries every minute, so a little bit of extra traffic just gets lost in the flow.

In brief, dnscat works by taking advantage of DNS recursion. It sends messages to the authoritative nameserver for a domain, which is the key -- to be a server, you have to be the authoritative nameserver for a domain. For example, I'm the authoritative server for skullseclabs.org, so any requests that end with .skullseclabs.org, no matter where they originate, will eventually connect to 208.81.2.52 (my current address).

If you want more details, check out the full documentation:

- [dnscat](/wiki/index.php/dnscat)
- [nbtool](/wiki/index.php/nbtool)

## Where do I get dnscat?

For complete instructions on how to download and install it, check out the [download section](/wiki/index.php/Nbtool#Downloads) in the nbtool.

Your best bet is to compile from source, if you're on a \*nix system. I've tested it on every system I can get my hands on, and it compiles and works great. That being said, I've also created a few binary packages for good measure (primarily Windows, but also Slackware 32-bit and Slackware 64-bit).

At some point in the future, I'd like to be able to generate .rpm and .deb files, but I have no experience with that.

## Which operating systems does dns support?

I have compiled and tested it on:

- Slackware 13 (32- and 64-bit)
- Windows 2000, XP, 2003 (Visual Studio)
- FreeBSD 7.2 and 8 (32- and 64-bit)
- Mac OS X (10.6, I think)

I expect it'll compile on any modern Linux or Windows system with either gcc or Visual Studio. My code is reasonably POSIX compliant, and has no external library dependencies.

## How do I use dnscat?

I thought you'd never ask!

The biggest hurdle to using dnscat is becoming an authoritative nameserver. You have to register a domain and point its nameservers at your own address. That takes some effort and money, but the payback, in my opinion, is great! Full two-way communication from anywhere on the Internet without worrying firewalls?

If you think you have the authoritative nameserver for your domain but aren't sure, you can use dnscat's --test command (or run dnstest):

```
dnstest --domain <yourdomain></yourdomain>
```

or

```
dnscat --test <yourdomain></yourdomain>
```

Once you have your authoritative nameserver set up and you want to try it out, you can create a server like this (on the authoritative server):

```
dnscat --listen
```

Then, on the client (anywhere on the Intenet), you can run:

```
dnscat --domain <yourdomain></yourdomain>
```

There's a lot more you can do, of course. My favourite is the --exec command, which can be run on the server or the client (works best on the client, though).

If you want some different examples, including how to tunnel a shell or how to tunnel a socket (ssh session), check out [the examples/usage](/wiki/index.php/Dnscat#Examples.2Fusage) section of the documentation. If you'd like to contribute your own examples or use cases, please do! Or, if you have an idea and would like me to figure out how to do it, that's good too.

## Can I implement my own client/server?

Yes for clients! Currently, I have my C implementation (built into dnscat), and my friend Stef wrote a Javascript implementation (included in the samples/ folder of the source install). If you want to implement a client in any other language, and you're ok with releasing it under dnscat's permission license, you're welcome to! I went into gory detail about [the dnscat protocol](/wiki/index.php/Dnscat#Protocol) in the documentation.

You're also welcome to implement a server, but I don't know why you would. If you write a good, working, and compatible server in another language, I'd be happy to add it to the tree!

## How else can I help?

The best thing you can do right now is to help me test it and develop the use cases/documentation. Also, if you have experience developing Linux installers (.rpm, .deb, etc) and would like to help out, please let me know.