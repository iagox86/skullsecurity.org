---
id: 409
title: 'smb-psexec.nse: owning Windows, fast (Part 3)'
date: '2010-01-08T17:21:42-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=409'
permalink: '/?p=409'
---

Posts in this series (I'll add links as they're written):

1. [What does smb-psexec do?](/blog/?p=365)
2. [**Sample configurations ("sample.lua")**](/blog/?p=379)
3. Default configuration ("default.lua")
4. Advanced configuration ("pwdump.lua" and "backdoor.lua")
5. Conclusions

## Getting started

Hopefully you all read the last [two](/blog/?p=365) [posts](/blog/?p=379). I started with an introduction to smb-psexec.nse in the first post, then went over some "example" configurations in the second. The example configurations are nice to study because I designed them to be instructive, but today's post is going to look at some real configurations I'm including. As of the 5.10beta1 and beta2 versions, these are included in default.lua.

## Configuration files

The configuration file for smb-psexec.nse is stored in the <tt>nselib/data/psexec</tt> directory. Depending on which operating system you're on, and how you install Nmap, it might be in one of the following places:

- /usr/share/nmap/nselib/data/psexec
- /usr/local/share/nmap/nselib/data/psexec
- C:\\Program Files\\Nmap\\nselib\\data\\psexec

Note that up to and including Nmap 5.10BETA2, this folder will be missing on Windows. You'll need to download the Linux install and copy over the folder.

## Command 1: Windows version

```

mod = {}
mod.upload           = false
mod.name             = "Windows version"
mod.program          = "cmd.exe"
mod.args             = "/c \"ver\""
mod.maxtime          = 1
mod.noblank          = true
table.insert(modules, mod)
```

This command gets the full version of Windows by running the "ver" command. Interestingly, this command wouldn't work when I tried running it directly. You'll see this theme running throughout my configuration files -- bugs where certain programs require certain variables to be set or certain environments that don't seem to make sense. I've learned how to work around many of them, but be warned if you're writing configurations yourself: things may not always work as you expect.

Output:

```
|   Windows version
|     Microsoft Windows 2000 [Version 5.00.2195]
```

## Command 2: IP/MAC address

```
mod = {}
mod.upload           = false
mod.name             = "IP Address and MAC Address from 'ipconfig.exe'"
mod.program          = "ipconfig.exe"
mod.args             = "/all"
mod.maxtime          = 1
mod.find             = {"IP Address", "Physical Address", "Ethernet adapter"}
mod.replace          = {{"%. ", ""}, {"-", ":"}, {"Physical Address", "MAC Address"}}
table.insert(modules, mod)
```

I believe this one is either similar to or the same as the sample configuration from examples.lua, so I won't dwell on it.

Output:

```
|   IP Address and MAC Address from 'ipconfig.exe'
|     Ethernet adapter Local Area Connection 2:
|       MAC Address: 00:50:56:A1:24:C2
|       IP Address: 10.0.0.30
|     Ethernet adapter Local Area Connection:
|       MAC Address: 00:50:56:A1:00:65
```

## Commands 3 and 4: List of users

```
mod = {}
mod.upload           = false
mod.name             = "User list from 'net user'"
mod.program          = "net.exe"
mod.args             = "user"
mod.maxtime          = 1
mod.remove           = {"User accounts for", "The command completed", "%-%-%-%-%-%-%-%-%-%-%-"}
mod.noblank          = true
table.insert(modules, mod)

mod.upload           = false
mod.name             = "Membership of 'administrators' from 'net localgroup administrators'"
mod.program          = "net.exe"
mod.args             = "localgroup administrators"
mod.maxtime          = 1
mod.remove           = {"The command completed", "%-%-%-%-%-%-%-%-%-%-%-", "Members", "Alias name", "Comment"}
mod.noblank          = true
table.insert(modules, mod)
```

As before, these commands were discussed previously. Strictly speaking, these aren't the most useful commands to run because identical information can be obtained from running smb-enum-users.nse and smb-enum-groups.nse.

Output:

```
|   User list from 'net user'
|     Administrator            AKolmakov                Guest
|     IUSR_RON-WIN2K-TEST      IWAM_RON-WIN2K-TEST      nmap
|     rontest123               sshd                     SvcCOPSSH
|     test1234                 Testing                  TsInternetUser
|   Membership of 'administrators' from 'net localgroup administrators'
|     Administrator
|     SvcCOPSSH
|     test1234
|     Testing
```

### Ping the scanner

```
mod = {}
mod.upload           = false
mod.name             = "Can the host ping our address?"
mod.program          = "ping"
mod.args             = "-n 1 $lhost"
mod.maxtime          = 5
mod.remove           = {"statistics", "Packet", "Approximate", "Minimum"}
mod.noblank          = true
mod.env              = "SystemRoot=c:\\WINDOWS"
table.insert(modules, mod)
```

Although this one was also discussed in the last post, I do want to bring up one noteworthy issue. It seems that many Windows programs that deal with IP addresses will fail in a spectacularily weird way. Here is the proper output

