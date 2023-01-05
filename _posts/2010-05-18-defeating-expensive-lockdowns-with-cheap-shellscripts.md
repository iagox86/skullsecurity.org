---
id: 820
title: Defeating expensive lockdowns with cheap shellscripts
date: '2010-05-18T10:43:33-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=820
permalink: "/2010/defeating-expensive-lockdowns-with-cheap-shellscripts"
categories:
- hacking
comments_id: '109638352111636433'

---

Recently, I was given the opportunity to work with an embedded Linux OS that was locked down to prevent unauthorized access. I was able to obtain a shell fairly quickly, but then I ran into a number of security mechanisms. Fortunately, I found creative ways to overcome each of them. 

Here's the list of the biggest problems I encountered, in the order that I overcame them:
<ul>
 <li>The user account couldn't 'ls' most folders due to lack of privileges</li>
 <li>Process management tools (like ps) didn't work (thanks to the missing 'ls')</li>
 <li>The user account could only write to designated areas, in spite of file permissions</li>
 <li>Architecture was PowerPC, which I have no experience with</li>
 <li>netstat, ifconfig, arp, and other tools were disabled</li>
</ul>
<!--more-->
I can't talk about how I actually obtained a shell, unfortunately, because the nature of the device would be too obvious. But I will say this: despite all their lockdowns, they accidentally left netcat installed. Oops :)

If you've been in similar situations and found some other tricks, I'd like to hear about them!



<h2>Implementing ls</h2>
Unfortunately, I was only able to obtain user access, not root. Despite permissions to the contrary, I couldn't run 'ls' against any system folders:
<pre>$ cd /
$ ls
/bin/ls: cannot open directory .: Permission denied
$ cd /bin
$ ls
/bin/ls: cannot open directory .: Permission denied
$ find /
/
$ find .
.</pre>

And so on. I could, however, run ls on /home/user, /tmp, and subfolders thereof. 

As a side effect, I couldn't run the 'ps' command because it didn't have permission to read /proc:
<pre>$ ps
Error: can not access /proc.</pre>

But I'll get to that later. 

After struggling a little, I was happy to discover that the 'which' command was enabled! 
<pre>$ which ls
/usr/bin/ls
$ which ps
/usr/bin/ps</pre>


Great luck! I wrote a script on my personal laptop that would find every executable:
<pre>
# find / -perm /0111 -type f |       # Find all executable files
  grep -v '^/home'           |       # Remove files stored on /home
  grep -v '\.so$'            |       # Remove libraries
  grep -v '\.a$'             |       # Remove libraries
  grep -v '\.so\.'           |       # Remove libraries
  sed 's|^.*/||'                     # Remove the path
</pre>
  
And redirected the output from this script to a file. Then, I uploaded the file to the device using netcat and, after adding the sbin folders to the $PATH, I ran the following command:
<pre>$ export PATH=/sbin:/usr/sbin:/usr/local/sbin:$PATH
$ cat my-programs.txt | xargs which | sort | uniq > installed-programs.txt</pre>

Which returned a list that looked like:
<pre>$ head installed-programs.txt
bin/arch
/bin/bzip2recover
/bin/cpio
/bin/dmesg
/bin/fusermount
/bin/hostname
/bin/ipmask
/bin/kill
/bin/killall
/bin/login
</pre>

And finally, if you want more information:
<pre>$ cat installed-programs.txt | xargs ls -l > installed-programs-full.txt</pre>

Which, of course, gives you this type of output:
<pre>$ head installed-programs-full
-rwxr-xr-x 1 root   root        2896 2008-03-31 16:56 /bin/arch
-rwxr-xr-x 1 root   root        7696 2008-04-07 00:42 /bin/bzip2recover
-rwxr-xr-x 1 root   root       52800 2007-04-07 12:04 /bin/cpio
-rwxr-xr-x 1 root   root        4504 2008-03-31 16:56 /bin/dmesg
-rwsr-xr-x 1 root   root       19836 2008-03-07 19:52 /bin/fusermount
-rwxr-xr-x 1 root   root        9148 2008-03-31 23:10 /bin/hostname
-rwxr-xr-x 1 root   root        3580 2008-03-31 23:10 /bin/ipmask
-rwxr-xr-x 1 root   root        8480 2008-03-31 16:56 /bin/kill
-rwxr-xr-x 1 root   root       14424 2006-12-19 18:07 /bin/killall
-rwxr-xr-x 1 root   root       44692 2008-03-24 15:11 /bin/login
</pre>

Success! Now I have a pretty good idea of which programs are installed. I could collect samples from a wider variety of machines than just my laptop, potentially turning up more interesting applications, but I found that just the output from a single Linux system was actually a good enough sample to work with. 

Remember, with the full 'ls -l' output, keep your eye out for 's' in the permissions. ;)




<h2>Implementing ps</h2>
As I mentioned earlier, the ps command fails spectacularly when you can't ls folders:
<pre>$ ps
Error: can not access /proc.</pre>

The first thing I tried was an experimental 'cat', which worked nicely:
<pre>$ cat /proc/1/status
Name:   init
State:  S (sleeping)
[...]
</pre>

Which tells me that the /proc filesystem is there, and that I have access to their accounting information. The only reason I can't list them is because 'ls /proc' (or the equivalent thereof) is failing. An investigation also told me that /proc/cpuinfo and /proc/meminfo also exist, which were helpful. So, I threw together a quick script to bruteforce the list:

