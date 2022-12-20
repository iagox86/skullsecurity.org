---
id: 379
title: 'smb-psexec.nse: owning Windows, fast (Part 2)'
date: '2009-12-21T16:40:55-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=379'
permalink: /2009/smb-psexec-nse-owning-windows-fast-part-2
categories:
    - Hacking
    - NetBIOS/SMB
    - Nmap
---

Posts in this series (I'll add links as they're written):
<ol>
<li><a href='/blog/?p=365'>What does smb-psexec do?</a></li>
<li><a href='/blog/?p=379'><strong>Sample configurations ("sample.lua")</strong></a></li>
<li><a href='/blog/?p=404 '>Default configuration ("default.lua")</a></li>
<li>Advanced configuration ("pwdump.lua" and "backdoor.lua")</li>
</ol>
<!--more-->
<h2>Getting started</h2>
Hopefully you all read <a href='/blog/?p=365'>last week's post</a>. It's a good introduction on what you need to know about smb-psexec.nse before using it, but I realize it's a little dry in terms of things you can do. I'm hoping to change that this week, though, as I'll be going over a bunch of sample configurations. 

For what it's worth, this information is lifted, though heavily modified, from the <a href='http://nmap.org/nsedoc/scripts/smb-psexec.html'>NSEDoc</a> for the script. 

<h2>Configuration files</h2>
The configuration file for smb-psexec.nse is stored in the <tt>nselib/data/psexec</tt> directory. Depending on which operating system you're on, and how you install Nmap, it might be in one of the following places:
<ul>
  <li>/usr/share/nmap/nselib/data/psexec</li>
  <li>/usr/local/share/nmap/nselib/data/psexec</li>
  <li>C:\Program Files\Nmap\nselib\data\psexec</li>
</ul>

Note that up to and including Nmap 5.10BETA1, this folder will be missing on Windows. You'll need to download the Linux install and extract the 'psexec' folder. 

The configuration file is mostly a module list. Each module is a program to run, and it's defined by a Lua table. It has, for example, the executable to run and the arguments to pass to it. There are all kinds of options, but it's probably easiest just to look at an example (note: all examples can be found in <strong><tt>examples.lua</tt></strong>, which is included with Nmap). 

To test this stuff out, copy one of the built-in configuration files (such as example.lua), edit it, and run it with:
<pre>nmap -p139,445 -d --script=smb-psexec 
    --script-args=smbuser=&lt;username&gt;,smbpass=&lt;password&gt;,config=&lt;yourfilename&gt; &lt;target&gt;</pre>

For example:
<pre>nmap -p139,445 -d --script=smb-psexec 
    --script-args=smbuser=ron,smbpass=nor,config=experimental 10.0.0.123</pre>


<h2>Example 1: Getting started</h2>

<pre>
  mod = {}
  mod.upload           = false
  mod.name             = "Example 1: Membership of 'administrators'"
  mod.program          = "net.exe"
  mod.args             = "localgroup administrators"
  table.insert(modules, mod)
</pre>

Let's take a closer look at the fields. 

<strong>mod.upload</strong> is false, indicating that the program is already present on the remote system. Since the program is 'net.exe', it's installed by default on Windows and, obviously, doesn't have to be uploaded. 

<strong>mod.name</strong> is simply used as part of the output.

<strong>mod.program</strong> and <strong>mod.args</strong> obviously define which program to run and the arguments to run it with. In this case, we're running "<tt>net localgroup administrators</tt>", which displays the list of administrators on the remote system. The output for this script is this:

<pre>
  |  Example 1: Membership of 'administrators'
  |  | Alias name     administrators
  |  | Comment        Administrators have complete and unrestricted access to the
computer/domain
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
</pre>

That works, but it's pretty ugly. If you're scanning a lot of systems, you're going to end up with a lot of empty lines and other junk that you just don't need. 

