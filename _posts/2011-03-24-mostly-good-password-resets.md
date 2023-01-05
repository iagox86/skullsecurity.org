---
id: 1088
title: "(Mostly) good password resets"
date: '2011-03-24T08:08:16-05:00'
author: ron
layout: post
guid: http://www.skullsecurity.org/blog/?p=1088
permalink: "/2011/mostly-good-password-resets"
categories:
- hacking
- passwords
comments_id: '109638357819617642'

---

Hey everybody!

This is part 3 to my 2-part series on password reset attacks (<a href='http://www.skullsecurity.org/blog/2011/hacking-crappy-password-resets-part-1'>Part 1</a> / <a href='http://www.skullsecurity.org/blog/2011/hacking-crappy-password-resets-part-2'>Part 2</a>). Overall, I got awesome feedback on the first two parts, but I got the same question over and over: what's the RIGHT way to do this?

So, here's the thing. I like to break stuff, but I generally leave the fixing to somebody else. It's just safer that way, since I'm not really a developer or anything like that.  Instead, I'm going to continue the trend of looking at others' implementations by looking at three major opensource projects - Wordpress, SMF, and MediaWiki. Then, since all of these rely on PHP's random number implementation to some extent, I'll take a brief look at PHP. 
<!--more-->
<h2>SMF</h2>
<a href='http://www.simplemachines.org/'>SMF</a> 1.1.13 implements the password-reset function in Sources/Subs-Auth.php:
<pre>
&nbsp;&nbsp;<font color="#80a0ff">// Generate a random password.</font><br>
&nbsp;&nbsp;<font color="#ff80ff">require_once</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">sourcedir</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;'<font color="#ffa0a0">/Subs-Members.php</font>'<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">newPassword</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;generateValidationCode<font color="#ffa500">()</font>;<br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">newPassword_sha1</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#40ffff">strtolower</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">user</font><font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">newPassword</font><font color="#ffa500">)</font>;<br></pre>

Looking at Sources/Subs-Members.php, we find:
<pre>
<font color="#80a0ff">// Generate a random validation code.</font><br>
<font color="#ff80ff">function</font>&nbsp;generateValidationCode<font color="#ffa500">()</font><br>
<font color="#ffa500">{</font><br>
&nbsp;&nbsp;<font color="#60ff60"><b>global</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">modSettings</font>;<br>
<br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">request</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;db_query<font color="#ffa500">(</font>'<br>
<font color="#ffa0a0">&nbsp;&nbsp;&nbsp;&nbsp;SELECT RAND()</font>', <font color="#ffa0a0">__FILE__</font>, <font color="#ffa0a0">__LINE__</font><font color="#ffa500">)</font>;<br>
<br>
&nbsp;&nbsp;<font color="#60ff60"><b>list</b></font>&nbsp;<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">dbRand</font><font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">mysql_fetch_row</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">request</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;<font color="#40ffff">mysql_free_result</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">request</font><font color="#ffa500">)</font>;<br>
<br>
&nbsp;&nbsp;<font color="#ffff60"><b>return</b></font>&nbsp;<font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#40ffff">preg_replace</font><font color="#ffa500">(</font>'<font color="#ffa0a0">/\W/</font>', '', <font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#40ffff">microtime</font><font color="#ffa500">()</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#40ffff">mt_rand</font><font color="#ffa500">()</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">dbRand</font>&nbsp;<font color="#ffff60"><b>.</b></font><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">modSettings</font><font color="#ffa500">[</font>'<font color="#ffa0a0">rand_seed</font>'<font color="#ffa500">]))</font>, <font color="#ffa0a0">0</font>, <font color="#ffa0a0">10</font><font color="#ffa500">)</font>;<br>
<font color="#ffa500">}</font><br>
</pre>

Which is pretty straight forward, but also, in my opinion, very strong. It takes entropy from a bunch of different places:
<ul>
<li>The current time (microtime())</li>
<li>PHP's random number generator (mt_rand())</li>
<li>MySQL's random number generator ($dbRand)</li>
<li>A user-configurable random seed</li>
</ul>

Essentially, it puts these difficult-to-guess values through a cryptographically secure function, sha1(), and takes the first 10 characters of the hash. 

