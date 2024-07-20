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

// This data is the font, from font.S
// 
extern u8 font[];

volatile int sda_frame_count = 0;
volatile int scroll_x = 0;
volatile int scroll_y = 0;

volatile int scroll_band = 0;
const int scroll_1_line = 104;
const int scroll_2_line = 144;

// Note:
// If the raster interrupt could happen during other VRAM updates, you should use
// vdc_get_last_regnum() to fetch the VDC register last used, and set it again at
// the end of the interrupt (see "FXBOAD" documentation from GMaker development kit)
//
__attribute__ ((interrupt_handler)) void my_video_irq (void)
{
   int16_t vdc_stat = vdc_status(0);

   if (vdc_stat & VDC_STAT_RR )
   {
      if (scroll_band == 0) {
         vdc_set_scroll(VDC0, scroll_x, scroll_1_line - 1);
	 vdc_set_raster(VDC0, scroll_2_line + 64);  // Need to set raster at line <n> + 64
      }
      else
         vdc_set_scroll(VDC0, (scroll_x<<1), scroll_2_line - 1);

      scroll_band++;
   }

   if (vdc_stat & VDC_STAT_VD )
   {
      sda_frame_count++;

      scroll_band = 0;

      vdc_set_scroll(VDC0, scroll_x, scroll_y);

      if ((sda_frame_count & 3) == 0)
      {
         scroll_x++;

	 if (scroll_x == 128)
            scroll_x = 0;

      }
      vdc_set_scroll(VDC0, 0, 0);                // At top of frame, "lock it in" to origin
      vdc_set_raster(VDC0, scroll_1_line + 64);  // Setup next raster interrupt
   }
}


int main(int argc, char *argv[])
{
	int i,j;
	u16 a, img;
	u16 microprog[16];

	vdc_init_5MHz(VDC0);
	vdc_init_5MHz(VDC1);

	vdc_setreg(VDC0, VDC_REG_MWR, VDC_MWR_SCREEN_32x32);
	vdc_set_scroll(VDC0, 0, 0);

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
	tetsu_set_palette(3, 0xFF88);
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

	king_set_kram_read(0, 1);
	king_set_kram_write(0, 1);

	// Clear BG0's RAM
	for(i = 0; i < 0x1E00; i++) {
		king_kram_write(0);
	}

        //
        // load font into video memory
        // font background/foreground should be subpalettes #0 and #3 respectively
        //
        vdc_set_vram_write(0, 0x1200);

        for(i = 0; i < 0x60; i++) {
           // first 2 planes of color
           for (j = 0; j < 8; j++) {
              img = font[(i*8)+j] & 0xff;
              a = (img << 8) | img;
              vdc_vram_write(0, a);
           }
           // last 2 planes of color
           for (j = 0; j < 8; j++) {
              vdc_vram_write(0, 0);
           }
        }

	// set up the BAT (background attribute table
	//
	vdc_set_vram_write(VDC0, 0);
	for(i = 0; i < (32 * 5); i++) {          /* First 5 lines need to be blank, to avoid covering the title */
		vdc_vram_write(VDC0, 0x120);     /* All tiles are at tile 0x120 (blank) */
	}
	for(i = 0; i < (32-5); i++) {            /* From like 5 to line 32 */
            for (j = 0; j < 32; j++) {
		vdc_vram_write(VDC0, (0x141+i)); /* Each line should be all one alphabetical character */
            }
	}

	king_set_kram_write(0, 1);
	printstr("VDC Raster example", 7, 0x10, 1);

	vdc_setreg(VDC0, VDC_REG_CR, VDC_CR_BB);

        // Disable all interrupts before changing handlers.
        irq_set_mask(0x7F);

        // Replace firmware IRQ handlers for the Timer and HuC6270-A.
        //
        // This libpcfx function uses the V810's hardware IRQ numbering,
        // see FXGA_GA and FXGABOAD documents for more info ...
        irq_set_raw_handler(0xC, my_video_irq);

        // Enable Timer and HuC6270-A interrupts.
        //
        // d6=Timer
        // d5=External
        // d4=KeyPad
        // d3=HuC6270-A
        // d2=HuC6272
        // d1=HuC6270-B
        // d0=HuC6273
        irq_set_mask(0x77);

        // Allow all IRQs.
        //
        // This libpcfx function uses the V810's hardware IRQ numbering,
        // see FXGA_GA and FXGABOAD documents for more info ...
        irq_set_level(8);

        // Enable V810 CPU's interrupt handling.
        irq_enable();

        vdc_setreg(VDC0, VDC_REG_CR, (VDC_CR_BB | VDC_CR_IRQ_RC | VDC_CR_IRQ_VC));

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

