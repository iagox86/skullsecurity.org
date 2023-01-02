---
id: 2034
title: 'Defcon Quals: Access Control (simple reverse engineer)'
date: '2015-05-21T12:30:15-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2034'
permalink: /2015/defcon-quals-access-control-simple-reverse-engineer
categories:
    - defcon-quals-2015
---

Hello all,

Today's post will be another write-up from the <a href='https://legitbs.net'>Defcon CTF Qualifiers</a>. This one will be the level called "Access Client", or simply "client", which was a one-point reverse engineering level. This post is going to be mostly about the process I use for reverse engineering crypto-style code - it's a much different process than reversing higher level stuff, because each instruction matters and it's often extremely hard to follow.

Having just finished another level (<a href='/2015/defcon-quals-r0pbaby-simple-64-bit-rop'>r0pbaby</a>, I think), and having about an hour left in the competition, I wanted something I could finish quickly. There were two one-point reverse engineering challenges open that we hadn't solved: one was 64-bit and written in C++, whereas this one was 32-bit and C and only had a few short functions. The choice was easy. :)

I downloaded <a href='https://blogdata.skullsecurity.org/client'>the binary</a> and had a look at its strings. Lots of text-based stuff, such as "list users", "print key", and "connection id:", which I saw as a good sign!
<!--more-->
<h2>Running it</h2>

If you wnat to follow along, I uploaded all my work to <a href='https://github.com/iagox86/defcon-quals-2015/tree/master/client'>my Github page</a>, including a program called server.rb that more or less simulates the server. It's written in Ruby, obviously, and simulates all the responses. The real client can't actually read the flag from it, though, and I can't figure out why (and spent way too much time last night re-reversing the client binary before realizing it doesn't matter).

Anyway, when you run the client, it asks for an ip address:

<pre>
$ ./client
need IP
</pre>

The competition gives you a target, so that's easy (note that most of this is based on my own server.rb, not the real one, which I re-created from <a href='https://blogdata.skullsecurity.org/client.pcapng'>packet captures</a>:

<pre>
$ ./client 52.74.123.29
Socket created
Enter message : <strong>Hello</strong>
nope...Hello
</pre>

If you look at a packet capture of this, you'll see that a connection is made but nothing is sent or received. Local checks are best checks!

All right.. time for some reversing! I open up the client program in IDA, and go straight to the Strings tab (Shift-F12). I immediately see "Enter message :" so I double click it and end up here:

<pre>
<span class="Statement">.rodata</span>:080490F5</span> <span class="Comment">; char aEnterMessage[]</span>
<span class="Statement">.rodata</span>:080490F5</span> <span class="Identifier">aEnterMessage</span>   <span class="Identifier">db</span> '<span class="Identifier">Enter</span> <span class="Identifier">message</span> : ',<span class="Constant">0 </span><span class="Comment">; DATA XREF: main+178o</span>
<span class="Statement">.rodata</span>:08049106</span> <span class="Identifier">aHackTheWorld</span>   <span class="Identifier">db</span> '<span class="Identifier">hack</span> <span class="Identifier">the</span> <span class="Identifier">world</span>',0<span class="Identifier">Ah</span>,<span class="Constant">0 </span><span class="Comment">; DATA XREF: main+1A7o</span>
<span class="Statement">.rodata</span>:08049116</span> <span class="Comment">; char aNope_[]</span>
<span class="Statement">.rodata</span>:08049116</span> <span class="Identifier">aNope___S</span>       <span class="Identifier">db</span> '<span class="Identifier">nope</span>...%<span class="Identifier">s</span>',0<span class="Identifier">Ah</span>,<span class="Constant">0 </span>   <span class="Comment">; DATA XREF: main+1CAo</span>
</pre>

Could it really be that easy?

The answer, for a change, is yes:

<pre>
$ ./client 52.74.123.29
Socket created
Enter message : hack the world
&lt;&lt; connection ID: nuc EW1A IQr^2&


*** Welcome to the ACME data retrieval service ***
what version is your client?

&lt;&lt; hello...who is this?
&lt;&lt;

