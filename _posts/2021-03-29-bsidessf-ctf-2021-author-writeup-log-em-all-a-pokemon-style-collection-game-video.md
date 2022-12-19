---
id: 2588
title: 'BSidesSF CTF 2021 Author writeup: log-em-all, a Pokemon-style collection game [video]'
date: '2021-03-29T10:39:10-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2588'
permalink: /2021/bsidessf-ctf-2021-author-writeup-log-em-all-a-pokemon-style-collection-game-video
categories:
    - CTFs
    - 'Reverse Engineering'
    - Video
---

This is a video walkthrough of Log 'em All, a difficult Hacking / Reverse Engineering challenge based on a classic bug in Pokemon Red. You can view the video below, or [directly on Youtube](https://www.youtube.com/watch?v=sY5V-vvipK4).

I've never done a video-based writeup before, so I'd love feedback!

<iframe allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen="" frameborder="0" height="315" loading="lazy" src="https://www.youtube-nocookie.com/embed/sY5V-vvipK4" title="YouTube video player" width="560"></iframe>

If you want to run this yourself, from a Linux computer with Docker (and a user in the appropriate group), run:

```
$ git clone https://github.com/BSidesSF/ctf-2021-...​
$ cd ctf-2021-release/logemall/challenge
$ docker build . -t test
$ docker run -p666:666 --rm -ti test
```

(Then in another window)

```
$ nc -v localhost 666
```