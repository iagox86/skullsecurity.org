---
id: 228
title: 'Updated Conficker detection'
date: '2009-04-02T07:57:37-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=228'
permalink: /2009/updated-conficker-detection
categories:
    - Malware
    - NetBIOS/SMB
---

Morning, all!

Last night Fyodor and crew rolled out [Nmap 4.85beta7](http://insecure.org/). This was because some folks from the Honeynet Project discovered a false negative (showed no infection where an infection was present), which was then confirmed by Tenable. We decided to be on the safe side, and updated our checks.  
  
4.85 also contains several bugfixes and enhancements, such as improved error messages. We tried to find the biggest issues people were having and solve them. Here are the full release notes from Fyodor:

```
Nmap 4.85BETA7 [2009-04-1]

o Improvements to the Conficker detection script (smb-check-vulns):
  o Treat any NetPathCanonicalize()return code of 0x57 as indicative
    of a vulnerable machine. We (and all the other scanners) used to
    require the 0x57 return code as well as a canonicalized path
    string including 0x5c450000.  Tenable confirmed an infected
    system which returned a 0x00000000 path, so we now treat any
    return code of 0x57 as indicative of an infection. [Ron]
  o Add workaround for crash in older versions of OpenSSL which would
    occur when we received a blank authentication challenge string
    from the server.  The error looked like: evp_enc.c(282): OpenSSL
    internal error, assertion failed: inl > 0". [Ron]
  o Add helpful text for the two most common errors seen in the
    Conficker check in smb-check-vulns.nse.  So instead of saying
    things like "Error: NT_STATUS_ACCESS_DENIED", output is like:
    |  Conficker: Likely CLEAN; access was denied.
    |  |  If you have a login, try using --script-args=smbuser=xxx,smbpass=yyy
    |  |  (replace xxx and yyy with your username and password). Also try
    |  |_ smbdomain=zzz if you know the domain. (Error NT_STATUS_ACCESS_DENIED)
    The other improved message is for
    NT_STATUS_OBJECT_NAME_NOT_FOUND. [David]

o The NSEDoc portal at http://nmap.org/nsedoc/ now provides download
  links from the script and module pages to browse or download recent versions
  of the code.  It isn't quite as up-to-date as obtaining them from
  svn directly, but may be more convenient. For an example, see
  http://nmap.org/nsedoc/scripts/smb-check-vulns.html. [David, Fyodor]

o A copy of the Nmap public svn repository (/nmap, plus its zenmap,
  nsock, nbase, and ncat externals) is now available at
  http://nmap.org/svn/.  We'll be updating this regularly, but it may
  be slightly behind the SVN version.  This is particularly useful
  when you need to link to files in the tree, since browsers generally
  don't handle svn:// repository links. [Fyodor]

o Declare a couple msrpc.lua variables as local to avoid a potential
  deadlock between smb-server-stats.nse instances. [Ron]

Enjoy!
-Fyodor
```

If you have any other issues, please let us know (either here or, better, on the nmap-dev mailing list), and we'll do our best to fix them.

## How does this check work?

Some of you are probably wondering how this check works. Since I prefer to write technical details anyways (I'd make a bad magician ;) ), let's find out!

There's a remote Windows function called NetPathCanonicalize() that can be accessed through the BROWSER service. It takes a path as a parameter, attempts to canonicalize it, and returns the canonicalized version. This function was the target of the notorious MS08-067 patch -- certain parameters could corrupt memory and crash it.

One of Conficker's primary propagation methods was this exact vulnerability -- MS08-067. In an attempt to prevent other infections, Conficker hooks NetPathCanonicalize() and effectively patches the function itself.

Before Microsoft released their patch, the function would either return an attempted canonicalization and no error code, or it would crash and not return at all (those are the checks I do in smb-check-vulns.nse if safechecks are disabled). After MS08-067 was applied, the evil-looking strings would return NT\_STATUS\_WERR\_INVALID\_NAME (0x7b or 123) as an error code. Conficker's patch, however, returns 0x57 -- an invalid error code -- and a distinct signature.

So what's this mean? It means we can send an invalid path to NetPathCanonicalize() and check the return value -- no error (or timeout) means unpatched, 0x7b means patched, and 0x57 means Conficker.

And it's as simple as that :)

Ron