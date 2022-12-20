---
id: 156
title: 'More password dictionaries'
date: '2009-02-07T18:44:09-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=156'
permalink: /2009/more-password-dictionaries
categories:
    - hacking
---

Last month, I posted about some <a href='http://www.skullsecurity.org/blog/?p=151'>password dictionaries</a> I've collected. Well, thanks to a hacker who <a href='http://hackedphpbb.blogspot.com/2009/01/place-holder.html'>compromised PHPBB's site</a>, I added another. There's a big caveat to this one, though -- these passwords are apparently based on ones that were cracked by the hacker, so they're only an accurate representation of weak passwords. 
<!--more-->
That being said, weak passwords are what most pen-testers are targeting, so it can be useful. 

Feel free to take a look at the list, <a href='http://www.skullsecurity.org/wiki/images/0/02/Phpbb-counts.txt'>with</a> and <a href='http://www.skullsecurity.org/wiki/images/e/e4/List-phpbb.txt'>without</a> associated counts. I'm not going to post the list with the usernames intact, because that doesn't do any good for my purposes. 

For fun, I did a grep of the password list for some common passwords. Have a look:
<pre>$ cat phpbb-counts.txt | grep -i password
    609 password
     11 password1
      9 PASSWORD
      7 Password
      6 mypassword
      6 1password
      4 nopassword
      2 thisismypassword
      2 random password
      2 passwords
      2 password2
      2 password123
      2 newpassword
      1 thepassword
      1 password\n
      1 password88
      1 password7
      1 password42
      1 password3
      1 password1234
      1 password11
      1 Password1
      1 password01
      1 PassWord
      1 password@
      1 password_
      1 forumpassword
      1 1Password!
      1 123password
</pre>
Over 600 people used 'password' for their passwords, and 11 used 'password1'. So 60x as many people don't even *try* to make themselves secure. 6 people used '1password', and nearly everybody who used a 'password' variation either added or removed something from the beginning or the end. Additionally, everybody who played with case used either 1, 2, or all capitals, which supports <a href='http://seclists.org/nmap-dev/2009/q1/0320.html'>my theory</a> nicely. 
