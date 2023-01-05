---
id: 127
title: Getting HKEY_PERFORMANCE_DATA
date: '2008-12-16T16:41:14-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=127
permalink: "/2008/getting-hkey_performance_data"
categories:
- smb
comments_id: '109638329420618205'

---

Hi everybody,

I spent most of last Saturday exploring how SysInternals' <a href='http://technet.microsoft.com/en-us/sysinternals/bb896682.aspx'>PsList</a> program works, and how I could re-implement it as an Nmap script. I quickly discovered that the HKEY_PERFORMANCE_DATA (HKPD) registry hive was opened, then it got complicated. So I went digging for documentation and discovered a couple journals posts written by Microsoft's Matt Pietrek wrote back in 1996. Those led me to the WinPerf.h header file. The three of those together were enough to get this working. 
<!--more-->
To summarize, this is based on these resources:
<ul>
<li><a href='http://www.microsoft.com/msj/archive/S271.aspx'>Journal post 1</a></li>
<li><a href='http://www.microsoft.com/msj/archive/S2A9.aspx'>Journal post 2</a></li>
<li>WinPerf.h (included with Visual Studio)</li>
</ul>

The HKEY_PERFORMANCE_DATA hive can be accessed either locally through standard registry API functions or remotely through MSRPC functions. Since MSRPC is essentially a layer on top of the API functions, these are essentially the same thing; as long as you have an administrator account, it doesn't matter where you're coming from, as long as you can call OpenHKPD() and QueryValue(). 

An important thing to keep in mind is that this isn't standard registry stuff -- whereas the Windows registry is a (fairly) static collection of data in well known places, the HKEY_PERFORMANCE_DATA is a dynamically generated snapshot of the system's current state that isn't necessarily accessed through well known places (although it's pretty simple to get an index). You basically query for what you want, and get back a huge chunk of data that has to be parsed. The majority of this post will be related to the type of information you get back; how to actually parse it is described better in the references above. 

There are likely libraries already written to parse performance data; in fact, in the link I gave above, Pietrek provides C++ code for parsing performance data locally. Since Nmap scripts are Lua, and I highly doubt that there's a Lua library written. So, everything I've written is parsed by hand. 

As of Nmap's SVN revision 11397, it can be found in svn://svn.insecure.org/nmap-exp/ron/nmap-smb (I haven't put it into the main trunk yet), in the file nselib/msrpcperformance.lua. 

<h2>Title database</h2>
Nothing in the performance database is guaranteed to be static. To figure out where everything is, we need a mapping of numbers to names. So, first off, we'll get an index called the "title database". This index contains most text strings. Some of them are names of objects we can query ("Process", "Job", etc.) and others are names of actual counters ("Bytes/second", "Writes/second", "Process ID", etc.). To get this, connect to HKEY_PERFORMANCE_DATA and read the key "Counter 009":
<pre>  openhkpd_result = msrpc.winreg_openhkpd(smbstate)
  queryvalue_result = msrpc.winreg_queryvalue(smbstate, 
                                 openhkpd_result['handle'], "Counter 009")
</pre>
That returns a series of null-terminated strings. First a number, then its corresponding name, another number, <i>its</i> corresponding name, etc. Here's part of the output on my system (it should look similar on any modern Windows system):
<pre>
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
</pre>

It's pretty trivial to convert this to a table in Lua:
<pre>
local function parse_perf_title_database(data, pos)
    local result = {}
    repeat
        local number, name
        pos, number, name = bin.unpack("&lt;zz", data, pos)
        result[tonumber(number)] = name
    until pos &gt;= #data

    return true, pos, result
end
</pre>

After parsing the title database, we have a mapping of index numbers to objects. For example, index "230" corresponds to the "Process" object. 
<pre>
...
000009b0 57 72 69 74 65 00 32 33 30 00 50 72 6f 63 65 73    Write.<span style='color: #8080FF'>230.Proces</span>
000009c0 73 00 32 33 32 00 54 68 72 65 61 64 00 32 33 34    <span style='color: #8080FF'>s</span>.232.Thread.234
000009d0 00 50 68 79 73 69 63 61 6c 44 69 73 6b 00 32 33    .PhysicalDisk.23
000009e0 36 00 4c 6f 67 69 63 61 6c 44 69 73 6b 00 32 33    6.LogicalDisk.23
000009f0 38 00 50 72 6f 63 65 73 73 6f 72 00 32 34 30 00    8.Processor.240.
...
</pre>

