---
id: 2194
title: 'dnscat2: now with crypto!'
date: '2015-11-17T11:43:47-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2194
permalink: "/2015/dnscat2-now-with-crypto"
categories:
- conferences
- dns
- hacking
- tools
comments_id: '109638373226532540'

---

Hey everybody,

Live from the <a href='https://www.sans.org/event/pen-test-hackfest-2015'>SANS Pentest Summit</a>, I'm excited to announce the latest beta release of dnscat2: <a href='https://github.com/iagox86/dnscat2/releases/tag/v0.04'>0.04</a>! Besides some minor cleanups and UI improvements, there is one serious improvement: all dnscat2 sessions are now encrypted by default!

Read on for some user information, then some implementation details for those who are interested! For all the REALLY gory information, check out the <a href='https://github.com/iagox86/dnscat2/blob/master/doc/protocol.md#encryption--signing'>protocol doc</a>!
<!--more-->
<h2>Tell me what's new!</h2>

By default, when you start a dnscat2 client, it now performs a key exchange with the server, and uses a derived session key to encrypt all traffic. This has the <em>huge</em> advantage that passive surveillance and IDS and such will no longer be able to see your traffic. But the disadvantage is that it's vulnerable to a man-in-the-middle attack - assuming somebody takes the time and effort to perform a man-in-the-middle attack against dnscat2, which would be awesome but seems unlikely. :)

By default, all connections are encrypted, and the server will refuse to allow cleartext connections. If you start the server with <tt>--security=open</tt> (or run <tt>set security=open</tt>), then the client decides the security level - including cleartext.

If you pass the server a --secret string (see below), then the server will require clients to authenticate using the same --secret value. That can be turned off by using <tt>--security=open</tt> or <tt>--security=encrypted</tt> (or the equivalent set commands).

Let's look at the man-in-the-middle protection...

<h3>Short authentication strings</h3>

First, by default, a short authentication string is displayed on both the client and the server. Short authentication strings, inspired by <a href='https://en.wikipedia.org/wiki/ZRTP#Authentication'>ZRTP and Silent Circle</a>, are a visual way to tell if you're the victim of a man-in-the-middle attack.

Essentially, when a new connection is created, the user has to manually match the short authentication strings on the client and the server. If they're the same, then it's a legit connection. Here's what it looks like on the client:

<pre>
Encrypted session established! For added security, please verify the server also displays this string:

Tort Hither Harold Motive Nuns Unwrap
</pre>

And the server:

<pre>
New window created: 1
Session 1 security: ENCRYPTED BUT *NOT* VALIDATED
For added security, please ensure the client displays the same string:

&gt;&gt; Tort Hither Harold Motive Nuns Unwrap
</pre>

There are 256 different possible words, so six words gives 48 bits of protection. While a 48-bit key can eventually be bruteforced, in this case it has to be done in real time, which is exceedingly unlikely.

<h3>Authentication</h3>

Alternatively, a pre-shared secret can be used instead of a short authentication string. When you start the server, you pass in a --secret value, such as <tt>--secret=pineapple</tt>. Clients with the same secret will create an authenticator string based on the password and the cryptographic keys, and send it to the server, encrypted, after the key exchange. Clients that use the wrong key will be summarily rejected.

Details on how this is implemented are below.

<h2>How stealthy is it?</h2>

To be perfectly honest: not completely.

The key exchange is pretty obvious. A 512-bit value has to be sent via DNS, and a 512-bit response has to come back. That's pretty big, and stands out.

After that, every packet has an unencrypted 40-bit (5-byte) header and an unencrypted 16-bit (2-byte) nonce. The header contains three bytes that don't really change, and the nonce is incremental. Any system that knows to look for dnscat2 will be able to find that.

It's conceivable that I could make this more stealthy, but anybody who's already trying to detect dnscat2 traffic will be able to update the signatures that they would have had to write anyway, so it becomes a cat-and-mouse game.

Of course, that doesn't stop people from patching things. :)

The plus side, however, is that none of your data leaks! And somebody would have to be specifically looking for dnscat2 traffic to recognize it.

<h2>What are the hidden costs?</h2>

Encrypted packets have 64 bits (8 bytes) of extra overhead: a 16-bit (two-byte) nonce and a 48-bit (six-byte) signature on each packet. Since DNS packets have between 200 and 250 bytes of payload space, that means we lose ~4% of our potential bandwidth.

Additionally, there's a key exchange packet and potentially an authentication packet. That's two extra roundtrips over a fairly slow protocol.

Other than that, not much changes, really. The encryption/decryption/signing/validation are super fast, and it uses a stream cipher so the length of the messages don't change.

<h2>How do I turn it off?</h2>

