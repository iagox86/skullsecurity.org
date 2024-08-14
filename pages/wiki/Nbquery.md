---
title: 'Wiki: Nbquery'
author: ron
layout: wiki
permalink: "/wiki/Nbquery"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Nbquery"
---

## Intro

[nbquery](nbquery "wikilink") is capable of sending out any type of NetBIOS request. These request types include:

-   NB
-   NBSTAT
-   Register
-   Refresh
-   Release
-   Conflict
-   Demand

More on what each of them do below.

One thing worth noting about the NetBIOS protocol is that it is nearly identical to DNS. In fact, it\'s close enough that this script uses the DNS library to \* build requests. The primary differences between NetBIOS and DNS are:

-   How names are encoded (NetBIOS names are encoded before being sent),
-   How the flags are used (NetBIOS has a different set of flags), and
-   How requests are sent (NetBIOS is capable of broadcasting requests

The \'dns\' library I wrote can easily deal with these differences, so it is used for building dns queries.

## Usage

    Usage: ./nbquery [options] <action>
     -h --help
        Help (this screen).
     -t --target <targetip>
        The address to send the request. For simple NB requests to the local
        network, the default (broadcast; '255.255.255.255') works. If you want to
        get full information (-t NBSTAT) or get information for a non-local network,
        this should be set to the target address.
     -s --source <sourceip>
     -p --port <port>
        Choose a port besides the default (137). Not generally useful, since Windows
        runs NetBIOS Name Service on UDP/137.
     -w --wait <ms>
        The amount of time, in milliseconds, to wait for repsonses. Default: 500ms.
     -V --version
        Print version and exit.
    Actions (must choose exactly one):
     --nb [name[:<suffix>]]
        Query for a NetBIOS name. Queries for any name by default ('*'). If you're
        looking for a specific server, say, 'TEST01', set the name to that to that
        name. You can optionally add the one-byte suffix after the name, such as
        'TEST01:03', but that isn't too common
     --nbstat [name[:<suffix>]]
        Query for a NetBIOS status. Format is the same as --nb.
     --register <name>
        Send out a notice that you're going to be using the given name.
        If any systems are already using the name, they will respond with a
        conflict.
     --refresh <name>
        Send out a notice that you're refreshing your use of a name. I haven't seen
        this provoke a response before, so it might be useless.
     --release <name>
        Send a notice that you're done using a name. If somebody else owns that
        name, they will generally return an error.
     --conflict <name>
        Sent immediately after somebody else registers, this informs the system
        that they aren't the rightful owner of a name and they should not use it.
        To automate this, see the 'nbsniff' tool with --poison.
     --demand <name>
        Demands that another system releases the name. Typically isn't implemented
        for security reasons. Again, see 'nbsniff --poison'.

## NB

A standard NB (NetBIOS) query, sent when \--nb is passed can do several things:

1.  Ask who owns a particular name
2.  Ask who is on the local segment (doesn\'t work against all hosts)
3.  Ask if a particular system has a name

The first two points require a broadcast \-- by default, we broadcast to the global broadcast address, 255.255.255.255, but I noticed that that doesn\'t always work, so you may need to pass your local broadcast address, \"-t x.x.x.255\" (where \"x.x.x\" is the start of your address).

Asking who owns a particular name is a technique used by Windows when it fails to find a host in DNS. This allows it to find hosts on the local network with a given name. Broadcasting for a name is obviously a bad idea; more on that in [nbsniff](nbsniff "wikilink").

Here\'s how it looks on nbquery:

    $ ./nbquery --nb=WINDOWSXP
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:WINDOWSXP      <00|workstation>): success, IP: 192.168.1.106, TTL: 300000s

    $ ./nbquery --nb=VISTA -t 192.168.1.255
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:VISTA          <00|workstation>): success, IP: 192.168.1.102, TTL: 300000s

