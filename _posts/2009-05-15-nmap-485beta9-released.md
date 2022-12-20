---
id: 256
title: 'Nmap 4.85beta9 released'
date: '2009-05-15T14:00:49-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=256'
permalink: /2009/nmap-485beta9-released
categories:
    - Tools
---

In case you haven't heard, Fyodor released Nmap 4.85beta9 this week. This is the first release in awhile that wasn't related to my code (or, most properly, mistakes :) ). It looks like the new stable version will be here soon, so give this one a shot and report your bugs. Here's the <a href='http://nmap.org/download.html'>download page</a>.
<!--more-->
<pre>From: Fyodor <fyodor_at_insecure.org>
Date: Tue, 12 May 2009 20:44:56 -0700

Hello everyone! I'm pleased to announce the first Nmap release in a
while which has NOTHING to do with Conficker :). Nmap 4.85BETA9
brings you a bunch of other great stuff instead. This includes a big
OS fingerprint submission run, a bunch of work to make Ncat SSL
support more functional and secure, boolean arguments and wildcards
for scripts so you can now request stuff like "--script '(default or
safe or intrusive) and not http-*'", Ncat HTTP proxy support on
Windows, Zenmap UI improvements, and much more! We also fixed some
embarrassing bugs from the last release, such as the non-existent
smb-check-vulns-2.nse appearing in script.db and a number of
discovered crashes. Not bad for a few weeks' work :).

You can download 4.85BETA9 at the normal location:

http://nmap.org/download.html

Do give it some thorough testing! I'd like to stabilize things so
that we can finally put out a stable version rather than endless
BETAs! The best way to help with that is testing, bug reporting, and
bug fixing! See http://nmap.org/book/man-bugs.html.

Without further ado, here is the full list of significant changes:

Nmap 4.85BETA9 [2009-05-12]

o Integrated all of your 1,156 of your OS detection submissions and
  your 50 corrections since January 8. Please keep them coming! The
  second generation OS detection DB has grown 14% to more than 2,000
  fingerprints! That is more than we ever had with the first system.
  The 243 new fingerprints include Microsoft Windows 7 beta, Linux
  2.6.28, and much more. See
  http://seclists.org/nmap-dev/2009/q2/0335.html. [David]

o [Ncat] A whole lot of work was done by David to improve SSL
  security and functionality:
  o Ncat now does certificate domain and trust validation against
    trusted certificate lists if you specify --ssl-verify.
  o [Ncat] To enable SSL certificate verification on systems whose
    default trusted certificate stores aren't easily usable by
    OpenSSL, we install a set of certificates extracted from Windows
    in the file ca-bundle.crt. The trusted contents of this file are
    added to whatever default trusted certificates the operating
    system may provide. [David]
  o Ncat now automatically generates a temporary keypair and
    certificate in memory when you request it to act as an SSL server
    but you don't specify your own key using --ssl-key and --ssl-cert
    options. [David]
  o [Ncat] In SSL mode, Ncat now always uses secure connections,
    meaning that it uses only good ciphers and doesn't use
    SSLv2. Certificates can optionally be verified with the
    --ssl-verify and --ssl-trustfile options. Nsock provides the
    option of making SSL connections that prioritize either speed or
    security; Ncat uses security while version detection and NSE
    continue to use speed. [David]

o [NSE] Added Boolean Operators for --script. You may now use ("and",
  "or", or "not") combined with categories, filenames, and wildcarded filenames
  to match a set files. Parenthetical subexpressions are allowed for
  precedence too. For example, you can now run:

  nmap --script "(default or safe or intrusive) and not http-*" scanme.nmap.org

  For more details, see
  http://nmap.org/book/nse-usage.html#nse-args. [Patrick]

o [Ncat] The HTTP proxy server now works on Windows too. [David]

o [Zenmap] The command wizard has been removed. The profile editor has
  the same capabilities with a better interface that doesn't require
  clicking through many screens. The profile editor now has its own
  "Scan" button that lets you run an edited command line immediately
  without saving a new profile. The profile editor now comes up
  showing the current command rather than being blank. [David]

