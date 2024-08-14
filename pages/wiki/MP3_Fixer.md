---
title: 'Wiki: MP3 Fixer'
author: ron
layout: wiki
permalink: "/wiki/MP3_Fixer"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/MP3_Fixer"
---

## MP3 Fixer {#mp3_fixer}

-   Name: MP3 Fixer
-   OS: Java
-   Language: Java
-   Path: <http://svn.skullsecurity.org:81/ron/old/mp3fixes>
-   Created: Old
-   State: Finished

This is actually a pair of programs and a shellscript I use to organize my MP3 collection:

-   FixID3 \-- Sets the files\' ID3 tag based on the directory structure
-   MoveMP3 \-- Moves the file based on the ID3 tag
-   fix.sh \-- Attempts to fix the filename
    svn co http://svn.skullsecurity.org:81/ron/old/mp3fixes
