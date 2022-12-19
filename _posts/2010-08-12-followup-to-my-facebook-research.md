---
id: 898
title: 'Followup to my Facebook research'
date: '2010-08-12T09:52:24-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=898'
permalink: /2010/followup-to-my-facebook-research
categories:
    - Passwords
---

Hey all,

Some of you may have heard what I did this month. It turns out, depending on who you listen to, that I'm either an evil "[Facebook hacker](http://www.theatlanticwire.com/opinions/view/opinion/Hacker-Harvests-100M-Facebook-Profiles-and-Publishes-Data-Whos-At-Risk-4510)" or just some [mischievous individual doing "unsettling" research](http://www.telegraph.co.uk/technology/facebook/7919103/First-Wikileaks-now-Facebook.-Is-this-the-death-of-privacy.html). But, one way or the other, a huge number of people have read or heard this story, and that's pretty cool.

Although it's awesome (and humbling) that so much attention was paid (at least for a couple days) to some fairly straight forward work I did, I want to talk about this from my perspective, including why I did it and what I think this means to the community. Then, for fun, I'll end by talking about other places this research can go and open up the floor for some discussion.

## Why I did it

The biggest question I get is: why? -- and it's a valid question. Why would I "expose" public data to the public? And, do I get this excited every year when I get the new phonebook?

Well, let's talk about it!

