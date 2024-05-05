---
id: 2294
title: 'Something different: my coding / Linux environment'
date: '2016-12-21T18:28:38-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2016/2289-revision-v1'
permalink: '/?p=2294'
---

Hey world,

I was asked by [The Setup](http://usesthis.com) to write a piece about my development environment, and I thought others might be interested in the tools I use for development and hacking. So here it is!

This is going to be weird, because I normally post about facts rather than talking about myself. But we'll see how it goes!

## Coding

### Languages

A lot of people ask me what my favourite language is. There's always language wars, people saying "C is better than Java!" or "Python is better than C!" or all these other weird comparisons.

I mean, we all know that Ruby is the best, right? :)

But seriously: I strongly believe that a variety of languages have their own useful purposes. Some languages are better at some things, and other languages are better at other things. I typically use C when I need low-level, Ruby when I need high level, Javascript when I'm doing Web stuff, Lua when I need to embed it in another program (like Nmap and Wireshark), x86/x86-64 assembly when I'm hacking, Python when I'm at work, and probably other languages as needed.

I don't think anybody should marry themselves to a single language to the detriment of others; in fact, I think a well-rounded developer is much more useful than a focused one. You'll certainly find it easier to get a job, if nothing else!

### Editor: neovim

Speaking of holy wars, let's talk about editors!

Note: I'm not going to teach how to use vi/vim/neovim; there are thousands of pages written for exactly that purpose, so it wouldn't be a valuable use of time. Also, it seriously takes years to really become an efficient vim user!

