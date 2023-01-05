---
id: 1459
title: A padding oracle example
date: '2013-01-07T10:40:52-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=1459
permalink: "/2013/a-padding-oracle-example"
categories:
- crypto
- hacking
comments_id: '109638361510785310'

---

Early last week, I <a href='http://www.skullsecurity.org/blog/2013/padding-oracle-attacks-in-depth'>posted a blog</a> about padding oracle attacks. I explained them in detail, as simply as I could (without making diagrams, I suck at diagrams). I asked on Reddit about how I could make it easier to understand, and <a href='http://www.reddit.com/r/crypto/comments/15u0to/an_indepth_look_at_padding_oracle_attacks_for/c7q3636'>JoseJimeniz suggested working through an example</a>. I thought that was a neat idea, and working through a padding oracle attack by hand seems like a fun exercise!

(Having done it already and writing this introduction afterwards, I can assure you that it isn't as fun as I thought it'd be :) )

I'm going to assume that you've read <a href='http://www.skullsecurity.org/blog/2013/padding-oracle-attacks-in-depth'>my previous blog</a> all the way through, and jump right into things!
<!--more-->
<h2>The setup</h2>
As an example, let's assume we're using DES, since it has nice short block sizes. We'll use the following variables:
<pre>
  P   = Plaintext (with the padding added)
  P<sub>n</sub>  = The n<sup>th</sup> block of plaintext
  N   = The number of blocks of either plaintext or ciphertext (the number is the same)
  IV  = Initialization vector
  E() = Encrypt, using a given key (we don't notate the key for reasons of simplicity)
  D() = Decrypt, using the same key as E()
  C   = Ciphertext
  C<sub>n</sub>  = The n<sup>th</sup> block of ciphertext
</pre>

We use the following values for the variables:
<pre>
  P   = "Hello World\x05\x05\x05\x05\x05"
  P<sub>1</sub>  = "Hello Wo"
  P<sub>2</sub>  = "rld\x05\x05\x05\x05\x05"
  N   = 2
  IV  = "\x00\x00\x00\x00\x00\x00\x00\x00"
  E() = des-cbc with the key "mydeskey"
  D() = des-cbc with the key "mydeskey"
  C   = "\x83\xe1\x0d\x51\xe6\xd1\x22\xca\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b"
  C<sub>1</sub>  = "\x83\xe1\x0d\x51\xe6\xd1\x22\xca"
  C<sub>2</sub>  = "\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b"
</pre>

For what it's worth, I generated the ciphertext like this:
<pre>
  irb(main):<span class="Constant">001</span>:<span class="Constant">0</span>&gt;; <span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">openssl</span><span class="Special">'</span>
  irb(main):<span class="Constant">002</span>:<span class="Constant">0</span>&gt;; c = <span class="Type">OpenSSL</span>::<span class="Type">Cipher</span>::<span class="Type">Cipher</span>.new(<span class="Special">'</span><span class="Constant">des-cbc</span><span class="Special">'</span>)
  irb(main):<span class="Constant">003</span>:<span class="Constant">0</span>&gt;; c.encrypt
  irb(main):<span class="Constant">004</span>:<span class="Constant">0</span>&gt;; c.key = <span class="Special">&quot;</span><span class="Constant">mydeskey</span><span class="Special">&quot;</span>
  irb(main):<span class="Constant">005</span>:<span class="Constant">0</span>&gt;; c.iv = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00\x00\x00\x00</span><span class="Special">&quot;</span>
  irb(main):<span class="Constant">006</span>:<span class="Constant">0</span>&gt;; data = c.update(<span class="Special">&quot;</span><span class="Constant">Hello World</span><span class="Special">&quot;</span>) + c.final
  irb(main):<span class="Constant">007</span>:<span class="Constant">0</span>&gt;; data.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)
  =&gt; [<span class="Special">&quot;</span><span class="Constant">83e10d51e6d122ca3faf089c7a924a7b</span><span class="Special">&quot;</span>]
</pre>

