---
id: 85
date: '2008-10-15T22:13:36-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=85'
permalink: '/?p=85'
---

Hello everybody!

Lately I've been putting a lot of work into Nmap scripts that'll probe Windows deeply for information. I'm testing this with both authenticated and unauthenticated users, mostly to determine how well error conditions are handled. Every once in awhile, however, I notice something that the anonymous account or guest account can access that seems odd. And today, I felt like I ought to post a blog, so you get to hear about it!

First, a little background. Users have two ways they can anonymously log into Windows through SMB:

- The 'anonymous' account, also known as the infamous 'null session', where a blank username/blank password are used for credentials
- 
- The 'guest' account, which is disabled by default

The 'guest' account has an additional interesting property -- if a user mistypes his or her username, and the 'guest' account is enabled, the system will automatically allow access as 'guest'. I suspect that this was done for user friendliness -- "oh, you don't have an account? Well come on in, you can have a little bit of access!" -- but in the end, I could see it being more annoying than anything. "Why can't I access my files after logging in?" Additionally, some versions of Windows (Windows XP Professional, for example) will always log in users as the 'guest' account, I'm assuming for security reasons (this behaviour is something that me and David from the Nmap-dev mailing list spent some time troubleshooting). This can be changed by modifying the local security policy, but I digress.

So anyway, those are the two anonymous accounts, so to speak. Every Windows system will allow an anonymous login, with minimal access, and every Windows system has a guest account, disabled by default.

Windows 2000, by default, gives so much information to the anonymous account that it isn't even funny:

```
Host script results: 
|  SMB Security: User-level authentication
|  SMB Security: Challenge/response passwords supported
|_ SMB Security: Message signing not supported
|  MSRPC: List of domains:
|  Domain: BASEWIN2K
|   |_ SID: S-1-5-21-1060284298-842925246-839522115
|   |_ Users: Administrator, ASPNET, blankadmin, blankuser, Guest, Ron, test
|   |_ Creation time: 2006-10-17 15:35:07
|   |_ Passwords: min length: n/a; min age: n/a; max age: 42 days
|   |_ Account lockout disabled
|   |_ Password properties:
|     |_  Password complexity requirements do not exist
|     |_  Administrator account cannot be locked out
|  Domain: Builtin
|   |_ SID: S-1-5-32
|   |_ Users:
|   |_ Creation time: 2006-10-17 15:35:07
|   |_ Passwords: min length: n/a; min age: n/a; max age: 42 days
|   |_ Account lockout disabled
|   |_ Password properties:
|     |_  Password complexity requirements do not exist
|_    |_  Administrator account cannot be locked out
|  OS from SMB: Windows 2000
|  LAN Manager: Windows 2000 LAN Manager
|  Name: WORKGROUPBASEWIN2K
|_ System time: 2008-10-13 21:18:05 UTC-5
|  MSRPC: NetSessEnum():
|  ERROR: Couldn't enumerate login sessions: NT_STATUS_ACCESS_DENIED
|  Active SMB Sessions:
|_ |_  is connected from 192.168.1.3 for [just logged in, it's probably you], idle for [not idle]
|  MSRPC: NetShareEnumAll():
|  Anonymous shares: IPC$
|_ Restricted shares: ADMIN$, C$
|  MSRPC: List of user accounts:
|  Administrator
|    |_ Domain: BASEWIN2K
|    |_ RID: 500
|    |_ Full name: Built-in account for administering the computer/domain
|    |_ Flags: Normal account, Password doesn't expire
|  ASPNET
|    |_ Domain: BASEWIN2K
|    |_ RID: 1001
|    |_ Full name: Account used for running the ASP.NET worker process (aspnet_wp.exe)
|    |_ Description: ASP.NET Machine Account
|    |_ Flags: Normal account, Password not required, Password doesn't expire
|  blankadmin
|    |_ Domain: BASEWIN2K
|    |_ RID: 1003
|    |_ Flags: Normal account
|  blankuser
|    |_ Domain: BASEWIN2K
|    |_ RID: 1004
|    |_ Flags: Normal account
|  Guest
|    |_ Domain: BASEWIN2K
|    |_ RID: 501
|    |_ Full name: Built-in account for guest access to the computer/domain
|    |_ Flags: Normal account, Password not required, Password doesn't expire
|  Ron
|    |_ Domain: BASEWIN2K
|    |_ RID: 1000
|    |_ Description: Ron
|    |_ Flags: Normal account, Password doesn't expire
|  test
|    |_ Domain: BASEWIN2K
|    |_ RID: 1002
|_   |_ Flags: Normal account
```

We have a list of user accounts, sessions, domain policies, etc. etc. etc. Yes, it's fun to find Windows 2000 machines, that's for sure!

Windows 2003, on the other hand, gives very little information to the anonymous account. Here is the output of my current plugins:

