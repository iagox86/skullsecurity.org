---
id: 2198
title: 'SANS Hackfest writeup: Hackers of Gravity'
date: '2015-12-22T12:07:12-05:00'
author: ron
layout: post
guid: https://blog.skullsecurity.org/?p=2198
permalink: "/2015/sans-hackfest-writeup-hackers-of-gravity"
categories:
- conferences
comments_id: '109638373630443371'

---

<s>Last week</s>A few weeks ago, SANS hosted a private event at the Smithsonian's Air and Space Museum as part of SANS Hackfest. An evening in the Air and Space Museum just for us! And to sweeten the deal, they set up a scavenger hunt called "Hackers of Gravity" to work on while we were there!

We worked in small teams (I teamed up with <a href='https://twitter.com/ericgershman'>Eric</a>, who's also writing this blog with me). All they told us in advance was to bring a phone, so every part of this was solved with our phones and Google.

Each level began with an image, typically with a cipher embedded in it. After decoding the cipher, the solution and the image itself were used together to track down a related artifact.

This is a writeup of that scavenger hunt. :)
<!--more-->

<h2>Challenge 1: Hacker of Tenacity</h2>

The order of the challenges was actually randomized, so this may not be the order that anybody else had (homework: there are 5040 possible orderings of challenges, and about 100 people attending; what are the odds that two people had the same order? The birthday paradox applies).

The first challenge was simply text:

<pre>
Sometimes tenacity is enough to get through a difficult challenge. This Hacker of Gravity never gave up and even purposefully created discomfort to survive their challenge against gravity. Do you possess the tenacity to break this message? 

T05ZR1M0VEpPUlBXNlpTN081VVdHMjNGT0pQWEdaTEJPUlpRPT09PQ==
</pre>

Based on the character set, we immediately recognized it as Base64. We found an online decoder and it decoded to:

<pre>ONYGS4TJORPW6ZS7O5UWG23FOJPXGZLBORZQ====</pre>
￼￼
We recognized that as Base32 - Base64 will never have four "====" signs at the end, and Base32 typically only contains uppercase characters and numbers. (Quick plug: I'm currently working on <a href='https://github.com/iagox86/dnscat2/issues/71'>Base32 support</a> for dnscat2, which is another reason I quickly recognized it!)

Anyway, the Base32 version decoded to <tt>spirit_of_wicker_seats</tt>, and Eric recognized "Spirit" as a possible clue and searched for "Spirit of St Louis Wicker Seats", which revealed the following quote from the <a href='https://en.wikipedia.org/wiki/Spirit_of_St._Louis'>Wikipedia article</a> on the Spirit of St. Louis: "The stiff wicker seat in the cockpit was also purposely uncomfortable".

<img src='/blogdata/hackers-of-gravity-07.png' width='600' height='auto'/>

The Spirit of St. Louis was one of the first planes we spotted, so we scanned the QR code and found the solution: <tt>lots_of_fuel_tanks</tt>! 


<h2>Challenge 2: Hacker of Navigation</h2>

We actually got stuck on the second challenge for awhile, but eventually we got an idea of how these challenges tend to work, after which we came back to it.

We were given a fragment of a letter:

<blockquote>
The museum archives have located part of a letter in an old storage locker from some previously lost collection. They'd REALLY like your help finding the author.


<img src='/blogdata/hackers-of-gravity-10.png'  width='600' height='auto'/>
</blockquote>

You'll note at the bottom-left corner it implies that "A = 50 degrees". We didn't notice that initially. :)

What we did notice was that the degrees were all a) multiples of 10, and b) below 260. That led us to believe that they were numbered letters, times ten (so A = 10, B = 20, C = 30, etc).

The numbers were: <tt>100 50 80 90 80 100 50 230 120 130 190 180 130 230 240 50</tt>.

Dividing by 10 gives <tt>10 5 8 9 8 10 5 23 12 13 19 18 13 23 24 5</tt>.

Converting that to the corresponding letters gave us <tt>JEHIH JEWLMSRMWXE</tt>. Clearly not an English sentence, but it looks like a cryptogram (<tt>JEHIH</tt> looks like "THERE" or "WHERE").

