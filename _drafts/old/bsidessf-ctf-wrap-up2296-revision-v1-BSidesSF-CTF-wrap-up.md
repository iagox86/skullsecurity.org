---
id: 2372
title: 'BSidesSF CTF wrap-up'
date: '2019-03-09T17:43:55-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2019/2296-revision-v1'
permalink: '/?p=2372'
---

Welcome!

While this is technically a CTF writeup, like I frequently do, this one is going to be a bit backwards: this is for a CTF I *ran*, instead of one I played! I've gotta say, it's been a little while since I played in a CTF, but I had a really good time running the [BSidesSF](https://bsidessf.com) CTF! I just wanted to thank the other organizers - in alphabetical order - [@bmenrigh](https://twitter.com/bmenrigh), [@cornflakesavage](https://twitter.com/cornflakesavage), [@itsc0rg1](https://twitter.com/itsc0rg1), and [@matir](https://twitter.com/matir). I couldn't have done it without you folks!

[BSidesSF CTF](https://ctftime.org/event/414) was a capture-the-flag challenge that ran in parallel with [BSides San Francisco](https://bsidessf.com). It was designed to be easy/intermediate level, but we definitely had a few hair-pulling challenges.

  
The goal of this post is to explain a little bit of the motivation behind the challenges I wrote, and to give basic solutions. It's not going to have a step-by-step walkthrough of each challenge - though you might find that in the [writeups list](https://docs.google.com/document/d/1SG81PDlkPG8RvSYjk3wQCcKfPD-yybds4yTnNfFNqVg/edit) - but, rather, I'll cover what I intended to teach, and some interesting (to me :) ) trivia.

If you want to see the source of the challenges, our notes, and mostly everything else we generated as part of creating this CTF, you can find them here:

- [Original sourcecode on github](https://github.com/BSidesSF/ctf-2017-release)
- [Google Drive notes](https://drive.google.com/drive/folders/0B1FCNPhYeo0zdVRSOWNaYWp3V00?usp=sharing) (note that that's not the complete set of notes - some stuff (like comments from our meetings, brainstorming docs, etc) are a little too private, and contain ideas for future challenges :) )

Part of my goal for releasing all of our source + planning documents + deployment files is to a) show others how a CTF can be run, and b) encourage other CTF developers to follow suit and release their stuff!

As of the writing, [the scoreboard](https://scoreboard.ctf.bsidessf.com) and challenges are still online. We plan to keep them around for a couple more days before finally shutting them down.

## Infrastructure

The rest of my team can most definitely confirm this: I'm not an infrastructure kinda guy. I was happy to write challenges, and relied on others for infrastructure bits. The only thing I did was write a Dockerfile for each of my challenges.

As such, I'll defer to my team on this part. I'm hoping that others on my team will post more details about the configurations, which I'll share on [my Twitter feed](https://twitter.com/iagox86). You can also find all the Dockerfiles and deployment scripts on [our Github repository](https://github.com/BSidesSF/ctf-2017-release).

What I do know is, we used:

- [Googles CTF Scoreboard](https://github.com/google/ctfscoreboard) running on AppEngine for our scoreboard
- Dockerfiles for each challenge that had an online component, and Docker for testing
- docker-compose for testing
- Kubernetes for deployment
- Google Container Engine for running all of that in The Cloud

As I said, all the configurations are on Github. The infrastructure worked *great*, though, we had absolutely no traffic or load problems, and only very minor other problems.

I'm also super excited that [Google](https://google.com) graciously sponsored all of our Google Cloud expenses! The CTF weekend cost us roughly $500 - $600, and as of now we've spent a little over $800.

## Players

Just a few numbers:

- We had **728** teams register
- We had **531** teams score at least one point
- We had **354** teams score at least 100 points
- We had **23** teams submit at least one on-site flag (presumably, that many teams played on-site)

Also, the top-10 teams were:

- dcua :: 6773
- OpenToAll :: 5178
- scryptos :: 5093
- Dragon Sector :: 4877
- Antichat :: 4877
- p4 :: 4777
- khack40 :: 4677
- squareroots :: 4643
- ASIS :: 4427
- Ox002147 :: 4397

The top-10 teams on-site were:

- OpenToAll :: 5178
- ▣ :: 3548
- hash\_slinging\_hackers :: 3278
- NeverTry :: 2912
- 0x41434142 :: 2668
- DevOps Solution :: 1823
- Shadow Cats :: 1532
- HOW BOU DAH :: 1448
- Newbie :: 762
- CTYS :: 694

The full list can be found on [our CTFTime.org page](https://ctftime.org/event/414).

## On-site challenges

We had three on-site challenges (none of them created by me):

### on-sight \[1\]

This was a one-point challenge designed simply to determine who's eligible for on-site prizes. We had to flag taped to the wall. Not super interesting. :)

(Speaking of prizes, I want to give a shout out to [Synack](https://www.synack.com/) for providing some prizes, and in particular to working with us on a fairly complex set-up for dealing with said prizes. :)

### Shared Secrets \[250\]

The [Shared Secrets](https://github.com/BSidesSF/ctf-2017-release/tree/master/crypto/shared-secret) challenge was a last-minute idea. We wanted more on-site challenges, and others on the CTF organizers team came up with Shamir Shared Secret Scheme. We posted [QR Codes containing pieces of a secret](https://docs.google.com/document/d/127AAQzIvKSJ0vWo7eVCasD3JoHCAFGTeOlc6JPAvGio/edit) around the venue.

It was a "3 of 6" scheme, so only three were actually needed to get the secret.

The quotes on top of each image try to push people towards either "Shamir" or "ACM 22(11)". My favourite was, "Hi, hi, howdy, howdy, hi, hi! While everyone is minus, you could call me multiply", which is a line from a Shamir (the rapper) song. I did not determine if Shamir the rapper and Shamir the cryptographer were the same person. :)

### Locker \[150\]

[Locker](https://github.com/BSidesSF/ctf-2017-release/tree/master/physical/lock) is really cool! We basically set up a padlock with an Arduino and a receipt printer. After successfully picking the lock, you'd get a one-time-use flag printed out by the printer.

(We had some problems with submitting the flag early-on, because we forgot to build the database for the one-time-use flags, but got that resolved quickly!)

@bmenrigh developed the lock post, which detected the lock opening, and @matir developed the software for the receipt printer.

## My challenges

I'm not going to go over others' challenges, other than the on-site ones I already covered, I don't have the insight to make comments on them. However, I do want to cover all my challenges. Not a ton of detail, but enough to understand the context. I'll likely blog about a couple of them specifically later.

I probably don't need to say it, but: **challenge spoilers coming!**

### 'easy' challenges \[10-40\]

I wrote a series of what I called 'easy' challenges. They don't really have a trick to them, but teach a fundamental concept necessary to do CTFs. They're also a teaching tool that I plan to use for years to come. :)

[easy](https://github.com/BSidesSF/ctf-2017-release/tree/master/reversing/easy) \[10\] - a couldn't-be-easier reversing challenge. Asks for a password then prints out a flag. You can get both the password and the flag by running <tt>strings</tt> on the binary.

[easyauth](https://github.com/BSidesSF/ctf-2017-release/tree/master/web/easyauth) \[30\] - a web challenge that sets a cookie, and tells you it's setting a cookie. The cookie is simply 'username=guest'. If you change the cookie to 'username=administrator', you're given the flag. This is to force people to learn how to edit cookies in their browser.

[easyshell](https://github.com/BSidesSF/ctf-2017-release/tree/master/pwn/easyshell) \[30\] and [easyshell64](https://github.com/BSidesSF/ctf-2017-release/tree/master/pwn/easyshell64) \[30\] - these are both simple programs where you can send it shellcode, and they run it. It requires the player to figure out what shellcode is and how to use it (eg, from msfvenom or an online shellcode database). There's both a 32- and a 64-bit version, as well.

easyshell and easyshell64 are also good ways to test shellcode, and a place where people can grab libc binaries, if needed.

And finally, [easycap](https://github.com/BSidesSF/ctf-2017-release/tree/master/forensics/easycap) \[40\] is a simple packet capture, where a flag is sent across the network one packet at a time. I didn't keep my generator, but it's essentially a ruby script that would do a s.send() on each byte of a string.

### skipper \[75\] and skipper2 \[200\]

Now, we're starting to get into some of the levels that require some amount of specialized knowledge. I wrote [skipper](https://github.com/BSidesSF/ctf-2017-release/tree/master/reversing/skipper) and [skipper2](https://github.com/BSidesSF/ctf-2017-release/tree/master/reversing/skipper2) for an internal company CTF a long time ago, and have kept them around as useful teaching tools.

One of the first thing I ever did in reverse engineering was write a registration bypass for some icon-maker program on 16-bit DOS using the <tt>debug.com</tt> command and some dumb luck. Something where you had to find the "Sorry, your registration code is invalid" message and bypass it. I wanted to simulate this, and that's where these came from.

With skipper, you can bypass the checks by just changing the program counter ($eip or $rip) or nop'ing out the checks. skipper2, however, incorporates the results from the checks into the final flag, so they can't be skipped quite so easily. Rather, you have to stop before each check and load the proper value into memory to get the flag. This simulates situations I've legitimately run into while writing keygens.

### hashecute \[100\]

When I originally conceived of [hashecute](https://github.com/BSidesSF/ctf-2017-release/tree/master/pwn/hashecute), I had imagined it being fairly difficult. The idea is, you can send any shellcode you want to the server, but you have to prepend the MD5 of the shellcode to it, and the prepended shellcode runs as well. That's gotta be hard, right? Making an MD5 that's executable??

Except it's not, really. You just need to make sure your checksum starts with a short-jump to the end of the checksum (or to a NOP sled if you want to do it even faster!). That's <tt>\\xeb\\x0e</tt> (for jmp) or <tt>\\e9\\x0e</tt> (for call), as the simplest examples (there are practically infinite others). And it's really easy to do that by just appending crap to the end of the shellcode: you can see that [in my solution](https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/hashecute/solution/sploit.rb).

It does, however, teach a little critical thinking to somebody who might not be super accustomed to dealing with machine code, so I intend to continue using this one as a teaching tool. :)

### b-64-b-tuff \[100\]

[b-64-b-tuff](https://github.com/BSidesSF/ctf-2017-release/tree/master/pwn/b-64-b-tuff) has the dual-honour of both having the stupidest name and being the biggest waste of my own time .:)

So, I came up with the idea of writing this challenge during a conversation with a friend: I said that I know people have written shellcode encoders for unicode and other stuff, but nobody had ever written one for Base64. We should make that a challenge!

So I spent a couple minutes writing [the challenge](https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/challenge/src/b-64-b-tuff.c). It's mostly just Base64 code from StackOverflow or something, and the rest is the same skeleton as easyshell/easyshell64.

Then I spent a few hours writing a [pure Base64 shellcode encoder](https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/b-64-b-tuff/solution/sploit.rb). I intend to do a future blog 100% about that process, because I think it's actually a kind of interesting problem. I eventually got to the point where it worked perfectly, and I was happy that I could prove that this was, indeed, solveable! So I gave it a stupid name and sent out my PR.

That's when I think @matir said, "isn't Base64 just a superset of alphanumeric?".

Yes. Yes it is. I could have used any off-the-shelf alphanumeric shellcode encoder such as msfvenom. D'OH!

But, the process was really interesting, and I do plan to write about it, so it's not a total loss. And I know at least one player did the same (hi [@Grazfather](https://twitter.com/Grazfather)! \[he graciously shared [his code](https://gist.github.com/Grazfather/d1b0b679989f1e8c7fdd236f388ba4f3) where he encoded it all by hand\]), so I feel good about that :-D

### in-plain-sight \[100\]

I like to joke that I only write challenges to drive traffic to my blog. This is sort of the opposite: it rewards teams that read my blog. :)

A few months ago, while writing the delphi-status challenge (more on that one later), I realized that when encrypting data using a padding oracle, the last block can be arbitrarily chosen! I [wrote about it](https://blog.skullsecurity.org/2016/going-the-other-way-with-padding-oracles-encrypting-arbitrary-data) in an off-handed sort of way at that time.

Shortly after, I realized that it could make a neat CTF challenge, and thus was born [in-plain-site](https://github.com/BSidesSF/ctf-2017-release/tree/master/crypto/in-plain-sight).

It's kind of a silly little challenge. Like one of those puzzles you get in riddle books. The ciphertext was literally the string "HiddenCiphertext", which I tell you in the description, but of course you probably wouldn't notice that. When you do, it's a groaner. :)

Fun story: I had a guy from the team OpenToAll bring up the blog before we released the challenge, and mention how he was looking for a challenge involving plaintext ciphertext. I had to resist laughing, because I knew it was coming!

### i-am-the-shortest \[200\]

This was a silly little level, which once again forces people to *get* shellcode. You're allowed to send up to 5 bytes of shellcode to the server, where the flag is loaded into memory, and the server executes them.

Obviously, 5 bytes isn't enough to do a proper syscall, so you have to be creative. It's more of a puzzle challenge than anything.

The trick is, I used a bunch of in-line assembly when developing the challenge (see [the original source](https://github.com/BSidesSF/ctf-2017-release/blob/master/pwn/i-am-the-shortest/challenge/src/shortest.c), it isn't pretty!) that ensures that the registers are basically set up to make a syscall - all you have to do it move esi (a pointer to the flag) into ecx. I later discovered that you can "link" variables to specific registers in gcc.

The intended method was for people to send <tt>\\xcc</tt> for the shellcode (or similar) and to investigate the registers, determining what the state was, and then to use shellcode along the lines of <tt>xchg esi, ecx / int 0x80</tt>. And that's what most solvers I talked to did.

One fun thing: <tt>eax</tt> (which is the syscall number when a syscall is made) is set to <tt>len(shellcode)</tt> (the return value of read()). Since <tt>sys\_write</tt>, the syscall you want to make, is number 4, you can easily trigger it by sending 4 bytes. If you send 5 bytes, it makes the wrong call.

Several of the solutions I saw had a <tt>dec eax</tt> instruction in them, however! The irony is, you only need that instruction because you have it. If you had just left it off, eax would already be 4!

### delphi-status \[250\]

[delphi-status](https://github.com/BSidesSF/ctf-2017-release/tree/master/web/delphi-status) was another of those levels where I spent *way* more time on the solution than on the challenge.

It seems common enough to see tools to decrypt data using a padding oracle, but not super common to see challenges where you have to *encrypt* data with a padding oracle. So I decided to create a challenge where you have to encrypt arbitrary data!

The original goal was to make somebody write a padding oracle encryptor tool for me. That seemed like a good idea!

But, I wanted to make sure this was do-able, and I was just generally curious, so I wrote it myself. Then I updated my tool [Poracle](https://github.com/iagox86/poracle) to support encryption, and [wrote a blog about it](https://blog.skullsecurity.org/2016/going-the-other-way-with-padding-oracles-encrypting-arbitrary-data). If there wasn't a tool available that could encrypt arbitrary data with a padding oracle, I was going to hold back on releasing the code. But tools do exist, so I just released mine.

It turns out, there was a simpler solution: you could simply xor-out the data from the block when it's only one block, and xor-in arbitrary data. I don't have exact details, but I know it works. Basically, it's a classic stream-cipher-style attack.

And that just demonstrates the [Cryptographic Doom Principle](https://moxie.org/blog/the-cryptographic-doom-principle/) :)

### ximage \[300\]

[ximage](https://github.com/BSidesSF/ctf-2017-release/tree/master/forensics/ximage) might be my favourite level. Some time ago - possibly years - I was chatting with a friend, and steganography came up. I wondered if it was possible to create an image where the very pixels were executable!?

I went home wondering if that was possible, and started trying to think of 3-byte NOP-equivalent instructions. I managed to think of a large number of work-able combinations, including ones that modified registers I don't care about, plus combinations of 1- and 2-byte NOP-equivalents. By the end, I could reasonably do most colours in an image, including black (though it was slightly greenish) and white. You can find the code [here](https://github.com/BSidesSF/ctf-2017-release/blob/master/forensics/ximage/challenge/embed_code.rb).

(I got totally nerdsniped while writing this, and just spent a couple days trying to find *every* 3-byte NOP equivalent to see how much I can improve this!)

Originally, I just made the image data executable, so you'd have to ignore the header and run the image body. Eventually, I noticed that the bitmap header, 'BM', was effectively <tt>inc edx / dec ebp</tt>, which is a NOP for all I'm concerned. That's followed by a 2-byte length value. I changed that length on every image to be <tt>\\xeb\\x32</tt>, which is effectively a jump to the end of the header. That also caused weird errors when reading the image, which I was totally fine with leaving as a hint.

So what you have is an image that's effectively shellcode; it can be loaded into memory and run. A steganographic method that has probably never been done. :)

### beez-fight \[350\]

[beez-fight](https://github.com/BSidesSF/ctf-2017-release/tree/master/misc/beez-fight) was an item-duplication vulnerability that was modeled after a similar vulnerability in Diablo 2. I had a friend a lonnnng time ago who discovered a vulnerability in Diablo 2, where when you sold an item it was copied through a buffer, and that buffer could be sold again. I was trying to think of a similar vulnerability, where a buffer wasn't cleared correctly.

I started by writing a simple game engine. While I was creating items, locations, monsters, etc., I didn't really think about how the game was going to be played - browser? A binary I distribute? netcat? Distributing a binary can be fun, because the player has to reverse engineer the protocol. But netcat is easier! The problem is, the vulnerability has to be a bit more subtle in netcat, because I can't depend on a numbered buffer - what you see is what you get!

Eventually, I came upon the idea of equip/unequip being problematic. Not clearing the buffer properly!

Something I see far too much in real life is code that checks if an object exists in a different way in different places. So I decided to replicate that - I had both an item that's NULL-able, and a flag :is\_equipped. When you tried to use an item, it would check if the :is\_equipped flag is set. But when you unequipped it, it checked if the item was NULL, which never actually happened (unequipping it only toggled the flag). As a result, you could unequip the item multiple times and duplicate it!

Once that was done, the rest was easy: make a game that's too difficult to reasonably survive, and put a flag in the store that's worth a lot of gold. The only reasonable way to get the flag is to duplicate an item a bunch, then sell it to buy the flag.

I think I got the most positive feedback on this challenge, people seem to enjoy game hacking!

### vhash + vhash-fixed \[450\]

This is a challenge that me and @bmenrigh came up with, designed to be quite difficult. It was [vhash](https://github.com/BSidesSF/ctf-2017-release/tree/master/crypto/vhash), and, later, [vhash-fixed](https://github.com/BSidesSF/ctf-2017-release/tree/master/crypto/vhash-fixed) - but we'll get to that. :)

It all dates back to a conversation I had with [@joswr1ght](https://twitter.com/joswr1ght) about a SANS Holiday Hack Challenge level I was designing. I suggested using a hash-extension vulnerability, and he said we can't, because of [hash\_extender](https://github.com/iagox86/hash_extender), recklessly written by yours truly, ruining hash extension vulnerabilities forever!

I found that funny, and mentioned it to @bmenrigh. We decided to make our own novel hashing algorithm that's vulnerable to an extension attack. We decided to make it extra hard by not giving out source! Players would have to reverse engineer the algorithm in order to implement the extension attack. PERFECT! Nobody knows as well as me how difficult it can be to create a new hash extension attack. :)

Now, there is where it gets a bit fun. I agreed to write the front-end if he wrote the back-end. The front-end was almost exactly <tt>easyauth</tt>, except the cookie was signed. We decided to use an md5sum-like interface, which was a bit awkward in PHP, but that was fine. I wrote and tested everything with md5sum, and then awaited the vhash binary.

When he sent it, I assumed vhash was a drop-in replacement without thinking too much about it. I updated the hash binary, and could log in just fine, and that was it.

When the challenge came out, the first solve happened in only a couple minutes. That doesn't seem possible! I managed to get in touch with the solver, and he said that he just changed the cookie and ignored the hash. Oh no! Our only big mess-up!

After investigation, we discovered that the agreed md5sum-like interface meant, to @bmenrigh, that the data would come on stdin, and to me it meant that the file would be passed as a parameter. So, we were hashing the empty string every time. Oops!

Luckily, we found it, fixed it, and rolled out an updated version shortly after. The original challenge became an easy 450-pointer for anybody who bothered to try, and the real challenge was only solved by a few, as intended.

### dnscap \[500\]

[dnscap](https://github.com/BSidesSF/ctf-2017-release/tree/master/forensics/dnscap) is simply a packet-capture from [dnscat2](https://github.com/iagox86/dnscat2), running in unecrypted-mode, over a laggy connection (coincidentally, I'm writing this writeup at the same bar where I wrote the original challenge!). In dnscat2, I sent a .png file that contains the dnscat2 logo, as well as the flag. Product placement anyone?

I assumed it would be fairly difficult to disentangle the packets going through, which is why we gave it a high point-value. Ultimately, it was easier than we'd expected, people were able to solve it fairly quickly.

### nibbler \[666\]

And finally, my old friend [nibbler](https://github.com/BSidesSF/ctf-2017-release/tree/master/pwn/nibbler).

At some point in the past few months, I had the realization: nibbles (the snake game for QBasic where I learned to program) sounds like nibble (a 4-bit value). I forget where it came from exactly, but I had the idea to build a nibbles-clone with a vulnerability where you'd have to exploit it by collecting the 'fruit' at the right time.

I originally stored the scores in an array, and each 'fruit' would change between between worth 00 and FF points. You'd have to overflow the stack and build an exploit by gathering fruit with the snake. You'll notice that the <tt>name</tt> that I ask for at the start uses read() - that's so it can have NUL bytes so you can build a ROP-chain in your name.

I realized that picking values between 00 and FF would take FOREVER, and wanted to get back to the original idea: nibbles! But I couldn't think of a way to make it realistic while only collecting 4-bit values.

Eventually, I decided to drop the premise of performing an exploit, and instead, just let the user write shellcode that is run directly. As a result, it went from a pwn to a programming challenge, but I didn't re-categorize it, largely because we don't have programming challenges.

It ended up being difficult, but solveable! One of my favourite writeups is [here](http://karabut.com/bsides-ctf-2017-nibbler-writeup.html); I HIGHLY recommend reading it. My favourite part is that he named the snakes and drew some damn sexy images!

I just want to give a shout out to the poor soul, who I won't name here, who solved this level *BY HAND*, but didn't cat the flag file fast enough. I shouldn't have had the 10-second timeout, but we did. As a result, he didn't get the flag. I'm so sorry. :(

Fun fact: @bmenrigh was confident enough that this level was impossible to solve that he made me a large bet that less than 2 people would solve it. Because we had 9 solvers, I won a lot of alcohol! :)

## Conclusion

Hopefully you enjoyed hearing a little about the BSidesSF CTF challenges I wrote! I really enjoyed writing them, and then seeing people working on solving them!

On some of the challenges, I tried to teach something (or have a teachable lesson, something I can use when I teach). On some, I tried to make something pretty difficult. On some, I fell somewhere between. But there's one thing they have in common: I tried to make my own challenges as easy as possible to test and validate. :)