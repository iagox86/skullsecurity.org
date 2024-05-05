---
id: 47
title: 'NTLMv2, as promised'
date: '2008-09-02T14:38:41-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://www.skullsecurity.org/blog/?p=47'
permalink: '/?p=47'
---

Last post, I promised I'd post about NTLMv2 once I got it implemented. LMv2 and NTLMv2 are a little trickier than the first versions, although most of my trouble was trying to figure out how to use HMAC-MD5 in OpenSSL. The good news is that LMv2 and NTLMv2 are almost identical to each other.

### Implementation ### LMv2 and NTLMv2 require the following values: - The NTLM hash (MD4 of the Unicode password)
- Username (uppercase Unicode)
- Domain (uppercase Unicode, supposedly<sup>1</sup>)
- Client challenge (a random string<sup>2</sup>)
- LMv2: 8 bytes
- NTLMv2: 10+ bytes (up to 24 bytes on Vista)

- Server challenge (8 bytes)





Once you have those values, the formula is simple:

```
v2hash = HMAC-MD5(v1hash, concat(username, domain_name));
hash = HMAC-MD5(v2hash, concat(server_challenge, client_challenge));
```

The only difference between LMv2 and NTLMv2 is the length of the client challenge.

Here is the code for generating v2hash using the OpenSSL library (note that I called the client challenge the "blob", and that I'm not randomizing it; if you want a secure implementation, it should be random):

```
void ntlmv2_create_hash(const uint8_t ntlm[16], const char *username, const char *domain, uint8_t hash[16])
{
    size_t username_length = strlen(username);
    size_t domain_length   = strlen(domain);
    char    *combined;
    uint8_t *combined_unicode;

    /* Probably shouldn't do this, but this is all prototype so eh? */
    if(username_length > 256 || domain_length > 256)
        DIE("username or domain too long.");

    /* Combine the username and domain into one string. */
    combined = malloc(username_length + domain_length + 1);
    memset(combined, 0, username_length + domain_length + 1);

    memcpy(combined,                   username, username_length);
    memcpy(combined + username_length, domain,   domain_length);

    /* Convert to Unicode. */
    combined_unicode = (uint8_t*)unicode_alloc_upper(combined);

    /* Perform the Hmac-MD5. */
    HMAC(EVP_md5(), ntlm, 16, combined_unicode, (username_length + domain_length) * 2, hash, NULL);

    free(combined_unicode);
    free(combined);
}
```

And here's the code for creating the full LMv2/NTLMv2 response:

```
void ntlmv2_create_response(const uint8_t ntlm[16], const char *username, const char *domain, const uint8_t challenge[8], uint8_t *result, uint8_t *result_size)
{
    size_t  i;
    uint8_t v2hash[16];
    uint8_t *data;

    uint8_t blip[8];
    uint8_t *blob;
    uint8_t blob_length;


    /* Create the 'blip'. TODO: Do I care if this is random? */
    for(i = 0; i 
<h3>What's the point</h3>
<p>So, the main difference between NTLMv1 and NTLMv2 is that a "client challenge" is incorporated. So, what's that buy us?</p>
<p>The main reason for adding some client randomness, I would guess, is to help prevent pre-computed password attacks from a malicious server. A malicious server can pre-compute the most common password hashes for a given server challenge, then send that challenge to every user. This is very similar to the client token/server token on Battle.net logins, for all you Battle.net people. </p>
<h3>How to enable</h3>
<p>Windows, by default, sends both LANMAN and NTLM to the server, and the server accepts both. If you want more security, you should configure your client to only send v2, and your server to only accept v2. Microsoft's documentation can be <a href="http://www.microsoft.com/technet/prodtechnol/windows2000serv/reskit/regentry/76052.mspx?mfr=true">here</a>, which boils down to this; change or create this DWORD value, taking the usual precautions not to screw up your registry:<br></br>
HKLMSYSTEMCurrentControlSetControlLsaLmCompatibilityLevel</p>
<p>To:</p>
```

- 0 -- Clients use LM and NTLM authentication, but they never use NTLMv2 session security. Domain controllers accept LM, NTLM, and NTLMv2 authentication.
- 1 -- Clients use LM and NTLM authentication, and they use NTLMv2 session security if the server supports it. Domain controllers accept LM, NTLM, and NTLMv2 authentication.
- 2 -- Clients use only NTLM authentication, and they use NTLMv2 session security if the server supports it. Domain controller accepts LM, NTLM, and NTLMv2 authentication.
- 3 -- Clients use only NTLMv2 authentication, and they use NTLMv2 session security if the server supports it. Domain controllers accept LM, NTLM, and NTLMv2 authentication.
- 4 -- Clients use only NTLMv2 authentication, and they use NTLMv2 session security if the server supports it. Domain controller refuses LM authentication responses, but it accepts NTLM and NTLMv2.
- 5 -- Clients use only NTLMv2 authentication, and they use NTLMv2 session security if the server supports it. Domain controller refuses LM and NTLM authentication responses, but it accepts NTLMv2.
Note that I haven't talked about session security (yet?).

### Footnotes

<sup>1</sup> From my experiments, the domain has to be in whichever case you sent it during the login, not uppercase.  
<sup>2</sup> The documentation I read described a specific structure that NTLMv2 required for the client challenge; this structure worked as well as a random string except on Vista, where I couldn't use a client challenge longer than 24 bytes. If anybody knows why, I'd be curious to hear it!