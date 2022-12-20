---
id: 209
title: 'Scanning for Conficker with Nmap'
date: '2009-03-30T11:49:09-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=209'
permalink: /2009/scanning-for-conficker-with-nmap
categories:
    - malware
    - smb
---

Using Nmap to scan for the famous Conficker worm. 
<!--more-->
<b>&lt;Update&gt;</b>
Nmap 4.85beta5 has all the scripts included, download it at <a href='http://nmap.org/download.html'>http://nmap.org/download.html</a>. 

You'll still need to run a scan:
<pre>nmap --script=smb-check-vulns --script-args=safe=1 -p445 -d &lt;target&gt;</pre>
<b>&lt;/Update&gt;</b>

<b>&lt;Update 2&gt;</b>
If you're having an OpenSSL problem, read this! 

OpenSSL isn't included by default in the Nmap RPMs, and I wasn't properly checking for that in my scripts. Fyodor will have a beta5 RPM up tonight, which will fix that issue. 

Until then, you have two options:
1. Use a source RPM
2. Compile straight from source, from the svn 
<b>&lt;/Update 2&gt;</b>

<b>&lt;Update 3&gt;</b>
If you're still having OpenSSL issues, try installing <strong>openssl-dev</strong> package, and install Nmap from source. Or, download the latest rpm (beta5) or svn version -- they have fixed the issue altogether (OpenSSL is no longer required!)

Further, if you're having an issue with error messages, this great post by <strong>Trevor2</strong> might help:
<pre>
NT_STATUS_OBJECT_NAME_NOT_FOUND can be returned if the browser service is disabled. There are at least two ways that can happen:
1) The service itself is disabled in the services list.
2) The registry key HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Browser\Parameters\MaintainServerList is set to Off/False/No rather than Auto or yes.
On these systems, if you reenable the browser service, then the test will complete.

There are probably many other reasons why NT_STATUS_OBJECT_NAME_NOT_FOUND can be returned (e.g. not a windows OS, possibly infected) but I have not confirmed these.
</pre>

Furthermore, this error will occur against on Windows NT. 
<b>&lt;/Update 3&gt;</b>

Hot on the coattails of the <a href='http://iv.cs.uni-bonn.de/wg/cs/applications/containing-conficker'>Simple Conficker Scanner</a>, I've added detection for Conficker to Nmap. Currently, there are two ways of doing this -- you can check out the SVN version of Nmap and compile from source, or you can update the three necessary files.

<h2> Update from SVN</h2>

If you're on a Unix-like system, this is probably the easiest way. You can install it either system-wide or in a folder. Here is the system-wide command:
<pre>$ svn co --username=guest --password='' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
$ sudo make install
$ nmap --script=smb-check-vulns --script-args=safe=1 -p445 -d &lt;target&gt;</pre>

If you prefer to run it from a local folder, use the following commands:
<pre>$ svn co --username=guest --password='' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
$ export NMAPDIR=.
$ ./nmap --script=smb-check-vulns --script-args=safe=1 -p445 -d &lt;target&gt;</pre>

<h2>Update just the files</h2>
If you're on Windows, or don't want to compile from source, you can install the three datafiles. 

First, make sure you're running Nmap 4.85beta4. That's the latest beta version. Then, download this file:
<ul><li><a href='http://www.skullsecurity.org/blogdata/smb-check-vulns.nse'>http://www.skullsecurity.org/blogdata/smb-check-vulns.nse</a></li></ul>
And place it in the "scripts" folder (see below).

Then, download these files:
<ul><li>http://www.skullsecurity.org/blogdata/msrpc.lua</li>
<li>http://www.skullsecurity.org/blogdata/smb.lua</li></ul>
And place them in the "nselib" folder (see below). 

<h3>Where are the folders?</h3>
On Linux, try /usr/share/nmap/ or /usr/local/share/nmap or even /opt/share/nmap. 

On Windows, try c:\program files\nmap

If all else fails, the scripts folder will contain a bunch of .nse files and the nselib folder will contain a bunch of lua files. Try searching your drive for smb-check-vulns.nse and msrpc.lua, and replace those. 

<h2>Conclusion</h2>
Hopefully that helps! If you have any problems or questions, don't hesitate to contact me! My name is Ron, and my email domain is @skullsecurity.net. 

Ron
