---
id: 404
title: 'smb-psexec.nse: owning Windows, fast (Part 3)'
date: '2010-01-19T15:23:11-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=404'
permalink: /2010/smb-psexec-nse-owning-windows-fast-part-3
categories:
    - hacking
    - smb
    - nmap
---

Posts in this series (I'll add links as they're written):
<ol>
<li><a href='/blog/?p=365'>What does smb-psexec do?</a></li>
<li><a href='/blog/?p=379'>Sample configurations ("sample.lua")</a></li>
<li><a href=/blog/?p=404'><strong>Default configuration ("default.lua")</strong></a></li>
<li>Advanced configuration ("pwdump.lua" and "backdoor.lua")</li>
</ol>
<!--more-->
<h2>Getting started</h2>
Hopefully you all read the last <a href='/blog/?p=365'>two</a> <a href='/blog/?p=379'>posts</a>. I started with an introduction to smb-psexec.nse in the first post, then went over some "example" configurations in the second. The example configurations are nice to study because I designed them to be instructive, but today's post is going to look at some real configurations I'm including. You'll notice that many are actually the same or very similar to the example configurations, and that's intentional. As of the Nmap 5.10beta1 and beta2 versions, these are included in default.lua.

<h2>Configuration files</h2>
The configuration file for smb-psexec.nse is stored in the <tt>nselib/data/psexec</tt> directory. Depending on which operating system you're on, and how you installed Nmap, it might be in one of the following places:
<ul>
  <li>/usr/share/nmap/nselib/data/psexec</li>
  <li>/usr/local/share/nmap/nselib/data/psexec</li>
  <li>C:\Program Files\Nmap\nselib\data\psexec</li>
</ul>

Note that up to and including Nmap 5.10BETA2, this folder will be missing on Windows. You'll need to download the Linux install and copy over the folder. 

Now, without further ado, let's take a look at the configurations, one at a time. 

<h2>Command 1: Windows version</h2>
<pre>
mod = {}
mod.upload           = false
mod.name             = "Windows version"
mod.program          = "cmd.exe"
mod.args             = "/c \"ver\""
mod.maxtime          = 1
mod.noblank          = true
table.insert(modules, mod)
</pre>

This command displays the full version of Windows by running the "ver" command. 

Interestingly, this command wouldn't work when I tried running it directly. You'll see this theme running throughout my configuration files -- bugs where certain programs require certain variables to be set or certain environments that don't seem to make sense. I've learned how to work around many of them, but be warned if you're writing configurations yourself: things may not always work as you expect. 

Output on Windows 2000:
<pre>|   Windows version
|     Microsoft Windows 2000 [Version 5.00.2195]
</pre>

Windows Server 2003:
<pre>|   Windows version
|     Microsoft Windows [Version 5.2.3790]
</pre>


<h2>Command 2: IP/MAC address</h2>

{% raw %}
<pre>mod = {}
mod.upload           = false
mod.name             = "IP Address and MAC Address from 'ipconfig.exe'"
mod.program          = "ipconfig.exe"
mod.args             = "/all"
mod.maxtime          = 1
mod.find             = {"IP Address", "Physical Address", "Ethernet adapter"}
mod.replace          = {{"%. ", ""}, {"-", ":"}, {"Physical Address", "MAC Address"}}
table.insert(modules, mod)
</pre>
{% endraw %}

I believe this one is either similar to or the same as the sample configuration from examples.lua, so I won't dwell on it. 

Output:
<pre>|   IP Address and MAC Address from 'ipconfig.exe'
|     Ethernet adapter Local Area Connection 2:
|       MAC Address: 00:50:56:A1:24:C2
|       IP Address: 10.0.0.30
|     Ethernet adapter Local Area Connection:
|       MAC Address: 00:50:56:A1:00:65
</pre>


<h2>Commands 3 and 4: List of users</h2>
<pre>mod = {}
mod.upload           = false
mod.name             = "User list from 'net user'"
mod.program          = "net.exe"
mod.args             = "user"
mod.maxtime          = 1
mod.remove           = {"User accounts for", "The command completed", 
                        "%-%-%-%-%-%-%-%-%-%-%-"}
mod.noblank          = true
table.insert(modules, mod)

mod.upload           = false
mod.name             = "Membership of 'administrators' from 'net localgroup administrators'"
mod.program          = "net.exe"
mod.args             = "localgroup administrators"
mod.maxtime          = 1
mod.remove           = {"The command completed", "%-%-%-%-%-%-%-%-%-%-%-", "Members", 
                       "Alias name", "Comment"}
mod.noblank          = true
table.insert(modules, mod)
</pre>

