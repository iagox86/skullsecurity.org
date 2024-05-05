---
id: 94
title: 'Calling RPC functions over SMB'
date: '2008-10-30T21:11:21-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=94'
permalink: '/?p=94'
---

Hi everybody!

This is going to be a fairly high level discussion on the sequence of calls and packets required to make MSRPC calls over the SMB protocol. I've learned this from a combination of reading the book [Implementing CIFS](http://www.ubiqx.org/cifs/), watching other tools do their stuff with Wireshark, and plain ol' guessing/checking.

# Making a SMB connection

SMB can be performed over ports tcp/445 and tcp/139. Port 445 allows for a "raw" SMB connection, while 139 is "SMB over NetBIOS". Effectively, they are the same thing with two differences:

1. SMB over NetBIOS requires a "NetBIOS Session Request" packet, which is a client saying, "hi, I'm xxx, can I connect to you?"
2. SMB over NetBIOS has a packet length field that's 17 bits (maximum = 131,072), while Raw SMB has a packet length field that's 24 bits long (maximum = 16,777,216). Since protocol limitations stop you long before you reach these limits, they aren't something I'd worry about.

I don't want to dwell on it, but the NetBIOS Session Request looks like this (when sent from my Nmap scripts):

```
NetBIOS Session Service
 +Length: 68
 +Called name: BASEWIN2K3
 +Calling name: NMAP
```

The trick here is that we need to find the server's name ("BASEWIN2K3") before we can make this request. This can be retrieved in a number of ways, but the easiest is to make an nbstat request over UDP/137, if possible, or check the DNS name.

# Starting a SMB Session

In a [previous blog](http://www.skullsecurity.org/blog/?p=45), in a section I called "Random SMB stuff", I talked about the first three packets sent to SMB: SMB\_COM\_NEGOTIATE, SMB\_COM\_SESSION\_SETUP\_ANDX, and SMB\_COM\_TREE\_CONNECT\_ANDX. These are the three packets we use to start the session:

- SMB\_COM\_NEGOTIATE -- This one is sent as normal
- SMB\_COM\_SESSION\_SETUP\_ANDX -- This one contains authentication information, if we're logging in with a user account. I'll talk about the differences between the four effective levels (administrator, user, guest, anonymous) in another blog, and I talked about how to prepare your password [in a previous blog](http://www.skullsecurity.org/blog/?p=34).
- SMB\_COM\_TREE\_CONNECT\_ANDX -- We use this to connect to a special share "IPC$" (that's interprocess communication, not the place I work). Everybody should have access to this share, no matter the user level.