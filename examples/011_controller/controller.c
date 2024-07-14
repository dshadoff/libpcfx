/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              David Shadoff  GitHub userid: dshadoff


# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

#include <stdio.h>
#include <string.h>

#include <pcfx/types.h>
#include <pcfx/v810.h>
#include <pcfx/romfont.h>
#include <pcfx/contrlr.h>

#include <eris/king.h>
#include <eris/tetsu.h>

void printch(u32 sjis, u32 kram, int tall);
void printstr(const char* str, int x, int y, int tall);

static int padmap[16][2] = {
	{ 7-3, 0x40 },
	{ 7+7-3, 0x40 },
	{ 7+7+7-3, 0x40 },
	{ 7-3, 0x50 },
	{ 7+7-3, 0x50 },
	{ 7+7+7-3, 0x50 },
	{ 7+7-3, 0x60 },
	{ 7-3, 0x60 },
	{ 7-3, 0x30 },
	{ 7+7+7+7-3, 0x30 },
	{ 7+7-3, 0x30 },
	{ 7+7+7-3, 0x30 },
	{ 7+7+7-3, 0x60 },
	{ 0, 0 },
	{ 7+7+7+7-3, 0x60 },
	{ 1, 0 },
};

int main(int argc, char *argv[])
{
	u32 paddata, padtype;
	u32 old_padtype = 64;
	u32 mouse_x = 0;
	u32 mouse_y = 0;
	char xstr[8];
	char ystr[8];

	int i;
	u16 microprog[16];

	eris_king_init();
	eris_tetsu_init();
	
	eris_tetsu_set_priorities(0, 0, 1, 0, 0, 0, 0);
	eris_tetsu_set_7up_palette(0, 0);
	eris_tetsu_set_king_palette(0, 0, 0, 0);
	eris_tetsu_set_rainbow_palette(0);

	eris_king_set_bg_prio(KING_BGPRIO_3, KING_BGPRIO_HIDE, KING_BGPRIO_HIDE, KING_BGPRIO_HIDE, 0);
	eris_king_set_bg_mode(KING_BGMODE_4_PAL, 0, 0, 0);
	eris_king_set_kram_pages(0, 0, 0, 0);

	for(i = 0; i < 16; i++) {
		microprog[i] = KING_CODE_NOP;
	}

	microprog[0] = KING_CODE_BG0_CG_0;
	eris_king_disable_microprogram();
	eris_king_write_microprogram(microprog, 0, 16);
	eris_king_enable_microprogram();

	eris_tetsu_set_palette(0, 0x0088);
	eris_tetsu_set_palette(1, 0xE088);
	eris_tetsu_set_palette(2, 0xE0F0);
	eris_tetsu_set_palette(3, 0x602C);
	eris_tetsu_set_video_mode(TETSU_LINES_262, 0, TETSU_DOTCLOCK_5MHz, TETSU_COLORS_16,
				TETSU_COLORS_16, 0, 0, 1, 0, 0, 0, 0);
	eris_king_set_bat_cg_addr(KING_BG0, 0, 0);
	eris_king_set_bat_cg_addr(KING_BG0SUB, 0, 0);
	eris_king_set_scroll(KING_BG0, 0, 0);
	eris_king_set_bg_size(KING_BG0, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256);
	eris_king_set_kram_read(0, 1);
	eris_king_set_kram_write(0, 1);
	// Clear BG0's RAM
	for(i = 0x0; i < 0x1E00; i++) {
		eris_king_kram_write(0);
	}
	printstr("FX Controller Test", 7, 0x8, 1);

	contrlr_pad_init(0);
	for(;;) {
		paddata = contrlr_pad_read(0);
		padtype = contrlr_pad_type(0);

		if(padtype == CONTRLR_TYPE_NONE)
		{
			if (padtype != old_padtype)
			{
				printstr("  NONE  ", 0, 0x70, 0);

				printstr("                             ", 0, 0x28, 0); // Nothing to show
				printstr("                             ", 0, 0x30, 0);
				printstr("                             ", 0, 0x38, 0);
				printstr("                             ", 0, 0x40, 0);
				printstr("                             ", 0, 0x48, 0);
				printstr("                             ", 0, 0x50, 0);
				printstr("                             ", 0, 0x58, 0);
				printstr("                             ", 0, 0x60, 0);
				printstr("  TYPE                       ", 0, 0x68, 0);
			}
		}
		else if(padtype == CONTRLR_TYPE_MOUSE)
		{
			if (padtype != old_padtype)
			{
				printstr(" MOUSE  ", 0, 0x70, 0);

				printstr("            LEFT  RIGHT      ", 0, 0x28, 0);
				printstr("                             ", 0, 0x30, 0);
				printstr("                             ", 0, 0x38, 0);
				printstr("                 ^           ", 0, 0x40, 0);
				printstr("               < * >         ", 0, 0x48, 0);
				printstr("                 v           ", 0, 0x50, 0);
				printstr("                             ", 0, 0x58, 0);
				printstr("                             ", 0, 0x60, 0);
				printstr("  TYPE                       ", 0, 0x68, 0);
			}

			mouse_x = contrlr_mouse_x(0);
			mouse_y = contrlr_mouse_y(0);

			if (paddata & MOUSE_LEFT)
				printstr("+", 14, 0x30, 0);
			else
				printstr(" ", 14, 0x30, 0);

			if (paddata & MOUSE_RIGHT)
				printstr("+", 20, 0x30, 0);
			else
				printstr(" ", 20, 0x30, 0);

			if (mouse_x > 127) {
				printstr("   ", 20, 0x48, 0);
				sprintf(xstr,"%3d", 256-mouse_x);
				printstr(xstr, 11, 0x48, 0);
			}
			else if (mouse_x > 0) {
				printstr("   ", 11, 0x48, 0);
				sprintf(xstr,"%3d", mouse_x);
				printstr(xstr, 20, 0x48, 0);
			}
			else {
				printstr("   ", 20, 0x48, 0);
				printstr("   ", 11, 0x48, 0);
			}

			if (mouse_y > 127) {
				printstr("   ", 16, 0x38, 0);
				sprintf(ystr,"%3d", 256-mouse_y);
				printstr(ystr, 16, 0x38, 0);
			}
			else if (mouse_x > 0) {
				printstr("   ", 16, 0x58, 0);
				sprintf(ystr,"%3d", mouse_y);
				printstr(ystr, 16, 0x58, 0);
			}
			else {
				printstr("   ", 16, 0x38, 0);
				printstr("   ", 16, 0x58, 0);
			}

		}
		else if(padtype == CONTRLR_TYPE_MULTITAP)
		{
			if (padtype != old_padtype)
			{
				printstr("   TAP  ", 0, 0x70, 0);

				printstr("                             ", 0, 0x28, 0); // Nothing to show
				printstr("                             ", 0, 0x30, 0);
				printstr("                             ", 0, 0x38, 0);
				printstr("                             ", 0, 0x40, 0);
				printstr("                             ", 0, 0x48, 0);
				printstr("                             ", 0, 0x50, 0);
				printstr("                             ", 0, 0x58, 0);
				printstr("                             ", 0, 0x60, 0);
				printstr("  TYPE                       ", 0, 0x68, 0);
			}
		}
		else if(padtype == CONTRLR_TYPE_FXPAD)
		{
			if (padtype != old_padtype)
			{
				printstr("   PAD  ", 0, 0x70, 0);

				printstr("|  UP  | DOWN | LEFT |RIGHT |", 0, 0x28, 0); // show header info
				printstr("                             ", 0, 0x30, 0);
				printstr("|   I  |  II  |  III |       ", 0, 0x38, 0);
				printstr("                             ", 0, 0x40, 0);
				printstr("|  IV  |   V  |  VI  |       ", 0, 0x48, 0);
				printstr("                             ", 0, 0x50, 0);
				printstr("|  RUN |SELECT|   A  |   B  |", 0, 0x58, 0);
				printstr("                             ", 0, 0x60, 0);
				printstr("  TYPE                       ", 0, 0x68, 0);
			}

			for(i = 0; i < 16; i++) {
				if(paddata & (1 << i))
					printstr("+", padmap[i][0], padmap[i][1], 0); // show individual joypad keys
				else
					printstr(" ", padmap[i][0], padmap[i][1], 0);
			}
		}
		for(i = 0; i < 0x8000; i++) {
			asm("mov r0, r0");
		}
		old_padtype = padtype;
	}

	return 0;
}

void printstr(const char* str, int x, int y, int tall)
{
	int i;
	u32 tempstr;

	u32 kram = x + (y << 5);
	int len = strlen(str);
	for(i = 0; i < len; i++) {
		tempstr = str[i];
		printch(tempstr, kram + i, tall);
	}
}

void printch(u32 sjis, u32 kram, int tall)
{
	u16 px;
	int x, y;
	u8* glyph = romfont_get(sjis, tall ? ROMFONT_ANK_8x16 : ROMFONT_ANK_8x8);
	for(y = 0; y < (tall ? 16 : 8); y++) {
		eris_king_set_kram_write(kram + (y << 5), 1);
		px = 0;
		for(x = 0; x < 8; x++) {
			if((glyph[y] >> x) & 1) {
				px |= 1 << (x << 1);
			}
		}
		eris_king_kram_write(px);
	}
}