<h2>Example 2: Cleaning it up</h2>
But, there's a solution! We can use some other fields to clean up the output, including:
<ul>
	<li><strong>mod.find</strong> -- Like 'grep', only lines that match the given pattern will be displayed.</li>
	<li><strong>mod.remove</strong> -- The opposite of 'find'; any lines containing the pattern are not displayed.</li>
	<li><strong>mod.replace</strong> -- A typical match/replace.</li>
	<li><strong>mod.noblank</strong> -- Remove blank lines.</li>
</ul>

A couple things worth noting here. This cleanup is done on the client, after the data has been returned from the server. So, if you're worried about a password field crossing the wire, or your output is thousands of lines, this isn't going to speed anything up. Additionally, the patterns are <a href='http://lua-users.org/wiki/PatternsTutorial'>Lua patterns</a>. 

So let's apply a few of these fields to our previous output:

<pre>
  mod = {}
  mod.upload           = false
  mod.name             = "Example 2: Membership of 'administrators', cleaned"
  mod.program          = "net.exe"
  mod.args             = "localgroup administrators"
  mod.remove           = {"The command completed", "%-%-%-%-%-%-%-%-%-%-%-", "Members", 
                                 "Alias name", "Comment"}
  mod.noblank          = true
  table.insert(modules, mod)
</pre>

Now we're using <strong>mod.remove</strong> to remove some of the crap, as well as <strong>mod.noblank</strong> to remove the blank lines.

We can see that the output is now much cleaner:

<pre>
  |  Example 2: Membership of 'administrators', cleaned
  |  | Administrator
  |  | ron
  |  |_test
</pre>

<h2>Example 3: Find/replace</h2>
For our next command, we're going to run <strong>ipconfig.exe</strong>, which outputs a significant amount of information. Let's say that all we want is the IP address and MAC address. Let's look at how to do it. 

{% raw %}
<pre>
  mod = {}
  mod.upload           = false
  mod.name             = "Example 3: IP Address and MAC Address"
  mod.program          = "ipconfig.exe"
  mod.args             = "/all"
  mod.maxtime          = 1
  mod.find             = {"IP Address", "Physical Address", "Ethernet adapter"}
  mod.replace          = {{"%. ", ""}, {"-", ":"}, {"Physical Address", "MAC Address"}}
  table.insert(modules, mod)
</pre>
{% endraw %}

Go ahead and type <tt>ipconfig /all</tt> to see what it looks like; I'll wait right here. 

This time, we use the <strong>mod.find</strong> to list the lines we want. Obviously, we're looking for three patterns: "IP Address", "Physical Address", and "Ethernet adapter". Then, we use <strong>mod.replace</strong> to replace ". " with nothing, "-" with ":", and "Physical Address" with "MAC Address" (arguably unnecessary). Here's the final output:

<pre>
  |  Example 3: IP Address and MAC Address
  |  | Ethernet adapter Local Area Connection:
  |  |    MAC Address: 00:0C:29:12:E6:DB
  |  |_   IP Address: 192.168.1.21
</pre>

<h2>Example 4 and 5: Variables</h2>
Next topic: variables!

Variables can be used in any field in the configuration file, such as find/replace, arguments, program name, etc. There are two types of variables: built-in and user-supplied. 

<strong>Built-in variables</strong> are set by the script. There are tons of them available, ranging in usefulness. Here are a bunch of them (I tried to put the more useful ones at the top):

