---
id: 142
title: 'Getting HKEY_PERFORMANCE_DATA'
date: '2008-12-16T14:20:07-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=142'
permalink: '/?p=142'
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
  openhkpd_result = msrpc.winreg_openhkpd(smbstate)
  queryvalue_result = msrpc.winreg_queryvalue(smbstate, 
                                 openhkpd_result['handle'], "Counter 009")
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
        pos, number, name = bin.unpack("<zz", data, pos)
        result[tonumber(number)] = name
    until pos >= #data

    return true, pos, result
end
```

After that, we have index numbers. As an example, I'll use "230", which corresponds to "Process":

```

...
000009b0 57 72 69 74 65 00 32 33 30 00 50 72 6f 63 65 73    Write.<span style="color: #8080FF">230.Proces</span>
000009c0 73 00 32 33 32 00 54 68 72 65 61 64 00 32 33 34    <span style="color: #8080FF">s</span>.232.Thread.234
000009d0 00 50 68 79 73 69 63 61 6c 44 69 73 6b 00 32 33    .PhysicalDisk.23
000009e0 36 00 4c 6f 67 69 63 61 6c 44 69 73 6b 00 32 33    6.LogicalDisk.23
000009f0 38 00 50 72 6f 63 65 73 73 6f 72 00 32 34 30 00    8.Processor.240.
...
```

So, to request process information, we query for "230". Note that we can query for multiple values using space-separated values, so if I wanted "Process" and "Processor", I'd specify "230 238". Also note that, as long as it's valid, we're guaranteed to get the requested value back, but we may get more, if they're required to properly describe something. For example, to properly describe a thread, you also need information about the process it belongs to. So, if you ask for a "Thread", you'll also get back the "Process" table. Pietrek used a really good metaphor when he described it: it's like ordering at a restaurant; you order your entrée, and it comes with free appetizers. Or maybe it's an awful metaphor and I'm just hungry...

In any case, the data returned matches up with different structs defined in WinPerf.h. The comments in WinPerf.h also give a great deal of information about how things work. Here is the high level overview of how the information is parsed:

```

title_database = QueryValue("Counter 009")
-- Query the data for "230", which is "process"
data = QueryValue("230")

-- Get the "Data Block" -- no matter what is queried for, 
-- there will always be exactly one datablock. It describes
-- how many objects were returned, among other things
data_block = parse_data_block(data)

-- Parse each object.
for i = 1, data_block['NumObjectTypes'] do
  -- An object type is like a class definition
  object_type = parse_object_type(data)

  -- The object type tells us how many counters exist; parse
  -- that many counter definitions
  for j = 1, object_type['NumCounters'], 1 do
    counter_def[i] = parse_counter_def(data)
  end

  -- The object type also tells us how many instances of the object exist; 
  -- an instance of "Process" exists for every process running on the system. 
  for j = 1, object_type['NumInstances'], 1 do
    object_instance[j] = parse_instance_definition(data)

    -- Each instance has counters associated with it, as defined by the object
    -- definition
    for k = 1, object_type['NumCounters'], 1 do
        counter_result = parse_counter(data, counter_definitions[k])
    end
  end
end
```

In this, we ran across several types of objects. Now, let's look at them a little bit deeper.

## Data Block

Every time you make a request for performance data, no matter how many different objects you request, you get a single "Data Block". In WinPerf.h, it's defined as "struct \_PERF\_DATA\_BLOCK". The data block returns the version and revision of the protocol, the lengths of the various pieces, and the name of the system. In an example run, these are some of the values returned to me:

```

TotalByteLength: 7344
HeaderLength: 112
NumObjectTypes: 1
LittleEndian: 1
Version: 1
Revision: 1
SystemTime: 1229465639
SystemName: BASEWIN2K3
```

## Object Type

A query for performance data will return one or more object type. An object can be a "Process", a "Thread", a "Job", etc. It's what we requested with "230", and possibly the extra stuff that came with it. An object type, which is defined in WinPerf.h as "struct \_PERF\_OBJECT\_TYPE", contains the index of the object (eg, "230" for "Process), the number of counters and instances, and other less interesting stuff. Here's what I get when I query for the "Process":

```

ObjectNameTitleIndex: 230
NumInstances: 26
NumCounters: 27
TotalByteLength: 7232
HeaderLength: 64
DefinitionLength: 1144
```

This tells us that there are 26 instances, each of which have 27 counters.

## Counter Definition

Now, for each counter in this object, we get a definition and a name. Let's just jump into it with a few of the counters (I'm not going to post all 27):

```

...
ByteLength: 40
CounterNameTitle: ID Process
CounterNameTitleIndex: 784
DetailLevel: 100

ByteLength: 40
CounterNameTitle: Creating Process ID
CounterNameTitleIndex: 1410
DetailLevel: 100

ByteLength: 40
CounterNameTitle: Thread Count
CounterNameTitleIndex: 680
DetailLevel: 200

ByteLength: 40
CounterNameTitle: Priority Base
CounterNameTitleIndex: 682
DetailLevel: 200
...
```

The length field is self explanatory. The CounterNameTitleIndex is the index in the title\_database (which is the first thing we talked about). The CounterNameTitle, I simply index into that table. The DetailLevel is interesting -- there are four possible values, 100, 200, 300, and 400. Values marked as "100" can be shown to any user, "200" are for administrators, and "400" are reserved for system developers.

## Instance Definition

An instance corresponds to one object that counters can be stored for. A single process, a single thread, a single network card, a single CPU, etc. Here are a couple "Process" instances:

```

ByteLength: 40
InstanceName: Idle

ByteLength: 40
InstanceName: System

ByteLength: 40
InstanceName: smss

ByteLength: 40
InstanceName: csrss
```

## Counter

And finally, each of those instances has counters. There is one counter per counter definition, as shown above, and all it contains is the value for that counter (a 4- or 8-byte value).

## Conclusion

So, when all's said and done, this is the kind of information we can pull:

```
Host script results:
|  smb-enum-processes:
|  Idle [0]
|  | Parent: 0 [Idle]
|  |_Priority: 0, Thread Count: 1, Handle Count: 0
|  System [4]
|  | Parent: 0 [Idle]
|  |_Priority: 8, Thread Count: 49, Handle Count: 395
|  smss [248]
|  | Parent: 4 [System]
|  |_Priority: 11, Thread Count: 3, Handle Count: 19
|  csrss [300]
|  | Parent: 248 [smss]
|  |_Priority: 13, Thread Count: 11, Handle Count: 339
|  winlogon [324]
|  | Parent: 248 [smss]
|  |_Priority: 13, Thread Count: 18, Handle Count: 506
|  services [380]
|  | Parent: 324 [winlogon]
|_ |_Priority: 9, Thread Count: 16, Handle Count: 272
```

The interesting thing about this whole thing is that it's all totally generic. You query for the title\_database, then for objects from the titlebase, and you get counters for those objects. The counters tell you their units (I skipped over that), what level of experience is required to u