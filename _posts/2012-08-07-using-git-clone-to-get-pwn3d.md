---
id: 1271
title: Using &#8220;Git Clone&#8221; to get Pwn3D
date: '2012-08-07T08:40:42-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=1271
permalink: "/2012/using-git-clone-to-get-pwn3d"
categories:
- hacking
- nmap
- tools
comments_id: '109638359872796867'

---

Hey everybody!

While I was doing a pentest last month, I discovered an attack I didn't previously know, and I thought I'd share it. This may be a Christopher Columbus moment - discovering something that millions of people already knew about - but I found it pretty cool so now you get to hear about it!

One of the first things I do when I'm looking at a Web app - and it's okay to make a lot of noise - is run the <a href="http://www.nmap.org/svn/scripts/http-enum.nse">http-enum.nse</a> Nmap script. This script uses the <a href='http://nmap.org/svn/nselib/data/http-fingerprints.lua'>http-fingerprints.lua</a> file to find any common folders on a system (basically brute-force browsing). I'm used to seeing admin folders, tmp folders, and all kinds of other interesting stuff, but one folder in particular caught my eye this time - /.git.
<!--more-->
Now, I'll admit that I'm a bit of an idiot when it comes to git. I use it from time to time, but not in any meaningful way. So, I had to hit up my friend <a href='http://www.twitter.com/mogigoma'>@mogigoma</a>. He was on his cellphone, but managed to get me enough info to make this attack work.

First, I tried to use <tt>git clone</tt> to download the source. That failed, and I didn't understand why, so I gave up that avenue right away.

Next, I wanted to download the /.git folder. Since directory listings were turned on, this was extremely easy:
<pre>$ mkdir git-test
$ cd git-test
$ wget --mirror --include-directories=/.git http://www.target.com/.git
</pre>

That'll take some time, depending on the size of the repository. When it's all done, go into the folder that wget created and use git --reset:
<pre>$ cd www.site.com
$ git reset --hard
HEAD is now at [...]</pre>

Then look around - you have their entire codebase!
<pre>$ ls
db  doc  robots.txt  scripts  test
</pre>

Browse this for interesting scripts (like test scripts?), passwords, configuration details, deployment, addresses, and more! You just turned your blackbox pentest into a whitebox one, and maybe you got some passwords in the deal! You can also use "git log" to get commit messages, "git remote" to get a list of interesting servers, "git branch -a" to get a list of branches, etc.
  
<h2>Why does this happen?</h2> 
When you clone a git repository, it creates a folder for git's metadata - .git - in the folder where you check it out. This is what lets you do a simple "git pull" to get new versions of your files, and can make deployment/upgrades a breeze. In fact, I intentionally leave .git folders in some of my sites - like my hackerspace, <a href='http://skullspace.ca/.git/'>SkullSpace</a>. You can find this exact code on github, so there's no privacy issue; this only applies to commercial sites where the source isn't available, or where more than just the code is bring stored in source control.

There are a few ways to prevent this:
<ul>
  <li>Remove the .git folder after you check it out</li>
  <li>Use a .htaccess file (or apache configuration file) to block access to .git</li>
  <li>Keep the .git folder one level up - in a folder that's not available to the Web server</li>
  <li>Use a framework - like Rails or .NET - where you don't give users access to the filesystem</li>
</ul>

There may be other ways as well, use what makes sense in your environment!

<h2>Finding this in an automated way</h2>
A friend of mine - <a href='https://www.twitter.com/AlexWebr'>Alex Weber</a> - wrote an Nmap script (his first ever!) to detect this vulnerability and print some useful information about the git repository! This script will run by default when you run <tt>nmap -A</tt>, or you can specifically request it by running <tt>nmap --script=<a href="http://www.nmap.org/svn/scripts/http-git.nse">http-git</a> &lt;target&gt;</tt>. You can quickly scan an entire network by using a command like:

<pre>nmap -sS -PS80,81,443,8080,8081 -p80,81,443,8080,8081 --script=http-git &lt;target&gt;</pre>

The output for an affected host will look something like:
<pre>
PORT     STATE  SERVICE
80/tcp   open   http
| http-git: 
|   Potential Git repository found at 206.220.193.152:80/.git/ (found 5 of 6
expected files)
|   Repository description: Unnamed repository; edit this file 'description' to name 
the...
|   Remote: https://github.com/skullspace/skullspace.ca.git
|_   -> Source might be at https://github.com/skullspace/skullspace.ca
</pre>

And that's all there is to it! Have fun, and let me know if you have any interesting results so I can post a followup!
