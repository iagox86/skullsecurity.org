---
id: 1319
date: '2012-12-20T16:04:37-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/2012/1318-revision'
permalink: '/?p=1319'
---

At my previous job - Tenable - one of the first tasks I ever had was to write a vulnerability check for MS10-070 - a padding oracle vulnerability in ASP.net. It's an interesting use of a padding oracle vulnerability, since it leads to code execution, but this blog is going to be a more general overview of padding oracles. When I needed to test this vuln, I couldn't find a good writeup on how they work. The descriptions I did find were very technical and academic, which I'm no good at. In fact, when it comes to reading academic papers, I'm clueless and easily frightened. But, I struggled through them, and now I'm gonna give you a writeup that even I'd be able to understand!

By the way, the [Wikipedia page](http://en.wikipedia.org/wiki/Padding_oracle_attack) for this attack isn't very good. If somebody wants to summarize my blog and make it into a Wikipedia page, there's now a source you can reference. :)

On a related note, I'm gonna be speaking at [Shmoocon](http://shmoocon.org/) in February: "Crypto: You're doing it wrong". Among other things, I plan to talk about padding oracles and hash extension attacks - I'm really getting into this crypto thing!

## Overview

Padding oracle attacks - also known as Vaudenay attacks - were originally published in 2002 by Serge Vaudenay. As I mentioned earlier, in 2010 it was used for code execution in ASP.net.

First, let's look at the definition of an "oracle". This has nothing to do with the Oracle database or the company that makes Java - they have enough vulnerabilities of their own without this one (well, actually, Java Server Faces ironically suffered from a padding oracle vulnerability, but I think that's before Oracle owned them..). In cryptography, an oracle - much like the Oracle of Delphi - is a system that will perform given cryptographic operations on behalf of the user (otherwise known as the attacker). A padding oracle is a specific type of oracle that will take encrypted data from the user, attempt to decrypt it privately, then reveal whether or not the padding is correct. We'll get into what padding is and why it matters soon enough.

## Example

Okay, so we need an oracle that will decrypt arbitrary data, secretly. When the heck does that happen?

Well, it turns out, it happens a lot. Every time there's an encrypted connection, in fact, one side is sending the other data that the other side attempts to decrypt. Of course, that requires a man-in-the-middle attack - or something similar - and a protocol that allows unlimited retries to actually be interesting. For the purposes of simplicity, let's look at something easier.

Frequently - in a practice that I don't think is a great idea - a Web server will entrust a client with encrypted data in either a cookie or a hidden field. The advantage to doing this is that the server doesn't need to maintain state - the client holds the state. The disadvantage is that, if the client can find a way to modify the encrypted data, they can play with private state information. Not good. In the case of ASP.net, this was enough to read/write to the filesystem.

So, for the purpose of this discussion, let's imagine a Web server that puts data in a hidden field/cookie and attempts to decrypt the data when the client returns it, then reveals to the client whether or not the padding was correct.

## Block ciphers

All right, now that we have the situation in mind, let's take a step back and look at block ciphers.

A block cipher operates on data in fixed-size blocks - say, 64-bit for DES, 128-bit for AES, etc. It encrypts each block then moves onto the next one, and the next one, and so on. This leads to two questions:

1. What happens if the length of the cipher isn't a multiple of the block size?
2. What happens if more than one block is identical, and therefore encrypts identically?

Let's look at each of those situations...

### Padding

Padding, padding, padding. Always with the padding. So, every group of cryptographic standards uses different padding schemes. I don't know why. There may be a great reason, but I'm not a mathematician and I don't understand it. In the [hash extension](http://www.skullsecurity.org/blog/2012/everything-you-need-to-know-about-hash-length-extension-attacks) blog I wrote awhile back, I talked about how hashing algorithms pad - by adding a 1 bit, followed by a bunch of 0 bits, then the length (so, in terms of bytes, "80 00 00 00 ... <length>"). That's not how block ciphers pad.

Every block cipher I've seen uses [PKCS7](https://en.wikipedia.org/wiki/Padding_(cryptography)#Byte_padding) for padding. PKCS7 says that the value to pad with is the number of bytes of padding that are required. So, if the blocksize is 8 bytes and we have the string "ABC", it would be padded "ABC\\x05\\x05\\x05\\x05\\x05". If we had "ABCDEFG", with padding it would become "ABCDEFG\\x01".

