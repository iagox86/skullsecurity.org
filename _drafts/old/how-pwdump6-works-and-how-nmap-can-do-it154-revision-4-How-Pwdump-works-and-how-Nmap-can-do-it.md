---
id: 161
title: 'How Pwdump works, and how Nmap can do it'
date: '2009-02-07T18:58:31-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=161'
permalink: '/?p=161'
---

It's been awhile since I've written a blog, so I figured I'd better write something or both my readers might stop checking. :)

But seriously, I wanted to discuss how the pwdump and fgdump tools work, in detail, and how I was able to integrate pwdump into my Nmap scripts. Is this integration useful? Maybe or maybe not, but it was definitely an interesting problem.

To steal password hashes from a remote system, the following steps are taken:

- Establish a connection to the target system
- Upload servpw.exe and lsremora.dll to a file share (currently, the C$ share is used, but in the future it will attempt to find an open share) 
  - Uses standard SMB file writing functions
- Create and start a service (servpw.exe) using SVCCTL functions 
  - Uses the following SVCCTL functions:
  - OpenSCManagerW()
  - CreateServiceW()
  - StartServiceW()
  - QueryServiceW() (to check when the service starts)
- Read and decrypt the data from the service (it writes to a named pipe using Blowfish encryption, which can be read remotely) 
  - The service writes encrypted data to a named pipe; smb-pwdump.nse reads and decrypts that data
- Stop the service and remove the files 
  - OpenServiceW()
  - StopService()
  - And standard SMB functions for deleting the file

Obviously, this process is *highly* intrusive (and requires administrative privileges). It's running a service on the remote machine with SYSTEM-level access, and the service itself injects a library into LSASS. This same process is used by pwdump6, fgdump, and my Nmap script, smb-pwdump.nse.

The Nmap script uses pwdump6's executable files, servpw.exe and lsremora.dll. These aren't included with Nmap, but have to be downloaded from pwdump6's Web site. Since these files can trigger antivirus software, care should be taken with them. Recompiling them from source is a great way to avoid antivirus software.

One of the main focuses of the script was on cleanup. Before and after the script runs, a cleanup routine will attempt to delete the files and stop the service. As a result, I can't randomize the file or service name, so it's more likely to be caught by antivirus or IDS software than, say, fgdump, whose sole purpose is to evade detection.

This script was written mostly as an academic exercise, and to highlight Nmap's growing potential as a penetration testing tool. It compliments the smb-brute.nse script, also written by me, because smb-brute can find weak administrator passwords, then smb-pwdump.nse can use those passwords to dump hashes. Those hashes can then be cracked (which is a manual process, right now, but in the future smb-brute.nse might be integrated with Rainbow Tables) and added to the password list for more brute forcing. The hashes themselves can also be added to Nmap's password list, since smb-brute.nse understands how to use hashes. Future plans include automatically using discovered hashes against other systems.

So that's smb-pwdump.nse!