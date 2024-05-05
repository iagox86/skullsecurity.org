---
id: 589
title: 'The ultimate faceoff between password lists'
date: '2010-03-11T10:51:20-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=589'
permalink: '/?p=589'
---

Yes, I'm still working on making the ultimate password list. And I don't mean the 16gb one I made by taking pretty much every word or word-looking string on the Internet when I was a kid; that was called ultimat*er* dictionary. No; I mean one that is streamlined, sorted, and will make Nmap the bruteforce tool of the future!  
  
First, a sidenote: JHaddix from Security Aegis posted a [story mentioning my password lists](http://www.securityaegis.com/easy-breezy-beautiful-password-attacking/) and noted "I'd grab these lists if you dont already have them, who knows how long they will stay up." He makes a great point -- if I'm asked to remove these lists, I'll have no choice (for what it's worth, I don't see why I would; I cleared it with my ISP before hosting them). But, just in case, I wrapped everything up in a single tarball: [skullsecurity-lists.tar.bz2](http://downloads.skullsecurity.org/passwords/skullsecurity-lists.tar.bz2). Weighing in at 132mb, it contains my whole collection of password lists. Feel free to grab it! If you want to pick and choose, as always, check out my [password page](http://www.skullsecurity.org/wiki/index.php/Passwords).

So anyway, on the subject of generating awesome password lists, Brandon Enright from the Nmap team is trying to come up with an algorithm to rank the different words in the different lists. Meanwhile, I spent some time graphing potential password dictionaries' success against leaked password lists to see which one was best.

These are the dictionaries I used:

- [John the ripper](http://downloads.skullsecurity.org/passwords/john.txt)
- [Myspace](http://downloads.skullsecurity.org/passwords/myspace.txt) (Nmap's original)
- [Phpbb](http://downloads.skullsecurity.org/passwords/phpbb.txt) (cracked by Brandon Enright)
- [Rockyou.com](http://downloads.skullsecurity.org/passwords/rockyou.txt) (my favourite; not that I'm biased)
- [Conficker](http://downloads.skullsecurity.org/passwords/conficker.txt) (which I already knew would suck)

And I put them up against some of the best leaked password lists I've collected:

- [Rockyou](http://downloads.skullsecurity.org/passwords/rockyou.txt)
- [Phpbb](http://downloads.skullsecurity.org/passwords/phpbb.txt)
- [Hotmail](http://downloads.skullsecurity.org/passwords/hotmail.txt)
- [Myspace](http://downloads.skullsecurity.org/passwords/myspace.txt)
- [Hak5](http://downloads.skullsecurity.org/passwords/hak5.txt)
- [Faithwriters](http://downloads.skullsecurity.org/passwords/faithwriters.txt)
- [Elitehackers](http://downloads.skullsecurity.org/passwords/elitehacker.txt)
- [500 worst passwords](http://downloads.skullsecurity.org/passwords/500-worst-passwords.txt)

(Obviously, where there's overlap, I didn't count the password cracking its own list; it wouldn't really be fair to crack Rockyou.com passwords using the Rockyou.com list -- I did that in [an earlier blog](http://www.skullsecurity.org/blog/?p=516) to measure coverage, though, if you want to check that out).

Because we want smaller lists, I used the top 1, 10, 50, 100, 200, 500, 1000, 2000, and 5000 passwords from each list, and measured how many of the original passwords it would crack. The best possible result, obviously, is to have points at {100,100}, {1000,1000}, etc. (dependent on the size of the target list). Naturally, that didn't happen anywhere, but it was close on a couple (the phpbb password list, for example, almost perfectly cracked Rockyou.com -- more because Rockyou.com is big than because phpbb is complete, but you get the picture).

Enough talk, here are the results (note: each graph represents a target, and the lines represent the dictionaries):  
![](/blogdata/cracked_rockyou.png)  
![](/blogdata/cracked_phpbb.png)  
![](/blogdata/cracked_hotmail.png)  
![](/blogdata/cracked_myspace.png)  
![](/blogdata/cracked_hak5.png)  
![](/blogdata/cracked_faithwriters.png)  
![](/blogdata/cracked_elitehackers.png)  
![](/blogdata/cracked_500worst.png)

## Conclusion

I think the conclusions here are:

- Rockyou.com and phpbb are the best lists (props to Brandon for cracking the phpbb passwords!)
- Conficker is a clear loser -- I wonder if Conficker would have done better if the authors spent more time generating its dictionary?
- No dictionary is perfect -- no dictionary won in every match. That's why we need to rank words and make the perfect one!
- OpenOffice.org 3 makes sexy graphs!

On the next episode of Skullsecurity.org..... why you need robots.txt if you're hosting dictionaries, especially German ones.