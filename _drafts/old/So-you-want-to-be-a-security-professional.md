---
id: 1265
title: 'So you want to be a security professional?'
date: '2012-05-26T12:07:41-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1265'
permalink: '/?p=1265'
categories:
    - Default
---

Hey everybody,

I'm often asked the question, "how do I get started in information security?". I find myself typing out the same advice over and over, so I thought I'd put together a blog post with my ideas on the topic. It's a wide and varied topic, and this is just my opinion on things. Feel free to leave a comment with your thoughts!

The first thing to keep in mind is that security is a wide and varied field. There are developers, reverse engineers, researchers, managers, CISOs, auditors, analysts, and more! I've personally been a PHP developer for a small local company, a researcher for [Symantec](http://www.symantec.com/), a security analyst for the [Government of Manitoba](http://www.gov.mb.ca/), and, currently a reverse engineer for [Tenable Network Security](http://www.tenable.com/). I'll briefly go over what I did to get to where I am, and then give my advice.

In highschool and [university](http://www.umanitoba.ca), I started playing Starcraft, and eventually got involved with a group called SCBackstab and then [\[vL\]](http://www.valhallalegends.com/). I considered the guy who ran SCBackstab - Yoshi - to be a mentor; he taught me the fundamentals of what I know about programming. I also met a man named Thing, who taught me about networking for the first time, and gave me space on his server and my first exposure to Linux operating systems, which I knew nothing about.

During that time, Yoshi wrote a program called the [SCBackstab Nickspoofer](http://skullsecurity.org/wiki/index.php/SCBSNickSpoofer), a program designed to change your in-game nickname in Starcraft. You could join games with names such as "Blizzard Staff" or "computer", and laugh when the other players believed it. He shared the sourcecode with me, and that gave me my first taste of developing hacks for games. I later wrote my own program - [UNickSpoofer](http://skullsecurity.org/wiki/index.php/UNickSpoofer) - that was similar to Yoshi's, except it supported more games (Starcraft, Warcraft 2, and Warcraft 3).

I later discovered that it was possible to add colours to your messages in Starcraft by adding special characters. I think I saw somebody else do it - I'm not really sure. But using similar techniques to the nickspoofer, I discovered that I could edit outgoing messages in a memory buffer to add special characters. I automated the process of finding and editing messages, and wrote a program called [MessageSpoofer](http://skullsecurity.org/wiki/index.php/MessageSpoofer) to automate it. I also discovered you could remove your name from the start of a message by adding a bunch of newlines in front of your message - the username would wind up off the buffer, and only the message could be displayed. We had a good time faking messages like "Nuclear Launch Detected", "Virus Uploading..." "iago has left the game", "experimental AI mode activated", and so on.