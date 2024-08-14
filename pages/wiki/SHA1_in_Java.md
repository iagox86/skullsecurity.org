---
title: 'Wiki: SHA1 in Java'
author: ron
layout: wiki
permalink: "/wiki/SHA1_in_Java"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/SHA1_in_Java"
---

## WardenSHA1.java

    package warden;

    import java.io.*;

    import util.ByteFromIntArray;

    public class WardenSHA1
    {
        private int[] bitlen = new int[2];
        private int[] state = new int[0x15];

        public static int[] hash(byte []data)
        {
            return WardenSHA1.hash(byteArrayToCharArray(data));
        }
        
        public static int[] hash(char []data)
        {
            WardenSHA1 ctx = new WardenSHA1();
            ctx.update(data);
            return ctx.digest();
        }
        
        public static int[] hash(String data)
        {
            return WardenSHA1.hash(data.toCharArray());
        }
        
        public WardenSHA1()
        {
            bitlen[0] = 0;
            bitlen[1] = 0;
            state[0] = 0x67452301;
            state[1] = 0xEFCDAB89;
            state[2] = 0x98BADCFE;
            state[3] = 0x10325476;
            state[4] = 0xC3D2E1F0;
        }

        private static int reverseEndian(int i)
        {
            i =  (( i << 24) & 0xFF000000) | 
                  ((i <<  8) & 0x00FF0000) | 
                  ((i >>  8) & 0x0000FF00) |
                  ((i >> 24) & 0x000000FF);
            
            return i;
        }

        public int[] digest()
        {
            byte[] vars;
            int len;
            char[] MysteryBuffer;
            int[] temp_vars = new int[2];
            
            temp_vars[0] = WardenSHA1.reverseEndian(bitlen[1]);
            temp_vars[1] = WardenSHA1.reverseEndian(bitlen[0]);     
            
            len = ((-9 - (bitlen[0] >>> 3)) & 0x3F) + 1;
            
            vars = (new ByteFromIntArray(true)).getByteArray(temp_vars);
            MysteryBuffer = new char[len];
            
            MysteryBuffer[0] = (char) 0x80;
            for (int x = 1; x < len; x++)
                MysteryBuffer[x] = (char) 0;

            update(MysteryBuffer);
            update(byteArrayToCharArray(vars));

            int[] hash = new int[5];
            for (int x = 0; x < 5; x++)
                hash[x] = WardenSHA1.reverseEndian(state[x]);

            return hash;
        }
        
        public void update(byte[] data)
        {
            this.update(WardenSHA1.byteArrayToCharArray(data));
        }

        public void update(char[] data)
        {
            int a = 0, b = 0, c = 0, x = 0, len = data.length;
            c = len >> 29;
            b = len << 3;

            a = (bitlen[0] / 8) & 0x3F;

            if (bitlen[0] + b < bitlen[0] || bitlen[0] + b < b)
                bitlen[1]++;
            bitlen[0] += b;
            bitlen[1] += c;

            len += a;
            x = -a;
            ByteFromIntArray bfia = new ByteFromIntArray(true);

            if (len >= 0x40)
            {
                if (a > 0)
                {
                    while (a < 0x40)
                    {
                        bfia.insertByte(state, a + 0x14, (byte) data[a + x]);
                        a++;
                    }
                    transform(state);
                    len -= 0x40;
                    x += 0x40;
                    a = 0;
                }
                if (len >= 0x40)
                {
                    b = len;
                    for (int i = 0; i < b / 0x40; i++)
                    {
                        for (int y = 0; y < 0x40; y++)
                            bfia.insertByte(state, y + 0x14, (byte) data[x + y]);
                        transform(state);
                        len -= 0x40;
                        x += 0x40;
                    }
                }
            }
            while (a < len)
            {
                bfia.insertByte(state, 20 + a, (byte) data[a + x]);
                a++;
            }
            return;
        }

        private static void transform(int[] hashBuffer)
        {
            int buf[] = new int[0x50];
            int dw, a, b, c, d, e, p, i;
            
            for(i = 5; i < hashBuffer.length; i++)
                hashBuffer[i] = WardenSHA1.reverseEndian(hashBuffer[i]);
            
            for (i = 0; i < 0x10; i++)
                buf[i] = hashBuffer[i + 5];

            for (i = 0; i < 0x40; i++)
            {
                dw = buf[i + 13] ^ buf[i + 8] ^ buf[i + 0] ^ buf[i + 2];
                buf[i + 16] = (dw >>> 0x1f) | (dw << 1);
            }

            a = hashBuffer[0];
            b = hashBuffer[1];
            c = hashBuffer[2];
            d = hashBuffer[3];
            e = hashBuffer[4];

            p = 0;

            i = 0x14;
            do
            {
                dw = ((a << 5) | (a >>> 0x1b)) + ((~b & d) | (c & b)) + e + buf[p++] + 0x5a827999;
                e = d;
                d = c;
                c = (b >>> 2) | (b << 0x1e);
                b = a;
                a = dw;
            }
            while (--i > 0);

            i = 0x14;
            do
            {
                dw = (d ^ c ^ b) + e + ((a << 5) | (a >>> 0x1b)) + buf[p++] + 0x6ED9EBA1;
                e = d;
                d = c;
                c = (b >>> 2) | (b << 0x1e);
                b = a;
                a = dw;
            }
            while (--i > 0);

            i = 0x14;
            do
            {
                dw = ((c & b) | (d & c) | (d & b)) + e + ((a << 5) | (a >>> 0x1b)) + buf[p++] - 0x70E44324;
                e = d;
                d = c;
                c = (b >>> 2) | (b << 0x1e);
                b = a;
                a = dw;
            }
            while (--i > 0);

            i = 0x14;
            do
            {
                dw = ((a << 5) | (a >>> 0x1b)) + e + (d ^ c ^ b) + buf[p++] - 0x359D3E2A;
                e = d;
                d = c;
                c = (b >>> 2) | (b << 0x1e);
                b = a;
                a = dw;
            }
            while (--i > 0);

            hashBuffer[0] += a;
            hashBuffer[1] += b;
            hashBuffer[2] += c;
            hashBuffer[3] += d;
            hashBuffer[4] += e;
        }

        public void pad(int amount)
        {
            char[] emptybuffer = new char[0x1000];
            for (int x = 0; x < 0x1000; x++)
                emptybuffer[x] = (byte) 0;
            while (amount > 0x1000)
            {
                update(emptybuffer);
                amount -= 0x1000;
            }
            emptybuffer = new char[amount];
            for (int x = 0; x < amount; x++)
                emptybuffer[x] = (byte) 0;
            update(emptybuffer);
        }

        public boolean hash_file(String filename)
        {
            try
            {
                byte[] data = new byte[(int) (new File(filename)).length()];
                InputStream in = new FileInputStream(filename);
                in.read(data);
                in.close();
                update(byteArrayToCharArray(data));
            }
            catch (Exception e)
            {
                System.out.println("lockdown_SHA1.hash_file(" + filename + ") Failed: " + e.toString());
                return false;
            }
            return true;
        }

        private static char[] byteArrayToCharArray(byte[] a)
        {
            char[] buff = new char[a.length];
            for (int x = 0; x < a.length; x++)
                buff[x] = (char) (a[x] & 0x000000FF);
            return buff;
        }

        public static void main(String[] args)
        {
            String test1 = "";
            String test2 = "The quick brown fox jumps over the lazy dog";
            String test3 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            String test4 = "~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./";
            String test5 = "";
            int i;
            
            int[] result;
            
            for(i = 0; i < 0x100; i++)
                test5 = test5 + (char) i;

            result = WardenSHA1.hash(test1);
            System.out.format("%08x %08x %08x %08x %08x\n", result[0], result[1], result[2], result[3], result[4]);
            System.out.println("eea339da 0d4b6b5e efbf5532 90186095 0907d8af");
            System.out.println();
            
            result = WardenSHA1.hash(test2);
            System.out.format("%08x %08x %08x %08x %08x\n", result[0], result[1], result[2], result[3], result[4]);
            System.out.println("c6e1d42f fc282d7a e19e84ed 39e776bb 12eb931b");
            System.out.println();
            
            result = WardenSHA1.hash(test3);
            System.out.format("%08x %08x %08x %08x %08x\n", result[0], result[1], result[2], result[3], result[4]);
            System.out.println("4d64e33a f5a17767 eaef1d6a 9caf74bc 493e314b");
            System.out.println();
            
            result = WardenSHA1.hash(test4);
            System.out.format("%08x %08x %08x %08x %08x\n", result[0], result[1], result[2], result[3], result[4]);
            System.out.println("df847112 54412b8d 7cf95a20 c8e1622c 598e0878");
            System.out.println();
            
            result = WardenSHA1.hash(test5);
            System.out.format("%08x %08x %08x %08x %08x\n", result[0], result[1], result[2], result[3], result[4]);
            System.out.println("bdd61649 688ef7b7 ab8c6903 6e58d132 c8df57a4");
            System.out.println();
        }
    }

