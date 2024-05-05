---
id: 262
title: 'Bypassing AV over the Internet with Metasploit'
date: '2009-05-15T14:25:37-05:00'
author: 'Matt Gardenghi'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=262'
permalink: '/?p=262'
---

I performed all of this to learn more about data exfiltration, remote control, etc... over a tightly controlled corp environment. It was depressing actually.... It's far too easy to gain control of a corp network even one that is conscientious. This work is built on the info at [ metasploit.com](http://trac.metasploit.com/wiki/AutomatingMeterpreter).

Oh, let me just say thanks for Metasploit. Words fail to describe how nice this project is. Thanks guys.

So, I want to share what I've learned and offer some thoughts for pondering.

**Attacker Setup**:

\- Wireless router with a Verizon Wireless card (EVDO) as the link to the internet. This means I have a single IP, that it changes, and that my laptop is NATted on the inside of the router.  
\- Laptop with BT 4 installed.

**Victim Setup**:  
\- Corp network has a restrictive FW that denies all outbound by default.  
\- Corp has a proxy; if it can't be proxied, it doesn't happen.  
\- Desktop has direct out through the FW and bypassing the proxy.  
\- Multiple VMs on desktop have various configurations. Some are NATted allowing for them to have direct out, others are bridged and use the proxy and abide by the standard FW rules.

**Caveat**:

As the attacker has to be NATted due to the nature of the Verizon wireless card, some tweaks were made to the tutorial created by HD Moore. HD Moore's instructions create a payload that communicates directly with the IP of the attacker; the msfconsole setup binds to the same IP. Obviously that doesn't work with NAT. So, I set port forwarding on the router. Then the first payload connects to the router's IP and is forwarded to the internal NATted address. The msfconsole binds to the local IP and receives the connection.

**Testing**:

**Step 1**. Testing with a direct out to learn how this works.  
I followed the cheat sheet found at the end of this to post to set up a basic reverse\_tcp connection. It works. Well, it did work after I changed the IP in the payload. Apparently the IP for my router was changed by Verizon right after I checked the IP.... That made my test fail for awhile, but I got over that. :-)

**Step 2.**

I set up a VM network. I have a PFSense FW that is NATted on the WAN side (granting it the same outbound access as the main desktop) and it serves DHCP on the LAN. The FW only allows outbound TCP on ports 80, 443. I then setup a XP Pro VM on the LAN side of the FW.

I re-ran the tests and found that it worked fine. I wanted to see how the whole process worked when I could control the FW. On the main desktop with the corp FW, I can't touch and manipulate the FW. This gave me a more controlled area for testing.

Everything worked fine. The payload reached out over the ports I instructed and connected to my attacking machine as planned.

**Step 3.**

New VM bridged to the network. This VM looks much more like a standard corp image which uses the proxy and standard FW ruleset.

Now, since this machine cannot connect directly out on port 80 (that's blocked), it needs to be routed through the proxy. So, I switched to reverse\_http. Which of course, ran into some significant problems. It's like working on the car or the house, it never goes smoothly. Something always decides to break even in the simplest of projects. :-)

So, next I set the PXHOST, PXURI, and PXPORT on the payload to be executed on the victim. Then I fired up the console and set the PXHOST to the local NATed IP as before. When the payload executed, the victim connected to the console and downloaded the DLL. Then nothing happened.

I pushed the button a few more times. Grrr. No luck.

I wiresharked the victim and discovered that the original payload called http://Public IP/URI which is then forwarded to the internal BT box. The new code though, called http://Private IP/URI because that was the IP that the console new about. Consequently, the victim attempts to contact the internal/non-routable IP address.

FAIL.

**Conclusion** (or Here's what I've learned so far):

If there is no proxy involved and port 80 outbound is open, then you can just reach out and use reverse TCP. If there is a proxy, then you need to utilize reverse\_http. This is a non-issue unless of course you have a NATted IP like myself. How do we fix this? It would seem simplest to have PXHOST1 and PXHOST2. PXHOST1 is the routable IP that is included in the payload for the victim. We want them to reach out to that IP which will be port-forwarded to our local attack machine. The PXHOST2 would be our local IP to which the exploit binds. This should solve lots of problems. First it covers the whole NAT issue, and second, it doesn't increase the load on a victim machine. (Third it should be relatively easy for someone to code. Takers anyone?)

It would be really cool, if the PXHOST/LHOST in the exploit code we sent out to the victim to start the process could handle DNS lookups. Then I could feed the DynDNS entry for my router to the code and not have to worry about time sensitive exploits. During a long pentest, I'd want some code that lasted longer than 4 hours. I guess the answer to that is a static IP, which I have in many circumstances though by no means all of them.

Anyone know how to get my code to re-execute? i.e. become sticky? I guess, I could bind the Metasploit payload to an executable ZIP. One that opens, runs a batch script that migrates the payload to a separate directory and attempts to schedule it with AT, then executes the payload immediately before cleaning itself up. Other than that, I have no idea how to make it sticky.

Comments, suggestions, improvements?

[My cheat sheet](http://www.skullsecurity.org/blogdata/mtgarden/bypassing%AV.txt).