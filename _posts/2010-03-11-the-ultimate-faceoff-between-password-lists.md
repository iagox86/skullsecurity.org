---
id: 549
title: 'The ultimate faceoff between password lists'
date: '2010-03-11T10:51:24-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=549'
permalink: /2010/the-ultimate-faceoff-between-password-lists
categories:
    - nmap
    - passwords
---

Yes, I'm still working on making the ultimate password list. And I don't mean the 16gb one I made by taking pretty much every word or word-looking string on the Internet when I was a kid; that was called ultimat<em>er</em> dictionary. No; I mean one that is streamlined, sorted, and will make Nmap the bruteforce tool of the future! 
<!--more-->
First, a sidenote: JHaddix from Security Aegis posted a <a href='http://www.securityaegis.com/easy-breezy-beautiful-password-attacking/'>story mentioning my password lists</a> and noted "I'd grab these lists if you dont already have them, who knows how long they will stay up." He makes a great point -- if I'm asked to remove these lists, I'll have no choice (for what it's worth, I don't see why I would; I cleared it with my ISP before hosting them). But, just in case, I wrapped everything up in a single tarball: <a href='http://downloads.skullsecurity.org/passwords/skullsecurity-lists.tar.bz2'>skullsecurity-lists.tar.bz2</a>. Weighing in at 132mb, it contains my whole collection of password lists. Feel free to grab it! If you want to pick and choose, as always, check out my <a href='http://www.skullsecurity.org/wiki/index.php/Passwords'>password page</a>. 

So anyway, on the subject of generating awesome password lists, Brandon Enright from the Nmap team is trying to come up with an algorithm to rank the different words in the different lists. Meanwhile, I spent some time graphing potential password dictionaries' success against leaked password lists to see which one was best. 

These are the dictionaries I used:
<ul>
<li><a href='http://downloads.skullsecurity.org/passwords/john.txt'>John the ripper</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/myspace.txt'>Myspace</a> (Nmap's original)</li>
<li><a href='http://downloads.skullsecurity.org/passwords/phpbb.txt'>Phpbb</a> (cracked by Brandon Enright)</li>
<li><a href='http://downloads.skullsecurity.org/passwords/rockyou.txt'>Rockyou.com</a> (my favourite; not that I'm biased)</li>
<li><a href='http://downloads.skullsecurity.org/passwords/conficker.txt'>Conficker</a> (which I already knew would suck)</li>
</ul>

And I put them up against some of the best leaked password lists I've collected:
<ul>
<li><a href='http://downloads.skullsecurity.org/passwords/rockyou.txt'>Rockyou</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/phpbb.txt'>Phpbb</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/hotmail.txt'>Hotmail</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/myspace.txt'>Myspace</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/hak5.txt'>Hak5</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/faithwriters.txt'>Faithwriters</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/elitehacker.txt'>Elitehackers</a></li>
<li><a href='http://downloads.skullsecurity.org/passwords/500-worst-passwords.txt'>500 worst passwords</a></li>
</ul>

(Obviously, where there's overlap, I didn't count the password cracking its own list; it wouldn't really be fair to crack Rockyou.com passwords using the Rockyou.com list -- I did that in <a href='http://www.skullsecurity.org/blog/?p=516'>an earlier blog</a> to measure coverage, though, if you want to check that out). 

Because we want smaller lists, I used the top 1, 10, 50, 100, 200, 500, 1000, 2000, and 5000 passwords from each list, and measured how many of the original passwords it would crack. The best possible result, obviously, is to have points at {100,100}, {1000,1000}, etc. (dependent on the size of the target list). Naturally, that didn't happen anywhere, but it was close on a couple (the phpbb password list, for example, almost perfectly cracked Rockyou.com -- more because Rockyou.com is big than because phpbb is complete, but you get the picture).

Enough talk, here are the results (note: each graph represents a target, and the lines represent the dictionaries):
<img src='/blogdata/cracked_rockyou.png'>
<img src='/blogdata/cracked_phpbb.png'>
<img src='/blogdata/cracked_hotmail.png'>
<img src='/blogdata/cracked_myspace.png'>
<img src='/blogdata/cracked_hak5.png'>
<img src='/blogdata/cracked_faithwriters.png'>
<img src='/blogdata/cracked_elitehackers.png'>
<img src='/blogdata/cracked_500worst.png'>

<h2>Conclusion</h2>
I think the conclusions here are:
<ul>
<li>Rockyou.com and phpbb are the best lists (props to Brandon for cracking the phpbb passwords!)</li>
<li>Conficker is a clear loser -- I wonder if Conficker would have done better if the authors spent more time generating its dictionary?</li>
<li>No dictionary is perfect -- no dictionary won in every match. That's why we need to rank words and make the perfect one!</li>
<li>OpenOffice.org 3 makes sexy graphs!</li>
</ul>

On the next episode of Skullsecurity.org..... why you need robots.txt if you're hosting dictionaries, especially German ones. 
