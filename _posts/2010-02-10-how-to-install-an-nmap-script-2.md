---
id: 459
title: 'How-to: install an Nmap script'
date: '2010-02-10T19:05:31-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=459
permalink: "/2010/how-to-install-an-nmap-script-2"
categories:
- nmap
comments_id: '109638342391157849'

---

Hey all,

I often find myself explaining to people how to install a script that isn't included in Nmap. Rather than write it over and over, this is a quick tutorial.
<!--more-->
<h2>Step 1: Figure out where your scripts are stored</h2>
First, you have to find out where your scripts are installed. The easiest way to do that is to search your harddrive for *.nse files.

Windows:
<pre>Windows Key + F, *.nse</pre>

Linux:
<pre>find / -name '*.nse'
locate *.nse</pre>

<img src='/blogdata/installing-scripts-1.png'>

The common places are:
<pre>c:\Program Files\Nmap\Scripts
/usr/share/nmap/scripts
/usr/local/share/nmap/scripts</pre>

While you're at it, in the same folder as 'scripts', there should be another folder called 'nselib', which contains files named *.lua. That's where libraries go.

<h2>Step 2: Get the script + libraries</h2>
Usually, I'll provide you with a link to the .nse file. All you have to do is download it and copy it into one of the directories above. If there are libraries to go with it (.lua files), copy them into the nselib folder.

Alternatively, you might be able to download them from the Nmap site itself, typically in the <a href='http://nmap.org/svn/scripts/'>scripts folder</a>.

<img src='/blogdata/installing-scripts-2.png'>

<h2>Step 3: Update script database (optional)</h2>
If you want to run the script using a wildcard or category, you have to run Nmap's script update command:
$ nmap --script-updatedb

Note: if you're ok with giving the full name of the script, this isn't necessary.

<h2>Step 4: Run it!</h2>
The last step is to run the script. Whether you are on the commandline or using Zenmap, the argument is the same: --script &lt;scriptname&gt;

<img src='/blogdata/installing-scripts-3.png'>

<h2>Conclusion</h2>
So basically, you find the path where the scripts are stored, copy the script there, and run it. Simple!

Now I can link back to this post whenever I write a new script. :)

Ron
