---
title: 'BSidesSF 2025: bug-me (hard reversing challenge)'
author: ron
layout: post
categories:
- bsidessf-2025
- ctfs
permalink: "/2025/bsidessf-2025-bug-me-hard-reversing-challenge-"
date: '2025-04-27T15:59:05-07:00'

---

Every year, I make a list of ideas and it contains the same thing: "process that debugs itself". It's from a half-remembered Windows challenge I solved when I was very new to CTFs.

I'm obsessed with that concept, having messed with writing debuggers a few times (including [Mandrake](https://github.com/iagox86/mandrake)), and [blogging about process injection](https://www.labs.greynoise.io/grimoire/2025-01-28-process-injection/). You'll find a few challenges influenced by that those concepts thie yar, but this time we're gonna look at `bug-me`.

You can download source and the challenge (including solution) [here](https://github.com/BSidesSF/ctf-2025-release/tree/main/bug-me).

<!--more-->

## Concept

The premise of this reversing challenge is:

* A binary that debugs itself
* It intentionally causes exceptions
* When an exception happens, the debugger potion of the process handles it,
  changes something, and then returns control

That cool (cruel?) part of this is that if you run the process in a debugger, the process will (semi-silently) fail to debug itself and the exception will be handled by the debugger, and the exception handler will never run.

## Debugging yourself

So typically, a process will spawn a child process using `fork()`, and that child runs `PTRACE_TRACEME` to request debugging. From the `ptrace(2)` manpage:

> A process can initiate a  trace  by  calling  fork(2)  and  having  the  resulting  child  do  a
> PTRACE_TRACEME,  followed  (typically) by an execve(2).  Alternatively, one process may commence
> tracing another process using PTRACE_ATTACH or PTRACE_SEIZE.

The problem with that whole technique is that you can still debug the server (which is debugging its child), and that defeats the purpose of the challenge! I wanted it to be secret-ish.

So here's what happens: the process uses `fork` to spawn a child, and that *child* debugs the *parent* (which, saw I said, is unusual):

```c
  if(!FORK()) {
    // We're actually attaching a debugger to the parent, not the child, because
    // we don't want users seeing the parent code
    pid_t parent = GETPPID();
    if(PTRACE(PTRACE_ATTACH, parent, 0, 0) < 0) {
      EXIT(0);
    }

    // Wait for the attach to finish, then resume
    int status;
    WAITPID(parent, &status, 0);
    PTRACE(PTRACE_CONT, parent, -1, 0);
```

(Don't worry about the capitalized function names, I'll talk about that when I cover the obfuscation techniques)

That causes a small race condition, where the program can crash before the debugger actually attaches, so I added a `sleep(1)` and life's good!

## Crashing

Let's have a look at the main function.. it looks pretty innocuous:

```c
int main(int argc, char *argv[]) {
  // Fork a child
  if(argc != 2) {
    fprintf(stderr, "Usage: %s <flag>\n", argv[0]);
    exit(1);
  }

  // Some delay is required to ensure the parent gets its debugger attached
  printf("Loading...\n");
  sleep(1);
  printf("Checking your flag...\n");

  // Basic length check, if this is wrong things get weird
  if(strlen(argv[1]) != FLAG_LENGTH) {
    printf("Flag is not correct!!\n");
    exit(0);
  }

  int i;
  check_flag('\0', -1);
  int result = 0;
  for(i = 0; i < strlen(argv[1]); i++) {
    result += (check_flag(argv[1][i], i) == 0 ? 0 : 1);
    *((uint32_t*)0) = 0x5754463f;
  }
  if(result > 0) {
    printf("Flag is not correct!!\n");
  } else {
    printf("Flag is correct!! YAY!\n");
  }

  return -1;
}
```

It has some usage, it loops over the argument, and it validates the flag one character at a time.

But you might notice one important detail: this line will crash attempting to write the string `WTF?` to the `NULL` pointer:

```
*((uint32_t*)0) = 0x5754463f;
```

That's one of the two exceptions that the debugger will handle. The other one is in the `check_flag()` function.

### `check_flag()`

`check_flag()` is what you get when you ask Perplexity (AI) to generate a "long function with a lot of math". Sorry to anybody who actually tried to reverse it:

```c
// You can just ignore this function, it's written by AI and all it needs to
// do is a) be long, and b) cause a SIGFPE somewhere. :)
//
// For each character, it'll get overwritten by new code
int check_flag(int c, int i) {
  int a = c;
  int b = i;

  int result = 0;

  // Step 1: Multiply a by b
  int product = a * b;

  // Step 2: Add the square of their sum
  int sumSquare = (a + b) * (a + b);
  result = product + sumSquare;

  // [...............]

  // Step 21-40: Repeat various operations
  for (int i = 0; i < 20; i++) {
    result += i * a;
    result -= i * b;
    result *= (i + 1);
    result /= (i - 1); // <---------- This will SIGFPE exactly once
  }

  // [...............]

  // Step 181-200: Final arithmetic operations
  result += sum;
  result -= product;
  result *= abs(a);
  result /= abs(b) + 1;

  return result;
}
```

The first time the `SIGFPE` fires (due to divide-by-zero) is when the game starts!

It's also where the game ends if you're trying to use a debugger to solve it:

```
(gdb) run 'CTF{aaaaaaaaaaaaaaaaaaaaaaaaa}'
quit
Starting program: /home/ron/projects/ctf-2025/challenges/bug-me/distfiles/bug-me 'CTF{aaaaaaaaaaaaaaaaaaaaaaaaa}'
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib64/libthread_db.so.1".
[Detaching after fork from child process 57137]
Loading...
Checking your flag...
Program received signal SIGFPE, Arithmetic exception.
0x000055555555537f in ?? ()
```

Also `strace`:

```
$ strace ./bug-me 'CTF{aaaaaaaaaaaaaaaaaaaaaaaaa}'
execve("./bug-me", ["./bug-me", "CTF{aaaaaaaaaaaaaaaaaaaaaaaaa}"], 0x7ffd39496d98 /* 90 vars */) = 0
brk(NULL)                               = 0x5653a419a000                                                                                        
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3                                                                                    
fstat(3, {st_mode=S_IFREG|0644, st_size=103403, ...}) = 0             
mmap(NULL, 103403, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f0f288f5000
close(3)                                = 0
[...]
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f0f286fea10) = 57528
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0), ...}) = 0
getrandom("\xd4\x92\x5d\xee\xe0\x7a\xe4\x17", 8, GRND_NONBLOCK) = 8
brk(NULL)                               = 0x5653a419a000
brk(0x5653a41bb000)                     = 0x5653a41bb000
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=57528, si_uid=1000, si_status=0, si_utime=0, si_stime=0} ---
write(1, "Loading...\n", 11Loading...
)            = 11
clock_nanosleep(CLOCK_REALTIME, 0, {tv_sec=1, tv_nsec=0}, 0x7ffd4937c720) = 0
write(1, "Checking your flag...\n", 22Checking your flag...
) = 22
--- SIGFPE {si_signo=SIGFPE, si_code=FPE_INTDIV, si_addr=0x56539c8c137f} ---
+++ killed by SIGFPE (core dumped) +++
fish: Job 1, 'strace ./bug-me 'CTF{aaaaaaaaaa…' terminated by signal SIGFPE (Floating point exception)
```

Although there IS a hint in there: `clone` and `SIGCHLD` are unusual!

## Changing the code

In the debugger process, after attaching to the executable it opens a) its own executable file (`/proc/self/exe`) and b) its parent's memory (`/proc/<parent pid>/mem`):

