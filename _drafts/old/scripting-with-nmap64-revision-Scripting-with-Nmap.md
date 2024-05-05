---
id: 65
title: 'Scripting with Nmap'
date: '2008-09-12T19:01:09-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=65'
permalink: '/?p=65'
---

As you can see from my past few posts, I've been working on implementing an SMB client in C. Once I got that into a stable state, I decided to pursue the second part of my goal for a bit -- porting that code over to an Nmap script. Never having used Lua before, this was a little intimidating. So, to get my feet wet, I modified an existing script -- netbios-smb-os-discovery.nse -- to have a little bit of extra functionality:

```

```