---
title: "Wiki: Miscellaneous useful 'nippits"
author: ron
layout: wiki
permalink: "/wiki/Miscellaneous_useful_'nippits"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Miscellaneous_useful_'nippits"
---

I\'m not sure what\'s going to end up here, but I\'ll know it when I see it. Be prepared!

## Overview

This is a quick and dirty overview of the whole process:

-   User connects to Battle.net
-   Built-in Warden module (\"Maiev\") is loaded from memory
-   Module is initialized (keys are generated, etc.)
-   User logs in
-   Battle.net sends 0x00 (\"Do you have this module?\")
    -   User responds with 0x00 0r 0x01
        -   If 0x01 is sent, skip to receiving 0x02
    -   Battle.net sends the new module, in a series of 0x01 packets
    -   \"Maiev\" decrypts, verifies, and prepares the new module
    -   Once module has been verified and prepared, client sends back 0x01
-   After each Warden packet, Battle.snp checks if a new module is prepared
    -   Once complete, the module is swapped out
-   Battle.net sends 0x02
    -   New module responds to 0x02 (somehow.. haven\'t done this yet)

## WinDBG Packet Dumper {#windbg_packet_dumper}

This little pair of WinDGB commands will set a breakpoint within the built-in module to decrypt and display Warden\'s initial packets:

    e SetThreadContext 0xc2 0x08 0x00
    ba e1 19018461 "bd *; ba e1 eax+0x248b \".echo Sent SID_WARDEN Data:; d poi(esp+4) poi(esp+4)+poi(esp+8)-1; g\"; ba e1 eax+0x2730 \".echo Received SID_WARDEN Data:; d eax eax+esi-1; g\"; g"
