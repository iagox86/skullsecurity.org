---
id: 887
title: Return of the Facebook Snatchers
date: '2010-07-26T21:44:32-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=887
permalink: "/2010/return-of-the-facebook-snatchers"
categories:
- hacking
- passwords
comments_id: '109638353732630633'

---

First and foremost: if you want to cut to the chase, just download the <a href='/blogdata/fbdata.torrent'>torrent</a>. If you want the full story, please read on....

<h2>Background</h2>
Way back when I worked at Symantec, my friend Nick wrote a blog that caused a little bit of trouble for us: <a href='http://www.symantec.com/connect/blogs/attack-facebook-snatchers'>Attack of the Facebook Snatchers</a>. I was blog editor at the time, and I went through the usual sign off process and, eventually, published it. Facebook was none too happy, but we fought for it and, in the end, we got to leave the blog up in its original form.

Why do I bring this up? Well last week <a href='https://twitter.com/FSLabsAdvisor'>@FSLabsAdvisor</a> wrote an interesting <a href='http://twitter.com/FSLabsAdvisor/status/18442678378'>Tweet</a>: it turns out, by heading to <a href='https://www.facebook.com/directory'>https://www.facebook.com/directory</a>, you can get a list of every searchable user on all of Facebook! 

My first idea was simple: spider the lists, generate first-initial-last-name (and similar) lists, then hand them over to <a href='https://twitter.com/ithilgore'>@Ithilgore</a> to use in Nmap's awesome new bruteforce tool he's working on, <a href='http://nmap.org/ncrack/'>Ncrack</a>. 
<!--more-->
But as I thought more about it, and talked to other people, I realized that this is a scary privacy issue. I can find the name of pretty much every person on Facebook. Facebook helpfully informs you that "[a]nyone can opt out of appearing here by changing their Search privacy settings" -- but that doesn't help much anymore considering I already have them all (and you will too, when you download the <a href='/blogdata/fbdata.torrent'>torrent</a>). Suckers!

Once I have the name and URL of a user, I can view, by default, their picture, friends, information about them, and some other details. If the user has set their privacy higher, at the very least I can view their name and picture. So, if any searchable user has friends that are non-searchable, those friends just opted into being searched, like it or not! Oops :) 

<h2>The lists</h2>
Which brings me to the next topic: the list! I wrote a <a href='/blogdata/facebook.rb'>quick Ruby script</a> (which has since become a more involved <a href='/blogdata/facebook.nse'>Nmap Script</a> that I haven't used for harvesting yet) that I used to download the full directory. I should warn you that it isn't exactly the most user friendly interface -- I wrote it for myself, primarily, I'm only linking to it for reference. I don't really suggest you try to recreate my spidering. It's a waste of several hundred gigs of bandwidth. 

The results were spectacular. <strong>171 million</strong> names (<strong>100 million</strong> unique). My original plan was to use this list to generate a <a href='/blogdata/facebook-f.last-withcount.txt.bz2'>list of the top usernames</a> (based on first initial last name):
<pre> 129369 jsmith
  79365 ssmith
  77713 skhan
  75561 msmith
  74575 skumar
  72467 csmith
  71791 asmith
  67786 jjohnson
  66693 dsmith
  66431 akhan
</pre>

Or <a href='/blogdata/facebook-first.l-withcount.txt.bz2'>first name last initial</a>:
<pre> 100225 johns
  97676 johnm
  97310 michaelm
  93386 michaels
  88978 davids
  85481 michaelb
  84824 davidm
  82677 davidb
  81500 johnb
  77800 michaelc
</pre>

Or even the top usernames based on first name dot last name (sorry, I can't link this one due to bandwidth concerns; but it's included in <a href='/blogdata/fbdata.torrent'>the torrent</a>):
<pre>  17204 john.smith
   7440 david.smith
   7200 michael.smith
   6784 chris.smith
   6371 mike.smith
   6149 arun.kumar
   5980 james.smith
   5939 amit.kumar
   5926 imran.khan
   5861 jason.smith
</pre>

Or even the most common <a href='/blogdata/facebook-firstnames-withcount.txt.bz2'>first</a> or <a href='/blogdata/facebook-lastnames-withcount.txt.bz2'>last</a> names:
<pre>
 977014 michael
 963693 john
 924816 david
 819879 chris
 640957 mike
 602088 james
 584438 mark
 515686 jason
 503658 robert
 484403 jessica

 913465 smith
 571819 johnson
 512312 jones
 503266 williams
 471390 brown
 386764 lee
 360010 khan
 355639 singh
 343220 kumar
 324972 miller
</pre>

So, those are the top 10 lists. But I'll bet you want everything!

<h2>The Torrent</h2>
But it occurred to me that this is public information that Facebook puts out, I'm assuming for search engines or whatever, and that it wouldn't be right for me to keep it private. Why waste Facebook's bandwidth and make everybody scrape it, right? 

So, I present you with: <strong><a href='/blogdata/fbdata.torrent'>a torrent</a></strong>! If you haven't download it, download it now! And seed it for as long as you can. 

This torrent contains:
<ul>
<li>The URL of every searchable Facebook user's profile</li>
<li>The name of every searchable Facebook user, both unique and by count (perfect for post-processing, datamining, etc)</li>
<li>Processed lists, including first names with count, last names with count, potential usernames with count, etc</li>
<li>The programs I used to generate everything</li>
</ul>

So, there you have it: lots of awesome data from Facebook. Now, I just have to find one more problem with Facebook so I can write "Revenge of the Facebook Snatchers" and complete the trilogy. Any suggestions? >:-)

<h2>Limitations</h2>
So far, I have only indexed the searchable users, not their friends. Getting their friends will be significantly more data to process, and I don't have those capabilities right now. I'd like to tackle that in the future, though, so if anybody has any bandwidth they'd like to donate, all I need is an ssh account and Nmap installed. 

An additional limitation is that these are only users whose first characters are from the latin charset. I plan to add non-Latin names in future releases. 