Now that we have our variables, let's get started!

<h3>Creating an oracle</h3>
As I explained in my previous blog, this attack relies on having a decryption oracle that'll return a true/false value depending on whether or not the decryption operation succeeded. Here's a workable oracle that, albeit unrealistic, will be a perfect demonstration:
<pre>
  irb(main):<span class="Constant">012</span>:<span class="Constant">0</span>&gt; <span class="PreProc">def</span> <span class="Identifier">try_decrypt</span>(data)
  irb(main):<span class="Constant">013</span>:<span class="Constant">1</span>&gt;   <span class="Statement">begin</span>
  irb(main):<span class="Constant">014</span>:<span class="Constant">2</span>&gt;     c = <span class="Type">OpenSSL</span>::<span class="Type">Cipher</span>::<span class="Type">Cipher</span>.new(<span class="Special">'</span><span class="Constant">des-cbc</span><span class="Special">'</span>)
  irb(main):<span class="Constant">015</span>:<span class="Constant">2</span>&gt;     c.decrypt
  irb(main):<span class="Constant">016</span>:<span class="Constant">2</span>&gt;     c.key = <span class="Special">&quot;</span><span class="Constant">mydeskey</span><span class="Special">&quot;</span>
  irb(main):<span class="Constant">017</span>:<span class="Constant">2</span>&gt;     c.iv = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00\x00\x00\x00</span><span class="Special">&quot;</span>
  irb(main):018:<span class="Constant">2</span>&gt;     c.update(data)
  irb(main):019:<span class="Constant">2</span>&gt;     c.final
  irb(main):<span class="Constant">020</span>:<span class="Constant">2</span>&gt;     <span class="Statement">return</span> <span class="Constant">true</span>
  irb(main):<span class="Constant">021</span>:<span class="Constant">2</span>&gt;   <span class="Statement">rescue</span> <span class="Type">OpenSSL</span>::<span class="Type">Cipher</span>::<span class="Type">CipherError</span>
  irb(main):<span class="Constant">022</span>:<span class="Constant">2</span>&gt;     <span class="Statement">return</span> <span class="Constant">false</span>
  irb(main):<span class="Constant">023</span>:<span class="Constant">2</span>&gt;   <span class="Statement">end</span>
  irb(main):<span class="Constant">024</span>:<span class="Constant">1</span>&gt; <span class="PreProc">end</span>
</pre>

As you can see, it returns true if we send C:
<pre>
  irb(main):<span class="Constant">025</span>:<span class="Constant">0</span>&gt; try_decrypt(<span class="Special">&quot;</span><span class="Special">\x83\xe1\x0d\x51\xe6\xd1\x22\xca\x3f\xaf\x08\x9c\x7a
  \x92\x4a\x7b</span><span class="Special">&quot;</span>)
  =&gt; <span class="Constant">true</span>
</pre>

And false if we flip the last bit of C (effectively changing the padding):
<pre>
  irb(main):<span class="Constant">026</span>:<span class="Constant">0</span>&gt; try_decrypt(<span class="Special">&quot;</span><span class="Special">\x83\xe1\x0d\x51\xe6\xd1\x22\xca\x3f\xaf\x08\x9c\x7a
   \x92\x4a\x7a</span><span class="Special">&quot;</span>)
  =&gt; <span class="Constant">false</span>
</pre>

Now we have our data, our encrypted data, and a simple oracle. Let's get to work!

<h2>Breaking the last character</h2>
Now, let's start with breaking the second block of ciphertext, C<sub>2</sub>. The first thing we do is create our own block of ciphertext &mdash; C&prime; &mdash; which has no particular plaintext value:
<pre>
  C&prime; = "\x00\x00\x00\x00\x00\x00\x00\x00"
</pre>

In reality, we can use any value, but all zeroes makes it easier to demonstrate. We concatenate C<sub>2</sub> to that block, giving us:
<pre>
  C&prime; || C<sub>2</sub> = "\x00\x00\x00\x00\x00\x00\x00\x00\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b"