```
    int code = OPEN(PROC_EXE, 0); // /proc/self/exe

    LSEEK(code, 0x13371337, SEEK_SET); // 0x13371337 will get replaced post-compile

    char filename[32];
    SPRINTF(filename, PROC_MEM, parent);

    int memory = OPEN(filename, O_RDWR|O_CLOEXEC); // /proc/<parent pid>/mem
```

The `lseek()` value (0x13371337) gets replaced post-compilation with the length of the executable - basically, it fast forwards to the end of the executable file on disk.

When an exception happens, the debugger "fixes" the exception by skipping over the code that caused it:

```
    for(;;) {
      // Wait for a signal
      int status;
      WAITPID(parent, &status, 0);

      // Make sure it's the right signal
      if(WIFSTOPPED(status)) {
        struct user_regs_struct regs;
        PTRACE(PTRACE_GETREGS, parent, NULL, &regs);

        // Bump RIP up depending on which exception we hit
        if(WSTOPSIG(status) == SIGFPE) {
          regs.rip += 2;
        } else if (WSTOPSIG(status) == SIGSEGV) {
          regs.rip += 6;
        }

        PTRACE(PTRACE_SETREGS, parent, NULL, &regs);
```

After compiling the binary, we append a bunch of encrypted code to it. After the exception is fixed, we read the encrypted code from the end of the binary, decrypt it, and *replace the entire check_flag() function*!!:

