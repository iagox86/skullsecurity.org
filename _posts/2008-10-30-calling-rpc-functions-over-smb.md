---
id: 92
title: 'Calling RPC functions over SMB'
date: '2008-10-30T22:45:19-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=92'
permalink: /2008/calling-rpc-functions-over-smb
categories:
    - NetBIOS/SMB
---

Hi everybody! 

This is going to be a fairly high level discussion on the sequence of calls and packets required to make MSRPC calls over the SMB protocol. I've learned this from a combination of reading the book <a href='http://www.ubiqx.org/cifs/'>Implementing CIFS</a>, watching other tools do their stuff with Wireshark, and plain ol' guessing/checking. 
<!--more-->
Basically, I want to take you from the SMB protocol, which I've discussed in previous posts, all the way down to making RPC calls against remote Windows systems. This is going to be quick, and light on detail, but it's only intended as an overview. If you want more information, follow the above references, take a peek at my Nmap scripts, or post a specific question. I'm more than happy to answer! 

<h2>Making a SMB connection</h2>
SMB communication can be performed over ports tcp/445 and tcp/139. Port 445 allows for a "raw" SMB connection, while 139 is "SMB over NetBIOS". Effectively, they are the same thing with two differences:
<ol>
<li>SMB over NetBIOS requires a "NetBIOS Session Request" packet, which is a client saying, "hi, I'm xxx, can I connect to you?"</li>
<li>SMB over NetBIOS has a packet length field that's 17 bits (maximum = 131,072), while Raw SMB has a packet length field that's 24 bits long (maximum = 16,777,216). Since protocol limitations stop you long before you reach these limits, they aren't significant.</li>
</ol>

I don't want to dwell on it, but the NetBIOS Session Request looks like this (when sent from my Nmap scripts):
<pre>NetBIOS Session Service
 +Length: 68
 +Called name: BASEWIN2K3<20>
 +Calling name: NMAP<20></pre>

The trick here is that we need to find the server's name ("BASEWIN2K3") before we can make this request. This can be retrieved in a number of ways, but the easiest is to make an nbstat request over UDP/137, if possible, or check the DNS name.

