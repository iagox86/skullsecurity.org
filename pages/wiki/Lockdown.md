---
title: 'Wiki: Lockdown'
author: ron
layout: wiki
permalink: "/wiki/Lockdown"
date: '2024-08-04T15:51:38-04:00'
---

Those of you who know me know that I use Linux as my primary operating system. As a result, I am unable to connect to Battle.net with any clients. That is why, for the purpose of cross-platform compatibility, I\'m posting source code that emulates Battle.net\'s lockdown system.

Note that this code was 100% written by me, and is available for free under the BSD license, which you will find at the top of all code files. The bottom line is that, if you wish to use the source, you may, provided that the file\'s copyright notice remains intact and that credit is given to the authors (in this case \"x86\" or, if you wish, \"iago\").

## Downloads

### Current version {#current_version}

Alpha3

Changes:

-   Added a completely new set of test cases
-   Confirmed War2 support

### Source and Binaries {#source_and_binaries}

-   [Complete Project](http://www.javaop.com/~ron/code/lockdown/alpha3/lockdown-complete.zip) (Visual Studio 2005)
    -   Although I\'m packaging this with an executable, that executable assumes that you have all the files you need in the same place as me, which isn\'t likely.
-   [Lockdown Source](http://www.javaop.com/~ron/code/lockdown/alpha3/lockdown-source.zip) (important files only)
-   [Screendump Executable](http://www.javaop.com/~ron/code/lockdown/alpha3/screendump-bin.zip) (lets you take the screendump of games)
-   [Lockdown Executable](http://www.javaop.com/~ron/code/lockdown/alpha3/lockdown.exe) (for testing)
-   [Browse the Source Online](http://www.javaop.com/~ron/code/lockdown/alpha3/lockdown)

### Other

-   [.idb of a lockdown .dll](http://www.javaop.com/~ron/code/lockdown/lockdown-IX86-00.idb.zip)
-   [Starcraft screen dump](http://www.javaop.com/~ron/code/lockdown/STAR.bin)
-   [Warcraft II screen dump](http://www.javaop.com/~ron/code/lockdown/W2BN.bin)
-   [Private](http://www.javaop.com/~ron/code/lockdown/Private.rar) (Ignore this unless I tell you otherwise)

Please note that this code is simply for demonstration, and has not been thoroughly tested. It doesn\'t do anything except calculate the values, so it\'s up to others to incorporate it into a bot or .dll or whatever.

The three main game files, the 20 lockdown files, and a screendump of the game are required. I cannot provide those here for legal reasons, unfortunately. The screendump can be taken with the screendump executable (extract into your game directory, follow the instructions at the top of the .bat file), and the rest you\'ll have to find on your own.

I believe that this code will work for any Blizzard product, but it has only been tested with original Starcraft.

If you think you can improve on my code, please feel free, and be sure to send me the final result! I am more than happy to incorporate your changes!

Enjoy, and please direct any questions to me: <ronld@javaop.com>

## Testing

I appreciate anybody who tests this for me. I also hate anybody who has a problem.

If you want to test it, do the following:

-   Download STAR.bin and/or W2BN.bin.
    -   Put them in C:\\Temp
-   Download the set of lockdown-IX86-XX.dll files from somewhere (not included).
    -   Put them in C:\\Temp
-   Install Starcraft or Brood War or Warcraft 3 to the default folder.
-   Download and run lockdown.exe. It should take a little time, then tell you which tests passed. Starcraft and Brood War tests will never both pass, and if you\'re missing any .dll files those will also fail.

Here is a sample of what you might expect:

    Note: Either Starcraft OR Brood War will pass, not both.
    Couldn't load lockdown file: c:\temp\lockdown-IX86-13.dll
    Warcraft 2 passed 18/19 tests
    Starcraft passed 0/11 tests
    Brood War passed 10/10 tests
    a76bd3ea
    3e79e38c

    a1720661207???9505df37f46f6212bd
    78d9f3e6bc78d4b2a34999b990de6c0e

    Press any key to continue . . .

Warcraft 2 failed a test due to a missing file.

## Old Versions {#old_versions}

-   [Alpha 1](http://www.javaop.com/~ron/code/lockdown/alpha1)
-   [Alpha 2](http://www.javaop.com/~ron/code/lockdown/alpha2) - Fixed a minor stack overflow issue so it would crash on codes (longer than 0x10 bytes).
