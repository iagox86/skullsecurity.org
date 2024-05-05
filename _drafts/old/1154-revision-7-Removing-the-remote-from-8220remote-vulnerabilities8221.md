---
id: 1235
title: 'Removing the remote from &#8220;remote vulnerabilities&#8221;'
date: '2011-12-19T18:38:22-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/2011/1154-revision-7'
permalink: '/?p=1235'
---

===============  
~/stuff/blogs/remote\_vuln  
===============

Hey everybody,

For this blog, I thought I'd reveal a trick I use for fuzzing, writing exploits (or, more commonly, vulnerability tests) for vulnerabilities. It removes a lot of the speed, randomness, and crashing issues that can sometimes make vulnerability discovery (or, in some cases, fuzzing) annoying. It isn't something particularly revolutionary, but hopefully it'll teach you something new!

To pick a vulnerability that this works well on, let's go with a blast from the past: ms08-067. As I'm sure you all remember, ms08-067 was a remotely exploitable memory corruption vulnerability that could be triggered over SMB.

## Finding the bug

Although this can be used for fuzzing, in this particular example we're going to use a published vulnerability report. The vulnerability that ms08-067 patches is [kb958644](http://support.microsoft.com/kb/958644). According to that page, the file of interest is netapi32.dll. So I'm going to grab a version of it both before and after the ms08-067 patch is applied. If you're following along, I'm using a copy from a fully updated (other than ms08-067) install of Windows 2003 Enterprise x86.

ms08-067

ms10-101  
\- Doesn't work on a .exe file