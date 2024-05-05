---
id: 534
title: 'How big is the ideal dick&#8230;tionary?'
date: '2010-03-04T17:08:59-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=534'
permalink: '/?p=534'
---

Hey all,

As some of you know, I've been working on collecting leaked passwords/other dictionaries. I spent some time this week updating my wiki's [password page](http://www.skullsecurity.org/wiki/index.php/Passwords). Check it out and let me know what I'm missing, and I'll go ahead and mirror it.

I've had a couple new developments in my password list, though. Besides having an entirely new layout, I've added some really cool data!

## Rockyou.com passwords

One of the most exciting things, at least to me, is the Rockyou.com passwords ([story](http://techcrunch.com/2009/12/14/rockyou-hacked/)). Back in 2009 (I realize that's a long time ago -- my friends would yell 'OLD!' if I tried talking about it on IRC), **32.6 million** passwords (**14.3 million** *unique* passwords) were stolen from Rockyou.com. These passwords were not encrypted/hashed and were stolen through, I believe, SQL injection. This attack was incredibly useful, at least from my perspective, because that's a HUGE number of passwords. Basically, it's a perfect cross section of the passwords people use when they aren't restricted.

I'm mirroring a few versions of the Rockyou.com password list on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords), so go grab a copy if you want one (warning: it's 50mb+ compressed). Just for fun, the top 10 passwords, which were used by 4.66% of all users on rockyou.com were:

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

Now, let's look at in a less exciting but more useful table form:

|  | **Passwords** |  | **Coverage** |  |
|---|---------------|---|--------------|---|
|  | 1 |  | 2.03% |  |
|  | 2 |  | 2.58% |  |
|  | 5 |  | 3.88% |  |
|  | 10 |  | 4.66% |  |
|  | 20 |  | 5.67% |  |
|  | 50 |  | 7.83% |  |
|  | 100 |  | 10.34% |  |
|  | 200 |  | 13.71% |  |
|  | 500 |  | 19.82% |  |
|  | 1000 |  | 25.68% |  |
|  | 2000 |  | 32.60% |  |
|  | 5000 |  | 42.62% |  |
|  | 10000 |  | 50.68% |  |
|  | 20000 |  | 59.33% |  |
|  | 50000 |  | 72.40% |  |

What's that mean? It means that if you take the top 10 passwords, you'll crack 4.66% of accounts. The top 100 passwords will get you 10.34% of accounts, and so on. That's cool to know, but isn't as usual for penetration testing. Let's go by coverage instead of count (I've included links to the password files, as well -- the same links you'll find on my wiki):

|  | **Passwords** |  | **Coverage** |  | **Download** |  |
|---|---------------|---|--------------|---|--------------|---|
|  | 13 |  | 4.99% |  | [rockyou-5.txt](http://downloads.skullsecurity.org/passwords/rockyou-.5txt) (104 bytes) |  |
|  | 92 |  | 10.00% |  | [rockyou-10.txt](http://downloads.skullsecurity.org/passwords/rockyou-10.txt) (723 bytes) |  |
|  | 249 |  | 15.01% |  | [rockyou-15.txt](http://downloads.skullsecurity.org/passwords/rockyou-15.txt) (1,943 bytes) |  |
|  | 512 |  | 20.00% |  | [rockyou-20.txt](http://downloads.skullsecurity.org/passwords/rockyou-20.txt) (3,998 bytes) |  |
|  | 929 |  | 25.00% |  | [rockyou-25.txt](http://downloads.skullsecurity.org/passwords/rockyou-25.txt) (7,229 bytes) |  |
|  | 1556 |  | 30.00% |  | [rockyou-30.txt](http://downloads.skullsecurity.org/passwords/rockyou-30.txt) (12,160 bytes) |  |
|  | 2506 |  | 35.00% |  | [rockyou-35.txt](http://downloads.skullsecurity.org/passwords/rockyou-35.txt) (19,648 bytes) |  |
|  | 3957 |  | 40.00% |  | [rockyou-40.txt](http://downloads.skullsecurity.org/passwords/rockyou-40.txt) (31,220 bytes) |  |
|  | 6164 |  | 45.00% |  | [rockyou-45.txt](http://downloads.skullsecurity.org/passwords/rockyou-45.txt) (49,133 bytes) |  |
|  | 9438 |  | 50.00% |  | [rockyou-50.txt](http://downloads.skullsecurity.org/passwords/rockyou-50.txt) (75,912 bytes) |  |
|  | 14236 |  | 55.00% |  | [rockyou-55.txt](http://downloads.skullsecurity.org/passwords/rockyou-55.txt) (115,186 bytes) |  |
|  | 21041 |  | 60.00% |  | [rockyou-60.txt](http://downloads.skullsecurity.org/passwords/rockyou-60.txt) (170,244 bytes) |  |
|  | 30290 |  | 65.00% |  | [rockyou-65.txt](http://downloads.skullsecurity.org/passwords/rockyou-65.txt) (244,535 bytes) |  |
|  | 42661 |  | 70.00% |  | [rockyou-70.txt](http://downloads.skullsecurity.org/passwords/rockyou-70.txt) (344,231 bytes) |  |
|  | 59187 |  | 75.00% |  | [rockyou-75.txt](http://downloads.skullsecurity.org/passwords/rockyou-75.txt) (478,948 bytes) |  |

This is essentially the same table -- I just based the rows on the coverage instead of the number of passwords. With this table you can determine, for example, that to crack 10% of users' passwords, you need to try the top 716 passwords. I put the same table and links on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords).

## phpbb passwords

One last interesting change on my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords) is the addition of Brandon Enright's cracked phpbb passwords. As I'm sure you all know, Phpbb had its password list stolen some time ago (closing in on two years, maybe?). Since then, Brandon has been diligently working to crack every single md5 password, and has mostly succeeded (over 97% cracked, I believe). He was kind enough to share that list with me, and it's now mirrored on my password page so check it out!