---
id: 2451
title: 'BSidesSF CTF: Difficult reverse engineering challenge: Gman'
date: '2020-02-26T12:46:30-05:00'
author: ron
layout: post
guid: 'https://blog.skullsecurity.org/?p=2451'
permalink: /2020/bsidessf-ctf-difficult-reverse-engineering-challenge-gman
categories:
    - conferences
    - ctfs
---

Once again, it was my distinct privilege to be a BSidesSF CTF organizer! As somebody who played CTFs for years, it really means a lot to me to organize one, and watch folks struggle through our challenges. And more importantly, each person that comes up to us and either thanks us or tells us they learned something is a huge bonus!

But this week, I want to post writeups for some of the challenges I wrote. I'm starting with my favourite - Gman!
<!--more-->
Gman is a clone of Pacman. I tried hard to make it pretty, though it doesn't seem like it looks great in most terminals, which is kind of sad. But here's what it's supposed to look like:

<img src="https://blogdata.skullsecurity.org/gman-1.png" />

The trick to solving it was two-fold:

<ol>
<li>There is a password screen that lets you skip levels</li>
<li>Level 101 is a "kill screen" - it lets you play the game in stack memory</li>
</ol>

<h2>The password</h2>

This is what the password entry looks like:

<pre>
       A   B   C   D   E   F   G
      ┌───┬───┬───┬───┬───┬───┬───┐
    1 │   │   │ ◆ │ ◆ │   │   │   │
      ├───┼───┼───┼───┼───┼───┼───┤
    2 │ ◆ │   │ ◆ │   │ ◆ │   │   │
      ├───┼───┼───┼───┼───┼───┼───┤
    3 │ ◆ │ ◆ │ ◆ │   │   │   │   │
      ├───┼───┼───┼───┼───┼───┼───┤
    4 │ ◆ │   │   │   │   │   │ ◆ │
      ├───┼───┼───┼───┼───┼───┼───┤
    5 │   │   │   │   │ ◆ │ ◆ │ ◆ │
      ├───┼───┼───┼───┼───┼───┼───┤
    6 │   │   │ ◆ │   │ ◆ │   │ ◆ │
      ├───┼───┼───┼───┼───┼───┼───┤
    7 │   │   │   │ ◆ │ ◆ │   │   │
      └───┴───┴───┴───┴───┴───┴───┘
       Toggle with &lt;space&gt;
       Submit with &lt;enter&gt;
</pre>

The password is actually three 8-bit values - level, lives, and random seed. It's stored in a grid of 49 bits. The grid is rotationally symmetric - that means each bit in the data is represented by two bits in the grid, for a total of 48 bits. Notice that if you take the top-left triangle and rotate it 180 degrees around its center, you get the bottom-right half.

The final bit - the single bit center of the grid - is a parity bit. It's set to 1 for an even number of bits, and 0 for an odd number.

You can find the full code <a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/gman/challenge/src/password.c#L75">here</a>, but here is the important part (with formatting code stripped out):

<pre>
// We can store 24 bits of data
void print_password(uint8_t a, uint8_t b, uint8_t c) {
  // Pack into a uint32
  uint32_t passcode = (a << 16 | b << 8 | c);

  // Xor it to make it more random looking
  passcode = passcode ^ 0x555555;

  // Set each bit appropriately
  int i;
  // Setting the checksum to 1 means that all-blank won't be valid
  int checksum = 1;
  int bit = 23;
  for(i = 0; i < 7; i++) {
    int j;
    for(j = 0; j < (i > 2 ? (6 - i) : (7 - i)); j++) {
      uint8_t thischar = (passcode >> bit) & 0x01 ? 1 : 0;
      bit--;

      // Count the number of bits
      checksum ^= thischar;
      print_to_grid(j, i, thischar ? ACS_DIAMOND : ' ');
      print_to_grid(6-j, 6-i, thischar ? ACS_DIAMOND : ' ');
    }
  }

  // Print the checksum
  print_to_grid(3, 3, checksum ? ACS_DIAMOND : ' ');
}
</pre>

Note that it prints a triangle - the first row, it prints 7 characters; the second, it prints 6, and so on. Meanwhile, it prints the same to the other half of the grid.

The only value that ultimately matters is the level. I wanted to use the full 24 bits, so I stored the number of lives (for verisimilitude - that's what a game would do, right?) as well as the random seed (I kept getting killed by my own AI! thought it'd be helpful).

The code above works out to level 101, and there are 100 initialized levels. The trick of the password is getting to level 101, which the code above will do for you.

<h2>Eating up the stack</h2>

If you go to level 101, it's going to look a bit different depending on your operating system, libraries, etc. But this is what it looks like on mine:

<img src="https://blogdata.skullsecurity.org/gman-2.png" />

The two important values are <a href="https://github.com/BSidesSF/ctf-2020-release/blob/master/gman/challenge/src/gman.c#L800">at the start of <tt>instructions()</tt></a>:

<pre>
char name[256];
void instructions() {
  char *highscore_file = "/home/ctf/highscores.txt";
</pre>

The <tt>name</tt> variable is user-controlled, and the <tt>highscore_file</tt> variable is read and displayed at the end. I spent a lot of time with a totally working game before deciding what the exploitation path was - hence adding highscores.

Coincidentally (but not really, because I tried really hard to make it work like this), you can unset bits from <tt>highscore_file</tt> to point it instead at the <tt>name</tt> pointer:

<pre>
FILE: 0x0804d1f9 => 11111001110100010000010000001000
NAME: 0x08041140 => 01000000000100010000010000001000
           Unset => ^ ^^^  ^^^
</pre>

On the actual game board, that looks like:

<img src="https://blogdata.skullsecurity.org/gman-3.png" />

If you eat those bits, then either die or press 'q', you'll get the flag instead of the highscores:

<img src="https://blogdata.skullsecurity.org/gman-4.png" />

And that's it!

<h2>An emergent bug</h2>

One small bug that was unintentionally but turned out be really helpful: the "ghosts" can't turn 180 degrees, which means if a ghost ends up wandering into a square with only one way out, it gets stuck - ghost D and B are stuck in the same square here:

<img src="https://blogdata.skullsecurity.org/gman-3.png" />

Originally it caused an infinite loop looking for a direction to go. I actually found it really helpful while testing to get all the ghosts stuck, so I decided not to fix it completely - now if they get stuck, they just give up and you can roam freely!
