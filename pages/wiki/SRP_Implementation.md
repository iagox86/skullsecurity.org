---
title: 'Wiki: SRP Implementation'
author: ron
layout: wiki
permalink: "/wiki/SRP_Implementation"
date: '2024-08-04T15:51:38-04:00'
---

## SRP

-   Name: SRP
-   OS: Windows
-   Language: C++
-   Path: <http://svn.skullsecurity.org:81/ron/old/SRP>
-   Created: Old
-   State: Complete

This is the original reverse-engineered implementation of the Battle.net SRP algorithm, written by myself, Maddox, and TheMinistered.

I\'m not really sure if it works, but even if it does it can\'t work very cleanly (it uses storm.dll). The first \*good\* version is the one I ported to Java and released in JavaOp(2?).

    svn co http://svn.skullsecurity.org:81/ron/old/SRP
