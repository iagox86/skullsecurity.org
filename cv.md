---
title: Ron's CV
date: '2023-02-17T17:28:24-05:00'
author: ron
layout: page
permalink: "/cv"

---

In 2022, I started doing enough public work that I decided I'd start keeping track of it all in one place. Here you go!

I'm going to update this from time to time, on a best-effort basis. I probably also missed stuff.

# 2023

## Vulnerabilities I Discovered

* Multiple vulnerabilities in Rocket Software UniData and UniVerse - [analysis blog](https://www.rapid7.com/blog/post/2023/03/29/multiple-vulnerabilities-in-rocket-software-unirpc-server-fixed/)
  * [Protocol implementation](https://github.com/rbowes-r7/libneptune)
  * [Metasploit modules](https://github.com/rapid7/metasploit-framework/pull/17832) for CVE-2023-28502 and CVE-2023-28503
  * Vulnerabilities:
    * CVE-2023-28501: Pre-authentication heap buffer overflow in `unirpcd` service
    * CVE-2023-28502: Pre-authentication stack buffer overflow in `udadmin_server` service
    * CVE-2023-28503: Authentication bypass in `libunidata.so`'s `do_log_on_user()` function
    * CVE-2023-28504: Pre-authentication stack buffer overflow in `libunidata.so`'s `U_rep_rpc_server_submain()`
    * CVE-2023-28505: Post-authentication buffer overflow in `libunidata.so`'s `U_get_string_value()` function
    * CVE-2023-28506: Post-authentication stack buffer overflow in `udapi_slave` executable
    * CVE-2023-28507: Pre-authentication memory exhaustion in LZ4 decompression in `unirpcd` service
    * CVE-2023-28508: Post-authentication heap overflow in `udsub` service
    * CVE-2023-28509: Weak protocol encryption
* Multiple vulnerabilities in Globalscape EFT - [analysis blog](https://www.rapid7.com/blog/post/2023/06/22/multiple-vulnerabilities-in-fortra-globalscape-eft-administration-server-fixed/)
  * [Protocol implementation + proofs of concept](https://github.com/rbowes-r7/gestalt)
  * Vulnerabilities:
    * CVE-2023-2989 - Authentication bypass via out-of-bounds memory read ([vendor advisory](https://kb.globalscape.com/Knowledgebase/11586/Is-EFT-susceptible-to-the-Authentication-Bypass-via-Outofbounds-Memory-Read-vulnerability))
    * CVE-2023-2990 - Denial of service due to recursive DeflateStream ([vendor advisory](https://kb.globalscape.com/Knowledgebase/11588/Is-EFT-susceptible-to-the-Denial-of-service-via-recursive-Deflate-Stream-vulnerability))
    * CVE-2023-2991 - Remote hard drive serial number disclosure ([vendor advisory](https://kb.globalscape.com/Knowledgebase/11589/Is-EFT-susceptible-to-the-Remotely-obtain-HDD-serial-number-vulnerability)) (not currently fixed)
    * Additional issue - Password leak due to insecure default configuration ([vendor advisory](https://kb.globalscape.com/Knowledgebase/11587/Is-EFT-susceptible-to-the-Password-Leak-Due-to-Insecure-Defaults-vulnerability))

## N-day analyses

*These are writeups / analyses / PoCs I wrote based on publicly known bugs, public proof of concepts, patch diffing, vendor advisories, forum posts, etc. The core vulnerabilities are not my original work.*

* CVE-2023-0669 - Remote code execution in Fortra GoAnywhere MFC via unsafe deserialization (and hardcoded crypto keys) - [AttackerKB analysis](https://attackerkb.com/topics/mg883Nbeva/cve-2023-0669/rapid7-analysis) / [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17607)
  * Media: [Dark Reading](https://www.darkreading.com/endpoint/massive-goanywhere-rce-exploit) / [The Stack](https://thestack.technology/goanywhere-mft-vulnerability-exploited-cve-2023-0669/) / [Security Week](https://www.securityweek.com/goanywhere-mft-zero-day-exploitation-linked-to-ransomware-attacks/)
* CVE-2022-47966 - Remote code execution in multiple ManageEngine products, including ADSelfService Plus, due to unsafe deserialization in an outdated XML library - [AttackerKB](https://attackerkb.com/topics/gvs0Gv8BID/cve-2022-47966/rapid7-analysis)
  * Media: [The Hacker News](https://thehackernews.com/2023/01/zoho-manageengine-poc-exploit-to-be.html) / [Bleeping Computer](https://www.bleepingcomputer.com/news/security/critical-manageengine-rce-bug-now-exploited-to-open-reverse-shells/) / [Security Week](https://www.securityweek.com/wild-exploitation-recent-manageengine-vulnerability-commences/)
* CVE-2022-47986 - Ruby deserialization vulnerability in IBM Aspera Faspex server - [AttackerKB](https://attackerkb.com/topics/jadqVo21Ub/cve-2022-47986/rapid7-analysis)
  * Media: [Help Net Security](https://www.helpnetsecurity.com/2023/03/30/exploiting-cve-2022-47986/) / [Ars Technica](https://arstechnica.com/information-technology/2023/03/ransomware-crooks-are-exploiting-ibm-file-exchange-bug-with-a-9-8-severity/) / [SC Media](https://www.scmagazine.com/news/ransomware/unpatched-ibm-aspera-faspex-file-transfer-service-under-active-attack)
* CVE-2023-25690 - Request smuggling in Apache's `mod_rewrite` - [AttackerKB](https://attackerkb.com/topics/0Uka1VHsPO/cve-2023-25690/rapid7-analysis)
* CVE-2023-34362 - SQL injection, header smuggling, session injection, and .net deserialization issues in MOVEit file transfer - [AttackerKB](https://attackerkb.com/topics/mXmV0YpC3W/cve-2023-34362/rapid7-analysis)
* CVE-2023-20887 - Command injection in VMware Aria Operations for Newtorks - [AttackerKB](https://attackerkb.com/topics/gxz1cUyFh2/cve-2023-20887/rapid7-analysis)
* CVE-2023-3519 - Stack-based buffer overflow in Citrix ADC - [AttackerKB](https://attackerkb.com/topics/si09VNJhHh/cve-2023-3519/rapid7-analysis)
* CVE-2023-34124 / CVE-2023-34133 / CVE-2023-34132 / CVE-2023-34127 - Multiple vulnerabilities culminating in RCE in SonicWall Global Management System (GMS) - [AttackerKB](https://attackerkb.com/topics/Vof5fWs4rx/cve-2023-34127/rapid7-analysis) / [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/18302)

# 2022

## Vulnerabilities I Discovered

* Multiple vulnerabilities in F5 BIG-IP and F5 BIG-IQ - [analysis blog](https://www.rapid7.com/blog/post/2022/11/16/cve-2022-41622-and-cve-2022-41800-fixed-f5-big-ip-and-icontrol-rest-vulnerabilities-and-exposures/)
  * Vulnerabilities:
    * CVE-2022-41622 - Remote code execution in F5 BIG-IP and BIG-IQ due to cross-site request forgery and SELinux bypass - [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17271)
    * CVE-2022-41800 - Authenticated remote code in F5 BIG-IP and BIG-IQ due to injection in an RPM specification file - [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17273)
    * (No CVE) - Privilege escalation in F5 BIG-IP and BIG-IQ due to bad file permissions on database socket - [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17392)
  * Media coverage: [Tech Target](https://www.techtarget.com/searchsecurity/news/252527322/Rapid7-discloses-more-F5-BIG-IP-vulnerabilities) / [Portswigger](https://portswigger.net/daily-swig/f5-fixes-high-severity-rce-bug-in-big-ip-big-iq-devices) / [Securityweek](https://www.securityweek.com/remote-code-execution-vulnerabilities-found-f5-products)
* Format string vulnerability in F5 BIG-IP - [analysis blog](https://www.rapid7.com/blog/post/2023/02/01/cve-2023-22374-f5-big-ip-format-string-vulnerability/)
* CVE-2022-27511 and CVE-2022-27512 (patch bypass) - Denial of service vulnerability in FlexNet Licensing Server affecting Citrix ADM (among other things) - [analysis blog](https://www.rapid7.com/blog/post/2022/10/18/flexlm-and-citrix-adm-denial-of-service-vulnerability/)
  * (I didn't find the original CVEs, but I bypassed the patch for one of them)

## N-day analyses

*These are writeups / analyses / PoCs I wrote based on publicly known bugs, public proof of concepts, patch diffing, vendor advisories, forum posts, etc. The core vulnerabilities are not my original work.*

* CVE-2022-36804 - Remote Code Execution in Atlassian Bitbucket - [AttackerKB analysis](https://attackerkb.com/topics/iJIxJ6JUow/cve-2022-36804/rapid7-analysis) / [high level blog](https://www.rapid7.com/blog/post/2022/09/20/cve-2022-36804-easily-exploitable-vulnerability-in-atlassian-bitbucket-server-and-data-center/)
* CVE-2015-1197 - Path traversal vulnerability in `cpio` continuing to affect most major Linux distros - [AttackerKB analysis](https://attackerkb.com/topics/FdLYrGfAeg/cve-2015-1197/rapid7-analysis) / [Personal blog](https://www.skullsecurity.org/2023/blast-from-the-past--how-attackers-compromised-zimbra-with-a-patched-vulnerability)
* CVE-2022-41352 - Remote code execution in Zimbra due to path traversal in `cpio` (CVE-2015-1197) - [AttackerKB analysis](https://attackerkb.com/topics/1DDTvUNFzH/cve-2022-41352/rapid7-analysis) / [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17114)
  * Media coverage: [Dark Reading](https://www.darkreading.com/remote-workforce/zimbra-rce-bug-under-active-attack) / [Ars Technica](https://arstechnica.com/information-technology/2022/10/ongoing-0-day-attacks-backdoor-zimbra-servers-by-sending-a-malicious-email/) / [IT World Canada](https://www.itworldcanada.com/article/cyber-security-today-oct-10-2022-warnings-to-zimbra-and-fortinet-administrators-lessons-from-the-hack-of-a-us-defence-contractor-and-more/507344) / [Security Affairs](https://securityaffairs.co/wordpress/136800/hacking/zimbra-collaboration-suite-rce.html) / [Digital Journal](https://www.digitaljournal.com/pr/web-collaboration-solution-market-know-technique-is-getting-more-and-more-popular-in-coming-years-2022-2029-ibm-zimbra-projectplace)
* CVE-2022-30333 - Path traversal in `unrar` that is exploitable for remote code execution in Zimbra - [AttackerKB analysis](https://attackerkb.com/topics/RCa4EIZdbZ/cve-2022-30333/rapid7-analysis) / [Metasploit Module](https://github.com/rapid7/metasploit-framework/pull/16796)
* CVE-2022-37393 - Local privilege escalation in Zimbra due to bad `sudo` configuration - [AttackerKB analysis](https://attackerkb.com/topics/92AeLOE1M1/cve-2022-37393/rapid7-analysis) / [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/16807/files)
* CVE-2022-27924 - Authentication bypass in Zimbra due to `memcached` poisoning - [AttackerKB analysis](https://attackerkb.com/topics/6vZw1iqYRY/cve-2022-27924/rapid7-analysis)
* CVE-2022-27925 / CVE-2022-37042 - Remote code execution in Zimbra due to a combination of ZIP-based path traversal (CVE-2022-27925) and authentication bypass (CVE-2022-37042) - [AttackerKB analysis](https://attackerkb.com/topics/dSu4KGZiFd/cve-2022-27925/rapid7-analysis) / [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/16922) 
* CVE-2022-3569 - Local privilege escalation in Zimbra due to bad `sudo` configuration - [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17141)
* CVE-2022-1388 - Remote code execution in F5 due to authentication bypass - [AttackerKB analysis](https://attackerkb.com/topics/SN5WCzYO7W/cve-2022-1388/rapid7-analysis)
* CVE-2022-40684 - Remote code execution in FortiOS due to header injection in proxied traffic - [AttackerKB analysis](https://attackerkb.com/topics/QWOxGIKkGx/cve-2022-40684/rapid7-analysis)
* CVE-2022-28219 - Remote code execution in ManageEngine ADAudit Plus due to a combination of unsafe deserialization and XXE - [AttackerKB analysis](https://attackerkb.com/topics/Zx3qJlmRGY/cve-2022-28219/rapid7-analysis) / [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/16758)
* CVE-2022-29799 - "NimbusPwn" - what I'm calling a "horizontal privilege escalation" vulnerability, meaning you can escalate to the same privileges you have - [AttackerKB analysis](https://attackerkb.com/topics/cZEN5EWng1/cve-2022-29799/rapid7-analysis)
* CVE-2022-3602 - 4-byte buffer overflow in OpenSSL's Punycode parser - [AttackerKB analysis](https://attackerkb.com/topics/GMp2yGvZCw/cve-2022-3602/rapid7-analysis) / [simple PoC](https://github.com/rbowes-r7/cve-2022-3602-and-cve-2022-3786-openssl-poc)
* CVE-2022-3786 - Buffer overflow (with `.` characters) in OpenSSL's Punycode parser - [AttackerKB analysis](https://attackerkb.com/topics/CKTqMzGksY/cve-2022-3786/rapid7-analysis) / [simple PoC](https://github.com/rbowes-r7/cve-2022-3602-and-cve-2022-3786-openssl-poc)
* CVE-2022-22954 - Remote code execution due to template injection in VMWare Workspace ONE - [AttackerKB analysis](https://attackerkb.com/topics/BDXyTqY1ld/cve-2022-22954/rapid7-analysis)

## Tools, projects, code releases, etc.

* [BSides San Francisco CTF](https://github.com/BSidesSF/ctf-2022-release) - I was a co-lead and challenge author
* [refreshing-mcp-tool](https://github.com/rbowes-r7/refreshing-mcp-tool) - A tool for working with F5's internal database protocol (MCP or Master Control Program)
* [refreshing-soap-exploit](https://github.com/rbowes-r7/refreshing-soap-exploit) - A tool for testing a SOAP-based CSRF vulnerability in F5 BIG-IP and BIG-IQ
* [Metasploit module](https://github.com/rapid7/metasploit-framework/pull/17272) for pulling data from F5's MCP socket
* [doltool](https://github.com/rbowes-r7/doltool) - An implementation of the FlexLM licensing server's protocol

# Pre-2022 work
*I'm not including stuff from [my blog](https://www.skullsecurity.org), you can see everything there!*

* CVE-2018-15442 (aka "WebExec") - a remote code execution vulnerability in the WebEx Update Service - [high-level writeup](https://webexec.org/) / [detailed blog](https://blog.skullsecurity.org/2018/technical-rundown-of-webexec) / [Metasploit modules](https://github.com/rapid7/metasploit-framework/pull/10864)
* BSides San Francisco lead / co-lead / challenge dev / etc - [2021](https://github.com/BSidesSF/ctf-2021-release) / [2020](https://github.com/BSidesSF/ctf-2020-release) / [2019](https://github.com/BSidesSF/ctf-2019-release) / [2018](https://github.com/BSidesSF/ctf-2018-release) / [2017](https://github.com/BSidesSF/ctf-2017-release)
* [hash_extender](https://github.com/iagox86/hash_extender) - a tool for exploiting most types of hash-length extension attacks
* [dnscat2](https://github.com/iagox86/dnscat2) - a TCP-over-DNS tunneling tool
* [mandrake](https://github.com/iagox86/mandrake) - a tool for instrumenting x64 assembly or shellcode
* [terraria-research-tracker](https://github.com/iagox86/terraria-research-tracker) - a tool for parsing Terraria's savefiles
* [cryptorama](https://github.com/iagox86/cryptorama) - teaching tools / labs for common cryptographic vulnerabilities
* [poracle](https://github.com/iagox86/poracle) - a padding oracle exploit tool
* [dnsutils](https://github.com/iagox86/dnsutils) - a Ruby gem for creating and capturing a variety of DNS traffic
* A whole pile of Nmap scripts and libraries:
  * [broadcast-dropbox-listener.nse](https://github.com/nmap/nmap/blob/master/scripts/broadcast-dropbox-listener.nse)
  * [dhcp-discover.nse](https://github.com/nmap/nmap/blob/master/scripts/dhcp-discover.nse)
  * [http-enum.nse](https://github.com/nmap/nmap/blob/master/scripts/http-enum.nse)
  * [http-exif-spider.nse](https://github.com/nmap/nmap/blob/master/scripts/http-exif-spider.nse)
  * [http-headers.nse](https://github.com/nmap/nmap/blob/master/scripts/http-headers.nse)
  * [http-iis-webdav-vuln.nse](https://github.com/nmap/nmap/blob/master/scripts/http-iis-webdav-vuln.nse)
  * [http-malware-host.nse](https://github.com/nmap/nmap/blob/master/scripts/http-malware-host.nse)
  * [http-vmware-path-vuln.nse](https://github.com/nmap/nmap/blob/master/scripts/http-vmware-path-vuln.nse)
  * [http-vuln-cve2013-7091.nse](https://github.com/nmap/nmap/blob/master/scripts/http-vuln-cve2013-7091.nse)
  * [irc-unrealircd-backdoor.nse](https://github.com/nmap/nmap/blob/master/scripts/irc-unrealircd-backdoor.nse)
  * [nbstat.nse](https://github.com/nmap/nmap/blob/master/scripts/nbstat.nse)
  * [p2p-conficker.nse](https://github.com/nmap/nmap/blob/master/scripts/p2p-conficker.nse)
  * [smb-brute.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-brute.nse)
  * [smb-enum-domains.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-enum-domains.nse)
  * [smb-enum-groups.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-enum-groups.nse)
  * [smb-enum-processes.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-enum-processes.nse)
  * [smb-enum-sessions.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-enum-sessions.nse)
  * [smb-enum-shares.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-enum-shares.nse)
  * [smb-enum-users.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-enum-users.nse)
  * [smb-flood.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-flood.nse)
  * [smb-os-discovery.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-os-discovery.nse)
  * [smb-psexec.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-psexec.nse)
  * [smb-security-mode.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-security-mode.nse)
  * [smb-server-stats.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-server-stats.nse)
  * [smb-system-info.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-system-info.nse)
  * [smb-vuln-conficker.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-conficker.nse)
  * [smb-vuln-cve2009-3103.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-cve2009-3103.nse)
  * [smb-vuln-ms06-025.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-ms06-025.nse)
  * [smb-vuln-ms07-029.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-ms07-029.nse)
  * [smb-vuln-ms08-067.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-ms08-067.nse)
  * [smb-vuln-regsvc-dos.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-regsvc-dos.nse)
  * [smb-vuln-webexec.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-vuln-webexec.nse)
  * [smb-webexec-exploit.nse](https://github.com/nmap/nmap/blob/master/scripts/smb-webexec-exploit.nse)

# SUPER old

* [unickspoofer](https://github.com/iagox86/old-unickspoofer) - a hack (that I wrote in Visual Basic 6!!!) to change your in-game name in Startcraft, Warcraft 2, and Diablo 2 (supports colours and illegal names; hilarity often ensued)
* [operation-status](https://github.com/iagox86/old-operation-stasis) - a set of cheats for Starcraft that have long since stopped working (and were never very stable to begin with)
* [d2plugin](https://github.com/iagox86/old-d2plugin) and [d2plugin2](https://github.com/iagox86/old-d2plugin2) - a set of cheaps for Diablo 2 that have long since stopped working (I'm not sure which one is better, if either, so I'm just linking both)

# Talks

*I've saved basically every talk I ever gave! A bunch of these weren't public, and now they are. The older ones look soooo bad. But, enjoy!*

* 2023-05 [UniData UniRPC Vulnerabilities](https://docs.google.com/presentation/d/1O-Bphmo8q64O9NSt7vmYUQ8Zevez5f6MLhcimyBv36s/edit?usp=sharing) @ NorthSec Montreal
* 2022-12 [F5 BIG-IP Vulnerabilities](https://docs.google.com/presentation/d/1CeWI7IIIVJEmrtPkFPnUIUHns2S7gZnchmlTo3ozhEA/edit?usp=share_link) @ Hushcon Seattle
* 2022-08 [From Vuln to CTF](https://docs.google.com/presentation/d/1-z8PFYhQGkuqjSN7Io_uxZYmGG95EZmx1fRden8UsW8/edit?usp=share_link) @ BSides Las Vegas
* 2022-02 [HHC Shellcode Primre](https://docs.google.com/presentation/d/1Fpohp1kyzwmF--kvnfp2NR-E5R-B3OAHFLFBukj3UW4/edit?usp=share_link) @ Montrehack - largely a walkthrough of a challenge from Holiday Hack Challenge
* 2020-10 [Reverse Engineering](https://docs.google.com/presentation/d/1CBozYzUZ0Hc-YE3FnIjpPH2djVT54xNXoCojKhpD6zE/edit?usp=share_link) @ DCA10 - I have no memory of writing or giving this talk, or what DCA10 is!
* 2020-06 [Crypto: You're Doing it Wrong](https://docs.google.com/presentation/d/1C1r4WeCzihfiTzzG9SV9BhD3E4OtNgJv5kzPQwPswng/edit?usp=share_link) @ PuPPy (Puget Sound Python group) - I wrote this, but due to the SPD protests/riots in Seattle, the event was cancelled
* 2018-11 [WebExec: Finding an 0-day in a Pentest](https://docs.google.com/presentation/d/1A8Ii78ApI-YH7Jqtw42c5wQ4K8G5soVpWigrpKg-toc/edit?usp=share_link) @ The Long Con
* 2018-05 [Video Games](https://docs.google.com/presentation/d/1-7cRY6VYE0B6mvf2JqIUQK6KoWoWMZNngtzzbf5_Jn0/edit?usp=share_link) @ NorthSec
* 2017-04 [CTF Workshop](https://docs.google.com/presentation/d/107IrLZ5VRIfw35QqDtqzxJKCUVm89VHeE-gGRGejoHU/edit?usp=share_link) @ Skullspace - Mostly a workshop
* 2016-12 [Using DNS for Pentesting](https://docs.google.com/presentation/d/1_5bp_0HOTerjEyBV2lVDbS6KXDYRMI59zklQjecTn34/edit?usp=share_link) @ DC204
* 2016-11 [Hash Extension attacks](https://docs.google.com/presentation/d/1hUJXMHPHTBB_9PeX2y83puMShGKUL7LcUPS7KUPI2z8/edit?usp=share_link) @ SANS (lightning talk)
* 2016-01 [Evil DNS Tricks](https://docs.google.com/presentation/d/1ZRgO_JPUMWuydNvisIwxo6ZZAUt6boetB-uJs7fakIQ/edit?usp=share_link) @ Shmoocon Firetalk
* 2015-11 [Pentesting with DNS](https://docs.google.com/presentation/d/1Jxh6PPO9JbUqXwOCTQFyA00uQoFMDBh-1PedDOp1Z0Y/edit?usp=share_link) @ SANS Pentest Summit
* 2015-06 [The Anatomy of a Vulnerability](https://docs.google.com/presentation/d/1UYECUf45zd_PDZarXwIOlxlB89oM-zjYpbXJVC69qKw/edit?usp=share_link) @ Sharkfest
* 2014-11 [Vulnerability War Stories](https://docs.google.com/presentation/d/1dXvqw84HB00axpzMYmcTdMo_0LNIVPoJZfXrhvbwRe8/edit?usp=share_link) @ UofM Comp Sci
* 2014-09 [DNS: More than Just Names](https://docs.google.com/presentation/d/1HfXVJyXElzBshZ9SYNjBwJf_4MBaho6UcATTFwApfXw/edit?usp=share_link) @ Derbycon
* 2014-06 [DNS](https://docs.google.com/presentation/d/1t_lfO1jC0GsCzjc847iyrZCS4zbLo3ReppXlpU7bURc/edit?usp=share_link) @ BSides Quebec
* 2013-06 [Why is Crypto so Hard?](https://docs.google.com/presentation/d/1N3LOUnDl3pK-VTkOtY1i4FAfKvRtPWKrIRkr3Nnl45Y/edit?usp=share_link) @ Sharkfest
* 2013-02 [Crypto: You're Doing it Wrong](https://docs.google.com/presentation/d/15S68RziN0fgK9Mb3TFy3E0kWt2UTy2Twcz03WbkNyFw/edit?usp=share_link) @ Shmoocon [[video](https://www.youtube.com/watch?v=im-Z6ni9jc4)]
* 2012-06 [Secrets of Vulnerability Scanning](https://docs.google.com/presentation/d/1BkQeF0p6XXk47ni7VmWlsqZbtaWg917EGAH-gUwf8zA/edit?usp=sharing) @ Sharkfest
* 2012-02 [Introduction to SkullSpace and Hackerspaces](https://docs.google.com/presentation/d/1Uq40bBuh_htE2NeON2UvbclApYFUnyiKW7G58a_os1g/edit?usp=share_link) @ Winnipeg Code Camp
* 2011-11 [Introduction to SkullSpace and Hackerspaces](https://docs.google.com/presentation/d/1tzFHSeJNxzUPzx2rpX4MTvKTFn2dWZA1zzCZ_Xj1OVc/edit?usp=share_link) @ SkullSpace
* 2011-11 [Introduction to SkullSpace and Hackerspaces](https://docs.google.com/presentation/d/1K50dkposXyQ5VSMFIvFArdw6_pa7OfIXlzQgQZEjtg8/edit?usp=share_link) @ IPAM
* 2011-10 [Introduction to SkullSpace and Hackerspaces](https://docs.google.com/presentation/d/1eQnWvtOJCPSi_R9JkEYUVAM16piAorryAwdfiNYnsK4/edit?usp=share_link) @ UofM
* 2011-10 [Advanced Nmap Scripting](https://docs.google.com/presentation/d/14TiPPsKCDhrSzW_ts8FfNX3Ncurbvu9bcJ5mHBESyIs/edit?usp=share_link) @ DerbyCon
* 2011-06 [Writing Wireshark Dissectors](https://docs.google.com/presentation/d/10vlAkJPalCZQrLUMiOvZx4wMxm3_UMiAyxliGAlRMJI/edit?usp=share_link) @ Sharkfest
* 2011-03 [Introducing SkullSpace](https://docs.google.com/presentation/d/1bacGDly-ahuA-E5PwQmjYY-0U8vouvmEhjn9m3qEH3c/edit?usp=share_link) @ UofM
* 2011-02 [Stupid Mistakes Made by Smart People](https://docs.google.com/presentation/d/1358qlVu6Y5xGn9FZDplpLRrJo1vod6P3qrfbu5Mpx7g/edit?usp=share_link) @ Winnipeg Code Camp - This is one of my favourite early talks!
* 2010-11 [Passwords in the Wild](https://docs.google.com/presentation/d/1Sg65L0fNlD0OvLmagpFbiw-uKRTHbSLR1Ix0l_VOYJk/edit?usp=share_link) @ IPAM
* 2010-11 [Passwords in the Wild](https://docs.google.com/presentation/d/1XzRW19xvcvB-aeQQBGYOPWek57qGQn4QBaGaPbww_sg/edit?usp=share_link) @ Deepsec
* 2010-11 [The Nmap Scripting Engine](https://docs.google.com/presentation/d/1z-J14qR-CL8vQV8u93IDYmTK8YORbVQ8nJYXeR9eIMw/edit?usp=share_link) @ BSides Ottawa - I gave this talk with no shoes on, because I got stuck in torrential rain... the conference organizers still remind me of that
* 2010-02 [VMWare Guest stealing](https://docs.google.com/presentation/d/1aPjWELp8PFcANdNk6NFJf3vQa84kwm6ejsGLRN2LoLk/edit?usp=share_link) @ IPAM
* 2009-10 [Nmap Scripts for Windows](https://docs.google.com/presentation/d/1j8zZKsDMeq5LujEPz_bZhYS3pjW1wkla-zG8E9su8YE/edit?usp=share_link) @ Toorcon - My first conference talk!
* 2009-07 [Introduction to Pentesting](https://docs.google.com/presentation/d/1ibfs7renT9NrfEXbtcggDiMcZX0MN4Bm_BsOxRqBIws/edit?usp=share_link) @ A company in Calgary that probably doesn't exist anymore
* 2009-05 [Lifecycle of a Stolen Identity](https://drive.google.com/file/d/0BzwwWJ2ItjiCRHl1QldoX3NCWXc/view?usp=share_link&resourcekey=0-i4PxGHdLTVKGyWuawbHLSA) @ a MLM company I won't name
* 2009-01 [Introduction to Pentesting](https://drive.google.com/drive/folders/0BzwwWJ2ItjiCcFQ2UXQyZXVXT3M?resourcekey=0-sVGemtb4CHhSDu8JSu25zg&usp=sharing) @ IPAM - my first (saved) talk, given to a local infosec group in Winnipeg, sorta summarizing what I learned in SANS560
