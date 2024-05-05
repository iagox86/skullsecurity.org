---
id: 130
title: 'Getting HKEY_PERFORMANCE_DATA'
date: '2008-12-16T12:27:02-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=130'
permalink: '/?p=130'
---

Hi everybody,

I spent most of Saturday exploring how SysInternals' [PsList](http://technet.microsoft.com/en-us/sysinternals/bb896682.aspx) program works, and how I could re-implement it as an Nmap script. I discovered that the HKEY\_PERFORMANCE\_DATA (HKPD) registry hive was opened, then it got complicated. So I went digging for documentation and sicovered a couple journals written by Matt Pietrek from Microsoft. Those led me to the WinPerf.h header file. The three of those together were enough to get this working.

To summarize, this is based on these resources:

- [Journal post 1](http://www.microsoft.com/msj/archive/S271.aspx)
- [Journal post 2](http://www.microsoft.com/msj/archive/S2A9.aspx)
- WinPerf.h (included with Visual Studio)

The HKEY\_PERFORMANCE\_DATA hive can be accessed either locally through standard API functions or remotely through MSRPC functions. Since MSRPC is essentially a layer on top of API functions, these are essentially the same thing; as long as you have an administrator account, it doesn't matter where you're coming from, as long as you can call OpenHKPD() and QueryValue().

An important thing to keep in mind is that this isn't standard registry stuff -- whereas the Windows registry is a (fairly) static collection of data in well known places, the HKEY\_PERFORMANCE\_DATA is a dynamically generated snapshot of the system's current state that isn't necessarily accessed through well known places (although it's pretty simple to get an index).

So, first off, we'll get an index. This index contains most text strings, from the names of data we can pull ("Process", "Job", etc.) to the names of the various counters ("Bytes/second", "Writes/second", "Process ID", etc.). For this, we simply connect to HKPD and read the key "Counter 009", like so:

```
  status, openhkpd_result = msrpc.winreg_openhkpd(smbstate)
  status, queryvalue_result = msrpc.winreg_queryvalue(smbstate, openhkpd_result['handle'], "Counter 009")
```

That returns a series of null-terminated strings. A number, its corresponding name, another number, *its* corresponding name, etc. Here's what it looks like:

```

00000000 31 00 31 38 34 37 00 32 00 53 79 73 74 65 6d 00    1.1847.2.System.
00000010 34 00 4d 65 6d 6f 72 79 00 36 00 25 20 50 72 6f    4.Memory.6.% Pro
00000020 63 65 73 73 6f 72 20 54 69 6d 65 00 31 30 00 46    cessor Time.10.F
00000030 69 6c 65 20 52 65 61 64 20 4f 70 65 72 61 74 69    ile Read Operati
00000040 6f 6e 73 2f 73 65 63 00 31 32 00 46 69 6c 65 20    ons/sec.12.File
00000050 57 72 69 74 65 20 4f 70 65 72 61 74 69 6f 6e 73    Write Operations
00000060 2f 73 65 63 00 31 34 00 46 69 6c 65 20 43 6f 6e    /sec.14.File Con
00000070 74 72 6f 6c 20 4f 70 65 72 61 74 69 6f 6e 73 2f    trol Operations/
00000080 73 65 63 00 31 36 00 46 69 6c 65 20 52 65 61 64    sec.16.File Read
.....
         Length: 33459 [0x82b3]
```

It's pretty trivial to convert this to a table in Lua:

```

local function parse_perf_title_database(data, pos)
    local result = {}
    repeat
        local number, name
        pos, number, name = bin.unpack("<zz data="" name="" pos="" result="" until="">= #data

    return true, pos, result
end
</zz>
```

After that, we have index numbers. As an example, I'll use "230", which corresponds to "Process":

```

...
000009b0 57 72 69 74 65 00 32 33 30 00 50 72 6f 63 65 73    Write.<i>230.Proces</i>
000009c0 73 00 32 33 32 00 54 68 72 65 61 64 00 32 33 34    <i>s</i>.232.Thread.234
000009d0 00 50 68 79 73 69 63 61 6c 44 69 73 6b 00 32 33    .PhysicalDisk.23
000009e0 36 00 4c 6f 67 69 63 61 6c 44 69 73 6b 00 32 33    6.LogicalDisk.23
000009f0 38 00 50 72 6f 63 65 73 73 6f 72 00 32 34 30 00    8.Processor.240.
...
```