The hash consists of lowercase letters and numbers, which means there are 36 possible choices for 10 characters, for a total of 36<sup>10</sup> or 3,656,158,440,062,976 possible outputs. That isn't as strong as it *could* be, since there's no reason to limit its length to 10 characters (or its character set to 36 characters). That being said, three quadrillion different passwords would be nearly impossible to guess. (By my math, exhaustively cracking all possible passwords, assuming md5 cracks at 5 million guesses/second, would take about 23 CPU-years). Not that cracking is terribly useful - remote bruteforce guessing is much more useful and is clearly impossible.

SMF is my favourite implementation of the three, but let's take a look at Wordpress!

<h2>Wordpress</h2>
<a href='http://wordpress.org/'>Wordpress</a> 3.1 implements the password-reset function in wp-login.php:
<pre>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-&gt;</b></font>get_var<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-&gt;</b></font>prepare<font color="#ffa500">(</font>&quot;<font color="#ffa0a0">SELECT user_activation_key FROM</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-&gt;</b></font>users<font color="#ffa0a0">&nbsp;WHERE user_login = %s</font>&quot;, <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_login</font><font color="#ffa500">))</font>;<br>
&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>empty</b></font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font><font color="#ffa500">)</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">{</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#80a0ff">// Generate something random for a key...</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;wp_generate_password<font color="#ffa500">(</font><font color="#ffa0a0">20</font>, <font color="#ffa0a0">false</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;do_action<font color="#ffa500">(</font>'<font color="#ffa0a0">retrieve_password_key</font>', <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_login</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#80a0ff">// Now insert the new md5 key into the db</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-&gt;</b></font>update<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-&gt;</b></font>users, <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font>'<font color="#ffa0a0">user_activation_key</font>'&nbsp;<font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>&gt;</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font><font color="#ffa500">)</font>, 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font>'<font color="#ffa0a0">user_login</font>'&nbsp;<font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>&gt;</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">user_login</font><font color="#ffa500">))</font>;<br>
&nbsp;&nbsp;<font color="#ffa500">}</font><br>
</pre>

wp_generate_password() is found in wp-includes/pluggable.php:
<pre>
<font color="#80a0ff">/**</font><br>
<font color="#80a0ff">&nbsp;* Generates a random password drawn from the defined set of characters.</font><br>
<font color="#80a0ff">&nbsp;*</font><br>
<font color="#80a0ff">&nbsp;* @since 2.5</font><br>
<font color="#80a0ff">&nbsp;*</font><br>
<font color="#80a0ff">&nbsp;* @param int $length The length of password to generate</font><br>
<font color="#80a0ff">&nbsp;* @param bool $special_chars Whether to include standard special characters.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Default true.</font><br>
<font color="#80a0ff">&nbsp;* @param bool $extra_special_chars Whether to include other special characters.</font><br>
<font color="#80a0ff">&nbsp;*&nbsp;&nbsp; Used when generating secret keys and salts. Default false.</font><br>
<font color="#80a0ff">&nbsp;* @return string The random password</font><br>
<font color="#80a0ff">&nbsp;**/</font><br>
<font color="#ff80ff">function</font>&nbsp;wp_generate_password<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffa0a0">12</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">special_chars</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffa0a0">true</font>, <font color="#ffff60"><b>$</b></font>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#40ffff">extra_special_chars</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffa0a0">false</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">{</font><br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;'<font color="#ffa0a0">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789</font>';<br>
&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">special_chars</font>&nbsp;<font color="#ffa500">)</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>&nbsp;<font color="#ffff60"><b>.=</b></font>&nbsp;'<font color="#ffa0a0">!@#$%^&amp;*()</font>';<br>
&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">extra_special_chars</font>&nbsp;<font color="#ffa500">)</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>&nbsp;<font color="#ffff60"><b>.=</b></font>&nbsp;'<font color="#ffa0a0">-_ []{}&lt;&gt;~`+=,.;:/?|</font>';<br>
<br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">password</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;'';<br>
&nbsp;&nbsp;<font color="#ffff60"><b>for</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font>&nbsp;<font color="#ffff60"><b>&lt;</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">{</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">password</font>&nbsp;<font color="#ffff60"><b>.=</b></font>&nbsp;<font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>, wp_rand<font color="#ffa500">(</font><font color="#ffa0a0">0</font>, <font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font><font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>-</b></font>&nbsp;<font color="#ffa0a0">1</font><font color="#ffa500">)</font>, <font color="#ffa0a0">1</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;<font color="#ffa500">}</font><br>
<br>
&nbsp;&nbsp;<font color="#80a0ff">// random_password filter was previously in random_password function which was
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;deprecated</font><br>
&nbsp;&nbsp;<font color="#ffff60"><b>return</b></font>&nbsp;apply_filters<font color="#ffa500">(</font>'<font color="#ffa0a0">random_password</font>', <font color="#ffff60"><b>$</b></font><font color="#40ffff">password</font><font color="#ffa500">)</font>;<br>
<font color="#ffa500">}</font><br>
</pre>

