---
title: 'Wiki: Dnstest'
author: ron
layout: wiki
permalink: "/wiki/Dnstest"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Dnstest"
---

## Intro

This program simply checks whether or not you have the authoritative nameserver for a given domain. It is implicitly called by the other dns\* programs I\'ve written, all it does is look up a random subdomain and see if the response comes back.

## Usage

    ./dnstest --domain <domain>

     -h --help
        Help (this page).
     -d --domain <domain>
        The domain name to check. The lookup will be for [random].domain.
     --dns <server>
        Set the DNS server. Default: the system's first DNS server.
     -s --source <address>
        The local address to bind to. Default: any (0.0.0.0)
     -p --port <port>
        The local port to listen on. I don't recommend changing this.
        default: 53.
     --rport <port>
        The port to send the request to. Default: 53.
     -u --username
        Drop privileges to this user after opening socket (default: 'nobody')
     -V --version
        Print the version and exit

## Example

There isn\'t really much to this program, but here\'s how it looks running on my laptop (which is the authoritative server for skullseclabs.org):

    $ sudo ./dnstest
    Listening for requests on 0.0.0.0:53
    Sending request to 208.81.7.10:53
    Trying to look up domain: avobwnjlopakgmdt.skullseclabs.org
    Received a response: avobwnjlopakgmdt.skullseclabs.org
    Contgratulations, you have the proper DNS server for this domain!