<ul>
	<li><strong>$lhost</strong>: The address of the scanner</li>
	<li><strong>$rhost</strong>: The address being scanned</li>
	<li><strong>$path</strong>: The path to which the scripts were uploaded (eg, "C:\WINDOWS")</li>
	<li><strong>$share</strong>: The share where the script was uploaded (eg, "\\ADMIN$")</li>
	<li><strong>$lport</strong>: local port (meaningless; it'll change by the time the module is uploaded since multiple connections are made).</li>
	<li><strong>$rport</strong>: remote port (likely going to be 445 or 139).</li>
	<li><strong>$lmac</strong>: local mac address as a string in the xx:xx:xx:xx:xx:xx format (note: only set if the Nmap is running as root).</li>
	<li><strong>$service_name</strong>: the name of the service that is running this program</li>
	<li><strong>$service_file</strong>: the name of the executable file for the service</li>
	<li><strong>$temp_output_file</strong>: The (ciphered) file where the programs' output will be written before being renamed to $output_file</li>
	<li><strong>$output_file</strong>: The final name of the (ciphered) output file. When this file appears, the script downloads it and stops the service</li>
	<li><strong>$timeout</strong>: The total amount of time the script is going to run before it gives up and stops the process</li>
</ul>

<strong>User-supplied variables</strong> are provided on the commandline (in the --script-args argument) by the user when he or she runs the program. For example, to set the $test variable to 123, the user would pass --script-args=123. The required variables are controlled by the <strong>mod.req_args</strong> field in the configuration file, so to make $test a required field, you'd add mod.req_args to "test".

Here is a module that pings the local ip address, $lhost, which is a built-in variable:

<pre>
  mod = {}
  mod.upload           = false
  mod.name             = "Example 4: Can the host ping our address?"
  mod.program          = "ping.exe"
  mod.args             = "$lhost"
  mod.remove           = {"statistics", "Packet", "Approximate", "Minimum"}
  mod.noblank          = true
  mod.env              = "SystemRoot=c:\\WINDOWS" 
  table.insert(modules, mod)
</pre>

And the output:

<pre>
  |  Example 4: Can the host ping our address?
  |  | Pinging 192.168.1.100 with 32 bytes of data:
  |  | Reply from 192.168.1.100: bytes=32 time<1ms TTL=64
  |  | Reply from 192.168.1.100: bytes=32 time<1ms TTL=64
  |  | Reply from 192.168.1.100: bytes=32 time<1ms TTL=64
  |  |_Reply from 192.168.1.100: bytes=32 time<1ms TTL=64
</pre>

And this module pings an arbitrary address that the user is expected to give, $host:

<pre>
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
</pre>

And the output:

$ ./nmap -n -d -p445 --script=smb-psexec --script-args=smbuser=test,smbpass=test,config=examples,host=1.2.3.4 192.168.1.21

<pre>
 |  Example 5: Can the host ping 1.2.3.4?
 |  | Pinging 1.2.3.4 with 32 bytes of data:
 |  | Request timed out.
 |  | Request timed out.
 |  | Request timed out.
 |  |_Request timed out.
</pre>

<h2>Example 6: Uploading</h2>
For the final example, we'll use the 'upload' setting to upload the "fgdump.exe", run it, download its output file, and clean up its logfile. You'll have to put fgdump.exe in the same folder as the script for this to work:

<pre>
  mod = {}
  mod.upload           = true
  mod.name             = "Example 6: FgDump"
  mod.program          = "fgdump.exe"
  mod.args             = "-c -l fgdump.log"
  mod.url              = "http://www.foofus.net/fizzgig/fgdump/"
  mod.tempfiles        = {"fgdump.log"}
  mod.outfile          = "127.0.0.1.pwdump"
  table.insert(modules, mod)
</pre>

The -l argument for fgdump (in <strong>mod.args</strong>) supplies the name of the logfile. That file is listed in the <strong>mod.tempfiles</strong> field. What, exactly, does mod.tempfiles do? It simply gives Nmap a list of files to delete after the program runs. It's good for deleting logfiles other other artifacts your programs leave. 

<strong>mod.url</strong> is displayed to the user in an error message if mod.program isn't found in Nmap's data directory. And finally, <strong>mod.outfile</strong> is the file that is downloaded from the system, since fgdump.exe doesn't print to stdout (pwdump6, for example, doesn't require mod.outfile).

