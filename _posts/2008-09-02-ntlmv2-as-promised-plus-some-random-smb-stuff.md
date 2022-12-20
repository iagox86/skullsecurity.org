---
id: 45
title: 'NTLMv2, as promised, plus some random SMB stuff!'
date: '2008-09-02T20:37:35-05:00'
author: ron
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=45'
permalink: /2008/ntlmv2-as-promised-plus-some-random-smb-stuff
categories:
    - smb
---

Last post, I promised I'd post about NTLMv2 once I got it implemented. And, here we are. 

The LMv2 and NTLMv2 responses are a little bit trickier than the first versions, although most of my trouble was trying to figure out how to use HMAC-MD5 in OpenSSL. The good news is that LMv2 and NTLMv2 are almost identical to each other, with only one minor difference. 
<!--more-->
<h3>Implementation</h3>
LMv2 and NTLMv2 require the following values:
<ul>
<li>The NTLM hash (MD4 of the Unicode password)</li>
<li>Username (uppercase Unicode)</li>
<li>Domain (uppercase Unicode, supposedly<sup>1</sup>)</li>
<li>Client challenge (a random string<sup>2</sup>)</li>
  <ul>
  <li>LMv2: 8 bytes</li>
  <li>NTLMv2: 10+ bytes (up to 24 bytes on Vista)</li>
  </ul>
<li>Server challenge (8 bytes)</li>
</ul>

Once you have those values, the formula is simple:
<pre>v2hash = HMAC-MD5(v1hash, concat(username, domain_name));
response = HMAC-MD5(v2hash, concat(server_challenge, client_challenge));</pre>
The only difference between LMv2 and NTLMv2 is the length of the client challenge. 

Here is the code for generating v2hash using the OpenSSL library (note that I called the client challenge the "blob", and that I'm not randomizing it; if you want a secure implementation, it should be random):
<pre>void ntlmv2_create_hash(const uint8_t ntlm[16], const char *username, 
    const char *domain, uint8_t hash[16])
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
    HMAC(EVP_md5(), ntlm, 16, combined_unicode, (username_length + 
        domain_length) * 2, hash, NULL);

    free(combined_unicode);
    free(combined);
}
</pre>

And here's the code for creating the full LMv2/NTLMv2 response:
<pre>void ntlmv2_create_response(const uint8_t ntlm[16], const char *username, 
    const char *domain, const uint8_t challenge[8], uint8_t *result, 
    uint8_t *result_size)
{
    size_t  i;
    uint8_t v2hash[16];
    uint8_t *data;

    uint8_t blip[8];
    uint8_t *blob;
    uint8_t blob_length;

    /* Create the 'blip'. TODO: Do I care if this is random? */
    for(i = 0; i < 8; i++)
        blip[i] = i;

    if(*result_size < 24)
    {
        /* Result can't be less than 24 bytes. */
        DIE("Result size is too low!");
    }
    else if(*result_size == 24)
    {
        /* If they're looking for 24 bytes, then it's just the raw blob. */
        blob = malloc(8);
        memcpy(blob, blip, 8);
        blob_length = 8;
    }
    else
    {
        blob = malloc(24);
        for(i = 0; i < 24; i++)
            blob[i] = i;
        blob_length = 24;
    }

    /* Allocate room enough for the server challenge and the client blob. */
    data = malloc(8 + blob_length);

    /* Copy the challenge into the memory. */
    memcpy(data, challenge, 8);
    /* Copy the blob into the memory. */
    memcpy(data + 8, blob, blob_length);

    /* Get the v2 hash. */
    ntlmv2_create_hash(ntlm, username, domain, v2hash);

    /* Generate the v2 response. */
    HMAC(EVP_md5(), v2hash, 16, data, 8 + blob_length, result, NULL);

    /* Copy the blob onto the end of the v2 response. */
    memcpy(result + 16, blob, blob_length);

    /* Store the result size. */
    *result_size = blob_length + 16;

    /* Finally, free up the memory. */
    free(data);
    free(blob);
}
</pre>

As with my previous post, the code I'm presenting here is straight from my nbtool code, this time revision 180. <a href='http://svn.skullsecurity.org:81/ron/security/nbtool/crypto.c'>Here is the code you need</a> (along with the <a href='http://svn.skullsecurity.org:81/ron/security/nbtool/crypto.h'>header file</a> and <a href='http://svn.skullsecurity.org:81/ron/security/nbtool/types.h'>types.h</a>). Compile them with -DTEST and -lssl/-lcrypto, and you're set! 