o [Zenmap] Added an small animated throbber which indicates that a
  scan is still running (similar in concept to the one on the
  upper-right Firefox corner which animates while a page is
  loading). [David]

o Regenerate script.db to remove references to non-existent
  smb-check-vulns-2.nse. This caused the following error messages when
  people used the --script=all option: "nse_main.lua:319:
  smb-check-vulns-2.nse is not a file!" The script.db entries are now
  sorted again to make diffs easier to read. [David,Patrick]

o Fixed --script-update on Windows--it was adding bogus backslashes
  preceding file names in the generated script.db. Reported by
  Michael Patrick at http://seclists.org/nmap-dev/2009/q2/0192.html,
  and fixed by Jah. The error message was also improved.

o The official Windows binaries are now compiled with MS Visual C++
  2008 Express Edition SP1 rather than the RTM version. We also now
  distribute the matching SP1 version of the MS runtime components
  (vcredist_x86.exe). A number of compiler warnings were fixed
  too. [Fyodor,David]

o Fixed a bug in the new NSE Lua core which caused it to round
  fractional runlevel values to the next integer. This could cause
  dependency problems for the smb-* scripts and others which rely on
  floating point runlevel values (e.g. that smb-brute at runlevel 0.5
  will run before smb-system-info at the default runlevel of 1).

o The SEQ.CI OS detection test introduced in 4.85BETA4 now has some
  examples in nmap-os-db and has been assigned a MatchPoints value of
  50. [David]

o [Ncat] When using --send-only, Ncat will now close the network
  connection and terminate after receiving EOF on standard input.
  This is useful for, say, piping a file to a remote ncat where you
  don't care to wait for any response. [Daniel Roethlisberger]

o [Ncat] Fix hostname resolution on BSD systems where a recently
  fixed libc bug caused getaddrinfo(3) to fail unless a socket type
  hint is provided. Patch originally provided by Hajimu Umemoto of
  FreeBSD. [Daniel Roethlisberger]

o [NSE] Fixed bug in the DNS library which caused the error message
  "nselib/dns.lua:54: 'for' limit must be a number". [Jah]

o Fixed Solaris 10 compilation by renaming a yield structure which
  conflicted with a yield function declared in unistd.h on that
  platform. [Pieter Bowman, Patrick]

o [Ncat] Minor code cleanup of Ncat memory allocation and string
  duplication calls. [Ithilgore]

o Fixed a bug which could cause -iR to only scan the first host group
  and then terminate prematurely. The problem related to the way
  hosts are counted by o.numhosts_scanned. [David]

o Fixed a bug in the su-to-zenmap.sh script so that, in the cases
  where it calls su, it uses the proper -c option rather than
  -C. [Michal Januszewski, Henry Gebhardt]

o Overhaul the NSE documentation "Usage and Examples" section and add
  many more examples: http://nmap.org/book/nse-usage.html [David]

o [NSE] Made hexify in nse_nsock.cc take an unsigned char * to work
  around an assertion in Visual C++ in Debug mode. The isprint,
  isalpha, etc. functions from ctype.h have an assertion that the
  value of the character passed in is <= 255. If you pass a character
  whose value is >= 128, it is cast to an unsigned int, making it a
  large positive number and failing the assertion. This is the same
  thing that was reported in
  http://seclists.org/nmap-dev/2007/q2/0257.html, in regard to
  non-ASCII characters in nmap-mac-prefixes. [David]

o [NSE] Fixed a segmentation fault which could occur in scripts which
  use the NSE pcap library. The problem was reported by Lionel Cons
  and fixed by Patrick.

o [NSE] Port script start/finish debug messages now show the target
  port number as well as the host/IP. [Jah]

o Updated IANA assignment IP list for random IP (-iR)
  generation. [Kris]

o [NSE] Fixed http.table_argument so that user-supplied HTTP headers
  are now properly sent in HTTP requests. [Jah]

Enjoy the new release!
-Fyodor 
</pre>