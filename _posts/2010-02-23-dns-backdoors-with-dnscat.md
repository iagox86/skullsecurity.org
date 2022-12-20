---
id: 426
title: 'DNS Backdoors with dnscat'
date: '2010-02-23T10:38:34-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=426'
permalink: /2010/dns-backdoors-with-dnscat
categories:
    - DNS
    - Hacking
    - Tools
---

Hey all,

I'm really excited to announce the first release of a tool I've put a lot of hard work into: <strong><a href='/wiki/index.php/dnscat'>dnscat</a></strong>.

It's being released, along with a bunch of other tools that I'll be blogging about, as part of <a href='/wiki/index.php/nbtool'>nbtool 0.04</a>. 
<!--more-->
<h2>What can dnscat do?</h2>
dnscat was designed in the tradition of <a href='http://netcat.sourceforge.net/'>Netcat</a> and, more recently, <a href='http://nmap.org/ncat'>Ncat</a>. Basically, it lets two hosts communicate with each other via the DNS protocol. One of my favourite features is the --exec flag, which lets you tunnel a shell (or a netcat socket) through the DNS protocol -- how awesome is that?

Communicating by DNS is great because the client only needs the ability to talk to a single DNS server, any DNS server on the Internet (with recursion enabled). dnscat will, by default, use the system DNS server, which should cover basically every case. Firewalls aren't going to stop you from talking to your local DNS server, right? And I don't know about the average network, but on ours there are thousands of DNS queries every minute, so a little bit of extra traffic just gets lost in the flow. 

In brief, dnscat works by taking advantage of DNS recursion. It sends messages to the authoritative nameserver for a domain, which is the key -- to be a server, you have to be the authoritative nameserver for a domain. For example, I'm the authoritative server for skullseclabs.org, so any requests that end with .skullseclabs.org, no matter where they originate, will eventually connect to 208.81.2.52 (my current address). 

If you want more details, check out the full documentation:
<ul>
<li><a href='/wiki/index.php/dnscat'>dnscat</a></li>
<li><a href='/wiki/index.php/nbtool'>nbtool</a></li>
</ul>

<h2>Where do I get dnscat?</h2>
For complete instructions on how to download and install it, check out the <a href='/wiki/index.php/Nbtool#Downloads'>download section</a> in the nbtool documentation -- dnscat is a standalone executable that comes with nbtool. 

Your best bet is to compile from source, if you're on a *nix system. I've tested it on every system I can get my hands on, and it compiles and works great. That being said, I've also created a few binary packages for good measure (primarily Windows, but also 32- and 64-bit Slackware, which might run on other Linux distributions). 

At some point in the future, I'd like to be able to generate .rpm and .deb files, but I have no experience with that. 

<h2>Which operating systems does dns support?</h2>
I have compiled and tested it on:
<ul>
<li>Slackware 13 (32- and 64-bit)</li>
<li>Windows 2000, XP, 2003 (Visual Studio)</li>
<li>FreeBSD 7.2 and 8 (32- and 64-bit)</li>
<li>Mac OS X (10.6, I think)</li>
</ul>

I expect it'll compile on any modern Linux or Windows system with either gcc or Visual Studio. My code is reasonably POSIX compliant, and has no external library dependencies.

<h2>How do I use dnscat?</h2>
I thought you'd never ask! 

The biggest hurdle to using dnscat is becoming an authoritative nameserver. You have to register a domain and point its nameservers at your own address. That takes some effort and money, but the payback, in my opinion, is great! Full two-way communication from anywhere on the Internet without worrying firewalls?

If you think you have the authoritative nameserver for your domain but aren't sure, you can use dnscat's --test command (or run dnstest):
<pre>dnstest --domain <yourdomain></pre>
or
<pre>dnscat --test <yourdomain></pre>

Once you have your authoritative nameserver set up and you want to try it out, you can create a server like this (on the authoritative server):
<pre>dnscat --listen</pre>

Then, on the client (anywhere on the Intenet), you can run:
<pre>dnscat --domain &lt;yourdomain&gt;</pre>

There's a lot more you can do, of course. My favourite is the --exec command, which can run an application over dns on either the server or the client (works best on the client). With --exec, you can tunnel a shell over DNS or forward a connection through it using netcat. 

If you want some different examples, including how to tunnel a shell or how to tunnel a socket (ssh session), check out <a href='/wiki/index.php/Dnscat#Examples.2Fusage'>the examples/usage</a> section of the documentation. If you'd like to contribute your own examples or use cases, please do! Or, if you have an idea and would like me to figure out how to do it, that's good too. 

<h2>Can I implement my own client/server?</h2>
Yes for clients! Currently, I have my C implementation (built into dnscat), and my friend Stef wrote a Javascript implementation (included in the samples/ folder of the source install). If you want to implement a client in any other language, and you're ok with releasing it under dnscat's permissive license, I'll add it to the source tree! I went into gory detail about <a href='/wiki/index.php/Dnscat#Protocol'>the dnscat protocol</a> in the documentation. 

You're also welcome to implement a server, but I don't know why you would. If you write a good, working, and compatible server in another language, I'd be happy to add it to the tree!

<h2>How else can I help?</h2>
The best thing you can do right now is to help me test it and develop the use cases/documentation. Also, if you have experience developing Linux installers (.rpm, .deb, etc) and would like to help out, please let me know. 
