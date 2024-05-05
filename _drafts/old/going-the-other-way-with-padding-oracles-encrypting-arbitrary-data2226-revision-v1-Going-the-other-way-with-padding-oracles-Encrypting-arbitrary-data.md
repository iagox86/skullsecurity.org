---
id: 2373
title: 'Going the other way with padding oracles: Encrypting arbitrary data!'
date: '2019-03-09T17:44:21-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2019/2226-revision-v1'
permalink: '/?p=2373'
---

A long time ago, I wrote a [couple](https://blog.skullsecurity.org/2013/padding-oracle-attacks-in-depth) [blogs](https://blog.skullsecurity.org/2013/a-padding-oracle-example) that went into a lot of detail on how to use padding oracle vulnerabilities to decrypt an encrypted string of data. It's pretty important to understand to use a padding oracle vulnerability for decryption before reading this, so I'd suggest going there for a refresher.

When I wrote that blog and the [Poracle](https://github.com/iagox86/poracle) tool originally, I didn't actually know how to encrypt arbitrary data using a padding oracle. I was vaguely aware that it was possible, but I hadn't really thought about it. But recently, I decided to figure out how it works. I thought and thought, and finally came up with this technique that seems to work. I also implemented it in Poracle in [commit a5cfad76ad](https://github.com/iagox86/poracle/commit/a5cfad76ada97862bdc1eb558937f03ad96d4ee6).  
  
Although I technically invented this technique myself, it's undoubtedly the same technique that any other tools / papers use. If there's a better way - especially on dealing with the first block - I'd love to hear it!

Anyway, in this post, we'll talk about a situation where you have a padding oracle vulnerability, and you want to *encrypt* arbitrary data instead of *decrypting* their data. It might, for example, be a cookie that contains a filename for your profile data. If you change the encrypted data in a cookie to an important file on the filesystem, suddenly you have arbitrary file read!

## The math

If you aren't familiar with block ciphers, how they're padded, how XOR (⊕) works, or how CBC chaining works, please read [my previous post](https://blog.skullsecurity.org/2013/padding-oracle-attacks-in-depth). I'm going to assume you're familiar with all of the above!

We'll define our variables more or less the same as last time:

```

  Let P   = the plaintext, and P<sub>n</sub> = the plaintext of block n (where n is in
            the range of 1..N). We select this.
  Let C   = the corresponding ciphertext, and C<sub>n</sub> = the ciphertext
            of block n (the first block being 1) - our goal is to calculate this
  Let N   = the number of blocks (P and C have the same number of blocks by
            definition). P<sub>N</sub> is the last plaintext block, and C<sub>N</sub> is
            the last ciphertext block.
  Let IV  = the initialization vector — a random string — frequently
            (incorrectly) set to all zeroes. We'll mostly call this C<sub>0</sub> in this
            post for simplicity (see below for an explanation).
  Let E() = a single-block encryption operation (any block encryption
            algorithm, such as AES or DES, it doesn't matter which), with some
            unique and unknown (to the attacker) secret key (that we don't
            notate here).
  Let D() = the corresponding decryption operation.
```

And the math for encryption:

```

  C<sub>1</sub> = E(P<sub>1</sub> ⊕ IV)
  C<sub>n</sub> = E(P<sub>n</sub> ⊕ C<sub>n-1</sub>) — for all n > 1
```

And, of course, decryption:

```

  P<sub>1</sub> = D(C<sub>1</sub>) ⊕ IV
  P<sub>n</sub> = D(C<sub>n</sub>) ⊕ C<sub>n-1</sub> - for all n > 1
```

Notice that if you define the IV as C<sub>0</sub>, both formulas could be simplified to just a single line.

## The attack

Like decryption, we divide the string into blocks, and attack one block at a time.

We start by taking our desired string, <tt>P</tt>, and adding the proper padding to it, so when it's decrypted, the padding is correct. If there are <tt>n</tt> bytes required to pad the string to a multiple of the block length, then the byte <tt>n</tt> is added <tt>n</tt> times.

For example, if the string is <tt>hello world!</tt> and the blocksize is 16, we have to add 4 bytes, so the string becomes <tt>hello world!\\x04\\x04\\x04\\x04</tt>. If the string is an exact multiple of the block length, we add a block afterwards with nothing but padding (so <tt>this is a test!!</tt>, because it's 16 bytes, becomes <tt>this is a test!!\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10\\x10</tt>, for example (assume the blocksize is 16, which will will throughout).

Once we have a string, <tt>P</tt>, we need to generate the ciphertext, <tt>C</tt> from it. And here's how that happens...

### Overview

After writing everything below, I realized that it's a bit hard to follow. Math, etc. So I'm going to start by summarizing the steps before diving more deeply into all the details. Good luck!

To encrypt arbitrary text with a padding oracle...

- Select a string, <tt>P</tt>, that you want to generate ciphertext, <tt>C</tt>, for
- Pad the string to be a multiple of the blocksize, using appropriate padding, then split it into blocks numbered from 1 to N
- Generate a block of random data (<tt>C<sub>N</sub></tt> - ultimately, the final block of ciphertext)
- For each block of plaintext, starting with the last one... 
  - Create a two-block string of ciphertext, <tt>C'</tt>, by combining an empty block (00000...) with the most recently generated ciphertext block (<tt>C<sub>n+1</sub></tt>) (or the random one if it's the first round)
  - Change the last byte of the empty block until the padding errors go away, then use math (see below for way more detail) to set the last byte to 2 and change the second-last byte till it works. Then change the last two bytes to 3 and figure out the third-last, fourth-last, etc.
  - After determining the full block, XOR it with the plaintext block <tt>P<sub>n</sub></tt> to create <tt>C<sub>n</sub></tt>
  - Repeat the above process for each block (prepend an empty block to the new ciphertext block, calculate it, etc)

To put that in English: each block of ciphertext decrypts to an unknown value, then is XOR'd with the previous block of ciphertext. By carefully selecting the *previous* block, we can control what the next block decrypts to. Even if the next block decrypts to a bunch of garbage, it's still being XOR'd to a value that we control, and can therefore be set to anything we want.

### A quick note about the IV

In CBC mode, the IV - initialization vector - sort of acts as a ciphertext block that comes before the first block in terms of XOR'ing. Sort of an elusive "zeroeth" block, it's not actually decrypted; instead, it's XOR'd against the first real block after decrypting to create <tt>P<sub>1</sub></tt>. Because it's used to set <tt>P<sub>1</sub></tt>, it's calculated *exactly* the same as every other block we're going to talk about, except the final block, <tt>C<sub>N</sub></tt>, which is random.

If we don't have control of the IV - which is pretty common - then we can't control the first block of plaintext, <tt>P<sub>1</sub></tt>, in any meaningful way. We can still calculate the full plaintext we want, it's just going to have a block of garbage before it.

Throughout this post, just think of the IV another block of ciphertext; we'll even call it <tt>C<sub>0</sub></tt> from time to time. <tt>C<sub>0</sub></tt> is used to generate <tt>P<sub>1</sub></tt> (and there's no such thing as <tt>P<sub>0</sub></tt>).

### Generate a fake block

The "last" block of ciphertext, <tt>C<sub>N</sub></tt>, is generated first. Normally you'd just pick a random blocksize-length string and move on. But you can also have some fun with it! The rest of this section is just a little playing, and is totally tangential to the point; feel free to skip to the next section if you just want the meat.

So yeah, interesting tangential fact: the final ciphertext block, <tt>C<sub>N</sub></tt> can be *any* arbitrary string of <tt>blocksize</tt> bytes. All 'A's? No problem. A message to somebody? No problem. By default, Poracle simply randomizes it. I assume other tools do as well. But it's interesting that we can generate arbitrary plaintext!

Let's have some fun:

- Algorithm = <tt>"AES-256-CBC"</tt>
- Key = <tt>c086e08ad8ee0ebe7c2320099cfec9eea9a346a108570a4f6494cfe7c2a30ee1</tt>
- IV = <tt>78228d4760a3675aa08d47694f88f639</tt>
- Ciphertext = <tt>"IS THIS SECRET??"</tt>

The ciphertext is ASCII!? Is that even possible?? It is! Let's try to decrypt it:

```

  2.3.0 :001 > require 'openssl'
   => true

  2.3.0 :002 > c = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
   => #<OpenSSL::Cipher::Cipher:0x00000001de2578>

  2.3.0 :003 > c.decrypt
   => #<OpenSSL::Cipher::Cipher:0x00000001de2578>

  2.3.0 :004 > c.key = ['c086e08ad8ee0ebe7c2320099cfec9eea9a346a108570a4f6494cfe7c2a30ee1'].pack('H*')
   => "\xC0\x86\xE0\x8A\xD8\xEE\x0E\xBE|# \t\x9C\xFE\xC9\xEE\xA9\xA3F\xA1\bW\nOd\x94\xCF\xE7\xC2\xA3\x0E\xE1" 

  2.3.0 :005 > c.iv = ['78228d4760a3675aa08d47694f88f639'].pack('H*')
   => "x\"\x8DG`\xA3gZ\xA0\x8DGiO\x88\xF69" 

  2.3.0 :006 > c.update("IS THIS SECRET??") + c.final()
   => "NO, NOT SECRET!" 

```

It's ciphertext that looks like ASCII ("IS THIS SECRET??") that decrypts to more ASCII ("NO, NOT SECRET!"). How's that even work!?

We'll see shortly why this works, but fundamentally: we can arbitrarily choose the last block (I chose ASCII) for padding-oracle-based encryption. The previous blocks - in this case, the IV - is what we actually have to determine. Change that IV, and this won't work anymore.

### Calculate a block of ciphertext

Okay, we've created the last block of ciphertext, <tt>C<sub>N</sub></tt>. Now we want to create the second-last block, <tt>C<sub>N-1</sub></tt>. This is where it starts to get complicated. If you can follow this sub-section, everything else is easy! :)

Let's start by making a new ciphertext string, <tt>C'</tt>. Just like in decrypting, <tt>C'</tt> is a custom-generated ciphertext string that we're going to send to the oracle. It's made up of two blocks:

- <tt>C'<sub>1</sub></tt> is the block we're trying to determine; we set it to all zeroes for now (though the value doesn't actually matter)
- <tt>C'<sub>2</sub></tt> is the previously generated block of ciphertext (on the first round, it's <tt>C<sub>N</sub></tt>, the block we randomly generated; on ensuing rounds, it's <tt>C<sub>n+1</sub></tt> - the block after the one we're trying to crack).

I know that's confusing, but let's push forward and look at how we generate a <tt>C'</tt> block and it should all become clear.

Imagine the string:

```

  C' = 00000000000000000000000000000000 || C<sub>N</sub>
                ^^^ C<sub>N-1</sub> ^^^               
```

Keep in mind that <tt>C<sub>N</sub></tt> is randomly chosen. We don't know - and can't know - what <tt>C'<sub>2</sub></tt> decrypts to, but we'll call it <tt>P'<sub>2</sub></tt>. We do know something, though - after it's decrypted to *something*, it's XOR'd with the previous block of ciphertext (<tt>C'<sub>1</sub></tt>), which we control. Then the padding's checked. Whether or not the padding is correct or incorrect depends wholly on <tt>C'<sub>1</sub></tt>! That means by carefully adjusting <tt>C'<sub>1</sub></tt>, we can find a string that generates correct padding for <tt>P'<sub>2</sub></tt>.

Because the *only things* that influence <tt>P'<sub>2</sub></tt> are the encryption function, E(), and the previous ciphertext block, <tt>C'<sub>1</sub></tt>, we can set it to anything we want without ever seeing it! And once we find a value for <tt>C'</tt> that decrypts to the <tt>P'<sub>2</sub></tt> we want, we have everything we need to create a <tt>C<sub>N-1</sub></tt> that generates the <tt>P<sub>N</sub></tt> we want!

So we create a string like this:

```

  00000000000000000000000000000000 41414141414141414141414141414141
        ^^^ C'<sub>1</sub> / C<sub>N-1</sub> ^^^                  ^^^ C'<sub>2</sub> / C<sub>N</sub> ^^^
```

The block of zeroes is the block we're trying to figure out (it's going to be <tt>C<sub>N-1</sub></tt>), and the block of 41's is the block of arbitrary/random data (<tt>C<sub>N</sub></tt>).

We send that to the server, for example, like this (this is on Poracle's [RemoteTestServer.rb](https://github.com/iagox86/poracle/blob/master/RemoteTestServer.rb) app, with a random key and blank IV - you should be able to just download and run the server, though you might have to run <tt>gem install sinatra</tt>):

- http://localhost:20222/decrypt/0000000000000000000000000000000041414141414141414141414141414141

We're almost certainly going to get a padding error returned, just like in decryption (there's a 1/256 chance it's going to be right). So we change the last byte of block <tt>C'<sub>1</sub></tt> until we stop getting padding errors:

- http://localhost:20222/decrypt/0000000000000000000000000000000141414141414141414141414141414141
- http://localhost:20222/decrypt/0000000000000000000000000000000241414141414141414141414141414141
- http://localhost:20222/decrypt/0000000000000000000000000000000341414141414141414141414141414141
- http://localhost:20222/decrypt/0000000000000000000000000000000441414141414141414141414141414141
- ...

And eventually, you'll get a success:

```

$ <strong><span class="Statement">for</span> i <span class="Statement">in</span> <span class="Special">`seq </span><span class="Number">0</span><span class="Special"> </span><span class="Number">255</span><span class="Special">`</span>; <span class="Conditional">do</span>
<span class="Identifier">URL</span>=<span class="Special">`printf </span><span class="Operator">"</span><span class="String">http://localhost:20222/decrypt/000000000000000000000000000000%02x41414141414141414141414141414141</span><span class="Operator">"</span><span class="Special"> </span><span class="PreProc">$i</span><span class="Special">`</span>
<span class="Statement">echo</span><span class="String"> </span><span class="PreProc">$URL</span>
curl <span class="Operator">"</span><span class="PreProc">$URL</span><span class="Operator">"</span>
<span class="Statement">echo</span><span class="String"> </span><span class="Operator">''</span>
<span class="Conditional">done</span></strong>

http://localhost:20222/decrypt/0000000000000000000000000000000041414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000000141414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000000241414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000000341414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000000441414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000000541414141414141414141414141414141
Fail!
<strong>http://localhost:20222/decrypt/0000000000000000000000000000000641414141414141414141414141414141
Success!</strong>
http://localhost:20222/decrypt/0000000000000000000000000000000741414141414141414141414141414141
Fail!
...
```

We actually found the valid encoding really early this time! When <tt>C'<sub>1</sub></tt> ends with 06, the last byte of <tt>P'<sub>2</sub></tt>, decrypts to 01. That means if we want the last byte of the generated plaintext (<tt>P'<sub>2</sub></tt>) to be 02, we simply have to XOR the value by 01 (to set it to 00), then by 02 (to set it to 02). 06 ⊕ 01 ⊕ 02 = 05. Therefore, if we set the last byte of <tt>C'<sub>1</sub></tt> to 05, we know that the last byte of <tt>P'<sub>2</sub></tt> will be 02, and we can start bruteforcing the second-last byte:

```

$ <strong><span class="Statement">for</span> i <span class="Statement">in</span> <span class="Special">`seq </span><span class="Number">0</span><span class="Special"> </span><span class="Number">255</span><span class="Special">`</span>; <span class="Conditional">do</span>
<span class="Identifier">URL</span>=<span class="Special">`printf </span><span class="Operator">"</span><span class="String">http://localhost:20222/decrypt/0000000000000000000000000000%02x0541414141414141414141414141414141</span><span class="Operator">"</span><span class="Special"> </span><span class="PreProc">$i</span><span class="Special">`</span>
<span class="Statement">echo</span><span class="String"> </span><span class="PreProc">$URL</span>
curl <span class="Operator">"</span><span class="PreProc">$URL</span><span class="Operator">"</span>
<span class="Statement">echo</span><span class="String"> </span><span class="Operator">''</span>
<span class="Conditional">done</span></strong>

http://localhost:20222/decrypt/0000000000000000000000000000000541414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000010541414141414141414141414141414141
Fail!
...
http://localhost:20222/decrypt/0000000000000000000000000000350541414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/0000000000000000000000000000360541414141414141414141414141414141
Success!
...
```

So now we know that when <tt>C'<sub>N-1</sub></tt> ends with 3605, <tt>P'<sub>2</sub></tt> ends with 0202. We'll go one more step: if we change <tt>C'<sub>1</sub></tt> such that <tt>P'<sub>2</sub></tt> ends with 0303, we can start working on the third-last character in <tt>C'<sub>1</sub></tt>. 36 ⊕ 02 ⊕ 03 = 37, and 05 ⊕ 02 ⊕ 03 = 04 (we XOR by 2 to set the values to 0, then by 3 to set it to 3):

```

$ <strong><span class="Statement">for</span> i <span class="Statement">in</span> <span class="Special">`seq </span><span class="Number">0</span><span class="Special"> </span><span class="Number">255</span><span class="Special">`</span>; <span class="Conditional">do</span>
<span class="Identifier">URL</span>=<span class="Special">`printf </span><span class="Operator">"</span><span class="String">http://localhost:20222/decrypt/00000000000000000000000000%02x370441414141414141414141414141414141</span><span class="Operator">"</span><span class="Special"> </span><span class="PreProc">$i</span><span class="Special">`</span>
<span class="Statement">echo</span><span class="String"> </span><span class="PreProc">$URL</span>
curl <span class="Operator">"</span><span class="PreProc">$URL</span><span class="Operator">"</span>
<span class="Statement">echo</span><span class="String"> </span><span class="Operator">''</span>
<span class="Conditional">done</span></strong>

...
http://localhost:20222/decrypt/000000000000000000000000006b370441414141414141414141414141414141
Fail!
http://localhost:20222/decrypt/000000000000000000000000006c370441414141414141414141414141414141
Success!
...
```

So now, when <tt>C'<sub>1</sub></tt> ends with 6c3704, <tt>P'<sub>2</sub></tt> ends with 030303.

We can go on and on, but I automated it using Poracle and determined that the final value for <tt>C'<sub>1</sub></tt> that works is <tt>12435417b15e3d7552810313da7f2417</tt>

```

$ curl <span class="Operator">'</span><span class="String">http://localhost:20222/decrypt/12435417b15e3d7552810313da7f241741414141414141414141414141414141</span><span class="Operator">'</span>
Success!
```

That means that when <tt>C'<sub>1</sub></tt> is <tt>12435417b15e3d7552810313da7f2417</tt>, <tt>P'<sub>2</sub></tt> is <tt>10101010101010101010101010101010</tt> (a full block of padding).

We can once again use XOR to remove 101010... from <tt>C'<sub>1</sub></tt>, giving us: <tt>02534407a14e2d6542911303ca6f3407</tt>. That means that when <tt>C'<sub>1</sub></tt> equals <tt>02534407a14e2d6542911303ca6f3407</tt>), <tt>P'<sub>2</sub></tt> is <tt>00000000000000000000000000000000</tt>. Now we can XOR it with whatever we want to set it to an arbitrary value!

Let's say we want the last block to decrypt to <tt>0102030405060708090a0b0c0d0e0f</tt> (15 bytes). We:

- Add one byte of padding: <tt>0102030405060708090a0b0c0d0e0f**01**</tt>
- XOR <tt>C'<sub>1</sub></tt> (<tt>02534407a14e2d6542911303ca6f3407</tt>) with <tt>0102030405060708090a0b0c0d0e0f01</tt> => <tt>03514703a4482a6d4b9b180fc7613b06</tt>
- Append the final block, <tt>C<sub>N</sub></tt>, to create <tt>C</tt>: <tt>03514703a4482a6d4b9b180fc7613b0641414141414141414141414141414141</tt>
- Send it to the server to be decrypted...

```

$ curl <span class="Operator">'</span><span class="String">http://localhost:20222/decrypt/03514703a4482a6d4b9b180fc7613b0641414141414141414141414141414141</span><span class="Operator">'</span>
Success
```

And, if you actually calculate it with the key I'm using, the final plaintext string <tt>P'</tt> is <tt>c49f1fdcd1cd93daf4e79a18637c98d80102030405060708090a0b0c0d0e0f</tt>.

(The block of garbage is a result of being unable to control the IV)

### Calculating the next block of ciphertext

So now, where have we gotten ourselves?

We have values for <tt>C<sub>N-1</sub></tt> (calculated) and <tt>C<sub>N</sub></tt> (arbitrarily chosen). How do we calculate <tt>C<sub>N-2</sub></tt>?

This is actually pretty easy. We generate ourselves a two-block string again, <tt>C'</tt>. Once again, <tt>C'<sub>1</sub></tt> is what we're trying to bruteforce, and is normally set to all 00's. But this time, <tt>C'<sub>2</sub></tt> is <tt>C<sub>N-1</sub></tt> - the ciphertext we just generated.

Let's take a new <tt>C'</tt> of:

```

000000000000000000000000000000000 3514703a4482a6d4b9b180fc7613b06
        ^^^ C'<sub>1</sub> / C<sub>N-2</sub> ^^^                 ^^^ C'<sub>2</sub> / C<sub>N-1</sub> ^^^
```

We can once again determine the last byte of <tt>C'<sub>1</sub></tt> that will cause the last character of <tt>P'<sub>2</sub></tt> to be valid padding (01):

```

$ <strong><span class="Statement">for</span> i <span class="Statement">in</span> <span class="Special">`seq </span><span class="Number">0</span><span class="Special"> </span><span class="Number">255</span><span class="Special">`</span>; <span class="Conditional">do</span>
<span class="Identifier">URL</span>=<span class="Special">`printf </span><span class="Operator">"</span><span class="String">http://localhost:20222/decrypt/000000000000000000000000000000%02x3514703a4482a6d4b9b180fc7613b06</span><span class="Operator">"</span><span class="Special"> </span><span class="PreProc">$i</span><span class="Special">`</span>
<span class="Statement">echo</span><span class="String"> </span><span class="PreProc">$URL</span>
curl <span class="Operator">"</span><span class="PreProc">$URL</span><span class="Operator">"</span>
<span class="Statement">echo</span><span class="String"> </span><span class="Operator">''</span>
<span class="Conditional">done</span></strong>
...
http://localhost:20222/decrypt/000000000000000000000000000000313514703a4482a6d4b9b180fc7613b06
Fail!
http://localhost:20222/decrypt/000000000000000000000000000000323514703a4482a6d4b9b180fc7613b06
Fail!
http://localhost:20222/decrypt/000000000000000000000000000000333514703a4482a6d4b9b180fc7613b06
Success!
...
```

...and so on, just like before. When this block is done, move on to the previous, and previous, and so on, till you get to the first block of <tt>P</tt>. By then, you've determined all the values for <tt>C<sub>1</sub></tt> up to <tt>C<sub>N-1</sub></tt>, and you have your specially generated <tt>C<sub>N</sub></tt> with whatever value you want. Thus, you have the whole string!

So to put it in another way, we calculate:

- <tt>C<sub>N</sub></tt> = random / arbitrary
- <tt>C<sub>N-1</sub></tt> = calculated from <tt>C<sub>N</sub></tt> combined with <tt>P<sub>N</sub></tt>
- <tt>C<sub>N-2</sub></tt> = calculated from <tt>C<sub>N-1</sub></tt> combined with <tt>P<sub>N-1</sub></tt>
- <tt>C<sub>N-3</sub></tt> = calculated from <tt>C<sub>N-2</sub></tt> combined with <tt>P<sub>N-2</sub></tt>
- ...
- <tt>C<sub>1</sub></tt> = calculated from <tt>C<sub>2</sub></tt> combined with <tt>P<sub>2</sub></tt>
- <tt>C<sub>0</sub></tt> (the IV) = calculated from <tt>C<sub>1</sub></tt> combined with <tt>P<sub>1</sub></tt>

So as you can see, each block is based on the next ciphertext block and the next plaintext block.

## Conclusion

Well, that's about all I can say about using a padding oracle vulnerability to encrypt arbitrary data.

If anything is unclear, please let me know! And, you can see a working implementation in [Poracle.rb](https://github.com/iagox86/poracle/blob/master/Poracle.rb).