---
id: 436
title: 'VM Stealing: The Nmap way (CVE-2009-3733 exploit)'
date: '2010-02-10T14:18:33-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=436
permalink: "/2010/how-to-install-an-nmap-script"
categories:
- nmap
comments_id: '109638342796945812'

---

Greetings! 

If you were at Shmoocon this past weekend, you might remember a talk on Friday, done by Justin Morehouse and Tony Flick, on <a href='http://fyrmassociates.com/tools/gueststealer-v1.pl'>VMWare Guest Stealing</a>. If you don't, you probably started drinking too early. :)
<!--more-->
Anyway, somebody in the audience asked if there was a Nessus or Nmap script to detect this vulnerability. If I was the kind to yell things out, I would have yelled "there will be!" -- and now, there is. It'll be included in the next full version of Nmap, but in the meantime here's how you can do it yourself. 

<strong>Requires:</strong> Nmap 5.10BETA1 or higher (<a href='http://nmap.org/dist/?C=M&O=D'>download directory</a>)

<strong>Script:</strong> <a href='/blogdata/http-vmware-path-vuln.nse'>/blogdata/http-vmware-path-vuln.nse</a>

<strong>Instructions:</strong> <a href='http://www.skullsecurity.org/blog/?p=459'>http://www.skullsecurity.org/blog/?p=459</a>

<img src='/blogdata/installing-scripts-3.png'>

<h2>Details</h2>
This is a vulnerability in the VMWare management interface, which is a Web server. All you have to do is add a bunch of "../" sequences to the URL, and give it your chosen path, and it'll let you grab any file on the filesystem. I'm not kidding, but I wish I was. You can even do the classic: https://x.x.x.x/sdk/%2E%2E/%2E%2E/%2E%2E/%2E%2E/%2E%2E/%2E%2E/etc/passwd

The applicable vulnerability identifiers are: <a href='http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-3733'>CVE-2009-3733</a>, <a href='http://www.vmware.com/security/advisories/VMSA-2009-0015.html'>VMSA-2009-0015</a>. 

The Nmap script simply downloads, parses, and displays the virtual machine inventory (assuming you're in verbose mode -- without verbose, it only prints 'VULNERABLE'). The <a href='http://fyrmassociates.com/tools/gueststealer-v1.pl'>exploit</a> released at Shmoocon will download the full vmware disk (vmdk) file, or you can do it yourself with your browser or wget. 

<h2>Mitigation</h2>
<strong>DO NOT</strong> let anybody have access to the VMWare management interface (the web server). It should be on a separate network. That makes this attack significantly more difficult to perform. 

Other than that, install the patches from <a href='http://www.vmware.com/security/advisories/VMSA-2009-0015.html'>the advisory</a>. 

UPDATE: I forgot to mention the punchline: ESX/ESXi run the Web server as root. /etc/shadow is fair game! 
