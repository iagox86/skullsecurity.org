---
title: 'Wiki: Tools (Hacking)'
author: ron
layout: wiki
permalink: "/wiki/Tools_(Hacking)"
date: '2024-08-04T15:51:38-04:00'
---

## Useful tools {#useful_tools}

This is my attempt to maintain a list of tools. I might eventually sort it by OS or purpose or whatever, but eh? Note that I\'m not including wireless tools in this list. So, in no particular order, \...

### General (uncategorized) {#general_uncategorized}

-   [nmap](http://www.insecure.org)
-   [nessus](http://www.nessus.org)
-   [metasploit](http://www.metasploit.com)
-   [hping3](http://www.hping.org/)
-   [netcat](http://netcat.sourceforge.net/)
-   [wireshark](http://www.wireshark.org) (ethereal)
-   [putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/)
-   [pstools](http://technet.microsoft.com/en-us/sysinternals/bb896649.aspx)
-   [RegMon](http://technet.microsoft.com/en-us/sysinternals/bb896652.aspx)/[FileMon](http://technet.microsoft.com/en-us/sysinternals/bb896642.aspx)/[procmon](http://technet.microsoft.com/en-us/sysinternals/bb896645.aspx) (from sysinternals)
-   [unix-privesc-check](http://pentestmonkey.net/tools/unix-privesc-check/)
-   [amap](http://freeworld.thc.org/thc-amap/)
-   [xprobe2](http://xprobe.sourceforge.net/)
-   [ettercap](http://ettercap.sourceforge.net/)
-   [BiLE.pl](http://www.vulnerabilityassessment.co.uk/bile.htm)
-   [LfT](http://www.askapache.com/tools/lft-traceroute-tool.html)
-   [Wireshark SSL cracker](http://www.lucianobello.com.ar/exploiting_DSA-1571/)
-   [gsecdump](http://www.truesec.com/PublicStore/catalog/categoryinfo.aspx?cid=223)
-   [p0f](http://lcamtuf.coredump.cx/p0f.shtml)
-   [nbtscan](http://www.inetcat.net/software/nbtscan.html)

### Enumeration/Passwords

-   user2sid/sid2user
-   enum
-   fgdump
-   pwdump
-   cain&able
-   rcrack (+tables)
-   john
-   hydra
    -   libssh2 0.11 (http://0xbadc0de.be/libssh/libssh-0.11.tgz)
-   pshtoolkit (pass-the-hash toolkit)
-   samba (w/ hash passing)
    -   Slackware source: <http://slackware.mirrors.tds.net/pub/slackware/slackware-12.1/source/n/samba/>
    -   Patch: <http://www.foofus.net/jmk/passhash.html>
-   [SQLHack](http://sqlhack.com/poc.html) (to crack MySQL old_password entries)

### Web

-   DirBuster (http://www.owasp.org/index.php/Category:OWASP_DirBuster_Project)
-   nikto.pl
-   paros
-   Malzilla (http://malzilla.sourceforge.net/)

## Stuff to investigate {#stuff_to_investigate}

-   SMBProxy (http://www.cqure.net/wp/11/)

## Useful Non-metasploit Exploits {#useful_non_metasploit_exploits}

-   vmsplice (http://www.milw0rm.com/exploits/5093)
    -   Works well against Fedora Core 8

## Firefox Addons {#firefox_addons}

I don\'t actually use all these on a regular basis, but I found some on another site.

-   [Add & Edit Cookies](https://addons.mozilla.org/en-US/firefox/addon/573)
-   [Firebug](https://addons.mozilla.org/en-US/firefox/addon/1843)
-   [Foxy Proxy](https://addons.mozilla.org/en-US/firefox/addon/2464)
-   [Noscript](https://addons.mozilla.org/en-US/firefox/addon/722)
-   [Server Spy](https://addons.mozilla.org/en-US/firefox/addon/2036)
-   [Tamper Data](https://addons.mozilla.org/en-US/firefox/addon/966)
-   [User Agent Switcher](https://addons.mozilla.org/en-US/firefox/addon/59)
-   [Web Developer](https://addons.mozilla.org/en-US/firefox/addon/60)
-   [SSL Blacklist](http://codefromthe70s.org/sslblacklist.aspx)
-   Firebug
-   Hackbar
-   Header Monitor
-   Poster
-   SQL Inject Me

This is cool enough that I had to link it from somewhere

-   Security Bookmarklets (http://ha.ckers.org/bookmarklets.html)

## Wireless tools {#wireless_tools}

TODO: learn to hack wireless. :)

## Stuff I wrote {#stuff_i_wrote}

-   See [My Projects](My_Projects#Security "wikilink")

## Tools used by an unnamed organization {#tools_used_by_an_unnamed_organization}

-   Achilles Proxy
-   ActivePerl
-   Air Magnet
-   AirSnort
-   Algosec
-   amap
-   Appscan
-   ArCrack
-   Auditor
-   AutoIT
-   Brutus
-   Burp Proxy
-   Burp Suite
-   Cadaver
-   Cai & Abel
-   CAL9000
-   Canvas Framework
-   CIS RAT
-   ClearSight
-   Core Impact
-   cURL
-   Cygwin
-   DAVexplorer
-   DiG
-   Dmitry
-   Dsniff
-   Enum
-   Ettercap
-   Fortify
-   Fping
-   Hping2, Hping3
-   Hunt
-   Hydra
-   ikescan
-   Iptraf
-   Jad
-   JADE Proxy
-   JODE
-   John the Ripper
-   kismet
-   LdapMiner
-   MBSA
-   Metasploit
-   Nbtscan
-   Nemesis
-   Nessus
-   Netcat
-   Net-SNMP
-   NetStumbler
-   Nikto
-   Nmap
-   N-Stealth
-   OAT
-   OpenLDAP
-   OpenVAS
-   OpenVPN
-   Ophcrack
-   Paros
-   Pwdump
-   Python
-   Retina
-   Sandstorm
-   Scapy
-   ScreamingCSS
-   Sing
-   SiVuS
-   SmartProxy
-   Sniffit
-   Snmpscan
-   Solar Winds
-   Stunnel
-   SuperScan
-   Tcpdump
-   Telesweep
-   TSEnum
-   WebCracker
-   Webinspect
-   Wget
-   Wireshark