</pre>

We now have a two-block string of ciphertext. <em>When you send that string to the oracle, the oracle will, following the <a href='https://en.wikipedia.org/wiki/File:Cbc_decryption.png'>cipher-block chaining</a> standard: a) decrypt the second block, b) XOR the decrypted block with the ciphertext block that we control, and c) check the padding on the resulting block and fail if it's wrong</em>. Read that sentence a couple times. If you need to know one thing to understand padding oracles, it's that.

Let me repeat and rephrase, to make sure it's clear: We send two blocks of ciphertext, one we control (C&prime;) and one we want to decrypt (C<sub>2</sub>). The one we want to decrypt (C<sub>2</sub>) is decrypted (secretly) by the server, XORed with the block we control (C&prime;), then the resulting plaintext's padding is validated. That means that <em>we know whether or not <strong>our ciphertext</strong> XORed with <strong>their plaintext</strong> has proper padding</em>. That gives us enough information to decrypt the entire string, one character after the other!

This will, of course, work for blocks other than C<sub>2</sub> (which I notate as C<sub>n</sub> in the previous blog). I'm using C<sub>2</sub> because I'm working through a concrete example.

So, we generate that string (C&prime; || C<sub>2</sub>). We send that to our decryption oracle, and should return a false result (unless we hit the 1/256 chance of getting the padding right at random, which we don't):
<pre>
  irb(main):<span class="Constant">027</span>:<span class="Constant">0</span>&gt; try_decrypt(<span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00\x00\x00\x00\x3f\xaf\x08\x9c
   \x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>)
  =&gt; <span class="Constant">false</span>
</pre>

Now, keep in mind that this isn't decrypting to anything remotely useful! It's decrypting to a garbage string, and all that matters to us is whether or not the padding is correct, because that, thanks to a beautiful formula, tells us something about the plaintext.

Let's now focus on just the last character of C&prime;. Before we get to the math, let's find the value for the last byte of C&prime; &mdash; C&prime;[8] &mdash; that returns valid padding, using a simple ruby script:
<pre>
  irb(main):<span class="Constant">067</span>:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):068:<span class="Constant">1</span>*   cprime = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00\x00\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">&quot;</span> + 
   <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):069:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>try_decrypt(cprime)<span class="Special">}</span><span class="Special">&quot;</span>)
  irb(main):<span class="Constant">070</span>:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">0</span>: 00000000000000003<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">1</span>: 00000000000000013<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">2</span>: 00000000000000023<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">3</span>: 00000000000000033<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">4</span>: 00000000000000043<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">5</span>: 00000000000000053<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">6</span>: 00000000000000063<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">7</span>: 00000000000000073<span class="Constant">faf089c7a924a7b</span>: <span class="Constant">false</span>
  ...
  <span class="Constant">203</span>: 00000000000000<span class="Constant">cb3faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">204</span>: 00000000000000<span class="Constant">cc3faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">205</span>: 00000000000000<span class="Constant">cd3faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">206</span>: 00000000000000<span class="Constant">ce3faf089c7a924a7b</span>: <span class="Constant">true</span>   &lt;--
  <span class="Constant">207</span>: 00000000000000<span class="Constant">cf3faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">208</span>: 00000000000000<span class="Constant">d03faf089c7a924a7b</span>: <span class="Constant">false</span>
  ...
</pre>

So what did we learn here? That when C&prime;[8] is 206 &mdash; 0xce &mdash; it decrypts to something that ends with the byte "\x01". We can see what it's decrypting to by using some more ruby code (note that this isn't possible in a normal attack, since we don't have access to the key, this is simply used as a demonstration):
<pre>
  irb(main):<span class="Constant">075</span>:<span class="Constant">0</span>&gt; puts (c.update(<span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00\x00\x00\xce\x3f\xaf\x08\x9c
  \x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>) + c.final).unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)
  62047db89b8144b8f18d6954e3d427
</pre>

