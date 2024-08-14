---
title: 'Wiki: Mac OS X Commands'
author: ron
layout: wiki
permalink: "/wiki/Mac_OS_X_Commands"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Mac_OS_X_Commands"
---

## Passwords

### Obtaining the hashes {#obtaining_the_hashes}

#### OS X 10.0 (Cheetah) {#os_x_10.0_cheetah}

The same as in 10.2 (Jaguar). See below.

#### OS X 10.1 (Puma) {#os_x_10.1_puma}

The same as in 10.2 (Jaguar). See below.

#### OS X 10.2 (Jaguar) {#os_x_10.2_jaguar}

Dump the hash

    nidump passwd . | grep username | cut -d':' -f2

This hash is created using the [Unix DES Crypt(3)](http://en.wikipedia.org/wiki/Crypt_(Unix)) function, where the password is first truncated to 8 characters.

#### OS X 10.3 (Panther) {#os_x_10.3_panther}

First find out a users\' GUID:

    niutil -readprop . /users/username generateduid

Next take that GUID and dump the hash file

    cat /var/db/shadow/hash/GUID

The first 64 characters are the NTLM hash (first 32 NT, next 32 LM) and the last 40 characters are the SHA1 hash.

#### OS X 10.4 (Tiger) {#os_x_10.4_tiger}

You can obtain the GUID just as in 10.3 (Panther). See above.

After obtaining the GUID, you can dump the passwords just as in 10.5 (Leopard). See below.

#### OS X 10.5 (Leopard) {#os_x_10.5_leopard}

First find a users\' GUID:

    dscl localhost -read /Search/Users/username | grep GeneratedUID | cut -c15-

After getting the GUID you can dump various hashes. By default the only hash stored is the salted SHA1. If the user has turned on SMB file sharing then the NTLM hash will also be stored. If you upgraded from 10.3-\>10.4-\>10.5 then the zero salted SHA1 is also stored.

Salted SHA1 (first 8 characters are the salt)

    cat /var/db/shadow/hash/GUID | cut -c105-152

Zero-Salted SHA1 (first 8 characters are the salt and will always be all zeros)

    cat /var/db/shadow/hash/GUID | cut -c169-216

NTLM (first 32 characters are NT, next 32 are LM)

    cat /var/db/shadow/hash/GUID | cut -c-64
