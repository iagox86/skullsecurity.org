---
id: 1028
title: 'Ethics of password cracking/dissemination'
date: '2011-01-24T09:03:26-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1028'
permalink: /2011/ethics-of-password-crackingdissemination
categories:
    - Conferences
    - Hacking
    - Passwords
---

It's rare these days for me to write blogs that I have to put a lot of thought into. Most of my writing is technical, which comes pretty naturally, but I haven't written an argument since I minored in philosophy. So, if my old Ethics or Philosophy profs are reading this, I'm sorry! 
<!--more-->
<h2>Introduction</h2>
Anybody who follows my blog/work regularly know that I collect, crack, and disseminate password breaches. I have a <a href='/wiki/index.php/Passwords'>wiki page</a> devoted to breaches and dictionaries and I occasionally <a href='https://deepsec.net/docs/speaker.html#PSLOT17'>do talks</a> on the subject. And if you <a href='https://twitter.com/iagox86'>follow me on Twitter</a>, you'll see <a href='https://twitter.com/iagox86/status/17619856631275520'>regular</a> <a href='https://twitter.com/iagox86/status/17615145828089856'>updates</a> about password dictionaries. 

The issue is, <a href='https://twitter.com/brainwagon/status/17619256166322177'>not</a> <a href='http://twitter.com/SimonLR/statuses/17984868306653185'>everybody</a> agrees with what I do (I was hoping to have more links in that sentence, but only two people actually said they thought it was wrong when I <a href='http://twitter.com/?status=@iagox86%20&in_reply_to_status_id=17983590822318080&in_reply_to=iagox86'>asked for comments on Twitter</a>). Fortunately, <a href='https://twitter.com/nikhil_mitt/statuses/17994429797244928'>many</a> <a href='https://twitter.com/LenIsham/statuses/18005375303294976'>more</a> <a href='https://twitter.com/ChrisJohnRiley/statuses/17987742487027712'>people</a> <a href='https://twitter.com/mruef/statuses/17986098747670528'>agreed</a> that I was doing something good. So I take that as a small victory... 

Anyway, this post is going to cover some of the pros and cons of what I do, and why I think that I'm doing the right thing, helping the world, etc. 

<h2>Cons</h2>
<strong>#1: you're helping the bad guys</strong>
The issue I hear most often is that I'm making it easier for the bad guys, whether it's people trying to take over users' accounts or perform bruteforce attacks more efficiently. Now, keeping in mind that every security tool and piece of security research in some way helps both good guys and bad guys, this is why I'm comfortable that my work isn't benefiting bad guys in any significant way:
<ul>
<li>The data I'm getting is *from* bad guys in the first place, which means that they already have it</li>
<li>My data contains no personally identifiable information... more on that later</li>
<li>The most common passwords are already known, and sites that use passwords like 'qwerty' on their admin account will be compromised anyways (and who would do something like that *cough<a href='http://scrollwars.com/'>darryl</a>cough*). The best thing I can do is raise awareness.</li>
</ul>

<strong>#2: you're actively harming people</strong>
This i largely covered by my response to the previous point, but I wanted to reiterate: I do my best to ensure nobody is harmed. 

It's a well known fact that people use the same password in multiple places. If you have 100 accounts online that each require a 7+ character password (or 14+ characters if you want actual security), how are you supposed to remember them? Unique passwords for facebook, twitter, gmail, hotmail, gawker, every random forum you visit, and so on and so on. Without a password management tool, you're re-using passwords. This week I decided to bite the bullet and strengthen all my passwords. I have 14 accounts that I would consider "important", and that doesn't include my computers themselves, my PGP key, my SSH key, and so on and so on. 

Now, the biggest danger in these password breaches is when somebody uses the same username/email address on a compromised site that they use on a more important site (their bank? Paypal? or, God forbid.... Facebook?) Attackers, armed with usernames and passwords, can wreak havoc on somebody's online life. I found a great story about the singles.org compromise, but unfortunately I can't find it again so <a href='http://www.computerworld.com.au/article/278298/exposed_christians_reminder_use_multiple_site_passwords/'>this one</a> will have to do. The basic idea is, after 4chan folks compromised singles.org's password database, they started using those passwords to log into Facebook, online banking, etc. 

Another, more modern version of that is the suspected link between the <a href='http://nakedsecurity.sophos.com/2010/12/13/acai-berry-spam-gawker-password-hack-twitter/'>Gawker compromise and Açaí berry spam</a>. Though nothing has been proven, and just using that word is probably going to get me some spam, some people suspect a correlation between the attack and the spam. Matt Weir has tried to prove this link, but so far I believe his results have been inconclusive. 

Now, what am I doing to protect people? Well, first and foremost, I don't release personally identifiable information. Ever. Most of the breaches I get contain usernames, email addresses, and sometimes more (in 3 or 4 cases, I've received entire dumps of databases!). And I don't release those. When people come to my site, they're getting aggregated password counts, which is pure statistical data, nothing more. (One thing I can't protect is people who use an email address as their password - you aren't fooling anybody!)

By making it easy to get the sanitized list of passwords, it's less likely people will look for, find, download, and distribute the full version - the version that, in my opinion, is far more dangerous. 