This generates a string of random characters (and possibly symbols) up to a defined length, choosing the characters using wp_rand(). So, for the final step, how is wp_rand() implemented? It's also found in wp-includes/pluggable.php and looks like this:
<pre>
&nbsp;&nbsp;<font color="#60ff60"><b>global</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>;<br>
<br>
&nbsp;&nbsp;<font color="#80a0ff">// Reset $rnd_value after 14 uses</font><br>
&nbsp;&nbsp;<font color="#80a0ff">// 32(md5) + 40(sha1) + 40(sha1) / 8 = 14 random numbers from $rnd_value</font><br>
&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font><font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>&lt;</b></font>&nbsp;<font color="#ffa0a0">8</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">{</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#40ffff">defined</font><font color="#ffa500">(</font>&nbsp;'<font color="#ffa0a0">WP_SETUP_CONFIG</font>'&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">)</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#60ff60"><b>static</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;'';<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>else</b></font><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;get_transient<font color="#ffa500">(</font>'<font color="#ffa0a0">random_seed</font>'<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">md5</font><font color="#ffa500">(</font>&nbsp;<font color="#40ffff">uniqid</font><font color="#ffa500">(</font><font color="#40ffff">microtime</font><font color="#ffa500">()</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#40ffff">mt_rand</font><font color="#ffa500">()</font>, <font color="#ffa0a0">true</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font>&nbsp;<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>&nbsp;<font color="#ffff60"><b>.=</b></font>&nbsp;<font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>&nbsp;<font color="#ffff60"><b>.=</b></font>&nbsp;<font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">md5</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>!</b></font>&nbsp;<font color="#40ffff">defined</font><font color="#ffa500">(</font>&nbsp;'<font color="#ffa0a0">WP_SETUP_CONFIG</font>'&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">)</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;set_transient<font color="#ffa500">(</font>'<font color="#ffa0a0">random_seed</font>', <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font><font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;<font color="#ffa500">}</font><br>
<br>
&nbsp;&nbsp;<font color="#80a0ff">// Take the first 8 digits for our value</font><br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>, <font color="#ffa0a0">0</font>, <font color="#ffa0a0">8</font><font color="#ffa500">)</font>;<br>
<br>
&nbsp;&nbsp;<font color="#80a0ff">// Strip the first eight, leaving the remainder for the next call to wp_rand().</font><br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>, <font color="#ffa0a0">8</font><font color="#ffa500">)</font>;<br>
<br>
&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">abs</font><font color="#ffa500">(</font><font color="#40ffff">hexdec</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font><font color="#ffa500">))</font>;<br>
<br>
&nbsp;&nbsp;<font color="#80a0ff">// Reduce the value to be within the min - max range</font><br>
&nbsp;&nbsp;<font color="#80a0ff">// 4294967295 = 0xffffffff = max random number</font><br>
&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">max</font>&nbsp;<font color="#ffff60"><b>!=</b></font>&nbsp;<font color="#ffa0a0">0</font>&nbsp;<font color="#ffa500">)</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">min</font>&nbsp;<font color="#ffff60"><b>+</b></font>&nbsp;<font color="#ffa500">((</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">max</font>&nbsp;<font color="#ffff60"><b>-</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">min</font>&nbsp;<font color="#ffff60"><b>+</b></font>&nbsp;<font color="#ffa0a0">1</font><font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>*</b></font>&nbsp;<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font>&nbsp;<font color="#ffff60"><b>/</b></font>&nbsp;<font color="#ffa500">(</font><font color="#ffa0a0">4294967295</font>&nbsp;<font color="#ffff60"><b>+</b></font>&nbsp;<font color="#ffa0a0">1</font><font color="#ffa500">)))</font>;<br>
<br>
&nbsp;&nbsp;<font color="#ffff60"><b>return</b></font>&nbsp;<font color="#40ffff">abs</font><font color="#ffa500">(</font><font color="#40ffff">intval</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font><font color="#ffa500">))</font>;<br>
<font color="#ffa500">}</font><br>
</pre>
This is quite complex for generating a number! But the points of interest are:
<ul>
<li>Hashing functions (sha1 and md5) are used, which are going to be <em>a lot</em> slower than a standard generator, but they, at least in theory, have cryptographic strength</li>
<li>The random number is seeded with microtime() and mt_rand(), which is PHP's "advanced" randomization function)</li>
<li>The random number is restricted to 0 - 0xFFFFFFFF, which is pretty typical</li>
</ul>

