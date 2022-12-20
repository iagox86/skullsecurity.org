---
id: 230
title: 'Scanning for Conficker&#8217;s peer to peer'
date: '2009-04-21T16:44:11-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=230'
permalink: /2009/scanning-for-confickers-peer-to-peer
categories:
    - Malware
    - Tools
---

Hi everybody,

With the help of Symantec's Security Intelligence Analysis Team, I've put together a script that'll detect Conficker (.C and up) based on its peer to peer ports. The script is called p2p-conficker.nse, and automatically runs against any Windows system when scripts are being used:
<pre>nmap --script p2p-conficker,smb-os-discovery,smb-check-vulns \
        --script-args=safe=1 -T4 -p445 &lt;host&gt;
or
sudo nmap -sU -sS --script p2p-conficker,smb-os-discovery,smb-check-vulns \
        --script-args=safe=1 -T4 -p U:137,T:139 &lt;host&gt;</pre>

See below for more information! 

Or, if you just want to scan your network fast, give this a shot:
<pre>nmap -p139,445 --script p2p-conficker,smb-os-discovery,smb-check-vulns \
        --script-args=checkconficker=1,safe=1 -T4 &lt;host&gt;</pre>

<ul>
<li><a href='http://seclists.org/nmap-dev/2009/q2/0161.html'>Official Nmap announcement</a></li>
<li><a href='https://forums2.symantec.com/t5/Malicious-Code/W32-Downadup-P2P-Scanner-Script-for-Nmap/ba-p/393519#A266'>Official Symantec announcement</a></li>
</ul>
<!--more-->

<h2>How do I get it?</h2>
Update to the newest <a href='http://nmap.org/book/install.html#inst-svn'>Nmap SVN version</a>, download the <a href='http://nmap.org/svn/scripts/p2p-conficker.nse'>.nse file</a> (<a href='http://nmap.org/nsedoc/scripts/p2p-conficker.html'>info</a>) and put it in your 'scripts' folder, or download and install <a href='http://nmap.org/download.html'>Nmap 4.85beta8 or higher</a>. 

<h2>How do I know if I'm infected?</h2>
Four tests are performed. If any of those tests come back INFECTED, you're probably infected. For example:
<pre>Host script results:
|  p2p-conficker: Checking for Conficker.C or higher...
|  | Check 1 (port 21249/tcp): INFECTED (Received valid data)
|  | Check 2 (port 25561/tcp): INFECTED (Received valid data)
|  | Check 3 (port 26106/udp): INFECTED (Received valid data)
|  | Check 4 (port 46447/udp): INFECTED (Received valid data)
|_ |_ 4/4 checks: Host is likely INFECTED
</pre>
That would indicate a host that's definitely infected. But even if only one of the ports came back, you are still infected:
<pre>Host script results:
|  p2p-conficker: Checking for Conficker.C or higher...
|  | Check 1 (port 21249/tcp): INFECTED (Received valid data)
|  | Check 2 (port 25561/tcp): CLEAN (Couldn't connect)
|  | Check 3 (port 26106/udp): CLEAN (Failed to receive data)
|  | Check 4 (port 46447/udp): CLEAN (Failed to receive data)
|_ |_ 1/4 checks: Host is likely INFECTED
</pre>

And finally, if one or more ports come back with a possible infection (invalid data or an incorrect checksum), you should be cautious -- it could indicate an infection and a flaky network or a different generation of the worm (what are the chances of two random ports being open?) This might look like this:

<pre>Host script results:
|  p2p-conficker: Checking for Conficker.C or higher...
|  | Check 1 (port 21249/tcp): CLEAN (Data received, but checksum was invalid (possibly INFECTED))
|  | Check 2 (port 25561/tcp): CLEAN (Data received, but checksum was invalid (possibly INFECTED))
|  | Check 3 (port 26106/udp): CLEAN (Failed to receive data)
|  | Check 4 (port 46447/udp): CLEAN (Failed to receive data)
|_ |_ 0/4 checks: Host is CLEAN or ports are blocked</pre>

<h2>If it says I'm clean, how sure is it?</h2>
Unfortunately, this check, like my <a href='http://www.skullsecurity.org/blog/?p=209'>other Conficker check</a>, isn't 100% reliable. There are several factors here:
<ul>
<li>This peer to peer first appeared in Conficker.C, so Conficker.A and Conficker.B won't be detected</li>
<li>It relies on connecting to Conficker's ports -- firewalls or port filters can block this</li>
<li>If the host is multihomed or NATed, the wrong ports will be generated. If you know its real IP, see the sample commands below</li>
<li>If the Windows ports are blocked (445/139), the check won't run by default. This behaviour can be overridden, see the sample commands below</li>
</ul>

<h2>How does this work?</h2>
When Conficker.C or higher infects a system, it opens four ports for communication (two TCP and two UDP). It uses these to connect to other infected hosts to send/receive updates and other information. These ports are based on two factors: a) the IP address, and b) the current time (the weeks since Jan 1 1970). 

Thanks to research by Symantec (and others), the port-generation algorithm and the protocol have been discovered, and that's what I implemented in my script. Each packet has an encryption key, some data and a checksum (encrypted), and some noise. By sending a packet to an infected host on any of its ports, the host will respond. That response indicates an infection. 

For more details on how it works, see <a href='http://nmap.org/svn/scripts/p2p-conficker.nse'>the code itself</a>. 

<h2>Sample commands</h2>
Perform a simple check:
<pre>nmap --script p2p-conficker,smb-os-discovery,smb-check-vulns \
        --script-args=safe=1 -T4 -p445 &lt;host&gt;
or
sudo nmap -sU -sS --script p2p-conficker,smb-os-discovery,smb-check-vulns \
        --script-args=safe=1 -T4 -p U:137,T:139 &lt;host&gt;</pre>

This is probably the <strong>best</strong> way to run a fast scan. It does a ping sweep then scans every host:
<pre>nmap -p139,445 --script p2p-conficker,smb-os-discovery,smb-check-vulns \
        --script-args=checkconficker=1,safe=1 -T4 &lt;host&gt;</pre>

Check all 65535 ports to see if any have been opened by Conficker (VERY slow, but thorough):
<pre>nmap --script p2p-conficker,smb-os-discovery,smb-check-vulns -p- \
        --script-args=checkall=1,safe=1 -T4 &lt;host&gt;</pre>

Check the standard Conficker ports for a chosen IP address (in other words, override the IP address that's used to generate the ports):
<pre>nmap --script p2p-conficker,smb-os-discovery -p445 \
        --script-args=realip=\"192.168.1.65\" -T4 &lt;host&gt;</pre>

<h2>But wait, there's more!</h2>
<a href='http://nmap.org/nsedoc/scripts/smb-check-vulns.html'>smb-check-vulns.nse</a> can now detect Conficker.D (and .E) using the same techniques as <a href='http://iv.cs.uni-bonn.de/wg/cs/applications/containing-conficker/'>scs2.py</a>. 

<h2>Conclusion</h2>
Hopefully the script helps you out! And, as usual, don't hesitate to contact me if you have any issues! You can find me in a bunch of places:
<ul>
<li>Post a comment here (I try hard to answer every comment)</li>
<li>Post a message to <a href='http://insecure.org/mailman/listinfo/nmap-dev'>Nmap-dev</a></li>
<li>Email me (ron --- skullsecurity.org)</li>
<li>#nmap on FreeNode (I don't look at that so often, though)</li>
</ul>

