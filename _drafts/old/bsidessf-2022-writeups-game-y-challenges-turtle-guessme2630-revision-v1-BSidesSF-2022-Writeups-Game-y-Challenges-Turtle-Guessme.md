---
id: 2643
title: 'BSidesSF 2022 Writeups: Game-y Challenges (Turtle, Guessme)'
date: '2022-06-17T15:18:56-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/?p=2643'
permalink: '/?p=2643'
---

Hey folks,

This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything [on github](https://github.com/bsidessf/ctf-2022-release). Most have either a Dockerfile or instructions on how to run locally. Enjoy!

Here are the four BSidesSF CTF blogs:

- [shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft)
- [mod\_ctfauth, refreshing](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh)
- [turtle, guessme](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme)
- [loca, reallyprettymundane](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane)

## Turtle

While discussing how we could appeal to current trends, I had the idea of making a challenge based on Wordle, called Turdle. My husband talked me out of "Turd", so we ended up with *[Turtle](https://github.com/BSidesSF/ctf-2022-release/tree/main/turtle)*.

I could swear growing up that we had a "game" called E-Z-Logic in elementary school, on the Apple \]\['s we had. It was a graphical version of the [logo programming language](https://en.wikipedia.org/wiki/Logo_%28programming_language%29). You could move the little turtle around, and had to navigate mazes. I tried and failed to find a reference to it, so it may never have existed.

Anyway, combining this mythical game and Wordle, I came up with an impossible Wordle clone: you move the turtle around, and have to match the directions/distances. The original "vulnerability" was supposed to be that you could submit future solutions, and I looked at using a broken RNG or something for future dates. But honestly, solving the current day was difficult enough that I really only had to do that. Ohwell. :)

The vulnerability was in the 2-digit dates used to calculate the path. If you rewind by exactly 100 years, the solution is the same. So you just have to get the solution for 1922, and there ya go! [Solution is here](https://github.com/BSidesSF/ctf-2022-release/blob/main/turtle/solution/solve.rb).

Honestly, this challenge was like 5% writing a challenge, and 95% making it look pretty. I thought it was pretty cool, though. :)

## Guessme

I had the idea that I wanted to make a challenge based on Base64 ambiguity. I've tweeted about it a couple times in the past year, because I thought it was interesting!

The idea of *\[guessme\[(<https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme>)* is that you're given a list of "clues" (which mean nothing), and you have one chance to guess the solution, which is checked using an encrypted base64-encoded token that the user also gets. If you guess wrong, you're sent the answer and it "blacklists" the encrypted token so you can't guess again.

The problem is that base64 is ambiguous! Each base64 character represents six bits of binary data, so four base64 characters are 24 bits or three bytes. But five base64 characters represent 30 bits, or 3.5 bytes. Since you obviously can't have half of a byte, the last 4 bits are disregarded. If you change those bits, you can create a new encoding without changing the original data!

My [solution](https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme/solution) naively increments the final character until it works. Not the cleanest solution, but it works eventually!  
uity. I've tweeted about it a couple times in the past year, because I thought it was interesting!

The idea of [*guessme*](https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme) is that you're given a list of "clues" (which mean nothing), and you have one chance to guess the solution, which is checked using an encrypted base64-encoded token that the user also gets. If you guess wrong, you're sent the answer and it "blacklists" the encrypted token so you can't guess again.

The problem is that base64 is ambiguous! Each base64 character represents six bits of binary data, so four base64 characters are 24 bits or three bytes. But five base64 characters represent 30 bits, or 3.5 bytes. Since you obviously can't have half of a byte, the last 4 bits are disregarded. If you change those bits, you can create a new encoding without changing the original data!

My [solution](https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme/solution) naively increments the final character until it works. Not the cleanest solution, but it works eventually!