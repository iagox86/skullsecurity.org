---
title: 'Wiki: Dnsxss'
author: ron
layout: wiki
permalink: "/wiki/Dnsxss"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Dnsxss"
---

## Intro

[dnsxss](dnsxss "wikilink") is designed to send back malicious responses to DNS queries in order to test DNS lookup servers for common classes of vulnerabilities. By default, dnsxss returns a string containing some Javascript code to all MX, CNAME, NS, and TEXT requests, in the hopes that the DNS lookup will be displayed in a browser.

When I originally wrote this, I tested it on a handful of Internet sites. Every one of them was vulnerable.

I haven\'t tried testing other vulnerabilities, like SQL injection or shell injection, but I suspect that this is a great attack vector for those and other vulnerabilities, because people don\'t realize that malicious traffic can be returned.

## Usage

    ./dnsxss [-t <test string>]
     -a <address>
        The address sent back to the user when an A request is made. Can be used
        to disguise this as a legitimate DNS server. Default: 127.0.0.1.
     -aaaa <address>
        The address sent back to the user when an AAAA (IPv6) request is made. Can
        be used to disguise this as a legitimate DNS server. Default: ::1.
     -d <domain>
        The domain to put after the test string. It should be the same as the
        one that points to your host.
     -h
        Help
     --payload <data>
        The string containing the HTML characters, that will ultimately test for
        the cross-site scripting vulnerability. Ultimately, this can contain any
        type of attack, such as sql-injection. One thing to note is that DNS
        generally seems to filter certain characters; in my testing, anything with
        an ASCII code of 0x20 (Space) or lower was replaced with an escaped
        /xxx, and brackets had a backslash added before them.
        Default:
        <script src='http://www.skullsecurity.org/test-js.js'></script>
        Note that unless a TEXT record is requested, spaces are replaced with
        slashes ('/'), which work in Firefox but not IE.
     --keep-spaces
        By default, spaces in the payload are replaced with slashes ('/') because
        the DNS protocol doesn't like spaces. Use this flag to bypass that
        filter.
     --test <domain>
        Test to see if we are the authoritative nameserver for the given domain.
     -u --username
        The username to use when dropping privileges. Default: nobody.
     -s --source <address>
        The local address to bind to. Default: any (0.0.0.0)
     -p --port <port>
        The local port to listen on. I don't recommend changing this.
        default: 53

------------------------------------------------------------------------

## Examples

Running this program without arguments returns a pretty typical cross-site scripting string:

    $ dig @localhost -t TXT test
    [...]
    ;; ANSWER SECTION:
    test.                   1       IN      TXT     "<script src='http://www.skullsecurity.org/test-js.js'></script>.test"

This will display a messagebox on the user\'s screen alerting them to the issue. You can change the payload using the \--payload argument and point it at, for example, a BeEF server.

## Authoritative DNS server {#authoritative_dns_server}

Many functions of this tool require you to be the authoritative nameserver for a domain. This typically costs money, but is fairly cheap and has a lot of benefits. If you aren\'t sure whether or not you\'re the authority, you can use the \--test argument to this program, or you can directly run the [dnstest](dnstest "wikilink") program, also included.
