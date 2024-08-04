---
title: 'Wiki: Fuzzer'
author: ron
layout: wiki
permalink: "/wiki/Fuzzer"
date: '2024-08-04T15:51:38-04:00'
---

This is a page for a \"fuzzer\" I\'m considering writing. It doesn\'t have a name yet.

## Features

-   Proxy functionality (HTTP, socks)
-   Different protocols automatically recognized (ie, raw, http, irc, rpc, etc.)
    -   Manipulation of protocol-specific headers (ie, adding/removing headers)
    -   Abusing the protocol itself (fields and user data)
    -   Knowledge of the protocol (ie, able to update the length field, crc field, etc., store cookies, sessions)
    -   Overflows
    -   Format strings
    -   Injections (sql, html, shell, email, path)
    -   Remote file inclusion, viewstate parsing, other language-specific things
-   Data encodings
    -   Including invalid ones (broken UTF8)
-   Validation
    -   Common mistakes: phone number, postal code, etc.
-   Spidering
    -   Scraping URLs from Javascript?
    -   Forced browsing
-   Queued tests
-   Encode/decode payloads (standard, customized)
-   Multi-page testing (as in, hits certain pages in a certain sequence)
    -   State detection (logged in, not logged in \-- user-led or automatic (\"these pages are logged in, these aren\'t, what do they have in common?\"))
-   User-submitted tests (solving CAPTCHAs when necessary)
-   Diff engine
    -   Automatically detect which fields change (has to happen after decoding is done)
-   Page rendering (HTML)
-   Save all tests
    -   Save .html/whatever files?
    -   Save everything to a DB, attach a Web app to view results?
-   Different plugins for different tasks (spiderer, fuzzer, reporting, etc)
    -   Each can send to the rest (right-click on one or more packets, \"send to X\")
-   Able to attack both clients and servers (may not be useful on browsers, but could be on other clients (ActiveX, applets, thin clients))