&lt;&lt; enter user password

&lt;&lt; hello grumpy, what would you like to do?
&lt;&lt;

&lt;&lt; grumpy
mrvito
gynophage
selir
jymbolia
sirgoon
duchess
deadwood
hello grumpy, what would you like to do?

&lt;&lt; the key is not accessible from this account. your administrator has been notified.
&lt;&lt;
hello grumpy, what would you like to do?
</pre>

Then it just sits there.

I logged the traffic with Wireshark and it looks like this (blue = incoming, red = outgoing, or you can just <a href="https://blogdata.skullsecurity.org/access.pcap">download my pcap</a>):

<pre>
<span style="color: blue">connection ID: Je@/b9~A&gt;Xa'R-</span>
<span style="color: blue"></span>
<span style="color: blue"></span>
<span style="color: blue">*** Welcome to the ACME data retrieval service ***</span>
<span style="color: blue">what version is your client?</span>
<span style="color: red">version 3.11.54</span>
<span style="color: blue">hello...who is this?</span><span style="color: red">grumpy</span>
<span style="color: blue"></span>
<span style="color: blue">enter user password</span>
<span style="color: red">H0L31</span>
<span style="color: blue">hello grumpy, what would you like to do?</span>
<span style="color: red">list users</span>
<span style="color: blue">grumpy</span>
<span style="color: blue">mrvito</span>
<span style="color: blue">gynophage</span>
<span style="color: blue">selir</span>
<span style="color: blue">jymbolia</span>
<span style="color: blue">sirgoon</span>
<span style="color: blue">duchess</span>
<span style="color: blue">deadwood</span>
<span style="color: blue">hello grumpy, what would you like to do?</span>
<span style="color: red">print key</span>
<span style="color: blue">the key is not accessible from this account. your administrator has been notified.</span>
<span style="color: blue">hello grumpy, what would you like to do?</span>
</pre>

<h2>Connection IDs and passwords</h2>