As before, these commands were discussed previously. Strictly speaking, these aren't the most useful commands to run because identical information can be obtained from running smb-enum-users.nse and smb-enum-groups.nse.

Output:
<pre>|   User list from 'net user'
|     Administrator            AKolmakov                Guest
|     IUSR_RON-WIN2K-TEST      IWAM_RON-WIN2K-TEST      nmap
|     rontest123               sshd                     SvcCOPSSH
|     test1234                 Testing                  TsInternetUser
|   Membership of 'administrators' from 'net localgroup administrators'
|     Administrator
|     SvcCOPSSH
|     test1234
|     Testing
</pre>

<h3>Ping the scanner</h3>
<pre>mod = {}
mod.upload           = false
mod.name             = "Can the host ping our address?"
mod.program          = "ping"
mod.args             = "-n 1 $lhost"
mod.maxtime          = 5
mod.remove           = {"statistics", "Packet", "Approximate", "Minimum"}
mod.noblank          = true
mod.env              = "SystemRoot=c:\\WINDOWS"
table.insert(modules, mod)</pre>
Although this one was also discussed in the last post, I do want to bring up one noteworthy issue. It seems that many Windows programs that deal with IP addresses will fail in a spectacularily weird way. Here is the proper output
<pre>|   Can the host ping our address?
|     Pinging 10.0.0.138 with 32 bytes of data:
|     Reply from 10.0.0.138: bytes=32 time<10ms TTL=64
</pre>

And here is the output without the environmental variable set:
<pre>|   Can the host ping our address?
|     Pinging $\x98\x07 with 32 bytes of data:
|     Reply from 10.0.0.138: bytes=32 time<10ms TTL=64
</pre>

Notice how the ip got totally whacked. The outputted ip address, while consistent across multiple iterations, is completely wrong. tracert has the same problem. 

<h3>Tracert to the scanner</h3>
<pre>mod = {}
mod.upload           = false
mod.name             = "Traceroute back to the scanner"
mod.program          = "tracert"
mod.args             = "-d -h 5 $lhost"
mod.maxtime          = 20
mod.remove           = {"Tracing route", "Trace complete"}
mod.noblank          = true
mod.env              = "SystemRoot=c:\\WINDOWS"
table.insert(modules, mod)
</pre>

Speaking of tracert, this command performs a traceroute from the target back to the scanner. This could be useful if you're trying to determine network layout or something, and you can't get a forward traceroute to work. Like ping, it requires the SystemRoot variable. 

Output:
<pre>
|   Traceroute back to the scanner
|       1    <1 ms    <1 ms    <1 ms  10.0.0.138
</pre>


<h3>arp cache</h3>
<pre>mod = {}
mod.name             = "ARP Cache from arp.exe"
mod.program          = 'arp.exe'
mod.upload           = false
mod.args             = '-a'
mod.remove           = "Interface"
mod.noblank          = true
table.insert(modules, mod)</pre>
This one is easy -- dump the arp cache of the host using the "arp -a" command. No special options are required. 


<pre>|   ARP Cache from arp.exe
|       Internet Address      Physical Address      Type
|       10.0.0.138            00-50-56-a1-27-4b     dynamic</pre>

<h3>Connected ports</h3>
<pre>mod = {}
mod.upload           = false
mod.name             = "List of listening and established connections (netstat -an)"
mod.program          = "netstat"
mod.args             = "-an"
mod.maxtime          = 1
mod.remove           = {"Active"}
mod.noblank          = true
mod.env              = "SystemRoot=c:\\WINDOWS"
table.insert(modules, mod)</pre>
Dump the list of listening and established connections using "netstat -an". Like most other network-related configurations, this requires the SystemRoot variable to be set. 

<pre>|   List of listening and established connections (netstat -an)
|       Proto  Local Address          Foreign Address        State
|       TCP    0.0.0.0:22             0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:25             0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:80             0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:135            0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:443            0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:445            0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:1025           0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:1027           0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:1028           0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:3389           0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:4933           0.0.0.0:0              LISTENING
|       TCP    0.0.0.0:27453          0.0.0.0:0              LISTENING
|       TCP    10.0.0.30:139          0.0.0.0:0              LISTENING
|       TCP    10.0.0.30:445          10.0.0.138:34913       ESTABLISHED
|       TCP    127.0.0.1:1030         127.0.0.1:40000        ESTABLISHED
|       TCP    127.0.0.1:5152         0.0.0.0:0              LISTENING
|       TCP    127.0.0.1:40000        0.0.0.0:0              LISTENING
|       TCP    127.0.0.1:40000        127.0.0.1:1030         ESTABLISHED
|       UDP    0.0.0.0:135            *:*
|       UDP    0.0.0.0:445            *:*
|       UDP    0.0.0.0:1029           *:*
|       UDP    0.0.0.0:3456           *:*
|       UDP    10.0.0.30:137          *:*
|       UDP    10.0.0.30:138          *:*
|       UDP    10.0.0.30:500          *:*
|       UDP    10.0.0.30:4500         *:*
|       UDP    127.0.0.1:1026         *:*</pre>

