---
id: 2627
title: 'BSidesSF 2022 Writeups: Apache Challenges (mod_ctfauth, refresh)'
date: '2022-06-17T15:19:18-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2627'
permalink: /2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh
categories:
    - 'BSidesSF 2022'
    - CTFs
---

Hey folks,

This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything [on github](https://github.com/bsidessf/ctf-2022-release). Most have either a Dockerfile or instructions on how to run locally. Enjoy!

Here are the four BSidesSF CTF blogs:

- [shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft)
- [mod\_ctfauth, refreshing](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh)
- [turtle, guessme](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme)
- [loca, reallyprettymundane](https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane)

## Refreshing - Reverse proxy mischief

The [*Refreshing*](https://github.com/BSidesSF/ctf-2022-release/tree/main/refreshing) challenge implements a reverse proxy that checks the query string for mischief, and attaches a header if it's bad. If the PHP application with a blatant vulnerability sees that header, it prints an error and does not render.

This was actually based entirely on CVE-2022-1388 (the name "Refreshing" is a nod to F5) - you can see my Rapid7 writeup [on AttackerKB](https://attackerkb.com/topics/SN5WCzYO7W/cve-2022-1388/rapid7-analysis).

This was absolutely new to me when I worked on that vuln: the `Connection` HTTP header [can remove headers when proxying](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Connection). That means if you set `Connection: Xyz` while proxying through Apache, it will remove the header `Xyz` when forwarding. This worked out of the box on Apache! I initially tried Nginx, and it did not work there - not sure why, maybe they don't implement that header the same?

Anyway, to solve this, all you have to do is set the header `Connection: X-Security-Danger` on the request, then take advantage of the path traversal on the PHP site:

```
$ curl -H 'Connection: X-Security-Danger' 'http://refreshing-d7c0f337.challenges.bsidessf.net/index.php?file=../../../../../../../flag.txt'
CTF{press_f5_to_continue}
```

## mod\_ctfauth - A custom Apache authentication module

[*mod\_ctfauth*](https://github.com/BSidesSF/ctf-2022-release/tree/main/mod-ctfauth) is a fairly simple Apache authentication plugin. It checks a username and token, then decides whether to grant access. I wrote it at the very last minute, because at work I was reverse engineering some Apache plugins and thought it'd be a good excuse to learn. And it worked! I've been re-using the container to test out more Apache stuff this week!

The source for the challenge is [here](https://github.com/BSidesSF/ctf-2022-release/blob/main/mod-ctfauth/challenge/ctfauth.c). As you can see, it's really pretty straight forward - you can expect something more interesting next year, now that I know how these plugins work!

The bulk of the challenge is the following code (I removed a bunch of extra checks to shorten it down):

```c
  char *username = (char*)apr_table_get(r->headers_in, USERNAME_HEADER);
  if(strcmp(username, "ctf")) {
    return AUTHZ_DENIED;
  }

  char* header = (char*)apr_table_get( r->headers_in, HEADER);
  char *encoded_token = header + strlen(TOKEN_PREFIX);
  int actual_length = apr_base64_decode(decoded_token, encoded_token);

[...]

apr_md5_ctx_t md5;
  apr_md5_init(&md5);
  apr_md5_update(&md5, SECRET, strlen(SECRET));
  apr_md5_update(&md5, username, strlen(username));
  apr_md5_update(&md5, SECRET, strlen(SECRET));

  char buffer[HASH_LENGTH];
  apr_md5_final(buffer, &md5);

  if(memcmp(buffer, decoded_token, HASH_LENGTH)) {
    ap_log_rerror(APLOG_MARK, APLOG_WARNING, 0, r, "CTF: Token doesn't match!");
    free(decoded_token);
    return AUTHZ_DENIED;
  }
```

It basically requires you to send a header and a token. The token is `MD5(SECRET + username + SECRET)`, which is quite easy to calculate (and doesn't change).