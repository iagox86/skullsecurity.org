---
id: 67
title: 'Scripting with Nmap'
date: '2008-09-12T19:02:42-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=67'
permalink: '/?p=67'
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
```