---
id: 64
title: 'My Scripting Experience with Nmap'
date: '2008-09-14T16:41:06-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=64'
permalink: /2008/scripting-with-nmap
categories:
    - NetBIOS/SMB
---

As you can see from my past few posts, I've been working on implementing an SMB client in C. Once I got that into a stable state, I decided to pursue the second part of my goal for a bit -- porting that code over to an Nmap script. Never having used Lua before, this was a little intimidating. So, to get my feet wet, I modified an existing script -- netbios-smb-os-discovery.nse -- to have a little bit of extra functionality:
<!--more-->
<pre>-----------------------------------------------------------------------
-- Response from Negotiate Protocol Response (TCP payload 2)
-- Must be SMB response.  Extract the time from it from a fixed
-- offset in the payload.

function extract_time(line)

    local smb, tmp, message, i, timebuf, timezonebuf, time, timezone

    message = 0

    if(string.sub(line, 6, 8) ~= "SMB") then
        message = "Didn't find correct SMB record as a response to the \
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
    while (i <= 8) do
        time = time + 1.0 + (bit.lshift(string.byte(timebuf, i), 8 * (i - 1)))
        i = i + 1
    end
    -- Convert time from 1/10 microseconds to seconds
    time = (time / 10000000) - 11644473600;

    -- Extract the timezone offset from the response
    timezonebuf = string.sub(line, 0x45, 0x45 + 2)
    timezone = (string.byte(timezonebuf, 1) + 
                     (bit.lshift(string.byte(timezonebuf, 2), 8)))

    -- This is a nasty little bit of code, so I'll explain it in detail. 
    -- If the timezone has the 
    -- highest-order bit set, it means it was negative. If 
    -- so, we want to take the two's complement
    -- of it (not(x)+1) and divide by 60, to get minutes. 
    -- Otherwise, just divide by 60. 
    -- To further complicate things (as if we needed 
    -- _that_!), the timezone offset is the number of
    -- minutes you'd have to add to the time to get to 
    -- UTC, so it's actually the negative of what
    -- we want. Confused yet?
    if(timezone == 0x00) then
        timezone = "UTC+0"
    elseif(bit.band(timezone, 0x8000) == 0x8000) then
        timezone = "UTC+" .. ((bit.band(bit.bnot(timezone), 0x0FFFF) + 1) / 60)
    else
        timezone = "UTC-" .. (timezone / 60)
    end

    return (os.date("%Y-%m-%d %H:%M:%S", time) .. " " .. timezone), message;

end
</pre>

This function is a little sloppy, in my opinion, and it was clear that I was just feeling my way around the language. I had an especially difficult time trying to convert the time using 64-bit values, because I was getting integer overflows (or so I thought -- it turned that I was displaying as a 32-bit signed integer, so I was getting 0x7FFFFFFF, but Lua was actually storing it as the correct 64-bit value). That's one reason I dislike weakly typed languages, but that's ok. 

In the original script (not written by me), the packets were being built like this:
<pre>rec1_payload = string.char(0x81, 0x00, 0x00, 0x44) .. ename  ..  winshare</pre>
(longer packets were, of course, much worse)

There are a few problems with this method, including:
<ul>
<li>It's difficult to read</li>
<li>It's difficult to modify</li>
<li>Unicode was being negotiated in a language that doesn't handle Unicode (that I'm aware of)</li>
<li>

When this was written, however, there was no really clean way to build packets, so this was a reasonable strategy. Seeing as how the pack() and unpack() functions were since created, and I've gained myself a comfort level working in SMB, I decided to re-write building packets like this:
<pre>    local header = bin.pack("<CCCCCICSSLSSSSS",
                smb:byte(1),  -- Header
                smb:byte(2),  -- Header
                smb:byte(3),  -- Header
                smb:byte(4),  -- Header
                command,      -- Command
                0,            -- status
                flags,        -- flags
                flags2,       -- flags2
                0,            -- extra (pid_high)
                0,            -- extra (signature)
                0,            -- extra (unused)
                tid,          -- tid
                0,            -- pid
                uid,          -- uid
                0             -- mid
            )

    return header
</pre>
As you can see, this is much cleaner (and is also a different packet). 

After awhile, I had some working code that I <a href="http://seclists.org/nmap-dev/2008/q3/0708.html">posted to the mailing list</a>. The response to it was positive, and it was even suggested by one of the developers that I turn it into a nselib library. Still being new to Lua, this was yet another seemingly difficult task! 

Despite the natural fear of the unknown, I started opening other nselib files, and looking at how they worked. And, as it turned out, they were just normal lua files with a single line at the front (a call to module() that I don't really understand). So, I started rearranging my code and pulling things together, and, before I knew it, I had a netbios and smb library! 

Just for fun, here's the interface for my netbios library:
<pre>
function name_encode(name, scope)
function name_decode(encoded_name)
function get_names(host, prefix)
function get_server_name(host, names)
function get_user_name(host, names)
function do_nbstat(host)
function flags_to_string(flags)
</pre>

And the SMB interface:
<pre>
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
</pre>

So, the bottom line is that I've picked up Lua quite quickly and have been quickly porting my C code to Lua. Woohoo! 

And if you're curious, you can get the full source to nmap stuff on my <a href='http://svn.skullsecurity.org:81/ron/security/nmap-ron/'>SVN server</a>. 