<h3>Routing table</h3>
<pre>mod = {}
mod.upload           = false
mod.name             = "Full routing table from 'netstat -nr'"
mod.program          = "cmd.exe"
mod.args             = "/c \"netstat -nr\""
mod.env              = "PATH=C:\\WINDOWS\\system32;C:\\WINDOWS;C:\\WINNT;C:\\WINNT\\system32"
mod.maxtime          = 1
mod.noblank          = true
table.insert(modules, mod)</pre>
Dump the routing table using netstat -nr. This command has to be run in a separate command session (that's why we have cmd.exe /c "netsat -nr"). It also requires the PATH variable to contain the 'windows' and 'system32' folders -- I don't know why that is. 

Output:
<pre>|     IPv4 Route Table
|     ===========================================================================
|     Interface List
|     0x1 ........................... MS TCP Loopback interface
|     0x2 ...00 0b db 94 12 58 ...... Broadcom NetXtreme Gigabit Ethernet - Trend Micro Common Firewall Miniport
|     0x10004 ...00 0b db 94 12 59 ...... Broadcom NetXtreme Gigabit Ethernet #2 - Trend Micro Common Firewall Miniport
|     ===========================================================================
|     ===========================================================================
|     Active Routes:
|     Network Destination        Netmask          Gateway       Interface  Metric
|               0.0.0.0          0.0.0.0         10.0.0.1       10.0.0.250     20
|              10.0.0.0    255.255.255.0       10.0.0.250       10.0.0.250     20
|            10.0.0.250  255.255.255.255        127.0.0.1        127.0.0.1     20
|        10.255.255.255  255.255.255.255       10.0.0.250       10.0.0.250     20
|             127.0.0.0        255.0.0.0        127.0.0.1        127.0.0.1      1
|             224.0.0.0        240.0.0.0       10.0.0.250       10.0.0.250     20
|       255.255.255.255  255.255.255.255       10.0.0.250       10.0.0.250      1
|       255.255.255.255  255.255.255.255       10.0.0.250            10004      1
|     Default Gateway:          10.0.0.1
|     ===========================================================================
|     Persistent Routes:
|       None
</pre>

<h3>Boot configuration</h3>
<pre>mod = {}
mod.upload           = false
mod.name             = "Boot configuration"
mod.program          = "bootcfg"
mod.args             = "/query"
mod.maxtime          = 5
table.insert(modules, mod)
</pre>
Displays the boot configuration for the system. Only works on Windows XP or 2003 and above (not on Windows 2000). It'll tell you if you're on a system with multiple boot configurations, provided they're all Microsoft. 

Output:
<pre>|   Boot configuration
|
|     Boot Loader Settings
|     --------------------
|     timeout:30
|     default:multi(0)disk(0)rdisk(0)partition(1)\WINDOWS
|
|     Boot Entries
|     ------------
|     Boot entry ID:    1
|     OS Friendly Name: Windows Server 2003, Standard
|     Path:             multi(0)disk(0)rdisk(0)partition(1)\WINDOWS
|     OS Load Options:  /fastdetect /NoExecute=OptOut
</pre>

<h3>Drive details</h3>

{% raw %}
<pre>mod = {}
mod.upload           = false
mod.name             = "Drive list (for more info, try adding --script-args=config=drives,drive=C:)"
mod.program          = "fsutil"
mod.args             = "fsinfo drives"
mod.replace          = {{string.char(0), " "}}
mod.maxtime          = 1</pre>
Finally, this is probably the simplest script, in terms of output. It simply prints a list of the known drive letters on the system. The trick to this one, though, is that for some insane reason the spaces in the output are actually NULL characters ('\0'). Originally, only one drive was showing up. After troubleshooting it for awhile and finding the issue, I added the mod.replace line and everything worked find. It just goes to show that some developers are just plain insane.

Output:
<pre>|   Drive list (for more info, try adding --script-args=config=drives,drive=C:)
|     Drives:
|     A:\ C:\ D:\ F:\
</pre>
{% endraw %}


<h3>Conclusion</h3>
So there you have it, my default configuration file on smb-psexec.nse. I tried to balance the output between speed, size, and usefulness of information, and I hope you agree that the information is valuable. 

I'm always happy to change the defaults, though, if you have some better ideas/options/whatever. 


See you at Shmoocon!
Ron
