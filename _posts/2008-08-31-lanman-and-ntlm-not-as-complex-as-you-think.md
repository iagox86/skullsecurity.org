---
id: 34
title: 'LANMAN and NTLM: Not as complex as you think!'
date: '2008-08-31T20:46:08-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=34'
permalink: /2008/lanman-and-ntlm-not-as-complex-as-you-think
categories:
    - NetBIOS/SMB
---

As I'm sure you've noticed with my first two posts, my NetBIOS/SMB project is taking up most of my time. I hit a bump this weekend, and almost got to the point where the only valid answer was throwing things; luckily, however, I figured it out. I did make a new enemy, though: signed data types! The devil's datatype. 
<!--more-->
But sour grapes (and, naturally, joking) aside, I just finished implementing the two older (and, by far, most common) Windows authentication hashes: LANMAN and NTLM. I'm also planning on implementing NTLMv2 in the near future, so stay tuned for that. LANMAN and NTLM are used by default on Windows, though, so you're far more likely to see them. 

In the past, I've always feared LANMAN and NTLM, thinking that there was something inherently complex and tricky about them. However, once I got around to implementing them, I realized that they're dead simple! Nothing to it! They're so simple, in fact, that they're the perfect topic for a blog post. 

The code I'm presenting here is straight from my nbtool code. The particular SVN revision is 169, but the code should basically be static now. <a href='http://svn.skullsecurity.org:81/ron/security/nbtool/crypto.c'>Here is the code you need</a> (along with the <a href='http://svn.skullsecurity.org:81/ron/security/nbtool/crypto.h'>header file</a> and <a href='http://svn.skullsecurity.org:81/ron/security/nbtool/types.h'>types.h</a>). Compile them with -DTEST and -lssl/-lcrypto, and you're set! 

<h3>Quick intro</h3>
If you're reading this, you should have some idea what LANMAN and NTLM are, and some knowledge of NetBIOS/SMB are helpful as well. But, in case you don't, here's a quick summary:
<ul>
<li>LANMAN: The original way Windows stored passwords</li>
<li>NTLM: A slightly more modern way that Windows stores passwords</li>
<li>NetBIOS/SMB: The protocol used by Windows for filesharing, RPC, and lots more</li>
</ul>

For more info, consult Wikipedia, etc. 

<h3>LANMAN hash</h3>
The first thing I'll go over is how to create a LANMAN hash. Many of you probably know it as the easiest hash in history to crack. That'd be the one! In short, here's how to generate it:
<ul>
<li>Convert password to uppercase.</li>
<li>Make the password exactly 14 characters, either by truncating or padding with NULL bytes ('\0').</li>
<li>Split into two 7-character (56-bit) passwords</li>
<li>Convert each of those passwords into a 64-bit DES key, by adding a parity bit to the end of each byte (I'll have some code later)</li>
<li>Encrypt the string "KGS!@#$%" with each of the two keys, generating two 8-byte encrypted strings</li>
<li>Concatenate those two strings to form a 16-byte string</li>
</ul>
That 16-byte string is the LANMAN hash that's stored in the SAM file (among other places). 

Here is the code for converting the 56-bit string into the 64-bit key:
<pre>static void password_to_key(const uint8_t password[7], uint8_t key[8])
{
    /* make room for parity bits */
    key[0] =                        (password[0] >> 0);
    key[1] = ((password[0]) << 7) | (password[1] >> 1);
    key[2] = ((password[1]) << 6) | (password[2] >> 2);
    key[3] = ((password[2]) << 5) | (password[3] >> 3);
    key[4] = ((password[3]) << 4) | (password[4] >> 4);
    key[5] = ((password[4]) << 3) | (password[5] >> 5);
    key[6] = ((password[5]) << 2) | (password[6] >> 6);
    key[7] = ((password[6]) << 1);
}
</pre>
Note: the password HAS to be unsigned for this to work! Trust me! If you used signed data types, it'll work fine until you try hashing binary data, then it won't work and you'll want to throw things. 

After that, the rest is easy:
<pre>void lm_create_hash(const char *password, uint8_t result[16])
{   
    size_t           i;
    uint8_t          password1[7];
    uint8_t          password2[7];
    uint8_t          kgs[] = "KGS!@#$%";
    uint8_t          hash1[8];
    uint8_t          hash2[8];

    /* Initialize passwords to NULLs. */
    memset(password1, 0, 7);  
    memset(password2, 0, 7);

    /* Copy passwords over, convert to uppercase, they're automatically padded with NULLs. */
    for(i = 0; i < 7; i++)
    {
        if(i < strlen(password))
            password1[i] = toupper(password[i]);
        if(i + 7 < strlen(password))
            password2[i] = toupper(password[i + 7]);
    }

    /* Do the encryption. */
    des(password1, kgs, hash1);
    des(password2, kgs, hash2);

    /* Copy the result to the return parameter. */
    memcpy(result + 0, hash1, 8);
    memcpy(result + 8, hash2, 8);
}
</pre>

And here's the DES function, which uses OpenSSL functions (don't worry if this is confusing, it was also confusing to me, at first):
<pre>static void des(const uint8_t password[7], const uint8_t data[8], uint8_t result[])
{   
    DES_cblock key;
    DES_key_schedule schedule;

    password_to_key(password, key);

    DES_set_odd_parity(&key);
    DES_set_key_unchecked(&key, &schedule);
    DES_ecb_encrypt((DES_cblock*)data, (DES_cblock*)result, &schedule, DES_ENCRYPT);
}  </pre>

