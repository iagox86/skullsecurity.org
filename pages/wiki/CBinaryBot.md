---
title: 'Wiki: CBinaryBot'
author: ron
layout: wiki
permalink: "/wiki/CBinaryBot"
date: '2024-08-04T15:51:38-04:00'
---

## CBinaryBot

-   Name: CBinaryBot
-   OS: Windows
-   Language: C++
-   Path: <http://svn.skullsecurity.org:81/ron/old/CBinaryBot>
-   Created: Old
-   State: Incomplete

This was my first attempt at writing a binary bot for Battle.net. I obviously didn\'t know much about what I was doing, but I also refused to use anybody else\'s code. Rather than reversing the libraries, which I didn\'t have the skill to do, I called out to functions within the Starcraft/IX86 files.

The original design was to make fairly abstract classes to handle Battle.net stuff, making it easy to write subclasses for various uses. I was new to OOP at the time, though, so that didn\'t turn out the way I\'d planned. :)

I never finished it, although I \*believe\* it was able to log in successfully. But it\'s been awhile, I could be wrong.

    svn co http://svn.skullsecurity.org:81/ron/old/CBinaryBot