<pre>for i in `seq 1 100000`; do    # Take the first 100,000 PIDs 
                               #(experimentally determined)
  if [ -f /proc/$i/status ]; then   # Check if the status file exists
    CMDLINE=`cat /proc/$i/cmdline | # Read the commandline
              sed 's/|//g' |        # Remove any pipes (will break things)
              sed "s/\x00/ /g"`;    # Replace null with space
    cat /proc/$i/status |           # Get the process details
      grep 'Name:'      |           # We only want the name
      cut -b7-          |           # Remove the prefix "Name:  "
      sed "s|$| ($CMDLINE)|";       # Add the commandline to the end
  fi; 
done
</pre>

The output for this will look like:
<pre>init (init [3]        )
kthreadd ()
[...]
udevd (/sbin/udevd --daemon )
syslogd (/usr/sbin/syslogd )
klogd (/usr/sbin/klogd -c 3 -x )
</pre>

So now I have a pretty good list of the running processes. Win!

Another option would be to write a patch for <a href='http://procps.sourceforge.net/'>procps</a> that implements a bruteforce listing, but that was beyond what I really wanted to do. 


<h2>Writing to protected areas</h2>
This one, I want to be careful with. The reason is, I don't understand what was happening, or why. 

In any case, in spite of permissions, I couldn't write to most folders, including /home/user. How they locked it down, I don't know, but I can't touch, cat, grep, etc them. 

After some poking, though, I discovered that I could rm files and read/write them using redirection. So, oddly, it would look like this:
<pre>$ touch test
touch: cannot touch `test': Permission denied
$ echo "TEST DATA" > test
$ cat test
cat: test: Permission denied
$ cat < test
TEST DATA
$ mv test test2
mv: cannot move `test' to `test2': Permission denied
$ cat < test > test2
$ rm test
</pre>

That's all I can really say about that one. This bug let me write to some sensitive folders and modify settings I shouldn't have been able to. 



<h2>PowerPC</h2>
The architecture of this device turned out to be PowerPC, which presented an interesting challenge. I've never done any cross compilation before, and I didn't even know where to start. So, I was going to skip it altogether. 

Then, this past weekend, my <a href='http://www.twitter.com/bkulyk'>friend</a> brought over a device called <a href='http://www.wdc.com/en/products/index.asp?cat=30'>WD HD Live</a>. After installing Linux on it, I discovered that, like our old friend WRT54g, it had a MIPS core. So I took a couple hours out and learned how to cross compile for MIPS. 

By Monday, I knew <s>everything</s> one or two things about cross compiliation, and was ready to get started! I downloaded <a href='http://www.kegel.com/crosstool/>Crosstool 0.43</a> and ran the following command:
<pre>demo-powerpc-860.sh</pre>

It automatically downloaded and installed the full toolchain and built a hello world program. I copied hello world to the device, using netcat, and verified that it worked. It did! 

Next step was to compile something useful. So, I downloaded the source for <a href='http://packages.debian.org/squeeze/netcat-traditional'>Hobbit's Netcat</a> from Debian and compiled it with the crosstool commands (note: I have *no* idea whether or not this is the right way to cross compile; all I know is, it worked :) ):
<pre>$ export PATH=/opt/crosstool/gcc-4.1.0-glibc-2.3.6/powerpc-860-linux-gnu/powerpc-860-linux-gnu/bin:$PATH
$ wget http://ftp.de.debian.org/debian/pool/main/n/netcat/netcat_1.10.orig.tar.gz
$ wget http://ftp.de.debian.org/debian/pool/main/n/netcat/netcat_1.10-38.diff.gz
$ tar -xvvzf netcat_1.10.orig.tar.gz
$ gunzip -v netcat_1.10-38.diff.gz
$ patch -p0 < netcat_1.10-38.diff
$ patch -p0 < netcat-1.10.orig/debian/patches/glibc-resolv-h.patch
$ cd netcat-1.10.orig
$ make linux CC=gcc</pre>

I successfully copied the new netcat to the device and ran it, to prove that the cross compile worked. 

Obviously, using netcat to copy netcat to the device makes very little sense. But the point was to prove that cross compilation works, not that I could do something interesting with it. 



<h2>No networking tools</h2>
Finally, I was dismayed to find out that netstat, ifconfig, arp, and others all returned a "Permission denied" error when I tried to run them. How am I supposed to figure out the system state without them?

Fortunately, none of them require setuid to run, so I downloaded the latest <a href='http://www.tazenda.demon.co.uk/phil/net-tools/'>net-tools</a> package, compiled it with the PowerPC toolchain, uploaded them with netcat, and tried them out:


<pre>$ ./netstat-ron -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
tcp        0      0 192.168.155.11:39002    192.168.155.105:3306     TIME_WAIT
tcp        0      0 192.168.155.11:41992    192.168.155.105:3306     ESTABLISHED
tcp        0      0 192.168.155.11:37288    192.168.155.105:3306     ESTABLISHED
tcp        0      0 192.168.155.11:38736    192.168.155.105:3306     ESTABLISHED
tcp        0      0 192.168.155.11:38652    192.168.155.105:3306     ESTABLISHED
</pre>
<pre>$ ./ifconfig-ron lo
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:1285090 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1285090 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:130762797 (124.7 MiB)  TX bytes:130762797 (124.7 MiB)
</pre>

<pre>$ ./arp-ron
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.155.1            ether   00:0C:29:7E:21:63   C                     eth0
192.168.155.105          ether   00:50:56:C0:00:00   C                     eth0
192.168.155.144          ether   00:0C:29:42:B7:1B   C                     eth0
</pre>

Done!



<h2>Conclusion</h2>
So, I managed to overcome the lockdown on the embedded device. Once I had shell I could do pretty anything I could normally do, in spite of the attempted lockdown. Therefore, I concluded that, in its current state, the lockdown was nearly useless. 

I plan to work with the vendor, of course, to help them resolve these issues. 

Now, your turn! Have you ever had to use makeshift tools on a locked down system? Any interesting stories?
