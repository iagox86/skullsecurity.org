---
title: 'BSidesSF 2023 Writeups: id-me (easy file identification challenge)'
author: ron
layout: post
categories:
- bsidessf-2023
- ctfs
permalink: "/2023/bsidessf-2023-writeups--id-me--easy-file-identification-challenge-"
date: '2023-04-23T17:08:44-07:00'
comments_id: '110301420185344621'

---

[`id-me`](https://github.com/BSidesSF/ctf-2023-release/tree/main/id-me) is a
challenge I wrote to teach people how to determine file types without extensions.
My intent was to use the `file` command, but other solutions are absolutely
possible!

<!--more-->

## Write-up

I designed `id-me` to be a fairly straight forward "identify this file"
challenge. The user is given four files, and they are tasked with reading part
of the flag from each of them.

I'd personally use the `file` command on Linux:

```
$ file *
file1: ASCII text
file2: JPEG image data [...]
file3: PDF document, version 1.4
file4: Zip archive data, at least v2.0 to extract, compression method=deflate
```

But lots of other ways exist, including simply opening them in the Chrome
browser.