## util.ByteFromIntArray.java

    /*
     * ByteFromIntArray.java
     *
     * Created on May 21, 2004, 11:39 AM
     */

    package util;

    /** This is a class to take care of treating an array of ints like a an array of bytes.
     * Note that this always works in Little Endian
     */
    public class ByteFromIntArray
    {
        private boolean littleEndian;
        
        public static final ByteFromIntArray LITTLEENDIAN = new ByteFromIntArray(true);
        public static final ByteFromIntArray BIGENDIAN = new ByteFromIntArray(false);

        /**
         * @param args the command line arguments
         */
        /*public static void main(String[] args)
        {
            int []test = { 0x01234567, 0x89abcdef };
            
            ByteFromIntArray bfia = new ByteFromIntArray(false);
            
            byte []newArray = bfia.getByteArray(test);
            
            for(int i = 0; i < newArray.length; i++)
                System.out.print(" " + PadString.padHex(newArray[i], 2));
        }*/
        
        public ByteFromIntArray(boolean littleEndian)
        {
            this.littleEndian = littleEndian;
        }

        public byte getByte(int[] array, int location)
        {
            if((location / 4) >= array.length)
                throw new ArrayIndexOutOfBoundsException("location = " + location + ", number of bytes = " + (array.length * 4));
            
            int theInt = location / 4; // rounded
            int theByte = location % 4; // remainder
            
            
            // reverse the byte to simulate little endian
            if(littleEndian)
                theByte = 3 - theByte;
            
            // I was worried about sign-extension here, but then I realized that they are being
            // put into a byte anyway so it wouldn't matter.
            if(theByte == 0)
                return (byte)((array[theInt] & 0x000000FF) >> 0);
            else if(theByte == 1)
                return (byte)((array[theInt] & 0x0000FF00) >> 8);
            else if(theByte == 2)
                return (byte)((array[theInt] & 0x00FF0000) >> 16);
            else if(theByte == 3)
                return (byte)((array[theInt] & 0xFF000000) >> 24);
            
            return 0;
        }
        
        
        /** This function is used to insert the byte into a specified spot in
         * an int array.  This is used to simulate pointers used in C++.
         * Note that this works in little endian only.
         * @param intBuffer The buffer to insert the int into.
         * @param b The byte we're inserting.
         * @param location The location (which byte) we're inserting it into.
         * @return The new array - this is returned for convenience only.
         */
        public int[] insertByte(int[] intBuffer, int location, byte b)
        {
            // Get the location in the array and in the int
            int theInt = location / 4;
            int theByte = location % 4;

            // If we're using little endian reverse the hex position
            if(littleEndian == false)
                theByte = 3 - theByte;
            
            int replaceInt = intBuffer[theInt];
            
            // Creating a new variable here because b is a byte and I need an int
            int newByte = b << (8 * theByte);

            if(theByte == 0)
                replaceInt &= 0xFFFFFF00;
            else if(theByte == 1)
                replaceInt &= 0xFFFF00FF;
            else if(theByte == 2)
                replaceInt &= 0xFF00FFFF;
            else if(theByte == 3)
                replaceInt &= 0x00FFFFFF;
            
            replaceInt = replaceInt | newByte;
            
            intBuffer[theInt] = replaceInt;
            
            return intBuffer;
            
        }

        
        public byte[] getByteArray(int[] array)
        {
            byte[] newArray = new byte[array.length * 4];
            
            int pos = 0;
            for(int i = 0; i < array.length; i++)
            {
                if(littleEndian)
                {
                    newArray[pos++] = (byte)((array[i] >> 0) & 0xFF);
                    newArray[pos++] = (byte)((array[i] >> 8) & 0xFF);
                    newArray[pos++] = (byte)((array[i] >> 16) & 0xFF);
                    newArray[pos++] = (byte)((array[i] >> 24) & 0xFF);
                }
                else
                {
                    newArray[pos++] = (byte)((array[i] >> 24) & 0xFF);
                    newArray[pos++] = (byte)((array[i] >> 16) & 0xFF);
                    newArray[pos++] = (byte)((array[i] >> 8) & 0xFF);
                    newArray[pos++] = (byte)((array[i] >> 0) & 0xFF);
                }
            }
            
            return newArray;
        }
        
        public byte[] getByteArray(int integer)
        {
            int[] temp = new int[1];
            temp[0] = integer;
            return getByteArray(temp);
        }
    }
