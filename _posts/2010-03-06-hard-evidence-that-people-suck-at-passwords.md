---
id: 538
title: 'Hard evidence that people suck at passwords'
date: '2010-03-06T17:26:07-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=538'
permalink: /2010/hard-evidence-that-people-suck-at-passwords
categories:
    - Passwords
---

Hey everybody! 

As you probably know, I've been working hard on generating and evaluating passwords. <a href='http://www.skullsecurity.org/blog/?p=516'>My last post</a> was all about Rockyou.com's passwords; next post will (probably) be about different groups of passwords from my just updated <a href='http://www.skullsecurity.org/wiki/index.php/Passwords'>password dictionaries page</a>. This will be a little different, though. 
<!--more-->
So, we all know that people frequently choose stupid passwords like 'password', '123456', etc. I'm sure a good part of the reason is that they just don't care. My mother, who isn't a tech savvy person and who rarely uses computers, was trying to get new games for her iPod today. When it prompted her for a password, we went through the semi-annual tradition of trying to figure out what we set. Since her credit card is linked to this account, it's a fairly important one. 

I personally use the password 'password' or 'Password1' on a fairly regular basis when I create throwaway accounts. Lots of sites make you create accounts to download por... err, software (VMWare comes to mind). Normally, if <a href='http://www.bugmenot.com/'>Bugmenot</a> doesn't have the proper password, I'll just fill out the forms with garbage info, a fake email, and a lazy password. And I'm sure I'm not the only one -- I wouldn't be surprised if that's where a lot of the really awful passwords came from. 

Besides the common stupid passwords, people will often use the name of the site. <a href='http://downloads.skullsecurity.org/passwords/rockyou-withcount.txt'>Rockyou.com's</a> (WARNING: big download) 8th most popular password is 'rockyou', <a href='http://downloads.skullsecurity.org/passwords/phpbb-withcount.txt'>phpbb's</a> 3rd most popular password is 'phpbb', and <a href='http://downloads.skullsecurity.org/passwords/faithwriters-withcount.txt'>faithwriters'</a> 10th most popular password is 'faithwriters' (the second most popular is 'writer', which narrowly edges out 'jesus1'). I suspect that phpbb has the highest ranked name simply because it's easy to type. My point is, if you're trying to protect your site, protect your users by using a blacklist <a href='http://downloads.skullsecurity.org/passwords/twitter-banned.txt'>like Twitter does</a> in addition to a good password policy. And, of course, if you're trying to break into a site, the name of the site is a great starting point!

On the topic of 'jesus1' being Faithwriters' second most common password, we all know that people tend to use passwords related to their hobbies, interests, etc. Ed Skoudis, Kevin Johnson, and others have spoken at length about harvesting passwords from social networking sites, and I don't doubt that you'll have amazing success if you do it. Just look at this comparison between <a href='http://downloads.skullsecurity.org/passwords/phpbb-withcount.txt'>phpbb's password list</a>, <a href='http://downloads.skullsecurity.org/passwords/faithwriters-withcount.txt'>faithwriters.com's password list</a>, and <a href='http://downloads.skullsecurity.org/passwords/elitehacker-withcount.txt'>elite-hackers.com's password list</a>:
<table>
<tr>
<td><strong>phpbb</strong></td>
<td><strong>Faithwriters</strong></td>
<td><strong>Elite hackers</strong></td>
</tr>
<tr>
<td><ol>
<li>123456</li>
<li>password</li>
<li>phpbb</li>
<li>qwerty</li>
<li>12345</li>
<li>12345678</li>
<li>letmein</li>
<li>111111</li>
<li>1234</li>
<li>123456789</li>
</ol></td>
<td><ol>
<li>123456</li>
<li>writer</li>
<li>jesus1</li>
<li>christ</li>
<li>blessed</li>
<li>john316</li>
<li>jesuschrist</li>
<li>password</li>
<li>heaven</li>
<li>faithwriters</li>
</ol></td>
<td><ol>
<li>123456</li>
<li>password</li>
<li>12345</li>
<li>passport</li>
<li>diablo</li>
<li>alpha</li>
<li>12345678</li>
<li>1</li>
<li>zxcvbnm</li>
<li>trustno1</li>
</ol></td>
</tr></table>

So, some trends are pretty obvious here. phpbb, which a fairly neutral site in terms of its userbase, has a list of 10 pretty lame passwords (including 'phpbb', as I mentioned earlier). 

Faithwriters has a bunch of passwords that are religious sounding, which makes sense because it's a religious site. Besides 'writer' and 'faithwriters', we see 'jesus1', 'christ', 'blessed', 'john316', etc. In fact, 6 of the top 10 passwords are religious in nature, and 8 of the top 10 passwords are ones you wouldn't expect to see anywhere else. And that's really the key here -- the majority if the passwords will *not* be found with a standard password dictionary, but *will* be found with a custom dictionary, tailored to the site! 

And finally, elite-hackers.com's list has several of the usual stupid passwords, but has a couple that you wouldn't generally see, such as 'diablo', 'alpha', and, of course, <a href='http://en.wikipedia.org/wiki/Fox_Mulder'>our favourite secret agent</a>'s password, 'trustno1'. 

So, this is some good hard data that supports something we've been saying for a long time: if you really want to get access to a network, build a custom password list based on what you know about them. You'll be happy you did! 

PS: In case you're wondering, yes; my mom remembered her iPod password and is happily playing her games. 
