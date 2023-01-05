---
id: 931
title: Finding Mapped Drives with Meterpreter
date: '2010-09-01T09:16:20-05:00'
author: mtgarden
layout: post
guid: http://www.skullsecurity.org/blog/?p=931
permalink: "/2010/finding-mapped-drives-with-meterpreter"
categories:
- hacking
comments_id: '109638354573036282'

---

This post written by <a href='https://twitter.com/matt_gardenghi'>Matt Gardenghi</a>
---------
This is going to be a series of short "how to" articles so that I have a resource when I forget how I did something. Your benefit from this post is incidental to my desire to have a resource I can reach when I've had a brain cloud.

When cracking into a computer via Metasploit, I often (OK, usually) install meterpreter.  It just makes life simpler.  Well, the other day, I was chatting with @jcran about my inability to get access to network drives on a Novell network.  The problem is that Novell maps drives in a sorta funny method compared to Active Directory. At least that was my thought.  The problem generally is that Novell handles things extremely differently then AD, that I assumed that things would be different.  #facepalm
<!--more-->
Anyhow, @jcran pointed out the following things to me:

1) If you are SYSTEM, you won't have the credentials of the logged in user.

2) The drives are mapped to the user and SYSTEM isn't a user with mapped drives.

3) The process is the same for finding mapped drives in both Novell and AD.

The procedure for accessing the user's drives goes like this for the SYSTEM user at the Meterpreter prompt:

1) run migrate explorer.exe (this migrates you to the explorer process and gives you the logged in user's privileges.)

2) getuid (verify that you are now the user)

3) run get_env (this dumps the environmental variables including the mapped drives)

4) cd &lt;drive letter&gt; (browse the drives at your leisure)

Simple enough.  Now if only I'd thought it out first....
<img src="/blogdata/file_browsing_example.png" alt="example of file browsing"/>
