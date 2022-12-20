---
id: 2521
title: 'BSidesSF CTF 2021 Author writeup: secure-asset-manager, a reversing challenge similar to Battle.net bot dev'
date: '2021-03-17T10:59:18-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2521'
permalink: /2021/bsidessf-ctf-2021-author-writeup-secure-asset-manager-a-reversing-challenge-similar-to-battle-net-bot-dev
categories:
    - CTFs
    - Hacking
    - 'Reverse Engineering'
---

Hi Everybody!

This is going to be a challenge-author writeup for the <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/secure-asset-manager">Secure Asset Manager</a> challenge from <a href="https://ctftime.org/event/1299">BSides San Francisco 2021</a>.

It's designed to be a sort of "server management software". I sort of chose that theme to play off the Solarwinds thing, the theme wasn't super linked to the challenge.

The challenge was to analyze and reverse engineer a piece of client-side software that "checks in" with a server. For the check-in, the client is required to "validate" itself. The server sends a random "challenge" - which is actually a block of randomized x86 code - and that code used to checksum active memory to prevent tampering. If anybody reading this worked on bots for the original Starcraft (and other Battle.net games), this might seem familiar! It's based on Battle.net's <a href="https://bnetdocs.org/document/47/checkrevision">CheckRevision</a> code.
<!--more-->
<h2>Server</h2>
The players don't normally get to see it, but <a href="https://github.com/BSidesSF/ctf-2021-release/tree/main/secure-asset-manager/challenge/server">this is my server code</a>. I'd like to draw your attention to <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/secure-asset-manager/challenge/server/assembly-generator.rb">assembly-generator.rb</a> in particular, which is what creates the challenge. It just does a whole bunch of random, and really bad checksumming with a few instructions and also randomized NOPs:
<pre>  0.upto(rand(1..5)) do
    0.upto(rand(2..5)) do
      # Do something to the value a few times
      s.push([
        "xor eax, #{ random_int }",
        "add eax, #{ random_int }",
        "sub eax, #{ random_int }",
        "ror eax, #{ rand(1..30) }",
        "rol eax, #{ rand(1..30) }",
      ].sample)
    end

    # Mix in the previous value (or seed)
    s.push("xor ecx, eax")
    s.push('')
    s.push(nop())
  end
</pre>
The server dumps all those random instructions into a file, assembles it with <tt>nasm</tt>, and sends over the resulting code.