In practice, due to the multiple seeds with difficult-to-predict values and the use of a hashing function to generate strong random numbers, this seems to be a good implementation of a password reset. My biggest concern is the complexity - using multiple hashing algorithms and hashing in odd ways (like hasing the value alone, then the hash with the seed). It has the feeling of being unsure what to do, so trying to do everything 'just in case'. While I don't expect to find any weaknesses in the implementation, it's a little concerning. 

Now, let's take a look at my least favourite (although still reasonably strong) password-reset implementation: MediaWiki!
<h2>MediaWiki</h2>
<a href='http://www.mediawiki.org/'>MediaWiki</a> 1.16.2 was actually the most difficult to find the password reset function in. Eventually, though, I managed to track it down to includes/specials/SpecialUserlogin.php:
<pre>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-&gt;</b></font>randomPassword<font color="#ffa500">()</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-&gt;</b></font>setNewpassword<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">throttle</font>&nbsp;<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-&gt;</b></font>saveSettings<font color="#ffa500">()</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">userLanguage</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-&gt;</b></font>getOption<font color="#ffa500">(</font>&nbsp;'<font color="#ffa0a0">language</font>'&nbsp;<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">m</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;wfMsgExt<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">emailText</font>, <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font>&nbsp;'<font color="#ffa0a0">parsemag</font>', '<font color="#ffa0a0">language</font>'&nbsp;<font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>&gt;</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">userLanguage</font>&nbsp;<font color="#ffa500">)</font>, 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">ip</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-&gt;</b></font>getName<font color="#ffa500">()</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>,<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wgServer</font>&nbsp;<font color="#ffff60"><b>.</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wgScript</font>, <font color="#40ffff">round</font><font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wgNewPasswordExpiry</font>&nbsp;<font color="#ffff60"><b>/</b></font>&nbsp;<font color="#ffa0a0">86400</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">result</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-&gt;</b></font>sendMail<font color="#ffa500">(</font>&nbsp;wfMsgExt<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">emailTitle</font>, <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font>&nbsp;'<font color="#ffa0a0">parsemag</font>', 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'<font color="#ffa0a0">language</font>'&nbsp;<font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>&gt;</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">userLanguage</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">)</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">m</font>&nbsp;<font color="#ffa500">)</font>;<br>
</pre>