I surmised, based on this, that the connection id was probably random (it looks random) and that the password is probably hashed (poorly) and not replay-able (that'd be too easy). Therefore, the password is probably based on the connection id.

To verify the first part, I ran a capture a second time:

<pre>
connection ID: #2^1}P>JAqbsaj
[...]
hello...who is this?
grumpy
enter user password
V/%S:
</pre>

Yup, it's different!

I did some quick digging in IDA and found a function - sub_8048EAB - that was called with "grumpy" and "1" as parameters, as well as a buffer that would be sent to the server. It looked like it did some arithmetic on "grumpy" - which is presumably a password, and it touched a global variable - byte_804BC70 - that, when I investigated, turned out to be the connection id. The function was called from a second place, too, but we'll get to that later!

So now we've found a function that looks at the password and the connection id. That sounds like the hashing function to me (and note that I'm using the word "hashing" in its literal sense, it's obviously not a secure hash)! I could have used a debugger to verify that it was actually returning a hashed password, but the clock was ticking and I had to make some assumptions in order to keep moving - if the the assumptions turned out to be wrong, I wouldn't have finished the level, but I wouldn't have finished it either if I verified everything.

I wasn't entirely sure what had to be done from here, but it seemed logical to me that reverse engineering the password-hashing function was something I'd eventually have to do. So I got to work, figuring it couldn't hurt!

<h2>Reversing the hashing function</h2>

There are lots of ways to reverse engineer a function. Frequently, I take a higher level view of what libc/win32 functions it calls, but sub_8048EAB doesn't call any functions. Sometimes I'll try to understand the code, mentally, but I'm not super great at that. So I used a variation of this tried-and-true approach I often use for crypto code:

<ol>
  <li>Reverse each line of assembly to exactly one line of C</li>
  <li>Test it against the real version, preferably instrumented so I can automatically ensure that it's working properly</li>
  <li>While the output of my code is different from the output of their code, use a debugger (on the binary) and printf statements (on your implementation) to figure out where the problem is - this usually takes the most of my time, because there are usually several mistakes</li>
  <li>With the testing code still in place, simplify the C function as much as you can</li>
</ol>

Because I only had about an hour to reverse this, I had to cut corners. I reversed it to Ruby instead of C (so I wouldn't have to deal with sockets in C), I didn't set up proper instrumentation and instead used Wireshark, and I didn't simplify anything till afterwards. In the end, I'm not sure whether this was faster or slower than doing it "right", but it worked so I can't really complain.

<h2>Version 1</h2>

As I said, the first thing I do is translate the code directly, line by line, to assembly. I had to be a little creative with loops and pointers because I can't just use goto and cast everything to an integer like I would in C, but this is what it looked like. Note that I've fixed all the bugs that were in the original version - there were a bunch, but it didn't occur to me to keep the buggy code - I did, however, leave in the printf-style statements I used for debugging!

<pre>
<span class="Comment"># mode = 1 for passwords, 7 for keys</span>
<span class="rubyDefine">def</span> <span class="Identifier">hash_password</span>(password, connection_id, mode)
<span class="Comment"># mov     eax, [ebp+password]</span>
  eax = password

<span class="Comment"># mov     [ebp+var_2C], eax</span>
  var_2c = eax

<span class="Comment"># mov     eax, [ebp+buffer]</span>
  eax = <span class="Special">&quot;&quot;</span>

<span class="Comment"># mov     [ebp+var_30], eax</span>
  var_30 = <span class="Special">&quot;&quot;</span>

<span class="Comment"># xor     eax, eax</span>
  eax = <span class="Constant">0</span>

<span class="Comment"># mov     ecx, ds:g_connection_id_plus_7 ; 0x0000007d, but changes</span>
  ecx = connection_id[<span class="Constant">7</span>]
  <span class="Comment">#puts('%x' % ecx.ord)</span>

<span class="Comment"># mov     edx, 55555556h</span>
  edx = <span class="Constant">0x55555556</span>
<span class="Comment"># mov     eax, ecx</span>
  eax = ecx
<span class="Comment"># imul    edx</span>
  <span class="Comment">#puts(&quot;imul&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax.ord)</span>
  <span class="Comment">#puts(&quot;%x&quot; % edx)</span>
  edx = ((eax.ord * edx) &gt;&gt; <span class="Constant">32</span>)
  <span class="Comment">#puts(&quot;%x&quot; % edx)</span>
<span class="Comment"># mov     eax, ecx</span>
  eax = ecx
<span class="Comment"># sar     eax, 1Fh</span>
  <span class="Comment">#puts(&quot;sar&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax.ord)</span>
  eax = eax.ord &gt;&gt; <span class="Constant">0x1F</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax)</span>
<span class="Comment"># mov     ebx, edx</span>
  ebx = edx
<span class="Comment"># sub     ebx, eax</span>
  ebx -= eax
  <span class="Comment">#puts(&quot;sub&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % ebx)</span>
<span class="Comment"># mov     eax, ebx</span>
  eax = ebx
<span class="Comment"># mov     [ebp+var_18], eax</span>
  var_18 = eax
<span class="Comment"># mov     edx, [ebp+var_18]</span>
  edx = var_18
<span class="Comment"># mov     eax, edx</span>
  eax = edx
<span class="Comment"># add     eax, eax</span>
  eax = eax * <span class="Constant">2</span>
<span class="Comment"># add     eax, edx</span>
  eax = eax + edx

  <span class="Comment">#puts(&quot;&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax)</span>
<span class="Comment"># mov     edx, ecx</span>
  edx = ecx
<span class="Comment"># sub     edx, eax</span>
  <span class="Comment">#puts()</span>
  <span class="Comment">#puts(&quot;%x&quot; % ecx.ord)</span>
  <span class="Comment">#puts(&quot;%x&quot; % edx.ord)</span>
  edx = edx.ord - eax
  <span class="Comment">#puts(&quot;%x&quot; % edx)</span>
<span class="Comment"># mov     eax, edx</span>
  eax = edx
<span class="Comment"># mov     [ebp+var_18], eax</span>
  var_18 = eax
  <span class="Comment">#puts()</span>
  <span class="Comment">#puts(&quot;%x&quot; % var_18)</span>
<span class="Comment"># mov     eax, dword_804B04C</span>
  eax = mode
<span class="Comment"># add     [ebp+var_18], eax</span>
  var_18 += eax
  <span class="Comment">#puts(&quot;%x&quot; % eax)</span>
<span class="Comment"># mov     edx, offset g_connection_id ; &lt;--</span>
  edx = connection_id
<span class="Comment"># mov     eax, [ebp+var_18]</span>
  eax = var_18
<span class="Comment"># add     eax, edx</span>
<span class="Comment"># mov     dword ptr [esp+8], 5 ; n</span>
<span class="Comment"># mov     [esp+4], eax    ; src</span>
<span class="Comment"># lea     eax, [ebp+dest]</span>
<span class="Comment"># mov     [esp], eax      ; dest</span>
<span class="Comment"># call    _strncpy</span>
  dest = connection_id[var_18, <span class="Constant">5</span>]
  <span class="Comment">#puts(dest)</span>
<span class="Comment"># mov     [ebp+var_1C], 0</span>
  var_1c = <span class="Constant">0</span>

<span class="Comment"># jmp     short loc_8048F4A</span>
<span class="Comment"># loc_8048F2A:                            ; CODE XREF: do_password+A3j</span>
  <span class="Constant">0</span>.upto(<span class="Constant">4</span>) <span class="Statement">do</span> |<span class="Identifier">var_1c</span>|
<span class="Comment">#   mov     eax, [ebp+var_1C]</span>
    eax = var_1c
<span class="Comment">#   add     eax, [ebp+var_30]</span>
    <span class="Comment"># </span><span class="Todo">XXX</span>
<span class="Comment">#   lea     edx, [ebp+dest]</span>
    edx = dest

<span class="Comment">#   add     edx, [ebp+var_1C]</span>
<span class="Comment">#   movzx   ecx, byte ptr [edx]</span>
    ecx = edx[var_1c]
<span class="Comment">#   mov     edx, [ebp+var_1C]</span>
    edx = var_1c

<span class="Comment">#   add     edx, [ebp+var_2C]</span>
<span class="Comment">#   movzx   edx, byte ptr [edx]</span>
    edx = var_2c[var_1c]

<span class="Comment">#   xor     edx, ecx</span>
    edx = edx.ord ^ ecx.ord
<span class="Comment">#   mov     [eax], dl</span>
    edx &amp;= <span class="Constant">0x0FF</span>
    var_30[var_1c] = (edx &amp; <span class="Constant">0x0FF</span>).chr

<span class="Comment">#   add     [ebp+var_1C], 1</span>
<span class="Comment">#</span>
<span class="Comment">#   loc_8048F4A:                            ; CODE XREF: do_password+7Dj</span>
<span class="Comment">#   cmp     [ebp+var_1C], 4</span>
<span class="Comment">#   jle     short loc_8048F2A</span>
  <span class="Statement">end</span>

  <span class="Comment">#puts()</span>

  <span class="Statement">return</span> var_30
<span class="rubyDefine">end</span>
</pre>

After I got it working and returning the same value as the real implementation, I had a problem! The value I returned - even though it matched the real program - wasn't quite right! It had a few binary characters in it, whereas the value sent across the network never did. I looked around and found the function - sub_8048F67 - that actually sends the password to the server. It turns out, that function replaces all the low- and high-ASCII characters with proper ones (the added lines are in bold):

<pre>
<span class="Comment"># mode = 1 for passwords, 7 for keys</span>
<span class="rubyDefine">def</span> <span class="Identifier">hash_password</span>(password, connection_id, mode)
<span class="Comment"># mov     eax, [ebp+password]</span>
  eax = password

<span class="Comment"># mov     [ebp+var_2C], eax</span>
  var_2c = eax

<span class="Comment"># mov     eax, [ebp+buffer]</span>
  eax = <span class="Special">&quot;&quot;</span>

<span class="Comment"># mov     [ebp+var_30], eax</span>
  var_30 = <span class="Special">&quot;&quot;</span>

<span class="Comment"># xor     eax, eax</span>
  eax = <span class="Constant">0</span>

<span class="Comment"># mov     ecx, ds:g_connection_id_plus_7 ; 0x0000007d, but changes</span>
  ecx = connection_id[<span class="Constant">7</span>]
  <span class="Comment">#puts('%x' % ecx.ord)</span>

<span class="Comment"># mov     edx, 55555556h</span>
  edx = <span class="Constant">0x55555556</span>
<span class="Comment"># mov     eax, ecx</span>
  eax = ecx
<span class="Comment"># imul    edx</span>
  <span class="Comment">#puts(&quot;imul&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax.ord)</span>
  <span class="Comment">#puts(&quot;%x&quot; % edx)</span>
  edx = ((eax.ord * edx) &gt;&gt; <span class="Constant">32</span>)
  <span class="Comment">#puts(&quot;%x&quot; % edx)</span>
<span class="Comment"># mov     eax, ecx</span>
  eax = ecx
<span class="Comment"># sar     eax, 1Fh</span>
  <span class="Comment">#puts(&quot;sar&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax.ord)</span>
  eax = eax.ord &gt;&gt; <span class="Constant">0x1F</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax)</span>
