---
id: 436
title: 'VM Stealing: The Nmap way (CVE-2009-3733 exploit)'
date: '2010-02-10T14:18:33-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=436'
permalink: /2010/how-to-install-an-nmap-script
categories:
    - Nmap
---

Greetings!

If you were at Shmoocon this past weekend, you might remember a talk on Friday, done by Justin Morehouse and Tony Flick, on [VMWare Guest Stealing](http://fyrmassociates.com/tools/gueststealer-v1.pl). If you don't, you probably started drinking too early. :)  
  
Anyway, somebody in the audience asked if there was a Nessus or Nmap script to detect this vulnerability. If I was the kind to yell things out, I would have yelled "there will be!" -- and now, there is. It'll be included in the next full version of Nmap, but in the meantime here's how you can do it yourself.

**Requires:** Nmap 5.10BETA1 or higher ([download directory](http://nmap.org/dist/?C=M&O=D))

**Script:** <http://www.skullsecurity.org/blogdata/http-vmware-path-vuln.nse>

**Instructions:** <http://www.skullsecurity.org/blog/?p=459>

![](/blogdata/installing-scripts-3.png)

## Details

This is a vulnerability in the VMWare management interface, which is a Web server. All you have to do is add a bunch of "../" sequences to the URL, and give it your chosen path, and it'll let you grab any file on the filesystem. I'm not kidding, but I wish I was. You can even do the classic: https://x.x.x.x/sdk/%2E%2E/%2E%2E/%2E%2E/%2E%2E/%2E%2E/%2E%2E/etc/passwd

The applicable vulnerability identifiers are: [CVE-2009-3733](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-3733), [VMSA-2009-0015](http://www.vmware.com/security/advisories/VMSA-2009-0015.html).

The Nmap script simply downloads, parses, and displays the virtual machine inventory (assuming you're in verbose mode -- without verbose, it only prints 'VULNERABLE'). The [exploit](http://fyrmassociates.com/tools/gueststealer-v1.pl) released at Shmoocon will download the full vmware disk (vmdk) file, or you can do it yourself with your browser or wget.

## Mitigation

**DO NOT** let anybody have access to the VMWare management interface (the web server). It should be on a separate network. That makes this attack significantly more difficult to perform.

Other than that, install the patches from [the advisory](http://www.vmware.com/security/advisories/VMSA-2009-0015.html).

UPDATE: I forgot to mention the punchline: ESX/ESXi run the Web server as root. /etc/shadow is fair game!