$u->randomPassword() is found in includes/User.php looks like this:
<pre>
&nbsp;&nbsp;<font color="#80a0ff">/**</font><br>
<font color="#80a0ff">&nbsp;&nbsp; * Return a random password. Sourced from mt_rand, so it's not particularly secure.</font><br>
<font color="#80a0ff">&nbsp;&nbsp; * @</font><span style="background-color: #ffff00"><font color="#0000ff">todo</font></span><font color="#80a0ff">&nbsp;hash random numbers to improve security, like generateToken()</font><br>
<font color="#80a0ff">&nbsp;&nbsp; *</font><br>
<font color="#80a0ff">&nbsp;&nbsp; * @return \string New random password</font><br>
<font color="#80a0ff">&nbsp;&nbsp; */</font><br>
&nbsp;&nbsp;<font color="#60ff60"><b>static</b></font>&nbsp;<font color="#ff80ff">function</font>&nbsp;randomPassword<font color="#ffa500">()</font>&nbsp;<font color="#ffa500">{</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#60ff60"><b>global</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">wgMinimalPasswordLength</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">pwchars</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;'<font color="#ffa0a0">ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz</font>';<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">l</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">strlen</font><font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">pwchars</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>-</b></font>&nbsp;<font color="#ffa0a0">1</font>;<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">pwlength</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">max</font><font color="#ffa500">(</font>&nbsp;<font color="#ffa0a0">7</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">wgMinimalPasswordLength</font>&nbsp;<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">digit</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#40ffff">mt_rand</font><font color="#ffa500">(</font>&nbsp;<font color="#ffa0a0">0</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwlength</font>&nbsp;<font color="#ffff60"><b>-</b></font>&nbsp;<font color="#ffa0a0">1</font>&nbsp;<font color="#ffa500">)</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;'';<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>for</b></font>&nbsp;<font color="#ffa500">(</font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font>&nbsp;<font color="#ffff60"><b>=</b></font>&nbsp;<font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font>&nbsp;<font color="#ffff60"><b>&lt;</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">pwlength</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">{</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>&nbsp;<font color="#ffff60"><b>.=</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font>&nbsp;<font color="#ffff60"><b>==</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">digit</font>&nbsp;<font color="#ffff60"><b>?</b></font>&nbsp;<font color="#40ffff">chr</font><font color="#ffa500">(</font>&nbsp;<font color="#40ffff">mt_rand</font><font color="#ffa500">(</font>&nbsp;<font color="#ffa0a0">48</font>, <font color="#ffa0a0">57</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffff60"><b>:</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">pwchars</font><font color="#ffa500">{</font>&nbsp;<font color="#40ffff">mt_rand</font><font color="#ffa500">(</font>&nbsp;<font color="#ffa0a0">0</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">l</font>&nbsp;<font color="#ffa500">)</font>&nbsp;<font color="#ffa500">}</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffa500">}</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>return</b></font>&nbsp;<font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>;<br>
&nbsp;&nbsp;<font color="#ffa500">}</font><br>
</pre>

This is easily the most complex, and also most dangerous, password-reset implementation that I've found.

First, the length is only 7 characters by default. That's already an issue.

Second, the set of characters is letters (uppercase + lowercase) and exactly one number. And it looks to me like they put a lot of effort into figuring out just how to put that one number into the password. Initially, I thought this made the password slightly weaker due to the following calculations:
<ul>
<li>7 characters @ 52 choices = 52<sup>7</sup> = 1,028,071,702,528</li>
<li>6 characters @ 52 choices + 1 character @ 10 choices = 52<sup>6</sup> * 10 = 197,706,096,640</li>
</ul>

However, as my friend pointed out, because you don't know where, exactly, the number will be placed, that actually adds an extra multiplier to the strength:
<ul>
<li>6 characters @ 52 choices + 1 characters @ 10 choices + unknown number location = 52<sup>6</sup> * 10 * 7 = 1,383,942,676,480</li>
</ul>

So, in reality, adding a single number does improve the strength, but only by a bit.

Even with the extra number, though, the best we have at 7 characters is about 1.4 trillion choices. As with the others, that's essentially impossible to guess/bruteforce remotely. That's a good thing. However, with a password cracker and 5 million checks/second, it would take a little over 3.2 CPU-days to exhaustively crack all generated passwords, so that can very easily be achieved.

The other issue here is that the only source of entropy is PHP's mt_rand() function. The next section will look at how PHP seeds this function.

<h2>PHP</h2>
All three of these implementations depend, in one way or another, on <a href='http://www.php.net/'>PHP</a>'s mt_rand() function. The obvious question is, how strong is mt_rand()?

I'm only going to look at this from a high level for now. When I have some more time, I'm hoping to dig deeper into this and, with luck, bust it wide open. Stay tuned for that. :)

