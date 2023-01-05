---
id: 2503
title: 'BSidesSF CTF 2021 Author writeup: Reverseme and Reverseme2 &#8211; simpler
  reverse engineering challenges'
date: '2021-03-15T11:40:00-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2503
permalink: "/2021/bsidessf-ctf-2021-author-writeup-reverseme-and-reverseme2-simpler-reverse-engineering-challenges"
categories:
- ctfs
- re
comments_id: '109638380094239850'

---

This is going to be a writeup for the Reverseme challenges (<a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/reverseme">reverseme</a> and <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/reverseme2">reverseme2</a> from <a href="https://ctftime.org/event/1299">BSides San Francisco 2021</a>.

Both parts are reasonably simple reverse engineering challenges. I provide the compiled binaries to the player (you can find those in the respective distfiles/ folders), and you have to figure out what to do with them.

Both challenges use the same basic code as the <a href="https://blog.skullsecurity.org/2021/bsidessf-ctf-2021-author-writeup-shellcode-primer-runme-runme2-and-runme3">runme</a> challenges, where you send shellcode that is executed. Only in this case, the shellcode must be modified or "encoded" in some way first!
<!--more-->
<h2>Reverseme</h2>
Since this can be solved with basic tools, I'm just going to use <tt>objdump</tt> disassemble the Reverseme binary. You can much more effectively use IDA or Ghidra, but to use those I might have to take screenshots, deal with file uploads, etc. :)

Here's the output from objdump, focused on the important part (which I found by searching for <tt>main</tt>):
<pre>$ objdump -D -M intel ./reverseme/distfiles/reverseme
[...]
    ; Read the code from stdin (should be identical to Runme)
    1220:       e8 3b fe ff ff          call   1060 &lt;read@plt&gt;
    1225:       48 89 45 e8             mov    QWORD PTR [rbp-0x18],rax


    ; Perform error checking
    1229:       48 83 7d e8 00          cmp    QWORD PTR [rbp-0x18],0x0

    ; Jump if no error
    122e:       79 16                   jns    1246 &lt;main+0xc1&gt;

    ; &lt;snip out error handling code&gt;

    ; A for loop starts here, that loops over the full buffer. This is a small
    ; optimization - it jumps to the bottom where the for loop's exit condition
    ; is checked
    124d:       eb 28                   jmp    1277 &lt;main+0xf2&gt;

    ; This loop is a super unoptimized way of doing:
    ; xor buffer[i], 0x41
    ; inc i
    124f:       8b 45 fc                mov    eax,DWORD PTR [rbp-0x4]
    1252:       48 63 d0                movsxd rdx,eax
    1255:       48 8b 45 f0             mov    rax,QWORD PTR [rbp-0x10]
    1259:       48 01 d0                add    rax,rdx
    125c:       0f b6 08                movzx  ecx,BYTE PTR [rax]
    125f:       8b 45 fc                mov    eax,DWORD PTR [rbp-0x4]
    1262:       48 63 d0                movsxd rdx,eax
    1265:       48 8b 45 f0             mov    rax,QWORD PTR [rbp-0x10]
    1269:       48 01 d0                add    rax,rdx
    126c:       83 f1 41                xor    ecx,0x41
    126f:       89 ca                   mov    edx,ecx
    1271:       88 10                   mov    BYTE PTR [rax],dl
    1273:       83 45 fc 01             add    DWORD PTR [rbp-0x4],0x1

    ; Eax = the next loop iterator
    1277:       8b 45 fc                mov    eax,DWORD PTR [rbp-0x4]
    127a:       48 98                   cdqe   

    ; Are we at the end of the loop?
    127c:       48 39 45 e8             cmp    QWORD PTR [rbp-0x18],rax

    ; Jump to the top until the loop is done
    1280:       7f cd                   jg     124f &lt;main+0xca&gt;

    ; Get the buffer and jump to it (same as Runme)
    1282:       48 8b 45 f0             mov    rax,QWORD PTR [rbp-0x10]
    1286:       ff d0                   call   rax
[...]
</pre>
When I was learning to reverse engineer, I got a ton of mileage out of compiling C code and looking at the resulting assembly to see what happens to loops and variables and stuff. So it might be illustrative to look at the source (which players wouldn't have had during the game):
<pre>  len = read(<span class="Number">0</span>, buffer, LENGTH);

  <span class="Conditional">if</span>(len &lt; <span class="Number">0</span>) {
    printf(<span class="String">"Error reading!</span><span class="SpecialChar">\n</span><span class="String">"</span>);
    exit(<span class="Number">1</span>);
  }

  <span class="Type">int</span> i;
  <span class="Repeat">for</span>(i = <span class="Number">0</span>; i &lt; len; i++) {
    buffer[i] ^= <span class="Number">0x41</span>;
  }

  <span class="Statement">asm</span>(<span class="String">"call *%0</span><span class="SpecialChar">\n</span><span class="String">"</span> : :<span class="String">"r"</span>(buffer));
</pre>
So basically, all that's doing is XORing each byte by 0x41. Let's write a <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/reverseme/solution/encode.rb">quick and inefficient encoder in Ruby</a>:
<pre><span class="Statement">loop</span> <span class="Statement">do</span>
  b = <span class="Identifier">STDIN</span>.read(<span class="Number">1</span>)
  <span class="Statement">if</span>(b.nil?)
    <span class="Statement">exit</span>(<span class="Number">0</span>)
  <span class="Statement">end</span>

  print (b.ord ^ <span class="Number">0x41</span>).chr
end
</pre>
And use it to encode the <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/runme/solution">shellcode from Runme</a>:
<pre>$ ruby ./reverseme-encoder.rb &lt; ./solution.bin | ./reverseme
Send me x64!!
CTF{fake_flag}
</pre>
That's it for part 1!
<h2>Reverseme2</h2>
Reverseme2 is very similar. Again, let's just use objdump:
<pre>$ objdump -D -M intel ./reverseme2/distfiles/reverseme2
[...]
    ; Call srand(0x13371337)
    1223:       bf 37 13 37 13          mov    edi,0x13371337
    1228:       e8 43 fe ff ff          call   1070 &lt;srand@plt&gt;

[...]

    ; Jump to the bottom of the loop (like last time)
    1277:       eb 38                   jmp    12b1 &lt;main+0x10c&gt;

    ; Top of the loop:

    ; Call rand()
    1279:       e8 22 fe ff ff          call   10a0 &lt;rand@plt&gt;

    ; Shift the return value from rand() right by three:
    127e:       c1 f8 03                sar    eax,0x3

    ; Take the right-most byte of the new value ...
    1281:       0f b6 c8                movzx  ecx,al

    1284:       8b 45 fc                mov    eax,DWORD PTR [rbp-0x4]
    1287:       48 63 d0                movsxd rdx,eax
    128a:       48 8b 45 f0             mov    rax,QWORD PTR [rbp-0x10]
    128e:       48 01 d0                add    rax,rdx
    1291:       0f b6 00                movzx  eax,BYTE PTR [rax]
    1294:       89 c2                   mov    edx,eax
    1296:       89 c8                   mov    eax,ecx
    1298:       89 d1                   mov    ecx,edx

    ; ... and xor it with the current byte
    129a:       31 c1                   xor    ecx,eax

    129c:       8b 45 fc                mov    eax,DWORD PTR [rbp-0x4]
    129f:       48 63 d0                movsxd rdx,eax
    12a2:       48 8b 45 f0             mov    rax,QWORD PTR [rbp-0x10]
    12a6:       48 01 d0                add    rax,rdx
    12a9:       89 ca                   mov    edx,ecx
    12ab:       88 10                   mov    BYTE PTR [rax],dl
    12ad:       83 45 fc 01             add    DWORD PTR [rbp-0x4],0x1

    ; Are we at the end of the loop?
    12b1:       8b 45 fc                mov    eax,DWORD PTR [rbp-0x4]
    12b4:       48 98                   cdqe   
    12b6:       48 39 45 e8             cmp    QWORD PTR [rbp-0x18],rax
    12ba:       7f bd                   jg     1279 &lt;main+0xd4&gt;
    12bc:       48 8b 45 f0             mov    rax,QWORD PTR [rbp-0x10]

    ; If so, call into the code
    12c0:       ff d0                   call   rax
[...]
</pre>
And once again, compare it to source:
<pre>  srand(<span class="Number">0x13371337</span>);
  <span class="Comment">//[...]</span>
  len = read(<span class="Number">0</span>, buffer, LENGTH);

  <span class="Comment">//[...]</span>

  <span class="Type">int</span> i;
  <span class="Repeat">for</span>(i = <span class="Number">0</span>; i &lt; len; i++) {
    buffer[i] ^= (rand() &gt;&gt; <span class="Number">3</span>) &amp; <span class="Number">0x0FF</span>;
  }

  <span class="Statement">asm</span>(<span class="String">"call *%0</span><span class="SpecialChar">\n</span><span class="String">"</span> : :<span class="String">"r"</span>(buffer));
</pre>
We can make <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/reverseme2/solution/encode.c">an encoder in C</a> using that exact code:
<pre><span class="Include">#include </span><span class="String">&lt;stdio.h&gt;</span>
<span class="Include">#include </span><span class="String">&lt;stdlib.h&gt;</span>
<span class="Include">#include </span><span class="String">&lt;unistd.h&gt;</span>

<span class="Type">int</span> main(<span class="Type">int</span> argc, <span class="Type">char</span> *argv[])
{
  <span class="Type">int</span> i;
  srand(<span class="Number">0x13371337</span>);
  <span class="Type">unsigned</span> <span class="Type">char</span> buffer[<span class="Number">4096</span>];

  <span class="Type">ssize_t</span> len = read(<span class="Number">0</span>, buffer, <span class="Number">4096</span>);

  <span class="Conditional">if</span>(len &lt; <span class="Number">0</span>) {
    printf(<span class="String">"Error reading!</span><span class="SpecialChar">\n</span><span class="String">"</span>);
    exit(<span class="Number">1</span>);
  }

  <span class="Repeat">for</span>(i = <span class="Number">0</span>; i &lt; len; i++) {
    buffer[i] ^= (rand() &gt;&gt; <span class="Number">3</span>) &amp; <span class="Number">0x0FF</span>;
    printf(<span class="String">"</span><span class="SpecialChar">%c</span><span class="String">"</span>, buffer[i]);
  }

  <span class="Statement">return</span> <span class="Number">0</span>;
}
</pre>
And execute it, once again with the same shellcode from runme:
<pre>$ ./reverseme2-encoder &lt; ./solution.bin | ./reverseme2
Send me (encoded) x64!!
CTF{fake_flag}
</pre>
<h2>Conclusion</h2>
I know that was pretty brief, I didn't want to dig TOO much more into a reversing challenge. I'm happy to answer any questions, though!
