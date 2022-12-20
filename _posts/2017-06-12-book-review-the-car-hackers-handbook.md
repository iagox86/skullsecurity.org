---
id: 2304
title: 'Book review: The Car Hacker&#8217;s Handbook'
date: '2017-06-12T10:12:32-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2304'
permalink: /2017/book-review-the-car-hackers-handbook
categories:
    - reviews
---

So, this is going to be a bit of an unusual blog for me. I usually focus on technical stuff, exploitation, hacking, etc. But this post will be a mixture of a book review, some discussion on my security review process, and <a href='https://xkcd.com/722/'>whatever asides fall out of my keyboard when I hit it for long enough</a>. But, don't fear! I have a nice heavy technical blog ready to go for tomorrow!
<!--more-->
<h2>Introduction</h2>
 
Let's kick this off with some pointless backstory! Skip to the next &lt;h1&gt; heading if you don't care how this blog post came about. :)
 
So, a couple years ago, I thought I'd give Audible a try, and read (err, listen to) some Audiobooks. I was driving from LA to San Francisco, and picked up a fiction book (one of Terry Pratchett's books in the Tiffany Aching series). I hated it (the audio experience), but left Audible installed and my account active.
 
A few months ago, on a whim, I figured I'd try a non-fiction book. I picked up NOFX's book, "The Hepatitis Bathtub and Other Stories". It was read by the band members and it was super enjoyable to listen while walking and exercising! And, it turns out, Audible had been giving me credits for some reason, and I have like 15 free books or something that I've been consuming like crazy.
 
Since my real-life friends are sick of listening to me talk about all books I'm reading, I started amusing myself by posting mini-reviews on Facebook, which got some good feedback.
 
That got me thinking: writing book reviews is kinda fun!
 
Then a few days ago, I was talking to a publisher friend at <a href='http://rmbooks.com/'>Rocky Mountain books</a> , and he mentioned how he there's a reviewer who they sent a bunch of books to, and who didn't write any reviews. My natural thought was, "wow, what a jerk!".
 
Then I remembered: I'd promised <a href='https://www.nostarch.com/'>No Starch</a> that I'd write about <a href='https://www.nostarch.com/carhacking'>The Car Hacker's Handbook</a> like two years ago, and totally forgot. <a href='https://imgur.com/gallery/zzcET'>Am <strong>I</strong> the <s>evil scientist</s> jerk</a>?
 
So now, after re-reading the book, you get to hear my opinions. :)
 
<h2>Threat Models</h2>
 
I've never really written about a technical book before, at least, not to a technical audience. So bear with this stream-of-consciousness style. :)
 
I think my favourite part of the book is the layout. When writing a book about car hacking to a technical audience, there's always a temptation to start with the "cool stuff" - protocols, exploits, stuff like that. It's also easy to forget about the varied level of your audience, and to assume knowledge. Since I have absolutely zero knowledge about car hacking (or cars, for that matter; my proudest accomplishment is filling the washer fluid by the third try and pulling up to the correct side of the gas pumps), I was a little worried.
 
At my current job (and previous one), I do product security reviews. I go through the cycle of: "here's something you've never seen before: ramp up, become an expert, and give us good advice. You have one week". If you ever have to do this, here's my best advice: just ask the engineers where they think the security problems are. In 5 minutes of casual conversation, you can find all the problems in a system and look like a hero. I love engineers. :)
 
But what happens when the engineers don't have security experience, or take an adversarial approach? Or when you want a more thorough / complete review?
 
That's how I learned to make threat models! Threat models are simply a way to discover the "attack surface", which is where you need to focus your attention as a reviewer (or developer). If you Google the term, you'll find lots of technical information on the "right way" to make a threat model. You might hear about STRIDE (spoofing/tampering/repudiation/information disclosure/denial of service/escalation of privileges). When I tried to use that, I tended to always get stuck on the same question: "what the heck IS 'repudiation', anyways?".
 
