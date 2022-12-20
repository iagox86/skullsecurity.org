---
id: 2453
title: 'BSidesSF CTF: Easy to hard Rust reversing challenges'
date: '2020-02-26T13:01:25-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2453'
permalink: /2020/bsidessf-ctf-easy-to-hard-rust-reversing-challenges
categories:
    - conferences
    - ctfs
    - re
---

As mentioned in a previous post, I was honoured to once again help run BSidesSF CTF!

This is going to be a quick writeup for three challenges: <tt>config-me</tt>, <tt>rusty1</tt>, and <tt>rusty2</tt>. All three are reversing challenges written in Rust, although the actual amount of reversing required is low for the first two.
<!--more-->
<h2>config-me</h2>

<tt>config-me</tt> (<a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/config-me/challenge/src/main.rs">source</a>) was actually modeled after two different (but identical) vulnerabilities I've run into. The premise is a configuration file with opportunistically encrypted values - that is, some values are encrypted, and some aren't - where you can fool the program into decrypting values for you.

From talking to solvers, I know it was solved in a fairly complex way, but I'm here to go over the simple route only. :)

When you run <tt>config-me</tt>, it reads <tt>config-me.conf</tt> and lets you edit it:

<pre>
$ ./config-me 
Welcome to the Configuration Configurer, the tool for configuring your config files! Now featuring secure encryption!

(This tool is brought to you by the San Francisco Department of Redundancy Department)

Let's start by loading your configuration from ./config-me.conf

------------------------------------

Welcome back, Ron! Your config file currently has 5 entries. What would you like to do?

 [A]dd a key
 [D]elete a key
 [S]ave configuration file
 [L]oad a different configuration file
 [Q]uit
</pre>

The important bit - that many people may have missed - is the welcome message:

<pre>
Welcome back, Ron! Your config file currently has 5 entries. What would you like to do?
</pre>

As you can see, that's in the configuration file:

<pre>
$ cat config-me.conf
name: Ron
password: E$0d6b731d24127ad34e76a78133c91e59f13ab12eaa8dc0ad99e10c71
comment: This configuration service is super duper! I'm going to write all my configurations like this!
conference: BSidesSF 2020
flag: E$af7ac775b3716f6d6ae96fdb6080ef41f4918e0b9f2837b82105b5da39
</pre>

So what we do is change the name value to the flag value:

<pre>
$ cat config-me.conf
name: E$af7ac775b3716f6d6ae96fdb6080ef41f4918e0b9f2837b82105b5da39
password: E$0d6b731d24127ad34e76a78133c91e59f13ab12eaa8dc0ad99e10c71
comment: This configuration service is super duper! I'm going to write all my configurations like this!
conference: BSidesSF 2020
</pre>

Then run the program:

<pre>
$ ./config-me 
Welcome to the Configuration Configurer, the tool for configuring your config files! Now featuring secure encryption!

(This tool is brought to you by the San Francisco Department of Redundancy Department)

Let's start by loading your configuration from ./config-me.conf

------------------------------------

Welcome back, CTF{my_rust_is_rusty}! Your config file currently has 4 entries. What would you like to do?

 [A]dd a key
 [D]elete a key
 [S]ave configuration file
 [L]oad a different configuration file
 [Q]uit

Your choice > 
</pre>

And there's your flag!

<h2>rusty1</h2>

I wanted rusty1 (<a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/rusty1/challenge/src/src/main.rs">source</a> - which was provided) to be a gentle introduction to Rust reversing, as well as preparation (and a reference) for rusty2. It's actually based 95% on <a href="https://github.com/iagox86/game-docker-wrapper">game-docker-wrapper</a>, which is a wrapper for running a Terraria server in Docker (with clean shutdown) that I wrote for my boyfriend. I just changed it to run <tt>/bin/bash</tt> instead of the Terraria server, removed all the flags, and added a bit of obfuscation.

They key lines are in <tt>input_task</tt> and <tt>output_task</tt>:

<pre>
  // Encode
  let mut bytes: Vec<u8> = line.into_bytes().into_iter().map(|b| b - 1).collect();
</pre>

<pre>
  // Output
  let mut bytes: Vec<u8> = line.into_bytes().into_iter().map(|b| b - 1).collect();
</pre>

That shifts each byte of the line by 1, meaning that you have to encode your payloads, and decode responses. <tt>cat /home/ctf/flag.txt</tt> becomes <tt>dbu!0ipnf0dug0gmbh/uyu</tt>. If you send that to the server, you get an encoded response:

<pre>
$ echo 'dbu!0ipnf0dug0gmbh/uyu' | nc rusty1-080e45dc.challenges.bsidessf.net 8832
BSEzxd`g^ats^xnt^g`c^sgd^rntqbd|
</pre>

If you decode that, it's the flag (please forgive the ruby code :) ):

<pre>
irb(main):007:0> 'BSEzxd`g^ats^xnt^g`c^sgd^rntqbd|'.bytes.map {|b| (b+1).chr}.join
=> "CTF{yeah_but_you_had_the_source}"
</pre>

<h2>rusty2</h2>

rusty2 (<a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/rusty2/challenge/src/src/main.rs">source</a>) is nearly identical to rusty1 with two changes: the encoding is more complex, and I don't provide source. My goal was for people to compare rusty1 and rusty2 source to eliminate all the same-y stuff, and just focus on the difference. I'd be curious if people did that?

This time, the encoding is Base32 encoded with a non-standard alphabet: <a href="https://en.wikipedia.org/wiki/Base32#Crockford's_Base32">Crockford</a>. Normally, it's used to ensure easier human readability - ambiguous characters are replaced. But in this case, it's to make it harder to guess. :)

I used <a href="https://www.dcode.fr/crockford-base-32-encoding">this encoder</a> to test, and encoded <tt>cat /home/ctf/flag.txt</tt>:

<pre>
$ echo 'CDGQ881FD1QPTS9FCDT6CBV6DHGPEBKMF1T0' | nc rusty2-7c8a2fad.challenges.bsidessf.net 8833
8DA4CYVFDDGQJQV3DXP6YXBJBXPPAQV9DNR74SBKEDJP8Z8
</pre>

The response decoded into the flag:

<pre>
CTF{okay_colour_me_impressed}
</pre>