<h2>Starting a SMB Session</h2>
In a <a href="http://www.skullsecurity.org/blog/?p=45">previous blog</a>, in a section entitled "Random SMB stuff", I talked about the first three packets sent to SMB: SMB_COM_NEGOTIATE, SMB_COM_SESSION_SETUP_ANDX, and SMB_COM_TREE_CONNECT_ANDX. These three packets are still used to start the session:
<ul>
<li>SMB_COM_NEGOTIATE -- Sent as normal</li>
<li>SMB_COM_SESSION_SETUP_ANDX -- Contains authentication information, if we're logging in with a user account. I'll talk about the differences between the four primary levels (administrator, user, guest, anonymous) in another blog, and I talked about how to prepare your password <a href="http://www.skullsecurity.org/blog/?p=34">in a previous blog</a>. </li>
<li>SMB_COM_TREE_CONNECT_ANDX -- We use this to connect to a special share "IPC$" (that's interprocess communication, not the place I work). Everybody should have access to this share, no matter the user level. </li>
</ul>

<h2>Attaching to the pipe</h2>
After the three standard initial packets, another common packet is sent -- SMB_COM_NT_CREATE. This is the packet used to create and open files. In this case, it's used to open a named pipe (since we're attached to the IPC$ share, you can't actually create files). This is done by opening what looks like a file. For example, some common pipes to open are:
<ul>
<li><a href="http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/samr.idl">\samr</a> -- user management (SAM) functions</li>
<li><a href="http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/srvsvc.idl">\srvsvc</a> -- server management</li>
<li><a href="http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/lsa.idl">\lsarpc</a> -- local security authority</li>
<li><a href="http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/winreg.idl">\winreg</a> -- Windows registry</li>
</ul>

Once the file has successfully been opened, we can begin interacting with it via the SMB_TRANSACTION layer. If you're using a low-level account, you may hit an ACCESS_DENIED error here. 

The links I provided contain all the information necessary to interact with each interface, put together in a C-like language. This includes the structors, packet opcodes, and input/output parameters. 

<h2>The SMB_COM_TRANSACTION packet</h2>
Now, I'm no pro on this packet, and this is where my documentation ran out, but I'll explain how SMB_TRANSACTION works for my purposes. 

SMB_TRANSACTION allows different actions to be performed, depending on how it's called. The only action I've used, however, is "write to named pipe". This lets us communicate with the back-end RPC services (although don't ask me how it works!). The SMB_TRANSACTION packet essentially implements a sub protocol -- the client takes data, wraps SMB_TRANSACTION around it, and sends it. When it arrives at the server, the SMB_TRANSACTION is taken off, and the raw data is passed to the function that needs it. When that function returns, SMB_TRANSACTION is wrapped around the returned data and it's sent back to the client, who removes the SMB_TRANSACTION and gets the returned data back. 

Those are all the SMB packets that are required to make the RPC calls! All calls are made through a sub-protocol, sent in the data of SMB_TRANSACTION. 

<h2>Binding to a service</h2>
Even though we've attached to a named pipe, we still have to declare which interface we want to communicate with. Generally, the pipe and the interface have to match (the "\samr" pipe goes with the "samr" interface). 

Here are some common interfaces:
<ul>
<li>"\samr": 12345778-1234-abcd-ef00-0123456789ac</li>
<li>"\srvsvc": 4b324fc8-1670-01d3-1278-5a47bf6ee188</li>
<li>"\lsarpc": 12345778-1234-abcd-ef00-0123456789ab</li>
<li>"\winreg": 338cd001-2244-31f1-aaaa-900038001003</li>
</ul>

To bind to a service, the interface and version are sent, with some extra information, to the bind() function (via SMB_TRANSACTION). If the response is positive, then we are now bound to the service and can make calls against that service's functions. 

<h2>Calling a function</h2>
Finally, once the interface is bound, we can call a function! 

To call a function, we build a buffer containing the header, which is the same across all RPC stuff, the opnum/opcode of the function (operation number or operation code), and the marshalled "in" arguments of the function (that is, the sent arguments). This is sent up through SMB_TRANSACTION and is sent to the server. If all goes well, the server will return a buffer containing the header, the marshalled "out" arguments of the function, and the return value. (Marshalling is the process of taking a bunch of parameters and turning them into a stream of data.)

Let's take a simple example from the "winreg" service, the OpenHKLM() function. That should be familiar to any Windows programmer, it opens a handle to HKEY_LOCAL_MACHINE. From the <a href='http://anonsvn.wireshark.org/wireshark/trunk/epan/dissectors/pidl/winreg.idl'>IDL file</a>, which is distributed with Samba 4.0 and later, we can find the function definition:
<pre>	/******************/
	/* Function: 0x02 */
	[public] WERROR winreg_OpenHKLM(
		[in]      uint16 *system_name,
		[in]      winreg_AccessMask access_mask,
		[out,ref] policy_handle *handle
	);
</pre>
So from this, we know the opcode is 2, we're going to send two parameters, and receive a handle. 

Here is my Nmap script code to call this function (note that this is from a newer version of my code than I've submitted -- in my current version, I marshall parameters by hand, but in this one it's abstracted away):
<pre>
--      [in]      uint16 *system_name,
    arguments = msrpctypes.marshall_int16_ptr(0x1337)

--      [in]      winreg_AccessMask access_mask,
    arguments = arguments .. msrpctypes.marshall_winreg_AccessMask(
                    msrpctypes.winreg_AccessMask['MAXIMUM_ALLOWED_ACCESS']
                   )

--      [out,ref] policy_handle *handle

    -- Do the call
    status, result = call_function(smbstate, 0x02, arguments)
</pre>

Simple enough! The "system_name" parameter seemd to be filled with garbage in my tests, so I set it randomly and it works fine. 

We'll explore the marshalling functions a little later, but first let's take a look at how the response is parsed:
<pre>--      [in]      uint16 *system_name,
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
</pre>
So the policy handle and return value are read. We check if return was 'nil', which means we accidentally read past the end of the packet, and we checked if return was non-0, which indicates an error condition. 

That's all there is to making function calls! Everything else is just headers, which are handled by other layers. The trickiest part I've found is marshalling the parameters (which can actually be automated by parsing the .idl files). 

So, on that topic....
<h2>Marshalling Parameters</h2>
This is going to be a very brief summary, since marshalling parameters is tricky and full of pitfalls. The first thing to remember is that parameters will always be aligned at 4-byte boundaries (but members of structs within them may not be!). So, if you're adding a single character, you're also adding three blank spaces. I fill these with nulls, but you can send whatever you want (even 0x29a if you have two bytes to fill and you swing that way). Additionally, all string parameters are unicode, and some (but not all) are null terminated. 

So without further ado, let's take a quick look at some data types! 

<h3>integer values</h3>
Integers are the easiest ones. Here are the functions for adding int32, int16, and int8:
<pre>function marshall_int32(int32)
    return bin.pack("&lt;I", int32)
end

function marshall_int16(int16)
    return bin.pack("&lt;SS", int16, 0)
end

function marshall_int8(int8)
    return bin.pack("&lt;CCS", int8, 0, 0)
end
</pre>
The variables are just converted to little endian and put directly into the buffer. 

<h3>Integer pointers</h3>
The next one is a little trickier, pointers to integers:
<pre>function marshall_int32_ptr(int32)
    if(int32 == nil) then
        return bin.pack("&lt;I", 0)
    end

    return bin.pack("&lt;II", REFERENT_ID, int32)
end

function marshall_int16_ptr(int16)
    if(int16 == nil) then
        return bin.pack("&lt;I", 0)
    end

    return bin.pack("&lt;ISS", REFERENT_ID, int16, 0)
end

function marshall_int8_ptr(int8)
    if(int8 == nil) then
        return bin.pack("&lt;I", 0)
    end

    return bin.pack("&lt;ICCS", REFERENT_ID, int8, 0, 0)
end
</pre>

The pointers are similar, except they have an extra 4-byte field in front, called a "referent_id" (at least by Wireshark). If the referent_id is non-zero, life goes on as usual; however, if the referent_id is zero, it's considered a "null" (or, in lua, "nil") pointer. 

<h3>Strings</h3>
Marshalling a string gets a little bit deeper:
<pre>function marshall_unicode(str, do_null, max_length)
    local buffer_length

    -- Check for null strings
    if(str == nil) then
        return bin.pack("&lt;I", 0)
    end

    if(do_null) then
        buffer_length = string.len(str) + 1
    else
        buffer_length = string.len(str)
    end

    if(max_length == nil) then
        max_length = buffer_length
    end

    return bin.pack("&lt;IIIIA",
                REFERENT_ID,      -- Referent ID
                max_length,       -- Max count
                0,                -- Offset
                buffer_length,    -- Actual count
                string_to_unicode(str, do_null, true)
            )
end
</pre>
A string is basically a referent_id followed by three values -- max count, offset, and buffer count -- followed by the string itself, in unicode. The max count is the maximum length of the buffer (if data is being returned in the buffer, this tells the function how much room it has; otherwise, it's just the length of the string). The offset is always 0 in everything I've looked at, so I ignore it. The actual count is the length of the string, counting the null terminator, if there is one. Note that my code handles both cases. 

<h3>Structs</h3>
My final example is going to be a series of structs that, together, represent a policy_handle:
<pre>typedef struct {
      uint32 handle_type;
      GUID   uuid;
  } policy_handle;
</pre>
Becomes
<pre>function marshall_policy_handle(policy_handle)
    return bin.pack("&lt;IA", policy_handle['handle_type'], 
                     marshall_guid(policy_handle['uuid']))
end</pre>

Then this struct:
<pre>typedef [public,noprint,gensize,noejs] struct {
      uint32 time_low;
      uint16 time_mid;
      uint16 time_hi_and_version;
      uint8  clock_seq[2];
      uint8  node[6];
  } GUID;
</pre>
Becomes
<pre>function marshall_guid(guid)
    return bin.pack("&lt;ISSAA", guid['time_low'], guid['time_high'], 
                     guid['time_hi_and_version'], guid['clock_seq'], guid['node'])
end</pre>

<h2>Summary</h2>
If you've followed along, you'll see that the entire protocol is simply layers of abstraction, to the point where, when I'm developing code, I'm only implementing the parameter marshalling and unmarshalling. Everything else is taken care of by the same code that everything else uses. Even though the protocol itself is more or less one big kludge (or, in some respects, a group of smaller kludges, or a clusterkludge?), almost all of it can be abstracted away! 

Hopefully this has been a fairly clear overview. I didn't want to dive too deeply right now, but to give a little taste of everything. Let me know if you have any questions or comments! 

Ron
