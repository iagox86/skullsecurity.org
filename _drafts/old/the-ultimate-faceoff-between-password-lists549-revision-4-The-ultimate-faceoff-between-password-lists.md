---
id: 553
title: 'The ultimate faceoff between password lists'
date: '2010-03-06T17:51:27-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=553'
permalink: '/?p=553'
---

Yes, I'm still working on making the ultimate password list. And I don't mean the 16gb one I made by taking pretty much every word or word-looking string on the Internet when I was a kid; that was called ultimat**er**\_dictionary. No; I mean one that is streamlined, sorted, and will make Nmap the bruteforce tool of the future!

At the request of some of the Nmap guys, I held a faceoff. I took my password lists from:

- [John the ripper](http://downloads.skullsecurity.org/passwords/john.txt)
- [Myspace](http://downloads.skullsecurity.org/passwords/myspace.txt) (Nmap's original)
- [Phpbb](http://downloads.skullsecurity.org/passwords/phpbb.txt) (cracked by Brandon Enright)
- [Rockyou.com](http://downloads.skullsecurity.org/passwords/rockyou.txt) (my favourite; not that I'm biased)
- [Conficker](http://downloads.skullsecurity.org/passwords/conficker.txt) (which I already knew would suck)

And I put them up against some of the best leaked password lists:

- [Rockyou](http://downloads.skullsecurity.org/passwords/rockyou.txt)
- [Phpbb](http://downloads.skullsecurity.org/passwords/phpbb.txt)
- [Hotmail](http://downloads.skullsecurity.org/passwords/hotmail.txt)
- [Myspace](http://downloads.skullsecurity.org/passwords/myspace.txt)
- [Hak5](http://downloads.skullsecurity.org/passwords/hak5.txt)
- [Faithwriters](http://downloads.skullsecurity.org/passwords/faithwriters.txt)
- [Elitehackers](http://downloads.skullsecurity.org/passwords/elitehacker.txt)
- [500 worst passwords](http://downloads.skullsecurity.org/passwords/500-worst-passwords.txt)

(Obviously, where there's overlap, I didn't count the password cracking its own list; that wouldn't really be fair).

Because we want in smaller lists, I used the top 1, 10, 50, 100, 200, 500, 1000, 2000, and 5000 passwords from each list, and measured how many of the original passwords it would crack. The best possible result, obviously, is for the line to be straight (points at {100,100}, {1000,1000}, etc.). Naturally, that didn't happen anywhere, but it was close on a couple!

Enough talk, here are the results:  
![](/blogdata/cracked_rockyou.png)  
![](/blogdata/cracked_phpbb.png)  
![](/blogdata/cracked_hotmail.png)  
![](/blogdata/cracked_myspace.png)  
![](/blogdata/cracked_hak5.png)  
![](/blogdata/cracked_faithwriters.png)  
![](/blogdata/cracked_elitehackers.png)  
![](/blogdata/cracked_500worst.png)