---
id: 915
title: 'Regarding my Facebook research&#8230;'
date: '2010-08-10T13:57:35-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=915'
permalink: '/?p=915'
---

Hey all,

Some of you may have heard of me that I'm either an evil "[Facebook hacker](http://www.theatlanticwire.com/opinions/view/opinion/Hacker-Harvests-100M-Facebook-Profiles-and-Publishes-Data-Whos-At-Risk-4510)"or just some [mischievous individual doing "unsettling" research](http://www.telegraph.co.uk/technology/facebook/7919103/First-Wikileaks-now-Facebook.-Is-this-the-death-of-privacy.html). But, one way or the other, pretty much everybody has read the story.

Anyway, I want to talk about this from my perspective, including why I did it and what I think this means to the community and, finally, open up some discussion on what this means.

## Why I did it

As most of you probably know, I'm a developer for the [Nmap security scanner](http://nmap.org). Among many, many other things, I've written several of the [bruteforce (aka, 'auth') scripts](http://nmap.org/nsedoc/categories/auth.html).

When I first started doing that, Nmap had a fairly weak dictionary based on the [exposed Myspace passwords](http://downloads.skullsecurity.org/passwords/myspace.txt). Those passwords were sub-optimal because they were phished, not leaked/breached, which means passwords with messages to the phishers, like 'fuckyou', are artificially common (not to mention "suck my dick" and "piss off cracker head").

Sometime during that period, there were other password breaches such as [Phpbb](http://downloads.skullsecurity.org/passwords/phpbb.txt.bz2). Phpbb was hashed with md5 so converting it into a useful password list was a long process (that, I'm happy to report, is over 98% done). Then RockYou came along -- I'm not going to link to my RockYou list directly, because of the size, but it consists of 32 million plaintext passwords. From a password research perspective, that's amazing.

Anyway, while doing this work I set up a [password breaches page](http://skullsecurity.org/wiki/index.php/Passwords). Since I created it, I've had exceptionally good feedback about from researchers around the world. As far as I know, it's the best collection of breached passwords anywhere. Nmap's [current password list](http://nmap.org/svn/nselib/data/passwords.lst) is based on extensive research performed by Nmap developers based on our many lists.

Now, back to the Facebook names. There are actually two sides to the situation. The first, and most obvious, occurs when Nmap (or other tools such as Hydra and Medusa) are perform a password-guessing attack against a host. Before it can guess a password, the program requires a high-quality list of usernames. Those names could be harvested from the site (such as an email directory), they could be created using default usernames (such as 'administrator', 'web', 'guest', etc), or they could be chosen using lists of actual names. That's where this list comes in -- having a list of 10, 100, or 1000 names wouldn't help us much, because there are billions of people in the world, but having a sample of 170 million names is a great cross-section that gives us great insight into the most common names and, therefore, the most common usernames (who would have thought that 'jsmith' would be the most common?)

The second reason, however, continues my research into [how people choose passwords](http://www.skullsecurity.org/blog/?p=538). It's a well known fact to anybody in the security field that people will choose poor passwords. By studying the most common trends in password choice, we help teach people how to choose better passwords (and hopefully, someday, we'll find a way to eliminate passwords altogether). I don't have results that I'm comfortable with releasing yet, but I hope to put together some statistics in the future. Stay tuned!

## Getting out of control

The reason this whole situation got out of control, in my opinion, was due to a [story posted by the BBC](http://www.bbc.co.uk/news/technology-10796584). At the time the story was posted I was at Black Hat, and wasn't answering phonecalls due to ludicrous roaming charges that the Canadian telcos like to hit us with. Therefore, the reporter, Daniel Emery, posted the story as he understood it at the time. If you read that link, you'll see that it sounds a lot better in that story than in real life.

Fortunately, that night, me and Daniel had a great email conversation about the work I did. The result was [an updated story](http://www.bbc.co.uk/news/technology-10802730) that very clearly spells out my motivations and, in my opinion, is one of the best stories on the topic.

By then, though, the damage was done. [Hundreds of articles](http://news.google.ca/news/search?aq=f&pz=1&cf=all&ned=ca&hl=en&q=ron+bowes) were published. All for something that really wasn't a big deal.

## What's this data mean?

So, as I said, I collected exactly two pieces of data:

1. The names of 170 million users
2. The URL of those users

I did **NOT** collect email addresses, friends, private data, or anything else. And the URL might lead to nothing but a name and whatever picture the user chose -- that's what Facebook shares at a minimum. Downloading the actual profile pages of all the users, based on some quick calculations I made, would be about 3tb big. though I don't doubt that soembody is trying. :)

So now, I want to open up the discussion a little. I've been telling reporters (and everybody else) for several weeks now that this data doesn't mean anything, and is only interesting as a research project into common names. My challenge to you, the readers, is: **what more can be done with this data?**

I've had several email (and real-world) discussions with various people, all of whom will remain unnamed. Some were from businesses, some academia, and some news. Here are some thoughts:

- Businesses that publish names for a living (eg, baby names) might be interested in this data
- 