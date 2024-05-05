---
id: 2449
title: 'My coding / Linux environment'
date: '2019-12-30T17:33:09-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2019/2289-revision-v1'
permalink: '/?p=2449'
---

Some time ago, I had a guy ask me to talk about my hacking / coding environment. So I wrote this, then forgot about it. So I dusted it off, updated it, and then forgot about it again. It wasn't till my friend and co-worker [Josh Wright](https://twitter.com/joswr1ght?lang=en) asked me about my config today that I realized I never published this. So here I am, updating it again. Who knows where it'll end up? :)

If folks are interested in similar posts about other parts of my environment, such as the hacking tools I use, let me know! This will be largely dev dev.

## Coding

### Languages

A lot of people ask me what my favourite language is. There's always language wars, people saying "C is better than Java!" or "Python is better than C!" or all these other weird comparisons.

I mean, we all know that Ruby is the best, right? :)

But seriously: I strongly believe that a variety of languages have their own useful purposes. Some languages are better at some things, and other languages are better at other things. I typically use C when I need low-level (although I've been excited about doing some Rust lately!), Ruby when I need high level, Javascript when I'm doing Web stuff, Lua when I need to embed it in another program (like Nmap and Wireshark), x86/x86-64 assembly when I'm hacking, and occasionally python and other languages when .

I don't think anybody should marry themselves to a single language to the detriment of others; in fact, I think a well-rounded developer is much more useful than a focused one. You'll certainly find it easier to get a job, if nothing else! Plus, the hard part of programming is abstracting problems, not writing code.

### Editor: neovim

Speaking of holy wars, let's talk about editors!

Note: I'm not going to teach how to use vi/vim/neovim; there are millions of pages written for exactly that purpose, so it wouldn't be a valuable use of time. Also, it seriously takes years to really become an efficient vim user. But it's so worthwhile!

I use [Neovim](https://neovim.io/) these days (though I'll mostly call it 'vim'). But no, I'm not against emacs. I've never learned how to use emacs, but I have 15 or so years of vim muscle memory built up, so I'm going to stick with what I'm good at! I've never found a graphical editor that I like, either, though people seem to like Sublime a lot. I've never used it. I do, however, find it extremely hard to believe I could ever be as quick and efficient on any editor other than vim.

I was forced to learn vi (like, classic vi, on Solaris) when I took first year programming. Our professor insisted on us using it for homework, and even had questions about it on the final. That was ~15 years ago, and I hated it at first. But I forced myself to use it on our old Solaris/SunOS systems through early university. No syntax highlighting, no fancy plugins, nothing like that. It was terrible, but I managed!

As time went on, I started using plugins, and even found a manager, [Janus](https://github.com/carlhuda/janus). It came with a bunch of built-in plugins, but it was kind of a pain to use. I couldn't cleanly copy over my ~/.vimrc folder to new systems, a few things didn't work out of the box. I was also always unclear of which plugins were installed, and which were enabled, and how to add more. So I just kept the defaults for years and years and years.

Eventually, I decided to drop Janus and give Neovim with Plug a shot. [Here's my init.vim file](https://gist.github.com/iagox86/f96965fb2c6fa5b98077fb25a1bdb1ee) for reference, but I'll go over the important stuff. It's probably far from perfect, but I'm happy with it!

#### neovim plugins

First, plugins. [Nerdtree](https://github.com/scrooloose/nerdtree) is an absolute necessity:

```

Plug <span class="String">'<a href="https://github.com/scrooloose/nerdtree.git">https://github.com/scrooloose/nerdtree.git</a>'</span>

<span class="Comment">" Map F2 to NERDTreeToggle</span>
<span class="Statement">map</span> <span class="Delimiter"><</span><span class="Special">F2</span><span class="Delimiter">></span> :NERDTreeToggle<span class="Delimiter"><</span><span class="Special">CR</span><span class="Delimiter">></span>
```

Basically, it's a view of all the files along the left of your screen that you can turn on and off with <f2>. Like normal vim/neovim windows (splits? panes?), use ctrl-w followed by <left> or <right> to switch between windows. You can also create/delete/move/rename files from Nerdtree!</right></left></f2>

Another plugin that changed my life (well, workflow) is [fzf](https://github.com/junegunn/fzf) - fast fuzzy searching:

```

<span class="Comment">" Fast fuzzy searching</span>
Plug <span class="String">'junegunn/fzf'</span>, <span class="Delimiter">{</span> <span class="String">'dir'</span>: <span class="String">'~/.fzf'</span>, <span class="String">'do'</span>: <span class="String">'./install --all'</span> <span class="Delimiter">}</span>
Plug <span class="String">'junegunn/fzf.vim'</span><span class="Statement">s</span>
<span class="Statement">set</span> <span class="PreProc">rtp</span>+=~/.fzf
<span class="Statement">map</span> <span class="Delimiter"><</span><span class="Special">C-F</span><span class="Delimiter">></span> :FZF +c -m -x<span class="Delimiter"><</span><span class="Special">cr</span><span class="Delimiter">></span>
```

With that binding, you can hit Ctrl-f and start typing a filename, and it'll very quickly search the full directory structure that you have open! With that command, it'll also take over Ctrl-r in Bash, so you might have to change the install command if you don't want that.

I also strongly recommend learning the plugin called [EasyMotion](https://github.com/easymotion/vim-easymotion). If you need to jump to a visible part of the screen, instead of using the arrows to move around, you can use <tt>\\\\f<c></c></tt> or <tt>\\\\F<c></c></tt> to quickly jump to any instance of character <c> either forward (f) or backward (F). You can also use <tt>\\\\w</tt> to jump to a word boundary. It took me a little while to get used to using that, but once you do it'll change your life!</c>

I also use a color scheme from the [base16](https://github.com/chriskempson/base16) collection:

```

<span class="Comment">" Colour scheme</span>
Plug <span class="String">'chriskempson/base16-vim'</span>

<span class="Statement">set</span> <span class="PreProc">termguicolors</span>
<span class="Statement">set</span> <span class="PreProc">background</span>=dark
<span class="Statement">colorscheme</span> base16<span class="Operator">-</span>phd
```

"base16" has a ton of nice colorschemes, I just picked my favourite one, "PhD".

I've used a few different syntax-highlight plugins, including probably the most famous ([Syntastic](https://github.com/scrooloose/syntastic)), but it was reallllly slow, and I couldn't find any workarounds on their project page. Now I use [w0rp/ale](https://github.com/w0rp/ale), which is asynchronous and really nice (it uses lint, so you need to install a supported linter like [rubocop-hq/rubocop](https://github.com/rubocop-hq/rubocop) for Ruby.

And finally, a shout out to the plugin [NarrowRegion](https://github.com/chrisbra/NrrwRgn):

```

<span class="Comment">" Narrow Region</span>
Plug <span class="String">'chrisbra/NrrwRgn'</span>
<span class="Statement">map</span> <span class="Delimiter"><</span><span class="Special">leader</span><span class="Delimiter">></span>r :NarrowRegion<span class="Delimiter"><</span><span class="Special">CR</span><span class="Delimiter">></span>
```

If you want to work on a small piece of your code or document, you can highlight it (using <tt>v</tt>) and type <tt>:NarrowRegion</tt> or <tt>\\r</tt>. It moves that block into its own window where you can do anything you want to it, using standard vim commands. When you are done, you can use <tt>:wq</tt> to copy that modified buffer back where it came from!

I frequently use it when I'm writing blogs. Generally, I'm in neovim with HTML syntax highlighting, but if I'm typing out some code and I want to make sure it's right, I'll use <tt>:NarrowRegion</tt> to write the code with different syntax highlighting before copying it back into the <pre> region of the blog.

#### neovim settings

Those are my favourite plugins! You can find the rest in the init.vim file I linked earlier.

This section is my favourite settings that aren't specific to plugins.

This setting turns on hybrid line numbering:

```

<span class="Comment">" Relative line numbers</span>
<span class="Statement">au</span> <span class="Type">BufReadPost</span> * <span class="Statement">set</span> <span class="PreProc">relativenumber</span>
<span class="Statement">au</span> <span class="Type">BufReadPost</span> * <span class="Statement">set</span> <span class="PreProc">number</span>
```

The current line is prefixed with the line number, and the lines above/below it are numbered relatively. This is what I'm looking at right now:

```

[...]
4     au BufReadPost * set relativenumber
3     au BufReadPost * set number
2   <span class="htmlEndTag"></</span><span class="Statement">pre</span><span class="htmlEndTag">></span>
1
130 The current line is prefixed with the line number, and the lines above/below it are numbered relatively. This is what I'm looking at right now:
1
2   ==
3   Don't forget:
4   * Terminal mode
[...]
```

When you search in neovim (using <tt>/<string></tt>), you can make it semi-case-sensitive with these commands:

```

<span class="Comment">" Smart search</span>
<span class="Statement">set</span> <span class="PreProc">ignorecase</span>
<span class="Statement">set</span> <span class="PreProc">smartcase</span>
```

What I mean by "semi-case-sensitive" is that if you search for a lowercase string, it'll ignore case. But if you search for a string with capital letters, it'll be case sensitive. That's a little weird, and isn't *always* what I want, but it seems to be the best option.

Speaking of search, when you search, and it highlights all matching terms, you have to type <tt>:noh</tt> to turn off highlighting. That was annoying, so here's a simple hitkey to make <tt>\\<space></space></tt> do it:

```

<span class="Comment">" Disable highlight</span>
<span class="Statement">nnoremap</span> <span class="Delimiter"><</span><span class="Special">leader</span><span class="Delimiter">></span><span class="Delimiter"><</span><span class="Special">space</span><span class="Delimiter">></span> :noh<span class="Delimiter"><</span><span class="Special">CR</span><span class="Delimiter">></span>
```

This makes tabs sane (<tab> becomes two spaces):

```

<span class="Comment">" Tabstops</span>
<span class="Statement">set</span> <span class="PreProc">tabstop</span>=2
<span class="Statement">set</span> <span class="PreProc">shiftwidth</span>=2
<span class="Statement">set</span> <span class="PreProc">softtabstop</span>=2
<span class="Statement">set</span> <span class="PreProc">expandtab</span>
```

I don't really use that anymore - instead, I use the [editorconfig](https://github.com/editorconfig/editorconfig-vim.git) plugin, which lets me have custom rules for different projects. That way, if others use a different style (I'm looking at you, [Tim](https://twitter.com/timmedin)), I can more easily match it without hating myself.

Here's another handy setting, which remembers where in a file you were when you re-open it:

```

<span class="Comment">" Return to the same spot in the file that we were at</span>
<span class="Statement">if</span> <span class="Function">has</span><span class="Delimiter">(</span><span class="String">"autocmd"</span><span class="Delimiter">)</span>
  <span class="Statement">au</span> <span class="Type">BufReadPost</span> * <span class="Statement">if</span> <span class="Function">line</span><span class="Delimiter">(</span><span class="String">"'\""</span><span class="Delimiter">)</span> <span class="Operator">></span> <span class="Number">0</span> &amp;&amp; <span class="Function">line</span><span class="Delimiter">(</span><span class="String">"'\""</span><span class="Delimiter">)</span> <span class="Operator"><=</span> <span class="Function">line</span><span class="Delimiter">(</span><span class="String">"$"</span><span class="Delimiter">)</span>
<span class="Special">    \</span>| <span class="Statement">exe</span> <span class="String">"normal! g'\""</span> | <span class="Statement">endif</span>
<span class="Statement">endif</span>
```

And finally, neovim has cool terminal support! You can open a terminal using <tt>:terminal</tt> and, more importantly, escape it using the typical ctrl-w+arrow commands:

```

<span class="Comment">" Re-map ctrl-h/j/k/l to move around in normal mode</span>
<span class="Statement">nnoremap</span> <span class="Delimiter"><</span><span class="Special">C-h</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-w</span><span class="Delimiter">></span>h
<span class="Statement">nnoremap</span> <span class="Delimiter"><</span><span class="Special">C-j</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-w</span><span class="Delimiter">></span>j
<span class="Statement">nnoremap</span> <span class="Delimiter"><</span><span class="Special">C-k</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-w</span><span class="Delimiter">></span>k
<span class="Statement">nnoremap</span> <span class="Delimiter"><</span><span class="Special">C-l</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-w</span><span class="Delimiter">></span>l

<span class="Comment">" Re-map ctrl-h/j/k/l to move around in terminal mode</span>
<span class="Statement">tnoremap</span> <span class="Delimiter"><</span><span class="Special">C-h</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-</span><span class="Delimiter">\><</span><span class="Special">C-n</span><span class="Delimiter">><</span><span class="Special">C-w</span><span class="Delimiter">></span>h
<span class="Statement">tnoremap</span> <span class="Delimiter"><</span><span class="Special">C-j</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-</span><span class="Delimiter">\><</span><span class="Special">C-n</span><span class="Delimiter">><</span><span class="Special">C-w</span><span class="Delimiter">></span>j
<span class="Statement">tnoremap</span> <span class="Delimiter"><</span><span class="Special">C-k</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-</span><span class="Delimiter">\><</span><span class="Special">C-n</span><span class="Delimiter">><</span><span class="Special">C-w</span><span class="Delimiter">></span>k
<span class="Statement">tnoremap</span> <span class="Delimiter"><</span><span class="Special">C-l</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-</span><span class="Delimiter">\><</span><span class="Special">C-n</span><span class="Delimiter">><</span><span class="Special">C-w</span><span class="Delimiter">></span>l

<span class="Comment">" Make ctrl-w escape insert mode</span>
<span class="Statement">tnoremap</span> <span class="Delimiter"><</span><span class="Special">C-w</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">C-</span><span class="Delimiter">\><</span><span class="Special">C-n</span><span class="Delimiter">><</span><span class="Special">C-w</span><span class="Delimiter">></span>
<span class="Statement">inoremap</span> <span class="Delimiter"><</span><span class="Special">C-w</span><span class="Delimiter">></span> <span class="Delimiter"><</span><span class="Special">esc</span><span class="Delimiter">><</span><span class="Special">C-w</span><span class="Delimiter">></span>

<span class="Comment">" Let <enter> enter insert mode (helpful for terminals)</span>
<span class="Statement">nnoremap</span> <span class="Delimiter"><</span><span class="Special">return</span><span class="Delimiter">></span> i
```

There are plenty more settings that I really like, but I want to spend a little time talking about my Linux environment. :)

## Linuxing

I have been a Linux user for ~15 years, and used Linux as my primary operating system for probably 10 or more years at this point. I have a single Windows desktop for gaming, but everything else I use is Linux (including my work devices). I used Slackware for the first few years, then Gentoo for many years. Now I'm using Ubuntu as of a couple years ago, largely because it automatically recognized my new laptop's harddrives (Gentoo couldn't find it, and I couldn't figure out which driver or firmware was missing).

In that time, I've realized I like fairly stripped-down and bare-bones stuff. That's why I use [Fluxbox](http://fluxbox.org/) as my window manager, and [xbindkeys ](http://www.nongnu.org/xbindkeys/) (I'll cover my configurations later) to run programs. I used to use [WindowMaker](https://windowmaker.org/), but some random guy on a bus one time convinced me to try Fluxbox, and I fell in love. True story!

Basically, I want a window manager with the minimal possible footprint (in terms of screen realestate), but lets me easily switch between virtual desktops. That's basically all I want. And Fluxbox does basically that. :)

The two things I use most are terminals ([kitty](https://sw.kovidgoyal.net/kitty/)) and my browser (Chrome). Within kitty, I frequently use [tmux](https://tmux.github.io/) for multiplexing sessions.

Let's look at all that stuff in a bit more detail!

### dotfiles

If you use Linux on more than one system, even serially (one system at a time), save yourself some trouble and make a dotfiles repository on github (or your favourite git service). I have a folder on my machine (~/stuff/dotfiles) that stores all my dotfiles that I want to share between machines. I rolled my own dotfiles scripts, though getting one online is probably better. Using them, I can set up a new box the way I like it in just a few minutes. I use it to configure:

- conky
- fceux
- fluxbox
- xbindkeys
- xresources
- zsnes
- editorconfig
- fish
- gdb
- nvim
- rvm
- ssh
- tmux

A typical script, say for gdb, is pretty simple:

```

~/stuff/dotfiles/server/gdb $ ls
gdbinit  install.sh*

~/stuff/dotfiles/server/gdb $ cat install.sh 
#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
source "$FUNCTIONS"

display "Configuring gdb..."
ln -sf $DIR/gdbinit $HOME/.gdbinit
```

I keep all those in a private Github repository, and just run all the install.sh files on a new system to get it going. Since they're symlinks, any changes I make can be committed and pushed back to git.

I don't necessarily suggest doing things my way - using a real tool like [Dotbot](https://github.com/anishathalye/dotbot) is probably better.

### Fluxbox

I honestly don't configure Fluxbox that much. I set the background to plain black, and the "slit" (like a taskbar) to auto-hide, and use the mousewheel to change virtual desktops. I also use exactly 6 virtual desktops. Outside of that, I don't really do much in the way of configuration. The menu and stuff are all defaults, because I don't actually use them.

This is my 'startup' file:

```

<span class="Comment">#!/bin/sh</span>
<span class="Comment">#</span>
<span class="Comment"># fluxbox startup-script:</span>
<span class="Comment">#</span>
<span class="Comment"># Lines starting with a '#' are ignored.</span>


<span class="Comment"># Keyboard repeat</span>
xset <span class="Statement">r</span> rate <span class="Number">250</span> <span class="Number">50</span>

<span class="Comment"># Background</span>
fbsetbg <span class="Operator">"</span><span class="PreProc">$HOME</span><span class="String">/.fluxbox/black.png</span><span class="Operator">"</span>

<span class="Comment"># xbindkeys</span>
xbindkeys

<span class="Comment"># conky</span>
conky

<span class="Comment"># Turn on palm detection for touchpads</span>
synclient <span class="Identifier">PalmDetect</span>=<span class="Number">1</span>

<span class="Statement">exec</span> fluxbox
```

On fluxbox, I use xbindkeys to start the programs I commonly used, which are basically just chrome and kitty.

### xbindkeys

xbindkeys is a wonderful way to bind hotkeys to programs. I use it *constantly*. I use alt-a to bring up kitty (at the time, I used aterm), and alt-c to bring up Chrome. I also use it for a couple other small things.

Here's my ~/.xbindkeysrc file:

```

<span class="Comment"># For the benefit of emacs users: -*- shell-script -*-</span>
<span class="Comment">###########################</span>
<span class="Comment"># xbindkeys configuration #</span>
<span class="Comment">###########################</span>
<span class="Comment">#</span>
<span class="Comment"># Version: 1.7.1</span>
<span class="Comment">#</span>

<span class="String">"kitty</span>
  alt + a

<span class="String">"google-chrome-beta"</span>
  alt + c

<span class="String">"xlock -mode blank"</span>
  alt + l

<span class="String">"xfrun4"</span>
  Mod4 + r

<span class="String">"xfrun4"</span>
  alt + r

<span class="String">"killall X"</span>
  Control+Alt + BackSpace

<span class="String">"firefox & /home/ron/tools/burpsuite/BurpSuitePro"</span>
  alt + f

<span class="String">"mkdir -p /home/ron/tmp/ss/; FILE=/home/ron/tmp/ss/`date --rfc-3339 seconds | sed 's/ /T/g'`.png; import -window root $FILE; gimp $FILE"</span>
  Print

<span class="String">"mkdir -p /home/ron/tmp/ss/; import -window root /home/ron/tmp/ss/`date --rfc-3339 seconds | sed 's/ /T/g'`.png"</span>
  alt + Print

<span class="String">"xset r rate 250 50"</span>
  alt + x

<span class="String">"VirtualBox"</span>
  alt + v

<span class="String">"xrandr --output eDP1 --mode 2560x1440 --output HDMI2 --off --output HDMI1 --off --output DP1 --off; sleep 1; killall -HUP conky"</span>
  Shift+Alt+Mod2 + 1

<span class="String">"xrandr --output eDP1 --mode 2560x1440 --output HDMI2 --mode 2560x1440 --right-of eDP1 --output HDMI1 --off; sleep 1; killall -HUP conky"</span>
  Shift+Alt+Mod2 + 2

<span class="String">"xrandr --output eDP1 --mode 2560x1440 --output HDMI2 --mode 2560x1440 --same-as eDP1 --output DP1 --mode 2560x1440 --left-of eDP1; sleep 1; killall -HUP conky"</span>
  Shift+Alt+Mod2 + 3
```

I don't think there's really much more to say about this, so let's talk kitty!

### kitty

I've tried almost every terminal on Linux, and I always wound up back on xterm due to bugs or annoyances. But fairly recently I started using [Kitty](https://sw.kovidgoyal.net/kitty/). Really, I just want a place where I can type in commands. Kitty is very simple and barebones, but also feels nicer than basic xterm. I like fancy features like being able to zoom. I don't really use tabs or anything like that.

Honestly, I don't even configure kitty. I'm happy with its defaults!

### tmux

There isn't much to say about my .tmux.conf file - it's mostly just switching things to screen-like bindings, and a few custom lines that I don't even remember why they're there, plus a custom status bar:

```

<span class="Comment"># Don't delay after <esc></span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">escape-time</span> <span class="Number">10</span>

<span class="Comment"># Handle 24-bit colours correctly, maybe</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">default-terminal</span> <span class="String">"screen-256color"</span>
<span class="Keyword">set</span><span class="Identifier"> -ga</span> <span class="Function">terminal-overrides</span> <span class="String">",*:Tc"</span>

<span class="Comment">## This is from:</span>
<span class="Comment"># <a href="http://www.chiark.greenend.org.uk/doc/tmux/examples/screen-keys.conf">http://www.chiark.greenend.org.uk/doc/tmux/examples/screen-keys.conf</a></span>
<span class="Comment">##</span>

<span class="Comment"># $Id: screen-keys.conf,v 1.7 2010-07-31 11:39:13 nicm Exp $</span>
<span class="Comment">#</span>
<span class="Comment"># By Nicholas Marriott. Public domain.</span>
<span class="Comment">#</span>
<span class="Comment"># This configuration file binds many of the common GNU screen key bindings to</span>
<span class="Comment"># appropriate tmux key bindings. Note that for some key bindings there is no</span>
<span class="Comment"># tmux analogue and also that this set omits binding some commands available in</span>
<span class="Comment"># tmux but not in screen.</span>
<span class="Comment">#</span>
<span class="Comment"># Note this is only a selection of key bindings and they are in addition to the</span>
<span class="Comment"># normal tmux key bindings. This is intended as an example not as to be used</span>
<span class="Comment"># as-is.</span>

<span class="Comment"># Set the prefix to ^A.</span>
<span class="Keyword">unbind</span> <span class="Special">C-b</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">prefix</span> <span class="Special">^A</span>
<span class="Keyword">bind</span> a <span class="Keyword">send-prefix</span>

<span class="Comment"># Bind appropriate commands similar to screen.</span>
<span class="Comment"># lockscreen ^X x</span>
<span class="Keyword">unbind</span> <span class="Special">^X</span>
<span class="Keyword">bind</span> <span class="Special">^X</span> <span class="Keyword">lock-server</span>
<span class="Keyword">unbind</span> x
<span class="Keyword">bind</span> x <span class="Keyword">lock-server</span>

<span class="Comment"># screen ^C c</span>
<span class="Keyword">unbind</span> <span class="Special">^C</span>
<span class="Keyword">bind</span> <span class="Special">^C</span> <span class="Keyword">new-window</span>
<span class="Keyword">unbind</span> c
<span class="Keyword">bind</span> c <span class="Keyword">new-window</span>

<span class="Comment"># detach ^D d</span>
<span class="Keyword">unbind</span> <span class="Special">^D</span>
<span class="Keyword">bind</span> <span class="Special">^D</span> <span class="Keyword">detach</span>

<span class="Comment"># displays *</span>
<span class="Keyword">unbind</span> *
<span class="Keyword">bind</span> * <span class="Keyword">list-clients</span>

<span class="Comment"># next ^@ ^N sp n</span>
<span class="Keyword">unbind</span> <span class="Special">^@</span>
<span class="Keyword">bind</span> <span class="Special">^@</span> <span class="Keyword">next-window</span>
<span class="Keyword">unbind</span> <span class="Special">^N</span>
<span class="Keyword">bind</span> <span class="Special">^N</span> <span class="Keyword">next-window</span>
<span class="Keyword">unbind</span> <span class="String">" "</span>
<span class="Keyword">bind</span> <span class="String">" "</span> <span class="Keyword">next-window</span>
<span class="Keyword">unbind</span> n
<span class="Keyword">bind</span> n <span class="Keyword">next-window</span>

<span class="Comment"># title A</span>
<span class="Keyword">unbind</span> A
<span class="Keyword">bind</span> A <span class="Keyword">command-prompt</span> <span class="String">"rename-window %%"</span>

<span class="Comment"># other ^A</span>
<span class="Keyword">unbind</span> <span class="Special">^A</span>
<span class="Keyword">bind</span> <span class="Special">^A</span> <span class="Keyword">last-window</span>

<span class="Comment"># prev ^H ^P p ^?</span>
<span class="Keyword">unbind</span> <span class="Special">^H</span>
<span class="Keyword">bind</span> <span class="Special">^H</span> <span class="Keyword">previous-window</span>
<span class="Keyword">unbind</span> <span class="Special">^P</span>
<span class="Keyword">bind</span> <span class="Special">^P</span> <span class="Keyword">previous-window</span>
<span class="Keyword">unbind</span> p
<span class="Keyword">bind</span> p <span class="Keyword">previous-window</span>
<span class="Keyword">unbind</span> BSpace
<span class="Keyword">bind</span> BSpace <span class="Keyword">previous-window</span>

<span class="Comment"># windows ^W w</span>
<span class="Keyword">unbind</span> <span class="Special">^W</span>
<span class="Keyword">bind</span> <span class="Special">^W</span> <span class="Keyword">list-windows</span>
<span class="Keyword">unbind</span> w
<span class="Keyword">bind</span> w <span class="Keyword">list-windows</span>

<span class="Comment"># quit \</span>
<span class="Comment">unbind '\'</span>
<span class="Keyword">bind</span> <span class="String">'\'</span> <span class="Keyword">confirm-before</span> <span class="String">"kill-server"</span>

<span class="Comment"># kill K k</span>
<span class="Keyword">unbind</span> K
<span class="Keyword">bind</span> K <span class="Keyword">confirm-before</span> <span class="String">"kill-window"</span>
<span class="Keyword">unbind</span> k
<span class="Keyword">bind</span> k <span class="Keyword">confirm-before</span> <span class="String">"kill-window"</span>

<span class="Comment"># redisplay ^L l</span>
<span class="Keyword">unbind</span> <span class="Special">^L</span>
<span class="Keyword">bind</span> <span class="Special">^L</span> <span class="Keyword">refresh-client</span>
<span class="Keyword">unbind</span> l
<span class="Keyword">bind</span> l <span class="Keyword">refresh-client</span>

<span class="Comment"># split -v |</span>
<span class="Keyword">unbind</span> |
<span class="Keyword">bind</span> | <span class="Keyword">split-window</span>

<span class="Comment"># :kB: focus up</span>
<span class="Keyword">unbind</span> Tab
<span class="Keyword">bind</span> Tab <span class="Keyword">select-pane</span><span class="Identifier"> -t</span>:.+
<span class="Keyword">unbind</span> BTab
<span class="Keyword">bind</span> BTab <span class="Keyword">select-pane</span><span class="Identifier"> -t</span>:.-

<span class="Comment"># " windowlist -b</span>
<span class="Keyword">unbind</span> <span class="String">'"'</span>
<span class="Keyword">bind</span> <span class="String">'"'</span> <span class="Keyword">choose-window</span>

<span class="Comment">######</span>
<span class="Comment"># Below here is largely from <a href="http://www.hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/">http://www.hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/</a></span>
<span class="Comment">######</span>

<span class="Comment"># split panes using | and -</span>
<span class="Keyword">bind</span> | <span class="Keyword">split-window</span><span class="Identifier"> -h</span>
<span class="Keyword">bind</span> - <span class="Keyword">split-window</span><span class="Identifier"> -v</span>
<span class="Keyword">unbind</span> <span class="String">'"'</span>
<span class="Keyword">unbind</span> %

<span class="Comment"># reload config file (change file location to your the tmux.conf you want to use)</span>
<span class="Keyword">bind</span> r <span class="Keyword">source-file</span> ~/.tmux.conf

<span class="Comment">######################</span>
<span class="Comment">### DESIGN CHANGES ###</span>
<span class="Comment">######################</span>

<span class="Comment"># panes</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">pane-border-fg</span> black
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">pane-active-border-fg</span> brightred

<span class="Comment">## Status bar design</span>
<span class="Comment"># status line</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-justify</span> left
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-bg</span> <span class="Boolean">default</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-fg</span> colour12
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-interval</span> <span class="Number">2</span>

<span class="Comment"># messaging</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">message-fg</span> black
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">message-bg</span> yellow
<span class="Keyword">set</span><span class="Identifier"> -g</span> message-command-fg blue
<span class="Keyword">set</span><span class="Identifier"> -g</span> message-command-bg black

<span class="Comment">#window mode</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> mode-bg colour6
<span class="Keyword">setw</span><span class="Identifier"> -g</span> mode-fg colour0

<span class="Comment"># window status</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-format</span> <span class="String">" #F#I:#W#F "</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-format</span> <span class="String">" #F#I:#W#F "</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-format</span> <span class="String">"#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W "</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-format</span> <span class="String">"#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W "</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-bg</span> colour0
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-fg</span> colour11
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-attr</span> dim
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-bg</span> green
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-fg</span> black
<span class="Keyword">setw</span><span class="Identifier"> -g</span> window-status-attr reverse

<span class="Comment"># Info on left (I don't have a session display for now)</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-left</span> <span class="String">''</span>

<span class="Comment"># loud or quiet?</span>
<span class="Keyword">set-option</span><span class="Identifier"> -g</span> <span class="Function">visual-activity</span> <span class="Boolean">off</span>
<span class="Keyword">set-option</span><span class="Identifier"> -g</span> <span class="Function">visual-bell</span> <span class="Boolean">off</span>
<span class="Keyword">set-option</span><span class="Identifier"> -g</span> <span class="Function">visual-silence</span> <span class="Boolean">off</span>
<span class="Keyword">set-window-option</span><span class="Identifier"> -g</span> <span class="Function">monitor-activity</span> <span class="Boolean">off</span>
<span class="Keyword">set-option</span><span class="Identifier"> -g</span> <span class="Function">bell-action</span> <span class="Boolean">none</span>

<span class="Comment"># The modes {</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">clock-mode-colour</span> colour135
<span class="Keyword">setw</span><span class="Identifier"> -g</span> mode-attr bold
<span class="Keyword">setw</span><span class="Identifier"> -g</span> mode-fg colour196
<span class="Keyword">setw</span><span class="Identifier"> -g</span> mode-bg colour238

<span class="Comment"># }</span>
<span class="Comment"># The panes {</span>

<span class="Keyword">set</span><span class="Identifier"> -g</span> pane-border-bg colour235
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">pane-border-fg</span> colour238
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">pane-active-border-bg</span> colour236
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">pane-active-border-fg</span> colour51

<span class="Comment"># }</span>
<span class="Comment"># The statusbar {</span>

<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-position</span> bottom
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-bg</span> colour234
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-fg</span> colour137
<span class="Keyword">set</span><span class="Identifier"> -g</span> status-attr dim
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-left</span> <span class="String">''</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-right</span> <span class="String">'#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-right-length</span> <span class="Number">50</span>
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">status-left-length</span> <span class="Number">20</span>

<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-fg</span> colour81
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-bg</span> colour238
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-attr</span> bold
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-current-format</span> <span class="String">' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '</span>

<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-fg</span> colour138
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-bg</span> colour235
<span class="Keyword">setw</span><span class="Identifier"> -g</span> window-status-attr <span class="Boolean">none</span>
<span class="Keyword">setw</span><span class="Identifier"> -g</span> <span class="Function">window-status-format</span> <span class="String">' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '</span>

<span class="Keyword">setw</span><span class="Identifier"> -g</span> window-status-bell-attr bold
<span class="Keyword">setw</span><span class="Identifier"> -g</span> window-status-bell-fg colour255
<span class="Keyword">setw</span><span class="Identifier"> -g</span> window-status-bell-bg colour1

<span class="Comment"># }</span>
<span class="Comment"># The messages {</span>

<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">message-attr</span> bold
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">message-fg</span> colour232
<span class="Keyword">set</span><span class="Identifier"> -g</span> <span class="Function">message-bg</span> colour166

<span class="Comment"># }</span>
```

### conky

Lastly, I'll give a quick shout-out to [conky](https://github.com/brndnmtthws/conky)! It's a fairly lightweight system monitor application that draws directly on the background (at least by default).

There's a ton you can do with conky! I looked at their example configurations until I found one that was nearly what I wanted, then I modified it to work for me.

It's not pretty, but this is what my conky configuration looks like:

```

background yes
cpu_avg_samples 2
net_avg_samples 2
out_to_console no
use_xft yes
xftfont Bitstream Vera Sans Mono:size=8
own_window_transparent no
own_window_colour hotpink
xftalpha 0.8
update_interval 1
own_window no
double_buffer yes
draw_shades no
draw_outline no
draw_borders no
stippled_borders 10
border_width 1
default_color white
default_shade_color white
default_outline_color white
gap_x 13
gap_y 13
alignment top_right
use_spacer none
no_buffers yes
uppercase no
TEXT
Conky :: $nodename - $sysname $kernel
$stippled_hr
${color lightgrey}Uptime:$color $uptime ${color lightgrey}- Load:$color $loadavg
${color lightgrey}CPU Usage:${color #5000a0} ${cpu}% ${cpubar}
${color lightgrey}Battery:$color ${battery} ${color lightgrey}:: Temp$color ${acpitemp}C
${color black}${cpugraph 000000 5000a0}
${color lightgrey}RAM Usage:$color $mem/$memmax - $memperc% $membar
${color lightgrey}Swap Usage:$color $swap/$swapmax - $swapperc% ${swapbar}
${color lightgrey}Processes:$color $processes  ${color grey}Running:$color $running_processes
$color$stippled_hr
${color lightgrey}Wireless (wlp4s0):
 Down:${color #8844ee} ${downspeed wlp4s0} k/s${color lightgrey} ${offset 70}Up:${color #22ccff} ${upspeed wlp4s0} k/s
${color black}${downspeedgraph wlp4s0 32,150 ff0000 0000ff} $alignr${color black}${upspeedgraph wlp4s0 32,150 0000ff ff0000}
${color lightgrey}Wired (enp0s31f6):
 Down:${color #8844ee} ${downspeed enp0s31f6} k/s${color lightgrey} ${offset 70}Up:${color #22ccff} ${upspeed enp0s31f6} k/s
${color black}${downspeedgraph enp0s31f6 32,150 ff0000 0000ff} $alignr${color black}${upspeedgraph enp0s31f6 32,150 0000ff ff0000}
${color lightgrey}File systems:
 / $color${fs_used /}/${fs_size /} ${fs_bar /}
${color}Name              PID     CPU%   MEM%
${color #ddaa00} ${top name 1} ${top pid 1} ${top cpu 1} ${top mem 1}
${color lightgrey} ${top name 2} ${top pid 2} ${top cpu 2} ${top mem 2}
${color lightgrey} ${top name 3} ${top pid 3} ${top cpu 3} ${top mem 3}
${color}Mem usage
${color #ddaa00} ${top_mem name 1} ${top_mem pid 1} ${top_mem cpu 1} ${top_mem mem 1}
${color lightgrey} ${top_mem name 2} ${top_mem pid 2} ${top_mem cpu 2} ${top_mem mem 2}
${color lightgrey} ${top_mem name 3} ${top_mem pid 3} ${top_mem cpu 3} ${top_mem mem 3}
```

## Conclusion

So yeah, that wound up longer than I'd intended, but that's my set up for development (and day-to-day life)!

I'm thinking of doing a similar blog about my hacking tools instead of development - what I use for debugging, disassembling, packet sniffing, and other tools I use - I have a decent collection, some of them probably pretty obscure!