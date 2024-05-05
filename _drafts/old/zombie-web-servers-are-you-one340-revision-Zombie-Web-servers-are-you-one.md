---
id: 341
title: 'Zombie Web servers: are you one?'
date: '2009-09-16T09:33:17-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=341'
permalink: '/?p=341'
---

Greetings!

I found this [excellent writeup of a Web-server botnet ](http://blog.unmaskparasites.com/2009/09/11/dynamic-dns-and-botnet-of-zombie-web-servers/)[on Slashdot this weekend](http://rss.slashdot.org/~r/Slashdot/slashdot/~3/KvpetB3SR6U/First-Botnet-of-Linux-Web-Servers-Discovered). Since it sounded like just the thing for Nmap to detect, I wrote a quick script!

When a server is compromised, an additional Web server is started on port 8080. This server will try and exploit vulnerable browsers. If anybody else connects to them, it redirects them (with a 302 Found) to another infected Web server (obviously, they have some mechanism of finding each other).

This redirection is easy to detect with Nmap.

The script is called http-malware-host.nse, and I highly recommend running it against your own servers. All you need to do is check it out from svn and run it:

```

$ svn co --username guest --password '' svn://svn.insecure.org/nmap
$ cd nmap
$ ./configure && make
# make install
$ nmap -d -p80,443,8080 --script=http-malware-host <target>
```

I opted to include two other common HTTP ports, just in case the attackers change their tactics.

If the host is clean, you will see no additional output. If the host is infected, you'll see the following:

```
$ ./nmap -p8080 --script=http-malware-host last-another-life.ru                                                                                                                                                                                                            Starting Nmap 5.05BETA1 ( http://nmap.org ) at 2009-09-16 09:32 CDT
Warning: Hostname last-another-life.ru resolves to 5 IPs. Using 80.69.74.73.
NSE: Script Scanning completed.
Interesting ports on 80-69-74-73.colo.transip.net (80.69.74.73):
PORT     STATE SERVICE
8080/tcp open  http-proxy
|  http-malware-host: Host appears to be infected (/ts/in.cgi?open2 redirects to http://last-another-life.ru:8080/index.php)
|_ See: http://blog.unmaskparasites.com/2009/09/11/dynamic-dns-and-botnet-of-zombie-web-servers/
```