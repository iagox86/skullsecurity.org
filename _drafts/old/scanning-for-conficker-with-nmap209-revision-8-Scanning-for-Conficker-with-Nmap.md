---
id: 218
title: 'Scanning for Conficker with Nmap'
date: '2009-03-30T16:39:40-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=218'
permalink: '/?p=218'
---

**<Update>**  
Nmap 4.85beta5 has all the scripts included, download it at <http://nmap.org/download.html>.

You'll still need to run a scan:

```
nmap --script=smb-check-vulns --script-args=safe=1 -p445 -d <target>
```

**</Update>**

**<Update 2>**  
If you're having an OpenSSL problem, read this!

OpenSSL isn't included by default in the Nmap RPMs, and I wasn't properly checking for that in my scripts. Fyodor will have a beta5 RPM up tonight, which will fix that issue.

Until then, you have two options:  
1\. Use a source RPM  
2\. Compile straight from source, from the svn  
**</Update 2>**

Hot on the coattails of the [Simple Conficker Scanner](http://iv.cs.uni-bonn.de/wg/cs/applications/containing-conficker), I've added detection for Conficker to Nmap. Currently, there are two ways of doing this -- you can check out the SVN version of Nmap and compile from source, or you can update the three necessary files.

##  Update from SVN

If you're on a Unix-like system, this is probably the easiest way. You can install it either system-wide or in a folder. Here is the system-wide command:

```
$ svn co --username=guest --password='' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
$ sudo make install
$ nmap --script=smb-check-vulns --script-args=safe=1 -p445 -d <target>
```

If you prefer to run it from a local folder, use the following commands:

```
$ svn co --username=guest --password='' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
$ export NMAPDIR=.
$ ./nmap --script=smb-check-vulns --script-args=safe=1 -p445 -d <target>
```

## Update just the files

If you're on Windows, or don't want to compile from source, you can install the three datafiles.

First, make sure you're running Nmap 4.85beta4. That's the latest beta version. Then, download this file:

- <http://www.skullsecurity.org/blogdata/smb-check-vulns.nse>

And place it in the "scripts" folder (see below).

Then, download these files:

- http://www.skullsecurity.org/blogdata/msrpc.lua
- http://www.skullsecurity.org/blogdata/smb.lua

And place them in the "nselib" folder (see below).

### Where are the folders?

On Linux, try /usr/share/nmap/ or /usr/local/share/nmap or even /opt/share/nmap.

On Windows, try c:program filesnmap

If all else fails, the scripts folder will contain a bunch of .nse files and the nselib folder will contain a bunch of lua files. Try searching your drive for smb-check-vulns.nse and msrpc.lua, and replace those.

## Conclusion

Hopefully that helps! If you have any problems or questions, don't hesitate to contact me! My name is Ron, and my email domain is @skullsecurity.net.

Ron