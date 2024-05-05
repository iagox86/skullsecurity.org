---
id: 1501
title: 'Compression attacks'
date: '2013-01-24T17:43:06-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1501'
permalink: '/?p=1501'
categories:
    - Default
---

For anybody who's been following my blog, you'll be well versed in attacks against poorly implemented cryptography. Well, I have one more: compression attacks (the type of attack used in the so-called [CRIME exploit](https://en.wikipedia.org/wiki/CRIME_(security_exploit))).

Of all the attacks I've implemented, this is both the easiest to understand, and the most annoying to implement. Why? Because compression is painfully unreliable!

## The theory

Let's start with looking at how compression works!

Now, I always have to prefix my posts with this little disclaimer: I am not an academic of any sort. I look at things purely as an outsider, and as an interested party. So I'm likely making mistakes on the technical details. But, even so, the outputs speak for themselves.

So the theory of cryptography is that patterns will be eliminated. We can prove that fairly easily using, as I always do, irb:

```

$ irb
irb(main):001:0> require 'zlib'
=> true
irb(main):002:0> Zlib::Deflate.deflate("This is a test").length
=> 20
irb(main):003:0> Zlib::Deflate.deflate("This is a testThis is a test").length
=> 23
```

Notice that I doubled the length of the string from 14 characters to 28, but the compressed string is only three characters longer? What if I compress 100 copies of that string? Or 1000?

```

irb(main):004:0> Zlib::Deflate.deflate("This is a test" * 100).length
=> 33
irb(main):005:0> Zlib::Deflate.deflate("This is a test" * 1000).length
=> 66
```

I'm compressing 14,000 bytes to 66 (that's 0.005% of the original size!) - it turns out, patterns are what compression is amazing at!

And that's what we're going to take advantage of.

## The setup

All right, now that we have a little theory behind them, let's look at how the attack works!

This attack requires partially chosen plaintext. That means, much like