```
|   Can the host ping our address?
|     Pinging 10.0.0.138 with 32 bytes of data:
|     Reply from 10.0.0.138: bytes=32 time
<p>And here is the output without the environmental variable set:</p>
|   Can the host ping our address?
|     Pinging $\x98\x07 with 32 bytes of data:
|     Reply from 10.0.0.138: bytes=32 time
<p>tracert has the same problem. Why it happens, though, I have no idea. </p>
<h3>Tracert to the scanner</h3>
mod = {}
mod.upload           = false
mod.name             = "Traceroute back to the scanner"
mod.program          = "tracert"
mod.args             = "-d -h 5 $lhost"
mod.maxtime          = 20
mod.remove           = {"Tracing route", "Trace complete"}
mod.noblank          = true
mod.env              = "SystemRoot=c:\\WINDOWS"
table.insert(modules, mod)

<p>Speaking of tracert, this command performs a traceroute from the target back to the scanner. This could be useful if you're trying to determine network layout or something, and you can't get a forward traceroute to work. Like ping, it requires the SystemRoot variable. </p>
<p>Output:</p>

|   Traceroute back to the scanner
|       1    
<h3>arp cache</h3>
mod = {}
mod.name             = "ARP Cache from arp.exe"
mod.program          = 'arp.exe'
mod.upload           = false
mod.args             = '-a'
mod.remove           = "Interface"
mod.noblank          = true
table.insert(modules, mod)
<p>This one is easy -- dump the arp cache of the host. </p>
<p>-- Get the listening/connected ports<br></br>
mod = {}<br></br>
mod.upload           = false<br></br>
mod.name             = "List of listening and established connections (netstat -an)"<br></br>
mod.program          = "netstat"<br></br>
mod.args             = "-an"<br></br>
mod.maxtime          = 1<br></br>
mod.remove           = {"Active"}<br></br>
mod.noblank          = true<br></br>
mod.env              = "SystemRoot=c:\\WINDOWS"<br></br>
table.insert(modules, mod)</p>
<p>-- Get the routing table.<br></br>
--<br></br>
-- Like 'ver', this has to be run through cmd.exe. This also requires the 'PATH' variable to be<br></br>
-- set properly, so it isn't going to work against systems with odd paths.<br></br>
mod = {}<br></br>
mod.upload           = false<br></br>
mod.name             = "Full routing table from 'netstat -nr'"<br></br>
mod.program          = "cmd.exe"<br></br>
mod.args             = "/c \"netstat -nr\""<br></br>
mod.env              = "PATH=C:\\WINDOWS\\system32;C:\\WINDOWS;C:\\WINNT;C:\\WINNT\\system32"<br></br>
mod.maxtime          = 1<br></br>
mod.noblank          = true<br></br>
table.insert(modules, mod)</p>
<p>-- Boot configuration<br></br>
mod = {}<br></br>
mod.upload           = false<br></br>
mod.name             = "Boot configuration"<br></br>
mod.program          = "bootcfg"<br></br>
mod.args             = "/query"<br></br>
mod.maxtime          = 5<br></br>
table.insert(modules, mod)</p>
<p>-- Get the drive configuration. For same (insane?) reason, it uses NULL characters instead of spaces<br></br>
-- for the response, so we have to do a replaceent.<br></br>
mod = {}<br></br>
mod.upload           = false<br></br>
mod.name             = "Drive list (for more info, try adding --script-args=config=drives,drive=C:)"<br></br>
mod.program          = "fsutil"<br></br>
mod.args             = "fsinfo drives"<br></br>
mod.replace          = {{string.char(0), " "}}<br></br>
mod.maxtime          = 1</p>
<p>|   ARP Cache from arp.exe<br></br>
|       Internet Address      Physical Address      Type<br></br>
|       10.0.0.138            00-50-56-a1-27-4b     dynamic<br></br>
|   List of listening and established connections (netstat -an)<br></br>
|       Proto  Local Address          Foreign Address        State<br></br>
|       TCP    0.0.0.0:22             0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:25             0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:80             0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:135            0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:443            0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:445            0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:1025           0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:1027           0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:1028           0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:3389           0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:4933           0.0.0.0:0              LISTENING<br></br>
|       TCP    0.0.0.0:27453          0.0.0.0:0              LISTENING<br></br>
|       TCP    10.0.0.30:139          0.0.0.0:0              LISTENING<br></br>
|       TCP    10.0.0.30:445          10.0.0.138:34913       ESTABLISHED<br></br>
|       TCP    127.0.0.1:1030         127.0.0.1:40000        ESTABLISHED<br></br>
|       TCP    127.0.0.1:5152         0.0.0.0:0              LISTENING<br></br>
|       TCP    127.0.0.1:40000        0.0.0.0:0              LISTENING<br></br>
|       TCP    127.0.0.1:40000        127.0.0.1:1030         ESTABLISHED<br></br>
|       UDP    0.0.0.0:135            *:*<br></br>
|       UDP    0.0.0.0:445            *:*<br></br>
|       UDP    0.0.0.0:1029           *:*<br></br>
|       UDP    0.0.0.0:3456           *:*<br></br>
|       UDP    10.0.0.30:137          *:*<br></br>
|       UDP    10.0.0.30:138          *:*<br></br>
|       UDP    10.0.0.30:500          *:*<br></br>
|       UDP    10.0.0.30:4500         *:*<br></br>
|       UDP    127.0.0.1:1026         *:*<br></br>
|   Full routing table from 'netstat -nr'<br></br>
|     ==========================================================================   =<br></br>
|     Interface List<br></br>
|     0x1 ........................... MS TCP Loopback interface<br></br>
|     0x2 ...00 50 56 a1 00 65 ...... VMware Accelerated AMD PCNet Adapter<br></br>
|     0x1000004 ...00 50 56 a1 24 c2 ...... VMware Accelerated AMD PCNet Adapter<br></br>
|     ==========================================================================   =<br></br>
|     ==========================================================================   =<br></br>
|     Active Routes:</p>
```