Note that this string is 15 characters long, and doesn't end with \x01. Why? Because the "\x01" on the end was considered to be padding by the library and removed. OpenSSL doesn't return padding to the programmer &mdash; why would it?

We refer to this garbage string as P&prime;, and it's not useful to us in any way, except for the padding byte that the server validates. In fact, since the server is decrypting the string secretly, we never even have access to P&prime;.

(For what it's worth, P&prime; is actually equal to the original block of plaintext (P<sub>2</sub>) XORed with the previous block of ciphertext (C<sub>1</sub>) and XORed with our ciphertext block (C&prime;). If you work through the math, you'll discover why).

<h3>The math</h3>
Recall from my previous blog that the second block of our new plaintext value &mdash; P&prime;<sub>2</sub> &mdash; is calculated like this:
<pre>
  P&prime;<sub>2</sub> = D(C<sub>2</sub>) ⊕ C&prime;
</pre>

That is, the second block of P&prime; &mdash; our newly and secretly decrypted string &mdash; is equal to the second block of the ciphertext decrypted, then XORed with C&prime;.

But C<sub>2</sub> was originally calculated like this:
<pre>
  C<sub>2</sub> = E(P<sub>2</sub> ⊕ C<sub>1</sub>)
</pre>

In other words, the second block of ciphertext is the second block of plaintext XORed with the first block of ciphertext, then encrypted.

We can substitute C<sub>2</sub> in the first formula with C<sub>2</sub> in the second formula, which results in this:
<pre>
  P&prime;<sub>2</sub> = D(E(P<sub>2</sub> ⊕ C<sub>1</sub>)) ⊕ C&prime;
</pre>

So, the server calculates P<sub>2</sub> XORed with C<sub>1</sub>, then encrypts it, decrypts it, and XORs it with C&prime;. But the encryption and decryption cancel out (D(E(x)) = x, by definition), so we can reduce the formula to this:
<pre>
  P&prime;<sub>2</sub> = P<sub>2</sub> ⊕ C<sub>1</sub> ⊕ C&prime;
</pre>

So P&prime;<sub>2</sub> &mdash; the value whose padding we're trying to discover &mdash; is the second block of plaintext XORed with the first block of ciphertext, XORed with our ciphertext (C&prime;).

What do we know about P&prime;<sub>2</sub>? Well, once we discover the proper padding value, the server knows that the value of P&prime;<sub>2</sub> is "\xf1\x8d\x69\x54\xe3\xd4\x27\x01". Unfortunately, all we know is that the padding is correct, and that P&prime;<sub>2</sub>[8] = "\x01". But, since we know the value of P&prime;<sub>2</sub>[8], we know enough to calculate P<sub>2</sub>[8]! Here's the calculation:
<pre>
  P&prime;<sub>2</sub>[8] = P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8] ⊕ C&prime;[8]
  (re-arrange using XOR's commutative property):
  P<sub>2</sub>[8] = P&prime;<sub>2</sub>[8] ⊕ C<sub>1</sub>[8] ⊕ C&prime;[8]
  P<sub>2</sub>[8] = 0x01 ⊕ 0xca ⊕ 0xce
  P<sub>2</sub>[8] = 5
</pre>

Holy crap! 5 is the last byte of padding! We just broke the last byte of plaintext!

The value we know for P<sub>2</sub> is "???????\x05"

<h2>Second-last byte...</h2>
Now, to calculate the second-last byte, we need a new P&prime;. We want the last byte of P&prime; to decrypt to 0x02 (so that our padding will wind up as "\x02\x02" once we bruteforce the second-last byte), so we use this formula from earlier:
<pre>
  P&prime;<sub>2</sub>[k] = P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k] ⊕ C&prime;[k]
</pre>

And re-arrange it:
<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]
</pre>

Then plug in the values we determined for P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8], and the value we desire for P&prime;<sub>2</sub>[8]:
<pre>
  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x02 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xcd
</pre>

