---
id: 627
title: 'Taking apart the Energizer trojan &#8211; Part 1: setup'
date: '2010-03-25T09:13:24-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=627'
permalink: /2010/taking-apart-the-energizer-trojan-part-1-setup
categories:
    - Malware
    - Nmap
    - 'Reverse Engineering'
---

Hey all,

As most of you know, a Trojan was [recently discovered](http://www.theregister.co.uk/2010/03/08/energizer_trojan/) in the software for Energizer's USB battery charger. Following its release, I wrote an [Nmap probe](http://www.skullsecurity.org/blog/?p=563) to detect the Trojan and HDMoore wrote a [Metasploit module](http://blog.metasploit.com/2010/03/locate-and-exploit-energizer-trojan.html) to exploit it.

I mentioned in my last post that it was a nice sample to study and learn from. The author made absolutely no attempt to conceal its purpose, once installed, besides a weak XOR encoding for communication. Some conspiracy theorists even think this may have been legitimate management software gone wrong -- and who knows, really? In any case, I offered to write a tutorial on how I wrote the Nmap probe, and had a lot of positive feedback, so here it is!

Just be sure to take this for what it is. This is \*not\* intended to show any new methods or techniques or anything like that. It's a reverse engineering guide targeted, as much as I could, for people who've never opened IDA or Windbg in their lives. I'd love to hear your comments!

## Sections

This tutorial was getting far too long for a single page, so I broke it into four sections:

- **[Part 1: setup](/blog/?p=627)**
- [Part 2: runtime analysis](/blog/?p=645) (windbg)
- [Part 3: disassembling](/blog/?p=647) (ida)
- [Part 4: generating probes](/blog/?p=649) (nmap)

## Step 0: You will need...

To follow along, you'll need the following (all free, except for Windows itself):

- A disposable Windows computer to infect (probably on VMWare)
- [Debugging Tools for Windows](http://www.microsoft.com/whdc/devtools/debugging/installx86.Mspx) (I used 6.11.1.404)
- [IDA (free)](http://www.hex-rays.com/idapro/idadownfreeware.htm)
- [Nmap](http://nmap.org)
- A basic understanding of C and x86 assembly would be an asset. <shamelessplug>Check out the [reverse engineering guide I wrote](http://www.skullsecurity.org/wiki/index.php/Assembly)</shamelessplug>
- A basic understanding of the Linux commandline (gcc, pipes, etc)

## Infect a test machine

The goal of this step is, obviously, to infect a test system with the Energizer Trojan.

Strictly speaking, this isn't necessary. You can do a fine job understanding this sample without actually infecting yourself. That being said, this Trojan appears to be fairly safe, as far as malware goes, so it's a good one to play with. I *strongly recommend against* installing this on anything other than a throwaway computer (I used VMWare). Do **not** install this on anything real. Ever. Seriously!

If you're good and sure this is what you really want to do, grab the file [here](http://downloads.skullsecurity.org/MALWARE/EnergizerTrojan-MALWARE.zip):

![](http://www.skullsecurity.org/blogdata/usbcharger-01-download.png)

Then extract the installation file, **UsbCharger\_setup\_v1\_1\_1.exe** (**arucer.dll** isn't necessary yet). The password for the zip archive is "infected", and by typing it in you promise to understand the risks of dealing with malware:  
![](http://www.skullsecurity.org/blogdata/usbcharger-02-infected.png)

Naturally, make sure you turn off antivirus software before extracting it. In fact you shouldn't even be running antivirus because your system shouldn't even be connected to the network!

Perform a typical install (ie, hit 'next' till it stops asking you questions). Once you've finished the installation, verify that the backdoor is listening on port 7777 by running "cmd.exe" and running "netstat -an":  
![](http://www.skullsecurity.org/blogdata/usbcharger-04-netstat.png)

Congratulations! Your system is now backdoored. To continue reading, go to [Part 2: runtime analysis](/blog/?p=645)