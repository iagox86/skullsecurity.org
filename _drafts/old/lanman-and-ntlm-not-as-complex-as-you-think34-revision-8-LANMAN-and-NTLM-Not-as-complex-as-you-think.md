---
id: 43
title: 'LANMAN and NTLM: Not as complex as you think!'
date: '2008-08-31T20:46:08-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=43'
permalink: '/?p=43'
---

As I'm sure you've noticed with my first two posts, my NetBIOS/SMB project is taking up most of my time. I hit a bump this weekend, and almost got to the point where the only valid answer was throwing things; luckily, however, I figured it out. I did make a new enemy, though: signed data types! The devil's datatype.

But sour grapes (and, naturally, joking) aside, I just finished implementing the two older (and, by far, most common) Windows authentication hashes: LANMAN and NTLM. I'm also planning on implementing NTLMv2 in the near future, so stay tuned for that. LANMAN and NTLM are used by default on Windows, though, so you're far more likely to see them.

In the past, I've always feared LANMAN and NTLM, thinking that there was something inherently complex and tricky about them. However, once I got around to implementing them, I realized that they're dead simple! Nothing to it! They're so simple, in fact, that they're the perfect topic for a blog post.

The code I'm presenting here is straight from my nbtool code. The particular SVN revision is 169, but the code should basically be static now. [Here is the code you need](http://svn.skullsecurity.org:81/ron/security/nbtool/crypto.c) (along with the [header file](http://svn.skullsecurity.org:81/ron/security/nbtool/crypto.h) and [types.h](http://svn.skullsecurity.org:81/ron/security/nbtool/types.h)). Compile them with -DTEST and -lssl/-lcrypto, and you're set!

### LANMAN hash

The first thing I'll go over is how to create a LANMAN hash. Many of you probably know it as the easiest hash in history to crack. That'd be the one! In short, here's how to generate it:

- Make the password exactly 14 characters, either by truncating or padding with NULL bytes (' ').
- Split into two 7-character (56-bit) passwords
- Convert each of those passwords into a 64-bit DES key, by adding a parity bit to the end of each byte (I'll have some code later)
- Encrypt the string "KGS!@#$%" with each of the two keys, generating two 8-byte encrypted strings
- Concatinate those two strings to form a 16-byte string

That 16-byte string is the LANMAN hash that's stored in the SAM file (among other places).

Here is the code for converting the 56-bit string into the 64-bit key:

```
static void password_to_key(const uint8_t password[7], uint8_t key[8])
{
    /* make room for parity bits */
    key[0] =                        (password[0] >> 0);
    key[1] = ((password[0]) > 1);
    key[2] = ((password[1]) > 2);
    key[3] = ((password[2]) > 3);
    key[4] = ((password[3]) > 4);
    key[5] = ((password[4]) > 5);
    key[6] = ((password[5]) > 6);
    key[7] = ((password[6]) 
<p>Note: the password HAS to be unsigned for this to work! Trust me! If you used signed data types, it'll work fine until you try hashing binary data, then it won't work and you'll want to throw things. </p>
<p>After that, the rest is easy:</p>
void lm_create_hash(const char *password, uint8_t result[16])
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
    for(i = 0; i 
<p>And here's the DES function, which uses OpenSSL functions (don't worry if this is confusing, it was also confusing to me, at first):</p>
static void des(const uint8_t password[7], const uint8_t data[8], uint8_t result[])
{   
    DES_cblock key;
    DES_key_schedule schedule;

    password_to_key(password, key);

    DES_set_odd_parity(&key);
    DES_set_key_unchecked(&key, &schedule);
    DES_ecb_encrypt((DES_cblock*)data, (DES_cblock*)result, &schedule, DES_ENCRYPT);
}  
<p>That's all there is to it! </p>
<h3>NTLM hash</h3>
<p>The NTLM hash is the other hash value that's stored in the SAM file. It's used for authentication in addition to LANMAN. Although it isn't stored in an easily crackable format, it does have one fatal flaw: it is almost always sent (and stored) alongside the LANMAN hash, for backwards compatibility, making any added security completely irrelevant. </p>
<p>Generating the NTLM hash is far easier than a LANMAN hash. It is simply an MD4() of the password (in Unicode). Here is the code (note that I'm doing the Unicode in an incredibly inefficient way, but for the purposes of short code, it's the quickest way to demonstrate):</p>
void ntlm_create_hash(const char *password, uint8_t result[16])
{
    size_t i;
    MD4_CTX ntlm;
    MD4_Init(&ntlm);
    for(i = 0; i 
<p>Again, this uses the OpenSSL library. </p>
<h3>Challenge/response</h3>
<p>Once the LANMAN and NTLM hashes have been calculated, they can't just be put on the wire. That would be vulnerable to any number of attacks, the most obvious being replay. If an attacker captures one login, he or she can replay it any time to log in as that user. To prevent that, the server sends 8 bytes of random value, which I call a "challenge", to the client. It hashes the hashes using that challenge value to create a response. </p>
<p>The code for creating a challenge is almost identical to the code for creating the LANMAN hash, except instead of two parts, it has three. The procedure is identical for hashing a LANMAN or NTLM hash:</p>
```

- Pad the 16-byte hash with NULLs (' ') to 21 bytes
- Split the 21-byte string into three 7-byte (56-bit) strings
- Convert each of those strings into a 64-bit DES key, by adding a parity bit to the end of each byte (same code as before)
- Encrypt the 8-byte challenge sent by the server with each of the keys, generating three 8-byte encrypted strings
- Concatinate those three strings to form a single 24-byte string

And that 24-byte string is what's put on the wire. Simple, eh?

Here's some code:

```

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
    for(i = 0; i 
<p>That's all you need! </p>
<h3>Conclusion</h3>
<p>Hopefully you now see how simple it is to create LANMAN/NTLM hashes. There's really nothing to it, when it comes right down to it. </p>
```