That's when we noticed the "A = 50" in the corner, and realized that things were probably shifted by 5. Instead of manually converting it, we found a shift cipher bruteforcer that we could use. The result was: <tt>FADED FASHIONISTA</tt>

Searching for "Faded Fashionista Air and Space" led us to <a href='http://www.smithsonianmag.com/smart-news/amelia-earhart-fashionista-6707662/'>this Smithsonian Article</a>: <em>Amelia Earhart, Fashionista</em>. Neither of us knew where her exhibit was, but eventually we tracked it down on the map and walked around it until we found her Lockheed Vega, the QR code scanned to <tt>amelias_vega</tt>. 

<img src='/blogdata/hackers-of-gravity-15.png' width='600' height='auto' />

<h2>Challenge 3: Hacker of Speed</h2>

This was an image of some folks ready to board a plane or something:

<blockquote>
This super top secret photo has been censored. The security guys looked at this SO fast, maybe they missed something? 

<img src='/blogdata/hackers-of-gravity-03.png' width='600' height='auto' />
</blockquote>

Because of the hint, we started looking for mistakes in the censoring and noticed that they're wearing boots that say "X-15":

<img src='/blogdata/hackers-of-gravity-18.png' /> 

We found pictures of <a href='http://airandspace.si.edu/collections/artifact.cfm?object=nasm_A19690360000'>the X-15 page</a> on the museum's Web site and remembered seeing the plane on the 2nd floor. We reached the artifact and determined that the QR code read <tt>faster_than_superman</tt>. 

Once we got to the artifact, we noticed that we hadn't broken the code yet. Looking carefully at the image, we saw the text at the bottom, <tt>nbdi_tjy_qpjou_tfwfo_uxp</tt>.

As an avid cryptogrammer, I recognized <tt>tfwfo</tt> as likely being "never". Since 'e' is one character before 'f', it seemed likely that it was a single shift ('b'->'a', 'c'->'b', etc). I mentally shifted the first couple letters of the sentence, and it looked right, so I did the entire string while Eric wrote it down: <tt>mach_six_point_seven_two</tt>.

The funny thing is, the word was "seven", not "never", but the "e"s still matched!

<h2>Challenge 4: Hacker of Design</h2>

<blockquote>
While researching some physics based penetration testing, you find this interesting diagram. You feel like you've seen this device before... maybe somewhere or on something in the Air and Space museum? 

<img src='/blogdata/hackers-of-gravity-17.png' width='600' height='auto' />
</blockquote>

The diagram reminded Eric of an engine he saw on an earlier visit, we found the artifact on the other side of the museum: 

<img src='/blogdata/hackers-of-gravity-06.png' width='600' height='auto' />

Unfortunately there was no QR code so we decided to work on decoding the challenge to discover the location of the artifact. 

Now that we'd seen the hint on Challenge 2, we were more prepared for a diagram to help us! In this case, it was a drawing of an atom and the number "10". We concluded that the numbers probably referred to the atomic weight for elements on the periodic table, and converted them as such:

<img src='/blogdata/hackers-of-gravity-12.png' width='600' height='auto' style='background: white' />

10=>Ne
74=>W
... and so on.

After decoding the full string, we ended up with:

<tt>new_plan_schwalbe</tt>

We actually made a mistake in decoding the string, but managed to find it anyways thanks to search autocorrect. :)

After searching for "schwalbe air and space", we found <a href='http://airandspace.si.edu/collections/artifact.cfm?object=nasm_A19600328000'>this article</a>, which led us to the artifact: the Messerschmitt Me 262 A-1a Schwalbe (Swallow). The QR code scanned revealed <tt>the_swallow</tt>.

<img src='/blogdata/hackers-of-gravity-00.png' width='600' height='auto' />

<img src='/blogdata/hackers-of-gravity-05.png' width='600' height='auto' />

<h2>Challenge 5: Hacker of Distance</h2>

<blockquote>While at the bar, listening to some Dual Core, planning your next conference-fest with some fellow hackers, you find this interesting napkin. Your mind begins to wander. Why doesn't Dual Core have a GOLDEN RECORD?! Also, is this napkin trying to tell you something in a around-about way?

