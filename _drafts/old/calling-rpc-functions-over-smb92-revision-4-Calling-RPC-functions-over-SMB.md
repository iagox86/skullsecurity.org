---
id: 96
title: 'Calling RPC functions over SMB'
date: '2008-10-30T22:01:56-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=96'
permalink: '/?p=96'
---

Hi everybody!

This is going to be a fairly high level discussion on the sequence of calls and packets required to make MSRPC calls over the SMB protocol. I've learned this from a combination of reading the book [Implementing CIFS](http://www.ubiqx.org/cifs/), watching other tools do their stuff with Wireshark, and plain ol' guessing/checking.

## Making a SMB connection

SMB can be performed over ports tcp/445 and tcp/139. Port 445 allows for a "raw" SMB connection, while 139 is "SMB over NetBIOS". Effectively, they are the same thing with two differences:

1. SMB over NetBIOS requires a "NetBIOS Session Request" packet, which is a client saying, "hi, I'm xxx, can I connect to you?"
2. SMB over NetBIOS has a packet length field that's 17 bits (maximum = 131,072), while Raw SMB has a packet length field that's 24 bits long (maximum = 16,777,216). Since protocol limitations stop you long before you reach these limits, they aren't something I'd worry about.

I don't want to dwell on it, but the NetBIOS Session Request looks like this (when sent from my Nmap scripts):

```
NetBIOS Session Service
 +Length: 68
 +Called name: BASEWIN2K3
 +Calling name: NMAP
```

The trick here is that we need to find the server's name ("BASEWIN2K3") before we can make this request. This can be retrieved in a number of ways, but the easiest is to make an nbstat request over UDP/137, if possible, or check the DNS name.

## Starting a SMB Session