Now we have the last character of C&prime;: 0xcd. We use the same loop from earlier, except guessing C&prime;[7] instead of C&prime;[8]:
<pre>
  irb(main):<span class="Constant">076</span>:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):<span class="Constant">077</span>:<span class="Constant">1</span>&gt;   cprime = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\xcd</span><span class="Special">&quot;</span> + 
  <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):078:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>try_decrypt(cprime)<span class="Special">}</span><span class="Special">&quot;</span>)
  irb(main):079:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  ...
  <span class="Constant">36</span>: 00000000000024<span class="Constant">cd3faf089c7a924a7b</span>: <span class="Constant">false</span>
  <span class="Constant">37</span>: 00000000000025<span class="Constant">cd3faf089c7a924a7b</span>: <span class="Constant">true</span>
  <span class="Constant">38</span>: 00000000000026<span class="Constant">cd3faf089c7a924a7b</span>: <span class="Constant">false</span>
  ...
</pre>

All right, now we know that when C&prime;[7] = 0x25, P&prime;<sub>2</sub>[7] = 0x02! Plug that back into our formula:
<pre>
  P<sub>2</sub>[7] = P&prime;<sub>2</sub>[7] ⊕ C<sub>1</sub>[7] ⊕ C&prime;[7]
  P<sub>2</sub>[7] = 0x02 ⊕ 0x22 ⊕ 0x25
  P<sub>2</sub>[7] = 5
</pre>

Boom! Now we know that the second-last character of P<sub>2</sub> is 5.

The value we know for P<sub>2</sub> is "??????\x05\x05"

<h2>Third-last character</h2>
Let's keep going! First, we calculate C&prime;[7] and C&prime;[8] such that P&prime; will end with "\x03\x03":

<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]

  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x03 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xcc

  C&prime;[7] = P&prime;<sub>2</sub>[7] ⊕ P<sub>2</sub>[7] ⊕ C<sub>1</sub>[7]
  C&prime;[7] = 0x03 ⊕ 0x05 ⊕ 0x22
  C&prime;[7] = 0x24
</pre>

And run our program (modified a bit to just show us what's interesting):
<pre>
  irb(main):088:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):089:<span class="Constant">1</span>&gt;   cprime = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\x24\xcc</span><span class="Special">&quot;</span> +
  <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):090:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Special">&quot;</span>) <span class="Statement">if</span>(try_decrypt(cprime))
  irb(main):091:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">215</span>: 0000000000d724cc3faf089c7a924a7b
</pre>

And back to our formula:
<pre>
  P<sub>2</sub>[6] = P&prime;<sub>2</sub>[6] ⊕ C<sub>1</sub>[6] ⊕ C&prime;[6]
  P<sub>2</sub>[6] = 0x03 ⊕ 0xd1 ⊕ 0xd7
  P<sub>2</sub>[6] = 5
</pre>

The value we know for P<sub>2</sub> is "?????\x05\x05\x05"

<h2>Fourth-last character</h2>
Calculate the C&prime; values for \x04\x04\x04:
<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]

  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x04 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xcb

  C&prime;[7] = P&prime;<sub>2</sub>[7] ⊕ P<sub>2</sub>[7] ⊕ C<sub>1</sub>[7]
  C&prime;[7] = 0x04 ⊕ 0x05 ⊕ 0x22
  C&prime;[7] = 0x23

  C&prime;[6] = P&prime;<sub>2</sub>[6] ⊕ P<sub>2</sub>[6] ⊕ C<sub>1</sub>[6]
  C&prime;[6] = 0x04 ⊕ 0x05 ⊕ 0xd1
  C&prime;[6] = 0xd0
</pre>

And our program:
<pre>
  irb(main):092:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):093:<span class="Constant">1</span>&gt;   cprime = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\xd0\x23\xcb</span><span class="Special">&quot;</span> + 
  <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):094:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Special">&quot;</span>) <span class="Statement">if</span>(try_decrypt(cprime))
  irb(main):095:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">231</span>: 00000000e7d023cb3faf089c7a924a7b
</pre>