For now, though, let's look at the function that's used by all three password-reset functions: mt_rand(). mt_rand() is an implementation of the <a href='https://secure.wikimedia.org/wikipedia/en/wiki/Mersenne_Twister'>Mersenne Twister</a> algorithm, which is a well tested random number generator with an advertised average period of 2<sup>19937</sup>-1. That means that it won't repeat until 2<sup>19937</sup>-1 values are generated. I don't personally have the skills to analyze the strength of the algorithm itself, but what I CAN look at is the seed. 

Whether using rand() or mt_rand(), PHP automatically seeds the random number generator. The code is in ext/standard/rand.c, and looks like this:
<pre>
PHPAPI <font color="#60ff60"><b>long</b></font>&nbsp;php_rand(TSRMLS_D)<br>
{<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#60ff60"><b>long</b></font>&nbsp;ret;<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;(!BG(rand_is_seeded)) {<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;php_srand(GENERATE_SEED() TSRMLS_CC);<br>
&nbsp;&nbsp;&nbsp;&nbsp;}<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#80a0ff">// ...</font><br>
}<br>
</pre>

Simple enough - if rand() is called without a seed, then seed it with the GENERATE_SEED() macro, which is found in ext/standard/php_rand.h:
<pre>
<font color="#ff80ff">#ifdef PHP_WIN32</font><br>
<font color="#ff80ff">#define GENERATE_SEED() (((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">) (time(</font><font color="#ffa0a0">0</font><font color="#ff80ff">) * GetCurrentProcessId())) ^ <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">)<br>(</font><font color="#ffa0a0">1000000.0</font><font color="#ff80ff">&nbsp;* php_combined_lcg(TSRMLS_C))))</font><br>
<font color="#ff80ff">#else</font><br>
<font color="#ff80ff">#define GENERATE_SEED() (((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">) (time(</font><font color="#ffa0a0">0</font><font color="#ff80ff">) * getpid())) ^ <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">) (</font><font color="#ffa0a0">1000000.0</font><font color="#ff80ff">&nbsp;* php_combined_lcg(TSRMLS_C))))</font><br>
<font color="#ff80ff">#endif</font><br>
</pre>

So it's seeded with the current time() (known), process id (weak), and php_combined_lcg(). What the heck is php_combined_lcg? Well, an LCG is a Linear Congruential Generator, a type of random number generator, and it's defined at ext/standard/lcg.c so let's take a look:

