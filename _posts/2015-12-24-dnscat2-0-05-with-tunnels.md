---
id: 2220
title: 'dnscat2 0.05: with tunnels!'
date: '2015-12-24T12:36:18-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2220
permalink: "/2015/dnscat2-0-05-with-tunnels"
categories:
- dns
- hacking
- tools
comments_id: '109638374034329955'

---

Greetings, and I hope you're all having a great holiday!

My Christmas present to you, the community, is dnscat2 version 0.05!

Some of you will remember that I recently <a href='https://docs.google.com/presentation/d/1Jxh6PPO9JbUqXwOCTQFyA00uQoFMDBh-1PedDOp1Z0Y'>gave a talk</a> at the SANS Hackfest Summit. At the talk, I mentioned some ideas for future plans. That's when <a href='https://twitter.com/edskoudis'>Ed</a> jumped on the stage and took a survey: which feature did the audience want most?

The winner? Tunneling TCP via a dnscat. So now you have it! Tunneling: Phase 1. :)

<a href='https://github.com/iagox86/dnscat2/releases/tag/v0.05'>Info and downloads</a>.
<!--more--><style>.in { color: #dc322f; font-weight: bold; }</style>
<h2>High-level</h2>

There isn't a ton to say about this feature, so this post won't be particularly long. I'll give a quick overview of how it works, how to use it, go into some quick implementation details, and, finally, talk about my future plans.

On a high level, this works exactly like ssh with the <tt>-L</tt> argument: when you set up a port forward in a dnscat2 session, the dnscat2 server will listen on a specified port. Say, port 2222. When a connection arrives on that port, the connection will be sent - via the dnscat2 session and out the dnscat2 client - to a specified server.

That's pretty much all there is to it. The user chooses which ports to listen on, and which server/port to connect to, and all connections are forwarded via the tunnel.

Let's look at how to use it!

<h2>Usage</h2>

Tunneling must be used within a dnscat2 session. So first you need one of those, no special options required:

<pre>
(server)

# <span class='in'>ruby ./dnscat2.rb</span>
New window created: 0

[...]

dnscat2&gt;
</pre>

<pre>
(client)

$ <span class='in'>./dnscat --dns="server=localhost,port=53"</span>
Creating DNS driver:
 domain = (null)
 host   = 0.0.0.0
 port   = 53
 type   = TXT,CNAME,MX
 server = localhost

Encrypted session established! For added security, please verify the server also displays this string:

Encode Surfs Taking Spiced Finer Sonny

Session established!
</pre>

We, of course, take the opportunity to validate the six words - "Encode Surfs Taking Spiced Finer Sonny" - to make sure nobody is performing a man-in-the-middle attack against us (considering this is directly to localhost, it's probably okay :) ).

Once you have a session set up, you want to tell the session to listen with the <tt>listen</tt> command:

<pre>
New window created: 1
Session 1 security: ENCRYPTED BUT *NOT* VALIDATED
For added security, please ensure the client displays the same string:

&gt;&gt; Encode Surfs Taking Spiced Finer Sonny

dnscat2&gt; <span class='in'>session -i 1</span>
[...]
dnscat2&gt; <span class='in'>listen 8080 www.google.com:80</span>
Listening on 0.0.0.0:8080, sending connections to www.google.com:80
</pre>

Now the dnscat2 server is listening on port 8080. It'll continue listening on that port until the session closes.

The dnscat2 client, however, has no idea what's happening yet! The client doesn't know what's happening until it's actually told to connect to something with a <tt>TUNNEL_CONNECT</tt> message (which will be discussed later).

Now we can connect to the server on port 8080 and request a page:

<pre>
$ <span class='in'>echo -ne 'HEAD / HTTP/1.0\r\n\r\n' | nc -vv localhost 8080</span>
localhost [127.0.0.1] 8080 (http-alt) open
HTTP/1.0 200 OK
Date: Thu, 24 Dec 2015 16:28:27 GMT
Expires: -1
Cache-Control: private, max-age=0
[...]
</pre>

On the server, we see the request going out:

<pre>
command (ankh) 1&gt; <span class='in'>listen 8080 www.google.com:80</span>
Listening on 0.0.0.0:8080, sending connections to www.google.com:80
command (ankh) 1&gt;
Connection from 127.0.0.1:60480; forwarding to www.google.com:80...
[Tunnel 0] connection successful!
[Tunnel 0] closed by the other side: Server closed the connection!
Connection from 123.151.42.61:48904; forwarding to www.google.com:80...
</pre>

And you also see very similar messages on the client:

<pre>
Got a command: TUNNEL_CONNECT [request] :: request_id 0x0001 :: host www.google.com :: port 80
[[ WARNING ]] :: [Tunnel 0] connecting to www.google.com:80...
[[ WARNING ]] :: [Tunnel 0] connected to www.google.com:80!
[[ WARNING ]] :: [Tunnel 0] connection to www.google.com:80 closed by the server!
</pre>

That's pretty much all you need to know! One more quick example:

To forward a ssh connection to an internal machine:
<pre>
command (ankh) 1&gt; <span class='in'>listen 127.0.0.1:2222 192.168.1.100:22</span>
</pre>

Followed by <tt>ssh -p2222 root@localhost</tt>. That'll connect to 192.168.1.100 on port 22, via the dnscat client!

<h2>Stopping a session</h2>

I frequently used auto-commands while testing this feature:

<pre>
ruby ./dnscat2.rb --dnsport=53531 --security=open --auto-attach --auto-command="listen 2222 www.javaop.com:22;listen 1234 www.google.ca:1234;listen 4444 localhost:5555" --packet-trace
</pre>

The problem is that I'd connect with a client, hard-kill it with ctrl-c (so it doesn't tell the server it's gone), then start another one. When the second client connects, the server won't be able to listen anymore:

<pre>
Listening on 0.0.0.0:4444, sending connections to localhost:5555
Sorry, that address:port is already in use: Address already in use - bind(2)

If you kill a session from the root window with the 'kill'
command, it will free the socket. You can get a list of which
sockets are being used with the 'tunnels' command!

I realize this is super awkward.. don't worry, it'll get
better next version! Stay tuned!
</pre>

If you know which session is the problem, it's pretty easy.. just kill it from the main window (Window 0 - press ctrl-z to get there):

<pre>
dnscat2&gt; <span class='in'>kill 1</span>
Session 1 has been sent the kill signal!
Session 1 killed: No reason given
</pre>

If you don't know which session it is, you have to go into each session and run <tt>tunnels</tt> to figure out which one is holding the port open:

<pre>
dnscat2&gt; <span class='in'>session -i 1</span>
[...]
command (ankh) 1&gt; <span class='in'>tunnels</span>
Tunnel listening on 0.0.0.0:2222
Tunnel listening on 0.0.0.0:1234
Tunnel listening on 0.0.0.0:4444
</pre>

Once that's done, you can either use the 'shutdown' command (if the session is still active) or go back to the main window and use the <tt>kill</tt> command.

I realize that's super awkward, and I have a plan to fix it. It's going to require some refactoring, though, and it won't be ready for a few more days. And I really wanted to get this release out before Christmas!

<h2>Implementation details</h2>

As usual, the implementation is documented in detail in the <a href='https://github.com/iagox86/dnscat2/blob/master/doc/protocol.md'>protocol.md</a> and <a href='https://github.com/iagox86/dnscat2/blob/master/doc/command_protocol.md'>command_protocol.md</a> docs.

Basically, I extended the "command protocol", which is the protocol that's used for commands like <tt>upload</tt>, <tt>download</tt>, <tt>ping</tt>, <tt>shell</tt>, <tt>exec</tt>, etc.

Traditionally, the command protocol was purely the server making a request and the client responding to the request. For example, "download /etc/passwd" "okay, here it is". However, the tunnel protocol works a bit differently, because either side can send a request.

Unfortunately, the client sending a request to the server, while it was something I'd planned and written code for, had a fatal flaw: there was no way to identify a request as a request, and therefore when the client sent a request to the server it had to rely on some rickety logic to determine if it was a request or not. As a result, I made a tough call: I broke compatibility by adding a one-bit "is a response?" field to the start of <tt>request_id</tt> - responses now have the left-most bit set of the <tt>request_id</tt>.

At any time - presumably when a connection comes in, but we'll see what the future holds! - the server can send a <tt>TUNNEL_CONNECT</tt> request to the client, which contains a hostname and port number. That tells the client to make a connection to that host:port, which it attempts to do. If the connection is successful, the client responds with a <tt>TUNNEL_CONNECT</tt> response, which simply contains the <tt>tunnel_id</tt>.

From then on, data can be sent in either direction using <tt>TUNNEL_DATA</tt> requests. This is the first time the client has been able to send a request to the server, and is also the first time a message was defined that doesn't have a response - neither side should (or can) respond to a <tt>TUNNEL_DATA</tt> message. Which is fine, because we have guaranteed delivery from lower level protocols.

When either side decides to terminate the connection, it sends a <tt>TUNNEL_CLOSE</tt> request, which contains a <tt>tunnel_id</tt> and a reason string.

One final implementation detail: <tt>tunnel_id</tt>s are local to a session.

<h2>Future plans</h2>

As I said at the start, I've implemented <tt>ssh -L</tt>. My next plans are to implement <tt>ssh -D</tt> (easysauce!) and <tt>ssh -R</tt> (hardersauce!). I also have some other fun ideas on what I can do with the tunnel protocol, so stay tuned for that. :)

The tricky part about <tt>ssh -R</tt> is keeping it secure. The client shouldn't be able to arbitrarily forward connections via the server - the server should be able to handle malicious clients securely, at least by default. Therefore, it's going to require some extra planning and architecting!

<h2>Conclusion</h2>

And yeah, that's pretty much it! As always, if you like this blog or the work I'm doing on dnscat2, you can <a href='https://www.patreon.com/iagox86'>support me on Patreon</a>! Seriously, I have no ads or monetization on my site, and I spend more money on hosting password lists than I make off it, so if you wanna be awesome and help out, I really, really appreciate it! :)

And as always, I'm happy to answer questions or take feature requests! You're welcome to email me, reply to this blog, or file an <a href='https://github.com/iagox86/dnscat2/issues'>issue on Github</a>!
