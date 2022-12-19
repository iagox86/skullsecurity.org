---
id: 1318
title: 'Padding oracle attacks: in depth'
date: '2013-01-02T11:59:43-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1318'
permalink: /2013/padding-oracle-attacks-in-depth
categories:
    - Conferences
    - Crypto
    - Hacking
    - Tools
---

This post is about padding oracle vulnerabilities and the tool for attacking them - "Poracle" I'm officially releasing right now. **You can grab the Poracle tool on [Github](https://www.github.com/iagox86/Poracle)!**

At my previous job — [Tenable Network Security](http://www.tenable.com/) — one of the first tasks I ever had was to write a [vulnerability check](http://www.tenable.com/plugins/index.php?view=single&id=49806) for [MS10-070](http://technet.microsoft.com/en-ca/security/Bulletin/MS10-070) — a padding oracle vulnerability in ASP.net. It's an interesting use of a padding oracle vulnerability, since it leads to code execution, but this blog is going to be a more general overview of padding oracles. When I needed to test this vuln, I couldn't find a good writeup on how they work. The descriptions I did find were very technical and academic, which I'm no good at. In fact, when it comes to reading academic papers, I'm clueless and easily frightened. But, I struggled through them, and now I'm gonna give you a writeup that even I'd be able to understand!

By the way, the [Wikipedia page](http://en.wikipedia.org/wiki/Padding_oracle_attack) for this attack isn't very good. If somebody wants to summarize my blog and make it into a Wikipedia page, there's now a source you can reference. :)

On a related note, I'm gonna be speaking at [Shmoocon](http://shmoocon.org/) in February: "Crypto: You're doing it wrong". Among other things, I plan to talk about padding oracles and hash extension attacks — I'm really getting into this crypto thing!

## Overview

Padding oracle attacks — also known as Vaudenay attacks — were originally [published](http://lasec.epfl.ch/php_code/publications/search.php?ref=Vau02a) in 2002 by [Serge Vaudenay](https://en.wikipedia.org/wiki/Serge_Vaudenay). As I mentioned earlier, in 2010 it was used for code execution in ASP.net.

First, let's look at the definition of an "oracle". This has nothing to do with the Oracle database or the company that makes Java — they have enough vulnerabilities of their own without this one (well, actually, Java Server Faces ironically suffered from a padding oracle vulnerability, but I think that's before Oracle owned them). In cryptography, an [oracle](http://blog.cryptographyengineering.com/2011/09/what-is-random-oracle-model-and-why.html) — much like the [Oracle of Delphi](https://en.wikipedia.org/wiki/Pythia) — is a system that will perform given cryptographic operations on behalf of the user (otherwise known as the attacker). A padding oracle is a specific type of oracle that will take encrypted data from the user, attempt to decrypt it privately, then reveal whether or not the padding is correct. We'll get into what padding is and why it matters soon enough.

## Example

Okay, so we need an oracle that will decrypt arbitrary data, secretly. When the heck does that happen?

Well, it turns out, it happens a lot. Every time there's an encrypted connection, in fact, one side is sending the other data that the latter attempts to decrypt. Of course, to do anything interesting in that situation, it requires a man-in-the-middle attack — or something similar — and a protocol that allows unlimited retries to actually be interesting. For the purposes of simplicity, let's look at something easier.

Frequently — in a practice that I don't think is a great idea — a Web server will entrust a client with encrypted data in either a cookie or a hidden field. The advantage to doing this is that the server doesn't need to maintain state — the client holds the state. The disadvantage is that, if the client can find a way to modify the encrypted data, they can play with private state information. Not good. In the case of ASP.net, this was enough to read/write to the filesystem.

So, for the purpose of this discussion, let's imagine a Web server that puts data in a hidden field/cookie and attempts to decrypt the data when the client returns it, then reveals to the client whether or not the padding was correct, for example by returning a Web page with the user logged-in.

## Block ciphers

All right, now that we have the situation in mind, let's take a step back and look at block ciphers.

A block cipher operates on data in fixed-size blocks — 64-bit for DES, 128-bit for AES, etc. It encrypts each block then moves onto the next one, and the next one, and so on. When the data is decrypted, it also starts with the first block, then the next, and so on.

This leads to two questions:

1. What happens if the length of the data isn't a multiple of the block size?
2. What happens if more than one block is identical, and therefore encrypts identically?

Let's look at each of those situations...

### Padding

Padding, padding, padding. Always with the padding. So, every group of cryptographic standards uses different padding schemes. I don't know why. There may be a great reason, but I'm not a mathematician or a cryptographer, and I don't understand it. In the [hash extension](http://www.skullsecurity.org/blog/2012/everything-you-need-to-know-about-hash-length-extension-attacks) blog I wrote awhile back, I talked about how hashing algorithms pad — by adding a 1 bit, followed by a bunch of 0 bits, then the length (so, in terms of bytes, "<tt>\\x80\\x00\\x00\\x00 ... <length></tt>"). That's not how block ciphers pad.

Every block cipher I've seen uses [PKCS7](https://en.wikipedia.org/wiki/Padding_(cryptography)#Byte_padding) for padding. PKCS7 says that the value to pad with is the number of bytes of padding that are required. So, if the blocksize is 8 bytes and we have the string "<tt>ABC</tt>", it would be padded "<tt>ABC\\x05\\x05\\x05\\x05\\x05</tt>". If we had "<tt>ABCDEFG</tt>", with padding it would become "<tt>ABCDEFG\\x01</tt>".

Additionally, if the string is a multiple of the blocksize, an empty block of only padding is appended. This may sound weird — why use padding when you don't need it? — but it turns out that you couldn't otherwise distinguish, for example, the string "<tt>ABCDEFG\\x01</tt>" from "<tt>ABCDEFG</tt>" (the "<tt>\\x01</tt>" at the end looks like padding, but in reality it's part of the string). Therefore, "<tt>ABCDEFGH</tt>", with padding, would become "<tt>ABCDEFGH\\x08\\x08\\x08\\x08\\x08\\x08\\x08\\x08</tt>".

### Exclusive or (XOR)

This is just a very quick note on the exclusive or — XOR — operator, for those of you who may not be familiar with its crypto usage. XOR — denoted as '⊕' throughout this document and usually denoted as '^' in programming languages — is a bitwise operator that is used, in crypto, to mix two values together in a reversible way. A plaintext XORed with a key creates ciphertext, and XORing it with that the key again restores the plaintext. It is used for basically every type of encryption in some form, due to this reversible properly, and the fact that once it's been XORed, it doesn't reveal any information about either value.

XOR is also commutative and a bunch of other mathy stuff. To put it into writing:

```

  A ⊕ A = 0
  A ⊕ 0 = A
  A ⊕ B = B ⊕ A
  (A ⊕ B) ⊕ C = A ⊕ (B ⊕ C)
  ∴ A ⊕ B ⊕ B = A ⊕ (B ⊕ B) = A ⊕ 0 = A
```

If you don't fully understand every line, please read up on the bitwise XOR operator before you continue! You won't understand any of this otherwise. You need to be very comfortable with how XOR works.

When we talk about XORing, it could mean a few things:

- When we talk about XORing bits, we simply XOR together the two arguments (0⊕0=0, 0⊕1=1, 1⊕0=1, 1⊕1=0)
- When we talk about XORing bytes, we XOR each bit in the first argument with the corresponding bit in the second
- When we talk about XORing strings, we XOR each byte in the first string with the corresponding byte in the second. If they have different lengths there's a problem in the algorithm and any result is invalid

### Cipher-block chaining (CBC)

Now, this is where things get interesting. CBC. And not the Canadian television station, either — the cryptographic construct. This is what ensures that no two blocks — even if they contain identical plaintext — will encrypt to the same ciphertext. It does this by mixing the ciphertext from the previous round into the plaintext of the next round using the XOR operator. In mathematical notation:

```

  Let P   = the plaintext, and P<sub>n</sub> = the plaintext of block n.
  Let C   = the corresponding ciphertext, and C<sub>n</sub> = the ciphertext of block n.
  Let N   = the number of blocks (P and C have the same number of blocks by
            definition).
  Let IV  = the initialization vector — a random string — frequently
            (incorrectly) set to all zeroes.
  Let E() = a single-block encryption operation (any block encryption algorithm, such
            as AES or DES, it doesn't matter which), with some unique and unknown (to
            the attacker) secret key (that we don't notate here).
  Let D() = the corresponding decryption operation.
```

We can then define the encrypted ciphertext — C — in terms of the encryption algorithm, the plaintext, and the initialization vector:

```

  C<sub>1</sub> = E(P<sub>1</sub> ⊕ IV)
  C<sub>n</sub> = E(P<sub>n</sub> ⊕ C<sub>n-1</sub>) — for all n > 1
```

You can use this [Wikipedia diagram](https://en.wikipedia.org/wiki/File:Cbc_encryption.png) to help understand.

In English, the first block of plaintext is XORed with an initialization vector. The rest of the blocks of plaintext are XORed with the previous block of ciphertext. Thinking of the IV as C<sub>0</sub> can be helpful.

Decryption is the opposite:

```

  P<sub>1</sub> = D(C<sub>1</sub>) ⊕ IV
  P<sub>n</sub> = D(C<sub>n</sub>) ⊕ C<sub>n-1</sub> - for all n > 1
```

You can use this [Wikipedia diagram](https://en.wikipedia.org/wiki/File:Cbc_decryption.png) to help understand.

In English, this means that the first block of ciphertext is decrypted, then XORed with the IV. Remaining blocks are decrypted then XORed with the previous block of ciphertext. Note that *this operation is between a ciphertext block — that we control — and a plaintext block — that we're interested in*. This is important.

*Once all blocks are decrypted, the padding on the last block is validated*. This is also important.

## The attack

Guess what? We now know enough to pull of this attack. But it's complicated and requires math, so let's be slow and gentle. \[Editor's note: [TWSS](https://en.wikipedia.org/wiki/Said_the_actress_to_the_bishop)\]

First, the attacker breaks the ciphertext into the individual blocks, based on the blocksize of the algorithm. We're going to decrypt each of these blocks separately. This can be done in any order, but going from the last to the first makes the most sense. C<sub>N</sub> — remembering that C is the ciphertext and N is the number of blocks — is the value we're going to attack first.

Next, the attacker generates his own block of ciphertext. It doesn't matter what it decrypts to or what the value is. Typically we start with all zeroes, but any random text will work fine. In the tool I'm releasing, this is optimized for ASCII text, but that's beyond the scope of this discussion. We're going to denote this block as C′.

The attacker creates the string (C′ || C<sub>n</sub>) — "||" is the concatenation operator in crypto notation — and sends it to the oracle for decryption. The oracle attempts to decrypt the string as follows:

```

  Let C′     = our custom-generated ciphertext block
  Let C′[k]  = the k<sup>th</sup> byte of our custom-generated ciphertext block
  Let P′     = the plaintext generated by decrypting our string, (C′ || C<sub>n</sub>)
  Let P′<sub>n</sub>    = the n<sup>th</sup> block of P′
  Let P′<sub>n</sub>[k] = k<sup>th</sup> byte of the n<sup>th</sup> plaintext block
  Let K      = the number of bytes in each block
```

Now, we can define P′ in terms of our custom ciphertext, the IV, and the decryption function:

```

  P′<sub>1</sub> = D(C′) ⊕ IV
  P′<sub>2</sub> = D(C<sub>N</sub>) ⊕ C′
```

This shows the two blocks we created being decrypted in the usual way — P<sub>n</sub> = D(C<sub>n</sub>) ⊕ C<sub>n-1</sub>.

P′<sub>1</sub> is going to be meaningless garbage — we don't care what it decrypts to — but P′<sub>2</sub> is where it gets interesting! Let's look more closely at P′<sub>2</sub>:

```

  Given:       P′<sub>2</sub> = D(C<sub>n</sub>) ⊕ C′
  And knowing: C<sub>n</sub>  = E(P<sub>n</sub> ⊕ C<sub>n-1</sub>)
  Implies:     P′<sub>2</sub> = D(E(P<sub>n</sub> ⊕ C<sub>n-1</sub>)) ⊕ C′
```

Remember, the variables marked with prime — ′ — are ones that result from our custom equation, and variables without a prime are ones from the original equation.

We know that D(E(x)) = x, by the definition of encryption, so we can reduce the most recent formula to:

```

  P′<sub>2</sub> = P<sub>n</sub> ⊕ C<sub>n-1</sub> ⊕ C′
```

Now we have four values in our equation:

- P′<sub>2</sub>: An unknown value that the server calculates during our "attack" (more on this later).
- P<sub>n</sub>: An unknown value that we want to determine, from the original plaintext.
- C<sub>n-1</sub>: A known value from the original ciphertext.
- C′: A value that we control, and can change at will.

You might see where we're going with this! Notice that we have a formula for P<sub>n</sub> that *doesn't contain any encryption operations*, just XOR!

The problem is, we have two unknown values: we don't know P′<sub>2</sub> or P<sub>n</sub>. A formula with two unknowns can't be solved, so we're outta luck, right?

Or are we?

### Here comes the oracle!

Remember, we have one more piece of information — the padding oracle! That means that we can actually determine when P′<sub>2</sub>\[K\] — the last byte of P′<sub>2</sub> — is equal to "<tt>\\x01</tt>" (in other words, we can determine when P′<sub>2</sub> has valid padding)!

So now, let's take the formula we were using earlier, but instead of looking at the full strings, we'll look specifically at the last character of the encrypted strings:

```

  P′<sub>2</sub>[K] = P<sub>n</sub>[K] ⊕ C<sub>n-1</sub>[K] ⊕ C′[K]
```

We send (C′ || C<sub>n</sub>) to the oracle with every possible value of C′\[K\], until we find a value that doesn't generate a padding error. When we find that value, we know beyond any doubt that the value at P′<sub>2</sub>\[K\] is "<tt>\\x01</tt>". Otherwise, the padding would be wrong. It HAS to be that way (actually, that's not entirely true, it can be "<tt>\\x02</tt>" if P′<sub>2</sub>\[K-1\] is "<tt>\\x02</tt>" as well — we'll deal with that later).

At that point, we have the following variables:

- P′<sub>2</sub>\[K\]: The valid padding value ("\\x01").
- P<sub>n</sub>\[K\]: The last byte of plaintext — our unknown value.
- C<sub>n-1</sub>\[K\]: The last byte of the previous block of ciphertext — a known value.
- C′\[K\]: The byte we control — and previously modified — to create the valid padding.

All right, we have three known variables! Let's re-write the equation a little — XOR being [commutative](http://en.wikipedia.org/wiki/Commutative_property#Rule_of_replacement), we're allowed to move variables around at will:

```

  Original:       P′<sub>2</sub>[K] = P<sub>n</sub>[K] ⊕ C<sub>n-1</sub>[K] ⊕ C′[K]
  Re-arranged:    P<sub>n</sub>[K] = P′<sub>2</sub>[K] ⊕ C<sub>n-1</sub>[K] ⊕ C′[K]
  Substitute "1": P<sub>n</sub>[K] = 1 ⊕ C<sub>n-1</sub>[K] ⊕ C′[K]
```

We just defined P<sub>n</sub>\[K\] using three known variables! That means that we plug in the values, and "turn the crank" as my former physics prof used to say, and we get the last byte of plaintext. Why? Because MATH!

### Stepping back a bit

So, the math checks out, but what's going on conceptually?

Have another look at the [Wikipedia diagram](https://en.wikipedia.org/wiki/File:Cbc_decryption.png) of cipher-block chaining. We're interested in the box in the very bottom-right corner — the padding. That value, as you can see on the diagram, is equal to the ciphertext left of it, XORed with the decrypted text above it.

Notice that there's no actual crypto that we have to defeat — just the XOR operation between a known value and the unknown value to produce a known value. Pretty slick, eh? Fuck your keys and transposition and s-boxes — I just broke your encryption after you did all that for me! :)

### Iterating

So, we now know the value of the last character of P<sub>N</sub>. That's pretty awesome, but it's also pretty boring, because the last byte is guaranteed to be padding (well, only if this is the last block). The question is, how do we get the second-, third-, and fourth-last bytes?

How do we calculate P<sub>N</sub>\[K-1\]? Well, it turns out that it's pretty simple. If you've been following so far, you can probably already see it.

First, we have to set C′\[K\] to an appropriate value such that P′\[K\] = 2. Why 2? Because we are now interested the second-last byte of P′<sub>N</sub>, and we can determine it by setting the last byte to 2, and trying every possible value of C′\[K-1\] until we stop getting padding errors, confirming that P′<sub>N</sub> ends with "\\x02\\x02".

Ensuring that P′\[K\] = 2 easy (although you don't realize *how* easy until you realize how long it took me to work out and explain this formula for the blog); we just take this formula that we derived earlier, plug in '2' for P′\[K\], and solve for C′\[K\]:

```

  We have:         C′[K] = P′<sub>2</sub>[K] ⊕ P<sub>N</sub>[K] ⊕ C<sub>N-1</sub>[K]
  Plug in the "2": C′[K] = 2 ⊕ P<sub>N</sub>[K] ⊕ C<sub>N-1</sub>[K]
```

Where our variables are defined as:

- C′\[K\] — The last byte in the C′ block, which we're sending to the oracle and that we fully control.
- P<sub>N</sub>\[K\] — The last byte in this block's plaintext, which we've solved for already.
- C<sub>N-1</sub>\[K\] — The last byte in the previous ciphertext block, which we know.

I don't think I have to tell you how to calculate P<sub>N</sub>\[K-2\], P<sub>N</sub>\[K-3\], etc. It's the same principle, applied over and over from the end to the beginning.

### A tricky little thing called the IV

In the same way that we can solve the last block of plaintext — P<sub>N</sub> — we can also solve other blocks P<sub>N-1</sub>, P<sub>N-2</sub>, etc. In fact, you don't even have to solve from right to left — each block can be solved in a vacuum, as long as you know the ciphertext value of the previous block.

...which brings us to the first block, P<sub>1</sub>. Earlier, we stated that P<sub>1</sub> is defined as:

```

  P<sub>1</sub> = D(C<sub>1</sub>) ⊕ IV
```

The "last block" value for P<sub>1</sub> — the block we've been calling C<sub>n-1</sub> — is the IV. So what do you do?

Well, as far as I can tell, there's no easy answer. Some of the less easy answers are:

- Try a null IV — many implementations won't set an IV — which, of course, has its own set of problems. But it's common, so it's worth trying.
- If you can influence text near the beginning of the encrypted string — say, a username — use as much data as possible to force the first block to be filled with stuff we don't want anyway.
- Find a way to reveal the IV, which is fairly unlikely to happen.
- If you can influence the hashing algorithm, try using an algorithm with a shorter blocksize (like DES, which has a blocksize of 64 bits — only 8 bytes).
- If all else fails, you're outta luck, and you're only getting the second block and onwards. Sorry!

## Poracle

If you follow my blog, you know that I rarely talk about an interesting concept without releasing a tool. That ain't how I roll. So, I present to you: [Poracle](https://www.github.com/iagox86/Poracle) (short for 'padding oracle', get it?)

Poracle is a library that I put together in Ruby. It's actually really, really simple. You have to code a module for the particular attack — unfortunately, because every attack is different, I can't make it any simpler than that. The module needs to implement a couple simple methods for getting values — like the blocksize and, if possible, the IV. The most important method, however, is <tt>attempt\_decrypt()</tt>. It must attempt to decrypt the given block and return a boolean value based on its success — true if the padding was good, and false if it was not. Here's an example of a module I wrote for a HTTP service:

```

<span class="Comment">##</span>
<span class="Comment"># RemoteTestModule.rb</span>
<span class="Comment"># Created: December 10, 2012</span>
<span class="Comment"># By: Ron Bowes</span>
<span class="Comment">#</span>
<span class="Comment"># A very simple implementation of a Padding Oracle module. Basically, it</span>
<span class="Comment"># performs the attack against an instance of RemoteTestServer, which is an</span>
<span class="Comment"># ideal padding oracle target.</span>
<span class="Comment">##</span>
<span class="Comment">#</span>
<span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">httparty</span><span class="Special">'</span>

<span class="PreProc">class</span> <span class="Type">RemoteTestModule</span>
  <span class="Statement">attr_reader</span> <span class="Constant">:iv</span>, <span class="Constant">:data</span>, <span class="Constant">:blocksize</span>

  <span class="Type">NAME</span> = <span class="Special">"</span><span class="Constant">RemoteTestModule(tm)</span><span class="Special">"</span>

  <span class="PreProc">def</span> <span class="Identifier">initialize</span>()
    <span class="Identifier">@data</span> = <span class="Type">HTTParty</span>.get(<span class="Special">"</span><span class="Constant"><a href="http://localhost:20222/encrypt">http://localhost:20222/encrypt</a></span><span class="Special">"</span>).parsed_response
    <span class="Identifier">@data</span> = [<span class="Identifier">@data</span>].pack(<span class="Special">"</span><span class="Constant">H*</span><span class="Special">"</span>)
    <span class="Identifier">@iv</span> = <span class="Constant">nil</span>
    <span class="Identifier">@blocksize</span> = <span class="Constant">16</span>
  <span class="PreProc">end</span>

  <span class="PreProc">def</span> <span class="Identifier">attempt_decrypt</span>(data)
    result = <span class="Type">HTTParty</span>.get(<span class="Special">"</span><span class="Constant"><a href="http://localhost:20222/decrypt/">http://localhost:20222/decrypt/</a></span><span class="Special">#{</span>data.unpack(<span class="Special">"</span><span class="Constant">H*</span><span class="Special">"</span>).pop<span class="Special">}</span><span class="Special">"</span>)

    <span class="Statement">return</span> result.parsed_response !~ <span class="Special">/</span><span class="Constant">Fail</span><span class="Special">/</span>
  <span class="PreProc">end</span>

  <span class="PreProc">def</span> <span class="Identifier">character_set</span>()
    <span class="Comment"># Return the perfectly optimal string, as a demonstration</span>
    <span class="Statement">return</span> <span class="Special">'</span><span class="Constant"> earnisoctldpukhmf,gSywb0.vWD21</span><span class="Special">'</span>.chars.to_a
  <span class="PreProc">end</span>
<span class="PreProc">end</span>
```

Then, you create a new instance of the Poracle class, pass in your module, and call the <tt>decrypt()</tt> method. Poracle will do the rest! It looks something like this:

```

<span class="lnr">1 </span><span class="Statement">begin</span>
<span class="lnr">2 </span>  mod = <span class="Type">RemoteTestModule</span>.new
<span class="lnr">3 </span>  puts <span class="Type">Poracle</span>.decrypt(mod, mod.data, mod.iv, <span class="Constant">true</span>, <span class="Constant">true</span>)
<span class="lnr">4 </span><span class="Statement">rescue</span> <span class="Type">Errno</span>::<span class="Type">ECONNREFUSED</span> => e
<span class="lnr">5 </span>  puts(e.class)
<span class="lnr">6 </span>  puts(<span class="Special">"</span><span class="Constant">Couldn't connect to remote server: </span><span class="Special">#{</span>e<span class="Special">}</span><span class="Special">"</span>)
<span class="lnr">7 </span><span class="Statement">end</span>
```

For more information, grab [Poracle.rb](https://github.com/iagox86/poracle/blob/master/Poracle.rb) and read the header comments. It'll be more complete and up-to-date than this blog post can ever be.

I implemented a couple test modules — a local and a remote. [LocalTestModule.rb](https://github.com/iagox86/poracle/blob/master/LocalTestModule.rb) will generate its own ciphertext with any algorithm you want, then <tt>attempt\_decrypt()</tt> simply tries to decrypt it in-line. Not very interesting, but good to make sure I didn't break anything.

[RemoteTestModule.rb](https://github.com/iagox86/poracle/blob/master/RemoteTestModule.rb) is more interesting. It comes with a server — [RemoteTestServer.rb](https://github.com/iagox86/poracle/blob/master/RemoteTestServer.rb) — which runs on Sinatra. The service is the simplest padding oracle vulnerability you can imagine — it has a path — "<tt>/encrypt</tt>" — that retrieves an encrypted string, and another path — "<tt>/decrypt</tt>" — that tries to decrypt it and reports "success" or "fail". That's it.

To try these, either just run "<tt>ruby DoTests.rb</tt>" or start the server with "<tt>ruby RemoteTestServer.rb</tt>" and then, in another window (or whatever), run "<tt>ruby DoTests.rb remote</tt>".

One interesting tidbit — Poracle doesn't actually require OpenSSL to function, or even an encryption library. All encryption and decryption are done by the service, not by Poracle. In fact, Poracle itself has not a single dependency (although the test modules do require OpenSSL, obviously, as well as Sinatra and httparty for the remote test module.

### Backtracking

Do you ever have that feeling that you're an idiot? I do, on a regular basis, and I'm not really sure why... but I'm gonna tell you a story about the development of Poracle that helps explain why I never want to be a real programmer.

So, while developing Poracle, I was worried about false positives and backtracking. What happens if I was trying to guess the last byte and instead of "<tt>xx yy zz 01</tt>", we wound up with "<tt>xx yy zz 02</tt>", where zz = "<tt>02</tt>"? "<tt>02 02</tt>", or two twos, is valid padding. That means we thought we'd guessed a "<tt>01</tt>", but it's actually "<tt>02</tt>"! False positive!

That's obviously a problem, but I went further, well into the regions of insanity. What if we're cracking the second-last digit and it was a "<tt>03</tt>"? What if we're on the 13th digit and it's a "<tt>0d</tt>"? So, I decided I'd do backtracking. After finding each digit, I'd recurse, and find the next. If none of the 256 possible characters works for the next byte, I'd return and the caller would continue guessing bytes. That made things complicated. It's recursion, that's what it's for!

Then, to speed things up and clean up some of the code, I tried to convert it to iteration. Haha. Trying to go back and forth in an array to track where we were left off when we hit the bad padding was painful. I will spare you the madness of explaining where I went with that. It wasn't pretty.

That's when I started talking to [Mak](https://www.twitter.com/mogigoma), who, contrary to popular belief, can actually save your sanity and not just drain it! He also makes a perfect [rubber duck](http://www.codinghorror.com/blog/2012/03/rubber-duck-problem-solving.html). Although he wasn't answering on IRC, I realized something just by explaining the problem to him — I can only ever get a padding error on the last digit of each block, because once I've sure — positive — that the last digit is "<tt>\\x01</tt>", we can reliably set it to "<tt>\\x02</tt>", "<tt>\\x03</tt>", etc. Because math! That means that we only have to worry about accidentally getting "<tt>\\x02\\x02</tt>", "<tt>\\x03\\x03\\x03</tt>", "<tt>\\x04\\x04\\x04\\x04</tt>", etc, *on the last digit of the block, nowhere else*.

Once I realized that, it was easy! After we successfully determine the last digit, we make one more request, where we XOR the second-last byte with "<tt>\\x01</tt>". That means if that the string was originally ending with "<tt>\\x02\\x02</tt>", it would end with "<tt>\\x03\\x02</tt>" and the padding would fail.

So, with one extra request, I can do a nice, simple, clean, iterative algorithm, instead of a crazy complex recursive one. And that opened the door to... optimization!

### Optimization

So, now we have clean, working code. However, this effectively guesses characters randomly. We try "<tt>\\x00</tt>" to "<tt>\\xFF</tt>" for the last byte of C′, but after all the XOR operations, the order that values are guessed for P<sub>n</sub> is effectively random. But, what if instead of guessing values for C′, you guessed values for P<sub>n</sub>? The math is actually quite simple and is based on this formula:

```

  P<sub>n</sub>[k] = 1 ⊕ C<sub>n-1</sub>[k] ⊕ C′[k]
```

Instead of choosing values for C′\[k\], you can choose the value for P<sub>n</sub>\[k\] that you want to guess, then solve for C′\[k\]

Since most strings are ASCII or, at least, in some way predictable, I started guessing each character in order, from 0 to 255. Since ASCII tends to be lower, it sped things up by a significant amount. After some further tweaking, I came up with the following algorithm:

- If we're at the end of the last block, we start with guessing at "\\x01", since that's the lowest possible byte that the (actual) padding can be.
- The last byte of the block is padding, so for that many bytes from the end, we guess the same byte. For example, if the last byte is "<tt>\\x07</tt>", we guess "<tt>\\x07</tt>" for the last 7 bytes — this lets us determine the padding bytes on our first guess every time!
- Finally, we weight more heavily toward ASCII characters, in order of the frequency that they occur in the English language, based on text from the [Battlestar Galactica Wiki](https://en.wikipedia.org/wiki/Battlestar_Galactica) because, why not Cylon?

On my test block of text, running against a Web server on localhost, I improved a pretty typical attack from 33,020 queries taking 63 seconds to 2,385 queries and 4.71 seconds.

### Ciphers

One final word — and maybe this will help with Google results :) — I've tested this successfully against the following ciphers:

- CAST-cbc
- aes-128-cbc
- aes-192-cbc
- aes-256-cbc
- bf-cbc
- camellia-128-cbc
- camellia-192-cbc
- camellia-256-cbc
- cast-cbc
- cast5-cbc
- des-cbc
- des-ede-cbc
- des-ede3-cbc
- desx-cbc
- rc2-40-cbc
- rc2-64-cbc
- rc2-cbc
- seed-cbc

But that's not interesting, because this isn't an attack against ciphers. It's an attack against cipher-block chaining — CBC — that can occur against any block cipher.

## Conclusion

So, hopefully you understand a little bit about how padding oracles work. If you haven't read my blog about [hash extension attacks](http://www.skullsecurity.org/blog/2012/everything-you-need-to-know-about-hash-length-extension-attacks), go do that. It's pretty cool. Otherwise, if you're going to be around for Shmoocon in DC this winter, come see my talk!