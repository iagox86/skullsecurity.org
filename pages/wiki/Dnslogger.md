---
title: 'Wiki: Dnslogger'
author: ron
layout: wiki
permalink: "/wiki/Dnslogger"
date: '2024-08-04T15:51:38-04:00'
---

## Intro

[dnslogger](dnslogger "wikilink") has two primary functions:

1.  Print all received DNS requests
2.  Reply to them with an error or a static ip address (IPv4 or IPv6)

This is obviously very simple, but is also powerful.

## DOWNLOAD

You can download the source from here: <https://github.com/iagox86/nbtool>

You can download a binary from here, as part of nbtool: <https://downloads.skullsecurity.org/>

## Usage

     -h --help
        Help (this page)
     --test <domain>
        Test to see if we are the authoritative nameserver for the given domain.
     -s --source <address>
        The local address to bind to. Default: any (0.0.0.0)
     -p --port <port>
        The local port to listen on. I don't recommend changing this.
        default: 53
     -A <address>
        The A record to return when a record is requested. Default: NXDOMAIN.
     --AAAA <address>
        The AAAA record to return when a record is requested. Default: NXDOMAIN.
     --TTL <time>
        The time-to-live value to send back, in seconds. Default: 1 second.
     -u --username
        Drop privileges to this user after opening socket (default: 'nobody')
     -V --version
        Print the version and exit

## Printing requests {#printing_requests}

Printing DNS requests has a lot of uses. Essentially, it\'ll tell you if a program tried to connect to your site, without the program ever attempting the connection. There are a great number of possible uses for that:

-   Finding open proxies without making an actual connection through it
-   Finding open mail relays without sending an email through it
-   Finding errors in mail-handling code on a site
-   Finding shell injection on a Web application without outbound traffic or delays
-   Checking if a user visited a certain page

In every one of those cases, the server will try to look up the domain name to perform some action, and fails. For example, to find an open proxy you can connect to the potential proxy and send it \"CONNECT `<yourdomain>`\". If the proxy server is indeed open, it\'ll do a lookup on `<yourdomain>` and you\'ll see the request. Then, by default, an error is returned, so the proxy server gives up on attempting the connection and it\'s never logged. That\'s really the key \-- the connection attempt never gets logged.

Likewise, shell injection. If you\'re testing an application for shell injection, you can send it the payload \'ping `<yourdomain>`\' to run. a vulnerable server will attempt to ping the domain and perform a DNS lookup. By default, the DNS lookup will fail, and the server won\'t perform the ping. It\'ll look like this:

    $ ping www.skullseclabs.org
    ping: unknown host www.skullseclabs.org

dnslogger, however, will have seen the request and we therefore know that the application is vulnerable. This is far more reliable than the classic \'ping localhost 4 times and see if it takes 3 seconds\' approach to finding shell injection.

One final note is discovering Web applications that handle email incorrectly. A classic vulnerability when sending email, besides shell injection, is letting the user terminate the email with a \".\" on its own line, then start a new email. Something like this:

    This is my email, hello!
    .
    mail from: test@test.com
    rcpt to: test@<yourdomain>
    data
    This email won't get sent!

So the first email was terminated on the second line, with a period. A new email is composed to test@`<yourdomain>`. If the application is vulnerable to this type of attack, it will attempt to look up `<yourdomain>` so it can send an email there. We\'ll see the request, respond with an error, and the request will never be sent.

## Controlling the response {#controlling_the_response}

In addition to logging requests, dnslogger can also respond with arbitrary A or AAAA records to any incoming request. A long time ago, at work, I used a Visual Basic program I found somewhere called \"FakeDNS\" that accomplished a similar task, but I\'ve since lost it and decided to implement it myself. Some potential uses of this program are:

-   Investigating malware that connects to a remote host
-   Redirecting users if you control their DNS server
-   Redirecting a legitimate program to your own server

The first use is actually the one I created this for \-- investigating malware. One of the most common types of malware I\'m asked to investigate at work is a classic downloader, which reaches out to the Internet and downloads its payload. Almost always, it uses a DNS server to find the malware. By setting the system\'s dns to the dnslogger DNS server, all DNS lookups will be seen (for later investigation), and you can control which server it tries to connect to to download the files.

Another potential use, and somewhat malicious, is, if you control the DHCP server on a victim\'s computer, you can point their DNS to a malicious host, perhaps one running a password-stealer or Metasploit payload, and do what you want.

One final use, which takes me back to the old days of Battle.net programming, is redirecting a legitimate program with a hardcoded domain. For example, Battle.net used to default to useast.battle.net, uswest.battle.net, etc. Although you could change these servers in the registry, another option is to point your system DNS to dnslogger and let it redirect the requests for you.

## Authoritative DNS server {#authoritative_dns_server}

Many functions of this tool require you to be the authoritative nameserver for a domain. This typically costs money, but is fairly cheap and has a lot of benefits. If you aren\'t sure whether or not you\'re the authority, you can use the \--test argument to this program, or you can directly run the [dnstest](dnstest "wikilink") program, also included.
