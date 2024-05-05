---
id: 791
title: 'Metasploit Express Beta &#8211; First Look'
date: '2010-05-11T09:16:06-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=791'
permalink: '/?p=791'
---

*This post was written by [Matt Gardenghi](http://www.twitter.com/matt_gardenghi)*

This is just initial impressions of a beta product.

I've been playing with this for about a week now in an internal network. I have a dedicated box running Ubuntu 10.04 and Metasploit Express. I've noticed that Express loves CPU time but is much less caring about RAM. It's also not multi-threaded. I'd recommend a dual core box as Express will peg one core. If you want to do anything else while Express is running, you need two cores. Still, Express does not require an expensive RAM build out. I've run top plenty of times and seen that the RAM usage remains low even when I've had 170+ shells running. :-p Hopefully, we'll get multi-threading down the road. When multiple tasks are running simultaneously, this lack of multi-threading becomes an issue. Everything slows to a crawl.

Anyway speed issues aside, Express is very slick. The interface is clean and minimalistic. At first, things are a little to minimalistic. It took me a while to realize that I had tasks running; they appeared to start and finish, but had actually moved to the task list. Express gives subtle hints about tasks running, sessions opened, and updated system information as seen in this screenshot (the blue circles with numbers).

![](/blogdata/Express1.PNG "Express")

There are a lot of features to talk about, but let me simplify it this way: As long as you are willing to run generic scans, exploits, etc, Express will simplify your pentesting.

Wait, don't go yet. You can still do quite a bit with this. (And from my communication with the developers, we will eventually receive the ability to tweak the defaults.) Let's suppose you want to see if anyone is running default usernames and passwords across a large organization. Express will do that (and give you shell if possible). Express handles large groups of repetitive tasks well.

Down the road, it would be nice if users can change the defaults if they see a need (maybe your AV picks up this particular default). Still, as a general rule, the defaults are set because they work in most instances. You may never need to change anything. (You can run specific modules from the Metasploit kit.)

There are times when the more advanced Metasploit features are needed. These can be accessed from the console if you tell Metasploit to use the same Postgres DB. I haven't got that working yet, probably user error.

Anyway, having played with this for a while now, I can't see it replacing my usual toolset. I'm seldom given an internal IP to test and am seldom allowed to perform social engineering. So, I'm not certain how much use this will be to me as my access usually starts with a website flaw (file upload, poor password) or router misconfiguration. Now if I could set up multi/handler, execute a payload (social engineering, file upload flaw or such), and then pivot into the organization..., well that would make a BIG difference.

I can see this being worth the price for anyone on an internal security team. At the least, this will grab all the low hanging fruit and then will grant you the information you need to perform more in depth testing.

This is a good tool for those network admins who also wear the security hat. They can run NeXpose or Nessus across their environment, import it into Express and demonstrate the need to fix these holes.

Check it out. And once we leave beta, I'm hoping to write a full review about the various features. Questions? Drop me a line or post a comment and I'll see what I can answer for you.

There is a high likelihood that you will find this tool useful in your security testing work.