---
id: 567
title: 'Using Nmap to detect the Arucer (ie, Energizer) Trojan'
date: '2010-03-08T13:42:35-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=567'
permalink: '/?p=567'
---

Hey,

I don't usually write two posts in one day, but today is a special occasion! I was reading my news feeds (well, my co-op student (ie, intern) was -- I was doing paperwork), and noticed a story about a remote backdoor being included with the Energizer UsbCharger software. Too funny!

This Trojan listens for commands on port 7777. [US-CERT's alert](http://www.kb.cert.org/vuls/id/154421) contains some Snort signatures that'll detect it for you, but only if somebody's using it. If you want to actively detect infections, you'll need to use a scanner; as always, [Nmap](http://nmap.org) to the rescue! I spent the morning, along with my co-op student, reverse engineering enough of this Trojan to write an Nmap signature for it.

To detect this Trojan, you'll either need the latest build of Nmap (as of today), or to download the new nmap-service-probes file. Then, simply run a version scan against port 7777 (see below).

## Option 1: latest build

If you are using Linux, I suggest simply checking out the latest SVN version of Nmap:

```
$ svn co --username=guest --password="" svn://svn.insecure.org/nmap ./nmap-svn
$ cd nmap-svn
$ ./configure && make
$ make install
```

## Option 2: update nmap-service-probes

First, find the file on your system called **nmap-service-probes**. On Windows, it'll likely be in c:\\Program Files\\Nmap. On Linux, check /usr/share/nmap and /usr/local/share/nmap. When you find it, replace it with the latest version from Nmap's site:

- <http://nmap.org/svn/nmap-service-probes>

## Perform the scan

Since it's implemented as a simple version probe, all you have to do is scan port 7777 with the version scan option (-sV):

```
nmap -sV -p7777 <target>
```

If you're infected, you'll see the following output:

```
$ nmap -sV -p7777 10.0.0.222

Starting Nmap 5.21 ( http://nmap.org ) at 2010-03-08 12:39 CST
Nmap scan report for 10.0.0.222
Host is up (0.0031s latency).
PORT     STATE SERVICE VERSION
7777/tcp open  arucer  Arucer backdoor (**BACKDOOR**)
Service Info: OS: Windows
```

## Warning!

This technique isn't 100% reliable (because of the Trojan, not because of me!). I've found that the service occasionally goes into an infinite loop trying to receive data, and sometimes it'll disconnect you right away (showing up as tcpwrapped). So, use caution, and ensure you have up to date virus signatures!

## More?

This was actually a fun executable to reverse engineer. It's pretty simple, and isn't packed, so it's a good "my first malware" type of executable. If anybody is interested in more information about it, let me know and I'll see if I can do up a tutorial on how I made this signature! My email address is at the right, ron-at-skullsecurity.netand my Twitter account is iagox86.