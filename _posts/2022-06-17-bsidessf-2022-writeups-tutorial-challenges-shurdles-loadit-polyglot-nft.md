---
id: 2624
title: 'BSidesSF 2022 Writeups: Tutorial Challenges (Shurdles, Loadit, Polyglot, NFT)'
date: '2022-06-17T15:19:14-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2624
permalink: "/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft"
categories:
- bsidessf-2022
- ctfs
comments_id: '109638383343300957'

---

<p>Hey folks,</p>
<p>This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything <a href="https://github.com/bsidessf/ctf-2022-release">on github</a>. Most have either a Dockerfile or instructions on how to run locally. Enjoy!</p>
<!--more-->
<p>Here are the four BSidesSF CTF blogs:</p>
<ul>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft">shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh">mod_ctfauth, refreshing</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme">turtle, guessme</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane">loca, reallyprettymundane</a></li>
</ul>
<h2>Shurdles - Shellcode Hurdles</h2>
<p>The <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/shurdles-1"><em>Shurdles</em></a> challenges are loosely based on a challenge from last year, <code>Hurdles</code>, as well as a <a href="https://www.holidayhackchallenge.com/2021/">Holiday Hack Challenge 2021</a> challenge I wrote called <em>Shellcode Primer</em>. It uses a tool I wrote called <a href="https://github.com/iagox86/mandrake">Mandrake</a> to instrument shellcode to tell the user what's going on. It's helpful for debugging, but even more helpful as a teaching tool!</p>
<p>The difference between this and the Holiday Hack version was that this time, I didn't bother to sandbox it, so you could pop a shell and inspect the box. I'm curious if folks did that.. probably they couldn't damage anything, and there's no intellectual property to steal. :)</p>
<p>I'm not going to write up the solutions, but I did include solutions in <a href="https://github.com/BSidesSF/ctf-2022-release">the repository</a>.</p>
<p>Although I don't work for Counter Hack anymore, a MUCH bigger version of this challenge that I wrote is included in the SANS NetWars version launching this year. It covers a huge amount, including how to write bind- and reverse-shell shellcode from  scratch. It's super cool! Unfortunately, I don't think SANS is doing hybrid events anymore, but if you find yourself at a SANS event be sure to check out NetWars!</p>
<h2>Loadit - Learning how to use <code>LD_PRELOAD</code></h2>
<p>I wanted to make a few challenges that can be solved with <code>LD_PRELOAD</code>, which is where <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/loadit1">loadit</a> came from! These are designed to be tutorial-style, so I think <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/loadit1/solution">the solutions</a> mostly speak for themselves.</p>
<p>One interesting tidbit is that the third <code>loadit</code> challenge requires some state to be kept - <code>rand()</code> needs to return several different values. I had a few folks ask me about that, so I'll show off my solution here:</p>
<pre><code class="language-c">#include &lt;unistd.h&gt;

int rand(void) {
  int answers[] = { 20, 22, 12, 34, 56, 67 };
  static int count = 0;

  return answers[count++];
}

// Just for laziness
unsigned int sleep(unsigned int seconds) {
  return 0;
}</code></pre>
<p>I use the <a href="https://www.geeksforgeeks.org/static-variables-in-c/">static variable type</a> to keep track of how many times rand() has been called. When you declare something as <code>static</code> inside a function, it means that the variable is initialized the first time the function is called, but changes are maintained as if it's a global variable (at least conceptually - in reality, it's initialized when the program is loaded, even if the function is never called).</p>
<p>Ironically, this solution actually has an overflow - the 7th time and onwards <code>rand()</code> is called, it will start manipulating random memory. Luckily, we know that'll never happen. :)</p>
<h2>Polyglot - Technically correct!</h2>
<p>Polyglot claims to be a polyglot. It's distributed as a .exe file. It runs fine-ish under <code>wine</code>:</p>
<pre><code>$ wine ./polyglot.exe
Figure out the polyglot and enter the key here --&gt; hello
?YCd;??x?&#039;B???)1???R7?e-?8????*#?????R?w</code></pre>
<p>If you look at the source, it'll be pretty obvious that it's XORing a 40-character key, provided by the user, with a 40-character &quot;encrypted&quot; string. If you make the logical assumption that the flag is <code>CTF{...36 characters…}</code>, you will find that the key is, <code>This????????????????????????????????????.</code>. That might be a hint!</p>
<p>So it turns out that every PE file (<code>*.exe</code>) is actually a Polyglot - it's an <a href="https://en.wikipedia.org/wiki/DOS_MZ_executable">MZ executable</a> with a <a href="https://en.wikipedia.org/wiki/Portable_Executable">PE executable</a> glued on. When you run the executable on Windows, it runs the PE portion, but when you run on DOS (or <a href="https://www.dosbox.com/">DOSBox</a>), it runs on the MZ portion.</p>
<p>If you run it in DOS mode, you'll instantly see the answer:</p>
<pre><code>c:\&gt; POLYGLOT.EXE
The password is: &quot;This program cannot be run in DOS mode.&quot;</code></pre>
<p>It's a bit of a troll, but easy enough to solve. :)</p>
<p>In case you're curious, here's the header:</p>
<pre><code class="language-asm">$ cat stub.asm 
ORG 0h ;# Offset 0, for NASM

push cs
pop ds

call thepasswordis
  ; db &quot;The password is: &#039;$&quot;
  db 0xab, 0x97, 0x9a, 0xdf, 0x8f, 0x9e, 0x8c, 0x8c, 0x88, 0x90, 0x8d, 0x9b, 0xdf, 0x96, 0x8c, 0xc5, 0xdf, 0xdd, 0xdb, 0

thepasswordis:
pop dx
mov cx, dx

decoder_top:
  cmp byte [ecx], 0
  je decoder_bottom
  xor byte [ecx], 0xff
  inc cx
  jmp decoder_top

decoder_bottom:
mov ah, 09
int 0x21

call cannotberun
  db &quot;This program cannot be run in DOS mode.$&quot;, 0

cannotberun:
pop dx
mov ah, 09
int 0x21

dec cx
dec cx
mov dx, cx
mov ah, 09
int 0x21

; # terminate the program
mov ax,0x4c01
int 0x21</code></pre>
<p>If you did Shurdles (see above), some of that will be familiar! Then I just used a <a href="https://github.com/BSidesSF/ctf-2022-release/blob/main/shurdles-1/challenge/src/app.rb">small Ruby script</a> to replace the start of the executable.</p>
<p>If you're interested in the PE format, be sure to check out <a href="TODO">the writeup for Loca</a>!</p>
<h2>Not for taking</h2>
<p><em>Not for taking</em> - or <em>NFT</em> - is just a joke challenge. It's a photo of my bird, with the flag embedded in the image like a caption. But! - the image is cropped by CSS so you can't see the flag, AND right clicking is disabled. So you have to view source (ctrl-u) or use developer tools (F12) or.. like 100 other ways to get it.</p>