```
        // The next byte is the "key"
        uint8_t key;
        READ(code, &key, 1);

        // The next 4 bytes are the length of the new function
        uint8_t length;
        READ(code, &length, 1);

        // Read the function (up to 256 bytes)
        uint8_t func[256];
        READ(code, func, length);

        int i;
        for(i = 0; i < length; i++) {
          func[i] = func[i] ^ key ^ (i << 2) ^ checksum;
        }

        // Overwrite the code
        PWRITE(memory, func, length, (void*)check_flag);

        // Continue execution
        PTRACE(PTRACE_CONT, parent, -1, 0);
```

I'll talk more about the checksum byte in a second, but first, to summarize the debugger:

* Attaches to its parent to handle exceptions
* When an exception occurs, skip the "bad code"
* Read a chunk of encrypted code from the end of the binary
* Decrypt the chunk of code (it's just `xor` stuff)
* Overwrite the `check_flag` function with the new code

## Obfuscations

I didn't want to make it TOO easy, so I added a long trail of obfuscations to mess with players!

### Code sections and constructors

The debugger isn't attached in `_start` or `main()`; instead, it's attached in a special kind of function called a `constructor`, which runs when an ELF binary starts. You can see the code in IDA, and perhaps some tools will alert you that there are constructors, but they're not super obvious:

```
__attribute__((constructor)) __attribute__((section(".ctor"))) void __gmon_init__() {
  register uint8_t *my_dlsym = ((uint8_t*)dlsym) + 0x1000;

  char buf[32];
  if(!FORK()) {
[...]
```

What you'll also see there is I put the code in a section called `.ctor`. That doesn't really do anything, I'm not even sure if it's a standard name on ELF files. I simply used it to be more confusing - it's not in the `.code` section.

And finally, I named it `__gmon_init__()`, because I noticed several functions with names that start with `__gmon_` and wanted to blend in. :)

### Main checksum

During testing, I realized you could solve this by modifying the `main()` function to only check the first character, then the first two, then three, and so on. That wasn't good!

I decided to incorporate a checksum of `main()` into all the decryption code. Basically, I generated a one-byte key by adding together every byte in the `main()` function in memory:

```
    int memory = OPEN(filename, O_RDWR|O_CLOEXEC);
    uint8_t main_in_memory[1024];

    uint16_t main_length = ((uint8_t*) IGNOREMEPLZ) - ((uint8_t*)MAIN);
    PREAD(memory, main_in_memory, main_length, MAIN);
    uint8_t checksum = 0;
    int i;
    for(i = 0; i < main_length; i++) {
      checksum += main_in_memory[i];
    }
```

When we embed the code, we calculate the same value from the file on disk:

```
# We're going to incorporate a checksum of main() to prevent shenanigans                                                                        
disas_main = `gdb -q -batch -ex 'file ./bug-me' -ex 'disassemble main' -ex 'quit'`                                                              
             .split(/\n/)                                                                                                                       
             .select { |line| line =~ /0x000/ }                                                                                                 
             .map { |line| line =~ /(0x000[0-9a-fA-F]*)/; Regexp.last_match(0) }                                                                
                                                                                                                                                
main_start = disas_main[0].to_i(16)                                                                                                             
main_end = disas_main[-1].to_i(16)                                                                                                              
                                                                                                                                                
checksum = 0                                                                                                                                    
bugme.bytes[main_start..main_end].each do |b|                                                                                                   
  checksum = (checksum + b) % 256                                                                                                               
end
```

If you modify the binary in any way, that checksum will be incorrect and nothing will decrypt correctly (which causes some weird errors :) ).

That includes adding breakpoints, by the way, so even if you get a debugger attached it's yet another anti-debug technique!

### Obfuscated function names