<span class="Comment"># mov     ebx, edx</span>
  ebx = edx
<span class="Comment"># sub     ebx, eax</span>
  ebx -= eax
  <span class="Comment">#puts(&quot;sub&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % ebx)</span>
<span class="Comment"># mov     eax, ebx</span>
  eax = ebx
<span class="Comment"># mov     [ebp+var_18], eax</span>
  var_18 = eax
<span class="Comment"># mov     edx, [ebp+var_18]</span>
  edx = var_18
<span class="Comment"># mov     eax, edx</span>
  eax = edx
<span class="Comment"># add     eax, eax</span>
  eax = eax * <span class="Constant">2</span>
<span class="Comment"># add     eax, edx</span>
  eax = eax + edx

  <span class="Comment">#puts(&quot;&quot;)</span>
  <span class="Comment">#puts(&quot;%x&quot; % eax)</span>
<span class="Comment"># mov     edx, ecx</span>
  edx = ecx
<span class="Comment"># sub     edx, eax</span>
  <span class="Comment">#puts()</span>
  <span class="Comment">#puts(&quot;%x&quot; % ecx.ord)</span>
  <span class="Comment">#puts(&quot;%x&quot; % edx.ord)</span>
  edx = edx.ord - eax
  <span class="Comment">#puts(&quot;%x&quot; % edx)</span>
