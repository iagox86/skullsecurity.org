---
id: 346
title: 'Updated: Scanning for Microsoft FTP with Nmap'
date: '2009-09-17T14:27:40-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=346'
permalink: '/?p=346'
---

Hi all,

I [wrote a blog last week](http://www.skullsecurity.org/blog/?p=315)$ svn co --username guest --password '' svn://svn.insecure.org/nmap $ cd nmap $ ./configure && make # make install $ nmap -d -p21 --script=ftp-capabilities <target>Or you can download the current version (as of September 17, 2009) at <http://www.skullsecurity.org/blogdata/ftp-capabilities.nse> (note that that version won't be updated).

The output will simply tell you whether or not it's Windows FTP, and whether or not MKDIR is permitted. It doesn't tell you "vulnerable" or

</target>