---
title: 'Wiki: DSRelay'
author: ron
layout: wiki
permalink: "/wiki/DSRelay"
date: '2024-08-04T15:51:38-04:00'
---

## Dead (Damn?) Simple Relay {#dead_damn_simple_relay}

-   Name: Dead Simple Relay
-   OS: Windows (for now)
-   Language: C
-   Path: <http://svn.skullsecurity.org:81/ron/security/DSRelay>
-   Created: 2008-07
-   State: In development
-   License: BSD

## TODO

-   Move the relay stuff into a module
-   Add support for \*nix
-   Clean up the commandline interface

## Description

This is essentially an N-way relay for sockets. It can listen on a port and connect outbound to any number of others. This type of relay can be useful for penetration testing; the attacker exploits a server to get a shell, drops this on, and can relay additional attacks through it.

    Usage: dsrelay [options] [<host:port> [<host:port>[<host:port>[...]]]]

    Options
    -l <port>      Listen for incoming connections
    -w             Wait for an incoming connection before making outbound
                   connections (must be in listen mode). Use multiple 'w's to
                   wait for multiple incoming connections (-ww, -www, -www, ...)
    -W <N>         As -w, but wait for N incoming connections
    -v             Be verbose (print notifications for connects/disconnects)
    -vv            Be very verbose (print notifications for packets)
    -d             Show raw data
    -dd            Show raw data with some context
    -s             Sanitize the raw data (replace non-printable characters,
                   including newlines)
    -t <N>         Terminate when there are <=N active connections (default 0)
                   Note: only happens after waiting (-w) threshold is reached
    -T             Terminates when any connection closes
    -e             Terminate on any winsock error (eg, failed connection)
    -r             Restarts each outbound connection when any connection ends

    Either -l or multiple outgoing connections must be given.

    Example 1, to create a relay between localhost and Google, watching data:
    c:\> dsrelay -vv -dd -eT -w -l 80 www.google.ca:80

    Example 2, to create an outbound-only tunnel to Google, watching data:
    c:\> dsrelay -eT localhost:4444 www.google.ca:80

    Example 3, to create a tunnel to a locally-running VNC server, with a monitor
               (listens on 5901 (vnc:1), relays data to 5900 (vnc:0), and copies it
               to 4444 (presumably a netcat listener)
    c:\> dsrelay -w -e -T -l 5901 localhost:5900 localhost:4444

    Example 4, to forward a Hydra attack against a FTP server
               (here, we use a second connection (probably a netcat client) to
               the connection. Every time Hydra reconnects, the connection resets,
               but when the other disconnects, it falls below the threshold of 1
               connection and the session terminates.
               Note: Hydra must be set to one connection (-t1) for this to work.

## SVN

    svn co http://svn.skullsecurity.org:81/ron/security/DSRelay
