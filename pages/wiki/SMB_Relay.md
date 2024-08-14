---
title: 'Wiki: SMB Relay'
author: ron
layout: wiki
permalink: "/wiki/SMB_Relay"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/SMB_Relay"
---

I intend to write a program with the following features:

-   Listens on 445 (and possibly 135 - 139)
-   Accepts SMB connections destined for another server
-   Relays data to/from that remote server

What sets this apart from other types of relays is that it\'ll have built-in pass the hash capabilities. What that means is, it\'ll ignore the user\'s supplied credentials and instead supply the Lanman/NTLM hashes.

It should be an interesting project! :)