<h2>The request</h2>
To request process information, we query HKEY_PERFORMANCE_DATA for the value "230" (as a string). If we want to query for more than one object, that's also possible; any number of index numbers can be requested, separated by spaces. Since "238" corresponds to "Processor", if we want both Process (230) and Processor (238), we'd query for "230 238" (or "238 230")

As long as they are valid index numbers, we're guaranteed to get the requested object; however, there's no guarantee that we'll <i>only</i> get that object back. The server will send back the requested object (or objects), and any objects that it thinks are required to properly describe the requested object. For example, to properly describe a thread, you need the process that it belongs to; when you request a "Thread" object, you'll also receive a "Process" object. In his journal postings, Pietrek used a really good metaphor when he described it: it's like ordering at a restaurant; you order your entrée, and it comes with free appetizers. Or maybe it's an awful metaphor and I'm just hungry...

In any case, the data returned is defined by different structs found in WinPerf.h. The comments in WinPerf.h give a great deal of information about how things work. Basically, the data returned is a series of structs that are sequentially parsed. 

Here is the high level overview of which structs are processed
<pre>
title_database = QueryValue("Counter 009")
-- Query the data for "230", which is "process"
data = QueryValue("230")

-- Get the "Data Block" -- no matter what is queried, 
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
</pre>

In this, we ran across a lot of vocabulary (data blocks, object types, counter definitions, etc). Now, let's look at each of them a little bit deeper. 

<h2>Data Block</h2>
Every time you make a request for performance data, no matter how many different objects you request, you get a single "Data Block". In WinPerf.h, it's defined as "struct _PERF_DATA_BLOCK". The data block returns the version and revision of the protocol, the lengths of the various pieces, and the name of the system. In an example run, these are some of the values returned to me:
<pre>
TotalByteLength: 7344
HeaderLength: 112
NumObjectTypes: 1
LittleEndian: 1
Version: 1
Revision: 1
SystemTime: 1229465639
SystemName: BASEWIN2K3
</pre>
This tells that one type of object is returned (I know it's a "Process"). The other information is fairly self explanatory and is well defined in WinPerf.h. 

<h2>Object Type</h2>
A query for performance data will return one or more object type structs. An object can be a "Process", a "Thread", a "Job", etc. When we requested the index "230", we were asking for a "Process" object (although we might get other types as well). Object types are defined in WinPerf.h as "struct _PERF_OBJECT_TYPE". Here's an example of what one can return:

<pre>
ObjectNameTitleIndex: 230
NumInstances: 26
NumCounters: 27
TotalByteLength: 7232
HeaderLength: 64
DefinitionLength: 1144
</pre>

This tells us that it's a "Process" object (the ObjectNameTitleIndex is '230', which is looked up in the title database). It also tells us that there are 26 instances of the "Process" object, each of which have 27 counters. As we'll see in the next sections, the instances correspond to running processes (Explorer, System, WinLogon, etc), and the counters refer to the data we can pull (process id, priority, parent process, thread count, handle count, cpu usage, etc). 

<h2>Counter Definition</h2>
Now, for each counter in this object, we get a definition and a name. Here are a few of the counters returned for the "Process" object (I won't display all 27 of them):
<pre>
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
</pre>
The length field is self explanatory. The CounterNameTitleIndex is the index in the title database (which is the first thing we talked about). The textual version displayed is the result of a title database lookup. The DetailLevel is interesting -- there are four possible values, 100, 200, 300, and 400. Values marked as "100" refer to counters that can be understood by any user, "200" are for administrators, and "400" are reserved for system developers. This lets a program display relevant information to users without knowing beforehand 

<h2>Instance Definition</h2>
An instance corresponds to one actual object that has counters. In the case of the "Process" object, the instance is the actual process. In other cases, an instance can be a single thread, a single network card, a single CPU, etc. Here are a couple "Process" instances:
<pre>
ByteLength: 40
InstanceName: Idle

ByteLength: 40
InstanceName: System

ByteLength: 40
InstanceName: smss

ByteLength: 40
InstanceName: csrss
</pre>

<h2>Counter</h2>
And finally, each of those instances has counters, as defined in the counter definitions. There is one counter per counter definition, and a counter is simply a size value followed by an 4- or 8-byte. 

<h2>Conclusion</h2>
So, when all's said and done, this is the kind of information we can pull from just the Process object:
<pre>Host script results:
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
|  |_Priority: 9, Thread Count: 16, Handle Count: 272
|
.....
</pre>

The most interesting thing, in my opinion, is that it's completely generic. You query for the title database, then for objects from the title database, and you get counters for those objects. The counters tell you their units (I skipped over that) and names, and what level of experience is required to understand them, in addition to their values. All this can be done in a totally generic way. 
