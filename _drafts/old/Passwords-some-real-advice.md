---
id: 2000
title: 'Passwords: some real advice'
date: '2015-04-01T18:50:18-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2000'
permalink: '/?p=2000'
categories:
    - Default
---

Hey everybody,

I see a lot of people giving password advice online that ranges from bad to dangerous - in fact, most "standard" advice I see online sucks - and I wanted to post a blog to explain my side instead of re-typing this argument every time I see somebody giving advice that I don't agree with.

Please note that these are my own opinions formed from years of working in the field, and I'm open to changing these views if somebody provides a compelling counter-argument!

Note that this is end-user advice, not specifically for developers, but it's written assuming you are knowledgeable in the field of How Stuff Works. :)

## Types of attacks

There are three different attacks that are useful to distinguish...

First, active attacks: an active attack is one where the attacker is guessing passwords at a login screen or repeatedly (possibly using automated tools) filling out a field on a Web site.

The thing about active attacks is that they're sloooooow... taking some numbers from [thc-hydra](https://www.thc.org/thc-hydra/README)'s docs, the best speed against a service running on *localhost* is a bit less than 30 seconds per 300 passwords, meaning that 10 passwords/second is a pretty reasonable upper bound. And that's with optimal parallelization!

A password with 6 lowercase letters and numbers - chosen randomly - has 2,176,782,336 possible values (36<sup>6</sup>) - at 10/second, it'll take nearly 7 years to cover the whole space.

The point is that it's unreasonably slow, even assuming 100% optimal conditions and a very weak password. We'll come back to that!

The second attack type is offline - given a hash, how long does it take to get the password back?

The answer to that depends greatly on how they are stored by the service, a fact that is normally opaque to the end user - and something that end users should not be required to worry about! But this will range from zero seconds (for plaintext passwords) to longer that active attacks.

The upside is that these attacks can only be performed if the attacker has a dump of all passwords, and is generally done to increase the amount of access that an account has - that is, now that the attacker has stolen/cracked your password from your local video game forum, they can log into your Facebook account.

Basically, offline password cracking is akin to privilege escalation.

The third attack type is a hybrid - cases where you can attack a password offline, but that unlocks new information when it is cracked. I'm thinking of things like full-disk encryption, password-protected encryption keys, stuff like that.

This advice doesn't apply to this situation - if cracking a password offline has a straight-line path to stealing new data, use the strongest password you can. This will be considered out of scope for the rest of this post.

## Foiling active attacks

You, naturally, have different types of accounts - some of which you care about, and some of which you don't. You have to think - how much impact would losing your account on a particular site have? It could be a severe impact (if you lost your Gmail or Amazon account), a moderate/small impact (if you lose the account on your favourite video game forum), or no impact (if you lose the account you had to make to download that driver that one time - you know the one).

Let's assume that we're talking about a password that will negatively impact your life in some way if stolen.

To prevent an active attack (guessing passwords against a Web site), even a relatively simple - but **random** - password will forestall all but the most intense attackers.

The key word is *random* - 6 random letters/numbers, as I said earlier, has a total of 2,176,782,336 possible combinations. If you use a dictionary word (like "puppy") - or a variation of a dictionary word (like "puppy1"), you're down to the size of the English language - about 350,000 options in the [dictionary I host](https://wiki.skullsecurity.org/Passwords). 35,000 seconds is a whole lot different than 217,678,234 seconds.

That being said, turning 350,000 options into more than 2.1 billion options isn't that hard - just channel [password strength advice from xkcd](https://xkcd.com/936/) (though note that he assumes 1000 guesses/second)!

You can easily square the 350,000 number by using two words! If you use two *randomly selected* English words, you now have 122,500,000,000 combinations - well outside the range of an active attacker! Separate them with a symbol - say, randomly selected from the 33 you can see on your keyboard - and you suddenly have 4,042,500,000,000 possibilities. So a password like "maximise\]obtained" is both easy to remember and highly resistant against active attacks!

The key, as I said, is randomness. The words can't normally be used together, or can't form a common phrase, otherwise it becomes much weaker!

One more thing: if you can, use two-factor authentication. Because that basically makes active attacks impossible

## What about offline attacks?

Offline attacks are where most people tend to focus when giving password advice! However, in my opinion, we shouldn't be focussing on this. Let's see why?

Granted, cracking an MD5-hashed password can be done at 10 million guesses per second, which means that our 6-character password instantly fails. So maybe my "use a short random password" situation is a failure here. Or is it?

What people don't usually bring up is that there's a chance that your carefully selected and memorized 24-character password will be instantly compromised: all it takes is the site not hashing passwords at all.

So in reality, depending on factors that are completely opaque and out of the user's control, a given password may take between 0 seconds (a reasonably strong password unhashed) and millions of years (a moderate password hashed with bcrypt). As a user, you can't rely on that.

What's more: for this attack to actually start, it means that a site's password list was compromised. That means that, at best, the attacker probably has access to the site's database (including all your data from the site). At worst, they have access to everything on the server (and in that case, even if passwords are strongly hashed, they can start capturing passwords before they're hashed!).

The bottom line is: if an incident occurs where your password's strength against offline attacks is a factor, it's safe advice to assume your password is instantly broken.

## Password re-use

And that brings me to the biggest danger: password re-use. As soon as you use a password on any given site, it's imperative that you realize one thing: the password is now under full control of that site. Period. The end.

As soon as you use a password on multiple sites, you've given your account not just to attacker who've compromised it, but to any developer or administrator who has permission to change code on your site.

Would you tell your Gmail password to that sketchy guy who hosts your gaming forum? If not, why would you type the password into a page that he controls (nevermind that it's hashed - he can capture it before it's hashed by backdooring the app!)

That being said, there is one situation where password re-use is okay: remember that time you had to register to download that piece of software? You know, the one that you didn't want, but that needed email verification and nothing more? Go ahead and use a shitty password on that site. In fact, you can use my usual password - "Password1". I don't mind!

Honestly, I see a ton of news stories focussing on all the really crappy passwords people used on, for example, phpbb. But think of it this way: I'm being forced to create an account that I never plan to use again so I can ask for support. If somebody gets my account through an active attack, I really don't care. If they get the account through downloading the hashes and cracking it, I still don't care. Using "Password1" as my password is my indication that I don't care about the account in any way whatsoever.

So when you say "40% of users use '123456' as their password!" - what you really mean is, 40% of people don't care about the particular site you're using for your "research".

## What do you recommend doing?

So let's re-iterate...

It's easy to prevent online attacks as a user: use a unique, fairly random password.

It's impossible to prevent offline attacks as a user: you have no control over whether or not your password is even hashed, and even if it is, the attacker probably have access to more than just passwords.

The natural solution: use a *unique* and *random* password for every site that you care about.

## Conclusion

To wrap things up, here is my advice:

- Use a *unique* and *random* password for every site that you care about.
- Don't be afraid to use a throw-away password (like "Password1") for sites you don't care about
- If possible, use two-factor authentication
- If possible, use a third-party authenticator (authenticate via Facebook or G+ or equivalent - although these options may have privacy implications)

And that's about it!

I'd love to hear feedback. :)