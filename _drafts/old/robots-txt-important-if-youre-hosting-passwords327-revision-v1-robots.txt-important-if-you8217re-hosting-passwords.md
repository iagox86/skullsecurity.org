---
id: 1682
title: 'robots.txt: important if you&#8217;re hosting passwords'
date: '2013-10-14T13:05:16-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/327-revision-v1'
permalink: '/?p=1682'
---

This is going to be a fun post that's related to some of my password work. Some of the text may not be PG13, so parental discretion is advised.

As most of you know, I've been collecting [password lists](http://www.skullsecurity.org/wiki/index.php/Passwords). In addition to normal password lists that are useful in bruteforcing, I have a (so far) lame collection of [non-hacking dictionaries](http://www.skullsecurity.org/wiki/index.php/Passwords#Miscellaneous_non-hacking_dictionaries). Things like cities, English words, etc.

There was a time when the biggest dictionary I had, weighing in at 6.4mb, was a [German wordlist](http://downloads.skullsecurity.org/passwords/german.txt). 6.4mb doesn't sound like much, but at the time I was on a DSL connection; with about 400kbit upstream (on a good day), I could feel every download.  
  
After awhile, I started realizing that german.txt was being downloaded pretty regularly. Far more regularly than any other lists. This didn't make any sense to me -- were German hackers stockpiling their tools before 202(c) came into effect? Were people interested in what Germans were using for passwords? Were people trying to cheat at German Boggle? I wasn't sure!

At that point, I removed the files and didn't worry too much about it. It wasn't worth hosting.

Fast forward a year or two. A friend of mine, who we affectionately call "The German", was doing some research into referer logs for different sites, and asked if he could have the referer log skullsecurity.org. I happily obliged, and asked him if he could figure out why so many people were downloading my German password list (he's German himself, after all). The referer entries he found made us laugh. There were thousands, but here are a few:

- http://www.google.de/search?q=1%20cm%20dicker%20anleimer%20wie%20hinlegen%20beim%20trocknen -> German\_list.txt
- http://www.google.de/search?q=Du%20singst%20shake%20your%20ass%20und%20wackelst%20mit%20dem%20kopf -> German\_list.txt
- http://www.google.de/search?q=schuh%20bode%20cowboy%20stiefel -> German\_list.txt
- http://www.google.de/search?q=Drillinge%2BIchstedt -> German\_list.txt
- http://www.google.de/search?q=porn+bemastung -> German\_list.txt
- http://www.google.de/search?q=masth%c3%bchner+von+gut+deutsch-nienhof -> German\_list.txt
- http://www.google.de/search?q=teuerste+sexpuppe+Real+Dolls+shop -> German\_list.txt
- http://www.google.de/search?q=lolita+sexfilm+ohne+jeglichen+geb%C3%BCrhen -> German\_list.txt

And, of course, my absolute favourite:

- http://www.google.de/search?q=porno+ porn+ comics+ cartoon+ hardcore+ gropers+ raped+ Asian+ porn,Asian+ porn+ movies,Asian+ porn+ video,Asian+ idol+ movies,Asian+ idol+ porn+ wild+ japan+ porn,+ asian+ porn+ videos,+ free+ japanese+ porn,+ asian+ sex+ movies,+ orienta+ porn,+ japan+ porn,+ asian+ porn,+ asian+ sex -> German\_list.txt

Now, I don't know German, and I'm pretty they aren't all questionable. Google Translate tells me that one is about cowboy boots. I do, however, recognize some somewhat more naughty words; words that really shouldn't be associated with my site.

So, the moral of the story is: hosting wordlists can get you some pretty interesting search results. If that's what you're into, let me know and I'll send you a list of keywords to put on your site. :)

Now? I host my passwords on a [separate domain](http://downloads.skullsecurity.org) with a [robots.txt](http://downloads.skullsecurity.org/robots.txt) file. No more wacky referers!