And breaking it:
<pre>
  P<sub>2</sub>[5] = P&prime;<sub>2</sub>[5] ⊕ C<sub>1</sub>[5] ⊕ C&prime;[5]
  P<sub>2</sub>[5] = 0x04 ⊕ 0xe6 ⊕ 0xe7
  P<sub>2</sub>[5] = 5
</pre>

The value we know for P<sub>2</sub> is "????\x05\x05\x05\x05"

<h2>Fifth-last character</h2>
Time for the last padding character! Calculate C&prime; values for \x05\x05\x05\x05:
<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]

  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x05 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xca

  C&prime;[7] = P&prime;<sub>2</sub>[7] ⊕ P<sub>2</sub>[7] ⊕ C<sub>1</sub>[7]
  C&prime;[7] = 0x05 ⊕ 0x05 ⊕ 0x22
  C&prime;[7] = 0x22

  C&prime;[6] = P&prime;<sub>2</sub>[6] ⊕ P<sub>2</sub>[6] ⊕ C<sub>1</sub>[6]
  C&prime;[6] = 0x05 ⊕ 0x05 ⊕ 0xd1
  C&prime;[6] = 0xd1

  C&prime;[5] = P&prime;<sub>2</sub>[5] ⊕ P<sub>2</sub>[5] ⊕ C<sub>1</sub>[5]
  C&prime;[5] = 0x05 ⊕ 0x05 ⊕ 0xe6
  C&prime;[5] = 0xe6
</pre>

Run the program:
<pre>
  irb(main):096:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):097:<span class="Constant">1</span>*   cprime = <span class="Special">&quot;</span><span class="Special">\x00\x00\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\xe6\xd1\x22\xca</span><span class="Special">&quot;</span> + 
 <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):098:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Special">&quot;</span>) <span class="Statement">if</span>(try_decrypt(cprime))
  irb(main):099:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">81</span>: 00000051e6d122ca3faf089c7a924a7b
</pre>

And break the character:
<pre>
  P<sub>2</sub>[4] = P&prime;<sub>2</sub>[4] ⊕ C<sub>1</sub>[4] ⊕ C&prime;[4]
  P<sub>2</sub>[4] = 0x05 ⊕ 0x51 ⊕ 0x51
  P<sub>2</sub>[4] = 5
</pre>

The value we know for P<sub>2</sub> is "???\x05\x05\x05\x05\x05"

<h2>Sixth-last character</h2>
Only three to go! Calculate C&prime; for \x06\x06\x06\x06\x06:
<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]

  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x06 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xc9

  C&prime;[7] = P&prime;<sub>2</sub>[7] ⊕ P<sub>2</sub>[7] ⊕ C<sub>1</sub>[7]
  C&prime;[7] = 0x06 ⊕ 0x05 ⊕ 0x22
  C&prime;[7] = 0x21

  C&prime;[6] = P&prime;<sub>2</sub>[6] ⊕ P<sub>2</sub>[6] ⊕ C<sub>1</sub>[6]
  C&prime;[6] = 0x06 ⊕ 0x05 ⊕ 0xd1
  C&prime;[6] = 0xd2

  C&prime;[5] = P&prime;<sub>2</sub>[5] ⊕ P<sub>2</sub>[5] ⊕ C<sub>1</sub>[5]
  C&prime;[5] = 0x06 ⊕ 0x05 ⊕ 0xe6
  C&prime;[5] = 0xe5

  C&prime;[4] = P&prime;<sub>2</sub>[4] ⊕ P<sub>2</sub>[4] ⊕ C<sub>1</sub>[4]
  C&prime;[4] = 0x06 ⊕ 0x05 ⊕ 0x51
  C&prime;[4] = 0x52
</pre>

Run the program:
<pre>
  irb(main):<span class="Constant">100</span>:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):<span class="Constant">101</span>:<span class="Constant">1</span>*   cprime = <span class="Special">&quot;</span><span class="Special">\x00\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\x52\xe5\xd2\x21\xc9</span><span class="Special">&quot;</span> + 
  <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):<span class="Constant">102</span>:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Special">&quot;</span>) <span class="Statement">if</span>(try_decrypt(cprime))
  irb(main):<span class="Constant">103</span>:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">111</span>: 00006f52e5d221c93faf089c7a924a7b
