---
id: 276
title: 'WebDAV Scanning with Nmap'
date: '2009-05-19T18:39:29-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=276'
permalink: '/?p=276'
---

Greetings!

This morning I heard ([from the security-basics mailing list](http://www.securityfocus.com/archive/105/503536/30/30/threaded), of all places) that there's a zero-day vulnerability going around for WebDAV on Windows 2003. I always like a good vulnerability early in the week, so I decided to write an Nmap script to find it!

The first open script I found was [Metasploit's](http://metasploit.com:55555/EXPLOITS?MODE=SELECT&MODULE=iis50_webdav_ntdll), so I had a look at how that works. It was so simple, I didn't even have to look at the source -- a packet capture was enough.

## How do I use it?

At a high level, all you need to do is [Update Nmap from SVN](http://nmap.org/book/install.html#inst-svn) and run it with the following command:

```
--script=http-webdav-unicode-bypass
```

In more detail...

### Obtaining Nmap from SVN

Run the following command:

```
svn co --username guest --password "" svn://svn.insecure.org/nmap/
```

Then compile it:

```
cd nmap
./configure
make
sudo make install
```

### What if I don't have SVN?

Then you're doing it the hard way...

1. Make sure you're at [  
  Nmap 4.85 beta 9](http://nmap.org/download.html) or higher.
2. Find the script http.lua. It'll be in a folder called 'nselib'; for example, /usr/local/share/nmap/nselib/http.lua. Replace it with [this version](/blogdata/http.lua).
3. In that folder (nselib), there's a directory called 'data'. Put [folders.lst](/blogdata/folders.lst) in it.
4. Go up one directory, and there should be a directory called 'scripts'; for example, /usr/local/share/nmap/scripts. Put [http-webdav-unicode-bypass.nse](/blogdata/http-webdav-unicode-bypass.nse) in it.

Once you've done all that, you're good to go.

### How do I run it?

Running it is as simple as running Nmap itself. Here's the simplest case:

```
nmap -sV --script=http-webdav-unicode-bypass <target>
```

Every port running HTTP should be probed, but it'll take awhile. For a quicker check, try this:

```
nmap -p80,8080 --script=http-webdav-unicode-bypass <target>
```

But keep in mind that it'll only check the two most common ports for Web servers.

## How does it work?

This is the part I like -- how does it work?

Well, the answer is simple -- it works the same as the [Metasploit Auxiliary module](http://metasploit.com:55555/EXPLOITS?MODE=SELECT&MODULE=iis50_webdav_ntdll). Here's what it does:

### Step 1: Find a password protected folder

I have a great big list of folders from a long time ago. I honestly don't know where I got it from, but if you created it and want credit, just hit me up. If you created it and you're pissed off that I stole it.. well, don't hit me up. :) -- But seriously, I don't want to take away anybody's credit, so let me know.

Anyway, it checks the [error code](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html) for each folder. If the error is 404 Not Found or 200 OK, we don't care. In fact, we care about very little -- we're only looking for one error code: 401 Unauthorized.

### Exploit it!

After we find a password-protected folder, there's only one thing left to do: exploit it! This is done by putting a Unicode-encoded string at the beginning of the URL. Thus, "/private" becomes "/%c0afprivate". If the error remains 401 Unauthorized, the server is not vulnerable (it may be non-IIS6, or it may not be using WebDAV). If the error becomes 207 Multi-status, we're vulnerable! That's it!

The script will list all folders found to be vulnerable.

## How do I exploit it?

That's a great question! But, my answer is a cop out right now: I'll get back to you. I suspect that it's possible (and easy) to exploit with free tools, such as [Paros](http://www.parosproxy.org/) and the freely available portion of [Burp Suite](http://portswigger.net/suite/), but I haven't had a chance to try it out. When I do, I'll post a new blog!