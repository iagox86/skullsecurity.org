---
id: 187
title: 'How Pwdump6 works, and how Nmap can do it'
date: '2009-02-09T18:39:53-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=187'
permalink: '/?p=187'
---

Today I want to discuss how the [pwdump6](http://foofus.net/fizzgig/pwdump/) and [fgdump](http://foofus.net/fizzgig/fgdump/) tools work, in detail, and how I was able to integrate pwdump6 into my Nmap scripts. Is this integration useful? Maybe or maybe not, but it was definitely an interesting problem.

The Nmap script in question is called smb-pwdump.nse, and currently exists in my experimental branch. It can be checked out using the following command:

```
svn co -r12061 svn://svn.insecure.org/nmap-exp/ron/nmap-smb
```

(Username 'guest', no password)

And run like this:

```
nmap --script=smb-pwdump --script-args=smbuser=<username>,smbpass=<password> -p139,445 <host>
```

The Nmap script uses pwdump6's executable files, servpw.exe and lsremora.dll. These aren't included with Nmap, but have to be downloaded from pwdump6's Web site. Since these files can trigger antivirus software, care should be taken with them. Recompiling them from source is a great way to avoid antivirus software. They need to be put in the nselib/data directory, wherever that happens to be.

pwdump6 and fgdump both attempt to download the password hashes from a remote machine. These password hashes are actually password equivalent, so they can be used to log into another system directly. They are also incredibly easy to crack, and can be cracked (that is, converted back to the password text) using a tool such as [Rainbow Crack](http://www.antsight.com/zsl/rainbowcrack/).

On a high level, both pwdump6 and fgdump access the [service control service](http://viewcvs.samba.org/cgi-bin/viewcvs.cgi/branches/SAMBA_4_0/source/librpc/idl/svcctl.idl?rev=24449&view=log) (SVCCTL). It gives users the ability to create, start, stop, and delete services on the remote machine. The service control service is being used to run a process on the remote machine -- it's also used by tools like [psexec](http://technet.microsoft.com/en-us/sysinternals/bb897553.aspx) to execute remote programs.

Pwdump6 and smb-pwdump.nse both perform the following actions:

- Establish a connection to the target system
- Upload servpw.exe and lsremora.dll to a file share
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


Obviously, this process is *highly* intrusive (and requires administrative privileges). It's running a service on the remote machine with SYSTEM-level access, and the service itself injects a library into LSASS.

When I wrote the Nmap script, I focused more on cleanup than anything else. Before and after the script runs, a cleanup routine will attempt to delete the files and stop the service. As a result, I can't randomize the file or service name (otherwise, it wouldn't know what to clean), so it's more likely to be caught by antivirus or IDS software than, say, fgdump, whose sole purpose is to evade detection. The names can easily be changed by editing the source, if you want to be more careful. You probably don't even need the .exe extension on servpw.exe. If you change the name of lsremora.dll, you'll have to recompile servpw.exe with the new lsremora.dll name.

For me, this script was written mostly as an academic exercise, and to highlight Nmap's growing potential as a pentesting tool. It compliments the smb-brute.nse script, also written by me, because smb-brute.nse can find weak administrator passwords, then smb-pwdump.nse can use those passwords to dump hashes. Those hashes can then be cracked and added to the password list for more brute forcing. The hashes themselves can also be added to Nmap's password list, since smb-brute.nse understands how to use hashes. Future plans include automatically using discovered hashes against other systems.

So that's smb-pwdump.nse! Let me know what you think (or if you even read my blog :P) in a comment!