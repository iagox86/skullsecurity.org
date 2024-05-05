---
id: 2552
title: 'BSidesSF CTF 2021 &#8211; PermCoin Author Write-up: The Rubik&#8217;s Cube makes a terrible hash algorithm'
date: '2021-03-18T03:31:16-05:00'
author: symmetric
layout: revision
guid: 'https://blog.skullsecurity.org/2021/2492-revision-v1'
permalink: '/?p=2552'
---

Hey everyone, this is *symmetric* aka Brandon Enright back for a second year with another author write-up. This time it's 2021 and the challenge is the `PermCoin` trio of challenges we had for the BSides San Francisco 2021 CTF. Of course, before I start, I'd like to thank the venerable Ron Bowes for his generosity hosting this post!

The `PermCoin` challenge and the so-called `permhash296` that it's based on is somewhat unusual both from a CTF and cryptographic perspective. The `permhash296` algorithm is entirely custom cryptography based on a permutation group rather than more traditional cryptography. My hope with this write-up is to explain much of the thought process and design decisions that went into making the challenge and how to solve it.

## Designing the `permhash296` cryptography

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

I thought about the challenge on and off throughout 2020 trying to come up with the "best" permutation group to base the challenge on. I really liked the fact that `log2(64!) ~= 295.99951` which means I could map each permutation into 296 bits very neatly. As January 2021 came and the CTF drew near I began experimenting with [GAP](https://www.gap-system.org/) exploring what sort of groups and permutations (generators) would make for a good solving experience. I initially planned on players using `GAP`'s `GroupHomomorphismByImages` feature (see [Analyzing Rubik's Cube with GAP](https://www.gap-system.org/Doc/Examples/rubik.html) for an example) to find [preimages](https://en.wikipedia.org/wiki/Preimage_attack) however `GAP` every cryptographically reasonably sized group (>= 2^80 elements) I tried would cause `GAP` to run out of memory while finding a preimage. At this point I was stuck for about two weeks unsure of what to do. If `GAP` is out for finding preimages then there needs to be some natural way for players to find their own via a simple algorithm.

Eventually I realized that the [Symmetric Group](https://en.wikipedia.org/wiki/Symmetric_group) S<sub>64</sub> (the group of all permutations of 64 elements) would make for a good challenge after all. Instead of using `GAP` to find preimages players would be given permutations that easily build a simple sorting algorithm like [bubble sort](https://en.wikipedia.org/wiki/Bubble_sort). Since bubble sort only relies on swapping pairs of adjacent elements I found that giving players a way to swap a pair, combine with a way to "rotate" the state, they could combine swaps and rotates to swap any adjacent pair anywhere. From here building bubble sort is very straight-forward.

To complete the `permhash296` design I decided to select 16 different permutations plus a "finalization" permutation that gets applied after all the input bytes are consumed. `permhash296` works by initializing an array of 64 elements with the numbers 0 .. 63. Then each nibble (4-bits) of input selects one of the 16 permutations to apply to the state, one permutation after another. This means each byte always applies two permutations to the state. To produce the 296-bit hash output, the state of the 64-element array is mapped to an integer between `0` and `64! - 1` using a [factorial number system](https://en.wikipedia.org/wiki/Factorial_number_system) (sometimes called a factoradic) by way of a [Lehmer code](https://en.wikipedia.org/wiki/Lehmer_code).

I deliberated extensively during the process of making the specific choices for each of the 16 permutations. I wanted the solving experience to feel very much like the solving process for a permutation puzzle like the Rubik's Cube. Most permutation puzzles require that you search for useful sequences of moves, colloquially called "algorithms" by much of the twisty puzzle community. Often these move sequences are [commutators](https://en.wikipedia.org/wiki/Commutator#Group_theory): `a b a' b'`. This leads to a problem for a cryptographic hash though: it requires the inverse permutations to be readily available. On a Rubik's Cube and most other twisty puzzles the inverse of a move is trivial: just turn the face the opposite direction and you've undone the previous move. For a cryptographic hash though this leads to extremely trivial collisions. I didn't want the challenge to be *that easy*! With this in mind I decided on some basic criteria for selecting the permutations:

- No permutation would be directly useful all by itself
- No permutation would have a very low-order
- No permutation would be the inverse of another
- Products of the permutations should produce results *useful for bubble sort*
- Extra permutations should be available that, while not directly required for bubble sort, *allow for substantial optimization* of the bubble sort algorithm

Using the above criteria I used `GAP` to construct the S<sub>64</sub> group for me. Here you can see the construction, size, selecting a random element, and testing for group membership:

```
<pre class="wp-block-code">```
gap> s64 := Image(IsomorphismPermGroup(SymmetricGroup(64)));
Sym( [ 1 .. 64 ] )

gap> Size(s64);
126886932185884164103433389335161480802865516174545192198801894375214704230400000000000000

gap> Random(s64);
(1,24,9,53,43,47,23,2,25,36,12,15,11,22,56,6,10,49,3,52,51,35,8,38,17,63,30,19,16,59,46,44,26,32,54,28,58,39,45,42,55,37)(4,62,13,57,
29,5,7,27,33,64,14)(18,50,31)(20,34,48,60,21,41)

gap> (1,2) in s64;
true
```
```

To generate the actual permutations I first manually defined what I wanted the result to be, and then generated a random masking element to "hide" the clean permutation. For example here, here is how the core bubble sort "tools", namely the swap and state rotate were made:

```
<pre class="wp-block-code">```
gap> rot := (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64);
(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,
48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64)

gap> rot_mask := Random(s6);
(2,40,36,30,5,10,56,23,45,31,55,13,29,46,9,26,58,18,39,17,41,33,52,35,48,20,19,25,21,11,16,59,22,61,63,37,7,53,15,44,54,4,32,47,57,14,
49,51,24,64,8)(3,60,34,43,6,42,50)(12,38)

gap> perm_0 := rot * rot_mask^2;
(1,36,53,32,35,5,50,64)(2,34,20,16,33,6,15,22,31,57,39,30,13,51,48,24,11,12,46,14,54,29,10,59,43,4,56,49,60,37,38,41,3,47,19,25,18,21,
63)(7,40,52,44,55,45,26,27,28,9,23,8,58,61,62)

gap> perm_1 := rot_mask^-1;
(2,8,64,24,51,49,14,57,47,32,4,54,44,15,53,7,37,63,61,22,59,16,11,21,25,19,20,48,35,52,33,41,17,39,18,58,26,9,46,29,13,55,31,45,23,56,
10,5,30,36,40)(3,50,42,6,43,34,60)(12,38)

gap> swap := (1,2);
(1,2)

gap> swap_mask := Random(s64);
(1,7,33,26,13,48,2,59,23,28,12,17,50,32,41,36,44,34,47,43,21,4,56,35,52,58,62,8,9,5,15,24,61,37,55,6,38,25,49,42,30,40,18,11,14)(3,46,
19,31,57,60,39,16,20,53,64)(10,54,29,51,63,45,27)

gap> perm_2 := swap * swap_mask^2;
(1,23,12,50,41,44,47,21,56,52,62,9,15,61,55,38,49,30,18,14,7,26,48,59,28,17,32,36,34,43,4,35,58,8,5,24,37,6,25,42,40,11)(2,33,13)(3,19,
57,39,20,64,46,31,60,16,53)(10,29,63,27,54,51,45)

gap> perm_3 := swap_mask^-1;
(1,14,11,18,40,30,42,49,25,38,6,55,37,61,24,15,5,9,8,62,58,52,35,56,4,21,43,47,34,44,36,41,32,50,17,12,28,23,59,2,48,13,26,33,7)(3,64,
53,20,16,39,60,57,31,19,46)(10,27,45,63,51,29,54)
```
```

In all the following rotation sequences were hidden among the permutations:

<figure class="wp-block-image size-large">![](http://www.brandonenright.net/~bmenrigh/permhash_rotates.png)</figure>And the following swaps:

<figure class="wp-block-image size-large">![](http://www.brandonenright.net/~bmenrigh/permhash_swaps.png)</figure>The reason for `233`, `323`, and `332` are all swaps is because sequence rotations are part of the same [conjugacy class](https://en.wikipedia.org/wiki/Conjugacy_class). Of course the same applies to `cddd`, `dcdd`, `ddcd`, and `dddc`.

The rotations `89` and `ab` rotate the state by 8 and 32 respectively. `eff` only rotates 63 elements, leaving the first element in place. This is equivalent to a full state rotation followed by a swap. Since bubble sort makes heavy use of rotations followed by swaps `eff` was provided for additional opportunities for optimization. The `89` and `ab` sequences are available to "compress" long strings of repeated `011` rotations into much shorter sequences.

## Designing the `PermCoin` Challenges

At first while I was designing `permhash296` I thought the only challenge asked of players would be to find an optimized preimage for some hash value. In the process of designing I realized two things. First, I was spending WAY TOO MUCH TIME for just a single challenge, and second, players would probably need some coaxing with a few "sub" challenges to lead them to find all the breadcrumbs that would help them generate preimages.

In my experience, my best CTF challenges are made inside-out. First I identify the technical details of what a player will be expected to do in the solving process. After that I work out the narrative/framework that provides them a reason for why the problem even exists. In the case of the `PermCoin` challenges I worked on `permhash296` for more than a month and had written the optimized bubble sort preimage generation code before the blockchain-based narrative structure came to mind. Armed with the blockchain narrative framing the reasons for the sub challenges practically wrote themselves.

There were a few breadcrumbs I wanted lead players to. The first was thinking about the [order](https://en.wikipedia.org/wiki/Order_(group_theory)) of the permutations. By asking first for a collision and then later a collision with the empty string I wanted players to spot how sequences like `233233` leave the state unchanged. This is because `233` is a swap which is order 2. The second breadcrumb I wanted players to find was sequences in the same conjugacy class. By asking for a "restricted collision" where the inputs couldn't share any bytes I wanted players to find sequences like `abab` == `baba` or `233233` == `323323`. These rotations of useful sequences are themselves useful. With these goals in mind I picked 8 sub challenges and divided them into three categories, each category rewarding a flag:

```
<pre class="wp-block-code">```
PermCoin Hacktool> status

Challenge Statuses
==================

Starter:
 1 - permhash296 arbitrary-input computation
 2 - permhash296 collision
 3 - permhash296 empty-string collision

Partial:
 4 - permhash296 length extension
 5 - permhash296 restricted collision
 6 - permhash296 unrestricted pre-image

Full:
 7 - permhash296 chosen-prefix collision
 8 - permhash296 optimized state control

```
```

## Solving `PermCoin`

### Challenge 1:

```
<pre class="wp-block-code">```
PermCoin Hacktool> challenge 1
Challenge 1:

If we're going to have any chance of attacking the PermCoin blockchain
we'll need to be able to compute permhash296 on arbitrary inputs! To
make sure we have the permhash296 computations working, you will be
asked to compute the permhash296 of a random hex-encoded string.

== Technical Requirements ==
permhash296(<provided plaintext>) = <your answer>

Please compute the hash of 44a48d34678b877f
```
```

The `PermCoin` challenge comes with a built-in `hash` command for convenience:

```
<pre class="wp-block-code">```
PermCoin Hacktool> hash 44a48d34678b877f
de7dbdb3935a5e74dbf4601a28fd50bb3b44768a39e6ec6d3bb2a8e156c3c36b303b61725d
```
```

```
<pre class="wp-block-code">```
permhash296? de7dbdb3935a5e74dbf4601a28fd50bb3b44768a39e6ec6d3bb2a8e156c3c36b303b61725d

Challenge 1 complete!
```
```

### Challenge 2:

```
<pre class="wp-block-code">```
PermCoin Hacktool> challenge 2
Challenge 2:

PermCoin was built with the assumption that permhash296 is
collision-resistant.  If we can find collisions in permhash296 we can
'fork' the blockchain by sending some nodes in the network one copy
and other nodes in the network the other copy without worrying about
hash inconsistencies. Later when the nodes try to reconcile, the chain
will validate cryptographically but their history will disagree. We've
found a way to crash the PermCoin client during reconciliation with
collisions. Using this we can temporarily DoS the network and perform
arbitrage on the price differential when the network can't settle!

== Technical Requirements ==
permhash296(<your message 1>) = permhash296(<your message 2>)
```
```

This challenge is trivial to solve with brute force. There are tons of short colliding messages like `abab` and `baba`. I thought perhaps the most obvious choice would be to find a few elements with short orders like permutation `6` that has order 40 and permutation `f` that has order 56.

To easily find the orders of the permutations they can be "imported" into `GAP`. The main difference between the provided `go` code and `GAP` is that the `go` code is 0-based and `GAP` is 1-based. This is easily handled in `GAP` by using `List` and adding 1 to each element. Here is how to load permutation `0`:

```
<pre class="wp-block-code">```
gap> PermList(List([63, 62, 40, 42, 34, 32, 61, 22, 27, 28, 23, 10, 29, 45, 5, 19, 16, 24, 46, 33, 17, 14, 8, 47, 18, 44, 25, 26, 53, 38, 21, 52, 15, 1, 31, 0, 59, 36, 56, 6, 37, 41, 58, 51, 54, 11, 2, 50, 55, 4, 12, 39, 35, 13, 43, 3, 30, 7, 9, 48, 57, 60, 20, 49], i -> i + 1))^-1;
(1,36,53,32,35,5,50,64)(2,34,20,16,33,6,15,22,31,57,39,30,13,51,48,24,11,12,46,14,54,29,10,59,43,4,56,49,60,37,38,41,3,47,19,25,18,
21,63)(7,40,52,44,55,45,26,27,28,9,23,8,58,61,62)
```
```

Once all the permutations are loaded up into a list (named `gens`) the `Order` of each can be computed:

```
<pre class="wp-block-code">```
gap> List(gens, Order);
[ 1560, 714, 462, 3465, 3990, 1484, 40, 836, 114, 2064, 918, 910, 440, 260, 3600, 56 ]
```
```

Using `"6"x40` and `"f"x56`:

```
<pre class="wp-block-code">```
Please enter message 1: 6666666666666666666666666666666666666666
Message 1's permhash296 is 4eeab86b437733ccd24f37aea5b5c37a690a4326fc84ee183a18a20710e5a253181c94e452

Please enter message 2 (this must hash to the same thing as message 1): ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
Message 2's permhash296 is 4eeab86b437733ccd24f37aea5b5c37a690a4326fc84ee183a18a20710e5a253181c94e452

Challenge 2 complete!
```
```

### Challenge 3:

```
<pre class="wp-block-code">```
PermCoin Hacktool> challenge 3
Challenge 3:

There are a number of situations where having an input that hashes to
the same value as the empty-string/empty-input is useful. Trivial
collisions are possible with such a value! We will need an input that
collides with the empty-string in order to simplify our attacks.

== Technical Requirements ==
permhash296("") = permhash296(<your message>)

The empty-string hash: 4eeab86b437733ccd24f37aea5b5c37a690a4326fc84ee183a18a20710e5a253181c94e452
```
```

Using the order of the elements shown in `challenge 2` this is trivial. A less trivial solution is to find that `456` is the identity element (order 0). However, `456` is an odd number of nibbles so can't just be used once. This is very useful for "padding" solutions that use an odd number of nibbles into one that have an even number (since `permhash296` uses bytes). I specifically provided `456` for this very reason. Here I use it in a tricky way just for fun. Do you see why this works?

```
<pre class="wp-block-code">```
Please another message that collides with the empty-string: 464556
Your input's permhash296 is 4eeab86b437733ccd24f37aea5b5c37a690a4326fc84ee183a18a20710e5a253181c94e452

Challenge 3 complete!
```
```

### Challenge 4:

```
<pre class="wp-block-code">```
PermCoin Hacktool> challenge 4
Challenge 4:

As part of a new PermCoin transparency initiative, central nodes
broadcast a 'running hash' of transactions without broadcasting the
transactions themselves.  Later when the block is 'sealed' with a
final hash the transactions are revealed and nodes can verify the
previously-broadcast running hashes.  To append rogue transactions
into the ledger we need to be able to compute permhash296 values from
these intermediate hashes without having the intermediate
plaintext. Our best bet is a length-extension attack.

== Technical Requirements ==
permhash296(<plaintext not provided>) = <given hash>
permhash296(<plaintext not provided>||<given message>) = <your answer>

The intermediate hash broadcast through the network was dc40b9e8b1bcc54733ed7cbdf868bd3255a6bdae82077d41d288d4d1d33d0953df2c25e908
We need you to compute a new intermediate hash after d44c4a18f7e8aa34 has been appended to the hidden plaintext.
```
```

`Challenge 4` is where the difficulty starts to really ramp up. To perform length-extension, the state of the internal 64-element array must be recovered from the provided hash. In short, `permhash296` converts the permutation into an integer and to recover the state you must be able to do the inverse: convert an integer into a permutation. Here is the `go` code I wrote do do that:

```
<pre class="wp-block-code">```
package main

import (
    "permhash296"
    "math/big"
)

func frombinary(s *permhash296.Permhash296, bin []byte) {

    pint := new(big.Int).SetBytes(bin)

    nv := make([]int, permhash296.N)
    for i := 0; i < permhash296.N; i++ {
        nv[i] = i;
    }

    fact := big.NewInt(1)
    for i := 2; i < permhash296.N; i++ {
        fact.Mul(fact, big.NewInt(int64(i)))
    }

    for i := permhash296.N; i > 1; i-- {
        var q, r big.Int
        q.DivMod(pint, fact, &r)

        qint := q.Int64()

        s.State[permhash296.N - i] = nv[qint]
        nv = append(nv[:qint], nv[qint + 1:]...)

        fact.Div(fact, big.NewInt(int64(i - 1)))
        pint.Set(&r)
    }

    s.State[permhash296.N - 1] = nv[0]

}
```
```

I think the easiest way to write a function like `frombinary` is to first study the `Tobinary` function in the provided `permhash296.go` code and simply perform the steps in reverse.

With `frombinary` the hash `dc40b9e8b1bcc54733ed7cbdf868bd3255a6bdae82077d41d288d4d1d33d0953df2c25e908` can be converted back into an internal state: `[55, 15, 43, 3, 25, 60, 45, 42, 31, 52, 7, 57, 17, 23, 44, 62, 16, 41, 1, 59, 28, 26, 56, 46, 12, 27, 4, 61, 18, 35, 53, 2, 34, 19, 29, 47, 40, 0, 48, 39, 50, 5, 49, 37, 36, 58, 11, 24, 21, 9, 10, 6, 14, 51, 32, 20, 8, 38, 30, 54, 33, 63, 13, 22]`

However this state can't be used directly. This state was further permuted by the finalization permutation so before additional input can be appended the inverse finalization permutation must be applied. Here I chose to apply all the permutations including the required `d44c4a18f7e8aa34` to be appended in `GAP`:

```
<pre class="wp-block-code">```
gap> state := PermList(List([55, 15, 43, 3, 25, 60, 45, 42, 31, 52, 7, 57, 17, 23, 44, 62, 16, 41, 1, 59, 28, 26, 56, 46, 12, 27, 4, 61, 18, 35, 53, 2, 34, 19, 29, 47, 40, 0, 48, 39, 50, 5, 49, 37, 36, 58, 11, 24, 21, 9, 10, 6, 14, 51, 32, 20, 8, 38, 30, 54, 33, 63, 13, 22], i -> i + 1))^-1;
(1,38,44,3,32,9,57,23,64,62,28,26,5,27,22,49,39,58,12,47,24,14,63,16,2,19,29,21,56)(6,42,18,13,25,48,36,30,35,33,55,60,20,34,61)(7,52,54,31,59,46)(8,11,51,41,37,45,15,53,10,50,43)

gap> List(Permuted([1 .. 64], state * final^-1 * gens[14] * gens[5] * gens[5] * gens[13] * gens[5] * gens[11] * gens[2] * gens[9] * gens[16] * gens[8] * gens[15] * gens[9] * gens[11] * gens[11] * gens[4] * gens[5] * final), i -> i - 1);
[ 55, 49, 7, 3, 54, 63, 0, 28, 33, 42, 16, 26, 44, 1, 20, 22, 29, 11, 56, 32, 5, 36, 23, 50, 51, 8, 62, 6, 10, 12, 60, 17, 58, 34, 47, 57, 19, 18, 45, 52, 27, 46, 48, 61, 41, 38, 31, 4, 37, 35, 24, 53, 9, 40, 59, 25, 43, 39, 15, 13, 14, 21, 2, 30 ]
```
```

Here the `gens[14] * gens[5]...` correspond to the `d4...` of the content to be appended. In hindsight doing this entirely in `GAP` was more work than it needed to. Instead of using `GAP` to apply the inverse finalization permutation, it could be used to compute the inverse and then that could be loaded up into a custom fork of the `permhash296.go` code so that a routine like `UnFinalize` could be written:

```
<pre class="wp-block-code">```
func (s *Permhash296) UnFinalize() {
    s.apply_perm(unfinal[:])
}
```
```

Alternatively, the order of the final permutation is 3828 so you could just call `Finalize` 3827 more times to undo it. Once the state is found as shown above, it's just a matter of calling `Tobinary` to get the hash:

```
<pre class="wp-block-code">```
What is the new length-extended hash? de5e5c7f04b2ce0817710e0b7ec213bd1af3041854d7793683ae9936a911f7115f6a268638

Challenge 4 complete!
```
```

### Challenge 5:

```
<pre class="wp-block-code">```
PermCoin Hacktool> challenge 5
Challenge 5:

For permhash296 collisions to be maximally useful, we need you to be
able to create very short ones of equal length. Furthermore, some byte
comparison code in the PermCoin client will erroneously handle our
collisions if they have even a single byte in common at the same
place.

For example \x0011 compared to \x1122 is fine but \x0011 compared to
\x0022 is not because they both start with \x00 which is the same byte
in the same offset.

We will need you to find a pair of equal-length short messages that
don't share any common bytes in the same place that have the same
permhash296 value. This will allow us to send PermCoins to specific
nodes in the network and then later we can swap-out the node ID in the
ledger with a colliding node ID we control. With this, we can spend
money and then later re-write history to pay ourselves!

== Technical Requirements ==
permhash296(<your message 1>) = permhash296(<your message 2>)
```
```

`Challenge 5` forces you to find a short cycle or other useful short-sequence "tools". By restricting the maximum input to 8 bytes the order 40 `6` permutation isn't sufficient. As described in previous challenges there are many short cycles. Here is a non-trivial solution just for fun:

```
<pre class="wp-block-code">```
Please enter message 1 (max 8 bytes): eff456
Message 1's permhash296 is 4addb2442f52d80bdf3baed6999de55ca7f130a58779fc9912cc8cf77403087e181c94e452

Please enter message 2 (length 3 bytes): 011233
Message 2's permhash296 is 4addb2442f52d80bdf3baed6999de55ca7f130a58779fc9912cc8cf77403087e181c94e452

Challenge 5 complete!
```
```

### Challenge 6:

```
<pre class="wp-block-code">```
PermCoin Hacktool> challenge 6
Challenge 6:

We think we've found a way to spend or transfer PermCoins that we no
longer own!  Up until now the ledger history stored in the PermCoin
blockchain has prevented any significant attacks. If you can generate
an entirely fake history that matches the permhash296 hash up to some
point we can swap out the start of the real ledger for our (possibly
corrupt) false initial history.  This attack will be detected
eventually but if we convert our stollen PermCoins to fiat before it's
detected, nothing can be done.

To pull this attack off, we'll find a permhash296 value in the
blockchain history. Your job will be to find some input (a pre-image)
that hashes to that same hash.

== Technical Requirements ==
permhash296(<your answer plaintext>) = <given hash>

Please compute a pre-image for the hash 8f26a97359fdf5f08d06df5066e9a3597bb0b082b37244a5b006bb9ddc31eefebb57b08d57
```
```

Unfortunately `challenge 6` proved to be a wall for most teams. The two teams that solved this challenge went on to solve the final two as well. To find a preimage for the provided hash, first the hash must be converted back into an internal state permutation. Here using `frombinary` written in `challenge 4`: `[35, 58, 14, 18, 23, 47, 17, 22, 11, 28, 40, 31, 45, 37, 60, 29, 15, 62, 24, 20, 1, 4, 10, 49, 34, 27, 42, 50, 25, 41, 54, 5, 32, 57, 8, 39, 38, 6, 7, 30, 63, 12, 36, 3, 46, 61, 2, 56, 59, 44, 16, 53, 21, 9, 51, 19, 13, 0, 43, 48, 33, 26, 55, 52]`

Then you can apply the inverse permutation using `GAP` (or via the easier methods described in `challenge 4`:

```
<pre class="wp-block-code">```
gap> state := PermList(List([35, 58, 14, 18, 23, 47, 17, 22, 11, 28, 40, 31, 45, 37, 60, 29, 15, 62, 24, 20, 1, 4, 10, 49, 34, 27, 42, 50, 25, 41, 54, 5, 32, 57, 8, 39, 38, 6, 7, 30, 63, 12, 36, 3, 46, 61, 2, 56, 59, 44, 16, 53, 21, 9, 51, 19, 13, 0, 43, 48, 33, 26, 55, 52], i -> i + 1))^-1;
(1,58,34,61,15,3,47,45,50,24,5,22,53,64,41,11,23,8,39,37,43,27,62,46,13,42,30,16,17,51,28,26,29,10,54,52,55,31,40,36)(2,21,20,56,63,18,7,38,14,57,48,6,32,12,9,35,25,19,4,44,59)(49,60)

gap> List(Permuted([1 .. 64], state * final^-1), i -> i - 1);
[ 34, 1, 2, 31, 19, 53, 12, 4, 14, 3, 18, 30, 56, 7, 6, 28, 24, 50, 8, 35, 40, 55, 16, 51, 42, 33, 43, 59, 25, 49, 36, 10, 52, 23, 62, 27, 0, 32, 9, 38, 47, 45, 41, 11, 48, 61, 29, 26, 57, 54, 21, 58, 5, 44, 20, 39, 37, 63, 46, 17, 15, 22, 60, 13 ]
```
```

Here is some `perl` (sorry!) code to perform bubble sort using only `011` for rotating and `233` for swapping the first two array elements (and `456` for padding if needed):

```
<pre class="wp-block-code">```
#!/usr/bin/perl

use strict;
use warnings;

my $N = 64;

my $o; # The state rotation offset
my @state = (0 .. ($N - 1));

my @goal = (34, 1, 2, 31, 19, 53, 12, 4, 14, 3, 18, 30, 56, 7, 6, 28, 24, 50, 8, 35, 40, 55, 16, 51, 42, 33, 43, 59, 25, 49, 36, 10, 52, 23, 62, 27, 0, 32, 9, 38, 47, 45, 41, 11, 48, 61, 29, 26, 57, 54, 21, 58, 5, 44, 20, 39, 37, 63, 46, 17, 15, 22, 60, 13);
my @gidx = (0 x $N);

for (my $i = 0; $i < $N; $i++) {
    $gidx[$goal[$i]] = $i;
}

# Everything is going to be done relative to goal[0] so find where it is and call that 'solved' but at a different offset
for (my $i = 0; $i < $N; $i++) {
    if ($state[$i] == $goal[0]) {
        $o = $i;
        last;
    }
}

my $m = solve('', $o, \@state, \@goal);

print 'Length ', (length($m) / 2), ' solution found: ', "\n";
print $m, "\n";

sub is_solved {
    my $sref = shift;

    for (my $i = 0; $i < $N; $i++) {
        if ($sref->[$i] != $goal[$i]) {
            return 0;
        }
    }

    return 1;
}


sub rot {
    my $sref = shift;

    unshift @$sref, pop @$sref;

    return '011';
}


sub swap_0_1 {
    my $sref = shift;

    ($sref->[0], $sref->[1]) = ($sref->[1], $sref->[0]);

    return '233';
}


sub print_state {
    my $sref = shift;

    print '[', join(',', @{$sref}), ']', "\n";
}


sub solve {
    my $m = shift;
    my $o = shift;
    my $sref = shift;
    my $gref = shift;

    my @state = @{$sref};
    my @goal = @{$gref};

    while (is_solved(\@state) != 1) {

        if ($o > 1) {
            if ($gidx[$state[0]] > $gidx[$state[1]]) {

                $m .= swap_0_1(\@state);
            }
        }

        $m .= rot(\@state);
        $o = ($o + 1) % $N; # Rotate the state offset

    }

    if (length($m) % 2 == 1) {
        $m .= '456';
    }

    return $m;
}
```
```

This is the most straight-forward completely non-optimized bubble sort possible. It produces huge solutions:

```
<pre class="wp-block-code">```
$ ./solve_state.pl 
Length 6621 solution found: 
23301123301123301123301123[..truncated for your sanity...]011011011011011011011011011011011011011456
```
```

However the preimage works:

```
<pre class="wp-block-code">```
pre-image? 
23301123301123301123301123[..truncated for your sanity...]011011011011011011011011011011011011011456

Challenge 6 complete!
```
```