But yeah, that doesn't really matter. I use STRIDE to help me come up with questions and scenarios, but I don't do anything more formal than that.
 
If you are approaching a new system, and you want a threat model, here's what you do: figure out (or ask) what the pieces are, and how they fit together. The pieces could be servers, processes, data levels, anything like that; basically, things with a different "trust level", or things that shouldn't have full unfettered access to each other (read, or write, or both).
 
Once you have all that figured out, look at each piece and each connection between pairs of pieces and try to think of what can go wrong. Is plaintext data passing through an insecure medium? Is the user authentication/authorization happening in the right place? Is the traffic all repudiatable (once we figure out what that means)? Can data be forged? Or changed?
 
It doesn't have to be hard. It doesn't have to match any particular standard. Just figure out what the pieces are and where things can go wrong. If you start there, the rest of a security review is much, much easier for both you and the engineers you're working with. And speaking of the engineers: it's almost always worth the time to work together with engineers to develop a threat model, because they'll remember it next time.
 
Anyway, getting back to the point: that's the exact starting point that the Car Hacker's Handbook takes! The very first chapter is called "Understanding Threat Models". It opens by taking a "bird's eye view" of a car's systems, and talking about the big pieces: the cellular receiver, the Bluetooth, the wifi, the "infotainment" console, and so on. All these pieces that I was vaguely aware of in my car, but didn't really know the specifics of.
 
It then breaks them down into the protocols they use, what the range is, and how they're parsed. For example, the Bluetooth is "near range", and is often handled by "Bluez". USB is, obviously, a cable connection, and is typically handled by udev in the kernel. And so on.
 
Then they look at the potential threats: remotely taking over a vehicle, unlocking it, stealing it, tracking it, and so on.
 
For every protocol, it looks at every potential threat and how it might be affected.
 
This is the perfect place to start! The authors made the right choice, no doubt about it!

(Sidenote: because the rule of comedy is that 3 references to something is funnier than 2, and I couldn't find a logical third place to mention it, I just want to say "repudiation" again.)
 
<h2>Protocols</h2>
 
If you read my blog regularly, you know that I love protocols. The reason I got into information security in the first place was by reverse engineering Starcraft's game protocol and implementing and documenting it (others had reversed it before, but nobody had published the information).
 
So I found the section on protocols intriguing! It's not like the olden days, when every protocol was custom and proprietary and weird: most of the protocols are well documented, and it just requires the right hardware to interface with it.
 
I don't want to dwell on this too much, but the book spends a TON of time talking about how to find physical ports, sniff protocols, understand what you're seeing, and figure out how to do things like unlock your doors in a logical, step-by-step manner. These protocols are all new to me, but I loved the logical approach that they took throughout the protocol chapters. For somebody like me, having no experience with car hacking or even embedded systems, it was super easy to follow and super informative!

It's good enough that I wanted to buy a new car just so I could hack it. Unfortunately, my accountant didn't think I'd be able to write it off as a business expense. :(
 
<h2>Attacks</h2>
 
After going over the protocols, the book moves to attacks. I had just taken <a href='http://www.sexviahex.com/'>a really good class on hardware exploitation</a>, and many of the same principles applied: dumping firmware, reverse engineering it, and exploring the attack surfaces.
 
Not being a hardware guy, I don't really want to attempt to reproduce this part in any great detail. It goes into a ton of detail on building out a lab, exploring attack surfaces (like the "infotainment" system, vehicle-to-vehicle communication, and even using SDR (software defined radio) to eavesdrop and inject into the wireless communication streams).
 
<h2>Conclusion</h2>
 
So yeah, this book is definitely well worth the read!
 
The progression is logical, and it's an incredible introduction, even for somebody with absolutely no knowledge of cars or embedded systems!
 
Also: I'd love to hear feedback on this post! I'm always looking for new things to write about, and if people legitimately enjoy hearing about the books I read, I'll definitely do more of this!