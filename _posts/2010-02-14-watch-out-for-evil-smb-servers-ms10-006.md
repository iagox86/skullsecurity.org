---
id: 452
title: 'Watch out for evil SMB servers: MS10-006'
date: '2010-02-14T16:04:14-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=452'
permalink: /2010/watch-out-for-evil-smb-servers-ms10-006
categories:
    - Hacking
    - NetBIOS/SMB
---

Thanks to a <a href='http://www.google.ca/alerts'>Google Alert</a> on my name, I recently found <a href='http://g-laurent.blogspot.com/'>Laurent Gaffié's</a> blog post about <a href='http://g-laurent.blogspot.com/2010/02/more-details-on-ms10-006.html'>MS10-006</a> (<a href='http://blogs.technet.com/srd/archive/2010/02/09/ms10-006-and-ms10-012-smb-security-bulletins.aspx'>Microsoft Technet link</a>). 
<!--more-->
I found this vulnerability interesting because this style is something I've been thinking about for a couple years. We (in the industry) have done all kinds of work wringing every last bug out of server implementations, but how many people have really scrutinized client implementations (besides browsers, I mean). 

MS10-006 is a vulnerability in the SMB <em>client</em> that can be exploited by connecting to a malicious <em>server</em>. So how do you exploit something like that?

Well, as Laurent mentioned, I wrote a tool awhile back called <a href='http://www.skullsecurity.org/wiki/index.php/Nbtool'>Nbtool</a> (specifically, nbpoison or, in the upcoming release, nbsniff) that will intercept NetBIOS requests on the local network and respond with a chosen address. If the user is trying to access a local resource using NetBIOS name lookups, it becomes a race condition for the attacker. 

Another likely avenue of attack I see is against so-called "road warriors", who bring their laptops to conferences, hotels, coffee shops, and other untrusted networks. If those laptops try accessing local resources, such as a file share, it will obviously fail (unless they're connected to their VPN already). But when the DNS (or WINS) lookup fails, they'll fall back to using broadcast NetBIOS lookups and me, with <a href='http://www.skullsecurity.org/wiki/index.php/Nbtool'>Nbtool</a> ready, can send them a malicious address. And when they try connecting to my evil fileshare, I can send back my special MS10-006 exploit. Win!

For what it's worth, I was on a public network earlier this week and decided to see if sending NetBIOS responses pointing to me for all requests would provoke any 445 calls to my host -- it did. So this is definitely a possible vector. Now we just wait for the exploit! 
