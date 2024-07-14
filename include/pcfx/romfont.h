/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff <GitHub user: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*
 *  Access fonts from ROM.
 */

#ifndef _LIBPCFX_ROMFONT_H_
#define _LIBPCFX_ROMFONT_H_

#include <pcfx/types.h>

/*  Type of font to get data for.
 */
typedef enum {
	ROMFONT_KANJI_16x16 = 0, /* 16x16 kanji font */
	ROMFONT_KANJI_12x12 = 1, /* 12x12 kanji font */
	ROMFONT_ANK_8x16    = 2, /* 8x16 alpha/numeric/kana font */
	ROMFONT_ANK_6x12    = 3, /* 6x12 alpha/numeric/kana font */
	ROMFONT_ANK_8x8     = 4, /* 8x8 alpha/numeric/kana font */
	ROMFONT_ANK_8x12    = 5, /* 8x12 alpha/numeric/kana font */
} romfont_type;

/* Get font data.
 *
 * Gets font data for the specified symbol. The data is returned in a series
 * of bytes, and is stored in a simple 1bpp format.
 *
 * parameters: sjis = The ShiftJIS code to get the font data for. (ASCII works too)
 *             type = The type of font to get the data from.
 * return:     Font data.
 */
u8* romfont_get(u32 sjis, romfont_type type);

#endif