<h2>Fields in 'mod'</h2>
The following is a list of all possible fields in the 'mod' variable:
<ul>
  <li><strong>upload</strong> <em>(boolean)</em> true if it's a local file to upload, false if it's already on the host machine. If upload is true, program has to be in nselib/data/psexec.</li>
  <li><strong>name</strong> <em>(string)</em> The name to display above the output. If this isn't given, program .. args are used.</li>
  <li><strong>program</strong> <em>(string)</em> If upload is false, the name (fully qualified or relative) of the program on the remote system; if upload is true, the name of the local file that will be uploaded (stored in nselib/data/psexec).</li>
  <li><strong>args</strong> <em>(string)</em> Arguments to pass to the process.</li>
  <li><strong>env</strong> <em>(string)</em> Environmental variables to pass to the process, as name=value pairs, delimited, per Microosft's spec, by NULL characters (string.char(0)).</li>
  <li><strong>maxtime</strong> <em>(integer)</em> The approximate amount of time to wait for this process to complete. The total timeout for the script before it gives up waiting for a response is the total of all 'maxtime' fields.</li>
  <li><strong>extrafiles</strong> <em>(string[])</em> Extra file(s) to upload before running the program. These will <em>not</em> be renamed (because, presumably, if they are then the program won't be able to find them), but they will be marked as hidden/system/etc. This may cause a race condition if multiple people are doing this at once, but there isn't much we can do. The files are also deleted afterwards as tempfiles would be. The files have to be in the same directory as programs (nselib/data/psexec), but the program doesn't necessarily need to be an uploaded one.</li>
  <li><strong>tempfiles</strong> <em>(string[])</em> A list of temporary files that the process is known to create (if the process does create files, using this field is recommended because it helps avoid making a mess on the remote system)</li>
  <li><strong>find</strong> <em>(string[])</em> Only display lines that contain the given string(s) (for example, if you're searching for a line that contains 'IP Address', set this to {'IP Address'}. This allows Lua-style patterns, see: <http://lua-users.org/wiki/PatternsTutorial> (don't forget to escape special characters with a '%'). Note that this is client-side only; the full output is still returned, the rest is removed while displaying. The line of output only needs to match one of the strings given here.</li>
  <li><strong>remove</strong> <em>(string[])</em> Opposite of find; this removes lines containing the given string(s) instead of displaying them. Like find, this is client-side only and uses Lua-style patterns. If 'remove' and 'find' are in conflict, the 'remove' takes priority.</li>
  <li><strong>noblank</strong> <em>(boolean)</em> Setting this to true removes all blank lines from the output.</li>
  <li><strong>replace</strong> <em>(table)</em> A table of values to replace in the strings returned. Like find and replace, this is client-side only and uses Lua-style patterns.</li>
  <li><strong>headless</strong> <em>(boolean)</em> If 'headless' is set to true, the program doesn't return any output; rather, it runs detached from the service so that, when the service ends, the program keeps going. This can be useful for, say, a monitoring program. Or a backdoor, if that's what you're into (a Metasploit payload should work nicely). Not compatible with: find, remove, noblank, replace, maxtime, outfile.</li>
  <li><strong>enabled</strong> <em>(boolean)</em> Set to false, and optionally set disabled_message, if you don't want a module to run. Alternatively, you can comment out the process.</li>
  <li><strong>disabled_message</strong> <em>(string)</em> Displayed if the module is disabled.</li>
  <li><strong>url</strong> <em>(string)</em> A module where the user can download the uploadable file. Displayed if the uploadable file is missing.</li>
  <li><strong>outfile</strong> <em>(string)</em> If set, the specified file will be returned instead of stdout.</li>
  <li><strong>req_args</strong> <em>(string[])</em> An array of arguments that the user must set in --script-args.</li>
</ul>

As you can see, there are a ton of options. Check out my default scripts for more ideas/examples!
