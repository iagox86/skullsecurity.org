---
id: 643
title: 'Learning how the Energizer Trojan ticks&#8230;'
date: '2010-03-23T10:50:26-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=643'
permalink: '/?p=643'
---

Hey all,

As most of you know, a Trojan was [recently discovered](http://www.theregister.co.uk/2010/03/08/energizer_trojan/) in the software for Energizer's USB battery charger. Following its release, I wrote an [Nmap probe](http://www.skullsecurity.org/blog/?p=563) to detect the Trojan and HDMoore wrote a [Metasploit module](http://blog.metasploit.com/2010/03/locate-and-exploit-energizer-trojan.html) to exploit it.

I mentioned in my last post that it was a nice sample to study and learn from. The author made absolutely no attempt to conceal its purpose, once installed, besides a weak XOR ciphering for communication. Some conspiracy theorists even think this may have been legitimate management software gone wrong -- and who knows, really? In any case, I offered to write a tutorial on how I wrote the Nmap probe, and had a lot of positive feedback, so here it is!

## Step 0: You will need...

To follow along, you'll need the following (all free, except for Windows):

- A disposable Windows computer to infect (probably on VMWare)
- [Debugging Tools for Windows](http://www.microsoft.com/whdc/devtools/debugging/installx86.Mspx) (I used 6.11.1.404)
- [IDA (free)](http://www.hex-rays.com/idapro/idadownfreeware.htm)
- [Nmap](http://nmap.org)
- A basic understanding of C and x86 assembly would be an asset. <shamelessplug>Check out the [reverse engineering guide I wrote](http://www.skullsecurity.org/wiki/index.php/Assembly)</shamelessplug>
- A basic understanding of the Linux commandline (gcc, pipes, etc)

## Step 1: Infect a test machine

The goal of this step is, obviously, to infect a test system with the Energizer Trojan.

Strictly speaking, this isn't necessary. You can do a fine job understanding this sample without actually infecting yourself. That being said, this Trojan appears to be fairly safe, as far as malware goes, so it's a good one to play with. I *strongly recommend against* installing this on anything other than a throwaway computer (I used VMWare). Do **not** install this on anything real. Ever. Seriously!

If you're good and sure this is what you really want to do, grab the file [here](http://downloads.skullsecurity.org/MALWARE/EnergizerTrojan-MALWARE.zip):

![](http://www.skullsecurity.org/blogdata/usbcharger-01-download.png)

Then extract the installation file, **UsbCharger\_setup\_v1\_1\_1.exe** (**arucer.dll** isn't necessary yet). The password for the zip archive is "infected", and by typing it in you promise to understand the risks of dealing with malware:  
![](http://www.skullsecurity.org/blogdata/usbcharger-02-infected.png)

Naturally, make sure you turn off antivirus software before extracting it. In fact you shouldn't even be running antivirus because your system shouldn't even be connected to the network!

Perform a typical install (ie, hit 'next' till it stops asking you questions). Once you've finished the installation, verify that the backdoor is listening on port 7777 by running "cmd.exe" and running "netstat -an":  
![](http://www.skullsecurity.org/blogdata/usbcharger-04-netstat.png)

Congratulations! Your system is now backdoored.

## Step 2: Runtime analysis

Now that we've infected a test machine, the goal of the next step is to experiment a little with the debugger and find out a little about the Energizer Trojan. This can all be discovered with a simple disassembler, but I find it more fun to take apart a live sample. All we're going to do is add a breakpoint at the recv() function and see where it's called from.

In Step 1, we infected the system with the Trojan. It should still be running on the victim machine.

This step is going to require [Debugging Tools for Windows](http://www.microsoft.com/whdc/devtools/debugging/installx86.Mspx). If you haven't installed it already, install it on the victim machine.

Run "windbg"; then, under the "File" menu, choose "Attach to a Process" (or press F6):  
![](http://www.skullsecurity.org/blogdata/usbcharger-05-attach.png)

Navigate the list and find "rundll32.exe":  
![](http://www.skullsecurity.org/blogdata/usbcharger-06-rundll32.png)

If you aren't sure if it's the right one, expand it with the "+" and validate that it's running "Arucer.dll":  
![](http://www.skullsecurity.org/blogdata/usbcharger-07-arucer.dll.png)

Once you hit "OK", the debugger will attach to the Trojan process and suspend it, waiting for your actions. It'll look something like this:  
![](http://www.skullsecurity.org/blogdata/usbcharger-08-windbg.png)

All we want to do is add a breakpoint on the "recv" function. "recv" is a function in Winsock that reads data from the network. Since this Trojan is listening on a port, it'll likely try to receive data from anything that connects to it. In the command window of Windbg, type "bp recv":  
![](http://www.skullsecurity.org/blogdata/usbcharger-09-bp_recv.png)

To validate that the breakpoint was successfully created, you can run the "bl" command ("breakpoint list"), which will print all breakpoints that have been set on this process:  
![](http://www.skullsecurity.org/blogdata/usbcharger-10-bl.png)

Now that we've set a breakpoint on recv() and verified that it exists, resume the Trojan process by clicking the "Resume" button (or press F5, or type "g<enter>"):  
![](http://www.skullsecurity.org/blogdata/usbcharger-11-g.png)

You'll note that nothing happens right away. And unless something tries to connect to the host on port 7777, nothing is going to happen. The reason is that the Trojan is waiting for a connection, sitting on the accept() call. Obviously, we need to trigger the recv() to happen, so open up a new command prompt (cmd.exe) and telnet to it:  
![](http://www.skullsecurity.org/blogdata/usbcharger-12-telnet.png)

As soon as you do that, the accept() call finishes and the Trojan attempts to receive some data, hitting our breakpoint:  
![](http://www.skullsecurity.org/blogdata/usbcharger-13-break.png)

The process is once again suspended and waiting for us to do something. You can have some fun at this point and poke around, but first run the "k" command, which is short for "call stack" -- it'll tell us who called recv(), who called that function, and so on:  
![](http://www.skullsecurity.org/blogdata/usbcharger-14-stack.png)

Make note of the two addresses here -- 0x100011aa and 0x10001624 -- we'll be using those later. 0x100011aa is the place where recv() was recalled, and 0x10001624 is the place where that function was called.  
And that's the end of the runtime analysis for now. We now know the call path that leads up to the recv(), and can work our way backwards to find out what kind of data it wants to receive.

At this point, feel free to play around in the debugger and see what you can learn. The first thing I usually do is tell the recv() function to return using Debug->Step Out and look at how it processes the data -- make sure you type something in the console for it to receive first.

When you're all done, restart the process so we can test later:  
![](http://www.skullsecurity.org/blogdata/usbcharger-54-restart.png)

Then run it:  
![](http://www.skullsecurity.org/blogdata/usbcharger-55-go.png)

## Disassembly -- from the top

Now that we have some starting addresses, we can move on to a disassembler and look at what the code's actually doing. Fortunately, the author made no attempt to disguise the code or pack or or anything like that, so a simple disassembler is all we need to examine the code.

If you haven't already, install [IDA](http://www.hex-rays.com/idapro/idadownfreeware.htm) somewhere. This part is safe and doesn't have to be on your sacrificial system, but you probably won't be able to do this on any system with antivirus installed. It'll delete the Trojan before you have a chance to disassemble it.

First off, fire up IDA and load the arucer.dll file (I included it in the same archive as the installer; get it [here](http://downloads.skullsecurity.org/MALWARE/EnergizerTrojan-MALWARE.zip) (password is "infected", as always be careful when handling live malware); alternatively, navigate to c:\\Windows\\System32 on the infected machine and grab it).

![](http://www.skullsecurity.org/blogdata/usbcharger-15-dll.png)

When IDA comes up, it'll ask you what you want to do. Hit "New":  
![](http://www.skullsecurity.org/blogdata/usbcharger-16-new.png)

When prompted, hit "PE Executable" and then "OK" -- in theory, you can probably pick something more appropriate but it auto-detects anyways.  
![](http://www.skullsecurity.org/blogdata/usbcharger-17-pe.png)

Then, navigate to the path where you extracted Arucer.dll and choose it (you may need to change the "Files of type" dropdown to "all files":  
![](http://www.skullsecurity.org/blogdata/usbcharger-19-arucer.dll.png)

After selecting it, you'll be prompted with a bunch of questions. Like installing software, just keep hitting 'next' until it stops asking you questions. Eventually, it'll be loaded up and you'll be presented with a screen full of assembly. Feel free to customize it how you like; I generally turn off the main menu bar and maximize the sub-windows.

The first thing I like to do when looking at malware, and it's because I was bitten by this once on a contest, is hit the "Exports" tab and see what it can do:  
![](http://www.skullsecurity.org/blogdata/usbcharger-20-exports.png)

On the Trojan, we can see there are two exports -- "DllEntryPoint", which every .dll file has, and "Arucer". If you follow DllEntryPoint, you won't get anywhere. It sets some variables, that's about it. But if you double-click on Arucer, we can see where the actual Trojan does its work:

![](http://www.skullsecurity.org/blogdata/usbcharger-21-export.png)

The first thing we see here is a call to CreateMutexA() with the name "liuhong-061220". Liu Hong, eh? The author, perhaps? Why would somebody writing an actual Trojan put his name in it? That brings back the question of whether this was intended to be a Trojan at all, or just a misguided feature?

After the mutex is created, a call to CreateThread() is made. If you double-click on StartAddress (the address that's called when the thread starts):  
![](http://www.skullsecurity.org/blogdata/usbcharger-22-startaddress.png)

You'll see a simple loop:  
![](http://www.skullsecurity.org/blogdata/usbcharger-23-startaddress2.png)

The code calls sub\_10001D80 then jumps back to the line that calls sub\_10001D80. This is an infinite loop. So double-click on sub\_10001D80 and look around. You'll see that, among other things, a call is made to listen():  
![](http://www.skullsecurity.org/blogdata/usbcharger-24-listen.png)

That tells us that we're definitely on the right track! If you keep going, you'll eventually make it to the same recv() function that we already found using the debugger.

At this point, feel free to look around a little bit, see if you can understand a little about what's going on. The biggest key is the system functions being called (like accept(), listen(), recv(), etc) -- they tell you what's going on more than anything else.

## Disassembly -- from the bottom

In the last section, we followed the code execution from the beginning of the program to the listen() and accept() calls, which lead to the recv() and send(). That's one way to skin this cat, but, since we already learned some useful addresses from the debugger, let's start at one of them: 0x100011aa. During this section, feel free to explore. I'm posting screenshots and addresses for everything I talk about, so you can always hit "g" (for "go") and catch up.

0x100011aa is the address where recv() returned. In IDA, hit "g" and type it in. You'll find yourself in the middle of a function, right after a call to recv(). Scroll up and find the top of the function (sub\_10001180), which will look like this:  
![](http://www.skullsecurity.org/blogdata/usbcharger-25-sub_10001180.png)

The first thing to note is that this function takes three arguments. The second and third were discovered by IDA to be 'buf' and 'len'. We're going to try and figure out what the first argument is. if you click on "arg\_0" in the list of local variables, you'll see that three lines into the function it's moved to 'ebx'. If you click on 'ebx', you'll see that, a little later, the value it points to is moved to eax:  
![](http://www.skullsecurity.org/blogdata/usbcharger-26-sub_10001180-ebx.png)

If you click on 'eax', you'll see that it's pushed last (and, therefore, is the first argument) to recv(), and, as the automatically generated comment tells you, that's the 's' (socket) parameter:  
![](http://www.skullsecurity.org/blogdata/usbcharger-27-sub_10001180-eax.png)

So now that we know what's going on, we can name the variables properly. Go to the top of sub\_10001180 again, click on the name, and press 'y' to define the function. Change the first argument to "int \*socket":  
![](http://www.skullsecurity.org/blogdata/usbcharger-28-sub_10001180-socket.png)

If you scroll around the function, you'll see that all it really does is recv() some data into the buffer. Therefore, it's a wrapper around recv(). Click on the function name again ("sub\_10001180") and press "n" to change the name. Type in something you'll remember, like "recv\_wrapper":  
![](http://www.skullsecurity.org/blogdata/usbcharger-29-sub_10001180-renamed.png)

One trick here is that this function does a little more than recv(). If you scroll a little past the recv() call to loc\_100011D2, you'll see a little loop:  
![](http://www.skullsecurity.org/blogdata/usbcharger-30-recv_xor.png)

This loop moves a byte from 'esi' to the 'bl' register, XORs the byte with 0xE5, then puts the byte back into 'esi'. Then it decrements ecx and loops as long as ecx is non-zero. Even without knowing what the different registers are doing here, it's pretty obvious what's going on -- every byte in the string is being XORed with 0xE5. That's a weak cipher, but it's definitely enough to keep out prying eyes.

Scrolling down a bit further, you'll find the end of the recv\_wrapper() function. Because this function is called from a lot of different places (scroll up and click on the recv\_wrapper declaration and press ctrl-x to find out where), the easiest way of finding the caller is to go back to our stacktrace from the debugger; in that stacktrace, the next address was 0x10001624.

Naturally, the first thing you'll see at 0x10001624 is, on the previous line, the call to recv\_wrapper(). But looking above it, we only see one argument -- the socket -- being passed to it. To find the other arguments, you'll have to scroll way up to 0x10001575. There you'll see the length (4) and the buffer (eax), which points at a local variable called, at the moment, "len".

So now we know that exactly 4 bytes are being received. Thinking back to my Battle.net days, that sounds like a packet header -- typically, the header will contain the length of the packet, then that many more bytes are received.

Now, if you scroll down a little more past the recv\_wrapper() call, you'll find a second recv\_wrapper() -- we can guess that it's probably downloading the rest of the packet. We're at line 0x10001659 now:  
![](http://www.skullsecurity.org/blogdata/usbcharger-34-recv_call_2_buffer.png)

The length being passed is 'eax' which, as you can see on line 0x10001639, is set to the buffer from the previous call to recv\_wrapper(). That's good -- we expected the first recv\_wrapper() call to return the length. The 'buf' argument is also set to the same buffer as the previous call, which was called length. Now that we know it isn't specifically for length but for both recv\_wrapper() buffers, we can rename it. Click on "len" and press "n" for "name", and type "buffer" or "buf":  
![](http://www.skullsecurity.org/blogdata/usbcharger-35-recv_call_2_buffer_rename.png)

All right, so now we've received a header and a body. But what happens to the body? Let's have a look:  
![](http://www.skullsecurity.org/blogdata/usbcharger-36-memicmp.png)

To explain that diagram a little: shortly after the call to recv\_wrapper(), a call is made to memicmp(). memicmp() is passed 'eax', which is the buffer from the recv\_wrapper() call; 'edx', which is a local variable, var\_828, that we'll look at shortly; and 0x27, or 39, for the length. Remember the length, it's going to be used later.

As for the var\_828, click on it and scroll wayyyy up till you see where it's set, right at the top of this function:  
![](http://www.skullsecurity.org/blogdata/usbcharger-37-var828.png)

'esi' (the source register) is set to a static string that just happens to be 38 characters long -- 39 including the string terminator (remember that string; again, it'll be used later). 'edi' (the destination register) is set to var\_828. Then 'rep movsd' is executed. 'rep movsd' basically moves data from 'esi' (source) to 'edi' (destination). In short, it copies that big long string into var\_828.

Jumping back down to the memicmp() (0x10001697), the next instruction is a jump-if-not-zero. Since memicmp() returns 0 when strings match, it'll fall through if the data matches our long string:  
![](http://www.skullsecurity.org/blogdata/usbcharger-38-cmpjmp.png)

I realize that's a lot to take in, but we're almost done. Let's summarize what we've seen so far:

- A 4-byte header -- the length -- is recv()'ed from the client
- The number of bytes given in the header are recv()'ed from the client
- The received bytes are XORed with 0xE5
- The bytes are compared to a 38-character string, "{E2AC5089-3820-43fe-8A4D-A7028FAD8C28}"
- If it matches, ...well, let's talk about that.

If you scroll a little bit past the memicmp() call, you'll see a call to sub\_100011F0 (at 0x100016C6). The only thing left after that call is a return, so that call has to be important:  
![](http://www.skullsecurity.org/blogdata/usbcharger-39-sub_100011F0.png)

This function has three arguments: 'esi', 'eax', and "3". 'esi', if you scroll up far enough, is the socket. So what are the other two?

If you look up a few lines to 0x100016AC, you'll see that eax is set to the buffer where the received data was going. a few lines down, the 'cx' register, which is set to a value at word\_1000405C, is put into 'buffer':  
![](http://www.skullsecurity.org/blogdata/usbcharger-40-cx.png)

Likewise, the third byte in "buffer" is set to 'dl', which is set to byte\_1000405E a few lines above:  
![](http://www.skullsecurity.org/blogdata/usbcharger-41-dl.png)

To figure out what these values are, double-click on one of them. You'll be brought to 0x1000405C, which should look like this:  
![](http://www.skullsecurity.org/blogdata/usbcharger-42-cx-value2.png)

If you've looked at enough hex, you'll immediately recognize these three values on ascii. Click on each of them, then select Edit->Operand type->Character (or just press "R"):  
![](http://www.skullsecurity.org/blogdata/usbcharger-43-cx-value3.png)

You'll see that these three bytes are actually, 'EY' and 'S', which, because of little endian, is actually 'YE' and 'S' -- 'YES'!  
![](http://www.skullsecurity.org/blogdata/usbcharger-44-cx-value4.png)

Hit "esc" to go back (or press "g" and type 0x1000169F) and, if you'd like, add comments saying what the values are (use ";" or shift-";" to add comments):  
![](http://www.skullsecurity.org/blogdata/usbcharger-45-values.png)

So, three bytes, "YES", are placed in "buffer" and passed to a function, along with the socket and the number "3" -- the length. It's pretty safe to assume that this function is the send\_wrapper(). Double click on it to find out!

Near the top of the send\_wrapper() function (sub\_100011F0), you'll see another little loop:  
![](http://www.skullsecurity.org/blogdata/usbcharger-47-xor.png)  
The array is being XORed with 0xE5. Next, we'll see what we're looking for:  
![](http://www.skullsecurity.org/blogdata/usbcharger-48-send.png)

send()! Now we know -- if we send a 4-byte length followed by the 38-byte string ("{E2AC5089-3820-43fe-8A4D-A7028FAD8C28}"), encoded by XORing it with 0xE5, we should receive a 3-byte response ("YES"), also encoded by XORing with 0xE5.

So, in this section we followed the flow of data from the recv() function, which we found with a debugger, to the send() function. We were fortunate that the first type we found was a simple ping -- I send it data, and it replies with "YES". It's safe, doesn't harm anything, has a static request, and a static response. Perfect!

## Building a probe

Now that we know what we need to send and receive, let's generate the actual packet, try it out, then make it into an Nmap probe! In most of this section, I assume you're running Linux, Mac, or some other operating system with a built-in compiler and useful tools. If you're on Windows, you'll probably just have to follow along until I generate the probe.

First of all, let's write a quick program to encode (or decode) the packets. I chose C because it's one of the easiest languages to write this in:  
<font face="monospace">  
<font color="#a020f0">\#include </font><font color="#ff00ff"><stdio.h></font></font>

<font color="#2e8b57">**int**</font> main(<font color="#2e8b57">**int**</font> argc, <font color="#2e8b57">**char**</font> \*argv\[\])  
{  
 <font color="#2e8b57">**int**</font> c;

 <font color="#a52a2a">**while**</font>((c = getchar()) != <font color="#ff00ff">EOF</font>)  
 printf(<font color="#ff00ff">"</font><font color="#6a5acd">%c</font><font color="#ff00ff">"</font>, c ^ <font color="#ff00ff">0xE5</font>);

 <font color="#a52a2a">**return**</font> <font color="#ff00ff">0</font>;  
}

Once you have that, compile it and run it with some test data:

```
ron@ankh:~$ vim test.c
ron@ankh:~$ gcc -o test test.c
ron@ankh:~$ echo "this is a test" | ./test | hexdump -C
00000000  91 8d 8c 96 c5 8c 96 c5  84 c5 91 80 96 91 ef     |....Å..Å.Å....ï|
0000000f
ron@ankh:~$ 
```

Looks almost right! The only issue is the 'ef' on the end -- that's a newline. We don't want newlines, so we pass "-n" to echo. We also want the ability to pass control characters, like \\x00, so we pass "-e" as well:

```
ron@ankh:~$ echo -ne "this is a test\x00" | ./test | hexdump -C
00000000  91 8d 8c 96 c5 8c 96 c5  84 c5 91 80 96 91 e5     |....Å..Å.Å....å|
0000000f
ron@ankh:~$ 
```

There we go! Now we need make a proper probe out of our string. Recall the string we found earlier:  
![](http://www.skullsecurity.org/blogdata/usbcharger-52-string.png)

As we know, it's 0x27 bytes long including the null terminator (that's what was passed to strcmpi). So, we echo the string, with the 4-byte header in front and the 1-byte terminator at the end:

```
echo -ne "\x27\x00\x00\x00{E2AC5089-3820-43fe-8A4D-A7028FAD8C28}\x00"
```

In theory, that packet should provoke a response from the Trojan. Let's try it out:

```
ron@ankh:~$ echo -ne "\x27\x00\x00\x00{E2AC5089-3820-43fe-8A4D-A7028FAD8C28}\x00" |
>  ./test | # encode it
>  ncat 192.168.1.123 7777 | # send it
>  ./test # decode the response
YES
```

Success! The Trojan talked to us, and it said "YES". Now all we have to do is create an Nmap probe!

Note that I am using an Nmap probe here rather than a script. Scripts are great if you need something with some intelligence or that can interact with the service, but in reality we're just sending a static request and getting a static response back. If somebody wants to take this a step further and write an Nmap script that interacts with this Trojan and gets some useful data from the system, that'd be good too -- it always feels better to the user when they see evidence that something's working.

Anyways, the first step to writing an Nmap probe is to find the nmap-service-probes file. It'll likely be in /usr/share/nmap or /usr/local/share/nmap or c:\\windows\\program files\\nmap. Where ever it is, open it up and scroll to the bottom. Add this probe (if it isn't already there):

```
##############################NEXT PROBE##############################
# Arucer backdoor
# http://www.kb.cert.org/vuls/id/154421
# The probe is the UUID for the 'YES' command, which is basically a ping command, encoded
# by XORing with 0xE5 (the original string is "E2AC5089-3820-43fe-8A4D-A7028FAD8C28"). The
# response is the string 'YES', encoded the same way.
Probe TCP Arucer q|\xC2\xE5\xE5\xE5\x9E\xA0\xD7\xA4\xA6\xD0\xD5\xDD\xDC\xC8\xD6\xDD\xD7\xD5\xC8\xD1\xD6\x83\x80\xC8\xDD\xA4\xD1\xA1\xC8\xA4\xD2\xD5\xD7\xDD\xA3\xA4\xA1\xDD\xA6\xD7\xDD\x98\xE5|
rarity 8
ports 7777

match arucer m|^\xbc\xa0\xb6$| p/Arucer backdoor/ o/Windows/ i/**BACKDOOR**/
```

So basically, we're sending a probe equal to the packet we just sent on port 7777. If it comes back with the encoded 'YES', then we mark it as 'Infected'. Go ahead, give it a try:

```
$ nmap -sV -p7777 192.168.1.123

Starting Nmap 5.21 ( http://nmap.org ) at 2010-03-22 21:42 CDT
Nmap scan report for 192.168.1.123
Host is up (0.00020s latency).
PORT     STATE SERVICE VERSION
7777/tcp open  arucer  Arucer backdoor (**BACKDOOR**)
Service Info: OS: Windows

Service detection performed. Please report any incorrect results at http://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 12.61 seconds
```

It successfully detected the Arucer backdoor! Woohoo!

## Conclusion

So, to wrap up, here's what we did:

- Execute the Trojan in a contained environment
- Attach a debugger to the Trojan and learn how recv() is called
- Get the callstack from the recv() call
- Disassemble the Trojan to learn how it works
- Find the addresses we saw on the callstack
- Determine how the simple crypto works (XOR with 0xE5)
- Determine what we need to XOR with 0xE5 ("{E2AC5089-3820-43fe-8A4D-A7028FAD8C28}")
- Determine what we can expect to receive ("YES" XORed with 0xE5)
- Write an Nmap probe to make it happen

Keep in mind that most malicious software isn't quite this easy. Normally there's some kind of protection against debugging, reverse engineering, virtualizing, etc. Don't think that after reading this tutorial, you can grab yourself a sample of Conficker and go to town on it. If you do, you're in for a lot of pain. :)

Anyway, I hope you learned something! Feel free to email me (my address is on the right), twitter me [@iagox86](http://www.twitter.com/iagox86), or leave a comment right here.