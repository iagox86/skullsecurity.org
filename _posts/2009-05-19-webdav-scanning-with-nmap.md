---
id: 271
title: 'WebDAV Scanning with Nmap'
date: '2009-05-19T18:48:32-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=271'
permalink: /2009/webdav-scanning-with-nmap
categories:
    - Hacking
    - Tools
---

Greetings!

This morning I heard (<a href='http://www.securityfocus.com/archive/105/503536/30/30/threaded'>from the security-basics mailing list</a>, of all places) that there's a zero-day vulnerability going around for WebDAV on Windows 2003. I always like a good vulnerability early in the week, so I decided to write an Nmap script to find it!
<!--more-->
The first open script I found was <a href='http://metasploit.com:55555/EXPLOITS?MODE=SELECT&MODULE=iis50_webdav_ntdll'>Metasploit's</a>, so I had a look at how that works. It was so simple, I didn't even have to look at the source -- a packet capture was enough.

<a href='http://nmap.org/nsedoc/scripts/http-iis-webdav-vuln.html'>Read the module documentation</a>

<h2>How do I use it?</h2>
At a high level, all you need to do is <a href='http://nmap.org/book/install.html#inst-svn'>Update Nmap from SVN</a> and run it with the following command:
<pre>--script=http-iis-webdav-vuln</pre>

In more detail...
<h3>Obtaining Nmap from SVN</h3>
Run the following command:
<pre>svn co --username guest --password "" svn://svn.insecure.org/nmap/</pre>

Then compile it:
<pre>cd nmap
./configure
make
sudo make install
</pre>

<h3>What if I don't have SVN?</h3>
Then you're doing it the hard way...
<ol>
<li>Make sure you're at <a href='http://nmap.org/download.html'>
Nmap 4.85 beta 9</a> or higher.</li>
<li>Find the script http.lua. It'll be in a folder called 'nselib'; for example, /usr/local/share/nmap/nselib/http.lua. Replace it with <a href='/blogdata/http.lua'>this version</a>. </li>
<li>In that folder (nselib), there's a directory called 'data'. Put <a href='/blogdata/folders.lst'>folders.lst</a> in it. </li>
<li>Go up one directory, and there should be a directory called 'scripts'; for example, /usr/local/share/nmap/scripts. Put <a href='/blogdata/http-iis-webdav-vuln.nse'>http-iis-webdav-vuln.nse</a> in it. </li>
</ol>
Once you've done all that, you're good to go.

<h3>How do I run it?</h3>
Running it is as simple as running Nmap itself. Here's the simplest case:
<pre>nmap -sV --script=http-iis-webdav-vuln &lt;target&gt;</pre>

Every port running HTTP should be probed, but it'll take awhile. For a quicker check, try this:
<pre>nmap -p80,8080 --script=http-iis-webdav-vuln &lt;target&gt;</pre>

But keep in mind that it'll only check the two most common ports for Web servers.

Finally, if you know the name of a password-protected folder on the system, provide it directly:
<pre>nmap -p80,8080 --script=http-iis-webdav-vuln --script-args=webdavfolder=secret &lt;target&gt;</pre>
or
<pre>nmap -p80,8080 --script=http-iis-webdav-vuln --script-args=webdavfolder=\"my/folder/secret\" &lt;target&gt;</pre>
(note the backslashes -- they may not be required in the future)

<h2>How accurate is it?</h2>
This script <strong>relies on finding a password-protected folder</strong>, so it won't be 100% accurate. I have a list of around 850 common folder names, but that definitely won't find everything.

If you provide a folder name yourself using the webdavfolder argument, you're going to have a lot more luck. As far as I know, once it has the name of a real password-protected folder, it's 100% reliable. The trick is finding one.

Unfortunately, there doesn't appear to be a good way to check if a server has WebDAV enabled. So, there's no easy check that I know of.

<h2>How does it work?</h2>
This is the part I like -- how does it work?

Well, the answer is simple -- it works the same as the <a href='http://metasploit.com:55555/EXPLOITS?MODE=SELECT&MODULE=iis50_webdav_ntdll'>Metasploit Auxiliary module</a>. Here's what it does:
<h3>Step 1: Find a password protected folder</h3>
I have a great big list of folders from a long time ago. I honestly don't know where I got it from, but if you created it and want credit, just hit me up. If you created it and you're pissed off that I stole it.. well, don't hit me up. :) -- But seriously, I don't want to take away anybody's credit, so let me know.

Anyway, it checks the <a href='http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html'>error code</a> for each folder. If the error is 404 Not Found or 200 OK, we don't care. In fact, we care about very little -- we're only looking for one error code: 401 Unauthorized.

<h3>Step 2: Exploit it!</h3>
After we find a password-protected folder, there's only one thing left to do: exploit it! This is done by putting a Unicode-encoded string at the beginning of the URL. Thus, "/private" becomes "/%c0%afprivate". If the error remains 401 Unauthorized, the server is not vulnerable (it may be non-IIS6, or it may not be using WebDAV). If the error becomes 207 Multi-status, we're vulnerable! That's it!

The script will list all folders found to be vulnerable.

<h2>How do I exploit it for real?</h2>
That's a great question! But, my answer is a cop out right now: I'll get back to you. I suspect that it's possible (and easy) to exploit with free tools, such as <a href='http://www.parosproxy.org/'>Paros</a> and the freely available portion of <a href='http://portswigger.net/suite/'>Burp Suite</a>, but I haven't had a chance to try it out. When I do, I'll post a new blog!