{% raw %}
<pre>
PHPAPI <font color="#60ff60"><b>double</b></font>&nbsp;php_combined_lcg(TSRMLS_D) <font color="#80a0ff">/*</font><font color="#80a0ff">&nbsp;{{{ </font><font color="#80a0ff">*/</font><br>
{<br>
&nbsp;&nbsp;&nbsp;&nbsp;php_int32 q;<br>
&nbsp;&nbsp;&nbsp;&nbsp;php_int32 z;<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;(!LCG(seeded)) {<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lcg_seed(TSRMLS_C);<br>
&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;MODMULT(<font color="#ffa0a0">53668</font>, <font color="#ffa0a0">40014</font>, <font color="#ffa0a0">12211</font>, <font color="#ffa0a0">2147483563L</font>, LCG(s1));<br>
&nbsp;&nbsp;&nbsp;&nbsp;MODMULT(<font color="#ffa0a0">52774</font>, <font color="#ffa0a0">40692</font>, <font color="#ffa0a0">3791</font>, <font color="#ffa0a0">2147483399L</font>, LCG(s2));<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;z = LCG(s1) - LCG(s2);<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;(z &lt; <font color="#ffa0a0">1</font>) {<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;z += <font color="#ffa0a0">2147483562</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>return</b></font>&nbsp;z * <font color="#ffa0a0">4.656613e-10</font>;<br>
}<br>
</pre>
{% endraw %}

This function also needs to be seeded! It's pretty funny to seed a random number generator with another random number generator - what, exactly, does that improve?

Here is what lcg_seed(), in the same file, looks like:

{% raw %}
<pre>
<font color="#60ff60"><b>static</b></font>&nbsp;<font color="#60ff60"><b>void</b></font>&nbsp;lcg_seed(TSRMLS_D) <font color="#80a0ff">/*</font><font color="#80a0ff">&nbsp;{{{ </font><font color="#80a0ff">*/</font><br>
{<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#60ff60"><b>struct</b></font>&nbsp;timeval tv;<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;(gettimeofday(&amp;tv, <font color="#ffa0a0">NULL</font>) == <font color="#ffa0a0">0</font>) {<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LCG(s1) = tv.tv_sec ^ (tv.tv_usec&lt;&lt;<font color="#ffa0a0">11</font>);<br>
&nbsp;&nbsp;&nbsp;&nbsp;} <font color="#ffff60"><b>else</b></font>&nbsp;{<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LCG(s1) = <font color="#ffa0a0">1</font>;<br>
&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ff80ff">#ifdef ZTS</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;LCG(s2) = (<font color="#60ff60"><b>long</b></font>) tsrm_thread_id();<br>
<font color="#ff80ff">#else</font>&nbsp;<br>
&nbsp;&nbsp;&nbsp;&nbsp;LCG(s2) = (<font color="#60ff60"><b>long</b></font>) getpid();<br>
<font color="#ff80ff">#endif</font><br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#80a0ff">/*</font><font color="#80a0ff">&nbsp;Add entropy to s2 by calling gettimeofday() again </font><font color="#80a0ff">*/</font><br>
&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff60"><b>if</b></font>&nbsp;(gettimeofday(&amp;tv, <font color="#ffa0a0">NULL</font>) == <font color="#ffa0a0">0</font>) {<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LCG(s2) ^= (tv.tv_usec&lt;&lt;<font color="#ffa0a0">11</font>);<br>
&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;LCG(seeded) = <font color="#ffa0a0">1</font>;<br>
}<br></pre>
{% endraw %}

This is seeded with the current time (known), the process id (weak), and the current time again (still known).

So to summarize, unless I'm missing something, PHP's automatic seeding uses the following for entropy:
<ul>
<li>Current time (known value)</li>
<li>Process ID (predictable range)</li>
<li>php_combined_lcg</li>
  <ul>
    <li>Current time (again)</li>
    <li>Process id (again)</li>
    <li>Current time (yet again)</li>
  </ul>
</ul>

I haven't done any further research into PHP's random number generator, but from what I've seen I don't get a good feeling about it. It would be interesting if somebody took this a step further and actually wrote an attack against PHP's random number implementation. That, or discovered a source of entropy that I was unaware of. Because, from the code I've looked at, it looks like there may be some problems.

An additional issue is that every seed generated is cast to a (long), which is 32-bits. That means that at the very most, despite the ridiculously long period of the mt_rand() function, there are only 4.2 billion possible seeds. That means, at the very best, an application that relies entirely on mt_rand() or rand() for their randomness are going to be a lot less random than they think!

It turns out, after a little research, I'm <a href='http://www.suspekt.org/2008/08/17/mt_srand-and-not-so-random-numbers/'>not the only one</a> who's noticed problems with PHP's random functions. In fact, in that article, Stefan goes over a history of PHP's random number issues. It turns out, what I've found is only the tip of the iceberg!

<h2>Observations</h2>
I hope the last three blogs have raised some awareness on how randomization can be used and abused. It turns out, using randomness is far more complex than people realize. First, you have to know how to use it properly; otherwise, you've already lost. Second, you have to consider how you're generating the it in the first place. 

It seems that the vast majority of applications make either one mistake or the other. It's difficult to create "good" randomness, though, and I think the one that does the best job is actually SMF.

<h2>Recommendation</h2>
Here is what I would suggest:
<ul>
<li>Get your randomness from multiple sources</li>
<li>Save a good random seed between sessions (eg, save the last output of the random number generator to the database)</li>
<li>Use cryptographically secure functions for random generation (for example, hashing functions)</li>
<li>Don't limit your seeds to 32-bit values</li>
<li>Collect entropy in the application, if possible (what happens in your application that is impossible to guess/detect/force but that can accumulate?)</li>
</ul>

I'm sure there are some other great suggestions for ensuring your random numbers are cryptographically secure, and I've love to hear them!