In a [previous blog](http://www.skullsecurity.org/blog/?p=45), in a section I called "Random SMB stuff", I talked about the first three packets sent to SMB: SMB\_COM\_NEGOTIATE, SMB\_COM\_SESSION\_SETUP\_ANDX, and SMB\_COM\_TREE\_CONNECT\_ANDX. These are the three packets we use to start the session:

- SMB\_COM\_NEGOTIATE -- This one is sent as normal
- SMB\_COM\_SESSION\_SETUP\_ANDX -- This one contains authentication information, if we're logging in with a user account. I'll talk about the differences between the four effective levels (administrator, user, guest, anonymous) in another blog, and I talked about how to prepare your password [in a previous blog](http://www.skullsecurity.org/blog/?p=34).
- SMB\_COM\_TREE\_CONNECT\_ANDX -- We use this to connect to a special share "IPC$" (that's interprocess communication, not the place I work). Everybody should have access to this share, no matter the user level.

## Attaching to the pipe

After the three standard initial packets, another common packet is sent -- SMB\_COM\_NT\_CREATE. This is the packet used to create and open files. In this case, it's used to open a named pipe (since we're attached to the IPC$ share, you can't actually create files). This is done by opening what looks like a file. For example, some common pipes to open are:

- [samr](http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/samr.idl) -- user management (SAM) functions
- [srvsvc](http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/srvsvc.idl) -- server management
- [lsarpc](http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/lsa.idl) -- local security authority
- [winreg](http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/winreg.idl) -- Windows registry

Once the file is successfully opened, we can begin interacting with it via the SMB\_TRANSACTION layer.

The links I provided contain all the information necessary to interact with each interface, put together in a C-like language. This includes the structors, packet opcodes, and input/output parameters.

## The SMB\_COM\_TRANSACTION packet

Now, I'm no pro on this packet, and this is where my documentation ran out, but I'll explain how SMB\_TRANSACTION works for my purposes.

SMB\_TRANSACTION allows different actions to be performed, depending on how it's called. The only action I've used, however, is "write to named pipe". This lets us communicate with the back-end RPC services (although don't ask me how it works!). The SMB\_TRANSACTION packet essentially implements a sub protocol -- the client takes data, wraps SMB\_TRANSACTION around it, and sends it. When it arrives at the server, the SMB\_TRANSACTION is taken off, and the raw data is passed to the function that needs it. When that function returns, SMB\_TRANSACTION is wrapped around the returned data and it's sent to the caller, who removes the SMB\_TRANSACTION and gets the returned data back.

Those are all the SMB packets that are required to make the RPC calls! All calls are made through a sub-protocol, sent in the data of SMB\_TRANSACTION.

## Binding to a service

Even though we've attached to a named pipe, we still have to declare which interface we want to communicate with. Generally, the pipe and the interface have to match (the "samr" pipe goes with the "samr" interface).

Here are some common interfaces:

- "samr": 12345778-1234-abcd-ef00-0123456789ac
- "srvsvc": 4b324fc8-1670-01d3-1278-5a47bf6ee188
- "lsarpc": 12345778-1234-abcd-ef00-0123456789ab
- "winreg": 338cd001-2244-31f1-aaaa-900038001003

A common header is attached to the data, the interface and version are sent, and the bind() call is made (via SMB\_TRANSACTION). If the response is positive, then we are now bound to the service and can make calls against that service's functions.

## Calling a function

Finally, once the interface is bound, we can call a function!

To call a function, we build a buffer containing the common header, the opnum of the function (operator number), and the "in" arguments of a function (that is, the sent arguments). This is sent up through SMB\_TRANSACTION and is sent to the server. If all goes well, the server will return a buffer containing the header, the "out" arguments of the function, and the return value.

Let's take a simple example from the "winreg" service, the OpenHKLM() function. That should be familiar to any Windows programmer, it opens a handle to HKEY\_LOCAL\_MACHINE. From the \[url=http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/winreg.idl\]IDL file\[/url\], which is distributed with Samba, starting at version 4.0, we can find the function definition:

```
	/******************/
	/* Function: 0x02 */
	[public] WERROR winreg_OpenHKLM(
		[in]      uint16 *system_name,
		[in]      winreg_AccessMask access_mask,
		[out,ref] policy_handle *handle
	);
```

So from this, we know the opcode is 2, we're going to send two parameters, and receive a handle.

Here is my Nmap script code to call this function (note that this is from a newer version of my code than I've submitted -- in my current version, I marshall parameters by hand, but in this one it's abstracted away):

```

--      [in]      uint16 *system_name,
    arguments = msrpctypes.marshall_int16_ptr(0x1337)

--      [in]      winreg_AccessMask access_mask,
    arguments = arguments .. msrpctypes.marshall_winreg_AccessMask(
                                msrpctypes.winreg_AccessMask['MAXIMUM_ALLOWED_ACCESS']
                              )

--      [out,ref] policy_handle *handle

    -- Do the call
    status, result = call_function(smbstate, 0x02, arguments)
```

Simple enough! The "system\_name" parameter seemd to be filled with garbage in my tests, so I set it randomly and it works fine.

We'll explore the marshalling functions a little later, but first let's take a look at how the response is parsed:

```
--      [in]      uint16 *system_name,
--      [in]      winreg_AccessMask access_mask,
--      [out,ref] policy_handle *handle
    pos, response['handle'] = msrpctypes.unmarshall_policy_handle(arguments, 1)

    pos, response['return'] = msrpctypes.unmarshall_int32(arguments, pos)

    if(response['return'] == nil) then
        return false, "Read off the end of the packet (winreg.openhku)"
    end
    if(response['return'] ~= 0) then
        return false, smb.get_status_name(response['return']) .. " (winreg.openhku)"
    end
```

So the policy handle and return value are read. We check if return was 'nil', which means we accidentally read past the end of the packet, and we checked if return was non-0, which indicates an error condition.

That's all there is to making function calls! Everything else is just headers, which is handled by other layers. The trickiest part I've found is marshalling the parameters (which can actually be automated by parsing the .idl files).

So, on that topic....

## Marshalling Parameters

This is going to be a very brief summary, since marshalling parameters is tricky and full of pitfalls. The first thing to remember is that parameters will always be aligned at 4-byte boundaries (but structs in them may not be!). So, if you're adding a single character, you're also adding three blank spaces. Additionally, all string parameters are unicode, and some (but not all) have null-termination.

Without further ado, let's take a quick look at some data types!

### integer values ### Integers are the easiest ones. Here are the functions for adding int32, int16, and int8: ```
function marshall_int32(int32)
    return bin.pack("<i bin.pack="" end="" function="" int16="" int32="" int8="" marshall_int16="" marshall_int8="" return="">
</i><p>The variables are just converted to little endian and put directly into the buffer. </p>
<p>The next one is a little trickier, pointers to integers:</p>
function marshall_int32_ptr(int32)
    if(int32 == nil) then
        return bin.pack("<i bin.pack="" end="" function="" if="" int16="" int32="" int8="" marshall_int16_ptr="" marshall_int8_ptr="" nil="" referent_id="" return="" then="">
</i><p>The pointers are similar, except they have an extra 4-byte field in front, called a "referent_id" (at least by Wireshark). If the referent_id is non-zero, life goes on as usual; however, if the referent_id is zero, it's considered a "null" (or, in lua, "nil") pointer. </p>
<p>Marshalling a string gets a little bit deeper:</p>
function marshall_unicode(str, do_null, max_length)
    local buffer_length

    -- Check for null strings
    if(str == nil) then
        return bin.pack("<i actual="" bin.pack="" buffer_length="string.len(str)" count="" do_null="false" else="" end="" id="" if="" max="" max_length="buffer_length" nil="" offset="" referent="" referent_id="" return="" string_to_unicode="" then="" true="">
</i><p>A string is basically a referent_id followed by three values -- max count, offset, and buffer count -- followed by the string itself, in unicode. the max count is the maximum length of the buffer (if data is being returned in the buffer, this tells the function how much room it has). The offset is always 0 in everything I've looked at, so I ignore it. The actual count is the length of the string, counting the null terminator, if there is one. </p>
<p>My final example is going to be a series of structs that, together, represent the policy_handle:</p>
typedef struct {
      uint32 handle_type;
      GUID   uuid;
  } policy_handle;

<p>Becomes</p>
function marshall_policy_handle(policy_handle)
    return bin.pack("<ia end="" marshall_guid="" policy_handle="">
<p>Then this struct:</p>
typedef [public,noprint,gensize,noejs] struct {
      uint32 time_low;
      uint16 time_mid;
      uint16 time_hi_and_version;
      uint8  clock_seq[2];
      uint8  node[6];
  } GUID;

<p>Becomes:</p>
function marshall_guid(guid)
    return bin.pack("<issaa end="" guid="">
<h2>Summary</h2>
<p>If you've followed along, you'll see that the entire protocol is simply layers of abstraction, to the point where, when I'm developing code, I'm only implementing the parameter marshalling and unmarshalling. Everything else is taken care of by the same code that everything else uses. Even though the protocol itself is one big kludge, almost all of it can be abstracted away! </p>
<p>Hopefully this has been a fairly clear overview. I didn't want to dive too deeply right now, but give a little taste of everyt</p>
</issaa></ia>
```