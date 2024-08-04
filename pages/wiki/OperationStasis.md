---
title: 'Wiki: OperationStasis'
author: ron
layout: wiki
permalink: "/wiki/OperationStasis"
date: '2024-08-04T15:51:38-04:00'
---

## Operation Stasis {#operation_stasis}

-   Name: Operation Stasis
-   OS: Windows
-   Language: C++
-   Path: <http://svn.skullsecurity.org:81/ron/old/OperationStasis>
-   Created: Old
-   State: Working, but buggy

This is one of many Starcraft plugins I\'ve written over the years. I believe it\'s the last one I did in C++ (I moved to c). As far as I remember, it had several working features and several non-working ones.

The problem is, it suffers from a race condition due to my foolish usage of static variables among threads. I never got around to fixing it.

    svn co http://svn.skullsecurity.org:81/ron/old/OperationStasis