To generate a checksum on the server side, I actually used what I'd consider a solution: dumping client memory.
<h2>First solution: dump memory</h2>
To validate the client, the server wraps <tt>gdb</tt> (the GNU Debugger) and sends commands to dump process memory. Here's the code:
<pre><span class="Statement">def</span> <span class="Function">dump_binary</span>(binary, target)
  <span class="rubyConstant">L</span>.info(<span class="rubyStringDelimiter">"</span><span class="String">Dumping memory from </span><span class="rubyInterpolationDelimiter">#{</span> binary <span class="rubyInterpolationDelimiter">}</span><span class="String"> using gdb...</span><span class="rubyStringDelimiter">"</span>)

  <span class="Statement">begin</span>
    <span class="rubyConstant">Timeout</span>.timeout(<span class="Number">3</span>) <span class="Statement">do</span>
      <span class="rubyConstant">Open3</span>.popen2(<span class="rubyStringDelimiter">"</span><span class="String">gdb -q </span><span class="rubyInterpolationDelimiter">#{</span> binary <span class="rubyInterpolationDelimiter">}</span><span class="rubyStringDelimiter">"</span>) <span class="Statement">do</span> |i, o, t|
        <span class="Comment"># Don't confirm things</span>
        i.puts(<span class="rubyStringDelimiter">"</span><span class="String">set no-confirm</span><span class="rubyStringDelimiter">"</span>)

        <span class="Comment"># Breakpoint @ malloc - we just need to stop anywhere</span>
        i.puts(<span class="rubyStringDelimiter">"</span><span class="String">break malloc</span><span class="rubyStringDelimiter">"</span>)

        <span class="Comment"># Run the executable</span>
        i.puts(<span class="rubyStringDelimiter">"</span><span class="String">run</span><span class="rubyStringDelimiter">"</span>)

        <span class="Comment"># Remove the breakpoint - this is VERY important, the breakpoint will mess</span>
        <span class="Comment"># up the memory dump!</span>
        i.puts(<span class="rubyStringDelimiter">"</span><span class="String">delete</span><span class="rubyStringDelimiter">"</span>)

        <span class="Comment"># Get the pid</span>
        i.puts(<span class="rubyStringDelimiter">"</span><span class="String">print (int) getpid()</span><span class="rubyStringDelimiter">"</span>)

        <span class="Statement">loop</span> <span class="Statement">do</span>
          out = o.gets().strip()
          puts(out)
          <span class="Statement">if</span> out =~ <span class="rubyStringDelimiter">/</span><span class="Special">\$</span><span class="rubyRegexp">1 = </span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9</span><span class="Special">]</span><span class="Special">+</span><span class="Special">)</span><span class="rubyStringDelimiter">/</span>
            <span class="rubyConstant">L</span>.info(<span class="rubyStringDelimiter">"</span><span class="String">Found PID: </span><span class="rubyInterpolationDelimiter">#{</span> <span class="Identifier">$1</span> <span class="rubyInterpolationDelimiter">}</span><span class="rubyStringDelimiter">"</span>)
            <span class="rubyConstant">L</span>.info(<span class="rubyStringDelimiter">"</span><span class="String">Reading /proc/</span><span class="rubyInterpolationDelimiter">#{</span> <span class="Identifier">$1</span> <span class="rubyInterpolationDelimiter">}</span><span class="String">/maps to find memory block</span><span class="rubyStringDelimiter">"</span>)
            mappings = <span class="rubyConstant">File</span>.read(<span class="rubyStringDelimiter">"</span><span class="String">/proc/</span><span class="rubyInterpolationDelimiter">#{</span> <span class="Identifier">$1</span> <span class="rubyInterpolationDelimiter">}</span><span class="String">/maps</span><span class="rubyStringDelimiter">"</span>).split(<span class="rubyStringDelimiter">/</span><span class="Special">\n</span><span class="rubyStringDelimiter">/</span>)

            mappings.each <span class="Statement">do</span> |m|
              <span class="Statement">if</span> m =~ <span class="rubyStringDelimiter">/</span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9a-f</span><span class="Special">]</span><span class="Special">+</span><span class="Special">)</span><span class="rubyRegexp">-</span><span class="Special">(</span><span class="Special">[</span><span class="rubyRegexp">0-9a-f</span><span class="Special">]</span><span class="Special">+</span><span class="Special">)</span><span class="rubyRegexp"> </span><span class="Special">(</span><span class="rubyRegexp">r-xp</span><span class="Special">)</span><span class="Special">.</span><span class="Special">*</span><span class="Special">\/</span><span class="rubyRegexp">secure-asset-manager</span><span class="Special">$</span><span class="rubyStringDelimiter">/</span>
                <span class="rubyConstant">L</span>.debug(<span class="rubyStringDelimiter">"</span><span class="String">Found memory block: </span><span class="rubyInterpolationDelimiter">#{</span> m <span class="rubyInterpolationDelimiter">}</span><span class="rubyStringDelimiter">"</span>)
                i.puts(<span class="rubyStringDelimiter">"</span><span class="String">dump memory </span><span class="rubyInterpolationDelimiter">#{</span> target <span class="rubyInterpolationDelimiter">}</span><span class="String"> 0x</span><span class="rubyInterpolationDelimiter">#{</span> <span class="Identifier">$1</span> <span class="rubyInterpolationDelimiter">}</span><span class="String"> 0x</span><span class="rubyInterpolationDelimiter">#{</span> <span class="Identifier">$2</span> <span class="rubyInterpolationDelimiter">}</span><span class="rubyStringDelimiter">"</span>)
                i.puts(<span class="rubyStringDelimiter">"</span><span class="String">quit</span><span class="rubyStringDelimiter">"</span>)

                <span class="Statement">loop</span> <span class="Statement">do</span>
                  out = o.gets()
                  <span class="Statement">if</span> !out
                    <span class="Statement">break</span>
                  <span class="Statement">end</span>
                  puts(out.strip())
                <span class="Statement">end</span>

                <span class="rubyConstant">L</span>.info(<span class="rubyStringDelimiter">"</span><span class="String">Memory from original binary dumped to </span><span class="rubyInterpolationDelimiter">#{</span> target <span class="rubyInterpolationDelimiter">}</span><span class="rubyStringDelimiter">"</span>)
                <span class="Statement">return</span>
              <span class="Statement">end</span>
            <span class="Statement">end</span>
          <span class="Statement">end</span>
        <span class="Statement">end</span>
      <span class="Statement">end</span>
    <span class="Statement">end</span>
  <span class="Statement">rescue</span> <span class="rubyConstant">Timeout</span>::<span class="rubyConstant">Error</span>
    <span class="rubyConstant">L</span>.fatal(<span class="rubyStringDelimiter">"</span><span class="String">Something went wrong dumping the binary! Check the gdb output above</span><span class="rubyStringDelimiter">"</span>)
    <span class="Statement">exit</span>(<span class="Number">1</span>)
  <span class="Statement">end</span>
