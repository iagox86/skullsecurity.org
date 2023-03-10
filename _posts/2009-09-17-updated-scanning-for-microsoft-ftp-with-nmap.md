---
id: 345
title: 'Updated: Scanning for Microsoft FTP with Nmap'
date: '2009-09-17T14:30:06-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=345
permalink: "/2009/updated-scanning-for-microsoft-ftp-with-nmap"
categories:
- nmap
- tools
comments_id: '109638338343103008'

---

Hi all,

I <a href='http://www.skullsecurity.org/blog/?p=315'>wrote a blog last week</a> about <a href='http://blog.rootshell.be/2009/09/01/updated-iis-ftp-nmap-script/'>scanning for Microsoft FTP with Nmap</a>. In some situations the script I linked to wouldn't work, so I gave it an overhaul and it should work nicely now. 
<!--more-->
I renamed the script to ftp-capabilities.nse. You can get the new version from svn with the usual commands:
<pre>
$ svn co --username guest --password '' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
# make install
$ nmap -d -p21 --script=ftp-capabilities <target>
</pre>

Or you can download the current version (as of September 17, 2009) at <a href='/blogdata/ftp-capabilities.nse'>/blogdata/ftp-capabilities.nse</a> (note that that version won't be updated). 

The output will simply tell you whether or not it's Windows FTP, and whether or not MKDIR is permitted. It doesn't tell you "vulnerable" or "not vulnerable", because it isn't actually checking for an exploit. Of course, if you let anonymous call MKDIR, you probably have other issues. :)

Happy scanning! 
Ron
