---
id: 1631
title: 'Determine Windows version from offline image'
date: '2013-10-14T12:53:52-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/465-revision-v1'
permalink: '/?p=1631'
---

I am not a forensics expert, nor do I play one on TV. I do, however, play one at work from time to time and I own some of the key tools: a magnifying glass and a 10baseT hub. Oh, and a Sherlock Holmes hat -- that's the key. Unfortunately, these weren't much help when I was handed a pile of drives and was asked to find out which version of Windows they had been running. I wasn't allowed to boot them, and I couldn't really find the full answer of how to get the version after a lot of googling, so I figured it out the hard way. Hopefully I can save you guys some time by explaining it in detail.

And if there's a better way, which I'm sure there is, please let me know. I don't doubt that I did this the hard way -- that's kinda my thing.

The order of events is, basically:

- Step 1: Copy the system's registry hive to your analysis system
- Step 2: Mount the registry hive in regedit.exe
- Step 3: Navigate to the OS version in regedit.exe
- Step 4: Unmount the registry hive.

If you know how to do all that, then thanks for reading! Check back Tuesday for a brand new blog posting! I have an interesting blog that combines DNS and cross-site scripting lined up.

Otherwise, keep reading. Or just look at the pictures.

## Step 1: Get the registry hive

This step is pretty simple. The file is called **software** and is located in **%SYSTEMROOT%\\system32\\config**. You're going to have problems if you try grabbing this file from a running system, but fortunately we have an offline version of the harddrive. Copy that file to a USB stick, or some other device, following your standard evidence collection policies. I also recommend working from an image, not the live drive, if you're doing actual forensic work.

![](/blogdata/offline-os-1.png)

## Step 2: Import the hive

First, run regedit on the analysis machine (that you copied the **software** file to):  
![](/blogdata/offline-os-2.png)

Next, click on the HKEY\_LOCAL\_MACHINE hive (or any other, really):  
![](/blogdata/offline-os-3.png)

Next, under the File menu, click "Load Hive...":  
![](/blogdata/offline-os-4.png)

Navigate to the 'software' file that you copied from the target machine:  
![](/blogdata/offline-os-5.png)

When prompted, type in a name - it doesn't matter what:  
![](/blogdata/offline-os-6.png)

And that's it! Now you'll have the registry mounted as the name you gave it under HKEY\_LOCAL\_MACHINE:  
![](/blogdata/offline-os-7.png)

## Step 3: Find the key

The key is located in **HKEY\_LOCAL\_MACHINE/<thenameyoupicked>/Microsoft/Windows NT/CurrentVersion**:  
![](/blogdata/offline-os-8.png)

Any key you want related to the version of Windows is right there. In my screenshot, we're running Windows XP Service Pack 2. The Owner and Company given during installation is shown there too, if you're into that.

## Step 4: Unmount

If you don't unmount the device, you'll get file-in-use errors until you do. So, click on the hive and under the File menu, select "Unload Hive...":  
![](/blogdata/offline-os-9.png)

## Done!

That's it! Once you learn how to mount the registry from the offline machine, it's actually pretty easy.

If you know of a better way to do it, let me know! Comments and registration should once again work, assuming you an do simple math, or you can find my email address at the right somewhere.

Thanks for reading!