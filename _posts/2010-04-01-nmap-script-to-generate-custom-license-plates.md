---
id: 723
title: 'Nmap script to generate custom license plates'
date: '2010-04-01T08:47:30-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=723'
permalink: /2010/nmap-script-to-generate-custom-license-plates
categories:
    - 'April Fools'
    - Humour
    - Nmap
---

Hey all,

In honour of this special day, I'm releasing an Nmap script I wrote a few months ago as a challenge: [http-california-plates.nse](/blogdata/http-california-plates.nse). To install it, ensure you're at the **latest svn version of Nmap** (I fixed a bug in http.lua last night that prevented this from working, so only the svn version as of today will work), download [http-california-plates.nse](/blogdata/http-california-plates.nse), and [install it](http://www.skullsecurity.org/blog/?p=459).  
  
To use it, you run Nmap as usual, against any server and any ports, the http-california-plates script, and a special script argument called 'plate'. 'plate' can be two to seven characters, and the script will validate whether or not it's a valid plate in California, and whether or not it's already being used!

Here is what you can expect to see if a plate isn't available:

```
$ nmap -p22 localhost --script=http-california-plates --script-args=plate=abcdef

Starting Nmap 5.30BETA1 ( http://nmap.org ) at 2010-04-01 08:27 CDT
NSE: Script Scanning completed.
Nmap scan report for localhost (127.0.0.1)
Host is up (0.0011s latency).
PORT   STATE SERVICE
22/tcp open  ssh

Host script results:
|_http-california-plates: Plate is not available!
```

And here's what you see if a plate IS available:

```
$ ./nmap --script=http-california-plates --script-args=plate=inscure -p22 localhost

Starting Nmap 5.30BETA1 ( http://nmap.org ) at 2010-04-01 08:31 CDT
[...]

Host script results:
|_http-california-plates: Plate is available!
```

Never again will you have to spend your valuable seconds finding the California DMV's [online tool for checking](https://xml.dmv.ca.gov/IppWebV3/welcome.do)!

## How's it work?

This script is dead simple -- it just makes three HTTP requests to a site. The first one is a simple GET request to this page:  
https://xml.dmv.ca.gov/IppWebV3/initPers.do

This page is simply generates the session cookie, which is saved. The second request is a POST to here (I'm adding the arguments as GET to save space):  
https://xml.dmv.ca.gov/IppWebV3/processPers.do?imageSelected=plateMemorial.jpg&vehicleType=AUTO&isVehLeased=no&plateType=R

Finally, the actual license plate it sent:  
https://xml.dmv.ca.gov/IppWebV3/processConfigPlate.do?kidsPlate=&plateType=R&plateLength=7&plateChar0=A&plateChar1=B&...

And the response is parsed for success, failure, or error message.

Done!

Happy April Fool's :)