Additionally, if the string is a multiple of the blocksize, an empty block of just padding is appended. This may sound weird - why use padding when you don't need it? - but it turns out that you couldn't otherwise distinguish, for excample, the string "ABCDEFG\\x01" from "ABCDEFG" (the "\\x01" at the end looks like padding, but in reality it's part of the string). Therefore, "ABCDEFGH", with padding, would become "ABCDEFGH\\x08\\x08\\x08\\x08\\x08\\x08\\x08\\x08".

### Exclusive or (XOR)

This is just a very quick note on the exclusive or - or XOR - operator, for those of you who may not be familiar with its crypto usage. XOR - donated '^' throughout this document - is a bitwise operator that is used, in crypto, to mix two values together in a reversable way. A value XORed with a key creates a ciphered value, and XORing it with that the key again restores the plaintext value. It is used for basically every type of encryption in some form, due to this reversable properly and the fact that once it's been XORed, it doesn't reveal any information about either value.

XOR is also commutative and a bunch of other mathy stuff. To put it into writing:

- A ^ A = 0
- A ^ 0 = A
- A ^ B = B ^ A
- (A ^ B) ^ C = A ^ (B ^ C)
- Therefore, A ^ B ^ B = A ^ (B ^ B) = A ^ 0 = A

If you don't fully understand every line, please read up on the bitwise XOR operator before you continue! You won't understand any of this otherwise. You need to be very comfortable with how XOR works.

When we talk about XORing, it could mean a few things:

- When we talk about XORing bits, we simply XOR together the two arguments
- When we talk about XORing bytes, we XOR each bit in the first argument with the corresponding bit in the second
- When we talk about XORing strings, we XOR each byte in the first string with the corresponding byte in the second. If they have different numbers of bytes, then there's a problem in the algorithm and any result is invalid

### Cipher-block chaining (CBC)

Now, this is where things get interesting. CBC. And not the Canadian television station, either - the cryptographic construct. This is what ensures that no two blocks - even if they're the same plaintext - will encrypt to the same ciphertext. It does this by mixing the ciphertext from each round into the plaintext of the next using the XOR operator. In mathematical notation:

```

  Let C   = the ciphertext, and C<sub>n</sub> = the ciphertext of block n.
  Let P   = the plaintext, and P<sub>n</sub> = the ciphertext of block n.
  Let n   = the number of blocks (P and C have the same number of blocks).
  Let IV  = the initialization vector - a random string - frequently
            (incorrectly) set to all zeroes.
  Let E() = a single-block encryption operation (any block encryption
            algorithm, such as AES or DES, it doesn't matter which), with some
            unique and unknown (to the attacker) secret key.
  Let D() = the corresponding decryption operation.

  C<sub>1</sub> = E(P<sub>1</sub> ^ IV)
  C<sub>n</sub> = E(P<sub>n</sub> ^ C<sub>n-1</sub>) - for all n > 1
```

You can use this [Wikipedia diagram](https://en.wikipedia.org/wiki/File:Cbc_encryption.png) to help understand.

In English, the first block of plaintext is XORed with an initialization vector. The rest of the blocks of plaintext are XORed with the previous block of ciphertext. Thinking of the IV as C<sub>0</sub> can be helpful.

Decryption is the opposite (and uses the same variables/functions that we won't re-define):

```

  P<sub>1</sub> = D(C<sub>1</sub>) ^ IV
  P<sub>n</sub> = D(C<sub>n</sub>) ^ C<sub>n-1</sub> - for all n > 0
```

You can use this [Wikipedia diagram](https://en.wikipedia.org/wiki/File:Cbc_decryption.png) to help understand.

In English, this means that the first block of ciphertext is decrypted, then XORed with the IV. Remaining blocks are decrypted then XORed with the previous block of ciphertext. Note that *this operation is between a ciphertext block - that we control - and a plaintext block - that we're interested in*. This is important.

*Once all blocks are decrypted, the padding is validated*. This is also important.

## The attack

Guess what? We now know enough to pull of this attack. But it's complicatd and requires math, so let's be slow and gentle.

First, the attacker breaks the encrypted text into the individual blocks, based on the blocklength of the algorithm. We're going to decrypt each of these blocks separately. This can be done in any order, but going from the last to the first makes the most sense. <tt>C<sub>n</sub></tt> is the value we're going to attack first.

Next, the attacker generates his own block of ciphertext. It doesn't matter what it decrypts to or what the value is. Typically we start with all zeroes, but any random text will work fine. In the tool I'm releasing, this is optimized for ASCII text, but that's beyond the scope of this discussion. We're going to denote our all-zeroes block as C′.

The attacker creates the string <tt>(C′ || C<sub>n</sub>)</tt> ("||" is the concatenation operator in crypto notation) and sends it to the oracle for decryption. The oracle attempts to decrypt the string as follows:

```

  Let C′ = our custom-generated ciphertext block.
  Let P′ = the plaintext that is generated by decrypting our custom string, (C′ || C<sub>n</sub>)
  Let P′[k] = the byte at index 'k' in the plaintext string
  Let k = the number of bytes in each block

  P′<sub>1</sub> = D(C′) ^ IV
  P′<sub>2</sub> = D(C<sub>n</sub>) ^ C′
```

This shows the two blocks we created being decrypted in the usual way - <tt>P<sub>n</sub> = D(C<sub>n</sub>) ^ C<sub>n-1</sub></tt>.

P′<sub>1</sub> is going to be meaningless garbage - we don't care what it decrypts to - but P′<sub>2</sub> is where it gets interesting! Let's look more closely at P′<sub>2</sub>:

```

  P′<sub>2</sub> = D(C<sub>n</sub>) ^ C′
  C<sub>n</sub> = E(P<sub>n</sub> ^ C<sub>n-1</sub>])
  --> P′<sub>2</sub> = D(E(P<sub>n</sub> ^ C<sub>n-1</sub>)) ^ C′
```

But <tt>D(E(x)) = x</tt>, by the definition of encryption, so:

```

  P′<sub>2</sub> = P<sub>n</sub> ^ C<sub>n-1</sub> ^ C′
```

Now we have four values in our equation:

- P′<sub>2</sub>: An unknown value that the server calculates (more on this later).
- P<sub>n</sub>: An unknown value that we want to determine, from the original plaintext.
- C<sub>n-1</sub>: A known value from the original ciphertext.
- C′: A value that we control, and can change at will.

You might see where we're going with this! The problem is, we have two unknown values: we don't know P′<sub>2</sub> or P<sub>n</sub>. A formula with two unknowns can't be solved, so we're outta luck, right?

Or are we?

### Here comes the oracle!

Remember, we have one more piece of information - the padding oracle! That means that we can actually determine when P′<sub>2</sub>\[k\] - the last byte of P′<sub>2</sub> - is equal to '1' (in other words, we can determine when P′\[2\] has valid padding)!

So now, let's take the formula we were using earlier, but instead of looking at the full strings, we'll look specifically at the last character of the encrypted strings:

```

  P′<sub>2</sub>[k] = P<sub>n</sub>[k] ^ C<sub>n-1</sub>[k] ^ C′[k]
```

We send that with every possible value of C′\[k\] - which we control, until we stop getting padding errors. When we stop getting errors, we know beyond any doubt that the value at <tt>P′<sub>2</sub>\[k\]</tt> is "\\x01". Otherwise, the padding would be wrong. It HAS to be that way (actually, that's not entirely true, it can be "\\x02" if the previous byte is "\\x02" as well - we'll deal with that later).

At that point, we have the following variables:

- <tt>P′<sub>2</sub>\[k\]</tt>: The valid padding value ("\\x01")
- <tt>P<sub>n</sub>\[k\]</tt>: The last byte of plaintext - our unknown value.
- <tt>C<sub>n-1</sub>\[k\]</tt>: The last byte of the previous block of ciphertext - a known value.
- <tt>C′\[k\]</tt>: The byte we control - and modified - to create the valid padding.

All right, we have three variables! Let's re-write the equation a little (being XOR, we're allowed to do this):

```

  P′<sub>2</sub>[k] = P<sub>n</sub>[k] ^ C<sub>n-1</sub>[k] ^ C′[k]
  --> P<sub>n</sub>[k] = P′<sub>2</sub>[k] ^ C<sub>n-1</sub>[k] ^ C′[k]
  --> P<sub>n</sub>[k] = 1 ^ C<sub>n-1</sub>[k] ^ C′[k]
```

We just defined P<sub>n</sub>\[k\] using three known variables! That means that we plug in the values, and "turn the crank" as my late physics prof used to say, and we get the last byte of plaintext. Why? Because MATH!

### Stepping back a bit

So, the math checks out, but what's going on conceptually?

Have another look at the [Wikipedia diagram](https://en.wikipedia.org/wiki/File:Cbc_decryption.png) of cipher-block chaining. We're interested in the box in the very bottom-right corner - the padding. That value, as you can see on the diagram, is equal to the ciphertext left of it, XORed with the decrypted text above it.

Notice that there's no actual crypto that we have to defeat - just the XOR operation between a known value and the unknown value to produce a known value. Pretty slick, eh? Fuck your keys and transposition and s-boxes - I just broke your encryption after you did all that for me! :)

### Iterating

So, we now know the value of the last character of P<sub>n</sub>. That's pretty awesome, but it's also pretty boring, because the last byte is guaranteed to be padding, by definition (unless this is a block other than the last block - this will work on any block!).

How do we calculate P<sub>n</sub>\[k-1\]? Well, it turns out that it's pretty simple. If you've been following so far, you can probably already see it.

First, we have to set C′\[k\] to an appropriate value such that P′\[k\] = 2. Why 2? Because we are now interested the second-last byte of P′<sub>n</sub>, and we can determine it by setting the last byte to 2, and trying every possible value of C′<sub>k</sub>.

Ensuring that P′\[k\] = 2 easy (although you don't realize *how* easy until you realize how long it took me to figure this formula out while writing the blog..); we just take this formula that we derived earlier, plug in '2' for C′\[k\], and solve for C′\[k\]:

```

  C′[k] = P′<sub>2</sub>[k] ^ P<sub>n</sub>[k] ^ C<sub>n-1</sub>[k]
  --> C′[k] = 2 ^ P<sub>n</sub>[k] ^ C<sub>n-1</sub>[k]
```

Where our variables are defined as:

- C′\[k\] - The last byte in the C′ block, which we're sending to the oracle and that we fully control.
- P<sub>n</sub>\[k\] - The last byte in this block's plaintext, which we've solved for already.
- C<sub>n-1</sub>\[k\] - The last byte in the previous ciphertext block, which we know

I don't think I have to tell you how to calculate P<sub>n</sub><sub>k-2</sub>, P<sub>n</sub><sub>k-3</sub>, etc. It's the same principal, applied over and over.

### A tricky little thing called the IV

In the same way that we can solve the last block of plaintext - P<sub>n</sub> - we can also solve other blocks P<sub>n-1</sub>, P<sub>n-2</sub>, etc. In fact, you don't even have to solve from right to left - each block can be solved in a vacuum, as long as you know the ciphertext value of the previous block.

...which brings us to the first block, P<sub>1</sub>. Earlier, we stated that P<sub>1</sub> is defined as:

```

  P<sub>1</sub> = D(C<sub>1</sub>) ^ IV
```

The "last block" value for P<sub>1</sub> - the block we've been calling C<sub>n-1</sub> - is the IV. So what do you do?

Well, as far as I can tell, there's no easy answer. Some of the less easy answers are:

- Try a null IV - many implementations won't set an IV - which, of course, has its own set of problems. But it's common, so it's worth trying.
- If you can influence text near the beginning of the encrypted string - say, a username - use as much data as possible to force the first block to be filled with stuff we don't want anyway.
- Find a way to reveal the IV, which is fairly unlikely to happen.
- If you can influence the hashing algorithm, try using an algorithm with a shorter blocksize (like DES, which has a blocksize of 64 bits - only 8 bytes).
- If all else fails, you're outta luck, and you're only getting the second block and onwards. Sorry!

## Poracle

If you follow my blog, you know that I rarely talk about an interesting concept without releasing a tool. That ain't how I roll. So, I present to you: [Poracle](https://www.github.com/iagox86/Poracle) (short for 'padding oracle', get it?)

Poracle is a library that I put together in Ruby. It's actually really, really simple. You have to code a module for the particular attack - unfortunately, because every attack is different, I can't make it any simpler than that. The module needs to implement a couple simple methods for gretting values - like the blocksize and, if possible, the IV. The most important method, however, is attempt\_decrypt(). It must attempt to decrypt the given block and return a binary value based on its success - true if the padding was good, and false if it was not.

Then, you create a new instance of the Poracle class, pass in your module, and call the decrypt() method. Pooracle will do the rest! For more information, grab Poracle.rb from the link above and read the header comments. It'll be more complete and up-to-date than this blog post can ever be.

I implemented a couple test modules - a local and a remote. LocalTestModule.rb will generate its own encrypted text with any algorithm you want, then attempt\_decrypt() simply tries to decrypt it in-line. Not very intresting, but good to make sure I didn't break anything.

RemoteTestModule.rb is more interesting. It comes with a server - RemoteTestServer.rb - which runs on Sinatra. The service is the simplest padding oracle vulnerability you can imagine - it has a path - '/encrypt' - that retrieves an encrypted string, and another path - '/decrypt' - that tries to decrypt it and reports 'success' or 'fail'. That's it.

To try these, either just run "ruby DoTests.rb" or start the server with "ruby RemoteTestServer.rb" and then, in another window (or whatever), run "ruby DoTests.rb remote".

One interesting tidbit - Poracle doesn't actually require OpenSSL to function, or even an encryption library. All encryption and decryption are done by the service, not by Poracle. In fact, Poracle itself has not a single dependency (although the test modules do require OpenSSL, obviously, as well as Sinatra and some httparty for the remote test module.

### Backtracking

Do you ever have that feeling that you're an idiot? I do, on a regular basis, and I'm not really sure why... but I'm gonna tell you a story about the development of Poracle that helps explain why I never want to be a real programmer.

So, while developing Poracle, I was worried about false positives and backtracking. What happens if I was trying to guess the last byte and instead of "xx yy zz 01", we wound up with "xx yy zz 02", where zz = "02"? "02 02", or two twos, is valid padding. That means we thought we'd guessed a "01", but it's actually "02"! False positive!

That's obviously a problem, but I went further, well into the regions of insanity. What if we're cracking the second-last digit and it was a "03"? What if we're on the 13th digit and it's a "0d"? So, I decided I'd do backtracking. After finding each digit, I'd recurse, and find the next. If none of the 256 possible characters works for the next byte, I'd return an the caller would continue guessing bytes. That made things complicated. It's recursion, that's what it's for!

Then, to speed things up and clean up some of the code, I tried to convert it to iteration. Haha. Trying to go back and forth in an array to track where we were left off when we hit the bad padding wa painful. I will spare you the madness of explaining where I went with that. It wasn't pretty.

That's when I started talking to [Mak](https://www.twitter.com/mak_kolybabi), who makes a perfect [rubber duck](http://www.codinghorror.com/blog/2012/03/rubber-duck-problem-solving.html). Although he wasn't answering on IRC, I realized something just by explaining the problem to him - I can only ever get a padding error on the last digit of each block, because once I've sure - positive - that the last digit is "01", we can reliably set it to "02", "03", etc. Because math! That means that we only have to worry about accidentally getting "02 02", "03 03 03", "04 04 04 04", etc, on the last digit.

Once I realized that, it was easy! After we successfully determine the last digit, we make one more request, where we xor the second-last byte with "01". That means if that the string was originally ending with "02 02", it would end with "03 02" and the padding would fail.

So, with one extra request, I can do a nice, simple, clean, iterative algorithm, instead of a crazy complex recursive one. And that opened the door to... optimization!

### Optimization

So, now we have clean, working code. However, this effectively guesses characters randomly. We try "\\x00" to "\\xFF" for the last byte of <tt>C′</tt>, but after all the XOR operations, the order is effectively random. But, what if instead of guessing values for <tt>C′</tt>, you guessed values for <tt>P<sub>n</sub></tt>? The math is actually quite simple and is based on this formula:

```

  P<sub>n</sub>[k] = 1 ^ C<sub>n-1</sub>[k] ^ C′[k]
```

Instead of choosing values for C′\[k\], you can choose the value for <tt>P<sub>n</sub>\[k\]</tt> that you want to guess, then solve for <tt>C′\[k\]</tt>

Since most strings are ASCII or, at least, in some way predictable, I started guessing each character in order, from 0 to 255. Since ASCII tends to be lower, it sped things up by a significant amount. After some further tweaking, I came up with the following algorithm:

- If we're at the end of the last block, we start with guessing at "\\x01", since that's the lowest possible byte that the (actual) padding can be.
- The last byte of the block is padding, so for that many bytes from the end, we guess the same byte. For example, if the last byte is "\\x07", we guess "\\x07" for the last 7 bytes - this lets us determine the padding bytes on our first guess every time!
- Finally, we weight more heavily toward ASCII characters, in order of the frequency that they occur in the English language, based on text from the [Battlestar Galacticawiki](https://en.wikipedia.org/wiki/Battlestar_Galactica) because, why not Cylon?

On my test block of text, running against a Web server on localhost, I improved a pretty typical attack from 33,020 queries taking 63 seconds to 2,385 queries and 4.71 seconds.

### Ciphers

One final word - and maybe this will help with Google results :) - I've tested this successfully against the following ciphers:

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

But that's not interesting, because this isn't an attack against ciphers. It's an attack against cipher-block chaining - CBC - that can occur against any cipher.

## Conclusion

So, hopefully you understand a little bit about how padding oracles work. If you haven't read my blog about [hash extension attacks](http://www.skullsecurity.org/blog/2012/everything-you-need-to-know-about-hash-length-extension-attacks), go do that. It's pretty cool. Otherwise, if you're going to be around for Shmoocon in DC this winter, come see my talk!