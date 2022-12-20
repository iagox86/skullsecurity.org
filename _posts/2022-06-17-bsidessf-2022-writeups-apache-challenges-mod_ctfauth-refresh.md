---
id: 2627
title: 'BSidesSF 2022 Writeups: Apache Challenges (mod_ctfauth, refresh)'
date: '2022-06-17T15:19:18-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2627'
permalink: /2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh
categories:
    - 'BSidesSF 2022'
    - CTFs
---

<p>Hey folks,</p>
<p>This is my (Ron's / iagox86's) author writeups for the BSides San Francisco 2022 CTF. You can get the full source code for everything <a href="https://github.com/bsidessf/ctf-2022-release">on github</a>. Most have either a Dockerfile or instructions on how to run locally. Enjoy!</p>
<!--more-->
<p>Here are the four BSidesSF CTF blogs:</p>
<ul>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-tutorial-challenges-shurdles-loadit-polyglot-nft">shurdles1/2/3, loadit1/2/3, polyglot, and not-for-taking</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-apache-challenges-mod_ctfauth-refresh">mod_ctfauth, refreshing</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-game-y-challenges-turtle-guessme">turtle, guessme</a></li>
<li><a href="https://blog.skullsecurity.org/2022/bsidessf-2022-writeups-miscellaneous-challenges-loca-reallyprettymundane">loca, reallyprettymundane</a></li>
</ul>
<h2>Refreshing - Reverse proxy mischief</h2>
<p>The <a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/refreshing"><em>Refreshing</em></a> challenge implements a reverse proxy that checks the query string for mischief, and attaches a header if it's bad. If the PHP application with a blatant vulnerability sees that header, it prints an error and does not render.</p>
<p>This was actually based entirely on CVE-2022-1388 (the name &quot;Refreshing&quot; is a nod to F5) - you can see my Rapid7 writeup <a href="https://attackerkb.com/topics/SN5WCzYO7W/cve-2022-1388/rapid7-analysis">on AttackerKB</a>.</p>
<p>This was absolutely new to me when I worked on that vuln: the <code>Connection</code> HTTP header <a href="https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Connection">can remove headers when proxying</a>. That means if you set <code>Connection: Xyz</code> while proxying through Apache, it will remove the header <code>Xyz</code> when forwarding. This worked out of the box on Apache! I initially tried Nginx, and it did not work there - not sure why, maybe they don't implement that header the same?</p>
<p>Anyway, to solve this, all you have to do is set the header <code>Connection: X-Security-Danger</code> on the request, then take advantage of the path traversal on the PHP site:</p>
<pre><code>$ curl -H &#039;Connection: X-Security-Danger&#039; &#039;http://refreshing-d7c0f337.challenges.bsidessf.net/index.php?file=../../../../../../../flag.txt&#039;
CTF{press_f5_to_continue}</code></pre>
<h2>mod_ctfauth - A custom Apache authentication module</h2>
<p><a href="https://github.com/BSidesSF/ctf-2022-release/tree/main/mod-ctfauth"><em>mod_ctfauth</em></a> is a fairly simple Apache authentication plugin. It checks a username and token, then decides whether to grant access. I wrote it at the very last minute, because at work I was reverse engineering some Apache plugins and thought it'd be a good excuse to learn. And it worked! I've been re-using the container to test out more Apache stuff this week!</p>
<p>The source for the challenge is <a href="https://github.com/BSidesSF/ctf-2022-release/blob/main/mod-ctfauth/challenge/ctfauth.c">here</a>. As you can see, it's really pretty straight forward - you can expect something more interesting next year, now that I know how these plugins work!</p>
<p>The bulk of the challenge is the following code (I removed a bunch of extra checks to shorten it down):</p>
<pre><code class="language-c">  char *username = (char*)apr_table_get(r-&gt;headers_in, USERNAME_HEADER);
  if(strcmp(username, &quot;ctf&quot;)) {
    return AUTHZ_DENIED;
  }

  char* header = (char*)apr_table_get( r-&gt;headers_in, HEADER);
  char *encoded_token = header + strlen(TOKEN_PREFIX);
  int actual_length = apr_base64_decode(decoded_token, encoded_token);

[...]

apr_md5_ctx_t md5;
  apr_md5_init(&amp;md5);
  apr_md5_update(&amp;md5, SECRET, strlen(SECRET));
  apr_md5_update(&amp;md5, username, strlen(username));
  apr_md5_update(&amp;md5, SECRET, strlen(SECRET));

  char buffer[HASH_LENGTH];
  apr_md5_final(buffer, &amp;md5);

  if(memcmp(buffer, decoded_token, HASH_LENGTH)) {
    ap_log_rerror(APLOG_MARK, APLOG_WARNING, 0, r, &quot;CTF: Token doesn&#039;t match!&quot;);
    free(decoded_token);
    return AUTHZ_DENIED;
  }</code></pre>
<p>It basically requires you to send a header and a token. The token is <code>MD5(SECRET + username + SECRET)</code>, which is quite easy to calculate (and doesn't change).</p>