---
id: 385
title: 'smb-psexec.nse: owning Windows, fast (Part 2)'
date: '2009-12-21T16:04:53-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=385'
permalink: '/?p=385'
---

Posts in this series (I'll add links as they're written):

1. [What does smb-psexec do?](/blog/?p=365)
2. [**Sample configurations ("sample.lua")**](/blog/?p=379)
3. Default configuration ("default.lua")
4. Advanced configuration ("pwdump.lua" and "backdoor.lua")
5. Conclusions

## Getting started

Hopefully you all read [last week's post](/blog/?p=365). It's a good introduction on what you need to know about smb-psexec.nse before using it, but I realize it's a little dry in terms of things you can do. I'm hoping to change that this week, though, as I'll be going over a bunch of sample configurations.

For what it's worth, this information is lifted, by and large, from the [NSEDoc](http://nmap.org/nsedoc/scripts/smb-psexec.html) for the script.

## Configuration files

The configuration file for smb-psexec.nse is stored in the <tt>nselib/data/psexec</tt> directory. Depending on which operating system you're on, and how you install Nmap, it might be in one of the following places:

- /usr/share/nmap/nselib/data/psexec
- /usr/local/share/nmap/nselib/data/psexec
- C:\\Program Files\\Nmap\\nselib\\data\\psexec

Note that up to and including Nmap 5.10BETA1, this folder will be missing on Windows. You'll need to download the Linux install and copy out the file.

The configuration file is mostly a module list. Each module is a program to run, and it's defined by a Lua table. It has, for example, the executable to run and the arguments to pass to it. There are all kinds of options, but it's probably easiest just to look at an example (note: all examples can be found in **<tt>examples.lua</tt>**, which is included with Nmap):

```

  mod = {}
  mod.upload           = false
  mod.name             = "Example 1: Membership of 'administrators'"
  mod.program          = "net.exe"
  mod.args             = "localgroup administrators"
  table.insert(modules, mod)
```

Let's take a closer look at the fields.

**mod.upload** is **false**, indicating that the program is already present on the remote system. Since the program is **net.exe**, it's installed by default on Windows and, obviously, doesn't have to be uploaded.

**mod.name** is simply used as part of the output.

**mod.program** and **mod.args** obviously define which program to run and the arguments to run it with. In this case, we're running "<tt>net localgroup administrators</tt>", which displays the list of administrators on the remote system. The output for this script is this:

```

  |  Example 1: Membership of 'administrators'
  |  | Alias name     administrators
  |  | Comment        Administrators have complete and unrestricted access to the computer/domain
  |  | 
  |  | Members
  |  | 
  |  | -------------------------------------------------------------------------------
  |  | Administrator
  |  | ron
  |  | test
  |  | The command completed successfully.
  |  | 
  |  |_
```

That works, but it's pretty ugly. If you're scanning a lot of systems, you're going to end up with a lot of empty lines and other junk that you just don't need.

But, there's a solution! We can use some other fields to clean up the output, including:

- **mod.find** -- Like 'grep', only lines that match the given pattern will be displayed.
- **mod.remove** -- The opposite of 'find'; any lines containing the pattern are not displayed.
- **mod.replace** -- A typical match/replace.
- **mod.noblank** -- Remove blank lines.

A couple things worth noting here. This cleanup is done on the client, after the data has been returned from the server. So, if you're worried about a password field crossing the wire, or your output is thousands of lines, this isn't going to speed anything up. Additionally, the patterns are [Lua patterns](http://lua-users.org/wiki/PatternsTutorial).

So let's apply a few of these fields to our previous output:

```

  mod = {}
  mod.upload           = false
  mod.name             = "Example 2: Membership of 'administrators', cleaned"
  mod.program          = "net.exe"
  mod.args             = "localgroup administrators"
  mod.remove           = {"The command completed", "%-%-%-%-%-%-%-%-%-%-%-", "Members", "Alias name", "Comment"}
  mod.noblank          = true
  table.insert(modules, mod)
```

Now we're using **mod.remove** to remove some of the crap, as well as **mod.noblank** to remove the blank lines.

We can see that the output is now much cleaner:

```

  |  Example 2: Membership of 'administrators', cleaned
  |  | Administrator
  |  | ron
  |  |_test
```

For our next command, we're going to run **ipconfig.exe**, which outputs a significant amount of information. Let's say that all we want is the IP address and MAC address. Let's look at how to do it:

```

  mod = {}
  mod.upload           = false
  mod.name             = "Example 3: IP Address and MAC Address"
  mod.program          = "ipconfig.exe"
  mod.args             = "/all"
  mod.maxtime          = 1
  mod.find             = {"IP Address", "Physical Address", "Ethernet adapter"}
  mod.replace          = {{"%. ", ""}, {"-", ":"}, {"Physical Address", "MAC Address"}}
  table.insert(modules, mod)
```

Go ahead and type <tt>ipconfig /all</tt> to see what it looks like; I'll wait right here.

This time, we use the **mod.find** to list the lines we want. Obviously, we're looking for three patterns: "IP Address", "Physical Address", and "Ethernet adapter" Then, we use **mod.replace** to replace ". " with nothing, "-" with ":", and "Physical Address" with "MAC Address" (arguably unnecessary). Here's the final output:

```

  |  Example 3: IP Address and MAC Address
  |  | Ethernet adapter Local Area Connection:
  |  |    MAC Address: 00:0C:29:12:E6:DB
  |  |_   IP Address: 192.168.1.21|  Example 3: IP Address and MAC Address
```

Next topic: variables!

Variables can be used in any script field. There are two types of variables: built-in and user-supplied.

**Built-in variables** are set by the script. There are tons of them available, ranging in usefulness. Here are a bunch of them (I tried to put the more useful ones at the front):

- **$lhost**: The address of the scanner
- **$rhost**: The address being scanned
- **$path**: The path to which the scripts were uploaded (eg, "C:\\WINDOWS")
- **$share**: The share where the script was uploaded (eg, "\\\\ADMIN$")
- **$lport**: local port (meaningless; it'll change by the time the module is uploaded since multiple connections are made).
- **$rport**: remote port (likely going to be 445 or 139).
- **$lmac**: local mac address as a string in the xx:xx:xx:xx:xx:xx format (note: only set if the Nmap is running as root).
- **$service\_name**: the name of the service that is running this program
- **$service\_file**: the name of the executable file for the service
- **$temp\_output\_file**: The (ciphered) file where the programs' output will be written before being renamed to $output\_file
- **$output\_file**: The final name of the (ciphered) output file. When this file appears, the script downloads it and stops the service
- **$timeout**: The total amount of time the script is going to run before it gives up and stops the process

**User-supplied variables** are provided on the commandline (in the --script-args argument) by the user when he or she runs the program. For example, to set the $test variable to 123, the user would pass --script-args=123. The required variables are controlled by the **mod.req\_args** field in the configuration file, so to make $test a required field, you'd add mod.req\_args to "test".

Here is a module that pings the local ip address, $lhost, which is a built-in variable:

 mod = {}  
 mod.upload = false  
 mod.name = "Example 4: Can the host ping our address?"  
 mod.program = "ping.exe"  
 mod.args = "$lhost"  
 mod.remove = {"statistics", "Packet", "Approximate", "Minimum"}  
 mod.noblank = true  
 mod.env = "SystemRoot=c:\\\\WINDOWS"  
 table.insert(modules, mod)

And the output:

```

  |  Example 4: Can the host ping our address?
  |  | Pinging 192.168.1.100 with 32 bytes of data:
  |  | Reply from 192.168.1.100: bytes=32 time
<p>And this module pings an arbitrary address that the user is expected to give, $host:</p>

 mod = {}
 mod.upload           = false
 mod.name             = "Example 5: Can the host ping $host?"
 mod.program          = "ping.exe"
 mod.args             = "$host"
 mod.remove           = {"statistics", "Packet", "Approximate", "Minimum"}
 mod.noblank          = true
 mod.env              = "SystemRoot=c:\\WINDOWS"
 mod.req_args         = {'host'}
 table.insert(modules, mod)

<p>And the output:</p>
<p>$ ./nmap -n -d -p445 --script=smb-psexec --script-args=smbuser=test,smbpass=test,config=examples,host=1.2.3.4 192.168.1.21</p>

 |  Example 5: Can the host ping 1.2.3.4?
 |  | Pinging 1.2.3.4 with 32 bytes of data:
 |  | Request timed out.
 |  | Request timed out.
 |  | Request timed out.
 |  |_Request timed out.

<p>For the final example, we'll use the 'upload' command to upload the "fgdump.exe", run it, download its output file, and clean up its logfile. You'll have to put fgdump.exe in the same folder as the script for this to work:</p>

  mod = {}
  mod.upload           = true
  mod.name             = "Example 6: FgDump"
  mod.program          = "fgdump.exe"
  mod.args             = "-c -l fgdump.log"
  mod.url              = "http://www.foofus.net/fizzgig/fgdump/"
  mod.tempfiles        = {"fgdump.log"}
  mod.outfile          = "127.0.0.1.pwdump"
  table.insert(modules, mod)

<p>The -l argument for fgdump (in <b>mod.args</b>) supplies the name of the logfile. That file is listed in the <b>mod.tempfiles</b> field. What, exactly, does mod.tempfiles do? It simply gives Nmap a list of files to delete after the program runs, </p>
<p><b>mod.url</b> is displayed to the user in an error message if mod.program isn't found in Nmap's data directory. And finally, <b>mod.outfile</b> is the file that is downloaded from the system, since fgdump.exe doesn't print to stdout (pwdump6, for example, doesn't require mod.outfile).</p>
<p>The following is a list of all possible fields in the 'mod' variable:</p>

  
```

40. **upload** *(boolean)* true if it's a local file to upload, false if it's already on the host machine. If upload is true, program has to be in nselib/data/psexec.
41. **name** *(string)* The name to display above the output. If this isn't given, program .. args are used.
42. **program** *(string)* If upload is false, the name (fully qualified or relative) of the program on the remote system; if upload is true, the name of the local file that will be uploaded (stored in nselib/data/psexec).
43. **args** *(string)* Arguments to pass to the process.
44. **env** *(string)* Environmental variables to pass to the process, as name=value pairs, delimited, per Microosft's spec, by NULL characters (string.char(0)).
45. **maxtime** *(integer)* The approximate amount of time to wait for this process to complete. The total timeout for the script before it gives up waiting for a response is the total of all 'maxtime' fields.
46. **extrafiles** *(string\[\])* Extra file(s) to upload before running the program. These will \*not
47. **be renamed (because, presumably, if they are then the program won't be able to find them), but they will be marked as hidden/system/etc. This may cause a race condition if multiple people are doing this at once, but there isn't much we can do. The files are also deleted afterwards as tempfiles would be. The files have to be in the same directory as programs (nselib/data/psexec), but the program doesn't necessarily need to be an uploaded one.**
48. **tempfiles** *(string\[\])* A list of temporary files that the process is known to create (if the process does create files, using this field is recommended because it helps avoid making a mess on the remote system)
49. **find** *(string\[\])* Only display lines that contain the given string(s) (for example, if you're searching for a line that contains 'IP Address', set this to {'IP Address'}. This allows Lua-style patterns, see: <http:> (don't forget to escape special characters with a '%'). Note that this is client-side only; the full output is still returned, the rest is removed while displaying. The line of output only needs to match one of the strings given here.</http:>
50. **remove** *(string\[\])* Opposite of find; this removes lines containing the given string(s) instead of displaying them. Like find, this is client-side only and uses Lua-style patterns. If 'remove' and 'find' are in conflict, the 'remove' takes priority.
51. **noblank** *(boolean)* Setting this to true removes all blank lines from the output.
52. **replace** *(table)* A table of values to replace in the strings returned. Like find and replace, this is client-side only and uses Lua-style patterns.
53. **headless** *(boolean)* If 'headless' is set to true, the program doesn't return any output; rather, it runs detached from the service so that, when the service ends, the program keeps going. This can be useful for, say, a monitoring program. Or a backdoor, if that's what you're into (a Metasploit payload should work nicely). Not compatible with: find, remove, noblank, replace, maxtime, outfile.
54. **enabled** *(boolean)* Set to false, and optionally set disabled\_message, if you don't want a module to run. Alternatively, you can comment out the process.
55. **disabled\_message** *(string)* Displayed if the module is disabled.
56. **url** *(string)* A module where the user can download the uploadable file. Displayed if the uploadable file is missing.
57. **outfile** *(string)* If set, the specified file will be returned instead of stdout.
58. **req\_args** *(string\[\])* An array of arguments that the user must set in --script-args.
As you can see, there are a ton of options. Check out my default scripts for more ideas/examples!