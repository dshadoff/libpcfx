/*
	libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011		Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024		David Shadoff  GitHub userid: dshadoff

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

#include <string.h>

#include <pcfx/types.h>
#include <pcfx/v810.h>
#include <pcfx/romfont.h>
#include <pcfx/king.h>
#include <pcfx/tetsu.h>
#include <pcfx/vdc.h>

void printch(u32 sjis, u32 kram, int tall);
void printstr(const char* str, int x, int y, int tall);

// This data is the character encoding of a miniature "happy face"
// 
const uint16_t char_gfx[] = {
  0x007E,0x0080,0x2882,0x0082,0x3882,0x00C6,0x007C,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
};

int main(int argc, char *argv[])
{
	int i;
	u16 microprog[16];

	vdc_init_5MHz(VDC0);
	vdc_init_5MHz(VDC1);

	king_init();
	tetsu_init();
	
	tetsu_set_priorities(0, 0, 1, 0, 0, 0, 0);
	tetsu_set_vdc_palette(0, 0);
	tetsu_set_king_palette(0, 0, 0, 0);
	tetsu_set_rainbow_palette(0);

	king_set_bg_prio(KING_BGPRIO_3, KING_BGPRIO_HIDE, KING_BGPRIO_HIDE, KING_BGPRIO_HIDE, 0);
	king_set_bg_mode(KING_BGMODE_4_PAL, 0, 0, 0);
	king_set_kram_pages(0, 0, 0, 0);

	for(i = 0; i < 16; i++) {
		microprog[i] = KING_CODE_NOP;
	}

	microprog[0] = KING_CODE_BG0_CG_0;
	king_disable_microprogram();
	king_write_microprogram(microprog, 0, 16);
	king_enable_microprogram();

	tetsu_set_palette(0, 0x0088);
	tetsu_set_palette(1, 0xE088);
	tetsu_set_palette(2, 0xE0F0);
	tetsu_set_palette(3, 0x602C);
	tetsu_set_palette(4, 0x5080);
	tetsu_set_palette(5, 0xC422);
	tetsu_set_palette(6, 0x9999);
	tetsu_set_palette(7, 0x1234);
	tetsu_set_video_mode(TETSU_LINES_262, 0, TETSU_DOTCLOCK_5MHz, TETSU_COLORS_16,
				TETSU_COLORS_16, 1, 0, 1, 0, 0, 0, 0);
	king_set_bat_cg_addr(KING_BG0, 0, 0);
	king_set_bat_cg_addr(KING_BG0SUB, 0, 0);
	king_set_scroll(KING_BG0, 0, 0);
	king_set_bg_size(KING_BG0, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256);

	vdc_setreg(VDC0, VDC_REG_CR, VDC_CR_BB);
	vdc_setreg(VDC0, VDC_REG_MWR, VDC_MWR_SCREEN_32x32);
	vdc_set_scroll(VDC0, 0, 0);

	king_set_kram_read(0, 1);
	king_set_kram_write(0, 1);

	// Clear BG0's RAM
	for(i = 0; i < 0x1E00; i++) {
		king_kram_write(0);
	}

	// set up the BAT (background attribute table
	//
	vdc_set_vram_write(VDC0, 0);
	for(i = 0; i < (32 * 5); i++) {           /* First 5 lines need to be blank, to avoid covering the title */
		vdc_vram_write(VDC0, 0x80); /* All tiles are at tile 0x80 (blank) */
	}
	for(i = (32 * 5); i < 0x800; i++) {       /* Everything after first 5 lines */
		vdc_vram_write(VDC0, 0x81); /* All tiles are at tile 0x81 */
	}

	// set up the character tile definitiions for the two tiles
	// referenced by the BAT above (one blank, one with a pattern)
	//
	for(i = 0; i < 16; i++) {
		vdc_vram_write(VDC0, 0x00); /* Blank tile */
	}
	for(i = 0; i < 16; i++) {
		vdc_vram_write(VDC0, char_gfx[i]); /* happyface type logo defined above */
	}

	king_set_kram_write(0, 1);
	printstr("VDC BG example", 9, 0x10, 1);

	return 0;
}

void printstr(const char* str, int x, int y, int tall)
{
	int i;
	u32 tempchr;

	u32 kram = x + (y << 5);
	int len = strlen(str);
	for(i = 0; i < len; i++) {
		tempchr = str[i];
		printch(tempchr, kram + i, tall);
	}
}

void printch(u32 sjis, u32 kram, int tall)
{
	u16 px;
	int x, y;
	u8* glyph = romfont_get(sjis, tall ? ROMFONT_ANK_8x16 : ROMFONT_ANK_8x8);
	for(y = 0; y < (tall ? 16 : 8); y++) {
		king_set_kram_write(kram + (y << 5), 1);
		px = 0;
		for(x = 0; x < 8; x++) {
			if((glyph[y] >> x) & 1) {
				px |= 1 << (x << 1);
			}
		}
		king_kram_write(px);
	}
}

