---
id: 1485
title: 'Chosen prefix attacks and key re-use'
date: '2013-01-16T13:56:22-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1485'
permalink: '/?p=1485'
categories:
    - Conferences
    - Crypto
    - Hacking
    - Tools
---

<style>
  pre {
    font-family: monospace;
    color: #c0c0c0;
    background-color: #000040; }
  .c1 {
    width: 10px;
    background-color: #336633;
    text-align: center;
  }
  .c2 {
    width: 10px;
    background-color: #558855;
    text-align: center;
  }
  .c1a {
    width: 10px;
    color: #FF0000;
    background-color: #336633;
    text-align: center;
  }
  .c2a {
    width: 10px;
    color: #FF0000;
    background-color: #558855;
    text-align: center;
  }
  .lnr {
    color: #90f020;
  }
  .Statement {
    color: #ffff60;
  }
  .Type {
    color: #60ff60;
  }
  .Identifier {
    color: #40ffff;
  }
  .Constant {
    color: #ffa0a0;
  }
  .Special {
    color: #ffa500;
  }
  .PreProc {
    color: #ff80ff;
  }
</style></head><body>I've been posting a lot of blogs about crypto attacks lately, and today is no exception! Today, I'm going to be writing about a chosen prefix attack against most major ciphers, and releasing a tool—[Prephixer](https://github.com/iagox86/prephixer)—to exploit it. Essentially, the vulnerability allows an attacker to decrypt an encrypted string, one byte at a time, under the right circumstances, using a chosen prefix.

This attack is actually a key-reuse attack—that is, it works when an attacker is able to encrypt secret data with a chosen prefix multiple times with the same key and initialization vector (IV). I'll talk about what keys and IVs are later in this post.

This post was actually inspired by a [post on Gist I saw](https://gist.github.com/3095168) entitled "ecb\_is\_bad.rb"—possibly from [Reddit](https://www.reddit.com)—about a chosen prefix attack against ECB ciphers. I decided to implement it myself as an exercise, and quickly discovered that the attack works in other cipher modes—specifically, CBC mode— and even stream ciphers, as long as the key and IV are re-used (which is far too common, but also seriously impacts the security of an algorithm.

In the end, I wound up with a tool that can successfully decrypt almost every [cipher mode](https://en.wikipedia.org/wiki/Block_cipher_modes_of_operation)—ECB, CBC, OFB, CFB, CTR, etc.—and even RC4 and RC2, assuming they re-use keys and IVs.

I'm sure this attack has been done before—it's fairly obvious, when you think about it—but I hadn't heard of it, so I wanted to share with others.

But let's step back a little.

## The setup

Like all crypto attacks, this requires a certain setup. In this case, the setup is this: the attacker is allowed to choose part of the plaintext of an encrypted string, and is given the ciphertext of the entire string. The application/service that performs this encryption operation on behalf of users (or attackers) is often referred to as an "encryption oracle". The user is able to repeat this—with the same crypto operation using the same key and IV—until the string is decrypted.

When does this happen in the real world? Well, any time a user is entrusted with encrypted data, there's a good chance that part of that encrypted data contains something controlled by the attacker, and that's all that's needed. One example that immediately comes to mind is when Web servers encrypt session data and return it to a browser in a hidden field or cookie.

Let's define some variables to save us some time later:

```

  Let P = the Plaintext string
  Let P<sub>1</sub> and P<sub>2</sub> = secret, arbitrarily sized substrings of P (not necessarily block-aligned)
  Let P′ = a part of the string that the attacker controls
  Let E() = an encryption function with a set key/IV

  Let C = E(P) - The encrypted version of P

  For the purposes of our attack:
  Let C′ = E(P<sub>1</sub> || P′ || P<sub>2</sub>)
```

If an attacker can cause C′ to be calculated multiple times for different values of P′, it is possible to decrypt P<sub>2</sub>. Let's see how!

Instead of doing anything technical or math-like this time, I'm just going to work through an example. Hopefully that will make this easier to understand!

## A quick refresher on ciphers

It's important to understand [block ciphers](https://en.wikipedia.org/wiki/Block_cipher) before you read this blog. It may also be useful to understand the different [block cipher modes of operation](https://en.wikipedia.org/wiki/Block_cipher_modes_of_operation), since I refer to them throughout the post, but it isn't strictly necessary.

Here's the idea: a cipher encrypts data. A stream cipher encrypts data bit by bit (or, effectively, byte by byte). A block cipher encrypts data block by block - that is, 8 or 16 bytes at a time (usually). Some block ciphers behave like stream ciphers, in the sense that a block cipher is used to generate a stream of bits, and those bits are used to encrypt the stream.

In general, plaintext encrypted with the same key will generate the same ciphertext. That's generally considered a Bad Thing(tm), because it gives away information about the data and can lead to data leakage. As a result, a construct called an [initialization vector](https://en.wikipedia.org/wiki/Initialization_vector)—an IV— was invented. The initialization vector is a random value that's incorporated into the beginning of data to ensure uniqueness between messages.

Some modes—such as the [Electronic Codebook mode of operation](https://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Electronic_codebook_.28ECB.29)—don't even have the capability of IVs, and therefore are always vulnerable to this attack. Most ciphers, though, allow the user to set an IV, but that depends on the developer actually knowing that he has to.

Now, here's the problem: if an encryption oracle—an application, a service, or whatever&mash;uses the same IV for every message, *a lot* of information about that message is leaked, and is open to attack. There are many attacks against it that we won't get into for this blog: the one we'll worry about is a chosen prefix attack that affects almost every cipher.

Here's the idea: we let the server encrypt the unknown string, guess a byte (for stream ciphers) or a block (for block ciphers) and add it to the beginning, then encrypt it again with the new prefix. The result ciphertext is compared to the original ciphertext - if the byte or block encrypts the same way, then we know we guessed correctly. Otherwise, we guess again - there are only 256 possible values!

That's basically the entire attack: now let's go through an example of how it can work!

## A simple oracle

Once again, we need an oracle to perform this attack. This time, it's an encryption oracle. Here's a simple one in Ruby:

```

<span class="lnr">1 </span> <span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">openssl</span><span class="Special">'</span>
<span class="lnr">2 </span>
<span class="lnr">3 </span> <span class="PreProc">def</span> <span class="Identifier">do_crypto</span>(prefix)
<span class="lnr">4 </span>   c = <span class="Type">OpenSSL</span>::<span class="Type">Cipher</span>::<span class="Type">Cipher</span>.new(<span class="Special">"</span><span class="Constant">DES-ECB</span><span class="Special">"</span>)
<span class="lnr">5 </span>   c.encrypt
<span class="lnr">6 </span>   c.key = <span class="Special">"</span><span class="Constant">MYDESKEY</span><span class="Special">"</span>
<span class="lnr">7 </span>   <span class="Statement">return</span> c.update(<span class="Special">"</span><span class="Special">#{</span>prefix<span class="Special">}</span><span class="Constant">This is some test data</span><span class="Special">"</span>) + c.final
<span class="lnr">8 </span> <span class="PreProc">end</span>
```

Note that I'm using DES-ECB for purposes of simplicity (it's much more obvious to the user what's changing), but this same attack works on pretty much all stream and block ciphers.

We can see what blocks look like by encrypting two blocks with the same value:

```

irb(main):004:0> c.do_crypto('A' * 18)
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x74 | \\x31 | \\xe1 | \\xf0 | \\xc6 | \\x1b | \\x35 | \\x11 |
 |  | **P<sub>2</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' |
 |  | **C<sub>2</sub>** |  | \\x74 | \\x31 | \\xe1 | \\xf0 | \\xc6 | \\x1b | \\x35 | \\x11 |
 |  | **P<sub>3</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>3</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |
 |  | **P<sub>4</sub>** |  | 's' | 'o' | 'm' | 'e' | ' ' | 't' | 'e' | 's' |
 |  | **C<sub>4</sub>** |  | \\xb1 | \\x0e | \\xdf | \\x42 | \\x93 | \\xe8 | \\x17 | \\x42 |
 |  | **P<sub>5</sub>** |  | 't' | ' ' | 'd' | 'a' | 't' | 'a' | \\x02 | \\x02 |
 |  | **C<sub>5</sub>** |  | \\xe0 | \\x6f | \\xcf | \\xc0 | \\xcf | \\xfe | \\x87 | \\x66 |

Notice that the first block—'AAAAAAAA'—encrypts the same as the second block—'AAAAAAAA'. That's how ECB works. If we were using CBC or other modes, they wouldn't:

```

irb(main):003:0> c.do_crypto_cbc('A' * 16)
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x74 | \\x31 | \\xe1 | \\xf0 | \\xc6 | \\x1b | \\x35 | \\x11 |
 |  | **P<sub>2</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' |
 |  | **C<sub>2</sub>** |  | \\x9b | \\xe3 | \\x5d | \\x5c | \\x77 | \\x84 | \\x51 | \\xed |
 |  | **P<sub>3</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>3</sub>** |  | \\xfc | \\xe6 | \\x65 | \\xdf | \\x8f | \\xec | \\x88 | \\x08 |
 |  | **P<sub>4</sub>** |  | 's' | 'o' | 'm' | 'e' | ' ' | 't' | 'e' | 's' |
 |  | **C<sub>4</sub>** |  | \\xa3 | \\x1f | \\xcf | \\x94 | \\xf5 | \\x56 | \\x82 | \\x25 |
 |  | **P<sub>5</sub>** |  | 't' | ' ' | 'd' | 'a' | 't' | 'a' | \\x02 | \\x02 |
 |  | **C<sub>5</sub>** |  | \\x0c | \\x7f | \\xc7 | \\x9b | \\xdd | \\x02 | \\x83 | \\x4b |

Since we used a blank IV, the first block encrypts the same as it did in ECB mode, but the second block is different. Now, let's get onto something good!

## Decrypting the first byte

All right, let's start with the first byte of plaintext—'T' from 'This'. That's going to be our goal.

We start by adding a prefix to the string that's one byte less than the block size (in DES, which has a block size of 8 bytes, that's 7 bytes):

```

irb(main):004:0> Crypto.do_crypto_cbc("A" * 7)
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xea | \\xca | \\x59 | \\x30 | \\x3d | \\x8b | \\xe6 | \\x0f |
 |  | **P<sub>2</sub>** |  | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' |
 |  | **C<sub>2</sub>** |  | \\xf2 | \\xaa | \\xb1 | \\xfb | \\x54 | \\xb4 | \\xb5 | \\x87 |
 |  | **P<sub>3</sub>** |  | 'o' | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' |
 |  | **C<sub>3</sub>** |  | \\x34 | \\x87 | \\x06 | \\x80 | \\x9a | \\xcc | \\xad | \\x43 |
 |  | **P<sub>4</sub>** |  | ' ' | 'd' | 'a' | 't' | 'a' | \\x03 | \\x03 | \\x03 |
 |  | **C<sub>4</sub>** |  | \\xd3 | \\x71 | \\x2a | \\xf5 | \\x79 | \\x10 | \\x25 | \\xea |

Let's focus specifically on the first block—we now know that the encrypted version of "AAAAAAAT" is "\\xea\\xca\\x59\\x30\\x3d\\x8b\\xe6\\x0f". But as an attacker, all we know is that the encrypted version of "AAAAAAA?" is "\\xea\\xca\\x59\\x30\\x3d\\x8b\\xe6\\x0f", where the last character, "?", is unknown.

Now, we try "AAAAAAA" followed by all 256 possible characters, and focus only on the first block (I'll leave out the other blocks to save on space):

```

irb(main):009:0> 0.upto(255) do |i|
irb(main):010:1>   Crypto.do_crypto(("A" * 7) + i.chr)
irb(main):011:1> end

...
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'R' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x1a | \\xcd | \\xb7 | \\xe1 | \\x22 | \\x0b | \\xda | \\x85 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'S' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x1c | \\x32 | \\x22 | \\x39 | \\xb7 | \\x99 | \\x73 | \\x42 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xea | \\xca | \\x59 | \\x30 | \\x3d | \\x8b | \\xe6 | \\x0f |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'U' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x5a | \\x3c | \\x17 | \\x25 | \\xc8 | \\x0f | \\x68 | \\x3f |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'V' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xba | \\x23 | \\x5e | \\xa1 | \\xed | \\x55 | \\x19 | \\x5f |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 ... Take a close look at the middle one—the first block is 'AAAAAAAT', and encrypts to the same thing that 'AAAAAAAT' encrypted to originally—that's how encryption works! Now we know that the first character of plaintext is 'T'

I think it's pretty obvious from here how it goes, but as long as I spent all that time writing a program to generate HTML tables, I might as well do another character or two!

## The second character

To decrypt the second character, we send (block size minus 2) characters, or 6 in our example:

```

irb(main):019:0> Crypto.do_crypto("A" * 6)
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'h' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xcb | \\x7a | \\x74 | \\xd0 | \\x38 | \\x45 | \\xbf | \\x21 |
 |  | **P<sub>2</sub>** |  | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' |
 |  | **C<sub>2</sub>** |  | \\xf9 | \\x8e | \\xcd | \\xdf | \\x49 | \\xf0 | \\x86 | \\xcb |
 |  | **P<sub>3</sub>** |  | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' |
 |  | **C<sub>3</sub>** |  | \\x70 | \\x8c | \\xc0 | \\x1d | \\xe5 | \\xf2 | \\xdc | \\x01 |
 |  | **P<sub>4</sub>** |  | 'd' | 'a' | 't' | 'a' | \\x04 | \\x04 | \\x04 | \\x04 |
 |  | **C<sub>4</sub>** |  | \\xb4 | \\x74 | \\xfc | \\x99 | \\xd9 | \\xbe | \\xd2 | \\x70 |

Now our first block is "AAAAAAT?", which we know encrypts to "\\xcb\\x7a\\x74\\xd0\\x38\\x45\\xbf\\x21". Since there's only one missing character, we can easily bruteforce:

```

irb(main):020:0> 0.upto(255) do |i|
irb(main):021:1>   Crypto.do_crypto(("A" * 6) + "T" + i.chr)
irb(main):022:1> end

...
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'f' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xd4 | \\x4d | \\xd8 | \\xd4 | \\xec | \\xdb | \\x43 | \\x79 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'g' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xbb | \\x48 | \\x96 | \\xa3 | \\xb9 | \\xb5 | \\xc4 | \\x32 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'h' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xcb | \\x7a | \\x74 | \\xd0 | \\x38 | \\x45 | \\xbf | \\x21 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'i' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x79 | \\xc2 | \\x04 | \\x11 | \\x64 | \\xd0 | \\xae | \\xc2 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'j' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x2f | \\x44 | \\x59 | \\xb5 | \\x88 | \\x96 | \\xa9 | \\x99 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 ... Note that "AAAAAATh" encrypts to the same thing as our original string, "AAAAAATh". Now we know the second character: "h". We just repeat this over and over till the entire block is decrypted!

## Second block and beyond

So, it's pretty obvious what we do to get the rest of the first block. Starting out the second block can be a little tricky, since we no longer have 'A's in our encrypted string. But, it turns out, it's not so bad! Let's assume we've broken "This is so", which means we have all of the first block ("This is ") and two characters of the second block ("so"). Now what?

Well, like before, we want to add a prefix that forces the first unknown character to be immediately before a block boundary. In this case, that's 5 characters:

```

irb(main):026:0> Crypto.do_crypto("A" * 5)
```

|  | **P<sub>1</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'h' | 'i' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xc0 | \\x60 | \\x3c | \\x7d | \\x5d | \\x49 | \\x95 | \\xa6 |
 |  | **P<sub>2</sub>** |  | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' | 'm' |
 |  | **C<sub>2</sub>** |  | \\x52 | \\xb3 | \\x93 | \\x2a | \\x05 | \\x88 | \\x3a | \\xa0 |
 |  | **P<sub>3</sub>** |  | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' | 'd' |
 |  | **C<sub>3</sub>** |  | \\xa8 | \\xc8 | \\x40 | \\xd7 | \\xd3 | \\x65 | \\xdc | \\x92 |
 |  | **P<sub>4</sub>** |  | 'a' | 't' | 'a' | \\x05 | \\x05 | \\x05 | \\x05 | \\x05 |
 |  | **C<sub>4</sub>** |  | \\x1a | \\xe8 | \\x19 | \\x39 | \\xa6 | \\x45 | \\xa9 | \\x81 |

Now, on the second line, we see that "s is som" encrypts to "\\x52\\xb3\\x93\\x2a\\x05\\x88\\x3a\\xa0". We already know "s is so", so we wind up with the block "s is so?" = "\\x52\\xb3\\x93\\x2a\\x05\\x88\\x3a\\xa0". One unknown character? That's easy! We just manipulate the first block again until we figure out the right one:

```

irb(main):034:0> "k"[0].upto("o"[0]) do |i|
irb(main):035:1>   Crypto.do_crypto("s is so" + i.chr)
irb(main):036:1> end

...
```

|  | **P<sub>1</sub>** |  | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' | 'k' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xf3 | \\x64 | \\x29 | \\xea | \\x9f | \\xe6 | \\xde | \\x58 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' | 'l' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x0f | \\xe3 | \\xa8 | \\x80 | \\x95 | \\xbc | \\x52 | \\xc1 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' | 'm' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x52 | \\xb3 | \\x93 | \\x2a | \\x05 | \\x88 | \\x3a | \\xa0 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' | 'n' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x6c | \\xbb | \\x28 | \\xc0 | \\x47 | \\x35 | \\xd1 | \\x37 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 |  | **P<sub>1</sub>** |  | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' | 'o' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x43 | \\x98 | \\x26 | \\x35 | \\x1a | \\x1b | \\xbe | \\x99 |
 |  | **P<sub>2</sub>** |  | 'T' | 'h' | 'i' | 's' | ' ' | 'i' | 's' | ' ' |
 |  | **C<sub>2</sub>** |  | \\x35 | \\x13 | \\x7b | \\x27 | \\xb6 | \\xf5 | \\xda | \\x9c |

 ... Once again, we successfully discover that the "m" character is next, making the string, at that point, "This is som". Then we work on the next character the exact same way, and the next character, and so on

Obviously, this can be applied over and over!

## Handling other modes

The example I gave was for electronic codebook—ECB—mode. Now, how do we handle cipher-block chaining (CBC), output feedback (OFB), plaintext feedback (PFB), counter (CTR), or RC4?

Well, it turns out, there's absolutely no change. The code and algorithm and everything else work out of the box for all block cipher modes of operation. It also works out of the box for stream ciphers, if we treat the stream ciphers like block ciphers with a block size of one byte. That was a surprise to me - I thought I'd have to write special code for stream ciphers, but they actually worked automatically. Sweet!

This is, of course, *assuming the IV doesn't change* for these ciphers. If the IV is randomized, you're outta luck—you won't be able to decrypt the text, because there's no vulnerability.

## Handling prefixes

We looked at the case where we have P = P′ || P<sub>2</sub>—that is, the attacker-controlled data is at the start of the string. But what happens if we have P = P<sub>1</sub> || P′ || P<sub>2</sub>; that is, the attacker-controlled string is in the middle of the string?

Well, first off, it's going to be impossible to decrypt P<sub>1</sub>. However, P<sub>2</sub> is still vulnerable to attack; all we have to do is find a block that we entirely control. Let's modify our oracle slightly:

```

<span class="lnr">1 </span> <span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">openssl</span><span class="Special">'</span>
<span class="lnr">2 </span>
<span class="lnr">3 </span> <span class="PreProc">def</span> <span class="Identifier">do_crypto</span>(prefix)
<span class="lnr">4 </span>   c = <span class="Type">OpenSSL</span>::<span class="Type">Cipher</span>::<span class="Type">Cipher</span>.new(<span class="Special">"</span><span class="Constant">DES-ECB</span><span class="Special">"</span>)
<span class="lnr">5 </span>   c.encrypt
<span class="lnr">6 </span>   c.key = <span class="Special">"</span><span class="Constant">MYDESKEY</span><span class="Special">"</span>
<span class="lnr">7 </span>   <span class="Statement">return</span> c.update(<span class="Special">"</span><span class="Constant">prefix</span><span class="Special">#{</span>prefix<span class="Special">}</span><span class="Constant">This is some test data</span><span class="Special">"</span>) + c.final
<span class="lnr">8 </span> <span class="PreProc">end</span>
```

Similar to the old one, except now there's a prefix that's equal to, literally, "prefix". Let's do what we did earlier, and encrypt two full blocks of "A":

```

irb(main):002:0> Crypto.do_crypto("A" * 16)
```

|  | **P<sub>1</sub>** |  | 'p' | 'r' | 'e' | 'f' | 'i' | 'x' | 'A' | 'A' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x8b | \\x58 | \\x85 | \\x18 | \\x89 | \\xe9 | \\x5b | \\xba |
 |  | **P<sub>2</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' |
 |  | **C<sub>2</sub>** |  | \\x74 | \\x31 | \\xe1 | \\xf0 | \\xc6 | \\x1b | \\x35 | \\x11 |
 |  | **P<sub>3</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'h' |
 |  | **C<sub>3</sub>** |  | \\xcb | \\x7a | \\x74 | \\xd0 | \\x38 | \\x45 | \\xbf | \\x21 |
 |  | **P<sub>4</sub>** |  | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' |
 |  | **C<sub>4</sub>** |  | \\xf9 | \\x8e | \\xcd | \\xdf | \\x49 | \\xf0 | \\x86 | \\xcb |
 |  | **P<sub>5</sub>** |  | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' |
 |  | **C<sub>5</sub>** |  | \\x70 | \\x8c | \\xc0 | \\x1d | \\xe5 | \\xf2 | \\xdc | \\x01 |
 |  | **P<sub>6</sub>** |  | 'd' | 'a' | 't' | 'a' | \\x04 | \\x04 | \\x04 | \\x04 |
 |  | **C<sub>6</sub>** |  | \\xb4 | \\x74 | \\xfc | \\x99 | \\xd9 | \\xbe | \\xd2 | \\x70 |

Note that there is only one block full of 'A's, so using only the ciphertext we don't really know where the string we control starts. Luckily, it's possible to figure out the first full block we control with a little bit of work. There's a good chance that there are better ways to solve this type of problem than what I figured out, but I'm happy that my solution works perfectly on ECB, CBC, OFB, PFB, CTR, and all other ciphers (my original solution, which took hours to write in the middle of the night one time, only worked on ECB).

First, I encrypt two blocks of just 'A', and two blocks of just 'B':

```

irb(main):003:0> Crypto.do_crypto("A" * 16)
```

|  | **P<sub>1</sub>** |  | 'p' | 'r' | 'e' | 'f' | 'i' | 'x' | 'A' | 'A' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x8b | \\x58 | \\x85 | \\x18 | \\x89 | \\xe9 | \\x5b | \\xba |
 |  | **P<sub>2</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' |
 |  | **C<sub>2</sub>** |  | \\x74 | \\x31 | \\xe1 | \\xf0 | \\xc6 | \\x1b | \\x35 | \\x11 |
 |  | **P<sub>3</sub>** |  | 'A' | 'A' | 'A' | 'A' | 'A' | 'A' | 'T' | 'h' |
 |  | **C<sub>3</sub>** |  | \\xcb | \\x7a | \\x74 | \\xd0 | \\x38 | \\x45 | \\xbf | \\x21 |
 |  | **P<sub>4</sub>** |  | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' |
 |  | **C<sub>4</sub>** |  | \\xf9 | \\x8e | \\xcd | \\xdf | \\x49 | \\xf0 | \\x86 | \\xcb |
 |  | **P<sub>5</sub>** |  | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' |
 |  | **C<sub>5</sub>** |  | \\x70 | \\x8c | \\xc0 | \\x1d | \\xe5 | \\xf2 | \\xdc | \\x01 |
 |  | **P<sub>6</sub>** |  | 'd' | 'a' | 't' | 'a' | \\x04 | \\x04 | \\x04 | \\x04 |
 |  | **C<sub>6</sub>** |  | \\xb4 | \\x74 | \\xfc | \\x99 | \\xd9 | \\xbe | \\xd2 | \\x70 |

 |  | **P<sub>1</sub>** |  | 'p' | 'r' | 'e' | 'f' | 'i' | 'x' | 'B' | 'B' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xd0 | \\x0d | \\x0c | \\x02 | \\x4e | \\x2a | \\xa8 | \\x35 |
 |  | **P<sub>2</sub>** |  | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' |
 |  | **C<sub>2</sub>** |  | \\x59 | \\xac | \\x9a | \\x16 | \\x94 | \\x2b | \\x78 | \\xe7 |
 |  | **P<sub>3</sub>** |  | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'T' | 'h' |
 |  | **C<sub>3</sub>** |  | \\xc4 | \\x7e | \\x60 | \\xf3 | \\x69 | \\x9e | \\x24 | \\x24 |
 |  | **P<sub>4</sub>** |  | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' |
 |  | **C<sub>4</sub>** |  | \\xf9 | \\x8e | \\xcd | \\xdf | \\x49 | \\xf0 | \\x86 | \\xcb |
 |  | **P<sub>5</sub>** |  | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' |
 |  | **C<sub>5</sub>** |  | \\x70 | \\x8c | \\xc0 | \\x1d | \\xe5 | \\xf2 | \\xdc | \\x01 |
 |  | **P<sub>6</sub>** |  | 'd' | 'a' | 't' | 'a' | \\x04 | \\x04 | \\x04 | \\x04 |
 |  | **C<sub>6</sub>** |  | \\xb4 | \\x74 | \\xfc | \\x99 | \\xd9 | \\xbe | \\xd2 | \\x70 |

Then I look at where the encrypted data starts changing. In this case, since the prefix is smaller than a block, it starts changing immediately (at block 1 (C<sub>1</sub>). But if the prefix was longer than a block there would be a certain number of unchanging blocks at the start of the string that we would have to ignore.

So the first block of 'A's is our goal: 'prefixAA' => "\\x8b\\x58\\x85\\x18\\x89\\xe9\\x5b\\xba"

Next, I start filling the 'B' string with 'A's until we get the same value for P<sub>1</sub>:

```

irb(main):008:0> Crypto.do_crypto(("A" * 1) + ("B" * 15))
```

|  | **P<sub>1</sub>** |  | 'p' | 'r' | 'e' | 'f' | 'i' | 'x' | 'A' | 'B' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\xa7 | \\x21 | \\xc9 | \\x35 | \\xa9 | \\x90 | \\x3b | \\x58 |
 |  | **P<sub>2</sub>** |  | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' |
 |  | **C<sub>2</sub>** |  | \\x59 | \\xac | \\x9a | \\x16 | \\x94 | \\x2b | \\x78 | \\xe7 |
 |  | **P<sub>3</sub>** |  | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'T' | 'h' |
 |  | **C<sub>3</sub>** |  | \\xc4 | \\x7e | \\x60 | \\xf3 | \\x69 | \\x9e | \\x24 | \\x24 |
 |  | **P<sub>4</sub>** |  | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' |
 |  | **C<sub>4</sub>** |  | \\xf9 | \\x8e | \\xcd | \\xdf | \\x49 | \\xf0 | \\x86 | \\xcb |
 |  | **P<sub>5</sub>** |  | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' |
 |  | **C<sub>5</sub>** |  | \\x70 | \\x8c | \\xc0 | \\x1d | \\xe5 | \\xf2 | \\xdc | \\x01 |
 |  | **P<sub>6</sub>** |  | 'd' | 'a' | 't' | 'a' | \\x04 | \\x04 | \\x04 | \\x04 |
 |  | **C<sub>6</sub>** |  | \\xb4 | \\x74 | \\xfc | \\x99 | \\xd9 | \\xbe | \\xd2 | \\x70 |

 irb(main):009:0> Crypto.do\_crypto(("A" \* 2) + ("B" \* 14)) |  | **P<sub>1</sub>** |  | 'p' | 'r' | 'e' | 'f' | 'i' | 'x' | 'A' | 'A' |
|---|---|-------------------|---|-----|-----|-----|-----|-----|-----|-----|-----|
 |  | **C<sub>1</sub>** |  | \\x8b | \\x58 | \\x85 | \\x18 | \\x89 | \\xe9 | \\x5b | \\xba |
 |  | **P<sub>2</sub>** |  | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' |
 |  | **C<sub>2</sub>** |  | \\x59 | \\xac | \\x9a | \\x16 | \\x94 | \\x2b | \\x78 | \\xe7 |
 |  | **P<sub>3</sub>** |  | 'B' | 'B' | 'B' | 'B' | 'B' | 'B' | 'T' | 'h' |
 |  | **C<sub>3</sub>** |  | \\xc4 | \\x7e | \\x60 | \\xf3 | \\x69 | \\x9e | \\x24 | \\x24 |
 |  | **P<sub>4</sub>** |  | 'i' | 's' | ' ' | 'i' | 's' | ' ' | 's' | 'o' |
 |  | **C<sub>4</sub>** |  | \\xf9 | \\x8e | \\xcd | \\xdf | \\x49 | \\xf0 | \\x86 | \\xcb |
 |  | **P<sub>5</sub>** |  | 'm' | 'e' | ' ' | 't' | 'e' | 's' | 't' | ' ' |
 |  | **C<sub>5</sub>** |  | \\x70 | \\x8c | \\xc0 | \\x1d | \\xe5 | \\xf2 | \\xdc | \\x01 |
 |  | **P<sub>6</sub>** |  | 'd' | 'a' | 't' | 'a' | \\x04 | \\x04 | \\x04 | \\x04 |
 |  | **C<sub>6</sub>** |  | \\xb4 | \\x74 | \\xfc | \\x99 | \\xd9 | \\xbe | \\xd2 | \\x70 |

There we go! When we prefix with two 'A's, we wind up with the block being "prefixAA", which, of course, encrypts to the same value as "prefixAA", namely, "\\x8b\\x58\\x85\\x18\\x89\\xe9\\x5b\\xba".

From here on, we can prepend two 'A's to every test string and ignore the first block in the response. Once we do that, the attack is exactly the same as it was before. We can decrypt P<sub>2</sub> the same way we decrypted it in the previous examples!

## Introducing: Prephixer

As always, I wrote a tool to automate this attack: [. Much like the ](https://github.com/iagox86/prephixer)[padding oracle](/blog/2013/padding-oracle-attacks-in-depth) tool I wrote, [Poracle](https://github.com/iagox86/Poracle), this is implemented as a library and requires a module to make it work. And, just like Poracle, it comes with a couple example modules, [LocalTestModule.rb](https://github.com/iagox86/prephixer/blob/master/LocalTestModule.rb) and [RemoteTestModule.rb](https://github.com/iagox86/prephixer/blob/master/RemoteTestModule.rb) to demonstrate the right way to use it.

Basically, you instantiate a module that contains a few key methods—the most important being encrypt\_with\_prefix()—and pass it to Prephixer.decrypt(). Prephixer.decrypt() will call that method until it figures out what the original string was. Easy!

Prephixer also determines blocksize, the offset of the attacker-controlled text, and which blocks it controls automatically. It's pretty smart!

## Defense

People give me a hard time when I don't talk about how to prevent this type of attack. So, here you go. Usually, I promote HMAC as a way to solve every attack, but this time it's not enough!

At the core of it, as I said originally, this is a key-reuse attack. The only time this attack works, as I've pointed out several times, is when an application re-uses the same IV on multiple crypto operations. By using a new (and strong) IV for every message, and using a non-ECB mode of operation, this attack is completely prevented. Other common defenses - using a stronger cipher, using a HMAC, using an authenticated cipher - cannot prevent this attack!

ECB, sadly, has no IV, and therefore there's no way to prevent this type of attack against ECB. Sorry, but if you're using ECB, you're doomed. Please don't use ECB, for this and so many other reasons...