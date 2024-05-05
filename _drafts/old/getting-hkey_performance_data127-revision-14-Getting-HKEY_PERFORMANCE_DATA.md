---
id: 141
title: 'Getting HKEY_PERFORMANCE_DATA'
date: '2008-12-16T13:10:46-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=141'
permalink: '/?p=141'
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

In any case, the data returned matches up with different structs defined in WinPerf.h. The comments in WinPerf.h also give a great deal of information about how things work. Here is the high level overview of how the information is parsed (note that this is a summarized version of my code; for brevity, I removed error checking, position updates, etc):

```

    -- Open HKEY_PERFORMANCE_DATA
    openhkpd_result = msrpc.winreg_openhkpd(smbstate)

    -- Query for the title database, and parse it
    queryvalue_result = msrpc.winreg_queryvalue(smbstate, 
                                    openhkpd_result['handle'], "Counter 009")
    result['title_database'] = parse_perf_title_database(queryvalue_result['value'], 
                                          pos)

    -- Query for the objects, getting the raw data (in this case, simply get '230', 
    -- which is 'Process')
    queryvalue_result = msrpc.winreg_queryvalue(smbstate, 
                                   openhkpd_result['handle'], "230")

    -- Parse the "Data block", which is the primary header, describing all the 
    -- objects that'll be received
    data_block = parse_perf_data_block(queryvalue_result['value'], pos)

    -- Parse the data sections; there are 'NumObjectType' objects declared (an 
    -- object is like "Process", "Thread", etc)
    for i = 1, data_block['NumObjectTypes'], 1 do
        -- Get the type of the object (this is basically the class 
        -- definition -- info about the object instances)
        object_type = parse_perf_object_type(queryvalue_result['value'], pos)

        -- Now, parse the definition for each counter in this object
        for j = 1, object_type['NumCounters'], 1 do
            counter_definitions[j] = parse_perf_counter_definition(
                                                queryvalue_result['value'], pos)
        end

        -- Now parse every instance of the object (for Process, there will be one 
        -- instance for each running process)
        for j = 1, object_type['NumInstances'], 1 do
            object_instances[j] = parse_perf_instance_definition(
                                              queryvalue_result['value'], pos)

            -- Each instance has a single block of counters
            counter_block = parse_perf_counter_block(
                                      queryvalue_result['value'], pos)

            -- And that block of counters contains the number of counters that that type 
            -- of object knows
            for k = 1, object_type['NumCounters'], 1 do
                counter_result = parse_perf_counter(
                                           queryvalue_result['value'], pos, 
                                           counter_definitions[k])
            end
        end
    end
```