```
Host script results:
|  SMB Security: User-level authentication
|  SMB Security: Challenge/response passwords supported
|_ SMB Security: Message signing not supported
|  OS from SMB: Windows Server 2003 3790 Service Pack 2
|  LAN Manager: Windows Server 2003 5.2
|  Name: WORKGROUPBASEWIN2K3
|_ System time: 2008-10-15 21:12:44 UTC-5
|_ MSRPC: List of domains: ERROR: NT_STATUS_ACCESS_DENIED (samr.connect4)
|  MSRPC: NetSessEnum():
|  ERROR: Couldn't enumerate login sessions: NT_STATUS_ACCESS_DENIED
|_ ERROR: Couldn't enumerate network sessions: NT_STATUS_ACCESS_DENIED
|  MSRPC: List of user accounts:
|  Enum via LSA error: NT_STATUS_ACCESS_DENIED (lsa.openpolicy2)
|  Enum via SAMR error: NT_STATUS_ACCESS_DENIED (samr.connect4)
|_ Sorry, couldn't find any account names anonymously!
|  MSRPC: NetShareEnumAll():
|  Couldn't enum all shares, checking for common ones (NT_STATUS_ACCESS_DENIED)
|  Anonymous shares: IPC$
|_ Restricted shares: ADMIN$, C$
```

So, we get a little information about what type of password is expected, which is necessary. Then we get the operating system version, system time, and system name. Ok, that isn't too bad.

Now, when the 'guest' account is enabled, what kind of information do we get?

```
Host script results:
|  SMB Security: User-level authentication
|  SMB Security: Challenge/response passwords supported
|_ SMB Security: Message signing not supported
|  OS from SMB: Windows Server 2003 3790 Service Pack 2
|  LAN Manager: Windows Server 2003 5.2
|  Name: WORKGROUPBASEWIN2K3
|_ System time: 2008-10-15 21:30:15 UTC-5
|  MSRPC: NetShareEnumAll():  
|  Anonymous shares: IPC$
|_ Restricted shares: C$, ADMIN$
|  MSRPC: List of user accounts:  
|  Enum via SAMR error: NT_STATUS_ACCESS_DENIED (samr.opendomain)
|  Administrator
|    |_ Domain: BASEWIN2K3
|    |_ RID: 500
|  blankadmin
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1011
|  blankuser
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1012
|  consoletest
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1010
|  Guest
|    |_ Domain: BASEWIN2K3
|    |_ RID: 501
|  HelpServicesGroup
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1003
|  ron
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1009
|  SUPPORT_388945a0
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1004
|  TelnetClients
|    |_ Domain: BASEWIN2K3
|    |_ RID: 1005
|  test
|    |_ Domain: BASEWIN2K3
|_   |_ RID: 1007
|  MSRPC: NetSessEnum():  
|  Users logged in:
|  |_ BASEWIN2K3ron, logged in since 2008-10-13 17:10:51 [testing -- may not be accurate]
|_ ERROR: Couldn't enumerate network sessions: NT_STATUS_WERR_ACCESS_DENIED (srvsvc.netsessenum)
```

With the guest account, we get a list of users (although we don't get details on them -- we only get users by bruteforcing RIDs, which I'll talk about in another blog), an actual list of the shares on the system (which, in this case, happens to be identical to the list of shares we brute forced with the anonymous account -- something I may blog about in the future), and the list of users logged in.

This last one is curious -- where is the list of users logged in coming from? Let's look at the output of "smb-enumsessions" for Windows 2000, with the anonymous account:

```
Host script results:
|  MSRPC: NetSessEnum():  
|  ERROR: Couldn't enumerate login sessions: NT_STATUS_ACCESS_DENIED
|  Active SMB Sessions:
|_ |_  is connected from 192.168.1.3 for [just logged in, it's probably you], idle for [not idle]
```

Compared to Windows 2003, with the guest account:

```
Host script results:
|  MSRPC: NetSessEnum():  
|  Users logged in:
|  |_ BASEWIN2K3ron, logged in since 2008-10-13 17:10:51 [testing -- may not be accurate]
|_ ERROR: Couldn't enumerate network sessions: NT_STATUS_WERR_ACCESS_DENIED (srvsvc.netsessenum)
```

So, on Windows 2000, 'anonymous' can enumerate SMB sessions, but not user sessions. On Windows 2003, 'guest' can enumerate user sessions but not SMB sessions. What's going on? First, a little background on how this works.

Enumerating SMB sessions is a call to the NetSessEnum() function in the server service (SRVSVC). This is the same service that is used for enumerating shares (NetShareEnumAll()). So, we aren't allowed this SRVSVC call against Windows 2003 without a proper user account. That's fine.

The next part is where it gets interesting -- enumerating login sessions is done by reading the registry (WINREG). Specifically, enumerating the keys under HKEY\_USERS. Each key under HKEY\_USERS is the SID of a currently logged in user. A SID is a series of numbers that look like, "S-1-5-21-1060284298-842925246-839522115-1003". In this case, the first part is the domain ("S-1-5-21-1060284298-842925246-839522115") and the last part is the users's RID ("1003"). The RID can be translated back to a username using a LSA function, LsaLookupSids2() (the Lsa functions all have '2' on the end due to a typo in the parameters for the original ones. True story).

To summaring, here are the functions called to retrieve the list of users:

- winreg.OpenHKU()
- winreg.EnumKey()
- lsa.OpenPolicy2()
- lsa.LookupSids2()

Windows 2000 heads us off at the pass -- we are denied access as soon as we try looking at the Windows registry. But 2003 will let us open up the registry and take a look around, if we have 'guest'. I'm assuming that Windows XP will, as well, and some versions of XP seem to have 'guest' enabled by default.

As I get deeper into MSRPC, I will explore what the Guest account can actually do. But, that's all I have for now. Hopefully it wasn't too much of a ramble! :)