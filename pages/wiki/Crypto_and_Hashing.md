---
title: 'Wiki: Crypto and Hashing'
author: ron
layout: wiki
permalink: "/wiki/Crypto_and_Hashing"
date: '2024-08-04T15:51:38-04:00'
---

This page is about the various cryptographic and hashing functions used by Warden.

## SHA1

Warden uses a very similar version of SHA1 to Lockdown, with minor changes. The only changes, in fact, are the reversal of the endianness in a few places:

-   sha1_transform() \-- the 0x40 bytes of data to be hashed (not the \"state\", just the new data) have the endianness reversed in 0x10 4-byte blocks. So basically:
    -   112233445566778899aabbcc\.....
    -   becomes
    -   4433221188776655ccbbaa99\.....
-   sha1_final() \-- the endianness of the first 8 bytes are reversed (as a 64-bit integer). So:
    -   1122334455667788
    -   becomes
    -   8877665544332211

Those are the only changes.

I have no good code to demonstrate with, only some hacking code, but feel free to use my [C code](SHA1_in_C "wikilink") or [Java code](SHA1_in_Java "wikilink") if you have nothing better.

### SHA1 Test Strings {#sha1_test_strings}

     *     eea339da 0d4b6b5e efbf5532 90186095 0907d8af: ""
     *  c6e1d42f fc282d7a e19e84ed 39e776bb 12eb931b: "The quick brown fox jumps over the lazy dog":
     *  4d64e33a f5a17767 eaef1d6a 9caf74bc 493e314b: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA":
     *  df847112 54412b8d 7cf95a20 c8e1622c 598e0878: "~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./"
     *  bdd61649 688ef7b7 ab8c6903 6e58d132 c8df57a4: "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff":

## MD5

You can optionally use MD5 for one step in the Warden verification. It is 100% standard MD5.

## RSA

You can optionally use RSA for one step in the Warden validation. In particular, it is the algorithm:

m = c^d^ mod n

Again, this is completely standard.

Where c is the encrypted buffer, d is the key, and n is a known modulus value.

## Xor Encryption {#xor_encryption}

Warden uses a very simple symmetric encryption algorithm in at least two places. Although I haven\'t confirmed it myself, I\'m told that the algorithm is RC4. The algorithm has two parts:

1.  Take an arbitrary-length buffer and generate a 0x100-byte key
2.  Encrypt or decrypt data using that 0x100-byte key

### Implementation in C {#implementation_in_c}

    #define SWAP(a,b) (((a) == (b)) ? ((a)=(a)) : ((char)(a) ^= (char)(b) ^= (char)(a) ^= (char)(b)))

    /** Generates the key based on "base" */
    void generate_key(unsigned char *key_buffer, unsigned char *base, unsigned int base_length)
    {
        unsigned char val = 0;
        unsigned int i;
        unsigned int position = 0;

        for(i = 0; i < 0x100; i++)
            key_buffer[i] = i;

        key_buffer[0x100] = 0;
        key_buffer[0x101] = 0;

        for(i = 1; i <= 0x40; i++)
        {
            val += key_buffer[(i * 4) - 4] + base[position++ % base_length];
            SWAP(key_buffer[(i * 4) - 4], key_buffer[val & 0x0FF]);

            val += key_buffer[(i * 4) - 3] + base[position++ % base_length];
            SWAP(key_buffer[(i * 4) - 3], key_buffer[val & 0x0FF]);

            val += key_buffer[(i * 4) - 2] + base[position++ % base_length];
            SWAP(key_buffer[(i * 4) - 2], key_buffer[val & 0x0FF]);

            val += key_buffer[(i * 4) - 1] + base[position++ % base_length];
            SWAP(key_buffer[(i * 4) - 1], key_buffer[val & 0x0FF]);
        }
    }

    void do_crypt(unsigned char *key, unsigned char *data, int length)
    {
        int i;

        for(i = 0; i < length; i++)
        {
            key[0x100]++;
            key[0x101] += key[key[0x100]];
            SWAP(key[key[0x101]], key[key[0x100]]);

            data[i] = data[i] ^ key[(key[key[0x101]] + key[key[0x100]]) & 0x0FF];
        }
    }

### Implementation in Java {#implementation_in_java}

(the requirement for util.Buffer is only for the main() function, you don\'t need it.)

    package warden;

    import util.Buffer;

    /** Implements a very simple crypto system used by Warden. I'm told it's RC4, but I haven't bothered confirming. */

    public class SimpleCrypto
    {
        private byte[] key;

        /** Generates the key based on "base" */
        public SimpleCrypto(byte[] base)
        {
            char val = 0;
            int i;
            int position = 0;
            byte temp;

            key = new byte[0x102];

            for (i = 0; i < 0x100; i++)
                key[i] = (byte) i;

            key[0x100] = 0;
            key[0x101] = 0;

            for (i = 1; i <= 0x40; i++)
            {
                val += key[(i * 4) - 4] + base[position++ % base.length];
                temp = key[(i * 4) - 4];
                key[(i * 4) - 4] = key[val & 0x0FF];
                key[val & 0x0FF] = temp;

                val += key[(i * 4) - 3] + base[position++ % base.length];
                temp = key[(i * 4) - 3];
                key[(i * 4) - 3] = key[val & 0x0FF];
                key[val & 0x0FF] = temp;

                val += key[(i * 4) - 2] + base[position++ % base.length];
                temp = key[(i * 4) - 2];
                key[(i * 4) - 2] = key[val & 0x0FF];
                key[val & 0x0FF] = temp;

                val += key[(i * 4) - 1] + base[position++ % base.length];
                temp = key[(i * 4) - 1];
                key[(i * 4) - 1] = key[val & 0x0FF];
                key[val & 0x0FF] = temp;
            }
        }

        /** Encrypts or decrypts. */
        public byte[] do_crypt(byte[] data)
        {
            int i;
            byte temp;

            for (i = 0; i < data.length; i++)
            {
                key[0x100]++;
                key[0x101] += key[key[0x100] & 0x0FF];
                temp = key[key[0x101] & 0x0FF];
                key[key[0x101] & 0x0FF] = key[key[0x100] & 0x0FF];
                key[key[0x100] & 0x0FF] = temp;

                data[i] = (byte) (data[i] ^ key[(key[key[0x101] & 0x0FF] + key[key[0x100] & 0x0FF]) & 0x0FF]);
            }
            
            return data;
        }

        /** More for debugging than anything. */
        public byte[] getKey()
        {
            return key;
        }
        
        public static void main(String[] args)
        {
            SimpleCrypto c = new SimpleCrypto("This is my key. Don't hurt it!!".getBytes());
            String str = "This is not a test Of the emergency broadcast system Where malibu fires and radio towers Conspire to dance again And I cannot believe the media Mecca They're only trying to peddle reality, Catch it on prime time, story at nine The whole world is going insane";
            byte []out = c.do_crypt(str.getBytes());
            
            Buffer b = new Buffer(out);
            System.out.println(b);

            System.out.println("Proper output:");
            System.out.println("04 11 56 52 3b d5 86 ee 86 55 a7 f7 b5 a7 ae 18");
            System.out.println("e3 0a 97 7e 16 cf c8 cf 62 d7 3a 5c 26 ff 16 4b");
            System.out.println("f1 c9 a6 ef 1a f8 bd 89 9b 67 3e bb 34 31 35 1e");
            System.out.println("79 91 3b d2 f1 c1 b4 65 c3 6d 08 56 73 6c 53 c1");
            System.out.println("6d e9 76 06 4f b9 ba 5b 89 17 69 02 36 9a 14 48");
            System.out.println("04 e8 d6 a8 36 c3 a5 31 8c 2c d1 bf b7 75 e1 a2");
            System.out.println("89 61 ac 66 a0 44 09 bc e5 b1 59 71 cd 6f e3 ce");
            System.out.println("32 2c ca 95 7d 41 a3 17 08 e8 f6 bf 27 46 6a 9c");
            System.out.println("f3 89 f5 0d 32 9e 88 88 3d f8 bd 39 23 85 2c 4b");
            System.out.println("58 58 f8 2b e2 fd ee 4d 34 7f 4f 73 6d 9b d2 8f");
            System.out.println("37 58 23 1f ad 67 7b 07 9e c4 54 66 25 0c f2 7f");
            System.out.println("24 f0 4f 46 34 5d 1b b7 45 7b b8 30 fa 2d c0 2a");
            System.out.println("5f c0 4b 3d ce 4d 39 21 87 28 5a e4 31 2e 51 c4");
            System.out.println("65 dc 60 f8 43 0c 12 8d f7 56 2b 32 82 2a e5 97");
            System.out.println("24 62 f0 5e 7e 78 36 6e 6f ab b3 ca 76 b8 33 39");
            System.out.println("77 96 61 4a 5d 2a ed e8 54 ea fb 61 10 02 98 ce");
            System.out.println("c6 7b");
        }
    }

## Implementation in C# {#implementation_in_c_1}

    public class SimpleCrypto
    {
        private byte[] key;

        public byte[] Key
        {
            get
            {
                return this.key;
            }
        }

        /// <summary>
        /// Generates the key based on the baseData
        /// </summary>
        /// <param name="baseData"></param>
        public SimpleCrypto(byte[] baseData)
        {
            char val = (char)0;
            int i;
            int position = 0;
            byte temp;

            this.key = new byte[0x102];

            for (i = 0; i < 0x100; i++)
                key[i] = (byte)i;

            this.key[0x100] = 0;
            this.key[0x101] = 0;

            for (i = 1; i <= 0x40; i++)
            {
                val += (char)(this.key[(i * 4) - 4] + baseData[position++ % baseData.Length]);
                temp = this.key[(i * 4) - 4];
                this.key[(i * 4) - 4] = this.key[val & 0x0FF];
                this.key[val & 0x0FF] = temp;

                val += (char)(this.key[(i * 4) - 3] + baseData[position++ % baseData.Length]);
                temp = this.key[(i * 4) - 3];
                this.key[(i * 4) - 3] = this.key[val & 0x0FF];
                this.key[val & 0x0FF] = temp;

                val += (char)(this.key[(i * 4) - 2] + baseData[position++ % baseData.Length]);
                temp = this.key[(i * 4) - 2];
                this.key[(i * 4) - 2] = this.key[val & 0x0FF];
                this.key[val & 0x0FF] = temp;

                val += (char)(key[(i * 4) - 1] + baseData[position++ % baseData.Length]);
                temp = key[(i * 4) - 1];
                this.key[(i * 4) - 1] = this.key[val & 0x0FF];
                this.key[val & 0x0FF] = temp;
            }
        }

        /// <summary>
        /// Encrypts and decrypts data
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public byte[] Crypt(byte[] data)
        {
            int i;
            byte temp;

            for (i = 0; i < data.Length; i++)
            {
                key[0x100]++;
                key[0x101] += key[key[0x100] & 0x0FF];
                temp = key[key[0x101] & 0x0FF];
                key[key[0x101] & 0x0FF] = key[key[0x100] & 0x0FF];
                key[key[0x100] & 0x0FF] = temp;

                data[i] = (byte)(data[i] ^ key[(key[key[0x101] & 0x0FF] + key[key[0x100] & 0x0FF]) & 0x0FF]);
            }

            return data;
        }
    }

## Inflate

The standard \"inflate\" function from zlib is required. zlib 1.1.4 was used for create Warden, but it implements a standard protocol.

In C, I suggest using the [zlib library](http://www.zlib.net).

In Java, I suggest using [java.util.zip.Inflater](http://java.sun.com/j2se/1.3/docs/api/java/util/zip/Inflater.html).