<span class="Comment"># mov     eax, edx</span>
  eax = edx
<span class="Comment"># mov     [ebp+var_18], eax</span>
  var_18 = eax
  <span class="Comment">#puts()</span>
  <span class="Comment">#puts(&quot;%x&quot; % var_18)</span>
<span class="Comment"># mov     eax, dword_804B04C</span>
  eax = mode
<span class="Comment"># add     [ebp+var_18], eax</span>
  var_18 += eax
  <span class="Comment">#puts(&quot;%x&quot; % eax)</span>
<span class="Comment"># mov     edx, offset g_connection_id ; &lt;--</span>
  edx = connection_id
<span class="Comment"># mov     eax, [ebp+var_18]</span>
  eax = var_18
<span class="Comment"># add     eax, edx</span>
<span class="Comment"># mov     dword ptr [esp+8], 5 ; n</span>
<span class="Comment"># mov     [esp+4], eax    ; src</span>
<span class="Comment"># lea     eax, [ebp+dest]</span>
<span class="Comment"># mov     [esp], eax      ; dest</span>
<span class="Comment"># call    _strncpy</span>
  dest = connection_id[var_18, <span class="Constant">5</span>]
  <span class="Comment">#puts(dest)</span>
<span class="Comment"># mov     [ebp+var_1C], 0</span>
  var_1c = <span class="Constant">0</span>