Another point worth mentioning: I occasionally sit on lists for weeks or months to help minimize the potential damage they'll do to companies and their users. While I won't admit to sitting on any right now, I think it's important to judge whether or not a particular list can cause more harm than good if I release it, and to release it only when the amount of harm it can cause is minimized (that is, when we know the bad guys already have the list, so releasing it to the good guys doesn't matter anymore). 

<h2>Pros</h2>
So, those are the only cons I can think of, though I have somewhat of a biased view. If you feel I missed something important, let me know and I'll do my best to respond! 

Now, on to why I think I'm doing a *good* thing! 

<strong>#1: you're spreading the message on good password hashing</strong>
When I do talks, I discuss the benefits of good password hashing. Unsalted md5, we can usually crack 90% plus of all passwords; salted md5, probably closer to 70%. If a site uses <a href='http://codahale.com/how-to-safely-store-a-password/'>bcrypt</a> or something similar as the primary means of storing their passwords (sorry, Gawker, but using bcrypt only helps you if you don't store a weaker type beside it), I'd bet we'd have trouble cracking more than 25% of all passwords. 

To all Web developers: algorithms matter! 

Let's look at it this way: say a site loses 5.3 million passwords: If those passwords are unsalted (raw-md5, as john the ripper calls it), then we hash our first guess, compare it 5.3 million times, hash our second guess, compare 5.3 million times, etc. That means that for each md5() operation we perform, we can check 5.3 million hashes. If those hashes were salted, we'd hash once, compare to the first hash, hash the same guess with the second salt, compare to the second hash, and so on 5.3 million times. That means that, with salting, one md5() operation gets us one comparison. 

But what's that mean?

It means that unsalted passwords, in a list with 5.3 million passwords, will crack <em>5.3 million times as fast</em> as salted passwords. I can average about 5,000,000 checks/second on my laptop against a single md5 hash, which means I can perform approximately 5,300,000 times that, or 26,500,000,000,000 checks/second against unsalted passwords. 

To summarize:
<strong>Salted hashes:</strong> 5 million checks/second
<strong>Unsalted hashes</strong> 26.5 trillion checks/second

Taking it one step further, though - some algorithms, like WPA, bcrypt, and so on, are designed to be slow. Take bcrypt, for example - on my laptop, I can perform about 5 million checks/second for salted md5, and 17 checks/second for bcrypt. Compare 17 checks/second to the 26.5 trillion checks/second we saw earlier, against a large list, and the difference is astounding. Against the list of 5.3 million passwords, it would take us 86 hours to check each hash once. In other words, to guess '123456' for 5.3 million passwords, it would take over 3 days. Then guessing 'password' would take another 3 days, and so on. Basically, you could grow old and never crack more than a handful of passwords. 

So, part of my goal is just that: teach people to use proper hashing algorithms! 

<strong>#2: you're demonstrating why passwords are fundamentally flawed</strong>
But even with bcrypt, it isn't going to help us any if an attacker can go to the Web interface, type in an admin username (oh, let's say, 'darryl'), and try the top 10 passwords (let's say, 'qwerty') and have full access to the site. As long as passwords exist, people are going to <a href='http://www.skullsecurity.org/blog/2010/hard-evidence-that-people-suck-at-passwords'>choose stupid passwords</a> and get compromised that way, no matter what kind of hashing, lockouts, etc are used. Additionally, people are going to install malware that logs their passwords, preventing the need from ever guessing them. 

That's why passwords need to go away, or be enhanced. Somebody has to find a way to create ubiquitous two-factor authentication. That is, a second factor that can be safely used everywhere, and that's resistant to being stolen. I suspect it's a long way off, but it's something that I'll support when it starts becoming a reality. 

<strong>#3: you're providing research data/analysis</strong>
Everybody loves having hard data for their research. In the past I found it excessively hard to do any kind of research on passwords because getting the various compromises into one place was nearly impossible. But now, thanks to my efforts, you can calculate some pretty cool <a href='http://svn.skullsecurity.org:81/ron/security/2010-11-deepsec/data.ods'>data</a> on password breaches. 

<strong>#4: you're making password breaches less valuable</strong>
This is an interesting take on the issue that my friend had. Each breach that I mirror makes the breach itself, as well as other breaches, less valuable for a bad guy to have. It comes down to a supply and demand issue - if there's a large supply, it's unnecessary to get more. Therefore, people won't invest as much time, effort, or money into obtaining more breaches simply for their passwords. 

<strong>#5: you're helping us heat our houses this winter</strong>
Every machine that's cracking passwords is also <a href='https://twitter.com/_sid77/status/17620972215476224'>helping heat a house</a>, feel free to thank me for it. 

But when global warming comes for us, don't blame me! 

<h2>Conclusion</h2>
Hopefully you have some idea, now, of why I do what I do. In my mind, there's absolutely nothing unethical about distributing breached passwords as aggregate statistics (without personally identifiable information) and it helps the community a great deal. 

I'd love to hear comments from anybody who agrees or disagrees! My email is in the sidebar at the top-right, and the comments below allow anonymous posting (assuming you can do simple math :) ), so please let me know how you feel! 