<img src='/blogdata/hackers-of-gravity-01.png' width='600' height='auto' />

</blockquote>

The hidden text on this one was obvious… morse code! Typing the code into a phone (not fun!), we ended up with <tt>.- -.. .- ... - .-. .- .--. . .-. .- ... .--. . .-. .-</tt>, which translates to <tt>ADASTRAPERASPERA</tt>

According to Google, that slogan is used by a thousand different organizations, none of which seemed to be space or air related. However, searching for "Golden Record Air and Space" returned several results for the Voyager space probe. We looked at our map and scurried to the exhibit on the other side of the museum: 

<img src='/blogdata/hackers-of-gravity-16.png' width='600' height='auto' />

Once we made it to the exhibit finding the QR code was easy, scanning it revealed, <tt>the_princess_is_in_another_castle</tt>. The decoy flag!

We tried searching keywords from the napkin but none of the results seemed promising. After a few frustrating minutes we saw the museum banquet director and asked him for help. He told us that the plane we were looking for was close to the start of the challenge, we made a dash for the first floor and found the correct Voyager exhibit: 

<img src='/blogdata/hackers-of-gravity-09.png' width='600' height='auto' />

Scanning the QR code revealed the code, <tt>missing_canards</tt>.


<h2>Challenge 6: Hacker of Guidance</h2>

The sixth challenge gave us a map with some information:

<blockquote>
You have intercepted this map that appears to target something. The allies would really like to know the location of the target. Also, they'd like to know what on Earth is at that location. 

<img src='/blogdata/hackers-of-gravity-14.png' width='600' height='auto' />
</blockquote>

We immediately noticed the hex-encoded numbers on the left:

<pre>
35342e3133383835322c
31332e373637373235
</pre>

Which translates to 54.138852,13.767725. We googled the coordinates, and it turned out to be a location in Germany: Flughafenring, 17449 Peenemünde, Germany.

After many failed searches we tried "Peenemünde ww2 air and space", which led to a reference to the German V2 Rocket. Here is the exhibit and QR code: 

<img src='/blogdata/hackers-of-gravity-04.png' width='400' height='auto' />

Scanning the QR code revealed <tt>aggregat_4</tt>, the formal name for the V-2 rocket. 


<h2>Challenge 7: Hacker of Coding</h2>

This is an image with a cipher on the right:

<blockquote>
Your primary computer's 0.043MHz CPU is currently maxed out with other more important tasks, so converting all these books of source code to assembly is entirely up to you.

<img src='/blogdata/hackers-of-gravity-08.png' width='600' height='auto' />
</blockquote>

On the chalkboard is a cipher:

<img src='/blogdata/hackers-of-gravity-19.png' width='200' height='auto' />

We couldn't remember what it was called, and ended up searching for "line dot cipher", which immediately identified it as a pigpen cipher. The pigpen cipher can be decoded with this graphic:

<img src='/blogdata/hackers-of-gravity-13.png' width='300' height='auto' style='background: white' />

Essentially, you find the shape containing the letter that corresponds to the shape in that graphic. So, the first letter is ">" on the chalkboard, which maps to 'T'. The second is the upper three quarters of a square, which matches up with 'H', and the third is a square, which matches to E. And so on.

Initially we found a version that didn't map to the proper English characters, and translated it to:

<img src='/blogdata/hackers-of-gravity-11.png' width='300' height='auto' />

Later, we did it right and found the text "THE BEST SHIP TO COME DOWN THE LINE"

To find the artifact, we googled "0.043MHz", and immediately discovered it was "Apollo 11". 

<img src='/blogdata/hackers-of-gravity-02.png' width='600' height='auto' />

The QR code scanned to <tt>the_eleventh_apollo</tt>

<h2>And that's it!</h2>

And that's the end of the cipher portion of the challenge! We were first place by only a few minutes. :)

The last part of the challenge involved throwing wood airplanes. Because our plane didn't go backwards, it wasn't the worst, but it's nothing to write home about!

But in the end, it was a really cool way to see a bunch of artifacts and also break some codes!
