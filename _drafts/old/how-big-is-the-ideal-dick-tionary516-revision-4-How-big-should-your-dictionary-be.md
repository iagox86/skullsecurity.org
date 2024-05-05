---
id: 520
title: 'How big should your dictionary be?'
date: '2010-03-04T15:21:02-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=520'
permalink: '/?p=520'
---

Hey all,

As some of you know, I've been working on collecting leaked passwords/other dictionaries. I spent some time this week updating my wiki's [password page](http://www.skullsecurity.org/wiki/index.php/Passwords). Check it out and let me know what I'm missing, and I'll go ahead and mirror it.

One of the most exciting things, at least to me, is the Rockyou.com passwords ([story](http://techcrunch.com/2009/12/14/rockyou-hacked/)). Back in 2009 (I realize that's a long time ago -- my friends would yell 'OLD!' if I tried talking about it on IRC), 32.6 **million** passwords were stolen from Rockyou.com through, I believe, SQL injection. This attack was incredibly useful, at least from my perspective, because that's a HUGE number of passwords, they weren't encrypted/hashed, and there was no policy. So basically, it's a look at the passwords people use when they aren't restricted.

I'm mirroring a few versions of the password list on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords), so go grab a copy if you want one (warning: it's 50mb+ compressed).

Now, onto the good stuff!

The top 10 passwords leaked on rockyou.com were:

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

In total, these ten passwords account for 2.10% of all passwords used by users. On that topic, how many passwords do you need to have reasonable coverage? Well, according to the Rockyou passwords, here are the number of passwords you need to try to get different amounts of coverage:

|  | Number of passwords |  | Coverage |  |
|---|---------------------|---|----------|---|
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

What's that mean? It means that if you take the top 10 passwords, you'll crack 2.10% of accounts. The top 100 passwords will get you 4.57% of accounts, and so on. To put it another way:

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
|  | 716 |  | 10.00% |  |
|  | 928 |  | 11.00% |  |
|  | 1180 |  | 12.00% |  |
|  | 1486 |  | 13.00% |  |
|  | 1855 |  | 14.00% |  |
|  | 2300 |  | 14.99% |  |
|  | 2840 |  | 16.00% |  |
|  | 3495 |  | 17.00% |  |
|  | 4291 |  | 18.00% |  |
|  | 5254 |  | 19.00% |  |
|  | 6409 |  | 20.00% |  |
|  | 7787 |  | 21.00% |  |
|  | 9435 |  | 22.00% |  |
|  | 11404 |  | 23.00% |  |
|  | 13722 |  | 24.00% |  |
|  | 16450 |  | 25.00% |  |

This is essentially the same table -- I just based the rows on the coverage instead of the number of passwords. With this table you can determine, for example, that to crack 10% of users' passwords, you need to try the top 716 passwords.

Finally, since everybody loves graphs, here's the same table in graphical format:  
![](/blogdata/password-coverage.png)

So that gives you some cold hard data to use when selecting your password list.