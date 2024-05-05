---
id: 2208
title: 'SANS Hackfest writeup: Hackers of Gravity'
date: '2015-12-02T00:44:58-05:00'
author: hexxus
layout: revision
guid: 'https://blog.skullsecurity.org/2015/2198-autosave-v1'
permalink: '/?p=2208'
---

Last week, SANS hosted a private event at the Smithsonian's Air and Space Museum as part of SANS Hackfest. An evening in the Air and Space Museum just for us! And to sweeten the deal, they set up a scavenger hunt called "Hackers of Gravity" for us!

We worked in small teams (I teamed up with [Eric](https://twitter.com/ericgershman), who's also writing this blog with me). All they told us in advance was to bring a phone, so every part of this was solved with our phones and Google.

Each level began with an image, typically with a cipher encoded in it. After decoding the cipher, the solution and the image itself were used together to track down a related artifact.

This is a writeup of that scavenger hunt. :)

## Challenge 1: Hacker of Tenacity

The order of the challenges was actually randomized, so this may not be the order that anybody else had (homework: there are 5040 possible orderings of challenges, and about 100 people attending; what are the odds that two people had the same order? The birthday paradox applies).

The first challenge was simply text:

```

Sometimes tenacity is enough to get through a difficult challenge. This Hacker of Gravity never gave up and even purposefully created discomfort to survive their challenge against gravity. Do you possess the tenacity to break this message? 

T05ZR1M0VEpPUlBXNlpTN081VVdHMjNGT0pQWEdaTEJPUlpRPT09PQ==
```

Based on the character set, we immediately recognized it as Base64. We found an online decoder and it decoded to:

```
ONYGS4TJORPW6ZS7O5UWG23FOJPXGZLBORZQ====
```

￼￼  
We recognized that as Base32 - Base64 will never have four "====" signs at the end, and Base32 typically only contains uppercase characters and numbers. (Quick plug: I'm currently working on [Base32 support](https://github.com/iagox86/dnscat2/issues/71) for dnscat2, which is another reason I quickly recognized it!)

Anyway, the Base32 version decoded to <tt>spirit\_of\_wicker\_seats</tt>, and Eric recognized "Spirit" as a possible clue and searched for "Spirit of St Louis Wicker Seats", which revealed the following quote from the [Wikipedia article](https://en.wikipedia.org/wiki/Spirit_of_St._Louis) on the Spirit of St. Louis: "The stiff wicker seat in the cockpit was also purposely uncomfortable".

![](https://blogdata.skullsecurity.org/hackers-of-gravity-07.png)

The Spirit of St. Louis was one of the first planes we spotted, so we scanned the QR code and found the solution: <tt>lots\_of\_fuel\_tanks</tt>!

## Challenge 2: Hacker of Navigation

We actually got stuck on the second challenge for awhile, but eventually we got an idea of how these challenges tend to work, after which we came back to it.

We were given a fragment of a letter:

> The museum archives have located part of a letter in an old storage locker from some previously lost collection. They'd REALLY like your help finding the author.
> 
> ![](https://blogdata.skullsecurity.org/hackers-of-gravity-10.png)

You'll note at the bottom-left corner it implies that "A = 50 degrees". We didn't notice that initially. :)

What we did notice was that the degrees were all a) multiples of 10, and b) below 260. That led us to believe that they were numbered letters, times ten (so A = 10, B = 20, C = 30, etc).

The numbers were: <tt>100 50 80 90 80 100 50 230 120 130 190 180 130 230 240 50</tt>.

Dividing by 10 gives <tt>10 5 8 9 8 10 5 23 12 13 19 18 13 23 24 5</tt>.

Converting that to the corresponding letters gave us <tt>JEHIH JEWLMSRMWXE</tt>. Clearly not an English sentence, but it looks like a cryptogram (<tt>JEHIH</tt> looks like "THERE" or "WHERE").

That's when we noticed the "A = 50" in the corner, and realized that things were probably shifted by 5. Instead of manually converting it, we found a shift cipher bruteforcer that we could use. The result was:

> FADED FASHIONISTA

Searching for "Faded Fashionista Air and Space" led us to [this Smithsonian Article](http://www.smithsonianmag.com/smart-news/amelia-earhart-fashionista-6707662/): *Amelia Earhart, Fashionista*. Neither of us knew where her exhibit was, but eventually we tracked it down on the map and walked around it until we found her Lockheed Vega, the QR code scanned to <tt>amelias\_vega</tt>.

![](https://blogdata.skullsecurity.org/hackers-of-gravity-15.png)

## Challenge 3: Hacker of Speed

This was an image of some folks ready to board a plane or something:

> This super top secret photo has been censored. The security guys looked at this SO fast, maybe they missed something?
> 
> ![](https://blogdata.skullsecurity.org/hackers-of-gravity-03.png)

Because of the hint, we started looking for mistakes in the censoring and noticed that they're wearing boots that say "X-15":

![](https://blogdata.skullsecurity.org/hackers-of-gravity-18.png)

We found pictures of [the X-15 page](http://airandspace.si.edu/collections/artifact.cfm?object=nasm_A19690360000) on the museum's Web site and remembered seeing the plane on the 2nd floor. We reached the artifact and the QR code was <tt>faster\_than\_superman</tt>.

Once we got to the artifact, we noticed that we hadn't broken the code yet. Looking carefully at the image, we saw the text at the bottom, <tt>nbdi\_tjy\_qpjou\_tfwfo\_uxp</tt>.

As an avid cryptogrammer, I recognized <tt>tfwfo</tt> as likely being "never". Since 'e' is one character before 'f', it seemed likely that it was a single shift ('b'->'a', 'c'->'b', etc). I mentally shifted the first couple letters, and it looked right, so I did the entire string while Eric wrote it down: <tt>mach\_six\_point\_seven\_two</tt>.

## Challenge 4: Hacker of Design

> While researching some physics based penetration testing, you find this interesting diagram. You feel like you've seen this device before... maybe somewhere or on something in the Air and Space museum?
> 
> ![](https://blogdata.skullsecurity.org/hackers-of-gravity-17.png)

The diagram reminded Eric of an engine he saw on an earlier visit, we found the artifact on the other side of the museum:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-06.png)

Unfortunately there was no QR code so we decided to work on decoding the challenge to discover the location of the artifact.

Now that we'd seen the hint on Challenge 2, we were more prepared for a diagram to help us! In this case, it was a drawing of an atom and the number "10". We concluded that the numbers probably referred to the atomic weight for elements on the periodic table, and converted them as such:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-12.png)

10=>Ne  
74=>W  
... and so on.

After decoding the full string, we ended up with:

<tt>new\_plan\_schwalbe</tt>

We actually made a mistake in decoding the string, but managed to find it anyways thanks to search autocorrect. :)

After searching for "schwalbe air and space", we found [this article](http://airandspace.si.edu/collections/artifact.cfm?object=nasm_A19600328000), which led us to the artifact: the Messerschmitt Me 262 A-1a Schwalbe (Swallow). The QR code scanned revealed <tt>the\_swallow</tt>.

![](https://blogdata.skullsecurity.org/hackers-of-gravity-00.png)

![](https://blogdata.skullsecurity.org/hackers-of-gravity-05.png)

## Challenge 5: Hacker of Distance

> While at the bar, listening to some Dual Core, planning your next conference-fest with some fellow hackers, you find this interesting napkin. Your mind begins to wander. Why doesn't Dual Core have a GOLDEN RECORD?! Also, is this napkin trying to tell you something in a around-about way?
> 
> ![](https://blogdata.skullsecurity.org/hackers-of-gravity-01.png)

The hidden text on this one was obvious… morse code! Typing the code into a phone (not fun!), we ended up with <tt>.- -.. .- ... - .-. .- .--. . .-. .- ... .--. . .-. .-</tt>, which translates to <tt>ADASTRAPERASPERA</tt>

According to Google, that slogan is used by a thousand different organizations, none of which seemed to be space or air related. However, searching for "Golden Record Air and Space" returned several results for the Voyager space probe. We looked at our map and scurried to the exhibit on the other side of the museum:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-16.png)

Once we made it to the exhibit finding the QR code was easy, scanning it revealed, <tt>the\_princess\_is\_in\_another\_castle</tt>

The decoy flag! We tried searching keywords from the napkin but none of the results seemed promising. After a few frustrating minutes we saw the museum banquet director and asked him for help. He told us that the plane we were looking for was close to the start of the challenge, we made a dash for the first floor and found the correct Voyager exhibit:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-09.png)

Scanning the QR code revealed the code, <tt>missing\_canards</tt>

## Challenge 6: Hacker of Guidance

The sixth challenge gave us a map with some information:

> You have intercepted this map that appears to target something. The allies would really like to know the location of the target. Also, they'd like to know what on Earth is at that location.
> 
> ![](https://blogdata.skullsecurity.org/hackers-of-gravity-14.png)

We immediately noticed the hex-encoded numbers on the left:

```

35342e3133383835322c
31332e373637373235
```

Which translates to 54.138852,13.767725, We googled the coordinates, and it turned out to be a location in Germany: Flughafenring, 17449 Peenemünde, Germany.

After many failed searches we tried "Peenemünde ww2 air and space", which led to a reference to the German V2 Rocket. Here is the exhibit and QR code:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-04.png)

Scanning the QR code revealed <tt>aggregat\_4</tt>, the formal name for the V-2 rocket.

## Challenge 7: Hacker of Coding

This is an image with a cipher on the right:

> Your primary computer's 0.043MHz CPU is currently maxed out with other more important tasks, so converting all these books of source code to assembly is entirely up to you.
> 
> ![](https://blogdata.skullsecurity.org/hackers-of-gravity-08.png)

On the chalkboard is a cipher:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-19.png)

We couldn't remember what it was called, and ended up searching for "line dot cipher", which immediately identified it as a pigpen cipher. The pigpen cipher can be decoded with this graphic:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-13.png)

Essentially, you find the shape containing the letter that corresponds to the shape in that graphic. So, the first letter is ">" on the chalkboard, which maps to 'T'. The second is the upper three quarters of a square, which matches up with 'H', and the third is a square, which matches to E. And so on.

Initially we found a version that didn't map to the proper English characters, and translated it to:

![](https://blogdata.skullsecurity.org/hackers-of-gravity-11.png)

Later, we did it right and found the text "THE BEST SHIP TO COME DOWN THE LINE"

To find the artifact, we googled "0.043MHz", and immediately discovered it was "Apollo 11".

![](https://blogdata.skullsecurity.org/hackers-of-gravity-02.png)

The QR code scanned to <tt>the\_eleventh\_apollo</tt>

## And that's it!

And that's the end of the cipher portion of the challenge! We were first place by only a few minutes. :)

The last part of the challenge involved throwing wood airplanes. Because our plane didn't go backwards, it wasn't the worst, but it's nothing to write home about!

But in the end, it was a really cool way to see a bunch of artifacts and also break some codes!