That's all there is to it! 

<h3>NTLM hash</h3>
The NTLM hash is the other hash value that's stored in the SAM file. It's used for authentication in addition to LANMAN. Although it isn't stored in an easily crackable format, it does have one fatal flaw: it is almost always sent (and stored) alongside the LANMAN hash, for backwards compatibility, making any added security completely irrelevant. 

Generating the NTLM hash is far easier than a LANMAN hash. It is simply an MD4() of the password (in Unicode). Here is the code (note that I'm doing the Unicode in an incredibly inefficient way, but for the purposes of short code, it's the quickest way to demonstrate):
<pre>void ntlm_create_hash(const char *password, uint8_t result[16])
{
    size_t i;
    MD4_CTX ntlm;
    MD4_Init(&ntlm);
    for(i = 0; i < strlen(password); i++)
    {
        MD4_Update(&ntlm, password + i, 1);
        MD4_Update(&ntlm, "",           1);
    }  
    MD4_Final(result, &ntlm);
}
</pre>
Again, this uses the OpenSSL library. 

<h3>Challenge/response</h3>
Once the LANMAN and NTLM hashes have been calculated, they can't just be put on the wire. That would be vulnerable to any number of attacks, the most obvious being replay. If an attacker captures one login, he or she can replay it any time to log in as that user. To prevent that, the server sends 8 bytes of random value, which I call a "challenge", to the client. It hashes the hashes using that challenge value to create a response. 

The code for creating a challenge is almost identical to the code for creating the LANMAN hash, except instead of two parts, it has three. The procedure is identical for hashing a LANMAN or NTLM hash:
<ul>
<li>Pad the 16-byte hash with NULLs ('\0') to 21 bytes</li>
<li>Split the 21-byte string into three 7-byte (56-bit) strings</li>
<li>Convert each of those strings into a 64-bit DES key, by adding a parity bit to the end of each byte (same code as before)</li>
<li>Encrypt the 8-byte challenge sent by the server with each of the keys, generating three 8-byte encrypted strings</li>
<li>Concatenate those three strings to form a single 24-byte string</li>
</ul>

And that 24-byte string is what's put on the wire. Simple, eh?

Here's some code:
<pre>
void lm_create_response(const uint8_t lanman[16], const uint8_t challenge[8], uint8_t result[24])
{
    size_t i;

    uint8_t password1[7];
    uint8_t password2[7];
    uint8_t password3[7];

    uint8_t hash1[8];
    uint8_t hash2[8];
    uint8_t hash3[8];

    /* Initialize passwords. */
    memset(password1, 0, 7);
    memset(password2, 0, 7);
    memset(password3, 0, 7);

    /* Copy data over. */
    for(i = 0; i < 7; i++)
    {
        password1[i] = lanman[i];
        password2[i] = lanman[i + 7];
        password3[i] = (i + 14 < 16) ? lanman[i + 14] : 0;
    }

    /* do the encryption. */
    des(password1, challenge, hash1);
    des(password2, challenge, hash2);
    des(password3, challenge, hash3); 

    /* Copy the result to the return parameter. */
    memcpy(result + 0,  hash1, 8);
    memcpy(result + 8,  hash2, 8);
    memcpy(result + 16, hash3, 8);
}
</pre>

That's all you need! 

<h3>Conclusion</h3>
Hopefully you now see how simple it is to create LANMAN/NTLM hashes. There's really nothing to it, when it comes right down to it. 

<em>Update [2008-11-27]: Noted that LANMAN passwords were converted to uppercase before being hashed. </em>
