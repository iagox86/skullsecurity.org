---
id: 2377
title: 'Some crypto challenges: Author writeup from BSidesSF CTF'
date: '2019-03-12T11:23:36-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2377'
permalink: /2019/some-crypto-challenges-author-writeup-from-bsidessf-ctf
categories:
    - Conferences
    - Crypto
    - Passwords
    - Tools
---

Hey everybody,

This is yet another author's writeup for BSidesSF CTF challenges! This one will focus on three crypto challenges I wrote: <tt>mainframe</tt>, <tt>mixer</tt>, and <tt>decrypto</tt>!
<!--more-->
<h2>mainframe - bad password reset</h2>

<style>
.block1 {
    color: red;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
.block2 {
    color: orange;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
.block3 {
    color: yellow;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
.block4 {
    color: green;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
.block5 {
    color: blue;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
.block6 {
    color: purple;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
.blockdisabled {
    color: #404040;
    background-color: #3b3d37;
    border: 2px solid #17242b;
    margin: 2px;
}
</style>
<tt>mainframe</tt>, which you can view <a href='https://github.com/BSidesSF/ctf-2019-release/tree/master/challenges/mainframe'>on the Github release</a> immediately presents the player with some RNG code in Pascal:

<pre>
  <span class="Statement">function</span> msrand: <span class="Type">cardinal</span>;
  <span class="Statement">const</span>
    a = <span class="Number">214013</span>;
    c = <span class="Number">2531011</span>;
    m = <span class="Number">2147483648</span>;
  <span class="Statement">begin</span>
    x2 := (a * x2 + c) <span class="Operator">mod</span> m;
    msrand := x2 <span class="Operator">div</span> <span class="Number">65536</span>;
  <span class="Statement">end</span>;
</pre>

If you reverse engineer that, or google a constant, you'll find that it's a pretty common random number generator called a Linear Congruential Generator. You can find a ton of implementations, including that one, on <a href='https://rosettacode.org/wiki/Linear_congruential_generator'>Rosetta Code</a>.

The text below that says:

<pre>
We don't really know how it's seeded, but we do know they generate password resets one byte at a time (12 bytes total) - rand() % 0xFF - and they don't change the seed in between.
</pre>

I had at least one question about that set up - since <tt>rand() % 0xFF</tt> at <em>best</em> can only be 255/256 possible values - but this is a CTF problem, right?

To solve this, I literally implemented the <tt>gen_password()</tt> function in C (on the theory that it'll be fastest that way):

<pre>
<span class="Type">int</span> seed = <span class="Number">0</span>;

<span class="Type">int</span> <span class="Function">my_rand</span>() {
  seed = (<span class="Number">214013</span> * seed + <span class="Number">2531011</span>) &amp; <span class="Number">0x7fffffff</span>;
  <span class="Statement">return</span> seed &gt;&gt; <span class="Number">16</span>;
}

<span class="Type">void</span> <span class="Function">gen_password</span>(<span class="Type">uint8_t</span> buffer[<span class="Number">12</span>]) {
  <span class="Type">uint32_t</span> i;

  <span class="Repeat">for</span>(i = <span class="Number">0</span>; i &lt; <span class="Number">12</span>; i++) {
    buffer[i] = <span class="Function">my_rand</span>() % <span class="Number">0xFF</span>;
  }
}

<span class="Type">void</span> <span class="Function">print_hex</span>(<span class="Type">uint8_t</span> *hex) {
  <span class="Type">uint32_t</span> i;
  <span class="Repeat">for</span>(i = <span class="Number">0</span>; i &lt; <span class="Number">12</span>; i++) {
    <span class="Function">printf</span>(<span class="String">&quot;</span><span class="SpecialChar">%02x</span><span class="String">&quot;</span>, hex[i]);
  }
}
</pre>

Then called it for each possible seed:

<pre>
  <span class="Type">int</span> index;
  <span class="Repeat">for</span>(index = <span class="Number">0x0</span>; index &lt; <span class="Number">0x7FFFFFFF</span>; index++) {
    seed = index;

    <span class="Function">gen_password</span>(generated_pw);

    <span class="Conditional">if</span>(!<span class="Function">memcmp</span>(generated_pw, desired, <span class="Number">12</span>)) {
      <span class="Function">printf</span>(<span class="String">&quot;Found it! Seed = </span><span class="SpecialChar">%d</span><span class="SpecialChar">\n</span><span class="String">&quot;</span>, index);
      <span class="Function">gen_password</span>(generated_pw);
      <span class="Function">printf</span>(<span class="String">&quot;Next password: </span><span class="SpecialChar">\n</span><span class="String">&quot;</span>);
      <span class="Function">print_hex</span>(generated_pw);
      <span class="Function">printf</span>(<span class="String">&quot;</span><span class="SpecialChar">\n</span><span class="String">&quot;</span>);
      <span class="Function">exit</span>(<span class="Number">0</span>);
    }
  }
</pre>

Then I generated a test password: cfd55275b5d38beba9ab355b

Put that into the program:

<pre>
$ ./solution cfd55275b5d38beba9ab355b
...
Next password:
126ab42e0de3d300260ff309
</pre>

And log in as root, thereby solving the question!

In case you're curious, to implement this challenge I store the RNG seed in your local session. That way, people aren't stomping on each other's cookies!

<h2>mixer - ECB block shuffle</h2>

For the next challenge, <tt>mixer</tt> (<a href='https://github.com/BSidesSF/ctf-2019-release/tree/master/challenges/mixer'>Github link</a>), you're presented with a login form with a first name, a last name, and an is_admin field. is_admin is set to 0, disabled, and isn't actually sent as part of the form submit. The goal is to switch on the is_admin flag in your cookie.

When you log in, it sends the username and password as a GET request, and tells you to keep an eye on a certain cookie:

<pre>
$ curl -s --head 'http://localhost:1234/?action=login&amp;first_name=test&amp;last_name=test' | grep 'Set-Cookie: user='
Set-Cookie: user=a3000ad8bfaa21b7b20797c3d480601af63df911b378cf9729a203ff65d35ee723e95cf1d27d3a01758d32ea42bd52bb9b4113cd881549cb3edbc20ca3077726; path=/; HttpOnly
</pre>

Unfortunately for the player, the cookie is encrypted! We can confirm this by passing in a longer name and seeing a longer cookie:

<pre>
$ curl -s --head 'http://localhost:1234/?action=login&amp;first_name=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&amp;last_name=test' | grep 'Set-Cookie'
Set-Cookie: user=fbfaf2879c8e57b4ba623424c401915228bb743e365ba0dbe6987df8a6c3af9b28bb743e365ba0dbe6987df8a6c3af9b28bb743e365ba0dbe6987df8a6c3af9b1fa044b6e8a48ecb5f6ee54aa10f36c037010895d9a22f694c7b0b415dc22107029f9e0eb4236189e29044158b50c0d0; path=/; HttpOnly
Set-Cookie: rack.session=BAh7B0kiD3Nlc3Npb25faWQGOgZFVEkiRWM3ZDY1NjRlNDFkMTkzODMxNWVi%0AYzFkYWZhNjljMGNkYWY3MzEzNTRiNzE0NmQ5NTRjZDQ0ODQxNTUwNmVjMGMG%0AOwBGSSIMYWVzX2tleQY7AEYiJe%2BrNKamgEXyzoed3PFi8cn7XWYz%2Fu0UnP9B%0AR1OIjrqX%0A; path=/; HttpOnly

</pre>

Not only is it longer, there's another important characteristic. If we break up the encrypted data into 128-bit blocks, we can see a pattern emerge:

<pre>
fbfaf2879c8e57b4ba623424c4019152
28bb743e365ba0dbe6987df8a6c3af9b
28bb743e365ba0dbe6987df8a6c3af9b
28bb743e365ba0dbe6987df8a6c3af9b
1fa044b6e8a48ecb5f6ee54aa10f36c0
37010895d9a22f694c7b0b415dc22107
029f9e0eb4236189e29044158b50c0d0
</pre>

Notice how the second, third, and fourth blocks encrypt to the same data? That tells us that we're likely looking at encryption in ECB mode - electronic codebook - where each block of data is independently encrypted.

ECB mode has a useful property called "malleability". That means that the encrypted data can be changed in a controlled way, and the decrypted version of the data will reflect that change. Specifically, we can move blocks of data (16 bytes at a time) around - rearrange, delete, etc.

We can confirm this by sending back a user cookie with only the repeated field, which we can assume is a full block of As: "AAAAAAAAAAAAAAAA", twice (we also include the <tt>rack.session</tt> cookie, which is required to keep state):

<pre>
$ export USER=28bb743e365ba0dbe6987df8a6c3af9b28bb743e365ba0dbe6987df8a6c3af9b
$ export RACK=BAh7B0kiD3Nlc3Npb25faWQGOgZFVEkiRWM3ZDY1NjRlNDFkMTkzODMxNWVi%0AYzFkYWZhNjljMGNkYWY3MzEzNTRiNzE0NmQ5NTRjZDQ0ODQxNTUwNmVjMGMG%0AOwBGSSIMYWVzX2tleQY7AEYiJe%2BrNKamgEXyzoed3PFi8cn7XWYz%2Fu0UnP9B%0AR1OIjrqX%0A
$ curl -s 'http://localhost:1234/' -H "Cookie: user=$USER; rack.session=$RACK" | grep Error
        <p>Error parsing JSON: 765: unexpected token at 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'</p>
</pre>

Well, we know it's JSON! And we successfully created new ciphertext - simply 32 <tt>A</tt> characters.

If you mess around with the different blocks, you can eventually figure out that the JSON object encrypted in your cookie, if you choose "First Name" and "Last Name" for your names, looks like this:

<pre>
{"first_name":"First Name","last_name":"Last Name","is_admin":0}
</pre>

We can colour the blocks to see them more clearly:

<pre>
<span class="block1">{"first_name":"F</span>
<span class="block2">irst Name","last</span>
<span class="block3">_name":"Last Nam</span>
<span class="block4">e","is_admin":0}</span>
</pre>

So the "First Name" string starts with one character in the first block, then finished in the second block. If we were to make the first name 17 characters, the first byte would be in the first block, and the second block would be entirely made up of the first name. Kinda like this:

<pre>
<span class="block1">{"first_name":"A</span>
<span class="block2">AAAAAAAAAAAAAAAA</span>
<span class="block3">AAAAAAAAA","last</span>
<span class="block4">_name":"Last Nam</span>
<span class="block5">e","is_admin":0}</span>
</pre>

Note how 100% of the second block is controlled by us. Since ECB blocks are encrypted independently, that means we can use that as a building-block to build whatever customer ciphertext we want!

The only thing we can't use in a block is quotation marks, because they'll be escaped (unless we carefully ensure that the <tt>\</tt> from the escape is in a separate block).

If I set my first name to some JSON-like data:

<pre>
<span class="block1">t</span><span class="block2">:1}             est</span>
</pre>

And the last name to "AA", it creates the encrypted blocks:

<pre>
<span class="block1">{"first_name":"t</span>
<span class="block2">:1}             </span>
<span class="block3">est","last_name"</span>
<span class="block4">:"AA","is_admin"</span>
<span class="block5">:0}             </span>
</pre>

Then we can do a little surgury, and replace the last block with the second block:

<pre>
<span class="block1">{"first_name":"t</span>
<span class="blockdisabled">:1}             </span> &lt;-- Moved from here...
<span class="block3">est","last_name"</span>
<span class="block4">:"AA","is_admin"</span>
<span class="block2">:1}             </span> &lt;-- ...to here
</pre>

Or, put together:

<pre>
<span class="block1">{"first_name":"t</span><span class="block3">est","last_name"</span><span class="block4">:"AA","is_admin"</span><span class="block2">:1}             </span>
</pre>

Or just:

<pre>
{"first_name":"test","last_name":"AA","is_admin":1}
</pre>

So now, with encrypted blocks, we do the same thing. First encrypt the name <tt>t:1}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;est</tt> / <tt>AA</tt> (in curl, we have to backslash-escape the <tt>{</tt> and convert <tt>&nbsp;</tt> to <tt>+</tt>):

<pre>
$ curl -s --head 'http://localhost:1234/?action=login&first_name=t:1\}+++++++++++++est&last_name=AA' | grep 'Set-Cookie'
Set-Cookie: user=bb9f8c6b5224a3eebbfe923d31c3ed04c275c360f2a1321f9916ddc88a158d0e10c9e456be5b2e62e9709eb06b1f54a08f115ffefce89f2294fb29c2f2f32ecdc07be6f8d314073bbf780b2b7bbb5f80; path=/; HttpOnly
Set-Cookie: rack.session=BAh7B0kiD3Nlc3Npb25faWQGOgZFVEkiRTExOGFmODMzMjE0ZTA4OWE0OWYy%0ANGYzOTI4MzY1ZWMxNTY0ZGIyMWZhYmZjYzNiNTM5OGQ1MDk4OTA1NGRkMzYG%0AOwBGSSIMYWVzX2tleQY7AEYiJUrTUZz8H7iqi4W5CXOsTV5z4MCP0DTS7ZeI%0A5n02%2B7Xb%0A; path=/; HttpOnly
</pre>

Then split the user cookie into blocks, like we did with the encrypted text:

<pre>
<span class="block1">bb9f8c6b5224a3eebbfe923d31c3ed04</span>
<span class="block2">c275c360f2a1321f9916ddc88a158d0e</span>
<span class="block3">10c9e456be5b2e62e9709eb06b1f54a0</span>
<span class="block4">8f115ffefce89f2294fb29c2f2f32ecd</span>
<span class="block5">c07be6f8d314073bbf780b2b7bbb5f80</span>
</pre>

We literally switch the blocks around like we did before:

<pre>
<span class="block1">bb9f8c6b5224a3eebbfe923d31c3ed04</span>
<span class="blockdisabled">c275c360f2a1321f9916ddc88a158d0e</span> &lt;-- Moved from here...
<span class="block3">10c9e456be5b2e62e9709eb06b1f54a0</span>
<span class="block4">8f115ffefce89f2294fb29c2f2f32ecd</span>
<span class="block2">c275c360f2a1321f9916ddc88a158d0e</span> &lt;-- ...to here
</pre>

Which gives us the new user cookie, which we combine with the rack.session cookie:

<pre>
$ export USER=bb9f8c6b5224a3eebbfe923d31c3ed0410c9e456be5b2e62e9709eb06b1f54a08f115ffefce89f2294fb29c2f2f32ecdc275c360f2a1321f9916ddc88a158d0e
$ export RACK=BAh7B0kiD3Nlc3Npb25faWQGOgZFVEkiRTExOGFmODMzMjE0ZTA4OWE0OWYy%0ANGYzOTI4MzY1ZWMxNTY0ZGIyMWZhYmZjYzNiNTM5OGQ1MDk4OTA1NGRkMzYG%0AOwBGSSIMYWVzX2tleQY7AEYiJUrTUZz8H7iqi4W5CXOsTV5z4MCP0DTS7ZeI%0A5n02%2B7Xb%0A
$ curl -s 'http://localhost:1234/' -H "Cookie: user=$USER; rack.session=$RACK" | grep Congrats
      &lt;p&gt;And it looks like you're admin, too! Congrats! Your flag is &lt;span class='highlight'&gt;CTF{is_fun!!uffling_block_sh}&lt;/span&gt;&lt;/p&gt;
</pre>

And that's the challenge! We were able to take advantage of ECB's inherent malleability to change our JSON object to an arbitrary value.


<h2>decrypto - padding oracle + hash extension</h2>

The final crypto challenge I wrote was called <tt>decrypto</tt> (<a href='https://github.com/BSidesSF/ctf-2019-release/tree/master/challenges/decrypto'>github link</a>), since by that point I had entirely lost creativity, and is a combination of crypto vulnerabilities: a padding oracle and a hash extension. The goal was to demonstrate the classic <a href='https://moxie.org/blog/the-cryptographic-doom-principle/'>Cryptographic Doom Principle</a>, by checking the signature AFTER decrypting, instead of before.

Like before, this challenge uses the <tt>user=</tt> cookie, but additionally the <tt>signature=</tt> cookie will need to be modified as well.

Here are the cookies:

<pre>
$ curl -s --head 'http://localhost:1234/' | grep 'Set-Cookie'
Set-Cookie: signature=e66764f9e71824ad37a46732fb49838e6b65a36bcb7235e9286f6ed5bd84dfa8; path=/; HttpOnly
Set-Cookie: user=e71606ae685181fefb03ad69309e6ad6b8f6a2e0ecc1dd08215bdf27e90c7399e8100767eee43fb6f403d41c733b856b53accf9d755d830d244501b088190adb; path=/; HttpOnly
Set-Cookie: rack.session=BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiRTE0ZDFlZWNmNjE5MjhhZTg3ZjQy%0AMzk5MGFhZjk0NGZiZDRkYjRjNTk1ODU0OTRkYzAyNzRlOWVjYmI1MGJmNGIG%0AOwBGSSILc2VjcmV0BjsARiINJB8WSMskiqBJIghrZXkGOwBGIiX%2Fz97Y3FAe%0AiIsMrhHmtd1Eh94IpIgj3FRdGcUcSKH0dg%3D%3D%0A; path=/; HttpOnly
</pre>

We'll have to maintain the <tt>rack.session</tt> cookie, since that's where our encryption keys are stored. We initially have no idea of what format the <tt>user=</tt> cookie decrypts to, and no matter how much you ask, I wasn't gonna tell you. You can, however, see a few fields if you look at the actual rendered page:

<pre>
Welcome to the mainframe!
It looks like you want to access the flag!
...
Please present user object
...
...scanning
...scanning
...
Scanning user object...
...your UID value is set to 57
...your NAME value is set to baseuser
...your SKILLS value is set to n/a
...
ERROR: ACCESS DENIED
...
UID MUST BE '0'
</pre>

If we refresh, those values are still present, so we can assume that they're encoded into that value somehow. The cookie is, it turns out, exactly 64 bytes long.

First, let's make sure we can properly request the page with <tt>curl</tt>:

<pre>
$ export RACK=BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiRTE0ZDFlZWNmNjE5MjhhZTg3ZjQy%0AMzk5MGFhZjk0NGZiZDRkYjRjNTk1ODU0OTRkYzAyNzRlOWVjYmI1MGJmNGIG%0AOwBGSSILc2VjcmV0BjsARiINJB8WSMskiqBJIghrZXkGOwBGIiX%2Fz97Y3FAe%0AiIsMrhHmtd1Eh94IpIgj3FRdGcUcSKH0dg%3D%3D%0A
$ export SIGNATURE=e66764f9e71824ad37a46732fb49838e6b65a36bcb7235e9286f6ed5bd84dfa8
$ export USER=e71606ae685181fefb03ad69309e6ad6b8f6a2e0ecc1dd08215bdf27e90c7399e8100767eee43fb6f403d41c733b856b53accf9d755d830d244501b088190adb
$ curl -s 'http://localhost:1234/' -H "Cookie: user=$USER; signature=$SIGNATURE; rack.session=$RACK"
[...]
   data.push("...your UID value is set to 52");
   data.push("...your NAME value is set to baseuser");
   data.push("...your SKILLS value is set to n/a");
[...]
</pre>

One of the first things I always try when I see an encrypted-looking cookie is to change the last byte and see what happens. Now that we have a working curl request, let's try that:

<pre>
$ export RACK=BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiRTE0ZDFlZWNmNjE5MjhhZTg3ZjQy%0AMzk5MGFhZjk0NGZiZDRkYjRjNTk1ODU0OTRkYzAyNzRlOWVjYmI1MGJmNGIG%0AOwBGSSILc2VjcmV0BjsARiINJB8WSMskiqBJIghrZXkGOwBGIiX%2Fz97Y3FAe%0AiIsMrhHmtd1Eh94IpIgj3FRdGcUcSKH0dg%3D%3D%0A
$ export SIGNATURE=e66764f9e71824ad37a46732fb49838e6b65a36bcb7235e9286f6ed5bd84dfa8
$ export USER=e71606ae685181fefb03ad69309e6ad6b8f6a2e0ecc1dd08215bdf27e90c7399e8100767eee43fb6f403d41c733b856b53accf9d755d830d244501b088190ade
$ curl -s 'http://localhost:1234/' -H "Cookie: user=$USER; signature=$SIGNATURE; rack.session=$RACK" | grep -i error
    data.push("FATAL ERROR: bad decrypt")
</pre>

The decrypt fails if we set the last byte wrong! What if we set it to each of the 256 possible bytes?

<pre>
$ export RACK=BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiRTE0ZDFlZWNmNjE5MjhhZTg3ZjQy%0AMzk5MGFhZjk0NGZiZDRkYjRjNTk1ODU0OTRkYzAyNzRlOWVjYmI1MGJmNGIG%0AOwBGSSILc2VjcmV0BjsARiINJB8WSMskiqBJIghrZXkGOwBGIiX%2Fz97Y3FAe%0AiIsMrhHmtd1Eh94IpIgj3FRdGcUcSKH0dg%3D%3D%0A
$ export SIGNATURE=e66764f9e71824ad37a46732fb49838e6b65a36bcb7235e9286f6ed5bd84dfa8

$ for i in `seq 0 255`; do export USER=e71606ae685181fefb03ad69309e6ad6b8f6a2e0ecc1dd08215bdf27e90c7399e8100767eee43fb6f403d41c733b856b53accf9d755d830d244501b088190a`printf '%02x' $i`; curl -s 'http://localhost:1234/' -H "Cookie: user=$USER; signature=$SIGNATURE; rack.session=$RACK" | grep -i 'error' | grep -v 'bad decrypt'; done
    data.push("FATAL ERROR: Bad signature!")
    data.push("ERROR: ACCESS DENIED");
</pre>

There are two errors that are NOT the usual "bad decrypt" one - one is "ACCESS DENIED" - our original - and the other is "Bad signature!". Hmm! This sounds an awful lot like a <a href='/2013/padding-oracle-attacks-in-depth'>padding oracle vulnerability</a>!

Fortunately, I've <a href='https://github.com/iagox86/poracle'>written a tool for this</a>!

Here's my Poracle configuration file (just a file called Solution.rb in the same folder as Poracle.rb):

<pre>
<span class="Comment"># encoding: ASCII-8BIT</span>

<span class="Comment">##</span>
<span class="Comment"># Demo.rb</span>
<span class="Comment"># Created: February 10, 2013</span>
<span class="Comment"># By: Ron Bowes</span>
<span class="Comment">#</span>
<span class="Comment"># A demo of how to use Poracle, that works against RemoteTestServer.</span>
<span class="Comment">##</span>

<span class="Include">require</span> <span class="rubyStringDelimiter">'</span><span class="String">./Poracle</span><span class="rubyStringDelimiter">'</span>
<span class="Include">require</span> <span class="rubyStringDelimiter">'</span><span class="String">httparty</span><span class="rubyStringDelimiter">'</span>
<span class="Include">require</span> <span class="rubyStringDelimiter">'</span><span class="String">singlogger</span><span class="rubyStringDelimiter">'</span>
<span class="Include">require</span> <span class="rubyStringDelimiter">'</span><span class="String">uri</span><span class="rubyStringDelimiter">'</span>

<span class="Comment"># Note: set this to DEBUG to get full full output</span>
<span class="rubyConstant">SingLogger</span>.set_level_from_string(<span class="rubySymbol">level</span>: <span class="rubyStringDelimiter">&quot;</span><span class="String">DEBUG</span><span class="rubyStringDelimiter">&quot;</span>)
<span class="rubyConstant">L</span> = <span class="rubyConstant">SingLogger</span>.instance()

<span class="Comment"># 16 is good for AES and 8 for DES</span>
<span class="rubyConstant">BLOCKSIZE</span> = <span class="Number">16</span>

<span class="Statement">def</span> <span class="Function">request</span>(cookies)
  <span class="Statement">return</span> <span class="rubyConstant">HTTParty</span>.get(
    <span class="rubyStringDelimiter">'</span><span class="String"><a href="http://localhost:1234/">http://localhost:1234/</a></span><span class="rubyStringDelimiter">'</span>,
    <span class="rubySymbol">follow_redirects</span>: <span class="Boolean">false</span>,
    <span class="rubySymbol">headers</span>: {
      <span class="rubyStringDelimiter">'</span><span class="String">Cookie</span><span class="rubyStringDelimiter">'</span> =&gt; <span class="rubyStringDelimiter">&quot;</span><span class="String">signature=</span><span class="rubyInterpolationDelimiter">#{</span>cookies[<span class="rubySymbol">:</span><span class="rubySymbol">signature</span>]<span class="rubyInterpolationDelimiter">}</span><span class="String">; user=</span><span class="rubyInterpolationDelimiter">#{</span>cookies[<span class="rubySymbol">:</span><span class="rubySymbol">user</span>]<span class="rubyInterpolationDelimiter">}</span><span class="String">; rack.session=</span><span class="rubyInterpolationDelimiter">#{</span>cookies[<span class="rubySymbol">:</span><span class="rubySymbol">session</span>]<span class="rubyInterpolationDelimiter">}</span><span class="rubyStringDelimiter">&quot;</span>
    }
  )
<span class="Statement">end</span>

<span class="Statement">def</span> <span class="Function">get_cookies</span>()
  reset = <span class="rubyConstant">HTTParty</span>.head(<span class="rubyStringDelimiter">'</span><span class="String"><a href="http://localhost:1234/?action=reset">http://localhost:1234/?action=reset</a></span><span class="rubyStringDelimiter">'</span>, <span class="rubySymbol">follow_redirects</span>: <span class="Boolean">false</span>)
  cookies = reset.headers[<span class="rubyStringDelimiter">'</span><span class="String">Set-Cookie</span><span class="rubyStringDelimiter">'</span>]

  <span class="Statement">return</span> {
    <span class="rubySymbol">signature</span>: cookies.scan(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">signature=</span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9a-f</span><span class="Special">]</span><span class="Special">*</span><span class="Special">)</span><span class="rubyStringDelimiter">/</span>).pop.pop,
    <span class="rubySymbol">user</span>:      cookies.scan(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">user=</span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9a-f</span><span class="Special">]</span><span class="Special">*</span><span class="Special">)</span><span class="rubyStringDelimiter">/</span>).pop.pop,
    <span class="rubySymbol">session</span>:   cookies.scan(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">rack</span><span class="Special">\.</span><span class="rubyRegexp">session=</span><span class="Special">(</span><span class="Special">[^</span><span class="rubyRegexp">;</span><span class="Special">]</span><span class="Special">*</span><span class="Special">)</span><span class="rubyStringDelimiter">/</span>).pop.pop,
  }
<span class="Statement">end</span>

<span class="Comment"># Get the initial set of cookies</span>
<span class="rubyConstant">COOKIES</span> = get_cookies()

<span class="Comment"># This is the do_decrypt block - you'll have to change it depending on what your</span>
<span class="Comment"># service is expecting (eg, by adding cookies, making a POST request, etc)</span>
poracle = <span class="rubyConstant">Poracle</span>.new(<span class="rubyConstant">BLOCKSIZE</span>) <span class="Statement">do</span> |data|
  cookies = <span class="rubyConstant">COOKIES</span>.clone()
  cookies[<span class="rubySymbol">:</span><span class="rubySymbol">user</span>] = data.unpack(<span class="rubyStringDelimiter">&quot;</span><span class="String">H*</span><span class="rubyStringDelimiter">&quot;</span>).pop

  result = request(cookies)
  <span class="Comment">#result.parsed_response.force_encoding(&quot;ASCII-8BIT&quot;)</span>

  <span class="Comment"># Split the response and find any line containing error / exception / fail</span>
  <span class="Comment"># (case insensitive)</span>
  errors = result.parsed_response.split(<span class="rubyStringDelimiter">/</span><span class="Special">\n</span><span class="rubyStringDelimiter">/</span>).select { |l| l =~ <span class="rubyStringDelimiter">/</span><span class="rubyRegexp">bad decrypt</span><span class="rubyStringDelimiter">/i</span> }

  <span class="Comment"># Return true if there are zero errors</span>
  errors.empty?
<span class="Statement">end</span>

data = <span class="rubyConstant">COOKIES</span>[<span class="rubySymbol">:</span><span class="rubySymbol">user</span>]

<span class="rubyConstant">L</span>.info(<span class="rubyStringDelimiter">&quot;</span><span class="String">Trying to decrypt: %s</span><span class="rubyStringDelimiter">&quot;</span> % data)

<span class="Comment"># Convert to a binary string using pack</span>
data = [data].pack(<span class="rubyStringDelimiter">&quot;</span><span class="String">H*</span><span class="rubyStringDelimiter">&quot;</span>)

result = poracle.decrypt_with_embedded_iv(data)

<span class="Comment"># Print the decryption result</span>
puts(<span class="rubyStringDelimiter">&quot;</span><span class="String">-----------------------------</span><span class="rubyStringDelimiter">&quot;</span>)
puts(<span class="rubyStringDelimiter">&quot;</span><span class="String">Decryption result</span><span class="rubyStringDelimiter">&quot;</span>)
puts(<span class="rubyStringDelimiter">&quot;</span><span class="String">-----------------------------</span><span class="rubyStringDelimiter">&quot;</span>)
puts result
puts(<span class="rubyStringDelimiter">&quot;</span><span class="String">-----------------------------</span><span class="rubyStringDelimiter">&quot;</span>)
</pre>

If I run it, it outputs:

<pre>
$ ruby ./Solution.rb
I, [2019-03-10T14:57:29.516523 #24889]  INFO -- : Starting Poracle with blocksize = 16
I, [2019-03-10T14:57:29.516584 #24889]  INFO -- : Trying to decrypt: 02e16b251f7077786a2bba0d82ce1e4fab04a1a088c681ed493156fb7ef14a7a20b0f63c99a74249f9c04192da896ae0b4105ea7e187de2d960ec95f5de6bbaa
I, [2019-03-10T14:57:29.516604 #24889]  INFO -- : Grabbing the IV from the first block...
I, [2019-03-10T14:57:29.519956 #24889]  INFO -- : Starting Poracle decryptor...
D, [2019-03-10T14:57:29.520023 #24889] DEBUG -- : Encrypted length: 64
D, [2019-03-10T14:57:29.520037 #24889] DEBUG -- : Blocksize: 16
D, [2019-03-10T14:57:29.520047 #24889] DEBUG -- : 4 blocks:
D, [2019-03-10T14:57:29.520070 #24889] DEBUG -- : Block 1: ["02e16b251f7077786a2bba0d82ce1e4f"]
D, [2019-03-10T14:57:29.520085 #24889] DEBUG -- : Block 2: ["ab04a1a088c681ed493156fb7ef14a7a"]
D, [2019-03-10T14:57:29.520098 #24889] DEBUG -- : Block 3: ["20b0f63c99a74249f9c04192da896ae0"]
D, [2019-03-10T14:57:29.520110 #24889] DEBUG -- : Block 4: ["b4105ea7e187de2d960ec95f5de6bbaa"]
...
[... lots of output ...]
...
-----------------------------
Decryption result
-----------------------------
UID 53
NAME baseuser
SKILLS n/a
-----------------------------
</pre>

Aha, that's what the decrypted block looks like! Keep in mind that Poracle started its own session, so the values are different than they were earlier.

What we want to do is append a <tt>UID 0</tt> to the bottom:

<pre>
UID 53
NAME baseuser
SKILLS n/a
UID 0
</pre>

But if we just use the padding oracle to encrypt that, we'll get an "Invalid Signature" error. Fortunately, this is also vulnerable to hash length extension! And, also fortunately, I <a href='https://github.com/iagox86/hash_extender'>wrote a tool for this, too</a>, along with a <a href='https://blog.skullsecurity.org/2012/everything-you-need-to-know-about-hash-length-extension-attacks'>super detailed blog</a> about the attack!

I added the following code to the bottom of Solution.rb:

<pre>
<span class="Comment"># Write it to a file</span>
<span class="rubyConstant">File</span>.open(<span class="rubyStringDelimiter">&quot;</span><span class="String">/tmp/decrypt</span><span class="rubyStringDelimiter">&quot;</span>, <span class="rubyStringDelimiter">&quot;</span><span class="String">wb</span><span class="rubyStringDelimiter">&quot;</span>) <span class="Statement">do</span> |f|
  f.write(result)
<span class="Statement">end</span>

<span class="Comment"># Call out to hash_extender and pull out the new data</span>
append = <span class="rubyStringDelimiter">&quot;</span><span class="Special">\n</span><span class="String">UID 0</span><span class="Special">\n</span><span class="rubyStringDelimiter">&quot;</span>.unpack(<span class="rubyStringDelimiter">&quot;</span><span class="String">H*</span><span class="rubyStringDelimiter">&quot;</span>).pop
out = <span class="rubyStringDelimiter">`</span><span class="String">./hash_extender --file=/tmp/decrypt -s </span><span class="rubyInterpolationDelimiter">#{</span><span class="rubyConstant">COOKIES</span>[<span class="rubySymbol">:</span><span class="rubySymbol">signature</span>]<span class="rubyInterpolationDelimiter">}</span><span class="String"> -a '</span><span class="rubyInterpolationDelimiter">#{</span>append<span class="rubyInterpolationDelimiter">}</span><span class="String">' --append-format=hex -f sha256 -l 8</span><span class="rubyStringDelimiter">`</span>
new_signature = out.scan(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">New signature: </span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9a-f</span><span class="Special">]</span><span class="Special">*</span><span class="Special">)</span><span class="rubyStringDelimiter">/</span>).pop.pop
new_data = out.scan(<span class="rubyStringDelimiter">/</span><span class="rubyRegexp">New string: </span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9a-f</span><span class="Special">]</span><span class="Special">*</span><span class="Special">)</span><span class="rubyStringDelimiter">/</span>).pop.pop
</pre>

This dumps the decrypted data to a file, <tt>/tmp/decrypt</tt>. It then appends "\nUID 0\n" using hash_extender, and grabs the new signature/data.

Then, finally, we add a call to <tt>poracle.encrypt</tt> to re-encrypt the data:

<pre>
<span class="Comment"># Call out to Poracle to encrypt the new data</span>
new_encrypted_data = poracle.encrypt([new_data].pack(<span class="rubyStringDelimiter">'</span><span class="String">H*</span><span class="rubyStringDelimiter">'</span>))

<span class="Comment"># Perform the request to get the flag</span>
cookies = <span class="rubyConstant">COOKIES</span>.clone
cookies[<span class="rubySymbol">:</span><span class="rubySymbol">user</span>] = new_encrypted_data.unpack(<span class="rubyStringDelimiter">&quot;</span><span class="String">H*</span><span class="rubyStringDelimiter">&quot;</span>).pop
cookies[<span class="rubySymbol">:</span><span class="rubySymbol">signature</span>] = new_signature
puts(request(cookies))
</pre>

If you let the whole thing run, you'll first note that the encryption takes a whole lot longer than the decryption did. That's because it can't optimize for "probably English letters" going that way.

But eventually, it'll finish and print out the whole page, including:

<pre>
...
  data.<span class="jsFuncCall">push</span>(<span class="String">&quot;...your UID value is set to 0&quot;</span>);
  data.<span class="jsFuncCall">push</span>(<span class="String">&quot;...your NAME value is set to baseuser&quot;</span>);
  data.<span class="jsFuncCall">push</span>(<span class="String">&quot;...your SKILLS value is set to n/a&quot;</span>);
  data.<span class="jsFuncCall">push</span>(<span class="String">&quot;...your �@ value is set to &quot;</span>);
  data.<span class="jsFuncCall">push</span>(<span class="String">&quot;FLAG VALUE: &lt;span class='highlight'&gt;CTF{parse_order_matters}&lt;/span&gt;&lt;/p&gt;&quot;</span>);
...
</pre>

And that's the end of the crypto challenges! Definitely read my posts on padding oracles and hash extension, since I dive into deep detail!