To avoid having any recognizable strings or libc function calls in the debugger function - gotta fly under the radar! - we store all the functions we need as encrypted strings and decrypt them using these macros:

```c
#define ENC(s,l) (for(enc = 0; enc < l; enc++) { buf[enc] = s[enc] ^ 0xff; }  )
#define FNC(f) ((int (*)()) ((void* (*)())(my_dlsym - 0x1000))(NULL, f))
#define FNC2(f, l) ((int (*)()) ((void* (*)())(my_dlsym - 0x1000))(NULL, __gmon_map__(f, l, buf)))
```

And then stored as encrypted strings:

```
#define FORK FNC2("\x99\x92\x89\x92", 4)
#define GETPPID FNC2("\x98\x98\x8f\x89\x87\x9c\x97", 7)
#define PTRACE FNC2("\x8f\x89\x89\x98\x94\x90", 6)
#define EXIT FNC2("\x9a\x85\x92\x8d", 4)
#define WAITPID FNC2("\x88\x9c\x92\x8d\x87\x9c\x97", 7)
#define PTRACE FNC2("\x8f\x89\x89\x98\x94\x90", 6)
#define LSEEK FNC2("\x93\x8e\x9e\x9c\x9c", 5)
#define SPRINTF FNC2("\x8c\x8d\x89\x90\x99\x81\x95", 7)
#define OPEN FNC2("\x90\x8d\x9e\x97", 4)
#define WAITPID FNC2("\x88\x9c\x92\x8d\x87\x9c\x97", 7)
#define PTRACE FNC2("\x8f\x89\x89\x98\x94\x90", 6)
#define READ FNC2("\x8d\x98\x9a\x9d", 4)
#define PWRITE FNC2("\x8f\x8a\x89\x90\x83\x90", 6)
#define PREAD FNC2("\x8f\x8f\x9e\x98\x93", 5)
#define MAIN FNC2("\x92\x9c\x92\x97", 4)
#define IGNOREMEPLZ FNC2("\x96\x9a\x95\x96\x85\x90\x9e\x94\x9f\x81\x91", 11)

#define PROC_EXE __gmon_map__("\xd0\x8d\x89\x96\x94\xda\x80\x94\x83\x8b\xc4\x8c\x9f\x80", 14, buf)
#define PROC_MEM __gmon_map__("\xd0\x8d\x89\x96\x94\xda\xd6\x95\xc0\x80\x8e\x84", 12, buf)
```

I generated them using a quick Ruby script:

```
irb(main):025:1* ['fork', 'getppid', 'ptrace', 'exit', 'waitpid', 'ptrace', 'lseek', 'sprintf', 'open', 'waitpid', 'ptrace', 'read', 'pwrite', '/proc/self/exe', '/proc/%d/mem'].each do |str|
irb(main):026:1*   puts "#define #{ str.upcase } FNC2(\"#{str.bytes.each_with_index.map { |b, i| '\x%02x' % (b ^ 0xFF ^ (i << 1)) }.join }\", #{str.length})"
irb(main):027:0> end
```

To get the address, we use `dlsym` (which we do some math on to not be recognizable):

```
  register uint8_t *my_dlsym = ((uint8_t*)dlsym) + 0x1000;
```

With all that done, there's no way to see the function names that we're using, and also no way to reasonably debug it. It's a pain!

### Checking each character

We check the flag one character at a time using a pretty simple piece of C code:

```
FLAG = 'CTF{hope-you-enjoyed-this-one}'                                                                                                         
                                                                                                                                                
[...]

# Encode the flag onto the end of the binary                                                                                                    
FLAG.chars.each do |c|                                                                                                                          
  Tempfile.create(['matcher', '.c']) do |infile|                                                                                                
    a = c.ord % 5
    b = c.ord % 7
    c = c.ord % 11
    infile.puts('int match(char c) {')
    infile.puts("  return !((c % 5 == #{ a }) && (c % 7 == #{ b }) && (c % 11 == #{ c }));")
    infile.puts('}')
    infile.close
[...]
```

By modular dividing each character by 5, 7, and 11, you get a value that uniquely identifies a character (and also compiles to fairly short code).

## That's it!

I think that's it!

I hope y'all had fun with this super-obfuscated anti-debugger reversing challenge! It's both the hardest and my favourite reversing challenge I've ever written, and I hope folks appreciate it. :)
