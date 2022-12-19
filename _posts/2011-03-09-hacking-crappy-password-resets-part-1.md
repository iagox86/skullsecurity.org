---
id: 1054
title: 'Hacking crappy password resets (part 1)'
date: '2011-03-09T09:14:05-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1054'
permalink: /2011/hacking-crappy-password-resets-part-1
categories:
    - Hacking
    - Passwords
    - Tools
---

Greetings, all!

This is part one of a two-part blog on password resets. For anybody who saw my talk (or watched [the video](http://vimeo.com/20718776)) from [Winnipeg Code Camp](http://www.winnipegcodecamp.com/), some of this will be old news (but hopefully still interesting!)

For this first part, I'm going to take a closer look at some very common (and very flawed) code that I've seen in on a major "snippit" site and contained in at least 5-6 different applications (out of 20 or so that I reviewed). The second blog will focus on a single application that does something much worse.

## Password reset?

First off, what is a password reset? You probably know this already, so feel free to skip to the next section for the good stuff.

Many sites offer a feature for users who forgot their passwords. They click a link, and it sends them a temporary password (or, for some sites, it changes their site password to a temporary password, effectively locking out the user till they check their email).

These generally work by generating a one-time password/token/etc, and emailing it to the address on record. The legitimate user receives the email, and clicks the link/uses the temp password/etc to log back into their account, at which point they ought to (or are forced to) change their password.

Some reset schemes require the user to answer their "secret questions", which often involves knowing information that nobody else ([except Facebook](http://en.wikipedia.org/wiki/Sarah_Palin_email_hack)) knows. I'm not a fan of the "secret question" and "secret answer" strategy myself, and they were torn apart by experts after Sarah Palin's email was compromised, so we aren't going to talk about them.

It is widely known that passwords are the weakest point in most security systems. Well, as it turns out, password resets are often the weakest point in password schemes. No matter how good your password policies, login procedures, etc are, a bad password reset can compromise an entire system. Here's a few ways:

- Poorly chosen random passwords (that's what this post is about)
- Poorly validated email addresses (can I reset the password to \*my\* address?)
- Relying entirely on secret questions/answers (Palin hack)
- Not extending brute-force protection (or logging) to the reset tokens

The last point is somewhat interesting, but none of the reset schemes I found in applications used reset tokens so I'm not going to cover them.

## Methodology

To do this research, I found a large repository of PHP projects, clicks on the "blogs" category, and downloaded a whole bunch of them. In the end, I had about 20 different applications. I didn't keep a list, but from memory, I found the following:

- 10 had no accounts, no passwords, or no ability to recover passwords
- 6 used a password-reset function that is somewhat weak and very common (and can be found on snippits sites) - the scheme that I'm covering this week
- 3 emailed back the passwords in plaintext
- 1 used a \*really\* bad reset scheme (that's the one I'm covering next post)

## Motivation

Let's say you compromise a site (for a legitimate and ethical penetration test, of course). You wind up with 1,000,000 accounts from a database that happens to use this password generation technique (either for password resets or for generating initial passwords). Rather than wasting time cracking these passwords, you want to eliminate every "generated" password from the list. How can you do that?

Or another scenario: you realize that a company's corporate "password generator" toolbar utility is using this algorithm to generate "secure" passwords within a company. Knowing that some users are going to misuse this utility, and use the same "strong" passwords on multiple accounts, you compromise a weak host, crack a user's 14-character "random" password, then use that to log into their other systems.

How the heck do we crack a 14-character random password, you ask? Let's fine out!

## The code

We're going to focus on the six or so sites that used a common password reset function. Here's the snippit:

```

<font color="#ffa500"><?php</font><br></br>
  <font color="#ff80ff">function</font> generate_random_password<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font><font color="#ffa500">)</font><br></br>
  <font color="#ffa500">{</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font> <font color="#ffff60"><b>=</b></font> '<font color="#ffa0a0">abcdefghijkmnopqrstuvwxyz023456789!@#$</font>';<br></br>
<br></br>
    <font color="#40ffff">srand</font><font color="#ffa500">((</font><font color="#60ff60"><b>double</b></font><font color="#ffa500">)</font><font color="#40ffff">microtime</font><font color="#ffa500">()</font> <font color="#ffff60"><b>*</b></font> <font color="#ffa0a0">1000000</font><font color="#ffa500">)</font>;<br></br>
<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>=</b></font> '';<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars_length</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font><font color="#ffa500">)</font> <font color="#ffff60"><b>-</b></font> <font color="#ffa0a0">1</font>;<br></br>
<br></br>
    <font color="#ffff60"><b>for</b></font> <font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b><</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font><font color="#ffa500">)</font><br></br>
        <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>.=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>, <font color="#ffa500">(</font><font color="#40ffff">rand</font><font color="#ffa500">()</font> <font color="#ffff60"><b>%</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars_length</font><font color="#ffa500">)</font>, <font color="#ffa0a0">1</font><font color="#ffa500">)</font>;<br></br>
<br></br>
    <font color="#ffff60"><b>return</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font>;<br></br>
  <font color="#ffa500">}</font><br></br>
<font color="#ffa500">?></font><br></br>
```

At first glance, this didn't look too bad. I was a little disappointed, to be honest. Using srand() in modern PHP versions isn't recommended, but it appears to be seeded with a high-resolution timer - that could make it difficult to guess. In theory.

If you were to generate a password with strong randomization and a decent length (say, 14 characters), even with a fast/weak hashing algorithm like md5 it'll be nearly impossible to crack. We need a better way!

I decided to look at how strong the seed passed to srand() actually was. To do this, I replaced srand() with echo():

```

<font color="#ffa500"><?php</font><br></br>
  <font color="#ffff60"><b>for</b></font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b><</b></font> <font color="#ffa0a0">3</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font><font color="#ffa500">)</font><br></br>
  <font color="#ffa500">{</font><br></br>
    <font color="#ff80ff">echo</font><font color="#ffa500">((</font><font color="#60ff60"><b>double</b></font><font color="#ffa500">)</font><font color="#40ffff">microtime</font><font color="#ffa500">()</font> <font color="#ffff60"><b>*</b></font> <font color="#ffa0a0">1000000</font><font color="#ffa500">)</font>;<br></br>
    <font color="#ff80ff">echo</font> "<font color="#ffa500">\n</font>";<br></br>
  <font color="#ffa500">}</font><br></br>
<font color="#ffa500">?></font><br></br>
```

Then ran the application a few times to get an idea of how the seed worked:

```
$ php srand.php
155118
155198
155213
$ php srand.php
898454
898536
898552
$ php srand.php
673755
673844
673860
```

Hmm! It looks like the random seed is actually a fairly hard-to-guess integer between 0 and 1,000,000. Fortunately, 1,000,000 is a small number. Suddenly, this is a lot easier.

In my next blog, I'm going to look at how we can use commandline tools to do a bruteforce remotely and guess a password this way, but for now let's see how we can crack the passwords using two methods: php and john the ripper.

## Cracking it with PHP

If for whatever reason you only have a single hash that you want to crack, this is by far the easiest way. I basically modified the original function (found above) to take an extra parameter - the hash - and to generate random passwords with different seeds until it finds one that matches. Here's the code:

```

<font color="#ffa500"><?php</font><br></br>
  <font color="#ff80ff">function</font> generate_random_password<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">hash</font><font color="#ffa500">)</font><br></br>
  <font color="#ffa500">{</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font> <font color="#ffff60"><b>=</b></font> '<font color="#ffa0a0">abcdefghijkmnopqrstuvwxyz023456789!@#$</font>';<br></br>
<br></br>
    <font color="#ffff60"><b>for</b></font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font> <font color="#ffff60"><b><</b></font> <font color="#ffa0a0">1000000</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font><font color="#ffff60"><b>++</b></font><font color="#ffa500">)</font><br></br>
    <font color="#ffa500">{</font><br></br>
      <font color="#40ffff">srand</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font><font color="#ffa500">)</font>;<br></br>
<br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>=</b></font> '';<br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars_length</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font><font color="#ffa500">)</font> <font color="#ffff60"><b>-</b></font> <font color="#ffa0a0">1</font>;<br></br>
<br></br>
      <font color="#ffff60"><b>for</b></font> <font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b><</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font><font color="#ffa500">)</font><br></br>
          <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>.=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>, <font color="#ffa500">(</font><font color="#40ffff">rand</font><font color="#ffa500">()</font> <font color="#ffff60"><b>%</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars_length</font><font color="#ffa500">)</font>, <font color="#ffa0a0">1</font><font color="#ffa500">)</font>;<br></br>
<br></br>
      <font color="#ffff60"><b>if</b></font><font color="#ffa500">(</font><font color="#40ffff">md5</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font><font color="#ffa500">)</font> <font color="#ffff60"><b>==</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">hash</font><font color="#ffa500">)</font><br></br>
        <font color="#ffff60"><b>return</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font>;<br></br>
    <font color="#ffa500">}</font><br></br>
  <font color="#ffa500">}</font><br></br>
<font color="#ffa500">?></font><br></br>
```

Basically, we generate all million possible passwords and figure out which one it is. Easy!

I wrote a couple little test programs that basically just call those functions to confirm it works:

$ php password\_reset.php 14  
Generated a 14-character, random password: 4fx@xpxtuos6ee (md5: ef949c5bd59359a5403caafa95d3c5f9)  
$ php password\_reset.php 14  
Generated a 14-character, random password: 95h76tio0vbuh4 (md5: 8ad7fa746f82d90bee2bc38783ad7981)  
$ php password\_reset.php 20  
Generated a 20-character, random password: qnhbk95a8m2sqvwrzieb (md5: 1a902b5f425555446186f346a62c7a53)

Now normally, all three of these would be impossible to crack. Typically, a 14-character password, chosen from a set of 38 different characters, has 13,090,925,539,866,773,438,464 different possibilities. Fortunately, as we saw earlier, the rand() is seeded with only a million possible seeds, and a million is definitely bruteforceable!

We've already seen the function to crack the passwords, so let's try it out:

```
$ php ./password_reset_crack.php 14 ef949c5bd59359a5403caafa95d3c5f9
The password is: 4fx@xpxtuos6ee
$ php ./password_reset_crack.php 14 8ad7fa746f82d90bee2bc38783ad7981
The password is: 95h76tio0vbuh4
$ php ./password_reset_crack.php 20 1a902b5f425555446186f346a62c7a53
The password is: qnhbk95a8m2sqvwrzieb
```

And it isn't slow, either:

```
$ time php ./password_reset_crack.php 20 1a902b5f425555446186f346a62c7a53
The password is: qnhbk95a8m2sqvwrzieb

real    0m3.732s
user    0m3.709s
sys     0m0.005s
```

So basically, we cracked a 20-character "random" password in under 4 seconds, w00t! (or, to quote a new friend, "WOOP WOOP WOOP WOOP")

## Cracking with john

Let's say that instead of three passwords, you have a thousand. In fact, let's generate a whole bunch! You can [try it yourself](/blogdata/14_character_hashes.txt.bz2), too. The file contains 5000 passwords in raw-md5 format (with a few duplicates thanks in part to the [Birthday Paradox](http://en.wikipedia.org/wiki/Birthday_paradox)). We're going to use john the ripper 1.7.6 with the Jumbo patch to try cracking them. By default, john fails miserably:

```

$ ./john --format=raw-md5 ./14_character_hashes.txt
Loaded 5000 password hashes with no different salts (Raw MD5 [raw-md5 64x1])
guesses: 0  time: 0:00:00:31 (3)  c/s: 20900M  trying: tenoeuf - tenoey5
Session aborted
```

Even at 20,000,000,000 checks/second, it's getting nothing. I can leave it all day and it will get nothing. These passwords are pretty much impossible to crack with brute force.

Now let's let john in on the secret and tell it the 1,000,000 possible passwords!

The first thing we do is write a quick php application to generate them:

```

<font color="#ffa500"><?php</font><br></br>
  <font color="#ff80ff">function</font> generate_random_password<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font><font color="#ffa500">)</font><br></br>
  <font color="#ffa500">{</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font> <font color="#ffff60"><b>=</b></font> '<font color="#ffa0a0">abcdefghijkmnopqrstuvwxyz023456789!@#$</font>';<br></br>
<br></br>
    <font color="#ffff60"><b>for</b></font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font> <font color="#ffff60"><b><</b></font> <font color="#ffa0a0">1000000</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font><font color="#ffff60"><b>++</b></font><font color="#ffa500">)</font><br></br>
    <font color="#ffa500">{</font><br></br>
      <font color="#40ffff">srand</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">j</font><font color="#ffa500">)</font>;<br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>=</b></font> '';<br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars_length</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font><font color="#ffa500">)</font> <font color="#ffff60"><b>-</b></font> <font color="#ffa0a0">1</font>;<br></br>
<br></br>
      <font color="#ffff60"><b>for</b></font> <font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b><</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font><font color="#ffa500">)</font><br></br>
          <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>.=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>, <font color="#ffa500">(</font><font color="#40ffff">rand</font><font color="#ffa500">()</font> <font color="#ffff60"><b>%</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars_length</font><font color="#ffa500">)</font>, <font color="#ffa0a0">1</font><font color="#ffa500">)</font>;<br></br>
      <font color="#ff80ff">echo</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">passwd</font> <font color="#ffff60"><b>.</b></font> "<font color="#ffa500">\n</font>";<br></br>
    <font color="#ffa500">}</font><br></br>
  <font color="#ffa500">}</font><br></br>
<br></br>
  generate_random_password<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">argv</font><font color="#ffa500">[</font><font color="#ffa0a0">1</font><font color="#ffa500">])</font>;<br></br>
<font color="#ffa500">?></font><br></br>
```

Then run it to prove it works:

```
$ php ./generate_plaintext.php 14 | head
!@fju@5qx7@s4r
!@fju@5qx7@s4r
we#hqgerz4@oro
2zyemt2h7caer2
rwm!2mdw4!yatk
tzd!nz@!njsyso
tgkzg60k!k!84p
jwnmnd4#eo8@!r
s@4cbh0ki7j@qz
avxgx#5qv0y2tw
```

And send its output into a file:

```

$ php ./generate_plaintext.php 14 > 14_character_plaintexts.txt
```

You can save some trouble and [download it here](/blogdata/14_character_plaintexts.txt.bz2) if you want to follow along.

Then we send that file into john and watch the magic...

```

$ rm john.pot
$ ./john --stdin --format=raw-md5 14_character_hashes.txt 
<p>As you can see, it loaded 4231 password hashes (there were less than 5000 due to collisions), and cracked them all. And it took 0 seconds. that's pretty darn good!</p>
<h2>Conclusion</h2>
<p>Now you've seen how we can very quickly crack a password generated with a bad algorithm. In my next blog, we'll see how we can crack one generated with an even worse algorithm, remotely! </p>
```