The server always supports crypto; if you don't WANT crypto, you'll have to manually hack the server or use a version of dnscat2 server &lt;=0.03. But you'll have to manually turn off encryption in the client; otherwise, the connection fail.

Speaking of turning off encryption in the client: you can compile without encryption by using <tt>make nocrypto</tt>. You can also disable encryption at runtime with <tt>dnscat2 --no-encryption</tt>. On Visual Studio, you'll have to define "NO_ENCRYPTION". Note that the server, by default, won't allow either of those to connect unless you start it with <tt>--security=open</tt>.

<h2>Give me some technical details!</h2>

Your best bet if you're <em>REALLY</em> curious is to check out <a href='https://github.com/iagox86/dnscat2/blob/master/doc/protocol.md#encryption--signing'>the protocol doc</a>, where I document the protocol in full.

But I'll summarize it here. :)

The client starts a session by initiating a key exchange with the server. Both sides generate a random, 256-bit private key, then derive a public key using Elliptic Curve Diffie Hellman (ECDH). The client sends the public key to the server, the server sends a public key to the client, and they both agree on a shared secret.

That shared secret is hashed with a number of different values to derive purpose-specific keys - the client encryption key, the server encryption key, the client signing key, the server signing key, etc.

Once the keys are agreed upon, all packets are encrypted and signed. The encryption is salsa20 and uses one of the derived keys as well as an incremental nonce. After being encrypted, the encrypted data, the nonce, and the packet header are signed using SHA3, but truncated to 48 bits (6 bytes). 48 bits isn't very long for a signature, but space is at an extreme premium and for most attacks it would have to be broken in real time.

As an aside: I really wanted to encrypt the header instead of just signing it, but because of protocol limitations, that's simply not possible (because I have no way of knowing which packets belong to which session, the session_id has to be plaintext).

Immediately after the key exchange, the client optionally sends an authenticator over the encrypted session. The authenticator is based on a pre-shared secret (passed on the commandline) that the client and server pre-arrange in some way. That secret is hashed with both public keys and the secret (derived) key, as well as a different static string on the client and server. The client sends their authenticator to the server, and the server sends their authenticator to the client. In that way, both sides verify each other without revealing anything.

If the client doesn't send the authenticator, then a short authentication string is generated. It's based on a very similar hash to the authenticator, except without the pre-shared secret. The first 6 bytes are converted into words using a list of 256 English words, and are displayed on the screen. It's up to the user to verify them.

Because the nonce is only 16 bits, only 65536 roundtrips can be performed before running out. As such, the client may, at its own discretion (but before running out), initiate a new key exchange. It's identical to the original key exchange, except that it happens in a signed and encrypted packet. After the renegotiation is finished, both the client and server switch their nonce values back to 0 and stop accepting packets with the old keys.

And... that's about it! Keys are exchanged, an authenticator is sent or a short authentication string is displayed, all messages are signed and encrypted, and that's that!

<h2>Challenges</h2>

A few of the challenges I had to work through...

<ul>
  <li>Because DNS has no concept of connections/sessions, I had to expose more information that I wanted in the packets (and because it's extremely length-limited, I had to truncate signatures)</li>
  <li>I had originally planned to use Curve25519 for the key exchange, but there's no Ruby implementation</li>
  <li>Finding a C implementation of ECC that doesn't require libcrypto or libssl was really hard</li>
  <li>Finding a <em>working</em> SHA3 implementation in Ruby was impossible! I filed bugs against the three more popular implementations and <a href='https://github.com/johanns/sha3'>one of them</a> actually <a href='https://github.com/johanns/sha3/issues/6'>took the time to fix it</a>!</li>
  <li>Dealing with DNS's gratuitous retransmissions and accidental drops was super painful and required some hackier code than I like to see in crypto (for example, an old key can still be used, even after a key exchange, until the new one is used successfully; the more secure alternative can't handle a dropped response packet, otherwise both peers would have different keys)</li>
</ul>

<h2>Shouts out</h2>

I just wanted to do a quick shout out to a few friends who really made this happen by giving me advice, encouragement, or just listening to me complaining.

So, in alphabetical order so nobody can claim I play favourites, I want to give mad propz to:

<ul>
  <li><a href='https://twitter.com/alexwebr'>Alex Weber</a>, who notably convinced me to use a proper key exchange protocol instead of just a static key (and who also wrote the <a href='https://github.com/alexwebr/salsa20'>Salsa20 implementation I used</a></li>
  <li><a href='https://twitter.com/bmenrigh'>Brandon Enright</a>, who give me a ton of handy crypto advice</li>
  <li>Sabine, who convinced me to work on encryption in the first place, and who listened to my constant complaining about how much I hate implementing crypto</li>
</ul>
