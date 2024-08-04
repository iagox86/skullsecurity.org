---
title: 'Wiki: SHA1 in C'
author: ron
layout: wiki
permalink: "/wiki/SHA1_in_C"
date: '2024-08-04T15:51:38-04:00'
---

## SHA1_Warden.h

    #ifndef __WARDEN_SHA1_H__
    #define __WARDEN_SHA1_H__

    /* Warden_SHA1.h
     * By Ron <ronwarden@javaop.com>
     * February 17, 2008
     *
     * Performs Warden's non-standard SHA1 operations. 
     * It's very similar to Lockdown's SHA1, except that some byte-reversing stuff was added.
     * 
     * Some test values:
     *  eea339da 0d4b6b5e efbf5532 90186095 0907d8af: ""
     *  c6e1d42f fc282d7a e19e84ed 39e776bb 12eb931b: "The quick brown fox jumps over the lazy dog":
     *  4d64e33a f5a17767 eaef1d6a 9caf74bc 493e314b: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA":
     *  df847112 54412b8d 7cf95a20 c8e1622c 598e0878: "~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./"
     *  bdd61649 688ef7b7 ab8c6903 6e58d132 c8df57a4: "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff":
     * 
     * (Watch out for the \x00 on the last one, strlen() doesn't work on it, I got confused by that)
     */

    typedef struct
    {
        int bitlen[2];
        int state[32];
    } SHA1_CTX;



    void warden_sha1_tweedle(int *ptr_rotator, int bitwise, int bitwise2, int bitwise3, int *ptr_adder, int *ptr_ret);
    void warden_sha1_twitter(int *ptr_rotator, int bitwise, int rotator2, int bitwise2, int *ptr_rotator3, int *ptr_ret);

    void warden_sha1_hash(int buffer[5], unsigned char *data, int length);

    void warden_sha1_init(SHA1_CTX *ctx);
    void warden_sha1_update(SHA1_CTX *ctx, char *data, int len);
    void warden_sha1_final(SHA1_CTX *ctx, int *hash);

    void warden_sha1_transform(int *data, int *state);

    #endif

