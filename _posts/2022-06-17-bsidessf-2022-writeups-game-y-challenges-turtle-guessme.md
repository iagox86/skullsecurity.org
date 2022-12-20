---
id: 2630
title: 'BSidesSF 2022 Writeups: Game-y Challenges (Turtle, Guessme)'
date: '2022-06-17T15:19:21-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2630'
permalink: /2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme
categories:
    - bsidessf-2022
    - ctfs
---

<p>Hey folks,</p>
<p>This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything <a href="https://github.com/bsidessf/ctf-2022-release">on github</a>. Most have either a Dockerfile or instructions on how to run locally. Enjoy!</p>
<!--more-->
<p>Here are the four BSidesSF CTF blogs:</p>
<ul>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft">shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh">mod_ctfauth, refreshing</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme">turtle, guessme</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane">loca, reallyprettymundane</a></li>
</ul>
<h2>Turtle</h2>
<p>While discussing how we could appeal to current trends, I had the idea of making a challenge based on Wordle, called Turdle. My husband talked me out of &quot;Turd&quot;, so we ended up with <em><a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/turtle">Turtle</a></em>.</p>
<p>I could swear growing up that we had a &quot;game&quot; called E-Z-Logic in elementary school, on the Apple ]['s we had. It was a graphical version of the <a href="https://en.wikipedia.org/wiki/Logo_%28programming_language%29">logo programming language</a>. You could move the little turtle around, and had to navigate mazes. I tried and failed to find a reference to it, so it may never have existed.</p>
<p>Anyway, combining this mythical game and Wordle, I came up with an impossible Wordle clone: you move the turtle around, and have to match the directions/distances. The original &quot;vulnerability&quot; was supposed to be that you could submit future solutions, and I looked at using a broken RNG or something for future dates. But honestly, solving the current day was difficult enough that I really only had to do that. Ohwell. :)</p>
<p>The vulnerability was in the 2-digit dates used to calculate the path. If you rewind by exactly 100 years, the solution is the same. So you just have to get the solution for 1922, and there ya go! <a href="https://github.com/BSidesSF/ctf-2022-release/blob/main/turtle/solution/solve.rb">Solution is here</a>.</p>
<p>Honestly, this challenge was like 5% writing a challenge, and 95% making it look pretty. I thought it was pretty cool, though. :)</p>
<h2>Guessme</h2>
<p>I had the idea that I wanted to make a challenge based on Base64 ambiguity. I've tweeted about it a couple times in the past year, because I thought it was interesting!</p>
<p>The idea of <em>[guessme[(<a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme">https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme</a>)</em> is that you're given a list of &quot;clues&quot; (which mean nothing), and you have one chance to guess the solution, which is checked using an encrypted base64-encoded token that the user also gets. If you guess wrong, you're sent the answer and it &quot;blacklists&quot; the encrypted token so you can't guess again.</p>
<p>The problem is that base64 is ambiguous! Each base64 character represents six bits of binary data, so four base64 characters are 24 bits or three bytes. But five base64 characters represent 30 bits, or 3.5 bytes. Since you obviously can't have half of a byte, the last 4 bits are disregarded. If you change those bits, you can create a new encoding without changing the original data!</p>
<p>My <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme/solution">solution</a> naively increments the final character until it works. Not the cleanest solution, but it works eventually!
uity. I've tweeted about it a couple times in the past year, because I thought it was interesting!</p>
<p>The idea of <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme"><em>guessme</em></a> is that you're given a list of &quot;clues&quot; (which mean nothing), and you have one chance to guess the solution, which is checked using an encrypted base64-encoded token that the user also gets. If you guess wrong, you're sent the answer and it &quot;blacklists&quot; the encrypted token so you can't guess again.</p>
<p>The problem is that base64 is ambiguous! Each base64 character represents six bits of binary data, so four base64 characters are 24 bits or three bytes. But five base64 characters represent 30 bits, or 3.5 bytes. Since you obviously can't have half of a byte, the last 4 bits are disregarded. If you change those bits, you can create a new encoding without changing the original data!</p>
<p>My <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/guessme/solution">solution</a> naively increments the final character until it works. Not the cleanest solution, but it works eventually!</p>