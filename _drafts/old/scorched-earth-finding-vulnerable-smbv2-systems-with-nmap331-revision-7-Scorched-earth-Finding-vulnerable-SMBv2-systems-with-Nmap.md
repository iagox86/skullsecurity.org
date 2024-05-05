---
id: 338
title: 'Scorched earth: Finding vulnerable SMBv2 systems with Nmap'
date: '2009-09-14T10:44:07-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=338'
permalink: '/?p=338'
---

Hello once again!

I just finished updating my smb-check-vulns.nse Nmap script to check for the recent [SMBv2 vulnerability](http://www.microsoft.com/technet/security/advisory/975497.mspx), which had a proof-of-concept posted on [full-disclosure](http://seclists.org/fulldisclosure/2009/Sep/0039.html).

**WARNING:** This script will cause vulnerable systems to bluescreen and restart. Do **NOT** run this in a production environment, unless you like angry phonecalls. You have been warned!

With that out of the way, let's look at how to run the script! The easiest way is to check out Nmap's SVN version and run it from there:

```

$ svn co --username guest --password '' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
# make install
$ nmap -d -p445 --script=smb-check-vulns --script-args=unsafe=1 <target>
```

Alternatively, you can skip the "make install" and run it from the current directory. Just run "export NMAPDIR=." first.

Note the "script-args" parameter -- due to the nature of these tests, I opted to require the user to explicitly enable unsafe checks. This may go away in the future, after discussion, but adding it won't hurt.

You should see something like this for a vulnerable server (a lot more if you give -d):

```

$ ./nmap -p445 --script=smb-check-vulns --script-args=unsafe=1 10.x.x.x

Starting Nmap 5.05BETA1 ( http://nmap.org ) at 2009-09-14 10:39 CDT
NSE: Script Scanning completed.
Interesting ports on 10.x.x.x:
PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
|  smb-check-vulns:
|  Conficker: Likely CLEAN; access was denied.
|  |  If you have a login, try using --script-args=smbuser=xxx,smbpass=yyy
|  |  (replace xxx and yyy with your username and password). Also try
|  |_ smbdomain=zzz if you know the domain. (Error NT_STATUS_ACCESS_DENIED)
|_ SMBv2 DoS (CVE-2009-3103): VULNERABLE
```

And that's it!

If you want more details about this vulnerability, this [VRT Blog post](http://vrt-sourcefire.blogspot.com/2009/09/smbv2-quotes-dos-quotes.html) has a great discussion about what's going on behind the scenes.