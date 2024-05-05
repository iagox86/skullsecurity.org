---
id: 440
title: 'How-to: install an Nmap script'
date: '2010-02-10T14:14:30-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=440'
permalink: '/?p=440'
---

Hey all,

I often find myself explaining to people how to install a script that isn't included in Nmap. Rather than write it over and over, this is a quick tutorial.

## Step 1: Figure out where your scripts are stored

First, you have to find out where your scripts are installed. The easiest way to do that is to search your harddrive for \*.nse files.

Windows:

```
Windows Key + F, *.nse
```

Linux:

```
find / -name '*.nse'
locate *.nse
```

![](/blogdata/installing-scripts-1.png)

The common places are:

```
c:\Program Files\Nmap\Scripts
/usr/share/nmap/scripts
/usr/local/share/nmap/scripts
```

While you're at it, in the same folder as 'scripts', there should be another folder called 'nselib', which contains files named \*.lua. That's where libraries go.

## Step 2: Get the script + libraries

Usually, I'll provide you with a link to the .nse file. All you have to do is download it and copy it into one of the directories above. If there are libraries to go with it (.lua files), copy them into the nselib folder.

Alternatively, you might be able to download them from the Nmap site itself, typically in the [scripts folder](http://nmap.org/svn/scripts/).

## Step 3: Move the file

Next, move the downloaded script into the folder with the rest of the scripts. Naturally, you can download it straight to this folder if you want to.

![](/blogdata/installing-scripts-2.png)

## Step 4: Update script database (optional)

If you want to run the script using a wildcard or category, you have to run Nmap's script update command:  
$ nmap --script-updatedb

Note: if you're ok with giving the full name of the script, this isn't necessary.

## Step 5: Run it!

The last step is to run the script. Whether you are on the commandline or using Zenmap, the argument is the same: --script <scriptname>

![](/blogdata/installing-scripts-3.png)

## Conclusion

So basically, you find the path where the scripts are stored, copy the script there, and run it. Simple!

Now I can link back to this post whenever I write a new script. :)

Ron