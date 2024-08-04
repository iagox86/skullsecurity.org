---
title: 'Wiki: FakeBattlenet'
author: ron
layout: wiki
permalink: "/wiki/FakeBattlenet"
date: '2024-08-04T15:51:38-04:00'
---

## FakeBattlenet

-   Name: FakeBattlenet
-   OS: Windows
-   Language: Visual Basic 6
-   Path: <http://svn.skullsecurity.org:81/ron/old/FakeBattlenet>
-   Created: Old
-   State: Incomplete

I wrote this while initially reverse engineering Battle.net, I think (it\'s possible I wrote it while reversing SRP, though). It creates a fake Battle.net server that the client can connect to. It helped me test out the protocol to see how the game would react to error conditions.

If I recall correctly, I think I ended up using a plugin for this instead of writing my own server.

    svn co http://svn.skullsecurity.org:81/ron/old/FakeBattlenet