I use [Neovim](https://neovim.io/) these days (though I'll call it 'vim' occasionally out of laziness). But no, I'm not against emacs. I've never learned how to use emacs, but I have 15 or so years of vim muscle memory built up! I've never found a graphical editor that I like, either, though I've never tried Sublime. I do, however, find it extremely hard to believe I could ever be as quick and efficient on any editor other than vim.

I was forced to learn vi when I took first year programming. Our professor insisted on us using it for homework, and even had questions on the final. That was ~15 years ago, and I hated it. But I forced myself to use it on our old Solaris/SunOS systems through early university. No syntax highlighting, no fancy plugins, nothing like that.

As time went on, I started using plugins, and even found a manager, [Janus](https://github.com/carlhuda/janus). It came with a bunch of built-in plugins, but it was kind of a pain to use. I couldn't cleanly copy over my ~/.vimrc folder to new systems, a few things didn't work out of the box. I was also always unclear of which plugins were installed, and which were enabled, and how to add more. So I just kept the defaults for years and years and years.

A couple months ago, I decided to drop Janus and give Neovim a shot. It had really simple built-in plugin management! [Here's my init.vim file](https://gist.github.com/iagox86/f96965fb2c6fa5b98077fb25a1bdb1ee) for reference, but I'll go over the important stuff.

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

"base16" has a ton of nice colourschemes, I just picked my favourite one, "PhD".

Another handy plugin is [Deoplete](https://github.com/Shougo/deoplete): an asynchronous auto-complete library. It picks up commands when you're typing and suggests them later. I don't 100% love my configuration of this yet, but this is what I have:

```

<span class="Comment">" Asynchronous auto-complete</span>
<span class="Comment">"</span> <span class="PreProc">See:</span><span class="Comment"> <a href="https://github.com/Shougo/deoplete.nvim/blob/master/doc%2Fdeoplete.txt">https://github.com/Shougo/deoplete.nvim/blob/master/doc%2Fdeoplete.txt</a></span>
Plug <span class="String">'Shougo/deoplete.nvim'</span>, <span class="Delimiter">{</span> <span class="String">'do'</span>: <span class="String">':UpdateRemotePlugins'</span> <span class="Delimiter">}</span>
Plug <span class="String">'zchee/deoplete-jedi'</span>
<span class="Statement">let</span> <span class="Identifier">g:deoplete#enable_at_startup</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:airline#extensions#tabline#enabled</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:deoplete#enable_ignore_case</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:deoplete#auto_complete_start_length</span> <span class="Operator">=</span> <span class="Number">0</span>
<span class="Statement">set</span> <span class="PreProc">completeopt</span>+=preview,
<span class="Statement">let</span> <span class="Identifier">g:auto_complete_start_length</span> <span class="Operator">=</span> <span class="Number">0</span>
<span class="Statement">let</span> <span class="Identifier">g:deoplete#enable_refresh_always</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:deoplete#enable_debug</span> <span class="Operator">=</span> <span class="Number">0</span>
<span class="Statement">let</span> <span class="Identifier">g:deoplete#enable_profile</span> <span class="Operator">=</span> <span class="Number">0</span>
```

[Syntastic](https://github.com/scrooloose/syntastic) is a plugin that does syntax checking as you're typing. I often need to disable this, using <tt>:SyntasticToggleMode</tt>, but I like having it on by default:

```

<span class="Comment">" Syntax checking</span>
Plug <span class="String">'scrooloose/syntastic'</span>
<span class="Statement">set</span> <span class="PreProc">statusline</span>+=%#warningmsg#
<span class="Statement">set</span> <span class="PreProc">statusline</span>+=%{SyntasticStatuslineFlag()}
<span class="Statement">set</span> <span class="PreProc">statusline</span>+=%*
<span class="Statement">let</span> <span class="Identifier">g:syntastic_always_populate_loc_list</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:syntastic_auto_loc_list</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:syntastic_check_on_open</span> <span class="Operator">=</span> <span class="Number">1</span>
<span class="Statement">let</span> <span class="Identifier">g:syntastic_check_on_wq</span> <span class="Operator">=</span> <span class="Number">0</span>
```

And finally, a shout out to the plugin [NarrowRegion](https://github.com/chrisbra/NrrwRgn):

```

<span class="Comment">" Narrow Region</span>
Plug <span class="String">'chrisbra/NrrwRgn'</span>
<span class="Statement">map</span> <span class="Delimiter"><</span><span class="Special">leader</span><span class="Delimiter">></span>r :NarrowRegion<span class="Delimiter"><</span><span class="Special">CR</span><span class="Delimiter">></span>
```

If you want to work on a small piece of your code or document, you can highlight it (using <tt>v</tt>) and type <tt>:NarrowRegion</tt> or <tt>\\r</tt>. It moves that block into its own window where you can do anything you want to it, using standard vim commands. When you are done, you can use <tt>:wq</tt> to copy that buffer back where it came from!

I frequently use it when I'm writing blogs to pull out blocks of code to work on independently from the rest of the blog. Then I can enable syntax highlighting and stuff to make it easier to work on before copying back into my HTML-formatted blog format.

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
4   * Terminmal mode
[...]
```

When you search in neovim (using <tt>/<string></string></tt>), you can make it semi-case-sensitive with these commands:

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

This makes tabs sane (<tab> becomes two spaces):</tab>

```

<span class="Comment">" Tabstops</span>
<span class="Statement">set</span> <span class="PreProc">tabstop</span>=2
<span class="Statement">set</span> <span class="PreProc">shiftwidth</span>=2
<span class="Statement">set</span> <span class="PreProc">softtabstop</span>=2
<span class="Statement">set</span> <span class="PreProc">expandtab</span>
```

Another handy setting, which remembers where in a file you were, and goes back to that location next time you open the file:

```

<span class="Comment">" Return to the same spot in the file that we were at</span>
<span class="Statement">if</span> <span class="Function">has</span><span class="Delimiter">(</span><span class="String">"autocmd"</span><span class="Delimiter">)</span>
  <span class="Statement">au</span> <span class="Type">BufReadPost</span> * <span class="Statement">if</span> <span class="Function">line</span><span class="Delimiter">(</span><span class="String">"'\""</span><span class="Delimiter">)</span> <span class="Operator">></span> <span class="Number">0</span> &amp;&amp; <span class="Function">line</span><span class="Delimiter">(</span><span class="String">"'\""</span><span class="Delimiter">)</span> <span class="Operator"><=</span> <span class="Function">line</span><span class="Delimiter">(</span><span class="String">"$"</span><span class="Delimiter">)</span>
<span class="Special">    \</span>| <span class="Statement">exe</span> <span class="String">"normal! g'\""</span> | <span class="Statement">endif</span>
<span class="Statement">endif</span>
```

And finally, neovim has cool terminal support! You can open a terminal using <tt>:terminal</tt> and, more importantly, escape the terminal by holding Ctrl and pressing <tt>\\n</tt>. These commands make it a little easier to switch windows and escape from terminal windows:

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
```

There are plenty more settings that I really like, but I want to spend a little time talking about my Linux environment. :)

## Linuxing

I have been a Linux user for ~15 years, and used Linux as my primary operating system for probably 10 or more years at this point. I have a single Windows laptop, but everything else I use is Linux (including my work devices, and even technically my phone). I used Slackware for the first few years, then Gentoo for many years. Now I'm using Ubuntu as of a few months ago, largely because it automatically recognized my new laptop's harddrives (Gentoo couldn't find it, and I couldn't figure out which driver was missing).

In that time, I've realized I like fairly stripped-down and bare-bones stuff. That's why I use [Fluxbox](http://fluxbox.org/) as my window manager, and [xbindkeys ](http://www.nongnu.org/xbindkeys/) (I'll cover my configurations later). I used to use [WindowMaker](https://windowmaker.org/), but some random guy on a bus one time convinced me to try Fluxbox, and I fell in love.

Basically, I want a window manager with the minimal possible footprint (in terms of screen realestate), but lets me easily switch between virtual desktops. That's basically all I want. And Fluxbox does basically that. :)

The two things I use most are terminals (xterm) and my browser (Chrome). Within xterm, I frequently use [tmux ](https://tmux.github.io/) for multiplexing sessions.

Let's look at all that stuff in a bit more detail!

### dotfiles

If you use Linux on more than one system, even serially (one system at a time), save yourself some trouble and make a dotfiles repository on github (or your favourite git service). I have a folder on my machine (~/tools/dotfiles) that stores all my dotfiles that I want to share between machines:

```

$ <strong>ls -a ~/tools/dotfiles/</strong>
.                      .conkyrc          .gimp-2.8   .tmux.conf
..                     .editorconfig     .git        .xbindkeysrc
52-synaptics.conf      .fceux            .MakeMKV    .xrandr
.bash_ron              .fluxbox          README.txt  .Xresources
.config                .frictionalgames  .screenrc   .zsnes
```

I keep them in a private github repository. The README.txt file is actually instructions on how to install the software that I like and any configuration stuff that can't be done with dotfiles.

### Fluxbox

I honestly don't configure Fluxbox that much. I set the background to plain black, and the "slit" (like a taskbar) to auto-hide, and to use the mousewheel to change virtual desktops. Outside of that, I don't really do much in the way of configuration. The menu and stuff are all defaults, becuse I don't actually use them.

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

<span class="Comment"># Turn on palm detection</span>
synclient <span class="Identifier">PalmDetect</span>=<span class="Number">1</span>

<span class="Statement">exec</span> fluxbox
```

On fluxbox, I use xbindkeys to start the programs I commonly used, which are basically just chrome and xterm.

### xbindkeys

xbindkeys is a wonderful way to bind hotkeys to programs. I use it *constantly*. I use alt-a to bring up xterm (at the time, I used aterm), and alt-c to bring up Chrome. I also use it for a couple other small things.

Here's my ~/.xbindkeysrc file:

```

<span class="Comment">###########################</span>
<span class="Comment"># xbindkeys configuration #</span>
<span class="Comment">###########################</span>
<span class="Comment">#</span>
<span class="Comment"># Version: 1.7.1</span>
<span class="Comment">#</span>
<span class="Operator">"</span><span class="String">uxterm -ls -sl 5000</span><span class="Operator">"</span>
  <span class="Statement">shift</span> + alt + a

<span class="Operator">"</span><span class="String">uxterm -ls -sl 5000 -fg white -bg black</span><span class="Operator">"</span>
  alt + a

<span class="Operator">"</span><span class="String">google-chrome-beta</span><span class="Operator">"</span>
  alt + c

<span class="Operator">"</span><span class="String">xlock -mode blank</span><span class="Operator">"</span>
  alt + l

<span class="Operator">"</span><span class="String">xlock -mode blank</span><span class="Operator">"</span>
  Mod<span class="Number">4</span> + l

<span class="Operator">"</span><span class="String">xlock -mode blank &amp; sleep 1; sudo pm-suspend</span><span class="Operator">"</span>
  alt + k

<span class="Operator">"</span><span class="String">killall X</span><span class="Operator">"</span>
  Control+Alt + BackSpace

<span class="Operator">"</span><span class="String">firefox</span><span class="Operator">"</span>
  alt + f
```

It's probably best to ignore my alt+k hacks to suspend my laptop... some day, I'll learn how to do that right. :)

I don't think there's really much more to say about this, so let's talk xterm!

### xterm

I've tried almost every terminal on Linux, and I always wind up back on xterm due to bugs or annoyances. Really, I just want a place where I can type in commands. If it has a nice font and stuff, that's a bonus!

I only recently learned how to configure xterm using an Xresources file. This is what my ~/.Xresources file looks like:

```

<span class="Comment">/* To merge: xrdb -merge ~/.Xresources */</span>

<span class="Comment">/* From <a href="https://unix4lyfe.org/xterm/">https://unix4lyfe.org/xterm/</a> */</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">font</span><span class="Normal">:</span><span class="Constant"> terminus-12</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">loginShell</span><span class="Normal">:</span><span class="Constant"> true</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">vt100</span><span class="Normal">*</span><span class="Type">geometry</span><span class="Normal">:</span><span class="Constant"> 80x30</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">termName</span><span class="Normal">:</span><span class="Constant"> xterm-color</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">eightBitInput</span><span class="Normal">:</span><span class="Constant"> false</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">boldMode</span><span class="Normal">:</span><span class="Constant"> false</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">colorBDMode</span><span class="Normal">:</span><span class="Constant"> true</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">colorBD</span><span class="Normal">:</span><span class="Constant"> rgb:fc/fc/fc</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">cutNewLine</span><span class="Normal">:</span><span class="Constant"> false</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">cutToBeginningOfLine</span><span class="Normal">:</span><span class="Constant"> false</span>
<span class="Type">xterm</span><span class="Normal">*</span><span class="Type">charClass</span><span class="Normal">:</span><span class="Constant"> 33:48, 35:48, 37:48, 42-47:48, 58:48, 63-64:48, 95:48, 126:48</span>
```

Most of that is pretty self explanatory. The last line is valuable to mention, though: xterm considers each character to be part of a "class". When you double-click a line in an xterm window, it selects all adjacent characters that are the same "class".

Class '48' (aka, 0x30 or '0') are for letters and numbers, and they let you double-click to select a word. That last line maps a bunch of extra stuff (like ':', '/', '@', '.', etc) to also look like characters to xterm, which lets you double-click to select a URL, email address, etc.

### tmux

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

If this gets a good reaction, I will do another similar writeup that focuses on my hacking environment. I can talk debuggers, disassemblers, packet sniffers, and other tools I use while hacking - I have a decent collection, some of them probably pretty obscure!