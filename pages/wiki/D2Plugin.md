---
title: 'Wiki: D2Plugin'
author: ron
layout: wiki
permalink: "/wiki/D2Plugin"
date: '2024-08-04T15:51:38-04:00'
---

## D2Plugin

-   Name: D2Plugin
-   OS: Windows
-   Language: C++
-   Path: <http://svn.skullsecurity.org:81/ron/old/D2Plugin>, <http://svn.skullsecurity.org:81/ron/old/D2Plugin2>
-   Created: Old
-   State: Complete

I wrote this plugin for Diablo 2 along with Eibro. The first version was heavily object oriented (Eibro\'s doing, he was very much into object-oriented programming). The second one was more procedural, since I basically wrote it myself.

I don\'t recall which version of Diablo 2 it was for, but the patch did a few things:

-   Automatically exits games when health falls below a certain threshold
-   Set right or left skill to \"kick\" (a hidden skill)
-   Displays packets to the user while playing (to help reverse the protocol)
-   Allows read/edit of memory addresses while playing (to help reverse the game)

This was actually a pretty slick program, I enjoyed writing it a lot.

    svn co http://svn.skullsecurity.org:81/ron/old/D2Plugin

    svn co http://svn.skullsecurity.org:81/ron/old/D2Plugin2
