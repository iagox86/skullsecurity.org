---
title: 'BSidesSF 2026: miscellaneous challenges (if-it-leads, gitfab, jengacrypt)'
author: ron
layout: post
categories:
- bsidessf-2026
- bsidessf
- ctfs
- misc
---

This will be a write-up for the three shorter / more miscellaneous challenges
I wrote:

* `if-it-leads`
* `gitfab`
* `jengacrypt`

As always, you can find copies of the binaries, containers, and full solution
in our [GitHub repo](https://github.com/BSidesSF/ctf-2026-release)!

<!--more-->

# `if-it-leads`

I wanted to do a Citrixbleed-style challenge ever since the vulnerability came
out, and this is it!

The TL;DR behind Citrixbleed2 (CVE-2023-4966) (and also this challenge) is that `snprintf` has
a surprising behavior: it doesn't return the number of bytes it wrote, it returns
the number of bytes it *wanted* to write. So if it tries to write more than
the `length` value, it'll return a different size than what was actually
written.

The specifically problematic line is:

```c
  fprintf(stderr, "Release year? --> ");
  int year;
  if(scanf("%d", &year) != 1) {
    fprintf(stderr, "Invalid year!\n");
    exit(1);
  }
  offset += snprintf(idv3 + offset, 5, "%04d", year);
  while(getchar() != '\n') {}  // discard rest of line
```

An integer can be up to 11 characters long (counting the `-` for negative
numbers). Even though we use the format specifier `%04d`, the user can enter
up to 11 characters, and instead of the offset increasing by 4 bytes (like it
looks like it's supposed to), it increases by up to 11. That means that you can
read about 6 bytes past the end of the buffer.

It just so happens - not coincidentally - that that's where the secret password
lies.

I didn't love using a secret password in addition to the flag, but I only had
about 6 characters and by the time we have the `CTF{...}` part of the flag,
we didn't have any space left.

Making it a 64-bit integer or a string would have made the challenge too
obvious, in my opinion.

# `gitfab`

I had this idea, "I'll implement that vulnerability from GitLab and call it
'Git Fab'!". That seemed fun. Then I finished the challenge and looked up the
reference and realized it was Bit Bucket (CVE-2022-36804), not GitLab. Oops :)

In any case, I mostly just told AI to write a git viewer and make sure it wasn't
vulnerable to command injection. Then I took the output and found the command
injection issue (which is what I expected - nobody remembers to check for
newlines in shell commands!)

There are definitely other solutions, but I used a newline and command injection:

```ruby
response = HTTParty.get("#{ base_url }/file/test%22%0acat%20/home/ctf/flag.txt%0aecho%20%22")
```

I'm pretty sure you can also just add a space and another argument to the URL as well,
to view a second file; this wasn't supposed to be a hard challenge!

# `jengacrypt`

This was a cryptosystem I thought up in a fever dream (when I fell asleep watching
some cartoon about Jenga).

It's a bit-wise cryptosystem where the key tells you what to do with the first 3
bits of the plaintext: either move the second bit to the end or the first and
third bits. Just like Jenga, get it??

Here's the encryption code, in C:

```c
void encrypt_bits(uint8_t *data, int64_t data_length, uint8_t *key, int64_t key_length) {
  int64_t i;
  uint64_t end = ((data_length - 1) / 3) * 3;
  uint64_t key_bit = 0;

  for(i = 0; i < end;) {
    uint8_t bit = get_bit_from_array((uint8_t*)key, key_length, key_bit);

    // We work in groups of three bits
    // If it's a 0, move the middle bit of the three to the "top"
    // If it's a 1, move the first and third bit
    // fprintf(stderr, "(%2d) %d: ", i, bit);
    if(bit == 1) {
      // fprintf(stderr, "(%2d) |%d  | ", key_bit, i + 1);
      move_bit_to_end(data, i + 1, data_length);
      i += 2;
    } else {
      // fprintf(stderr, "(%2d) |%d %d| ", key_bit, i, i + 2);
      move_bit_to_end(data, i + 0, data_length);
      move_bit_to_end(data, i + 1, data_length);
      i += 1;
    }
    key_bit++;
    // fprintf(stderr, "\n");
  }

  // fprintf(stderr, "After:  ");
  // print_bits_array(data, data_length);
}
```

And here's the C decryption code (that wasn't included).. it's not super nice,
but it works:

```c
void decrypt_bits(uint8_t *data, int64_t data_length, uint8_t *key, int64_t key_length) {
  int64_t i;

  // Calculate the starting key_bit and offset
  uint64_t end = ((data_length - 1) / 3) * 3;
  uint64_t key_bit = 0;
  uint64_t start;
  for(i = 0; i < end;) {
    uint8_t bit = get_bit_from_array((uint8_t*)key, key_length, key_bit++);
    if(bit == 1) {
      start = i;
      i += 2;
    } else {
      start = i;
      i += 1;
    }
  }
  key_bit--; // We go one too far

  // Round down to the nearest multiple of 3
  // fprintf(stderr, "Length = %2d\n", data_length);
  for(i = start; i >= 0; ) {
    uint8_t bit = get_bit_from_array((uint8_t*)key, key_length, key_bit);

    // We work in groups of three bits
    // If it's a 0, move the middle bit of the three to the "top"
    // If it's a 1, move the first and third bit
    // fprintf(stderr, "(%2d) %2d: ", i, bit);
    if(bit == 1) {
      // fprintf(stderr, "(%2d) |%d/%c|   ", key_bit, i + 1, data[data_length - 1]);
      // fprintf(stderr, " %s", data);
      move_bit_from_end(data, i + 1, data_length);
    } else {
      // fprintf(stderr, "(%2d) |%d/%c %d/%c|", key_bit, i + 2, data[data_length - 1], i + 0, data[data_length - 2]);
      // fprintf(stderr, " %s", data);
      move_bit_from_end(data, i + 1, data_length);
      move_bit_from_end(data, i, data_length);
    }

    key_bit--;

    uint8_t last_bit = get_bit_from_array((uint8_t*)key, key_length, key_bit);
    if(last_bit == 1) {
      i -= 2;
    } else {
      i -= 1;
    }

    // fprintf(stderr, " -> %s\n", data);

    // fprintf(stderr, "%s\n", data);
  }
}
```

And that's it!