<span class="Comment"># jmp     short loc_8048F4A</span>
<span class="Comment"># loc_8048F2A:                            ; CODE XREF: do_password+A3j</span>
  <span class="Constant">0</span>.upto(<span class="Constant">4</span>) <span class="Statement">do</span> |<span class="Identifier">var_1c</span>|
<span class="Comment">#   mov     eax, [ebp+var_1C]</span>
    eax = var_1c
<span class="Comment">#   add     eax, [ebp+var_30]</span>
    <span class="Comment"># </span><span class="Todo">XXX</span>
<span class="Comment">#   lea     edx, [ebp+dest]</span>
    edx = dest

<span class="Comment">#   add     edx, [ebp+var_1C]</span>
<span class="Comment">#   movzx   ecx, byte ptr [edx]</span>
    ecx = edx[var_1c]
<span class="Comment">#   mov     edx, [ebp+var_1C]</span>
    edx = var_1c

<span class="Comment">#   add     edx, [ebp+var_2C]</span>
<span class="Comment">#   movzx   edx, byte ptr [edx]</span>
    edx = var_2c[var_1c]

<span class="Comment">#   xor     edx, ecx</span>
    edx = edx.ord ^ ecx.ord
<span class="Comment">#   mov     [eax], dl</span>
    edx &amp;= <span class="Constant">0x0FF</span>
<strong>
    <span class="Comment">#puts(&quot;before edx = %x&quot; % edx)</span>
    <span class="Statement">if</span>(edx &lt; <span class="Constant">0x1f</span>)
      <span class="Comment">#puts(&quot;a&quot;)</span>
      edx += <span class="Constant">0x20</span>
    <span class="Statement">elsif</span>(edx &gt; <span class="Constant">0x7F</span>)
      edx = edx - <span class="Constant">0x7E</span> + <span class="Constant">0x20</span>
    <span class="Statement">end</span>
    <span class="Comment">#puts(&quot;after edx = %x&quot; % edx)</span>
</strong>
    var_30[var_1c] = (edx &amp; <span class="Constant">0x0FF</span>).chr

<span class="Comment">#   add     [ebp+var_1C], 1</span>
<span class="Comment">#</span>
<span class="Comment">#   loc_8048F4A:                            ; CODE XREF: do_password+7Dj</span>
<span class="Comment">#   cmp     [ebp+var_1C], 4</span>
<span class="Comment">#   jle     short loc_8048F2A</span>
  <span class="Statement">end</span>

  <span class="Comment">#puts()</span>

  <span class="Statement">return</span> var_30
<span class="rubyDefine">end</span>
</pre>

As you can see, it's quite long and difficult to follow. But, now that the bugs were fixed, it was outputting the same thing as the real version! I set it up to log in with the username 'grumpy' and the password 'grumpy' and it worked great!

<h2>Cleaning it up</h2>

I didn't actually clean up the code until after the competition, but here's the step-by-step cleanup that I did, just so I could blog about it.

First, I removed all the comments:

<pre>
<span class="rubyDefine">def</span> <span class="Identifier">hash_password_phase2</span>(password, connection_id, mode)
  eax = password
  var_2c = eax
  eax = <span class="Special">&quot;&quot;</span>
  var_30 = <span class="Special">&quot;&quot;</span>
  eax = <span class="Constant">0</span>
  ecx = connection_id[<span class="Constant">7</span>]
  edx = <span class="Constant">0x55555556</span>
  eax = ecx
  edx = ((eax.ord * edx) &gt;&gt; <span class="Constant">32</span>)
  eax = ecx
  eax = eax.ord &gt;&gt; <span class="Constant">0x1F</span>
  ebx = edx
  ebx -= eax
  eax = ebx
  var_18 = eax
  edx = var_18
  eax = edx
  eax = eax * <span class="Constant">2</span>
  eax = eax + edx

  edx = ecx
  edx = edx.ord - eax
  eax = edx
  var_18 = eax
  eax = mode
  var_18 += eax
  edx = connection_id
  eax = var_18
  dest = connection_id[var_18, <span class="Constant">5</span>]
  var_1c = <span class="Constant">0</span>

  <span class="Constant">0</span>.upto(<span class="Constant">4</span>) <span class="Statement">do</span> |<span class="Identifier">var_1c</span>|
    eax = var_1c
    edx = dest
    ecx = edx[var_1c]
    edx = var_1c
    edx = var_2c[var_1c]
    edx = edx.ord ^ ecx.ord
    edx &amp;= <span class="Constant">0x0FF</span>
    <span class="Statement">if</span>(edx &lt; <span class="Constant">0x1f</span>)
      edx += <span class="Constant">0x20</span>
    <span class="Statement">elsif</span>(edx &gt; <span class="Constant">0x7F</span>)
      edx = edx - <span class="Constant">0x7E</span> + <span class="Constant">0x20</span>
    <span class="Statement">end</span>
    var_30[var_1c] = (edx &amp; <span class="Constant">0x0FF</span>).chr
  <span class="Statement">end</span>
  <span class="Statement">return</span> var_30