First off, as many of you know, I'm a developer for the [Nmap security scanner](http://nmap.org). Among many, many other things, I've written several of the [bruteforce](http://nmap.org/nsedoc/categories/auth.html) (aka, 'auth') scripts, which are designed to test password strength on a system. The [Ncrack](http://nmap.org/ncrack) tool, a recent addition to the Nmap suite written by [Ithilgore](https://twitter.com/ithilgore), is primarily designed to test password strength by guessing username/password combinations, much like [Hydra](http://freeworld.thc.org/thc-hydra/) and [Medusa](http://www.foofus.net/~jmk/medusa/medusa.html).

When I joined the Nmap project, it came with a set of 8 or so common usernames and a couple hundred common passwords. The original password list, put together by Kris Katterjohn, was entirely based on some [exposed MySpace passwords](http://downloads.skullsecurity.org/passwords/myspace.txt). Those passwords were sub-optimal because they were phished, not leaked/breached, which means passwords with messages to the phishers, like "fuckyou", are artificially common (not to mention "suck my dick" and "piss off cracker head" -- I highly suggest searching the list for swear words and body parts, it's actually really amusing).

Fortunately for us, as password researchers, there were several more password breaches around that same time. One of the most interesting from a research perspective, due to it being the biggest breach at the time (with 188,000 records), was [Phpbb](http://downloads.skullsecurity.org/passwords/phpbb.txt.bz2). The Phpbb passwords hashed with md5 so converting them into a useful password list was a long process (that, I'm happy to report, is over 98% done -- not by me).

Not too long after the Phpbb breach, RockYou came along. I'm not going to link to my RockYou list directly, because of the size, but it consists of 32 million plaintext passwords and you can find it on my [passwords page](http://www.skullsecurity.org/wiki/index.php/Passwords). From a password research perspective, we couldn't have asked for better data.

Anyway, with all these breaches, keeping track of the lists became a hassle. So, like anybody who doesn't want to do the work himself, I set up a [wiki page](http://skullsecurity.org/wiki/index.php/Passwords) to keep track of my lists. Since I created it, I've had exceptionally good feedback about from researchers around the world. As far as I know, it's the best collection of breached passwords anywhere. Nmap's [current password list](http://nmap.org/svn/nselib/data/passwords.lst) is based on extensive research performed by Nmap developers based on our many lists.

Now, back to the Facebook names. There are actually two sides to the situation. The first, and most obvious, occurs when Nmap (or the other tools I mentioned) are performing a password-guessing audit against a host. Before it can guess a password, the program requires a high-quality list of usernames. Those names could be harvested from the site (such as an email directory), they could be created using default usernames lists (such as 'administrator', 'web', 'user', 'guest', etc), or they could be chosen using lists of actual names (such as 'jsmith' or 'rbowes'). That's where this list comes in -- having a list of 10, 100, or 1000 names wouldn't help us much, because there are billions of people in the world, but having a sample of 170 million names is a great cross-section that gives us great insight into the most common names and, therefore, the most common usernames (who would have thought that 'jsmith' would be the most common?)

The second reason, however, is more interesting to me because it continues my research into [how people choose passwords](http://www.skullsecurity.org/blog/?p=538). It's a well known fact to anybody in the security field that people choose poor passwords. By studying the most common trends in password choices, we help teach people how to choose better passwords (and hopefully, someday, we'll find a way to eliminate passwords altogether). I hope to put together some numbers showing how many people use passwords based on names. Although I don't have results that I'm comfortable with releasing yet, I hope to put together some statistics in the future. Stay tuned for that!

## Getting out of control

I hope now you have some insight into my motives. It was some simple research, how did it become so popular?

Well, the first reason is because when I wrote the [the original blog I posted on the subject](http://www.skullsecurity.org/blog/?p=887), I was somewhat careless with my language. As a result, people got the wrong impression and thought I had a lot more data than I actually did. As you can see in the [original story posted by the BBC](http://www.bbc.co.uk/news/technology-10796584), the whole situation sounded a lot more exciting, and controversial, than it actually was.

Now, at the time that these stories were running, I wasn't at home. In fact, I on that particular day, I was at the Grand Canyon. Now, why would I post some interesting research the day before I was going to the Grand Canyon? Well, all I can say is that planning ahead is overrated. :)

Anyway, because I was out of town, and Canadian telcos charge ludicrous roaming fees, I wasn't in a hurry to answer phonecalls or spend time on the phone doing an interview. Therefore, despite making attempts to contact me, the reporter from the BBC, Daniel Emery, ended up posting the story as he understood it at the time.

Fortunately, that night, me and Daniel had a great email conversation about the work I did. The result was [an updated story](http://www.bbc.co.uk/news/technology-10802730) that very clearly spells out my motivations and, in my opinion, is one of the best stories on the topic.

By then, though, the damage was done. [Hundreds of articles](http://news.google.ca/news/search?aq=f&pz=1&cf=all&ned=ca&hl=en&q=ron+bowes) were published. All for something that really wasn't a big deal.

I'm thankful, though, that Facebook's response aligned with mine, and that they didn't make any kind of an attempt to pursue legal action or request that I remove the information or anything else. That's a far better response than I'd expected, to be honest, and I have to thank Facebook for that (even if they didn't invite me to their Defcon party ;) ).

## What's this data mean?

So, as I said, I collected exactly two pieces of data:

1. The names of 170 million users
2. The URL of those users

I did **NOT** collect email addresses, friends, private data, public data, or anything else. And the URL might lead to nothing but a name and whatever picture the user chose -- that's what Facebook shares at a minimum. Downloading the actual profile pages of all the users, based on some quick calculations I made, would be about 3tb big. Of course, I don't doubt that somebody is trying. :)

So now, I want to open up the discussion a little. I've been telling reporters (and everybody else) since it started that this data doesn't mean anything, and is only interesting as a research project into common names. My challenge to you, the readers, is: **what more can be done with this data?**

I've had several email (and real-world) discussions with various people, all of whom will remain unnamed. Some were from businesses, some academia, and some media. Here are some thoughts people have run by me (if you see something that you don't want publicized, please let me know and I'll remove it from this page; I tried to keep these vague enough not to upset anybody, though):

- A business person suggested that companies who publish names for a living (eg, common baby names) might be interested in this data
- Other social network sites might want to check overlaps and/or build links between profiles on their site and Facebook
- In a blog comment, somebody suggested, and is working on, downloading profile pictures for facial recognition
- On IRC, we discussed the possibility of analyzing the user IDs, included in the URLs, to see if it's possible to enumerate non-searchable accounts
- A researcher suggested using this data to study the [name letter effect](http://en.wikipedia.org/wiki/Name_letter_effect), though I haven't collected enough information for that to be useful
- Similarly, names themselves can be indicative of race/culture -- could this be used for targeted advertising?

So, those are some ideas to expand this research, some of which are actually being worked on right now. And don't get me wrong, those are good ideas, but I'd really like to get some more. Why should we, whether we're security researchers, media, academics, etc, care about having a list of 170,000,000 names and URLs? What can we get from aggregating this data that we didn't have before? What can a good person do with it? What about an evil person?

I'd love to hear most opinions!