---
id: 146
title: 'How NOT to do CAPTCHAs'
date: '2008-12-17T10:54:50-05:00'
author: 'Ron Bowes'
layout: post
guid: 'http://www.skullsecurity.org/blog/?p=146'
permalink: /2008/how-not-to-do-captchas
categories:
    - Humour
---

![](/blogdata/dumbcaptcha.png)

Yes, this is a real CAPTCHA that I ran across.  
  
In case it isn't obvious from the picture, or you can't read that small, the text in the CAPTCHA matches the filename, therefore making it trivial to determine what the text says. Further, I tried specifying 6 random characters for the filename and it didn't work, which leads to two possibilities:

1. The CAPTCHA images are generated and saved in the root Web directory
2. There are a limited number of generated CAPTCHA images

I can't easily tell which one is actually happening, but in both cases there's a serious issue. And funny, too!