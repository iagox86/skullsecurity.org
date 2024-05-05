---
id: 1499
title: 'Prefix attacks'
date: '2013-01-15T17:15:32-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/2013/1485-revision-13'
permalink: '/?p=1499'
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
  .lnr { color: #90f020; }
  .Statement { color: #ffff60; }
  .Type { color: #60ff60; }
  .Identifier { color: #40ffff; }
  .Constant { color: #ffa0a0; }
  .Special { color: #ffa500; }
  .PreProc { color: #ff80ff; }
</style></head><body>I've been posting a lot of blogs about crypto attacks lately, and today is no exception! Today, I'm going to be writing about a chosen prefix attack against block ciphers, and releasing a tool—[Prephixer](https://github.com/iagox86/prephixer)—to exploit it.

This post was actually inspired by a [post on Gist I saw](https://gist.github.com/3095168) entitled "ecb\_is\_bad.rb"—possibly from [Reddit](https://www.reddit.com)—about a chosen prefix attack against ECB ciphers. I decided to implement it myself as an exercise, and quickly discovered that the attack works in other cipher modes—specifically, CBC mode—and that the attacker-controlled text doesn't actually have to be at the beginning.

I'm sure this attack has been done before—it's fairly obvious, when you think about it—but I hadn't heard of it, so I wanted to share with others.

But let's step back a little.

## The setup

Like all crypto attacks, this requires a certain setup. In this case, the setup is this: the attacker is allowed to choose part of the plaintext of an encrypted string, and is given the ciphertext of that string. They're allowed to repeat this—with the crypto operation using the same key and IV—repeatedly until the string is decrypted.

Let's look at it using math:

```

  Let P = the Plaintext string
  Let P<sub>1</sub> and P<sub>2</sub> = secret, arbitrarily sized substrings of P
  Let P′ = a part of the string that the attacker controls
  Let E = a block encryption function using ECB or CBC with a static key and IV

  C = E(P<sub>1</sub> || P′ || P<sub>2</sub>)
```

If an attacker can cause C to be calculated multiple times for differently values of P′, it is possible to decrypt P<sub>2</sub>. Let's see how!

Instead of doing anything technical or math-like this time, I'm just going to work through an example. Hopefully that will make this easier to understand!

## A quick refresher on block ciphers

It's important to understand [block ciphers](https://en.wikipedia.org/wiki/Block_cipher) and, in particular, [block cipher modes of operation](https://en.wikipedia.org/wiki/Block_cipher_modes_of_operation) before you read this blog post.

Here's the idea: a block cipher encrypts data in chunks. Most commonly, data is encrypted 64 bits (8 bytes) or 128 bits (16 bytes) at a time. The data is broken into appropriately sized chunks, and each chunk is encrypted by itself.

Now, there's a serious problem with doing that: if you have two identical blocks (say, "AAAAAAAA" and "AAAAAAAA"), they will encrypt exactly the same. That's a problem, because it reveals information about the plaintext data; namely, that this block over here is identical to that block over there. This form of encryption is called the "electronic codebook"—or ECB—and leads to problems like the famous [ECB-encrypted Tux](https://en.wikipedia.org/wiki/File:Tux_ecb.jpg), where black and white always encrypt to the same value, leaving the outline of Tux perfectly visible.

Naturally, we don't want that, so the crypto people invented a bunch of other "modes of operation". The mode we care about is called cipher-block chaining—or CBC—where each block is XORed with an initialization vector (IV). The IV of each block is the ciphertext of the previous block. The IV of the first block is typically random, or blank.

In other words, the plaintext of each block is mixed with the ciphertext of the block before it, or with random data if it's the first block. You can see a full diagram [on the applicable Wikipedia page](https://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Cipher-block_chaining_.28CBC.29).

Unlike my previous blogs, the down and dirty details aren't really important. If you have some idea of how block ciphers work, you'll be fine.

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

Note that even though I'm using DES-ECB, but that this attack works on all block ciphers that use either ECB or CBC. ECB is easier to demonstrate, though.

We can see what blocks look like by encrypting two blocks with the same value:

```

irb(main):004:0gt; c.do_crypto('A' * 18)
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

Notice that the first block—'AAAAAAAA'—encrypts the same as the second block—'AAAAAAAA'. That's how ECB works. If we were using CBC mode, they wouldn't:

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

We start by adding a prefix to the string that's one less than the block size (in DES, which has a block size of 8 bytes, that's 7 bytes):

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

To decrypt the second character, we send block size - 2 characters, or 6 in our example:

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

Note that "AAAAAATh" encrypts to the same thing as our original string, "AAAAAATh". Now we know the second character. And so on!

## Second block and beyond

So, it's pretty obvious what we do to get the rest of the first block. Starting out the second block can be a little tricky, since we no longer have 'A's in our encrypted string. But, it turns out, it's not so bad! Let's assume we've broken "This is so", which means we have all of the first block ("This is ") and two characters of the second block ("so"). Now what?

Well, like before, we want to add a prefix that forces the first unknown chracter to be on a block boundary. In this case, that's 5 characters:

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

Once again, we successfully discover that the "m" character is next, making the string, at that point, "This is som".

Obviously, this can be applied over and over!

## Handling CBC and CTR

The example I gave was for electronic codebook—ECB mode. Now, how do we handle cipher-block chaining (CBC) and counter (CTR) modes?

Well, it turns out, there's absolutely no change. The code and algorithm and everything else work out of the box in CBC and CTR modes, *assuming the IV doesn't change*. If the IV is randomized, you're outta luck—you won't be able to exploit this vulnerability.

## Handling prefixes

We looked at the case where we have P = P′ || P<sub>1</sub>—that is, the attacker-controlled data is at the start of the string. But what happens if we have P = P<sub>1</sub> || P′ || P<sub>2</sub>—that is, the attacker-controlled string is in the middle of the string?

Well, first off, it's going to be impossible to decrypt P<sub>1</sub>. However, P<sub>2</sub> is still vulnerable to attack, but we need to find a block that we entirely control. Let's use a new oracle:

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

Similar to the old one, except now there's a prefix that's equal to, literally, "prefix". Let's do what we did earlier, and pass in two full blocks of "A":

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

Note that there is only one block full of 'A's, so we don't have a good idea of where in the string we control. There's a good chance that there are better ways to solve this type of problem, but I'll talk about the solution I used for Prephixer. It's pretty slick, in my opinion, and works equally well on ECB, CBC, and CTR modes (my original solution only worked on ECB).

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

Then I look at where the encrypted data starts changing. In this case, since the prefix is smaller than a block, it starts changing immediately (at block 0). But if the prefix was longer than a block there would be a certain number of static blocks at the start of the string that we would have to ignore.

So the first block of 'A's is our goal: 'prefixAA' => "\\x8b\\x58\\x85\\x18\\x89\\xe9\\x5b\\xba"

Next, I start filling the 'B' string with 'A's until we get the same value for P<sub>1</sub>:

```

irb(main):008:0* Crypto.do_crypto(("A" * 1) + ("B" * 15))
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

From here on, we can prepend two 'A's to every test string and ignore the first block in the response. Once we do that, the attack is exactly the same as it was before. We can decrypt P<sub>2</sub> the same way we encrypted it in the previous examples!

## Introducing: Prephixer

As always I wrote a tool to automate this: [. Much like the ](https://github.com/iagox86/prephixer)[padding oracle](/blog/2013/padding-oracle-attacks-in-depth) tool I wrote, [Poracle](https://github.com/iagox86/Poracle), this is implemented as a library and requires a module to make it work. And, just like Poracle, it comes with a couple example modules, [LocalTestModule.rb](https://github.com/iagox86/prephixer/blob/master/LocalTestModule.rb) and [RemoteTestModule.rb](https://github.com/iagox86/prephixer/blob/master/RemoteTestModule.rb) to demonstrate the right way to use it.

Basically, you instantiate a module that contains a few key methods—the most important being encrypt\_with\_prefix()—and pass it to Prephixer.decrypt(). Prephixer.decrypt() will call that method until it figures out what the original string was. Easy!

Prephixer also determined blocksize, the offset of the attacker-controlled text, and which blocks it controls automatically. It's pretty smart!

## Defense

People give me a hard time when I don't talk about how to prevent this type of attack. So, here you go. Usually, I promote HMAC as a way to solve every attack, but this time it's not enough!

At the core of it, this is a key-reuse attack. The only time this attack works, as I mentioned above, is when an application re-uses the same IV on multiple crypto operations. By using a new (and strong) IV for every message, and using CBC or CTR mode, this attack is completely prevented.

ECB, sadly, has no IV, and therefore there's no way to prevent this type of attack against ECB. Sorry, but if you're using ECB, you're doomed. Please don't use ECB, for this and so many other reasons...