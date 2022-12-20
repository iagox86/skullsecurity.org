---
id: 752
title: 'Confidential Information in the Cloud'
date: '2010-05-05T09:43:16-05:00'
author: 'Matt Gardenghi'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=752'
permalink: /2010/confidential-information-in-the-cloud
categories:
    - Hacking
tags:
    - Cloud
    - exploitation
    - 'Matt Gardenghi'
    - SaaS
    - Security
    - VMWare
---

<em>This is another special blog written by <a href='http://twitter.com/matt_gardenghi'>Matt Gardenghi</a>!</em> 

My boss passed around a document about database security in the cloud.  It raised issues about proper monitoring of the DB, but offered no solutions.

This got me thinking.  I hate it when that happens.  Its like an automatic "boss button" that I can't switch off.  /gah

For the sake of argument, let's assume we are discussing VMs hosted on some provider's (Amazon) VMWare ESX cluster.  This could really apply to any VM on any company's specific VM host, but VMWare is big, popular, and a good basis to work from.  Let's say, some marketing exec bought a package that would hold data on a machine in the cloud.  (You may shoot him later; right now, you have to deal with the issues of integration into your secure environment.)
<!--more-->
Now let's suppose that you do not have enough machines to warrant a private cluster.  You will be sharing a cluster with unknown parties.  Fun!  (Ant-acid is found in aisle 5.)

After reading this document, my mind immediately ran to the story of Kevin Mitnick's hacked website.  You may recall that the headlines proclaimed that Mitnick was hacked, when that is only true in the strictest sense.  In reality, it was a shared host, and one of the other sites was running old code and was hacked.  That hack granted the attacker access to modify Mitnick's site.

OK, but are you really at risk this way?  We're talking about VMs here not shared hosting on a poorly configured LAMP stack.   But, surely you've heard of <a href="http://lists.vmware.com/pipermail/security-announce/2009/000055.html">Guest -&gt; Host</a> exploits?  And since this is publicly obtainable software, one *could* setup a duplicate environment and fuzz away at it....  (Not that any <a href="http://en.wikipedia.org/wiki/Russian_Business_Network">entity</a> would do that, of course.)

So theoretically, one of the other unknown/untrusted Guests could use a zero day exploit to compromise the Host.  Then they could compromise all of the co-located Guests on the box.  Cheery thought....  How would you know?  Since they are essentially performing a "man in the middle," the attacker could just watch your traffic and never touch your machine.  All of those techniques for modifying data on the wire come trudging depressingly back to mind.  You couldn't trust the data coming from the user or going to the user.

Further, if the ESX host is compromised, every machine that VMotioned over to it could be compromised.  Every machine that VMotioned off could then run the zero day against a new host.  This would get an entire cluster and possibly migrate to other clusters (though much less likely).

Now one might ask "how" a malicious user/competitor/etc would locate your server in Amazon's cloud and target your machine.  Cue stage right: a paper on doing that very <a href="http://cseweb.ucsd.edu/~hovav/dist/cloudsec.pdf">thing (pdf)</a>.

So now we are looking at 1) an attacker can find your machine, 2) an attacker could instigate Guest -&gt; Host exploits.  Are you still certain you want to put your data in the cloud?  Ugh.  I can't think of one good reason to do this on a public cloud hosting service.

I know that this is more of a theoretical post and not like Ron's usual posts detailing specific exploitation or research, but I'm interested in your comments.  Am I off base in this reasoning (has happened once or twice before - according to my wife anyway).  What are your thoughts?  Is it worse than I suspect or am I over-reacting?
