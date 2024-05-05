---
id: 201
title: 'ANDX&#8230; and what?'
date: '2008-08-29T13:43:07-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=201'
permalink: '/?p=201'
---

My current project, as you can see by my last post, is to learn how to work in Microsoft's networking protocols (NetBIOS, SMB, CIFS, etc). This is obviously difficult due to the lack of standards and documentation, but there are two things that are seriously making my life difficult:

- ANDX, and
- Byte ordering

This is all old news if you know your way around SMB/CIFS, but for those who don't, this offers a little insight into the twisted world of 1980s coding.

### ANDX

ANDX is, at the core, a way of compounding multiple requests into a single request. What that means is a client can send both a "create session" request and a "connect to tree" request in the same packet, which saves a little bit of bandwidth (the SMB header is 32 bytes, the NetBIOS header is 4 bytes, and TCP/IP adds its own stuff to each packet; that isn't much by today's standards, but we have to remember that this was invented a long time ago). Now, this seems like a good idea, but it had one fatal mistake: it was added afterwards (or, at least, as an afterthought).

I count a total of eight message that support ANDX:

- SMB\_COM\_LOCKING\_ANDX
- SMB\_COM\_OPEN\_ANDX
- SMB\_COM\_READ\_ANDX
- SMB\_COM\_WRITE\_ANDX
- SMB\_COM\_SESSION\_SETUP\_ANDX
- SMB\_COM\_LOGOFF\_ANDX
- SMB\_COM\_TREE\_CONNECT\_ANDX
- SMB\_COM\_NT\_CREATE\_ANDX

So those messages have 32-bits of ANDX data prepended to them:

- \[8 bits\] Next message type
- \[8 bits\] Reserved
- \[16 bits\] Offset of next ANDX

The funniest thing is the "Next message type" field stored at the top of each message. You end up with packets that look like this:

```
SMB Packet
{
    Header
    {
        ...
        type = TYPE1_ANDX;
        ...
    }
    Message1
    {
        type = TYPE2;
        offset = [offset];
        ...
    }
    Message2
    {
        type = 0xFF; [no further commands]
        ...
    }
}
```

This gets incredibly confusing, because 'Message1', of 'TYPE1', starts with 'type = TYPE2'.

The other part that really got me is having to put the offset of the next section at the top of the current section. Since I build packets linearly, I don't even know that information, which means I'd have to go back, find the right point, and stick the offset in after the message is built. Luckily, ANDX is entirely optional for client software so I don't need to worry about that. When I implement the server, though, I'm sure all kinds of things will break!

### Byte Ordering

Byte ordering normally isn't so bad, once you get over the fact that 0x1234 is stored as <tt>34 12</tt> on most systems. NetBIOS/SMB, however, takes the cake.

NetBIOS specifies that all packets must be in network byte order, or big endian. That's cool, that's what I'd expect from the network.

SMB specifies that all packets must be in little endian. That's cool too, I'm used to servers (like Battle.net) preferring little endian.

What gets me, however, is that NetBIOS is used in the same packets as SMB, so you end up with mixed endianness in a single packet! The NetBIOS header that's prepended to SMB requests is basically a 4-byte value: one 'reserved' byte set to 0x00, then the length in big endian. So you end up with this:

```
packet
{
    <big endian> length
    <little endian> data
}
```

Maybe this isn't a big deal to some, but this type of thing makes me go crazy!

### Conclusion

You might be wondering what the point of this post was. There wasn't any, unless you count me wanting to give readers a bit of insight into how all this behind-the-scenes stuff works. :)

Ron