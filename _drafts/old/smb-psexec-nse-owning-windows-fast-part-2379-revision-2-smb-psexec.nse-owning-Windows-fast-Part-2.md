---
id: 381
title: 'smb-psexec.nse: owning Windows, fast (Part 2)'
date: '2009-12-14T14:24:43-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=381'
permalink: '/?p=381'
---

Posts in this series (I'll add links as they're written):

1. [What does smb-psexec do?](/blog/?p=365)
2. **[Sample configurations ("sample.lua")](/blog/?p=365)**
3. Default configuration ("default.lua")
4. Advanced configuration ("pwdump.lua" and "backdoor.lua")
5. Conclusions

## Getting started

Hopefully you all read [last week's post](/blog/?p=365). It's a good introduction on what you need to know about smb-psexec.nse before using it, but I realize it's a little dry in terms of things you can do. I'm hoping to change that this week, though, as I'll be going over a bunch of sample configurations.

For what it's worth, this information is lifted, by and large, from the [NSEDoc](http://nmap.org/nsedoc/scripts/smb-psexec.html) for the script.