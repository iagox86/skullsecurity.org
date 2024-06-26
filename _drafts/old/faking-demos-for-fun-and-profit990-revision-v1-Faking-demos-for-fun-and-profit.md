---
id: 1685
title: 'Faking demos for fun and profit'
date: '2013-10-14T13:05:46-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/990-revision-v1'
permalink: '/?p=1685'
---

<s>This week</s> <s>Last week</s> <s>Earlier this month</s> <s>Last month</s> Last year (if this intro doesn't work, I give up trying to post this :) ), I presented at [B-Sides Ottawa](http://www.securitybsides.com/w/page/26807426/BSidesOttawa), which was put on by [Andrew Hay](http://www.andrewhay.ca/) and others (and sorry I waited so long before posting this... I kept revising it and not publishing). I got to give a well received talk, meet a lot of great folks, see Ottawa for the first time, and learn that I am a good solid Security D-lister. w00t!

Before I talk about the fun part, where I completely faked out my demo, if you want the slides you can grab them here:  
<http://svn.skullsecurity.org:81/ron/security/2010-11-bsides-ottawa/>. You can find more info about the conference and people's slides [at the official site](http://www.securitybsides.com/w/page/26807426/BSidesOttawa). And finally, [here's a picture of me](http://www.flickr.com/photos/jack_daniel/5172813651/in/set-72157625373535766/) trying to look casual.

B-sides conferences, for those of you who don't know, are awesome little conferences that often (but not always) piggyback on other conferences. They are free (or cheap), run by volunteers, and have raw and technical talks. B-sides Ottawa was no exception, and I'm thrilled I had the chance to not only see it, but take part in it. I really hope to run our own B-sides Winnipeg next year!  
  
Anyway, my talk was on the Nmap Scripting Engine. I wrote a talk and a couple demoes, both of which are available at the above link. My plan was to do two live demoes, coded on stage, with no safety net. Pre-recording demoes is cheating! The demoes were the following:

- Perform a DNS lookup and scan a host's mailservers
- Look up the router's MAC address in a geolocation service and show the google map

I practiced them over and over, and they were looking great, so I showed up at B-sides ready to go!

Then I found out I had no Internet connection.

Crap!

So, that night I had a lot of work to do, re-writing my entire talk to work with no Internet connection. As a natural procrastinator, I ended up hanging out with people until the middle of the night, so when I finally made it back to the hotel I couldn't do anything. So, four hours later, first thing in the morning, I got to work.

## Problem 1: DNS

So the first problem was that I had to perform DNS queries, both for MX and A records. I briefly considered using a shellscript and netcat to do this, but I'm not \*that\* crazy. Instead, I made some minor changes to [dnsxss](/wiki/index.php/Dnsxss) to return a few fake mailservers for MX queries.

The default behaviour of dnsxss returns 127.0.0.1 for all A queries, and that's exactly what I wanted.

Finally, I set the DNS server of my laptop to 127.0.0.1. Now, no matter what I requested, the right results came back. Problem solved!

## Problem 2: No mail servers!

The next problem I ran into is that I wanted to scan a mailserver. That was a simple matter of installing a SMTP server and making sure it ran on startup. Another option would have been faking it with netcat and a static response.

With those two problems solved, I had a workable first demo! On to the second...

## Problem 3: No MAC address

My second script was supposed to look up a MAC address's geolocation information, but what can I do without a MAC address? The easy way would have been to hardcode a MAC into the script, but that's cheating. Nmap doesn't return the MAC address for the loopback address, so I had to find a better way to cheat than simply redirecting DNS.

There's probably a far better way to do this, but I decided to simply set one of my VMWare instances to auto-start on boot. I could then scan it as if I was scanning my router with no one the wiser. Of course, its MAC address isn't going to be in the geolocation database, but that's okay because....

## Problem 4: Geolocation

To use Google's geolocation service, you obviously need to connect to Google (specifically, www.google.com/loc/json). Requests to www.google.com were already heading to localhost, thanks to my fake DNS server, so this was pretty easy. I created a valid JSON request that appeared to go to Google, and that appeared to have the proper MAC address embedded in it. Of course, it wasn't really going to Google, and it wasn't really the wireless MAC address. But because my Web server running on localhost always returned the proper coordinates, that didn't matter very much.

As a bonus, if I fudged up the MAC address encoding in any way, it wouldn't matter because it was returning a static page.

## Problem 5: Google maps 

The grand finale was going to be when I copied/pasted the latitude and longitude into Google Maps and our current location popped up. Obviously, that couldn't happen. But, my fake DNS server, along with a screenshot of Google Maps, looked surprisingly realistic.

One little point - because I wanted the URL http://maps.google.ca/maps?q=... to work, I had to add a content-type override to a .htaccess file. Not very exciting, but eh?

## Done!

The week following B-sides Ottawa, I had the privilege to speak at [DeepSec](https://deepsec.net/) in Vienna, Austria (I spoke on [password breaches](/wiki/index.php/Passwords), in case you're curious). Later that week, I was asked to do a short talk for [Metalab](http://metalab.at/wiki/English), an Austrian hackerspace. I pulled out this talk again, without my cobbled together infrastructure, and wrote the scripts on stage. This time I had an Internet connection and guess what? They worked the first time! Sven Guckes also posted pictures of me [getting ready](http://www.guckes.net/pics.2010-11-27/.tmp/SL385042.JPG.html) and [speaking](http://www.guckes.net/pics.2010-11-27/.tmp/SL385050.JPG.html).

And there! I \*finally\* posted this! See you all at Shmoocon later this week!