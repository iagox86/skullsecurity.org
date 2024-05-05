---
id: 1494
title: 'Prefix attacks'
date: '2013-01-15T15:15:06-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/2013/1485-revision-9'
permalink: '/?p=1494'
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
    background-color: #663366;
    text-align: center;
  }
</style></head><body>I've been posting a lot of blogs about crypto attacks lately, and today is no exception! Today, I'm going to be writing about a chosen prefix attack against block ciphers, and releasing a tool - [Prephixer](https://github.com/iagox86/prephixer) - to exploit it.

This post was actually inspired by a [post on Gist I saw](https://gist.github.com/3095168) entitled "ecb\_is\_bad.rb" - possibly from [Reddit](https://www.reddit.com) - about a chosen prefix attack against ECB ciphers. I decided to implement it myself as an exercise, and quickly discovered that the attack works in other cipher modes - specifically, CBC mode - and that the attacker-controlled text doesn't actually have to be at the beginning.

I'm sure this attack has been done before - it's fairly obvious, when you think about it - but I hadn't heard of it, so I wanted to share with others.

But let's step back a little.

## The setup

Like all crypto attacks, this requires a certain setup. In this case, the setup is this: the attacker is allowed to choose part of the plaintext of an encrypted string, and is given the ciphertext of that string. They're allowed to repeat this - with the crypto operation using the same key and IV - repeatedly until the string is decrypted.

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

Now, there's a serious problem with doing that: if you have two identical blocks (say, "AAAAAAAA" and "AAAAAAAA"), they will encrypt exactly the same. That's a problem, because it reveals information about the plaintext data; namely, that this block over here is identical to that block over there. This form of encryption is called the "electronic codebook" - or ECB - and leads to problems like the famous [ECB-encrypted Tux](https://en.wikipedia.org/wiki/File:Tux_ecb.jpg), where black and white always encrypt to the same value, leaving the outline of Tux perfectly visible.

Naturally, we don't want that, so the crypto people invented a bunch of other "modes of operation". The mode we care about is called cipher-block chaining - or CBC - where each block is XORed with an initialization vector (IV). The IV of each block is the ciphertext of the previous block. The IV of the first block is typically random, or blank.

In other words, the plaintext of each block is mixed with the ciphertext of the block before it, or with random data if it's the first block. You can see a full diagram [on the applicable Wikipedia page](https://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Cipher-block_chaining_.28CBC.29).

Unlike my previous blogs, the down and dirty details aren't really important. If you have some idea of how block ciphers work, you'll be fine.

## A simple oracle

Once again, we need an oracle to perform this attack. This time, it's an encryption oracle. Here's a simple one in Ruby:

```

 require 'openssl'

 def do_crypto(prefix)
   c = OpenSSL::Cipher::Cipher.new("DES-ECB")
   c.encrypt
   c.key = "MYDESKEY"
   return c.update("#{prefix}This is some test data") + c.final
 end
```

Note that even though I'm using DES-ECB, but that this attack works on all block ciphers that use either ECB or CBC. ECB is easier to demonstrate, though.

We can see what blocks look like by encrypting two blocks with the same value:

```

irb(main):004:0gt; c.do_crypto('A' * 18)
```

|  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'A' |  | 'T' |  | 'h' |  | 'i' |  | 's' |  | ' ' |  | 'i' |  | 's' |  | ' ' |  | 's' |  | 'o' |  | 'm' |  | 'e' |  | ' ' |  | 't' |  | 'e' |  | 's' |  | 't' |  | ' ' |  | 'd' |  | 'a' |  | 't' |  | 'a' |  | \\x02 |  | \\x02 |  |
|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-----|---|-------|---|-------|---|
|  | \\x74 |  | \\x31 |  | \\xe1 |  | \\xf0 |  | \\xc6 |  | \\x1b |  | \\x35 |  | \\x11 |  | \\x74 |  | \\x31 |  | \\xe1 |  | \\xf0 |  | \\xc6 |  | \\x1b |  | \\x35 |  | \\x11 |  | \\x35 |  | \\x13 |  | \\x7b |  | \\x27 |  | \\xb6 |  | \\xf5 |  | \\xda |  | \\x9c |  | \\xb1 |  | \\x0e |  | \\xdf |  | \\x42 |  | \\x93 |  | \\xe8 |  | \\x17 |  | \\x42 |  | \\xe0 |  | \\x6f |  | \\xcf |  | \\xc0 |  | \\xcf |  | \\xfe |  | \\x87 |  | \\x66 |  |

Notice that the first block - 'AAAAAAAA' - encrypts the same as the second block - 'AAAAAAAA'. That's how ECB works. If we were using CBC mode, they wouldn't:

```

irb(main):003:0> c.do_crypto_cbc('A' * 16)
```

'A''A''A''A''A''A''A''A' 'A''A''A''A''A''A''A''A' 'T''h''i''s'' ''i''s'' ' 's''o''m''e'' ''t''e''s' 't'' ''d''a''t''a'\\x02\\x02 |  | \\x74 | \\x31 | \\xe1 | \\xf0 | \\xc6 | \\x1b | \\x35 | \\x11 | \\x9b | \\xe3 | \\x5d | \\x5c | \\x77 | \\x84 | \\x51 | \\xed |  | \\xfc | \\xe6 | \\x65 | \\xdf | \\x8f | \\xec | \\x88 | \\x08 | \\xa3 | \\x1f | \\xcf | \\x94 | \\xf5 | \\x56 | \\x82 | \\x25 |  | \\x0c | \\x7f | \\xc7 | \\x9b | \\xdd | \\x02 | \\x83 | \\x4b |
|----------------------------------------------------------------------------------------------------------------------------------|---|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|---|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|---|-------|-------|-------|-------|-------|-------|-------|-------|

Since we used a blank IV, the first block encrypts the same, but the second block is different. Now, let's get onto something good!