<span class="rubyDefine">end</span>
</pre>

Then I started eliminating redundant statements:

<pre>
<span class="rubyDefine">def</span> <span class="Identifier">hash_password_phase3</span>(password, connection_id, mode)
  ecx = connection_id[<span class="Constant">7</span>]
  eax = ecx
  edx = ((eax.ord * <span class="Constant">0x55555556</span>) &gt;&gt; <span class="Constant">32</span>)
  eax = ecx
  eax = eax.ord &gt;&gt; <span class="Constant">0x1F</span>
  eax = ((edx - (eax.ord &gt;&gt; <span class="Constant">0x1F</span>)) * <span class="Constant">2</span>) + edx

  edx = ecx
  edx = edx.ord - eax
  eax = edx
  var_18 = eax
  var_18 += mode
  edx = connection_id
  eax = var_18
  dest = connection_id[var_18, <span class="Constant">5</span>]

  result = <span class="Special">&quot;&quot;</span>
  <span class="Constant">0</span>.upto(<span class="Constant">4</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
    eax = i
    edx = dest
    ecx = edx[i]
    edx = password[i]
    edx = edx.ord ^ ecx.ord
    edx &amp;= <span class="Constant">0x0FF</span>
    <span class="Statement">if</span>(edx &lt; <span class="Constant">0x1f</span>)
      edx += <span class="Constant">0x20</span>
    <span class="Statement">elsif</span>(edx &gt; <span class="Constant">0x7F</span>)
      edx = edx - <span class="Constant">0x7E</span> + <span class="Constant">0x20</span>
    <span class="Statement">end</span>
    result &lt;&lt; (edx &amp; <span class="Constant">0x0FF</span>).chr
  <span class="Statement">end</span>

  <span class="Statement">return</span> result
<span class="rubyDefine">end</span>
</pre>

Removed some more redundancy:

<pre>
<span class="rubyDefine">def</span> <span class="Identifier">hash_password_phase4</span>(password, connection_id, mode)
  char_7 = connection_id[<span class="Constant">7</span>].ord
  edx = ((char_7 * <span class="Constant">0x55555556</span>) &gt;&gt; <span class="Constant">32</span>)
  eax = ((edx - (char_7 &gt;&gt; <span class="Constant">0x1F</span> &gt;&gt; <span class="Constant">0x1F</span>)) * <span class="Constant">2</span>) + edx

  result = <span class="Special">&quot;&quot;</span>
  <span class="Constant">0</span>.upto(<span class="Constant">4</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
    edx = (password[i].ord ^ connection_id[char_7 - eax + mode + i].ord) &amp; <span class="Constant">0xFF</span>

    <span class="Statement">if</span>(edx &lt; <span class="Constant">0x1f</span>)
      edx += <span class="Constant">0x20</span>
    <span class="Statement">elsif</span>(edx &gt; <span class="Constant">0x7F</span>)
      edx = edx - <span class="Constant">0x7E</span> + <span class="Constant">0x20</span>
    <span class="Statement">end</span>
    result &lt;&lt; (edx &amp; <span class="Constant">0x0FF</span>).chr
  <span class="Statement">end</span>

  <span class="Statement">return</span> result
<span class="rubyDefine">end</span>
</pre>

And a final cleanup pass where I eliminated the "bad paths" - things that I know can't possibly happen:

<pre>
<span class="rubyDefine">def</span> <span class="Identifier">hash_password_phase5</span>(password, connection_id, mode)
  char_7 = connection_id[<span class="Constant">7</span>].ord

  result = <span class="Special">&quot;&quot;</span>
  <span class="Constant">0</span>.upto(<span class="Constant">4</span>) <span class="Statement">do</span> |<span class="Identifier">i</span>|
    edx = password[i].ord ^ connection_id[i + char_7 - (((char_7 * <span class="Constant">0x55555556</span>) &gt;&gt; <span class="Constant">32</span>) * <span class="Constant">3</span>) + mode].ord
    <span class="Statement">if</span>(edx &lt; <span class="Constant">0x1f</span>)
      edx += <span class="Constant">0x20</span>
    <span class="Statement">elsif</span>(edx &gt; <span class="Constant">0x7F</span>)
      edx = edx - <span class="Constant">0x7E</span> + <span class="Constant">0x20</span>
    <span class="Statement">end</span>
    result &lt;&lt; edx.chr
  <span class="Statement">end</span>

  <span class="Statement">return</span> result
<span class="rubyDefine">end</span>

</pre>

And that's the final product! Remember, at each step of the way I was testing and re-testing to make sure it worked for a few dozen test strings. That's important because it's really, really easy to miss stuff.

<h2>The rest of the level</h2>

Now, getting back to the level...

As we saw above, after logging in, the real client sends "list users" then "print key". "print key" fails because the user doesn't have administrative rights, so presumably one of the users printed out on the "list users" page does.

I went through and manually entered each user into the program, with the same username as password (seemed like the thing to do, since grumpy's password was "grumpy") until I reached the user "duchess". When I tried "duchess", I got the prompt:

<pre>
challenge: /\&[$
answer?
</pre>

When I was initially reversing the password hashing, I noticed that the hash_password() function was called a second time near the strings "challenge:" and "answer?"! The difference was that instead of passing the integer 1 as the mode, it passed 7. So I tried calling hash_password('/\&amp;[$', connection_id, 7) and got the response, "&lt;=}-^".

I sent that, and the key came back! Here's the full session:

<pre>
connection ID: Tk8)k)e3a[vzN^


*** Welcome to the ACME data retrieval service ***
what version is your client?
version 3.11.54
hello...who is this?
duchess
enter user password
/MJ#L
hello duchess, what would you like to do?
print key
challenge: /\&[$
answer?
&lt;=}-^
the key is: The only easy day was yesterday. 44564
</pre>

I submitted the key with literally three minutes to go. I was never really sure if I was doing the right thing at each step of the way, but it worked!

<h2>An alternate solution</h2>

If I'd had the presence of mind to realize that the username would always be the password, there's another obvious solution to the problem that probably would have been a whole lot easier.

The string "grumpy" (as both the username and the password) is only read in three different places in the binary. It would have been fairly trivial to:

<ol>
  <li>Find a place in the binary where there's some room (right on top of the old "grumpy" would be fine)</li>
  <li>Put the string "duchess" in this location (and the other potential usernames if you don't yet know which one has administrative access)</li>
  <li>Patch the three references to "grumpy" to point to the new string instead of the old one - unfortunately, using a new location instead of just overwriting the strings is necessary because "duchess" is longer than "grumpy" so there's no room</li>
  <li>Run the program and let it get the key itself</li>
</ol>

That would have been quicker and easier, but I wasn't confident enough that the usernames and passwords would be the same, and I didn't want to risk going down the wrong path with almost no time left, so I decided against trying that.

<h2>Conclusion</h2>

This wasn't the most exciting level I've ever done, but it was quick and gave me the opportunity to do some mildly interesting reverse engineering.

The main idea was to show off my process - translate line by line, instrument it, debug till it works, then refactor and reduce and clean up the code!
