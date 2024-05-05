---
id: 233
title: 'Scanning for Conficker&#8217;s peer to peer'
date: '2009-04-19T14:23:56-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=233'
permalink: '/?p=233'
---

Hi everybody,

With the help of Symantec Security Research, I've put together a script that'll detect Conficker (.C and up) based on its peer to peer ports. The script is called p2p-conficker.nse, and automatically runs against any Windows system:

```
nmap --script p2p-conficker.nse -p445 <host>
sudo nmap -sU -sS --script p2p-conficker.nse -p U:137,T:139 <host>
```

## How do I get it?

Update to the newest [Nmap SVN version](http://nmap.org/book/install.html#inst-svn), or download and install [Nmap 4.85beta8 or higher](http://nmap.org/download.html).

## How do I know if I'm infected?

Four tests are performed. If any of those tests come back INFECTED, you're probably infected. For example:

```
Host script results:
|  p2p-conficker: Checking for Conficker.C or higher...
|  | Check 1 (port 21249/tcp): INFECTED (Received valid data)
|  | Check 2 (port 25561/tcp): INFECTED (Received valid data)
|  | Check 3 (port 26106/udp): INFECTED (Received valid data)
|  | Check 4 (port 46447/udp): INFECTED (Received valid data)
|_ |_ 4/4 checks: Host is likely INFECTED
```

That would indicate a host that's definitely infected. But even if only one of the ports came back, you are still infected:

```
Host script results:
|  p2p-conficker: Checking for Conficker.C or higher...
|  | Check 1 (port 21249/tcp): INFECTED (Received valid data)
|  | Check 2 (port 25561/tcp): CLEAN (Couldn't connect)
|  | Check 3 (port 26106/udp): CLEAN (Failed to receive data)
|  | Check 4 (port 46447/udp): CLEAN (Failed to receive data)
|_ |_ 1/4 checks: Host is likely INFECTED
```

And finally, if one or more ports come back with a possible infection (invalid data or an incorrect checksum), you should be cautious -- it could indicate an infection and a flaky network or a different generation of the worm (what are the chances of two random ports being open?) This might look like this:

```
Host script results:
|  p2p-conficker: Checking for Conficker.C or higher...
|  | Check 1 (port 21249/tcp): CLEAN (Data received, but checksum was invalid (possibly INFECTED))
|  | Check 2 (port 25561/tcp): CLEAN (Data received, but checksum was invalid (possibly INFECTED))
|  | Check 3 (port 26106/udp): CLEAN (Failed to receive data)
|  | Check 4 (port 46447/udp): CLEAN (Failed to receive data)
|_ |_ 0/4 checks: Host is CLEAN or ports are blocked
```

## If it says I'm clean, how sure is it?

Unfortunately, this check, like my [other Conficker check](http://www.skullsecurity.org/blog/?p=209), isn't 100% reliable. There are several factors here:

- This peer to peer first appeared in Conficker.C, so Conficker.A and Conficker.B won't be detected
- It relies on connecting to Conficker's ports -- firewalls or port filters can block this
- If the host is multihomed or NATed, the wrong ports will be generated. If you know its real IP, see the sample commands below
- If the Windows ports are blocked (445/139), the check won't run by default. This behaviour can be overridden, see the sample commands below

## How does this work?

When Conficker.C or higher infects a system, it opens four ports for communication (two TCP and two UDP). It uses these to connect to other infected hosts to send/receive updates and other information.

## Sample commands

Perform a simple check:

```
nmap --script p2p-conficker.nse -p445 <host>
or
sudo nmap -sU -sS --script p2p-conficker.nse -p U:137,T:139 <host>
```

Run the check on the system, with the standard Conficker ports, no matter which ports are open (probably the best way to run it, but somewhat slow):

```
nmap --script p2p-conficker.nse -p445 --script-args=checkconficker=1 <host>
```

Check all 65535 ports to see if any have been opened by Conficker (VERY slow, but thorough):

```
nmap --script p2p-conficker.nse -p- --script-args=checkall=1 <host>
```

Check the standard Conficker ports for a chosen IP address (in other words, override the IP address that's used to generate the ports):

```
nmap --script p2p-conficker.nse -p445 --script-args=realip="192.168.1.65" <host>
```

## Conclusion

Hopefully the script helps you out! And, as usual, don't hesitate to contact me if you have any issues! You can find me in a bunch of places:

- Post a comment here (I try hard to answer every comment)
- Post a message to [Nmap-dev](http://insecure.org/mailman/listinfo/nmap-dev)
- Email me (ron --- skullsecurity.org)
- \#nmap on FreeNode (I don't look at that so often, though)