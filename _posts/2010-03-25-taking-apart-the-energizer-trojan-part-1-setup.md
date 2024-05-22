---
id: 627
title: 'Taking apart the Energizer trojan &#8211; Part 1: setup'
featured: true
date: '2010-03-25T09:13:24-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=627
permalink: "/2010/taking-apart-the-energizer-trojan-part-1-setup"
categories:
- malware
- nmap
- re
comments_id: '109638347658633231'

---

Hey all,

As most of you know, a Trojan was <a href='http://www.theregister.co.uk/2010/03/08/energizer_trojan/'>recently discovered</a> in the software for Energizer's USB battery charger. Following its release, I wrote an <a href='http://www.skullsecurity.org/blog/?p=563'>Nmap probe</a> to detect the Trojan and HDMoore wrote a <a href='http://blog.metasploit.com/2010/03/locate-and-exploit-energizer-trojan.html'>Metasploit module</a> to exploit it.

I mentioned in my last post that it was a nice sample to study and learn from. The author made absolutely no attempt to conceal its purpose, once installed, besides a weak XOR encoding for communication. Some conspiracy theorists even think this may have been legitimate management software gone wrong -- and who knows, really? In any case, I offered to write a tutorial on how I wrote the Nmap probe, and had a lot of positive feedback, so here it is!

Just be sure to take this for what it is. This is *not* intended to show any new methods or techniques or anything like that. It's a reverse engineering guide targeted, as much as I could, for people who've never opened IDA or Windbg in their lives. I'd love to hear your comments!
<!--more-->
<h2>Sections</h2>
This tutorial was getting far too long for a single page, so I broke it into four sections:
<ul>
 <li><strong><a href='/2010/taking-apart-the-energizer-trojan-part-1-setup'>Part 1: setup</a></strong></li>
 <li><a href='/2010/taking-apart-the-energizer-trojan-part-2-runtime-analysis'>Part 2: runtime analysis</a> (windbg)</li>
 <li><a href='/2010/taking-apart-the-energizer-trojan-part-3-disassembling'>Part 3: disassembling</a> (ida)</li>
 <li><a href='/2010/taking-apart-the-energizer-trojan-part-4-writing-a-probe'>Part 4: generating probes</a> (nmap)</li>
</ul>

<h2>Step 0: You will need...</h2>
To follow along, you'll need the following (all free, except for Windows itself):
<ul>
 <li>A disposable Windows computer to infect (probably on VMWare)</li>
 <li><a href='http://www.microsoft.com/whdc/devtools/debugging/installx86.Mspx'>Debugging Tools for Windows</a> (I used 6.11.1.404)</li>
 <li><a href='http://www.hex-rays.com/idapro/idadownfreeware.htm'>IDA (free)</a></li>
 <li><a href='http://nmap.org'>Nmap</a></li>
 <li>A basic understanding of C and x86 assembly would be an asset. &lt;shamelessplug&gt;Check out the <a href='http://www.skullsecurity.org/wiki/index.php/Assembly'>reverse engineering guide I wrote</a>&lt;/shamelessplug&gt;</li>
 <li>A basic understanding of the Linux commandline (gcc, pipes, etc)</li>
</ul>


<h2>Infect a test machine</h2>
The goal of this step is, obviously, to infect a test system with the Energizer Trojan.

Strictly speaking, this isn't necessary. You can do a fine job understanding this sample without actually infecting yourself. That being said, this Trojan appears to be fairly safe, as far as malware goes, so it's a good one to play with. I <em>strongly recommend against</em> installing this on anything other than a throwaway computer (I used VMWare). Do <strong>not</strong> install this on anything real. Ever. Seriously!

If you're good and sure this is what you really want to do, grab the file <a href='http://downloads.skullsecurity.org/MALWARE/EnergizerTrojan-MALWARE.zip'>here</a>:

<img src='/blogdata/usbcharger-01-download.png'>

Then extract the installation file, <strong>UsbCharger_setup_v1_1_1.exe</strong> (<strong>arucer.dll</strong> isn't necessary yet). The password for the zip archive is "infected", and by typing it in you promise to understand the risks of dealing with malware:
<img src='/blogdata/usbcharger-02-infected.png'>

Naturally, make sure you turn off antivirus software before extracting it. In fact you shouldn't even be running antivirus because your system shouldn't even be connected to the network!

Perform a typical install (ie, hit 'next' till it stops asking you questions). Once you've finished the installation, verify that the backdoor is listening on port 7777 by running "cmd.exe" and running "netstat -an":
<img src='/blogdata/usbcharger-04-netstat.png'>

Congratulations! Your system is now backdoored. To continue reading, go to <a href='/blog/?p=645'>Part 2: runtime analysis</a>
