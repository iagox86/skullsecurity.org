---
id: 521
title: 'How big is the ideal dick&#8230;tionary?'
date: '2010-03-04T15:41:49-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=521'
permalink: '/?p=521'
---

Hey all,

As some of you know, I've been working on collecting leaked passwords/other dictionaries. I spent some time this week updating my wiki's [password page](http://www.skullsecurity.org/wiki/index.php/Passwords). Check it out and let me know what I'm missing, and I'll go ahead and mirror it.

I've had a couple new developments in my password list, though. Besides having an entirely new layout, I've added some really cool data!

## Rockyou.com passwords

One of the most exciting things, at least to me, is the Rockyou.com passwords ([story](http://techcrunch.com/2009/12/14/rockyou-hacked/)). Back in 2009 (I realize that's a long time ago -- my friends would yell 'OLD!' if I tried talking about it on IRC), 32.6 **million** passwords were stolen from Rockyou.com through, I believe, SQL injection. This attack was incredibly useful, at least from my perspective, because that's a HUGE number of passwords, they weren't encrypted/hashed, and there was no policy. So basically, it's a perfect cross section of the passwords people use when they aren't restricted.

I'm mirroring a few versions of the password list on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords), so go grab a copy if you want one (warning: it's 50mb+ compressed). Just for fun, the top 10 passwords, which were used by 2.10% of all users on rockyou.com were:

1. 123456
2. 12345
3. 123456789
4. password
5. iloveyou
6. princess
7. 1234567
8. rockyou
9. 12345678
10. abc123

## Password coverage

When talking about dictionary sizes, the question often comes up: does size really matter? The answer, I'm assured by experts is, 'yes'. But what's the ideal size (for sanctioned penetrations, of course)?

So, here's the question: how many accounts can be cracked with the top-X passwords? Let's start by looking at a graph:  
![](/blogdata/password-coverage.png)

As you can see, there's some definite diminishing returns there. I was actually excited that the graph looks exactly how I thought it'd look. Pretty sweet!

Now, let's look at it in less exciting and more useful table form:

|  | **Number of passwords** |  | **Coverage** |  |
|---|-------------------------|---|--------------|---|
|  | 1 |  | 0.89% |  |
|  | 2 |  | 1.13% |  |
|  | 5 |  | 1.71% |  |
|  | 10 |  | 2.10% |  |
|  | 20 |  | 2.54% |  |
|  | 50 |  | 3.47% |  |
|  | 100 |  | 4.57% |  |
|  | 200 |  | 6.05% |  |
|  | 500 |  | 8.73% |  |
|  | 1000 |  | 11.30% |  |
|  | 2000 |  | 14.34% |  |
|  | 5000 |  | 18.75% |  |
|  | 10000 |  | 22.30% |  |
|  | 20000 |  | 26.10% |  |
|  | 50000 |  | 31.85% |  |

What's that mean? It means that if you take the top 10 passwords, you'll crack 2.10% of accounts. The top 100 passwords will get you 4.57% of accounts, and so on. That's cool to know, but isn't as usual for penetration testing. Let's go by coverage instead of count (with a few options to download the password lists):

|  | **Passwords** |  | **Coverage** |  | **Download** |  |
|---|---------------|---|--------------|---|--------------|---|
|  | 1 |  | 0.89% |  |
|  | 2 |  | 1.13% |  |
|  | 8 |  | 2.00% |  |
|  | 33 |  | 2.99% |  |
|  | 72 |  | 4.01% |  |
|  | 125 |  | 4.99% |  | [rockyou-5.txt](http://downloads.skullsecurity.org/passwords/rockyou-5.txt) |  |
|  | 196 |  | 6.00% |  |
|  | 286 |  | 7.00% |  |
|  | 400 |  | 8.00% |  |
|  | 542 |  | 9.00% |  |
|  | 716 |  | 10.00% |  | [rockyou-10.txt](http://downloads.skullsecurity.org/passwords/rockyou-10.txt) |  |
|  | 928 |  | 11.00% |  |
|  | 1180 |  | 12.00% |  |
|  | 1486 |  | 13.00% |  |
|  | 1855 |  | 14.00% |  |
|  | 2300 |  | 14.99% |  | [rockyou-15.txt](http://downloads.skullsecurity.org/passwords/rockyou-15.txt) |  |
|  | 2840 |  | 16.00% |  |
|  | 3495 |  | 17.00% |  |
|  | 4291 |  | 18.00% |  |
|  | 5254 |  | 19.00% |  |
|  | 6409 |  | 20.00% |  | [rockyou-20.txt](http://downloads.skullsecurity.org/passwords/rockyou-20.txt) |  |
|  | 7787 |  | 21.00% |  |
|  | 9435 |  | 22.00% |  |
|  | 11404 |  | 23.00% |  |
|  | 13722 |  | 24.00% |  |
|  | 16450 |  | 25.00% |  | [rockyou-25.txt](http://downloads.skullsecurity.org/passwords/rockyou-25.txt) |  |

This is essentially the same table -- I just based the rows on the coverage instead of the number of passwords. With this table you can determine, for example, that to crack 10% of users' passwords, you need to try the top 716 passwords. I put the same table and links on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords).

## phpbb passwords

One last interesting change on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords) is the addition of Brandon Enright's cracked phpbb passwords. As I'm sure you all know, Phpbb had its password list stolen some time ago (closing in on two years, maybe?). Since then, Brandon has been diligently working to crack every single md5 password, and has mostly succeeded (over 97% cracked, I believe). He was kind enough to share that list with me, and it's now mirrored on my password page so check it out!