</pre>

Break the character:
<pre>
  P<sub>2</sub>[3] = P&prime;<sub>2</sub>[3] ⊕ C<sub>1</sub>[3] ⊕ C&prime;[3]
  P<sub>2</sub>[3] = 0x06 ⊕ 0x0d ⊕ 0x6f
  P<sub>2</sub>[3] = 0x64 = "d"
</pre>

The value we know for P<sub>2</sub> is "??d\x05\x05\x05\x05\x05"

<h2>Two left!</h2>
Only two left! Time to calculate C&prime; for "\x07\x07\x07\x07\x07\x07":
<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]

  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x07 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xc9

  C&prime;[7] = P&prime;<sub>2</sub>[7] ⊕ P<sub>2</sub>[7] ⊕ C<sub>1</sub>[7]
  C&prime;[7] = 0x07 ⊕ 0x05 ⊕ 0x22
  C&prime;[7] = 0x21

  C&prime;[6] = P&prime;<sub>2</sub>[6] ⊕ P<sub>2</sub>[6] ⊕ C<sub>1</sub>[6]
  C&prime;[6] = 0x07 ⊕ 0x05 ⊕ 0xd1
  C&prime;[6] = 0xd2

  C&prime;[5] = P&prime;<sub>2</sub>[5] ⊕ P<sub>2</sub>[5] ⊕ C<sub>1</sub>[5]
  C&prime;[5] = 0x07 ⊕ 0x05 ⊕ 0xe6
  C&prime;[5] = 0xe5

  C&prime;[4] = P&prime;<sub>2</sub>[4] ⊕ P<sub>2</sub>[4] ⊕ C<sub>1</sub>[4]
  C&prime;[4] = 0x07 ⊕ 0x05 ⊕ 0x51
  C&prime;[4] = 0x52

  C&prime;[3] = P&prime;<sub>2</sub>[3] ⊕ P<sub>2</sub>[3] ⊕ C<sub>1</sub>[3]
  C&prime;[3] = 0x07 ⊕ 0x64 ⊕ 0x0d
  C&prime;[3] = 0x52
</pre>

The program:
<pre>
  irb(main):<span class="Constant">104</span>:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):<span class="Constant">105</span>:<span class="Constant">1</span>*   cprime = <span class="Special">&quot;</span><span class="Special">\x00</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\x6e\x53\xe4\xd3\x20\xc8</span><span class="Special">&quot;</span> + 
  <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):<span class="Constant">106</span>:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Special">&quot;</span>) <span class="Statement">if</span>(try_decrypt(cprime))
  irb(main):<span class="Constant">107</span>:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">138</span>: 008a6e53e4d320c83faf089c7a924a7b
</pre>

The calculation:
<pre>
  P<sub>2</sub>[2] = P&prime;<sub>2</sub>[2] ⊕ C<sub>1</sub>[2] ⊕ C&prime;[2]
  P<sub>2</sub>[2] = 0x07 ⊕ 0xe1 ⊕ 0x8a
  P<sub>2</sub>[2] = 0x6c = "l"
</pre>

The value we know for P<sub>2</sub> is "?ld\x05\x05\x05\x05\x05"