## SHA1_Warden.c

    #include <stdio.h>
    #include <windows.h>

    #include "Assembly.h"
    #include "util.h"

    #include "Warden_SHA1.h"

    void reverse_endian(int *val, int *buffer)
    {
        *buffer = ((*val & 0x000000FF) << 24) | ((*val & 0x0000FF00) << 8) | ((*val & 0x00FF0000) >> 8) | ((*val & 0xFF000000) >> 24);
    }

    void warden_sha1_tweedle(int *ptr_rotator, int bitwise, int bitwise2, int bitwise3, int *ptr_adder, int *ptr_ret)
    {
        *ptr_ret = *ptr_ret + (((RotateLeft32(bitwise3, 5)) + ( (~(*ptr_rotator) & bitwise2) | (*ptr_rotator & bitwise))) + *ptr_adder + 0x5A827999);
        *ptr_adder = 0;
        *ptr_rotator = RotateLeft32(*ptr_rotator, 0x1e);
    }

    void warden_sha1_twitter(int *ptr_rotator, int bitwise, int rotator2, int bitwise2, int *ptr_rotator3, int *ptr_ret)
    {
        *ptr_ret = *ptr_ret + ((((bitwise2 | bitwise) & *(ptr_rotator)) | (bitwise2 & bitwise)) + ((RotateLeft32(rotator2, 5)) + *ptr_rotator3) - 0x70e44324);
        *ptr_rotator3 = 0;
        *ptr_rotator = RotateLeft32(*ptr_rotator, 0x1e);
    }

    void warden_sha1_hash(int buffer[5], unsigned char *data, int length)
    {
        SHA1_CTX ctx;

        warden_sha1_init(&ctx);
        warden_sha1_update(&ctx, data, length);
        warden_sha1_final(&ctx, buffer);
    }

    void warden_sha1_init(SHA1_CTX *ctx)
    {
        ctx->bitlen[0] = 0;
        ctx->bitlen[1] = 0;
        ctx->state[0]  = 0x67452301;
        ctx->state[1]  = 0xEFCDAB89;
        ctx->state[2]  = 0x98BADCFE;
        ctx->state[3]  = 0x10325476;
        ctx->state[4]  = 0xC3D2E1F0;
    }

    void warden_sha1_update(SHA1_CTX *ctx, char *data, int len)
    {
        int *bitlen = ctx->bitlen;
        char *state = (char *) ctx->state;
        int a;
        int b;
        int c;
        int i;

        /** This is a hack because this function doesn't work with 64-byte strings or longer. 
         * So just split up those strings. */
        if(len >= 0x40) /* CHANGED */
        { /* CHANGED */
            for(i = 0; i < len; i += 0x3F) /* CHANGED */
            { /* CHANGED */
                warden_sha1_update(ctx, data + i, min(0x3F, len - i)); /* CHANGED */
            } /* CHANGED */
        } /* CHANGED */
        else /* CHANGED */
        { /* CHANGED */
            /* The next two lines multiply len by 8. */
            c = len >> 29;
            b = len << 3;

            a = (bitlen[0] / 8) & 0x3F;

            /* Check for overflow. */
            if(bitlen[0] + b < bitlen[0] || bitlen[0] + b < b)
                bitlen[1]++;
            bitlen[0] = bitlen[0] + b;
            bitlen[1] = bitlen[1] + c;

            len = len + a;
            data = data - a;

            if(len >= 0x40)
            {
                if(a)
                {
                    while(a < 0x40)
                    {
                        state[0x14 + a] = data[a];
                        a++;
                    }

                    warden_sha1_transform((int *) (state + 0x14), (int *) state);
                    len -= 0x40;
                    data += 0x40;
                    a = 0;
                }

                if(len >= 0x40)
                {
                    b = len;
                    for(i = 0; i < b / 0x40; i++)
                    {
                        warden_sha1_transform((int *) data, (int *) state);
                        len -= 0x40;
                        data += 0x40;
                    }
                }
            }
            
            for(; a < len; a++)
                state[a + 0x1c - 8] = data[a];
        } /* CHANGED */
    }

    void warden_sha1_final(SHA1_CTX *ctx, int *hash)
    {
        int i;
        int vars[2]; /* CHANGED */
        char *MysteryBuffer = "\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
        int len; /* CHANGED */

        reverse_endian(&ctx->bitlen[1], &vars[0]); /* CHANGED */
        reverse_endian(&ctx->bitlen[0], &vars[1]); /* CHANGED */

        len = ((-9 - (ctx->bitlen[0] >> 3)) & 0x3F) + 1; /* CHANGED */
        warden_sha1_update(ctx, MysteryBuffer, len);
        warden_sha1_update(ctx, (char *)vars, 8);
        

        for(i = 0; i < 5; i++)
            reverse_endian(&ctx->state[i], &hash[i]); /* CHANGED */
    }

    void warden_sha1_transform(int *data, int *state)
    {
        int a, b, c, d, e, f, g, h, m, n;
        int i;

        int buf[80];

        for(i = 0; i < 0x10; i++) /** CHANGED */
            reverse_endian(&data[i], &data[i]); /* CHANGED */

        memcpy(buf, data, 0x40);

        for(i = 0; i < 0x40; i++)
            buf[i + 16] = RotateLeft32(buf[i + 13] ^ buf[i + 8] ^ buf[i + 0] ^ buf[i + 2], 1);

        m = state[0];
        b = state[1];
        c = state[2];
        n = state[3];
        e = state[4];

        for(i = 0; i < 20; i += 5)
        {
            warden_sha1_tweedle(&b, c, n, m, &buf[0 + i], &e);
            warden_sha1_tweedle(&m, b, c, e, &buf[1 + i], &n);
            warden_sha1_tweedle(&e, m, b, n, &buf[2 + i], &c);
            warden_sha1_tweedle(&n, e, m, c, &buf[3 + i], &b);
            warden_sha1_tweedle(&c, n, e, b, &buf[4 + i], &m);
        }

        f = m;
        d = n;

        for(i = 0x14; i < 0x28; i += 5)
        {
            g =  buf[i] + RotateLeft32(f, 5) + (d ^ c ^ b);
            d = d + RotateLeft32(g + e + 0x6ed9eba1, 5) + (c ^ RotateLeft32(b, 0x1e) ^ f) + buf[i + 1] + 0x6ed9eba1;
            c = c + RotateLeft32(d, 5) + ((g + e + 0x6ed9eba1) ^ RotateLeft32(b, 0x1e) ^ RotateLeft32(f, 0x1e)) + buf[i + 2] + 0x6ed9eba1;
            e = RotateLeft32(g + e + 0x6ed9eba1, 0x1e);
            b = RotateLeft32(b, 0x1e) + RotateLeft32(c, 5) + (e ^ d ^ RotateLeft32(f, 0x1e)) + buf[i + 3] + 0x6ed9eba1;
            d = RotateLeft32(d, 0x1e);
            f = RotateLeft32(f, 0x1e) + RotateLeft32(b, 5) + (e ^ d ^ c) + buf[i + 4] + 0x6ed9eba1;
            c = RotateLeft32(c, 0x1e);

            memset(buf, 0, 20);

        } while(i < 0x28);

        m = f;
        n = d;
        
        for(i = 0x28; i < 0x3c; i += 5)
        {
            warden_sha1_twitter(&b, n, m, c, &buf[i + 0], &e);
            warden_sha1_twitter(&m, c, e, b, &buf[i + 1], &n);
            warden_sha1_twitter(&e, b, n, m, &buf[i + 2], &c);
            warden_sha1_twitter(&n, m, c, e, &buf[i + 3], &b);
            warden_sha1_twitter(&c, e, b, n, &buf[i + 4], &m);
        } 

        f = m;
        a = m;
        d = n;

        for(i = 0x3c; i < 0x50; i += 5)
        {
            g = RotateLeft32(a, 5) + (d ^ c ^ b) + buf[i + 0] + e - 0x359d3e2a;
            b = RotateLeft32(b, 0x1e);
            e = g;
            d = (c ^ b ^ a) + buf[i + 1] + d + RotateLeft32(g, 5) - 0x359d3e2a;
            a = RotateLeft32(a, 0x1e);
            g = RotateLeft32(d, 5);
            g = (e ^ b ^ a) + buf[i + 2] + c + g - 0x359d3e2a;
            e = RotateLeft32(e, 0x1e);
            c = g;
            g = RotateLeft32(g, 5) + (e ^ d ^ a) + buf[i + 3] + b - 0x359d3e2a;
            d = RotateLeft32(d, 0x1e);
            h = (e ^ d ^ c) + buf[i + 4];
            b = g;
            g = RotateLeft32(g, 5);
            c = RotateLeft32(c, 0x1e);
            a = (h + a) + g - 0x359d3e2a;

            buf[i + 0] = 0;
            buf[i + 1] = 0;
            buf[i + 2] = 0;
            buf[i + 3] = 0;
            buf[i + 4] = 0;
        } while(i < 0x50);

        state[0] = state[0] + a;
        state[1] = state[1] + b;
        state[2] = state[2] + c;
        state[3] = state[3] + d;
        state[4] = state[4] + e;
    }

    #if 0

    #include "Warden_binary.h"

    int main(int argc, char *argv[])
    {
        int buffer1[5];
        int buffer2[5];

        char test1[] = "";
        char test2[] = "The quick brown fox jumps over the lazy dog";
        char test3[] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        char test4[] = "~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./";
        char test5[] = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff";

        int len1 = strlen(test1);
        int len2 = strlen(test2);
        int len3 = strlen(test3);
        int len4 = strlen(test4);
        int len5 = strlen(test5 + 1) + 1;

        load_maive("C:\\temp\\Maive.bin");

        warden_sha1_hash(buffer1, test1, len1);
        SHA1_hash_real(buffer2, test1, len1);
        printf("%08x %08x %08x %08x %08x\n", buffer1[0], buffer1[1], buffer1[2], buffer1[3], buffer1[4], buffer1[5]);
        printf("%08x %08x %08x %08x %08x\n", buffer2[0], buffer2[1], buffer2[2], buffer2[3], buffer2[4], buffer2[5]);
        printf("\n");

    //  warden_sha1_hash(buffer1, test2, len2);
    //  SHA1_hash_real(buffer2, test2, len2);
    //  printf("%08x %08x %08x %08x %08x\n", buffer1[0], buffer1[1], buffer1[2], buffer1[3], buffer1[4], buffer1[5]);
    //  printf("%08x %08x %08x %08x %08x\n", buffer2[0], buffer2[1], buffer2[2], buffer2[3], buffer2[4], buffer2[5]);
    //  printf("\n");
    //
    //  warden_sha1_hash(buffer1, test3, len3);
    //  SHA1_hash_real(buffer2, test3, len3);
    //  printf("%08x %08x %08x %08x %08x\n", buffer1[0], buffer1[1], buffer1[2], buffer1[3], buffer1[4], buffer1[5]);
    //  printf("%08x %08x %08x %08x %08x\n", buffer2[0], buffer2[1], buffer2[2], buffer2[3], buffer2[4], buffer2[5]);
    //  printf("\n");
    //
    //  warden_sha1_hash(buffer1, test4, len4);
    //  SHA1_hash_real(buffer2, test4, len4);
    //  printf("%08x %08x %08x %08x %08x\n", buffer1[0], buffer1[1], buffer1[2], buffer1[3], buffer1[4], buffer1[5]);
    //  printf("%08x %08x %08x %08x %08x\n", buffer2[0], buffer2[1], buffer2[2], buffer2[3], buffer2[4], buffer2[5]);
    //  printf("\n");
    //
    //  warden_sha1_hash(buffer1, test5, len5);
    //  SHA1_hash_real(buffer2, test5, len5);
    //  printf("%08x %08x %08x %08x %08x\n", buffer1[0], buffer1[1], buffer1[2], buffer1[3], buffer1[4], buffer1[5]);
    //  printf("%08x %08x %08x %08x %08x\n", buffer2[0], buffer2[1], buffer2[2], buffer2[3], buffer2[4], buffer2[5]);
    //  printf("\n");

        return 0;
    }
    #endif
