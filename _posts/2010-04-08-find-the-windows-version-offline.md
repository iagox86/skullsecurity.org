---
id: 465
title: Determine Windows version from offline image
date: '2010-04-08T09:08:03-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=465
permalink: "/2010/find-the-windows-version-offline"
categories:
- forensics
comments_id: '109638350491208936'

---

I am not a forensics expert, nor do I play one on TV. I do, however, play one at work from time to time and I own some of the key tools: a magnifying glass and a 10baseT hub. Oh, and a Sherlock Holmes hat -- that's the key. Unfortunately, these weren't much help when I was handed a pile of drives and was asked to find out which version of Windows they had been running. I wasn't allowed to boot them, and I couldn't really find the full answer of how to get the version after a lot of googling, so I figured it out the hard way. Hopefully I can save you guys some time by explaining it in detail. 

And if there's a better way, which I'm sure there is, please let me know. I don't doubt that I did this the hard way -- that's kinda my thing. 

The order of events is, basically:
<ul>
<li>Step 1: Copy the system's registry hive to your analysis system</li>
<li>Step 2: Mount the registry hive in regedit.exe</li>
<li>Step 3: Navigate to the OS version in regedit.exe</li>
<li>Step 4: Unmount the registry hive.</li>
</ul>

If you know how to do all that, then thanks for reading! Check back Tuesday for a brand new blog posting! I have an interesting blog that combines DNS and cross-site scripting lined up. 

Otherwise, keep reading. Or just look at the pictures. 
<!--more-->
<h2>Step 1: Get the registry hive</h2>
This step is pretty simple. The file is called <strong>software</strong> and is located in <strong>%SYSTEMROOT%\system32\config</strong>. You're going to have problems if you try grabbing this file from a running system, but fortunately we have an offline version of the harddrive. Copy that file to a USB stick, or some other device, following your standard evidence collection policies. I also recommend working from an image, not the live drive, if you're doing actual forensic work. 

<img src='/blogdata/offline-os-1.png'>

<h2>Step 2: Import the hive</h2>
First, run regedit on the analysis machine (that you copied the <strong>software</strong> file to):
<img src='/blogdata/offline-os-2.png'>

Next, click on the HKEY_LOCAL_MACHINE hive (or any other, really):
<img src='/blogdata/offline-os-3.png'>

Next, under the File menu, click "Load Hive...":
<img src='/blogdata/offline-os-4.png'>

Navigate to the 'software' file that you copied from the target machine:
<img src='/blogdata/offline-os-5.png'>

When prompted, type in a name - it doesn't matter what:
<img src='/blogdata/offline-os-6.png'>

And that's it! Now you'll have the registry mounted as the name you gave it under HKEY_LOCAL_MACHINE:
<img src='/blogdata/offline-os-7.png'>

<h2>Step 3: Find the key</h2>
The key is located in <strong>HKEY_LOCAL_MACHINE/&lt;thenameyoupicked&gt;/Microsoft/Windows NT/CurrentVersion</strong>:
<img src='/blogdata/offline-os-8.png'>

Any key you want related to the version of Windows is right there. In my screenshot, we're running Windows XP Service Pack 2. The Owner and Company given during installation is shown there too, if you're into that. 

<h2>Step 4: Unmount</h2>
If you don't unmount the device, you'll get file-in-use errors until you do. So, click on the hive and under the File menu, select "Unload Hive...":
<img src='/blogdata/offline-os-9.png'>

<h2>Done!</h2>
That's it! Once you learn how to mount the registry from the offline machine, it's actually pretty easy. 

If you know of a better way to do it, let me know! Comments and registration should once again work, assuming you an do simple math, or you can find my email address at the right somewhere. 

Thanks for reading! 
