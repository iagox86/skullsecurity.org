---
title: 'Wiki: Key Generation in Java'
author: ron
layout: wiki
permalink: "/wiki/Key_Generation_in_Java"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/Key_Generation_in_Java"
---

## WardenRandom.java

    package warden;

    import util.Buffer;
    import util.ByteFromIntArray;

    public class WardenRandom
    {
        int position = 0;
        byte []random_data;
        byte []randomSource1;
        byte []randomSource2;
        
        public WardenRandom(byte []seed)
        {
            int length1 = seed.length >>> 1;
            int length2 = seed.length - length1;
            
            byte []seed1 = new byte[length1];
            byte []seed2 = new byte[length2];
            
            int i;
            
            for(i = 0; i < length1; i++)
                seed1[i] = seed[i];
            
            for(i = 0; i < length2; i++)
                seed2[i] = seed[i + length1];

            random_data = new byte[0x14];
            
            randomSource1 = ByteFromIntArray.LITTLEENDIAN.getByteArray(WardenSHA1.hash(seed1));
            randomSource2 = ByteFromIntArray.LITTLEENDIAN.getByteArray(WardenSHA1.hash(seed2));

            this.update();

            position = 0;

        }

        private void update()
        {
            WardenSHA1 sha1 = new WardenSHA1();
            sha1.update(this.randomSource1);
            sha1.update(this.random_data);
            sha1.update(this.randomSource2);
            this.random_data = ByteFromIntArray.LITTLEENDIAN.getByteArray(sha1.digest());
        }


        byte getByte()
        {
            int i = this.position;
            byte value = this.random_data[i];

            i++;
            if(i >= 0x14)
            {
                i = 0;
                this.update();
            }
            this.position = i;

            return value;
        }

        byte []getBytes(int bytes)
        {
            int i;
            byte []buffer = new byte[bytes];

            for(i = 0; i < bytes; i++)
                buffer[i] = this.getByte();
            
            return buffer;
        }

        public static void main(String []args)
        {
            WardenRandom source = new WardenRandom(new byte[] { 0x11, 0x22, 0x33, 0x44, 0x55 });
            Buffer b = new Buffer(source.getBytes(0x100));
            System.out.println(b);
            System.out.println();
            
            System.out.println("Should be:");
            System.out.println("94 76 f0 7d b1 56 ea 1c fc c6 a6 92 a7 89 55 8e");
            System.out.println("2e 92 79 20 7d c8 56 b8 96 ed 7a f7 99 2d dc a2");
            System.out.println("1e 92 c2 c6 03 72 b1 a8 82 0a a5 c6 14 4d 71 8e");
            System.out.println("57 3b 72 0b 88 2e 49 e7 71 9d 74 c1 8d cf 8d ed");
            System.out.println("f7 15 e2 02 a1 2a 56 8a 5b a8 97 56 ee 4e 02 bf");
            System.out.println("53 41 81 c6 21 ea 50 5e 6e fa db 13 cb 94 5f a2");
            System.out.println("bf 8b 2e 52 8e 79 84 85 58 b0 a4 bc 85 ff e7 a6");
            System.out.println("db 04 9c a1 76 2b 92 10 21 5b 21 e1 11 d5 1c a3");
            System.out.println("c6 e4 77 d9 bc 76 93 6e 37 44 09 66 23 cc e8 47");
            System.out.println("75 f5 85 ca 68 3b 3a 50 08 f4 4b ef 89 a0 6a fe");
            System.out.println("da c5 0a 47 7a 45 56 61 c8 10 b0 4a a4 78 fc 3e");
            System.out.println("41 06 ad ea e3 f5 52 75 4b 6c ab 8f 30 93 97 49");
            System.out.println("c7 74 2f 94 8d 36 0c 7b 2a f2 66 24 a5 bf 8e 77");
            System.out.println("3c 05 bd e3 6d 8d ff b9 37 fe 00 ba f6 53 02 5d");
            System.out.println("d3 5d ae 6b 0a 70 b5 c1 88 12 42 1a 6d 33 0e 5f");
            System.out.println("82 33 26 32 54 a1 28 3f 2d ae ae 52 60 da 4e 65");
        }
    }

## util.ByteFromIntArray

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
