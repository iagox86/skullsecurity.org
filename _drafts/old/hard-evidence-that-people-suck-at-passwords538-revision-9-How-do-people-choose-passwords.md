---
id: 547
title: 'How do people choose passwords?'
date: '2010-03-06T17:34:27-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=547'
permalink: '/?p=547'
---

This will be a quick one, but I hope it's interesting!

As you probably know, I've been working hard on generating and evaluating passwords. [My last post](http://www.skullsecurity.org/blog/?p=516) was all about Rockyou.com's passwords; next post will (probably) be about different groups of passwords from my just updated [password dictionaries page](http://www.skullsecurity.org/wiki/index.php/Passwords). This will be a little different, though.

So, we all know that people frequently choose stupid passwords like 'password', '123456', etc. I'm sure a good part of the reason is that they just don't care. My mother, who isn't a tech savvy person and who rarely uses computers, was trying to get new games for her iPod today. When it prompted her for a password, we went through the semi-annual tradition of trying to figure out what we set. Since her credit card is linked to this account, it's a fairly important one.

I personally use the password 'password' or 'Password1' on a fairly regular basis when I create throwaway accounts. Lots of sites make you create accounts to download por... err, software (vmware comes to mind). Normally, if [Bugmenot](http://www.bugmenot.com/) doesn't have the proper password, I'll just fill out the forms with garbage info, a fake email, and a lazy password. And I'm sure I'm not the only one -- I wouldn't be surprised if that's where a lot of the really awful passwords came from.

Besides the common stupid passwords, people will often use the name of the site. [Rockyou.com's](http://downloads.skullsecurity.org/passwords/rockyou-withcount.txt) (WARNING: big download) 8th most popular password is 'rockyou', [phpbb's](http://downloads.skullsecurity.org/passwords/phpbb-withcount.txt) 3rd most popular password is 'phpbb', and [faithwriters'](http://downloads.skullsecurity.org/passwords/faithwriters-withcount.txt) 10th most popular password is 'faithwriters' (the second most popular is 'writer', which narrowly edges out 'jesus1'). My point is, if you're trying to protect your site, protect your users by using a blacklist [like Twitter does](http://downloads.skullsecurity.org/passwords/twitter-banned.txt) in addition to a good password policy. And, of course, if you're trying to break into a site, the name of the site is a great starting point!

On the topic of 'jesus1' being Faithwriters' second most common password, people tend to use passwords related to their hobbies, interests, etc. Ed Skoudis, Kevin Johnson, and others have spoken at length about harvesting passwords from social networking sites, and I don't doubt that you'll have amazing success if you do it. Just look at this comparison between [phpbb's password list](http://downloads.skullsecurity.org/passwords/phpbb-withcount.txt), [faithwriters.com's password list, and ](http://downloads.skullsecurity.org/passwords/faithwriters-withcount.txt)[elite-hackers.com's password list:](http://downloads.skullsecurity.org/passwords/elitehacker-withcount.txt)

|  | **phpbb** |  | **Faithwriters** |  | **Elite hackers** |  |
|---|-----------|---|------------------|---|-------------------|---|
|  | 1. 123456
2. password
3. phpbb
4. qwerty
5. 12345
6. 12345678
7. letmein
8. 111111
9. 1234
10. 123456789 |  | 1. 123456
2. writer
3. jesus1
4. christ
5. blessed
6. john316
7. jesuschrist
8. password
9. heaven
10. faithwriters |  | 1. 123456
2. password
3. 12345
4. passport
5. diablo
6. alpha
7. 12345678
8. 1
9. zxcvbnm
10. trustno1 |  |

So, some trends are pretty obvious here. phpbb, which a fairly neutral site in terms of its userbase, has a list of 10 pretty lame passwords (including 'phpbb', as we discussed).

Faithwriters has a bunch of passwords that are religious sounding, which makes sense because it's a religious site. Besides 'writer' and 'faithwriters', we see 'jesus1', 'christ', 'blessed', 'john316', etc. In fact, 6 of the top 10 passwords are religious in nature, and 8 of the top 10 passwords are ones you wouldn't expect to see anywhere else. And that's really the key here -- the majority if the passwords will \*not\* be found with a standard password dictionary, but \*will\* be found with a custom dictionary, tailored to the site!

And finally, elite-hackers.com's list has several of the usual stupid passwords, but has a couple that you wouldn't generally see, such as 'diablo', 'alpha', and, of course, [our favourite secret agent](http://en.wikipedia.org/wiki/Fox_Mulder)'s password, 'trustno1'.

So, this is some good hard data that supports something we've been saying for a long time: if you really want to get access to a network, build a custom password list based on what you know about them. You'll be happy you did!

PS: In case you're wondering, yes; my mom got her new games and all is well with my family.