---
id: 1271
title: 'Using &#8220;Git Clone&#8221; to get Pwn3D'
date: '2012-08-07T08:40:42-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1271'
permalink: /2012/using-git-clone-to-get-pwn3d
categories:
    - Hacking
    - Nmap
    - Tools
---

Hey everybody!

While I was doing a pentest last month, I discovered an attack I didn't previously know, and I thought I'd share it. This may be a Christopher Columbus moment - discovering something that millions of people already knew about - but I found it pretty cool so now you get to hear about it!

One of the first things I do when I'm looking at a Web app - and it's okay to make a lot of noise - is run the [http-enum.nse](http://www.nmap.org/svn/scripts/http-enum.nse) Nmap script. This script uses the [http-fingerprints.lua](http://nmap.org/svn/nselib/data/http-fingerprints.lua) file to find any common folders on a system (basically brute-force browsing). I'm used to seeing admin folders, tmp folders, and all kinds of other interesting stuff, but one folder in particular caught my eye this time - /.git.  
  
Now, I'll admit that I'm a bit of an idiot when it comes to git. I use it from time to time, but not in any meaningful way. So, I had to hit up my friend [@mogigoma](http://www.twitter.com/mogigoma). He was on his cellphone, but managed to get me enough info to make this attack work.

First, I tried to use <tt>git clone</tt> to download the source. That failed, and I didn't understand why, so I gave up that avenue right away.

Next, I wanted to download the /.git folder. Since directory listings were turned on, this was extremely easy:

```
$ mkdir git-test
$ cd git-test
$ wget --mirror --include-directories=/.git http://www.target.com/.git
```

That'll take some time, depending on the size of the repository. When it's all done, go into the folder that wget created and use git --reset:

```
$ cd www.site.com
$ git reset --hard
HEAD is now at [...]
```

Then look around - you have their entire codebase!

```
$ ls
db  doc  robots.txt  scripts  test
```

Browse this for interesting scripts (like test scripts?), passwords, configuration details, deployment, addresses, and more! You just turned your blackbox pentest into a whitebox one, and maybe you got some passwords in the deal! You can also use "git log" to get commit messages, "git remote" to get a list of interesting servers, "git branch -a" to get a list of branches, etc.

## Why does this happen?

When you clone a git repository, it creates a folder for git's metadata - .git - in the folder where you check it out. This is what lets you do a simple "git pull" to get new versions of your files, and can make deployment/upgrades a breeze. In fact, I intentionally leave .git folders in some of my sites - like my hackerspace, [SkullSpace](http://skullspace.ca/.git/). You can find this exact code on github, so there's no privacy issue; this only applies to commercial sites where the source isn't available, or where more than just the code is bring stored in source control.

There are a few ways to prevent this:

- Remove the .git folder after you check it out
- Use a .htaccess file (or apache configuration file) to block access to .git
- Keep the .git folder one level up - in a folder that's not available to the Web server
- Use a framework - like Rails or .NET - where you don't give users access to the filesystem

There may be other ways as well, use what makes sense in your environment!

## Finding this in an automated way

A friend of mine - [Alex Weber](https://www.twitter.com/AlexWebr) - wrote an Nmap script (his first ever!) to detect this vulnerability and print some useful information about the git repository! This script will run by default when you run <tt>nmap -A</tt>, or you can specifically request it by running <tt>nmap --script=[http-git](http://www.nmap.org/svn/scripts/http-git.nse) <target></tt>. You can quickly scan an entire network by using a command like:

```
nmap -sS -PS80,81,443,8080,8081 -p80,81,443,8080,8081 --script=http-git <target>
```

The output for an affected host will look something like:

```

PORT     STATE  SERVICE
80/tcp   open   http
| http-git: 
|   Potential Git repository found at 206.220.193.152:80/.git/ (found 5 of 6
expected files)
|   Repository description: Unnamed repository; edit this file 'description' to name 
the...
|   Remote: https://github.com/skullspace/skullspace.ca.git
|_   -> Source might be at https://github.com/skullspace/skullspace.ca
```

And that's all there is to it! Have fun, and let me know if you have any interesting results so I can post a followup!