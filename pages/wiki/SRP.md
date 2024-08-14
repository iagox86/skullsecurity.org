---
title: 'Wiki: SRP'
author: ron
layout: wiki
permalink: "/wiki/SRP"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/SRP"
---

The Battle.net SRP is a variation the standard [SRP](http://srp.stanford.edu/ndss.html) protocol, with a few minor changes. There are several important packets I\'ll go over, and then I\'ll discuss each variable and how we come up with it, including a sample implementation in Java. As far as I know, me, Maddox, and TheMinistered are the first (and only) to reverse this publicly, so enjoy!

## Packets

### SID_AUTH_ACCOUNTCREATE (C -\> S) {#sid_auth_accountcreate_c___s}

-   (byte\[32\]) [s](#s "wikilink")
-   (byte\[32\]) [v](#v "wikilink")
-   (byte\[32\]) Username

### SID_AUTH_ACCOUNTLOGON (C -\> S) {#sid_auth_accountlogon_c___s}

-   (byte\[32\]) [A](#A "wikilink")
-   (ntstring) [C](#C "wikilink")

### SID_AUTH_ACCOUNTLOGON (C \<- S) {#sid_auth_accountlogon_c___s_1}

-   (dword) status
-   (byte\[32\]) [s](#s "wikilink")
-   (byte\[32\]) [B](#B "wikilink")

### SID_AUTH_ACCOUNTLOGONPROOF (C -\> S) {#sid_auth_accountlogonproof_c___s}

-   (byte\[20\]) [M1](#M1 "wikilink")

### SID_AUTH_ACCOUNTLOGONPROOF (C \<- S) {#sid_auth_accountlogonproof_c___s_1}

-   (byte\[20\]) [M2](#M2 "wikilink")

### SID_AUTH_ACCOUNTCHANGE (C -\> S) {#sid_auth_accountchange_c___s}

-   (byte\[32\]) [A](#A "wikilink") (for old password)

### SID_AUTH_ACCOUNTCHANGE (C \<- S) {#sid_auth_accountchange_c___s_1}

-   (byte\[32\]) [s](#s "wikilink") (for old password)
-   (byte\[32\]) [B](#B "wikilink") (for old password)

### SID_AUTH_ACCOUNTCHANGEPROOF (C -\> S) {#sid_auth_accountchangeproof_c___s}

-   (byte\[20\]) [M1](#M1 "wikilink") (for old password)
-   (byte\[32\]) [s](#s "wikilink") (for new password)
-   (byte\[32\]) [v](#v "wikilink") (for new password)

### SID_AUTH_ACCOUNTCHANGEPROOF (C \<- S) {#sid_auth_accountchangeproof_c___s_1}

-   (byte\[20\]) [M2](#M2 "wikilink") (for old password)

### SID_AUTH_ACCOUNTUPGRADE (C -\> S) {#sid_auth_accountupgrade_c___s}

-   \[blank\]

### SID_AUTH_ACCOUNTUPGRADE (S -\> C) {#sid_auth_accountupgrade_s___c}

-   (dword) status
-   (dword) server token

### SID_AUTH_ACCOUNTUPGRADEPROOF (C -\> S) {#sid_auth_accountupgradeproof_c___s}

-   (dword) client token
-   (byte\[20\]) BrokenSHA1 (for old password)
-   (byte\[32\]) [s](#s "wikilink")
-   (byte\[32\]) [v](#v "wikilink")

### SID_AUTH_ACCOUNTCHANGEPROOF (S -\> C) {#sid_auth_accountchangeproof_s___c}

-   (dword) status
-   (byte\[20\]) [M2](#M2 "wikilink")

## Functions

### H()

Standard SHA-1

### %

Modulo Division

### \* {#section_1}

Multiplication

### - {#section_2}

Subtraction

### + {#section_3}

Addition

## Variables

### C

Your username in upper case

### P

Your password in upper case

### N

N IS THE \"modulus\". It is a large 32-byte unsigned integer, and all calculations are done modulus N. That means no value in SRP will ever go over N. Its value is:\
Decimal: 112624315653284427036559548610503669920632123929604336254260115573677366691719\
Hex: 0xF8FF1A8B619918032186B68CA092B5557E976C78C73212D91216F6658523C787\

### g

g is the \"generator\" variable. It is used to generate public keys, based on private keys. The value is \"47\" in decimal, or 0x2F in hex.\

### I

I is not in the original SRP. I actually invented it to optimize Battle.net SRP, since it was being calculated. The way to calculate it, if you need to, is H(g) xor H(N). What this means is that you calculate the SHA-1 values of both g and N, then xor each byte of them together. The value you come out with is:\
Decimal: 1415864289515498529999010855430909456942718455404\
Hex: F8018CF0A425BA8BEB8958B1AB6BF90AED970E6C\

### a

a is a sessional private key. It is a random integer lower than N, and is regenerated for each log in.

### B

B is the server\'s temporary public key, derived from b (which I won\'t bother showing here). It is sent to the client in SID_AUTH_ACCOUNTLOGON.

### s

s is the \"salt\" value. You choose it randomly when you create your account, and then it never changes. Every time you log into Battle.net, it\'s sent back to you (in SID_AUTH_ACCOUNTLOGON), and is used to help scramble the password.

### x

x is a private key that is derived from [s](#s "wikilink"), [C](#C "wikilink"), [P](#P "wikilink"). Note that in standard SRP, it\'s only derived from the [s](#s "wikilink") and [P](#P "wikilink"). The formula is:\
x = H(s, H(C, \":\", P));\
Which means that you hash the salt along with the hash of the username, a colon, and the password. Here is a sample implementation of it:

            MessageDigest mdx = getSHA1();
            mdx.update(username.getBytes());
            mdx.update(":".getBytes());
            mdx.update(password.getBytes());
            byte []hash = mdx.digest();

            mdx = getSHA1();
            mdx.update(salt);
            mdx.update(hash);
            hash = mdx.digest();

### v

v is the \"Password Verifier\". It is basically a private key, which is derived from [g](#g "wikilink"), [x](#x "wikilink"), and is modulo [N](#N "wikilink"):\
v = g^x^ % N\
A sample implementation of this might be:

            g.modPow(x, N);

### A {#a_1}

A is a public key that exists only for a single login session. It is derived from [g](#g "wikilink"), [a](#a "wikilink"), and of course is modulo [N](#N "wikilink"):\
A = g^a^ % N\
A sample implementation for this might be:

        g.modPow(a, N);

### u

u is used to help \"scramble\" the private key. In regular SRP, it\'s generated by the server and sent to the client along with [B](#B "wikilink"). However, in Battle.net SRP, it is actually equal to the first 4 bytes of H([B](#B "wikilink")). Here is a sample implementation, which is, in Java, pretty yucky:

            byte []hash = getSHA1().digest(B); // Get the SHA-1 digest of B
            byte []u = new byte[4]; // Allocate 4 bytes for U
            u[0] = hash[3];
            u[1] = hash[2];
            u[2] = hash[1];
            u[3] = hash[0];

### S {#s_1}

S is where a lot of the magic happens. It is generated by both the client and the server, using different values and a different formula, and it ends up as the same value. On the client, it\'s derived from [B](#B "wikilink"), [v](#v "wikilink"), [a](#a "wikilink"), [u](#u "wikilink"), [x](#x "wikilink"), and is, of course, modulo [N](#N "wikilink"). On the server side, it\'s derived from [A](#A "wikilink"), [v](#v "wikilink"), [u](#u "wikilink"), and [B](#B "wikilink"). The respective formulas are:\
(client) S = ((N + B - v) % N)^(a\ +\ ux)^ % N\
(server) S = (A \* (v^u^ % N))^b^ % N\
If you really enjoy math, you can go ahead and figure out how these work out to the same value. It\'s actually a pretty interesting equation. Here is my Java implementation:

            
            S_base = N.add(B).subtract(v).mod(N);
            S_exp = a.add(get_u(B).multiply(x));
            S = S_base.modPow(S_exp, N);

### K

K is a value that is based on [S](#S "wikilink"), and is generated by both the client and the server as proof that they actually know the value of [S](#S "wikilink"). In standard SRP, it\'s just H(S); however, in Battle.net SRP, it\'s fairly complicated:\

-   2 buffers are created; one is the even bytes of S, and the other is the odd bytes of S.
-   Each buffer is hashed with SHA-1.
-   The even bytes of K are the even bytes of S, and the odd bytes of K are the odd bytes of S.

Here is my Java implementation:

            byte []K = new byte[40]; // Create the buffer for K
            byte []hbuf1 = new byte[16]; // Create the 2 buffers to each hold half of S
            byte []hbuf2 = new byte[16];
            
            for(int i = 0; i &lt; hbuf1.length; i++) // Loop through S
            {
                hbuf1[i] = S[i * 2];
                hbuf2[i] = S[(i * 2) + 1];
            }

            byte []hout1 = getSHA1().digest(hbuf1); // Hash the values
            byte []hout2 = getSHA1().digest(hbuf2);

            for(int i = 0; i &lt; hout1.length; i++)
            {
                K[i * 2] = hout1[i]; // Put them into K
                K[(i * 2) + 1] = hout2[i];
            }

Pretty stupid, if you ask me, but that\'s life.

### M1

M1 (or M\[1\] is the proof that you actually know your own password. In standard SRP, it\'s derived from [A](#A "wikilink"), [B](#B "wikilink"), and [K](#K "wikilink"). Of course, that\'s too simple for Blizzard, so Battle.net SRP is derived from [I](#I "wikilink"), H([C](#C "wikilink")), [s](#s "wikilink"), [A](#A "wikilink"), [B](#B "wikilink"), and [K](#K "wikilink"). Since [I](#I "wikilink") is constant, and [C](#C "wikilink") and [s](#s "wikilink") are sent across the network, I\'m pretty sure that the change adds no security, but as long as it makes them feel better. The formula is actually very simple, at least:\
M1 = H(I, H(C), s, A, B, K)\
My Java implementation looks like this:

            MessageDigest totalCtx = getSHA1();
            totalCtx.update(I);
            totalCtx.update(getSHA1().digest(username.getBytes()));
            totalCtx.update(s);
            totalCtx.update(A);
            totalCtx.update(B);
            totalCtx.update(K);
            
            M1 = totalCtx.digest();

### M2

M2 (or M\[2\]) is the proof that the server actually knows your password. It is derived by hashing the values of [A](#A "wikilink"), [M1](#M1 "wikilink"), and [K](#K "wikilink"). When the server sends it back, you should verify it to make sure that the server actually knows your password (if it doesn\'t, then there\'s likely an attack going on). The formula is:\
M2 = H(A, M1, K)\
My Java implementation looks like this:

            MessageDigest shaM2 = getSHA1();
            shaM2.update(A);
            shaM2.update(M);
            shaM2.update(K);
            
            M2 = shaM2.digest();

## Conclusion

I\'ve went over all the packets that I use in SRP, so there should be more than enough there to get you going. Good luck!

\-[Ron](mailto:ron@skullsecurity.org)

## Credits

I have to thank the following people:\
\* Maddox, SneakCharm \-- Reverse engineering the code with me\
\* Arta \-- For convincing me to figure out what it did, and get it on BNetDocs\
\* Cloaked - For actually reading it and pointing out mistakes :)\

## Legal stuff {#legal_stuff}

All information on this page is public domain. If for any reason you want to copy/use this, feel free and have fun. All software and source directly distributed by me is public domain, and may be used in any way. Any copyrights I use (Particularely Starcraft, Brood War, Diablo, Warcraft, and Blizzard) are copyrights of their respective owners (in this case, Blizzard). Please respect all copyrights, and enjoy any public domain source code and software.
