---
id: 157
title: 'More password dictionaries'
date: '2009-02-07T18:40:39-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=157'
permalink: '/?p=157'
---

Last month, I posted about some [password dictionaries](http://www.skullsecurity.org/blog/?p=151) I've collected. Well, thanks to a hacker who [compromised PHPBB's site](http://hackedphpbb.blogspot.com/2009/01/place-holder.html), I added another. There's a big caveat to this one, though -- these passwords are apparently based on ones that were cracked by the hacker, so they're only an accurate representation of weak passwords.

That being said, weak passwords are what most pen-testers are targeting, so it can be useful.

Feel free to take a look at the list, but [with](http://www.skullsecurity.org/wiki/images/0/02/Phpbb-counts.txt) and [without](http://www.skullsecurity.org/wiki/images/e/e4/List-phpbb.txt) associated counts. I'm not going to post the list with the usernames intact, because that doesn't do any good for my purposes.

For fun, I did a grep of the password list for some common passwords. Have a look:

```
$ cat phpbb-counts.txt | grep -i password
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
      1 passwordn
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
```

Over 600 people used 'password' for their passwords, and 11 used 'password1'. So 60x as many people don't even \*try\* to make themselves secure. 6 people used '1password', and nearly everybody who used a 'password' variation either added or removed something from the beginning or the end. Additionally, everybody who played with