<span class="Statement">end</span>
</pre>
Then I used a secondary script, which I called <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/secure-asset-manager/challenge/server/not-solution.c">not-solution.c</a>, to actually execute the code. But instead of performing the checksum on memory, it performs it on the dumped binary. It even uses <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/secure-asset-manager/challenge/common/validator.c">the same checksum function from the real client</a>:
<pre><span class="Type">uint32_t</span> checksum(data_block_t *code, data_block_t *binary) {
  <span class="Comment">// Allocate +rwx memory</span>
  <span class="Type">uint32_t</span> (*rwx)(<span class="Type">uint8_t</span>*, <span class="Type">uint8_t</span>*) = mmap(<span class="Number">0</span>, code-&gt;length, PROT_EXEC | PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_SHARED, -1, <span class="Number">0</span>);

  <span class="Comment">// Populate it with the code</span>
  memcpy(rwx, code-&gt;data, code-&gt;length);

  <span class="Comment">// Run the code</span>
  <span class="Type">uint32_t</span> result = rwx(binary-&gt;data, binary-&gt;data + binary-&gt;length);

  <span class="Comment">// Wipe and unmap the memory</span>
  memset(rwx, <span class="Number">0</span>, code-&gt;length);
  munmap(rwx, code-&gt;length);

  <span class="Statement">return</span> result;
}
</pre>
That server-side code is literally <a href="https://github.com/BSidesSF/ctf-2021-release/blob/main/secure-asset-manager/solution/solution.rb">what my solution does</a>, and I even use the same not-solution.c script to do it.

In retrospect, I need to stop using gdb in containers. It only causes headaches for our infrastructure guy, David. :)
<h2>Alternative solution: proxy</h2>
The first time I ever made a Starcraft bot, I used the real game client to connect, redirected it through a proxy, and once the connection was established, I'd disconnect the game and keep the bot going. It was crazy inefficient and a big pain to reconnect, but it worked and I was super proud of it!

I'm happy that at least one team solved it this way.

I actually don't have anything written that implements this, but I'd love to see a writeup where somebody did! I have no idea if there's any tooling out there that can make this easy.
<h2>Accidental solution: edit the binary</h2>
So it turns out, I only checksummed the code portion. You could freely change the data section of the binary (say, change the check-in command to the flag command) and everything Just Works. D'oh!
<h2>Conclusion</h2>
For years I've wanted to do a challenge like this. I'd actually like to repackage this and use a similar concept again, only a bit harder and with less opportunity to bypass it. Stay tuned for 2022!