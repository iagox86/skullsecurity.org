---
id: 516
title: 'How big is the ideal dick&#8230;tionary?'
date: '2010-03-04T17:14:39-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=516'
permalink: /2010/how-big-is-the-ideal-dick-tionary
categories:
    - hacking
---

Hey all,

As some of you know, I've been working on collecting leaked passwords/other dictionaries. I spent some time this week updating my wiki's <a href='http://www.skullsecurity.org/wiki/index.php/Passwords'>password page</a>. Check it out and let me know what I'm missing, and I'll go ahead and mirror it. 

I've had a couple new developments in my password list, though. Besides having an entirely new layout, I've added some really cool data!
<!--more-->
<h2>Rockyou.com passwords</h2>
One of the most exciting things, at least to me, is the Rockyou.com passwords (<a href='http://techcrunch.com/2009/12/14/rockyou-hacked/'>story</a>). Back in 2009 (I realize that's a long time ago -- my friends would yell 'OLD!' if I tried talking about it on IRC), <strong>32.6 million</strong> passwords (<strong>14.3 million</strong> <em>unique</em> passwords) were stolen from Rockyou.com. These passwords were not encrypted/hashed and were stolen through, I believe, SQL injection. This attack was incredibly useful, at least from my perspective, because that's a HUGE number of passwords. Basically, it's a perfect cross section of the passwords people use when they aren't restricted. 

I'm mirroring a few versions of the Rockyou.com password list on my <a href='http://www.skullsecurity.org/wiki/index.php/Passwords'>password page</a>, so go grab a copy if you want one (the full list is 50mb+ compressed). Just for fun, the top 10 passwords, which were used by 4.66% of all users on Rockyou.com, were:
<ol>
<li>123456</li>
<li>12345</li>
<li>123456789</li>
<li>password</li>
<li>iloveyou</li>
<li>princess</li>
<li>1234567</li>
<li>rockyou</li>
<li>12345678</li>
<li>abc123</li>
</ol>

<h2>Password coverage</h2>
When talking about dictionary sizes, the question often comes up: does size really matter? The answer, I'm assured by experts is, 'yes'. But what's the ideal size (for sanctioned penetrations, of course)?

So, here's the question: how many accounts can be cracked with the top-X passwords? Let's start by looking at a graph:
<img src='/blogdata/password-coverage.png'>

As you can see, there's some definite diminishing returns there. I was actually excited that the graph looks exactly how I thought it'd look. Pretty sweet!

Now, let's look at in a less exciting but more useful table form:

<table style='border-width: 1px; border-spacing: 2px; border-color: gray; border-style: outset; border-collapse: separate; color: #c0c0c0; font-size: 10pt;'>
 <tr>
  <td width='80'><strong>Passwords</strong></td>
  <td width='80'><strong>Coverage</strong></td>
 </tr>
<tr><td>1</td><td>2.03%</td></tr>
<tr><td>2</td><td>2.58%</td></tr>
<tr><td>5</td><td>3.88%</td></tr>
<tr><td>10</td><td>4.66%</td></tr>
<tr><td>20</td><td>5.67%</td></tr>
<tr><td>50</td><td>7.83%</td></tr>
<tr><td>100</td><td>10.34%</td></tr>
<tr><td>200</td><td>13.71%</td></tr>
<tr><td>500</td><td>19.82%</td></tr>
<tr><td>1000</td><td>25.68%</td></tr>
<tr><td>2000</td><td>32.60%</td></tr>
<tr><td>5000</td><td>42.62%</td></tr>
<tr><td>10000</td><td>50.68%</td></tr>
<tr><td>20000</td><td>59.33%</td></tr>
<tr><td>50000</td><td>72.40%</td></tr>
</table>

What's that mean? It means that if you take the top 10 passwords, you would have cracked 4.66% of accounts on Rockyou.com. The top 100 passwords would have gotten you 10.34% of the Rockyou.com accounts, and so on. That's cool to know, but isn't as useful for penetration testing. Let's go by coverage instead of count (I've included links to the password files, as well -- the same links you'll find on my wiki):

<table style='border-width: 1px; border-spacing: 2px; border-color: gray; border-style: outset; border-collapse: separate; color: #c0c0c0; font-size: 10pt;'>
 <tr>
  <td width='120'><strong>Passwords</strong></td>
  <td width='120'><strong>Coverage</strong></td>
  <td width='300'><strong>Download</strong></td>
 </tr>
 
<tr><td>13</td><td>4.99%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-5.txt'>rockyou-5.txt</a> (104 bytes)</td></tr>
<tr><td>92</td><td>10.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-10.txt'>rockyou-10.txt</a> (723 bytes)</td></tr>
<tr><td>249</td><td>15.01%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-15.txt'>rockyou-15.txt</a> (1,943 bytes)</td></tr>
<tr><td>512</td><td>20.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-20.txt'>rockyou-20.txt</a> (3,998 bytes)</td></tr>
<tr><td>929</td><td>25.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-25.txt'>rockyou-25.txt</a> (7,229 bytes)</td></tr>
<tr><td>1556</td><td>30.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-30.txt'>rockyou-30.txt</a> (12,160 bytes)</td></tr>
<tr><td>2506</td><td>35.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-35.txt'>rockyou-35.txt</a> (19,648 bytes)</td></tr>
<tr><td>3957</td><td>40.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-40.txt'>rockyou-40.txt</a> (31,220 bytes)</td></tr>
<tr><td>6164</td><td>45.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-45.txt'>rockyou-45.txt</a> (49,133 bytes)</td></tr>
<tr><td>9438</td><td>50.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-50.txt'>rockyou-50.txt</a> (75,912 bytes)</td></tr>
<tr><td>14236</td><td>55.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-55.txt'>rockyou-55.txt</a> (115,186 bytes)</td></tr>
<tr><td>21041</td><td>60.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-60.txt'>rockyou-60.txt</a> (170,244 bytes)</td></tr>
<tr><td>30290</td><td>65.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-65.txt'>rockyou-65.txt</a> (244,535 bytes)</td></tr>
<tr><td>42661</td><td>70.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-70.txt'>rockyou-70.txt</a> (344,231 bytes)</td></tr>
<tr><td>59187</td><td>75.00%</td><td><a href='http://downloads.skullsecurity.org/passwords/rockyou-75.txt'>rockyou-75.txt</a> (478,948 bytes)</td></tr>
</table>

This is essentially the same table -- I just based the rows on the coverage instead of the number of passwords. With this table you can determine, for example, that to crack 10% of users' passwords, you only need to try the top 92 passwords. I put the same table and links on my <a href='http://www.skullsecurity.org/wiki/index.php/Passwords'>password page</a>. 

<h2>phpbb passwords</h2>
One last interesting change on my <a href='http://www.skullsecurity.org/wiki/index.php/Passwords'>password page</a> is the addition of Brandon Enright's cracked phpbb passwords. As I'm sure you all know, Phpbb had its password list stolen some time ago (closing in on two years, maybe?). Since then, Brandon has been diligently working to crack every single md5 password, and has mostly succeeded (over 97% cracked, I believe). He was kind enough to share that list with me, and it's now mirrored on my password page so check it out! 
