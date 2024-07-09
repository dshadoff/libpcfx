/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub user: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*
 * Implementation of standard functions, with modifications for speed.
 */

#ifndef _LIBPCFX_STD_H_
#define _LIBPCFX_STD_H_

#include <pcfx/types.h>

void memset32(void* addr, u32 val, int size);
void memset16(void* addr, u16 val, int size);
void memset8(void* addr, u8 val, int size);
void memcpy32(void* dst, const void* src, int size);
void memcpy16(void* dst, const void* src, int size);
void memcpy8(void* dst, const void* src, int size);
int memcmp32(const void* mem1, const void* mem2, int size);
int memcmp16(const void* mem1, const void* mem2, int size);
int memcmp8(const void* mem1, const void* mem2, int size);

int strlen32(const u32* str);
int strlen16(const u16* str);
int strlen8(const char* str);
void strcpy32(u32* dst, const u32* src);
void strcpy16(u16* dst, const u16* src);
void strcpy8(char* dst, const char* src);
int strcmp32(const u32* str1, const u32* str2);
int strcmp16(const u16* str1, const u16* str2);
int strcmp8(const char* str1, const char* str2);
int strnlen32(const u32* str, int len);
int strnlen16(const u16* str, int len);
int strnlen8(const char* str, int len);
void strncpy32(u32* dst, const u32* src, int len);
void strncpy16(u16* dst, const u16* src, int len);
void strncpy8(char* dst, const char* src, int len);
int strncmp32(const u32* str1, const u32* str2, int len);
int strncmp16(const u16* str1, const u16* str2, int len);
int strncmp8(const char* str1, const char* str2, int len);


#endif

