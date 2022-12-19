---
id: 1088
title: '(Mostly) good password resets'
date: '2011-03-24T08:08:16-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=1088'
permalink: /2011/mostly-good-password-resets
categories:
    - Hacking
    - Passwords
---

Hey everybody!

This is part 3 to my 2-part series on password reset attacks ([Part 1](http://www.skullsecurity.org/blog/2011/hacking-crappy-password-resets-part-1) / [Part 2](http://www.skullsecurity.org/blog/2011/hacking-crappy-password-resets-part-2)). Overall, I got awesome feedback on the first two parts, but I got the same question over and over: what's the RIGHT way to do this?

So, here's the thing. I like to break stuff, but I generally leave the fixing to somebody else. It's just safer that way, since I'm not really a developer or anything like that. Instead, I'm going to continue the trend of looking at others' implementations by looking at three major opensource projects - WordPress, SMF, and MediaWiki. Then, since all of these rely on PHP's random number implementation to some extent, I'll take a brief look at PHP.

## SMF

[SMF](http://www.simplemachines.org/) 1.1.13 implements the password-reset function in Sources/Subs-Auth.php:

```

  <font color="#80a0ff">// Generate a random password.</font><br></br>
  <font color="#ff80ff">require_once</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">sourcedir</font> <font color="#ffff60"><b>.</b></font> '<font color="#ffa0a0">/Subs-Members.php</font>'<font color="#ffa500">)</font>;<br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">newPassword</font> <font color="#ffff60"><b>=</b></font> generateValidationCode<font color="#ffa500">()</font>;<br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">newPassword_sha1</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#40ffff">strtolower</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">user</font><font color="#ffa500">)</font> <font color="#ffff60"><b>.</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">newPassword</font><font color="#ffa500">)</font>;<br></br>
```

Looking at Sources/Subs-Members.php, we find:

```

<font color="#80a0ff">// Generate a random validation code.</font><br></br>
<font color="#ff80ff">function</font> generateValidationCode<font color="#ffa500">()</font><br></br>
<font color="#ffa500">{</font><br></br>
  <font color="#60ff60"><b>global</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">modSettings</font>;<br></br>
<br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">request</font> <font color="#ffff60"><b>=</b></font> db_query<font color="#ffa500">(</font>'<br></br>
<font color="#ffa0a0">    SELECT RAND()</font>', <font color="#ffa0a0">__FILE__</font>, <font color="#ffa0a0">__LINE__</font><font color="#ffa500">)</font>;<br></br>
<br></br>
  <font color="#60ff60"><b>list</b></font> <font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">dbRand</font><font color="#ffa500">)</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">mysql_fetch_row</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">request</font><font color="#ffa500">)</font>;<br></br>
  <font color="#40ffff">mysql_free_result</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">request</font><font color="#ffa500">)</font>;<br></br>
<br></br>
  <font color="#ffff60"><b>return</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#40ffff">preg_replace</font><font color="#ffa500">(</font>'<font color="#ffa0a0">/\W/</font>', '', <font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#40ffff">microtime</font><font color="#ffa500">()</font> <font color="#ffff60"><b>.</b></font> <font color="#40ffff">mt_rand</font><font color="#ffa500">()</font> <font color="#ffff60"><b>.</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">dbRand</font> <font color="#ffff60"><b>.</b></font><br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">modSettings</font><font color="#ffa500">[</font>'<font color="#ffa0a0">rand_seed</font>'<font color="#ffa500">]))</font>, <font color="#ffa0a0">0</font>, <font color="#ffa0a0">10</font><font color="#ffa500">)</font>;<br></br>
<font color="#ffa500">}</font><br></br>
```

Which is pretty straight forward, but also, in my opinion, very strong. It takes entropy from a bunch of different places:

- The current time (microtime())
- PHP's random number generator (mt\_rand())
- MySQL's random number generator ($dbRand)
- A user-configurable random seed

Essentially, it puts these difficult-to-guess values through a cryptographically secure function, sha1(), and takes the first 10 characters of the hash.

The hash consists of lowercase letters and numbers, which means there are 36 possible choices for 10 characters, for a total of 36<sup>10</sup> or 3,656,158,440,062,976 possible outputs. That isn't as strong as it \*could\* be, since there's no reason to limit its length to 10 characters (or its character set to 36 characters). That being said, three quadrillion different passwords would be nearly impossible to guess. (By my math, exhaustively cracking all possible passwords, assuming md5 cracks at 5 million guesses/second, would take about 23 CPU-years). Not that cracking is terribly useful - remote bruteforce guessing is much more useful and is clearly impossible.

SMF is my favourite implementation of the three, but let's take a look at WordPress!

## WordPress

[WordPress](http://wordpress.org/) 3.1 implements the password-reset function in wp-login.php:

```

  <font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font> <font color="#ffff60"><b>=</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-></b></font>get_var<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-></b></font>prepare<font color="#ffa500">(</font>"<font color="#ffa0a0">SELECT user_activation_key FROM</font><br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-></b></font>users<font color="#ffa0a0"> WHERE user_login = %s</font>", <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_login</font><font color="#ffa500">))</font>;<br></br>
  <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>empty</b></font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font><font color="#ffa500">)</font> <font color="#ffa500">)</font> <font color="#ffa500">{</font><br></br>
    <font color="#80a0ff">// Generate something random for a key...</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font> <font color="#ffff60"><b>=</b></font> wp_generate_password<font color="#ffa500">(</font><font color="#ffa0a0">20</font>, <font color="#ffa0a0">false</font><font color="#ffa500">)</font>;<br></br>
    do_action<font color="#ffa500">(</font>'<font color="#ffa0a0">retrieve_password_key</font>', <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_login</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font><font color="#ffa500">)</font>;<br></br>
    <font color="#80a0ff">// Now insert the new md5 key into the db</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-></b></font>update<font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">wpdb</font><font color="#60ff60"><b>-></b></font>users, <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font>'<font color="#ffa0a0">user_activation_key</font>' <font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>></b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">key</font><font color="#ffa500">)</font>, 
      <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font>'<font color="#ffa0a0">user_login</font>' <font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>></b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">user_login</font><font color="#ffa500">))</font>;<br></br>
  <font color="#ffa500">}</font><br></br>
```

wp\_generate\_password() is found in wp-includes/pluggable.php:

```

<font color="#80a0ff">/**</font><br></br>
<font color="#80a0ff"> * Generates a random password drawn from the defined set of characters.</font><br></br>
<font color="#80a0ff"> *</font><br></br>
<font color="#80a0ff"> * @since 2.5</font><br></br>
<font color="#80a0ff"> *</font><br></br>
<font color="#80a0ff"> * @param int $length The length of password to generate</font><br></br>
<font color="#80a0ff"> * @param bool $special_chars Whether to include standard special characters.<br></br>
      Default true.</font><br></br>
<font color="#80a0ff"> * @param bool $extra_special_chars Whether to include other special characters.</font><br></br>
<font color="#80a0ff"> *   Used when generating secret keys and salts. Default false.</font><br></br>
<font color="#80a0ff"> * @return string The random password</font><br></br>
<font color="#80a0ff"> **/</font><br></br>
<font color="#ff80ff">function</font> wp_generate_password<font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">12</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">special_chars</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">true</font>, <font color="#ffff60"><b>$</b></font>
      <font color="#40ffff">extra_special_chars</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">false</font> <font color="#ffa500">)</font> <font color="#ffa500">{</font><br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font> <font color="#ffff60"><b>=</b></font> '<font color="#ffa0a0">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789</font>';<br></br>
  <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">special_chars</font> <font color="#ffa500">)</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font> <font color="#ffff60"><b>.=</b></font> '<font color="#ffa0a0">!@#$%^&*()</font>';<br></br>
  <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">extra_special_chars</font> <font color="#ffa500">)</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font> <font color="#ffff60"><b>.=</b></font> '<font color="#ffa0a0">-_ []{}<>~`+=,.;:/?|</font>';<br></br>
<br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">password</font> <font color="#ffff60"><b>=</b></font> '';<br></br>
  <font color="#ffff60"><b>for</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b><</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">length</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font> <font color="#ffa500">)</font> <font color="#ffa500">{</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">password</font> <font color="#ffff60"><b>.=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font>, wp_rand<font color="#ffa500">(</font><font color="#ffa0a0">0</font>, <font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">chars</font><font color="#ffa500">)</font> <font color="#ffff60"><b>-</b></font> <font color="#ffa0a0">1</font><font color="#ffa500">)</font>, <font color="#ffa0a0">1</font><font color="#ffa500">)</font>;<br></br>
  <font color="#ffa500">}</font><br></br>
<br></br>
  <font color="#80a0ff">// random_password filter was previously in random_password function which was
      deprecated</font><br></br>
  <font color="#ffff60"><b>return</b></font> apply_filters<font color="#ffa500">(</font>'<font color="#ffa0a0">random_password</font>', <font color="#ffff60"><b>$</b></font><font color="#40ffff">password</font><font color="#ffa500">)</font>;<br></br>
<font color="#ffa500">}</font><br></br>
```

This generates a string of random characters (and possibly symbols) up to a defined length, choosing the characters using wp\_rand(). So, for the final step, how is wp\_rand() implemented? It's also found in wp-includes/pluggable.php and looks like this:

```

  <font color="#60ff60"><b>global</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>;<br></br>
<br></br>
  <font color="#80a0ff">// Reset $rnd_value after 14 uses</font><br></br>
  <font color="#80a0ff">// 32(md5) + 40(sha1) + 40(sha1) / 8 = 14 random numbers from $rnd_value</font><br></br>
  <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#40ffff">strlen</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font><font color="#ffa500">)</font> <font color="#ffff60"><b><</b></font> <font color="#ffa0a0">8</font> <font color="#ffa500">)</font> <font color="#ffa500">{</font><br></br>
    <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#40ffff">defined</font><font color="#ffa500">(</font> '<font color="#ffa0a0">WP_SETUP_CONFIG</font>' <font color="#ffa500">)</font> <font color="#ffa500">)</font><br></br>
      <font color="#60ff60"><b>static</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font> <font color="#ffff60"><b>=</b></font> '';<br></br>
    <font color="#ffff60"><b>else</b></font><br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font> <font color="#ffff60"><b>=</b></font> get_transient<font color="#ffa500">(</font>'<font color="#ffa0a0">random_seed</font>'<font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">md5</font><font color="#ffa500">(</font> <font color="#40ffff">uniqid</font><font color="#ffa500">(</font><font color="#40ffff">microtime</font><font color="#ffa500">()</font> <font color="#ffff60"><b>.</b></font> <font color="#40ffff">mt_rand</font><font color="#ffa500">()</font>, <font color="#ffa0a0">true</font> <font color="#ffa500">)</font> <font color="#ffff60"><b>.</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font> <font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font> <font color="#ffff60"><b>.=</b></font> <font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font><font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font> <font color="#ffff60"><b>.=</b></font> <font color="#40ffff">sha1</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font> <font color="#ffff60"><b>.</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font><font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">md5</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font> <font color="#ffff60"><b>.</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font><font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>!</b></font> <font color="#40ffff">defined</font><font color="#ffa500">(</font> '<font color="#ffa0a0">WP_SETUP_CONFIG</font>' <font color="#ffa500">)</font> <font color="#ffa500">)</font><br></br>
      set_transient<font color="#ffa500">(</font>'<font color="#ffa0a0">random_seed</font>', <font color="#ffff60"><b>$</b></font><font color="#40ffff">seed</font><font color="#ffa500">)</font>;<br></br>
  <font color="#ffa500">}</font><br></br>
<br></br>
  <font color="#80a0ff">// Take the first 8 digits for our value</font><br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>, <font color="#ffa0a0">0</font>, <font color="#ffa0a0">8</font><font color="#ffa500">)</font>;<br></br>
<br></br>
  <font color="#80a0ff">// Strip the first eight, leaving the remainder for the next call to wp_rand().</font><br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">substr</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">rnd_value</font>, <font color="#ffa0a0">8</font><font color="#ffa500">)</font>;<br></br>
<br></br>
  <font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">abs</font><font color="#ffa500">(</font><font color="#40ffff">hexdec</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font><font color="#ffa500">))</font>;<br></br>
<br></br>
  <font color="#80a0ff">// Reduce the value to be within the min - max range</font><br></br>
  <font color="#80a0ff">// 4294967295 = 0xffffffff = max random number</font><br></br>
  <font color="#ffff60"><b>if</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">max</font> <font color="#ffff60"><b>!=</b></font> <font color="#ffa0a0">0</font> <font color="#ffa500">)</font><br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font> <font color="#ffff60"><b>=</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">min</font> <font color="#ffff60"><b>+</b></font> <font color="#ffa500">((</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">max</font> <font color="#ffff60"><b>-</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">min</font> <font color="#ffff60"><b>+</b></font> <font color="#ffa0a0">1</font><font color="#ffa500">)</font> <font color="#ffff60"><b>*</b></font> <font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font> <font color="#ffff60"><b>/</b></font> <font color="#ffa500">(</font><font color="#ffa0a0">4294967295</font> <font color="#ffff60"><b>+</b></font> <font color="#ffa0a0">1</font><font color="#ffa500">)))</font>;<br></br>
<br></br>
  <font color="#ffff60"><b>return</b></font> <font color="#40ffff">abs</font><font color="#ffa500">(</font><font color="#40ffff">intval</font><font color="#ffa500">(</font><font color="#ffff60"><b>$</b></font><font color="#40ffff">value</font><font color="#ffa500">))</font>;<br></br>
<font color="#ffa500">}</font><br></br>
```

This is quite complex for generating a number! But the points of interest are:

- Hashing functions (sha1 and md5) are used, which are going to be *a lot* slower than a standard generator, but they, at least in theory, have cryptographic strength
- The random number is seeded with microtime() and mt\_rand(), which is PHP's "advanced" randomization function)
- The random number is restricted to 0 - 0xFFFFFFFF, which is pretty typical

In practice, due to the multiple seeds with difficult-to-predict values and the use of a hashing function to generate strong random numbers, this seems to be a good implementation of a password reset. My biggest concern is the complexity - using multiple hashing algorithms and hashing in odd ways (like hasing the value alone, then the hash with the seed). It has the feeling of being unsure what to do, so trying to do everything 'just in case'. While I don't expect to find any weaknesses in the implementation, it's a little concerning.

Now, let's take a look at my least favourite (although still reasonably strong) password-reset implementation: MediaWiki!

## MediaWiki

[MediaWiki](http://www.mediawiki.org/) 1.16.2 was actually the most difficult to find the password reset function in. Eventually, though, I managed to track it down to includes/specials/SpecialUserlogin.php:

```

    <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font> <font color="#ffff60"><b>=</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-></b></font>randomPassword<font color="#ffa500">()</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-></b></font>setNewpassword<font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">throttle</font> <font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-></b></font>saveSettings<font color="#ffa500">()</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">userLanguage</font> <font color="#ffff60"><b>=</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-></b></font>getOption<font color="#ffa500">(</font> '<font color="#ffa0a0">language</font>' <font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">m</font> <font color="#ffff60"><b>=</b></font> wfMsgExt<font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">emailText</font>, <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font> '<font color="#ffa0a0">parsemag</font>', '<font color="#ffa0a0">language</font>' <font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>></b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">userLanguage</font> <font color="#ffa500">)</font>, 
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">ip</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-></b></font>getName<font color="#ffa500">()</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>,<br></br>
        <font color="#ffff60"><b>$</b></font><font color="#40ffff">wgServer</font> <font color="#ffff60"><b>.</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">wgScript</font>, <font color="#40ffff">round</font><font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">wgNewPasswordExpiry</font> <font color="#ffff60"><b>/</b></font> <font color="#ffa0a0">86400</font> <font color="#ffa500">)</font> <font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">result</font> <font color="#ffff60"><b>=</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">u</font><font color="#60ff60"><b>-></b></font>sendMail<font color="#ffa500">(</font> wfMsgExt<font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">emailTitle</font>, <font color="#60ff60"><b>array</b></font><font color="#ffa500">(</font> '<font color="#ffa0a0">parsemag</font>', 
      '<font color="#ffa0a0">language</font>' <font color="#ffff60"><b>=</b></font><font color="#ffff60"><b>></b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">userLanguage</font> <font color="#ffa500">)</font> <font color="#ffa500">)</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">m</font> <font color="#ffa500">)</font>;<br></br>
```

$u->randomPassword() is found in includes/User.php looks like this:

```

  <font color="#80a0ff">/**</font><br></br>
<font color="#80a0ff">   * Return a random password. Sourced from mt_rand, so it's not particularly secure.</font><br></br>
<font color="#80a0ff">   * @</font><span style="background-color: #ffff00"><font color="#0000ff">todo</font></span><font color="#80a0ff"> hash random numbers to improve security, like generateToken()</font><br></br>
<font color="#80a0ff">   *</font><br></br>
<font color="#80a0ff">   * @return \string New random password</font><br></br>
<font color="#80a0ff">   */</font><br></br>
  <font color="#60ff60"><b>static</b></font> <font color="#ff80ff">function</font> randomPassword<font color="#ffa500">()</font> <font color="#ffa500">{</font><br></br>
    <font color="#60ff60"><b>global</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">wgMinimalPasswordLength</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwchars</font> <font color="#ffff60"><b>=</b></font> '<font color="#ffa0a0">ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz</font>';<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">l</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">strlen</font><font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwchars</font> <font color="#ffa500">)</font> <font color="#ffff60"><b>-</b></font> <font color="#ffa0a0">1</font>;<br></br>
<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwlength</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">max</font><font color="#ffa500">(</font> <font color="#ffa0a0">7</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">wgMinimalPasswordLength</font> <font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">digit</font> <font color="#ffff60"><b>=</b></font> <font color="#40ffff">mt_rand</font><font color="#ffa500">(</font> <font color="#ffa0a0">0</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwlength</font> <font color="#ffff60"><b>-</b></font> <font color="#ffa0a0">1</font> <font color="#ffa500">)</font>;<br></br>
    <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font> <font color="#ffff60"><b>=</b></font> '';<br></br>
    <font color="#ffff60"><b>for</b></font> <font color="#ffa500">(</font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>=</b></font> <font color="#ffa0a0">0</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b><</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwlength</font>; <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font><font color="#ffff60"><b>++</b></font> <font color="#ffa500">)</font> <font color="#ffa500">{</font><br></br>
      <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font> <font color="#ffff60"><b>.=</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">i</font> <font color="#ffff60"><b>==</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">digit</font> <font color="#ffff60"><b>?</b></font> <font color="#40ffff">chr</font><font color="#ffa500">(</font> <font color="#40ffff">mt_rand</font><font color="#ffa500">(</font> <font color="#ffa0a0">48</font>, <font color="#ffa0a0">57</font> <font color="#ffa500">)</font> <font color="#ffa500">)</font> <font color="#ffff60"><b>:</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">pwchars</font><font color="#ffa500">{</font> <font color="#40ffff">mt_rand</font><font color="#ffa500">(</font> <font color="#ffa0a0">0</font>, <font color="#ffff60"><b>$</b></font><font color="#40ffff">l</font> <font color="#ffa500">)</font> <font color="#ffa500">}</font>;<br></br>
    <font color="#ffa500">}</font><br></br>
    <font color="#ffff60"><b>return</b></font> <font color="#ffff60"><b>$</b></font><font color="#40ffff">np</font>;<br></br>
  <font color="#ffa500">}</font><br></br>
```

This is easily the most complex, and also most dangerous, password-reset implementation that I've found.

First, the length is only 7 characters by default. That's already an issue.

Second, the set of characters is letters (uppercase + lowercase) and exactly one number. And it looks to me like they put a lot of effort into figuring out just how to put that one number into the password. Initially, I thought this made the password slightly weaker due to the following calculations:

- 7 characters @ 52 choices = 52<sup>7</sup> = 1,028,071,702,528
- 6 characters @ 52 choices + 1 character @ 10 choices = 52<sup>6</sup> \* 10 = 197,706,096,640

However, as my friend pointed out, because you don't know where, exactly, the number will be placed, that actually adds an extra multiplier to the strength:

- 6 characters @ 52 choices + 1 characters @ 10 choices + unknown number location = 52<sup>6</sup> \* 10 \* 7 = 1,383,942,676,480

So, in reality, adding a single number does improve the strength, but only by a bit.

Even with the extra number, though, the best we have at 7 characters is about 1.4 trillion choices. As with the others, that's essentially impossible to guess/bruteforce remotely. That's a good thing. However, with a password cracker and 5 million checks/second, it would take a little over 3.2 CPU-days to exhaustively crack all generated passwords, so that can very easily be achieved.

The other issue here is that the only source of entropy is PHP's mt\_rand() function. The next section will look at how PHP seeds this function.

## PHP

All three of these implementations depend, in one way or another, on [PHP](http://www.php.net/)'s mt\_rand() function. The obvious question is, how strong is mt\_rand()?

I'm only going to look at this from a high level for now. When I have some more time, I'm hoping to dig deeper into this and, with luck, bust it wide open. Stay tuned for that. :)

For now, though, let's look at the function that's used by all three password-reset functions: mt\_rand(). mt\_rand() is an implementation of the [Mersenne Twister](https://secure.wikimedia.org/wikipedia/en/wiki/Mersenne_Twister) algorithm, which is a well tested random number generator with an advertised average period of 2<sup>19937</sup>-1. That means that it won't repeat until 2<sup>19937</sup>-1 values are generated. I don't personally have the skills to analyze the strength of the algorithm itself, but what I CAN look at is the seed.

Whether using rand() or mt\_rand(), PHP automatically seeds the random number generator. The code is in ext/standard/rand.c, and looks like this:

```

PHPAPI <font color="#60ff60"><b>long</b></font> php_rand(TSRMLS_D)<br></br>
{<br></br>
    <font color="#60ff60"><b>long</b></font> ret;<br></br>
<br></br>
    <font color="#ffff60"><b>if</b></font> (!BG(rand_is_seeded)) {<br></br>
        php_srand(GENERATE_SEED() TSRMLS_CC);<br></br>
    }<br></br>
    <font color="#80a0ff">// ...</font><br></br>
}<br></br>
```

Simple enough - if rand() is called without a seed, then seed it with the GENERATE\_SEED() macro, which is found in ext/standard/php\_rand.h:

```

<font color="#ff80ff">#ifdef PHP_WIN32</font><br></br>
<font color="#ff80ff">#define GENERATE_SEED() (((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">) (time(</font><font color="#ffa0a0">0</font><font color="#ff80ff">) * GetCurrentProcessId())) ^ <br></br>
     ((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">)<br></br>(</font><font color="#ffa0a0">1000000.0</font><font color="#ff80ff"> * php_combined_lcg(TSRMLS_C))))</font><br></br>
<font color="#ff80ff">#else</font><br></br>
<font color="#ff80ff">#define GENERATE_SEED() (((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">) (time(</font><font color="#ffa0a0">0</font><font color="#ff80ff">) * getpid())) ^ <br></br>
     ((</font><font color="#60ff60"><b>long</b></font><font color="#ff80ff">) (</font><font color="#ffa0a0">1000000.0</font><font color="#ff80ff"> * php_combined_lcg(TSRMLS_C))))</font><br></br>
<font color="#ff80ff">#endif</font><br></br>
```

So it's seeded with the current time() (known), process id (weak), and php\_combined\_lcg(). What the heck is php\_combined\_lcg? Well, an LCG is a Linear Congruential Generator, a type of random number generator, and it's defined at ext/standard/lcg.c so let's take a look:

{% raw %}
```
PHPAPI <font color="#60ff60"><b>double</b></font> php_combined_lcg(TSRMLS_D) <font color="#80a0ff">/*</font><font color="#80a0ff"> {{{ </font><font color="#80a0ff">*/</font><br></br>
{<br></br>
    php_int32 q;<br></br>
    php_int32 z;<br></br>
<br></br>
    <font color="#ffff60"><b>if</b></font> (!LCG(seeded)) {<br></br>
        lcg_seed(TSRMLS_C);<br></br>
    }<br></br>
<br></br>
    MODMULT(<font color="#ffa0a0">53668</font>, <font color="#ffa0a0">40014</font>, <font color="#ffa0a0">12211</font>, <font color="#ffa0a0">2147483563L</font>, LCG(s1));<br></br>
    MODMULT(<font color="#ffa0a0">52774</font>, <font color="#ffa0a0">40692</font>, <font color="#ffa0a0">3791</font>, <font color="#ffa0a0">2147483399L</font>, LCG(s2));<br></br>
<br></br>
    z = LCG(s1) - LCG(s2);<br></br>
    <font color="#ffff60"><b>if</b></font> (z < <font color="#ffa0a0">1</font>) {<br></br>
        z += <font color="#ffa0a0">2147483562</font>;<br></br>
    }<br></br>
<br></br>
    <font color="#ffff60"><b>return</b></font> z * <font color="#ffa0a0">4.656613e-10</font>;<br></br>
}<br></br>
```
{% endraw %}

This function also needs to be seeded! It's pretty funny to seed a random number generator with another random number generator - what, exactly, does that improve?

Here is what lcg\_seed(), in the same file, looks like:

{% raw %}
```
<font color="#60ff60"><b>static</b></font> <font color="#60ff60"><b>void</b></font> lcg_seed(TSRMLS_D) <font color="#80a0ff">/*</font><font color="#80a0ff"> {{{ </font><font color="#80a0ff">*/</font><br></br>
{<br></br>
    <font color="#60ff60"><b>struct</b></font> timeval tv;<br></br>
<br></br>
    <font color="#ffff60"><b>if</b></font> (gettimeofday(&tv, <font color="#ffa0a0">NULL</font>) == <font color="#ffa0a0">0</font>) {<br></br>
        LCG(s1) = tv.tv_sec ^ (tv.tv_usec<<<font color="#ffa0a0">11</font>);<br></br>
    } <font color="#ffff60"><b>else</b></font> {<br></br>
        LCG(s1) = <font color="#ffa0a0">1</font>;<br></br>
    }<br></br>
<font color="#ff80ff">#ifdef ZTS</font><br></br>
    LCG(s2) = (<font color="#60ff60"><b>long</b></font>) tsrm_thread_id();<br></br>
<font color="#ff80ff">#else</font> <br></br>
    LCG(s2) = (<font color="#60ff60"><b>long</b></font>) getpid();<br></br>
<font color="#ff80ff">#endif</font><br></br>
<br></br>
    <font color="#80a0ff">/*</font><font color="#80a0ff"> Add entropy to s2 by calling gettimeofday() again </font><font color="#80a0ff">*/</font><br></br>
    <font color="#ffff60"><b>if</b></font> (gettimeofday(&tv, <font color="#ffa0a0">NULL</font>) == <font color="#ffa0a0">0</font>) {<br></br>
        LCG(s2) ^= (tv.tv_usec<<<font color="#ffa0a0">11</font>);<br></br>
    }<br></br>
<br></br>
    LCG(seeded) = <font color="#ffa0a0">1</font>;<br></br>
}<br></br>
```
{% endraw %}

This is seeded with the current time (known), the process id (weak), and the current time again (still known).

So to summarize, unless I'm missing something, PHP's automatic seeding uses the following for entropy:

- Current time (known value)
- Process ID (predictable range)
- php\_combined\_lcg
- Current time (again)
- Process id (again)
- Current time (yet again)


I haven't done any further research into PHP's random number generator, but from what I've seen I don't get a good feeling about it. It would be interesting if somebody took this a step further and actually wrote an attack against PHP's random number implementation. That, or discovered a source of entropy that I was unaware of. Because, from the code I've looked at, it looks like there may be some problems.

An additional issue is that every seed generated is cast to a (long), which is 32-bits. That means that at the very most, despite the ridiculously long period of the mt\_rand() function, there are only 4.2 billion possible seeds. That means, at the very best, an application that relies entirely on mt\_rand() or rand() for their randomness are going to be a lot less random than they think!

It turns out, after a little research, I'm [not the only one](http://www.suspekt.org/2008/08/17/mt_srand-and-not-so-random-numbers/) who's noticed problems with PHP's random functions. In fact, in that article, Stefan goes over a history of PHP's random number issues. It turns out, what I've found is only the tip of the iceberg!

## Observations

I hope the last three blogs have raised some awareness on how randomization can be used and abused. It turns out, using randomness is far more complex than people realize. First, you have to know how to use it properly; otherwise, you've already lost. Second, you have to consider how you're generating the it in the first place.

It seems that the vast majority of applications make either one mistake or the other. It's difficult to create "good" randomness, though, and I think the one that does the best job is actually SMF.

## Recommendation

Here is what I would suggest:

- Get your randomness from multiple sources
- Save a good random seed between sessions (eg, save the last output of the random number generator to the database)
- Use cryptographically secure functions for random generation (for example, hashing functions)
- Don't limit your seeds to 32-bit values
- Collect entropy in the application, if possible (what happens in your application that is impossible to guess/detect/force but that can accumulate?)

I'm sure there are some other great suggestions for ensuring your random numbers are cryptographically secure, and I've love to hear them!