<h2>Last block!</h2>
For the last block &mdash; and the last time I ever do a padding oracle calculation by hand &mdash; we calculate C&prime; for "\x08\x08\x08\x08\x08\x08\x08":
<pre>
  C&prime;[k] = P&prime;<sub>2</sub>[k] ⊕ P<sub>2</sub>[k] ⊕ C<sub>1</sub>[k]

  C&prime;[8] = P&prime;<sub>2</sub>[8] ⊕ P<sub>2</sub>[8] ⊕ C<sub>1</sub>[8]
  C&prime;[8] = 0x08 ⊕ 0x05 ⊕ 0xca
  C&prime;[8] = 0xc7

  C&prime;[7] = P&prime;<sub>2</sub>[7] ⊕ P<sub>2</sub>[7] ⊕ C<sub>1</sub>[7]
  C&prime;[7] = 0x08 ⊕ 0x05 ⊕ 0x22
  C&prime;[7] = 0x2f

  C&prime;[6] = P&prime;<sub>2</sub>[6] ⊕ P<sub>2</sub>[6] ⊕ C<sub>1</sub>[6]
  C&prime;[6] = 0x08 ⊕ 0x05 ⊕ 0xd1
  C&prime;[6] = 0xdc

  C&prime;[5] = P&prime;<sub>2</sub>[5] ⊕ P<sub>2</sub>[5] ⊕ C<sub>1</sub>[5]
  C&prime;[5] = 0x08 ⊕ 0x05 ⊕ 0xe6
  C&prime;[5] = 0xeb

  C&prime;[4] = P&prime;<sub>2</sub>[4] ⊕ P<sub>2</sub>[4] ⊕ C<sub>1</sub>[4]
  C&prime;[4] = 0x08 ⊕ 0x05 ⊕ 0x51
  C&prime;[4] = 0x5c

  C&prime;[3] = P&prime;<sub>2</sub>[3] ⊕ P<sub>2</sub>[3] ⊕ C<sub>1</sub>[3]
  C&prime;[3] = 0x08 ⊕ 0x64 ⊕ 0x0d
  C&prime;[3] = 0x61

  C&prime;[2] = P&prime;<sub>2</sub>[2] ⊕ P<sub>2</sub>[2] ⊕ C<sub>1</sub>[2]
  C&prime;[2] = 0x08 ⊕ 0x6c ⊕ 0xe1
  C&prime;[2] = 0x85
</pre>

Then the program:
<pre>
  irb(main):<span class="Constant">112</span>:<span class="Constant">0</span>&gt; <span class="Constant">0</span>.upto(<span class="Constant">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  irb(main):<span class="Constant">113</span>:<span class="Constant">1</span>*   cprime = <span class="Special">&quot;</span><span class="Special">#{</span>i.chr<span class="Special">}</span><span class="Special">\x85\x61\x5c\xeb\xdc\x2f\xc7</span><span class="Special">&quot;</span> + 
  <span class="Special">&quot;</span><span class="Special">\x3f\xaf\x08\x9c\x7a\x92\x4a\x7b</span><span class="Special">&quot;</span>
  irb(main):<span class="Constant">114</span>:<span class="Constant">1</span>&gt;   puts(<span class="Special">&quot;</span><span class="Special">#{</span>i<span class="Special">}</span><span class="Constant">: </span><span class="Special">#{</span>cprime.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>)<span class="Special">}</span><span class="Special">&quot;</span>) <span class="Statement">if</span>(try_decrypt(cprime))
  irb(main):<span class="Constant">115</span>:<span class="Constant">1</span>&gt; <span class="Statement">end</span>
  <span class="Constant">249</span>: f985615cebdc2fc73faf089c7a924a7b
</pre>

And, finally, we calculate the character one last time:
<pre>
  P<sub>2</sub>[1] = P&prime;<sub>2</sub>[1] ⊕ C<sub>1</sub>[1] ⊕ C&prime;[1]
  P<sub>2</sub>[1] = 0x08 ⊕ 0x83 ⊕ 0xf9
  P<sub>2</sub>[1] = 0x72 = "r"
</pre>

The value we know for P<sub>2</sub> is "rld\x05\x05\x05\x05\x05"

<h2>Conclusion</h2>
So, you've seen the math behind how we can decrypt a full block of a CBC cipher (specifically, DES) using only a padding oracle. The previous block would be decrypted the exact same way, and would wind up as "Hello Wo". 

Hopefully this demonstration will help you understand what's going on! Padding oracles, once you really understand them, are one of the simplest vulnerabilities to exploit!
