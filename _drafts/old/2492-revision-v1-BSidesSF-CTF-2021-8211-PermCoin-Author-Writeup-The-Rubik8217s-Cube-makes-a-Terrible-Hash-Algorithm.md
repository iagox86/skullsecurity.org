---
id: 2528
title: 'BSidesSF CTF 2021 &#8211; PermCoin Author Writeup: The Rubik&#8217;s Cube makes a Terrible Hash Algorithm'
date: '2021-03-17T00:38:41-05:00'
author: symmetric
layout: revision
guid: 'https://blog.skullsecurity.org/2021/2492-revision-v1'
permalink: '/?p=2528'
---

Hey everyone, this is *symmetric* aka Brandon Enright back for a second year with an author writeup. This time it's 2021 and the challenge is the `PermCoin` trio of challenges we had for the BSides San Francisco 2021 CTF. Of course, before I start, I'd like to thank the venerable Ron Bowes for his generosity hosting this post!

The `PermCoin` challenge and the so-called `permhash296` that it's based on is somewhat unusual both from a CTF and cryptographic perspective. The `permhash296` algorithm is entirely custom cryptography based on a permutation group rather than more traditional cryptography. My hope with this post is to explain much of the thought process and design decisions that went into making the challenge and how to solve it.

### Designing the `permhash296` cryptography

I think it's fair to say that much of my adult life has been immersed in two thing: information security, and "twisty" (permutation) puzzles. Lock picking (hidden mechanism puzzles) probably comes in third but that's a topic for another blog. For years I've wanted to explore cryptographic primitives and ciphers based on permutation puzzles but so far I've never seen anything that looks like a good basis for a /secure/ algorithm. Fortunately when it comes to CTF challenges, security isn't a requirement! While working on challenges for the 2020 CTF the kernel of an idea for a hash algorithm based on a permutation puzzle started to emerge. I didn't have time to do it justice in 2020 so I shelved the idea for 2021. This is what I wrote in my notes:

```
<pre class="wp-block-code">```
== Permutation Hash ==

The hash is a 256-byte array (much like the RC4 state) initialized to
0 .. 255 and then each byte of input permutes the state in some
way. Using a tool like GAP you can completely break this hash in any
way you want.  You can find pre-images and chosen-prefix collisions
and all sorts of other useful things a hash is supposed to protect
against.

Then we use PermHash to protect something and the fact that the hash
is breakable allows the system we used it in to be broken.

Another idea would be to use a 64-byte array since 64! is very close
to a power-of-two and can be converted cleanly to hex using a
factorial number system. The bias in the high bit will be tiny.
```
```

I thought about the challenge on and off throughout 2020 trying to come up with the "best" permutation group to base the challenge on. I really liked the fact that `log2(64!) ~= 295.99951` which means I could map each permutation into 296 bits very neatly. As January 2021 came and the CTF drew near I began experimenting with [GAP](https://www.gap-system.org/) exploring what sort of groups and permutations (generators) would make for a good solving experience. I initially planned on players using GAP's `GroupHomomorphismByImages` feature (see [Analyzing Rubik's Cube with GAP](https://www.gap-system.org/Doc/Examples/rubik.html) for an example) to find preimages however GAP every cryptographically reasonably sized group (>= 2^80 elements) I tried would cause GAP to run out of memory while finding a preimage. At this point I was stuck for about two weeks unsure of what to do. If GAP is out for finding preimages then there needs to be some natural way for players to find their own via a simple algorithm.

Eventually I realized that the [Symmetric Group](https://en.wikipedia.org/wiki/Symmetric_group) S<sub>64</sub> (the group of all permutations of 64 elements) would make for a good challenge after all. Instead of using GAP to find preimages players would be given permutations that easily build a simple sorting algorithm like [bubble sort](https://en.wikipedia.org/wiki/Bubble_sort). Since bubble sort only relies on swapping pairs of adjacent elements I found that giving players a way to swap a pair, combine with a way to "rotate" the state, they could combine swaps and rotates to swap any adjacent pair anywhere. From here building bubble sort is very straight-forward.

To complete the `permhash296` design I decided to select 16 different permutations plus a "finalization" permutation that gets applied after all the input to the hash is consumed. `permhash296` works by initializing an array of 64 elements with the numbers 0 .. 63. Then each nibble (4-bits) of input selects one of the 16 permutations to apply to the state, one permutation after another in turn until all the input is consumed. This means each byte always applies two permutations to the state. To produce the 296-bit hash output, the state of the 64-element array is mapped to an integer between `0` and `64! - 1` using a [factorial number system](https://en.wikipedia.org/wiki/Factorial_number_system) (sometimes called a factoradic) by way of a [Lehmer code](https://en.wikipedia.org/wiki/Lehmer_code).