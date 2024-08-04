---
title: 'Wiki: Naming Conventions'
author: ron
layout: wiki
permalink: "/wiki/Naming_Conventions"
date: '2024-08-04T15:51:38-04:00'
---

While working with the Warden modules, I\'ve come up with a bit of a convention that I hope others will use.

Blizzard named the encrypted files \[md5sum\].mod. So I started there.

-   \[md5sum\].mod \-- Encrypted module
-   \[md5sum\].tmp1.bin \-- Decrypted, compressed module
-   \[md5sum\].tmp2.bin \-- Decrypted, decompressed and unprepared module
-   \[md5sum\].bin \-- Decrypted, decompressed and prepared module

In addition to md5sum-named files, there\'s one built-in module. Because the string \"Maiev.mod\" appears in the module, I decided to name the built-in module \"Maive.mod\", along with the variations above:

-   Maiev.mod \-- Encrypted module
-   Maiev.bin \-- Decrypted, decompressed, and prepared module
-   etc.
