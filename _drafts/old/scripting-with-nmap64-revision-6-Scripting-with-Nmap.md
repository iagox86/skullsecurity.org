---
id: 70
title: 'Scripting with Nmap'
date: '2008-09-14T16:38:33-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=70'
permalink: '/?p=70'
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
<p>This function is a little sloppy, in my opinion, and it was clear that I was just feeling my way around the language. I had an especially difficult time trying to convert the time using 64-bit values, because I was getting integer overflows (or so I thought -- it turned that I was displaying as a 32-bit signed integer, so I was getting 0x7FFFFFFF, but Lua was actually storing it as the correct 64-bit value). That's one reason I dislike weakly typed languages, but that's ok. </p>
<p>In the original script (not written by me), the packets were being built like this:</p>
rec1_payload = string.char(0x81, 0x00, 0x00, 0x44) .. ename  ..  winshare
<p>(longer packets were, of course, much worse)</p>
<p>There are a few problems with this method, including:</p>
```

- It's difficult to read
- It's difficult to modify
- Unicode was being negotiated in a language that doesn't handle Unicode (that I'm aware of)
- When this was written, however, there was no really clean way to build packets, so this was a reasonable strategy. Seeing as how the pack() and unpack() functions were since created, and I've gained myself a comfort level working in SMB, I decided to re-write building packets like this:
  
  ```
      local header = bin.pack("<cccccicsslsssss command="" extra="" flags="" flags2="" header="" mid="" pid="" return="" smb:byte="" status="" tid="" uid="">
  <p>As you can see, this is much cleaner (and is also a different packet). </p>
  <p>After awhile, I had some working code that I <a href="http://seclists.org/nmap-dev/2008/q3/0708.html">posted to the mailing list</a>. The response to it was positive, and it was even suggested by one of the developers that I turn it into a nselib library. Still being new to Lua, this was yet another seemingly difficult task! </p>
  <p>Despite the natural fear of the unknown, I started opening other nselib files, and looking at how they worked. And, as it turned out, they were just normal lua files with a single line at the front (a call to module() that I don't really understand). So, I started rearranging my code and pulling things together, and, before I knew it, I had a netbios and smb library! </p>
  <p>Just for fun, here's the interface for my netbios library:</p>
  
  function name_encode(name, scope)
  function name_decode(encoded_name)
  function get_names(host, prefix)
  function get_server_name(host, names)
  function get_user_name(host, names)
  function do_nbstat(host)
  function flags_to_string(flags)
  
  <p>And the SMB interface:</p>
  
  function get_port(host)
  function start(host)
  function stop(socket, uid, tid) 
  function start_raw(host, port)
  function start_netbios(host, port, name)
  function smb_send(socket, header, parameters, data)
  function smb_read(socket)
  function negotiate_protocol(socket)
  function start_session(socket, username, session_key, capabilities)
  function tree_connect(socket, path, uid)
  function tree_disconnect(socket, uid, tid)
  function logoff(socket, uid)
  
  <p>So, I've picked up Lua quite quickly and have been productively converting my<br></br>
  If you're curious, you can get the full source to nmap stuff on my <a href="http://svn.skullsecurity.org:81/ron/security/nmap-ron/">SVN server</a>. </p>
  </cccccicsslsssss>
  ```