---
id: 68
title: 'Scripting with Nmap'
date: '2008-09-12T19:13:48-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=68'
permalink: '/?p=68'
---

As you can see from my past few posts, I've been working on implementing an SMB client in C. Once I got that into a stable state, I decided to pursue the second part of my goal for a bit -- porting that code over to an Nmap script. Never having used Lua before, this was a little intimidating. So, to get my feet wet, I modified an existing script -- netbios-smb-os-discovery.nse -- to have a little bit of extra functionality:

```
-----------------------------------------------------------------------
-- Response from Negotiate Protocol Response (TCP payload 2)
-- Must be SMB response.  Extract the time from it from a fixed
-- offset in the payload.

function extract_time(line)

    local smb, tmp, message, i, timebuf, timezonebuf, time, timezone

    message = 0

    if(string.sub(line, 6, 8) ~= "SMB") then
        message = "Didn't find correct SMB record as a response to the 
                        Negotiate Protocol Response"
        return 0, message
    end

    if(string.byte(line, 9) ~= 0x72) then
        message = "Incorrect Negotiate Protocol Response type"
        return 0, message
    end

    -- Extract the timestamp from the response
    i = 1
    time = 0
    timebuf = string.sub(line, 0x3d, 0x3d + 7)
    while (i 
<p>This function is a little sloppy, in my opinion, and it was clear that I was just feeling my way around the language. I had an especially difficult time trying to convert the time using 64-bit values, because I was getting integer overflows (or so I thought -- it turned that I was displaying as a 32-bit signed integer, so I was getting 0x7FFFFFFF, but Lua was actually storing it as a 64-bit value). That's one reason I dislike weakly typed languages, but that's ok. </p>
<p>Anyways, in the original script (not written by me), the packets were being built like this:</p>
rec1_payload = string.char(0x81, 0x00, 0x00, 0x44) .. ename  ..  winshare
<p>(longer packets were much, much worse)</p>
<p>There are a few problems with this method, though, including:</p>
```

- It's difficult to read
- It's difficult to modify
- Unicode was being negotiated in a language that doesn't handle Unicode (that I'm aware of)
- When this was written, however, there was no really clean way to build packets, so this was a reasonable strategy. Seeing as how the pack() and unpack() functions were since created, and I've gained myself a comfort level working in SMB, I decided to re-write building packets like this:
  
  ```
      local header = bin.pack("<cccccicsslsssss command="" extra="" flags="" flags2="" header="" mid="" pid="" return="" smb:byte="" status="" tid="" uid="">
  <p>As you can see, this is much cleaner (and is also a different packet). </p>
  <p>After awhile, I had some working code that I <a href="http://seclists.org/nmap-dev/2008/q3/0708.html">posted to the mailing list</a>. The response to it was positive, and it was even suggested by one of the developers that I turn it into a nselib library. Still being new to Lua, this was yet another seemingly difficult task! </p>
  <p>Despite the natural fear of the unknown, I started opening other nselib </p>
  </cccccicsslsssss>
  ```