<h3>What's the point?</h3>
So, the main difference between NTLMv1 and NTLMv2 is that a "client challenge" is incorporated. So, what's that buy us?

The main reason for adding some client randomness, I would guess, is to help prevent pre-computed password attacks from a malicious server. A malicious server can pre-compute the most common password hashes for a given server challenge, then send that challenge to every user. 

Also, for what it's worth, this is very similar conceptually to the client token/server token on Battle.net logins, for all you Battle.net people. 

<h3>How to enable</h3>
Windows, by default, sends both LANMAN and NTLM to the server, and the server accepts both. If you require more security, you should configure your client/server to only send/accept v2 responses. Microsoft's documentation on how to change this can be found <a href="http://www.microsoft.com/technet/prodtechnol/windows2000serv/reskit/regentry/76052.mspx?mfr=true">here</a>, which boils down to this: change or create this DWORD value, taking the usual precautions to not screw up your registry:
HKLM\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel

To:
<ul>
<li>0 -- <strong>Client</strong>: LM/NTLM. <strong>Server</strong>: LM, NTLM, and NTLMv2.</li>
<li>1 -- <strong>Client</strong>: LM/NTLM, session security. <strong>Server</strong>: LM, NTLM, and NTLMv2.</li>
<li>2 -- <strong>Client</strong>: NTLM, session security. <strong>Server</strong>: LM, NTLM, and NTLMv2.</li>
<li>3 -- <strong>Client</strong>: NTLMv2, session security. <strong>Server</strong>: LM, NTLM, and NTLMv2.</li>
<li>4 -- <strong>Client</strong>: NTLMv2, session security. <strong>Server</strong>: NTLM and NTLMv2.</li>
<li>5 -- <strong>Client</strong>: NTLMv2, session security. <strong>Server</strong>: NTLMv2.</li>
</ul>
Note that I haven't talked about session security at all. That's something I plan to do in the near future, and I'll definitely post about it when I do. 

<h3>Random SMB stuff</h3>
As promised by the blog's title title, this section is for some random SMB stuff! 

The random stuff happens to be the, you guessed it, the standard login sequence! There are three messages involved:
<ol>
<li>SMB_COM_NEGOTIATE</li>
  <ul>
  <li>Client sends a list of protocols it understands</li>
  <li>Server responds with its protocol choice, a bunch of its capabilities/settings, and its challenge value (used when creating the login response hashes)</li>
  </ul>
<li>SMB_COM_SESSION_SETUP_ANDX</li>
  <ul>
  <li>Client sends its username, domain, and hashed password(s); the hashes can be in any format the server supports, from plaintext to NTLMv2; the server will check every possibility.</li>
  <li>Server responds with either the UID (User ID) for the session, or an error, depending on if a valid username/password was given; it also informs the client if its username was incorrect, resulting in being logged in as 'GUEST'<sup>3</sup>.</li>
  </ul>
<li>SMB_COM_TREE_CONNECT_ANDX</li>
  <ul>
  <li>Client sends the tree it wishes to connect to (eg, "IPC$" for special communications, "C$" for the hidden C drive share, "KITTEN" for a share called "KITTEN", etc).</li>
  <li>Server responds with the TID (Tree ID) for the session, or with an error, depending on whether the user has the appropriate privileges.</li>
  </ul>
</ol>
If you want to see any of that in action, grab a copy of Wireshark and connect to a network share ("<tt>c:\> net use * \\server\c$ /u:username</tt>"). 

<h3>Footnotes</h3>
<sup>1</sup> From my experiments, the domain has to be in whichever case you sent it during the login, not uppercase. To avoid this problem, I convert the domain to uppercase immediately after the user inputs it. 
<sup>2</sup> The documentation I read described a specific structure that NTLMv2 required for the client challenge; this structure worked as well as a random string except on Vista, where I couldn't use a client challenge longer than 24 bytes and therefore was forced to use the random string. If anybody knows why, I'd be curious to hear it! 
<sup>3</sup> That's right -- if you mistype your username, and the remote machine has the 'GUEST' account enabled, you're automatically logged in as the GUEST account. When user friendliness attacks?
