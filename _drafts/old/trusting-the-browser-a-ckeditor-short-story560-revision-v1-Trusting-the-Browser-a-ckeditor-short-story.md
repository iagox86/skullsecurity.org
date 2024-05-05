---
id: 1670
title: 'Trusting the Browser (a ckeditor short story)'
date: '2013-10-14T13:03:31-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/560-revision-v1'
permalink: '/?p=1670'
---

My name is Matt Gardenghi. Ron seems to think it important that this post be clearly attributed to someone else (this fact might worry me). I'm an occasional contributor here (see: [Bypassing AV](http://www.skullsecurity.org/blog/?p=261 "Bypassing AV")). I handle security at Bob Jones University and also perform pentests on the side. (So if you need someone to do work, here's my shameless plug.) I have acquired the oddly despised CISSP and the more respectable GCFA, GPEN, and GWAPT.  
\------------------

I know a company that purchased some Web 2.0 services. We'll leave it at that, to protect the guilty. :-p

So, one day a bored user decided that the editor used on the site was annoying. He used GreaseMonkey to replace the editor with his preferred editor. This was "Clue #1" that a problem existed with the Web 2.0 service.  
  
Fast forward four months. \[Many, many, many\]^2 security holes and fixes later, the "web 2.0" service has been secured.... They had an audit that found that they passed XSS testing. This is Clue #2. You don't start with Mack Truck sized holes and claim to be perfectly secure three months later. It just doesn't happen. Either the audit was bad (likely low grade as it claimed to focus on the OWASP Top 10), or something. A good audit should have found more.

Fast forward another three months. Within ten minutes, slightly more esoteric forms of XSS work. Ron once showed me how you could use the onerror="javascript:stuff" piece of the HTML image tag to bypass filtering. (Hint: it works) Clue #3; problems still exist. But hey, who's content with an esoteric XSS attack in a backwater location on the service? Not me anyway. Remember the user who rewrote the page via GreaseMonkey? Yeah, let's go back to that. In another section of the service, I found that the ckeditor had a "Source" toggle. Well, now, this is fun. I can do lot's of fun stuff there. But again, it's the backwoods. In the main locations the "Source" toggle is disabled.

Well, to compress about 30 minutes into one sentence, I figured out how to re-enable it. Hint: Just add " Source " to the toolbars in the config.js file as it comes to your browser. (You \*do\* use an interception proxy don't you?) This web 2.0 service thought that the absence of a "source" button and the built in ckeditor cleaning was protecting them. Not so much.

So, now we have a simple way to stuff gunk\* into the web page. Unless the site re-filters the data from ckeditor on insert into the DB or upon output, we have all sorts of hacking going on. \*gunk == BeEF.

In retrospect, this was the hard way of doing it. It works, but if you are going to the work of proxies, there's a faster solution. Just modify the POST parameters. (Realizing this was a face-palm moment. Oh well, live and learn.)

In this case, the problem is that the web 2.0 service instituted security by the rules. They were told to secure xyz, so they did. They didn't comprehend the reasons for securing it nor how a bad guy would attempt to bypass it; they failed to comprehend the bigger picture. They treated security as a point in time event and not a treadmill that never ends. (Depressing imagery but correct.)

Ensure that your devs recognize the threat and how it can be exploited. Educate them, otherwise these sorts of holes will just happen to your company on a continuous basis.

Next time you see a WYSIWYG editor, try manipulating the POST parameters and see if they are checking the results on the server. Let me know how it goes in the comments below or on twitter: @matt\_gardenghi or email me at mtgarden -at- gmail.

Enjoy.