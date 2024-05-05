---
id: 348
title: 'Updated: Scanning for Microsoft FTP with Nmap'
date: '2009-09-17T14:29:24-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=348'
permalink: '/?p=348'
---

Hi all,

I [wrote a blog last week](http://www.skullsecurity.org/blog/?p=315) about [scanning for Microsoft FTP with Nmap](http://blog.rootshell.be/2009/09/01/updated-iis-ftp-nmap-script/). In some situations the script I linked to wouldn't work, so I gave it an overhaul and it should work nicely now.

I renamed the script to ftp-capabilities.nse. You can get the new version from svn with the usual commands:

```

$ svn co --username guest --password '' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
# make install
$ nmap -d -p21 --script=ftp-capabilities <target>
</target>
```

Or you can download the current version (as of September 17, 2009) at <http://www.skullsecurity.org/blogdata/ftp-capabilities.nse> (note that that version won't be updated).

The output will simply tell you whether or not it's Windows FTP, and whether or not MKDIR is permitted. It doesn't tell you "vulnerable" or "not vulnerable", because it isn't actually checking for an exploit. Of course, if you let anonymous call MKDIR, you probably have other issues. :)

Happy scanning!  
Ron