---
id: 960
title: 'A call to arms! Web app fingerprints needed!'
date: '2010-11-03T08:01:31-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=960'
permalink: /2010/a-call-to-arms-web-app-fingerprints-needed
categories:
    - Hacking
    - Nmap
    - Tools
---

Hey all,

This is partly an overview of a new Nmap feature that I'm excited about, but is mostly a call to arms. I don't have access to enterprise apps anymore, and I'm hoping you can all help me out by submitting fingerprints! Read on for more.

## http-enum.nse

I couldn't resist throwing in the full history of http-enum.nse, because I'm chatty like that. If you want to get to the good stuff, go ahead and skip to the next section.

Like most of my projects, I was inspired to work on this after I went to a conference and got some cool ideas. This one happened to be Defcon 17, and the catalyst was [Kevin Johnson](http://secureideas.net/)'s talk on [Yokoso](http://yokoso.inguardians.com/). Basically, it had a list of known files, whether images or css files or anything else, and it would check if they exist in a browser's history to see if the person had been there. This was a great starting point for http-enum, so after getting Kevin's permission to use the Yokoso database, we intetegrated it and vastly improved http-enum.nse.

That was over a year ago, and just wasn't as powerful as it could be. So, finally, I decide a re-write was in order.

The logical choice for the file format seemed to be what [Nikto](http://cirt.net/nikto2) uses. After all, we're basically implementing Nikto as an Nmap script, so why not make things inter-operable? I wrote the code, and it worked great, but I discussed the concept with Patrik from [cqure.net](http://cqure.net) and we quickly decided that even the Nikto format lacked the power we really wanted.

My final attempt, which I just committed to Nmap's subversion repository this week, was inspired by my success using a .lua file for my [psexec configuration file](http://nmap.org/svn/nselib/data/psexec/default.lua). Instead of some random file format I invented, it uses a .lua file to build a table of fingerprints. You can take a look at the current version of the fingerprint file in Nmap's [Web SVN](http://nmap.org/svn/nselib/data/http-fingerprints.lua). You'll see that it basically builds a table of fingerprints, each of which is in a well defined format.

## Running http-enum.nse

Running http-enum.nse is pretty straight forward, since it's no different from any other script, so go ahead and skip this section if it's old news.

To use http-enum.nse, simply install the latest version of Nmap from SVN and run it:

```
svn co --username='guest' --password='' svn://svn.insecure.org/nmap ./nmap-svn
cd nmap-svn
./configure && make && make install
nmap --script=http-enum -p80 -d -n www.javaop.com
```

(www.javaop.com is my site, and is designed to come back with interesting results, so you're welcome to scan it)

## http-fingerprints.lua

Each fingerprint can have multiple probes, each containing a path and a method (GET/POST/etc). We may extend this in the future to include more options, like postdata, http headers, etc, if the need arises. The nice thing about Lua tables is that it's completely extensible.

Every fingerprint also contains a match list, which defines the output and, optionally, one or more strings to match. Like Nmap's version check, this can capture portions of the match by including it in parenthesis ('()') and output them using "\\1", "\\2", etc.

There are other options, too, and you can find them by reading the header document of the [http-fingerprints.lua](http://nmap.org/svn/nselib/data/http-fingerprints.lua) file. The file should have more than enough information and examples to start building your own probes right now.

And, speaking of building your own probes...

## A call to arms!

So, this is a powerful format. But, the entire http-fingerprints.lua file, as it stands, was based on static probes, so there are very few cases where it gets really interesting data. I no longer work for a place with a large network, so the best thing <s>I can do</s> my friend Bob can do is scan the Internet at random looking for interesting stuff. And while that's fun, it takes a long time and can upset certain organizations.

I'm hoping the community will help Nmap grow its fingerprint database. You can do this in many ways!

- Go to your major/interesting Web applications at work. Find the main page, or any unauthenticated page. Save the .html and send it, along with the path(s) where it's typically found, to me.
- Go to those applications, and write your own fingerprints. If possible, extract a version number. Send it to me.
- Go through the fingerprints I already have and see if you can improve the match. The current set of fingerprints were written before it was possible to extract versions, match text, etc.
- Go through the long list of "Potentially interesting directory" fingerprints at the end of [http-fingerprints.lua](http://nmap.org/svn/nselib/data/http-fingerprints.lua) and nominate ones that should be deleted or promoted to their own fingerprint.

My email is ron-at-skullsecurity.net. Or you can post it as a comment here, [tweet me](https://twitter.com/iagox86), etc. All my contact info is at the top right.

As you can see, there is a lot that needs to be done, but if we can make this a community effort, and everybody who reads this picks one enterprise application they use and submit a fingerprint for it, we can do some awesome stuff!

My fingerprint database is just over 1000 now.. let's see if we can double that!