(\'WINDOWSXP\' and \'VISTA\' are what I named my test systems)

The second use is asking who is on a local network. I\'ve found that this only works against certain systems; mostly Windows 2000. But here\'s how it\'s done:

    $ ./nbquery --nb
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:*<00|workstation>): success, IP: 192.168.1.109, TTL: 300000s

Finally, asking if somebody owns a name is silly, but it can be done using the -t argument:

    $ ./nbquery --nb=WINDOWSXP -t 192.168.1.106
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:WINDOWSXP      <00|workstation>): success, IP: 192.168.1.106, TTL: 300000s

## NBSTAT

NBSTAT goes further than NetBIOS. It is targeted against a specific host and asks that host for a list of all names it thinks it owns. The Windows program nbtstat does this, as well as the opensource nbtscan program.

This usage is pretty simple:

    $ ./nbquery --nbstat -t 192.168.1.106
    Creating a UDP socket.
    Sending query.
    NBSTAT response: Received 4 names; success (MAC: 00:0c:29:07:69:b0)
    ANSWER: (NBSTAT:*<00|workstation>): WINDOWSXP<00> <unique><active> (0x0400)
    ANSWER: (NBSTAT:*<00|workstation>): WINDOWSXP<20> <unique><active> (0x0400)
    ANSWER: (NBSTAT:*<00|workstation>): WORKGROUP<00> <group><active> (0x8400)
    ANSWER: (NBSTAT:*<00|workstation>): WORKGROUP<1e> <group><active> (0x8400)

    ron@ankh:~/tools/nbtool$ ./nbquery --nbstat -t 192.168.1.109
    Creating a UDP socket.
    Sending query.
    NBSTAT response: Received 6 names; success (MAC: 00:0c:29:f5:81:bd)
    ANSWER: (NBSTAT:*<00|workstation>): WINDOWS2000<00> <unique><active> (0x0400)
    ANSWER: (NBSTAT:*<00|workstation>): WINDOWS2000<03> <unique><active> (0x0400)
    ANSWER: (NBSTAT:*<00|workstation>): SKULLSECURITY<00> <group><active> (0x8400)
    ANSWER: (NBSTAT:*<00|workstation>): RON<03> <unique><active> (0x0400)
    ANSWER: (NBSTAT:*<00|workstation>): SKULLSECURITY<1e> <group><active> (0x8400)

## Register, Renew, Release {#register_renew_release}

The register, renew, and release queries are all very similar \-- they\'re designed to emulate the actions that Windows itself takes while booting and shutting down.

When a Windows computer boots, the first thing it does is send out a \'register\' request for its own name. It does this to let the other systems know that it intends to use that name. If another system already has that name, it sends back a conflict and the new system will give it up until the next boot. More on conflicts in [nbsniff](nbsniff "wikilink").

The register and release commands (activated by \--register and \--release) will generally provoke a response if a system is already using a name, whereas renew, in my experience, has never provokes a response.

Here is an example of the three of them, in the typical order that Windows would send them:

    $ ./nbquery --register=WINDOWS2000
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:WINDOWS2000    <00|workstation>): error: active, IP: 192.168.1.109, TTL: 0s

    ron@ankh:~/tools/nbtool$ ./nbquery --refresh=WINDOWSXP
    Creating a UDP socket.
    Sending query.
    Wait time has elapsed.

    ron@ankh:~/tools/nbtool$ ./nbquery --release=VISTA
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:VISTA          <00|workstation>): error: name not found, IP: 0.0.0.0, TTL: 0s

Note that the \--register provoked \"error: active\", whereas \--release provoked \"error: name not found\".

As before, WINDOWS2000, WINDOWSXP, and VISTA are the namef of my test systems.

One of those best uses of these programs is to test [nbsniff](nbsniff "wikilink").

## Conflict, Demand {#conflict_demand}

Conflict and demand (activated with \--conflict and \--demand) are ways of asking hosts to relinquish their name. Neither are supported by any modern NetBIOS implementation, though; I added them for completeness.

\--demand is actually the same as \--release, except that \--demand expects to be unicast and \--release expects to be broadcast.
