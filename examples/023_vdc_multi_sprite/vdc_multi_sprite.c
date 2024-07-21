/*
	libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011		Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024		David Shadoff  GitHub userid: dshadoff


# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

#include <string.h>
#include <stdlib.h>

#include <pcfx/types.h>
#include <pcfx/v810.h>
#include <pcfx/contrlr.h>
#include <pcfx/romfont.h>
#include <pcfx/king.h>
#include <pcfx/tetsu.h>
#include <pcfx/vdc.h>

void printch(u32 sjis, u32 kram, int tall);
void printstr(const char* str, int x, int y, int tall);

// This data is sprite encoding data for a small dot
//
const uint16_t spr_data[] = {
  0xC000,0xC000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
  0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
};

const uint16_t sprite_image_load_addr = 0x4000;  // just a location in video memory

// Each element will have a position (x,y) and a vector of movement (dx,dy)
// - palette is so that we can have some color variance, but not expected to be extreme
// - active indicates whether the sprite is enabled/disabled
//
typedef struct {
	int x;
	int y;
	int dx;
	int dy;
	int active;
	int palette;
} element;

element pixels[64];  // VDC can handle up to 64 sprites

int x, y;

///////////////////////////////// Interrupt handler variables
volatile int sda_frame_count = 0;
volatile int last_sda_frame_count = 0;

///////////////////////////////// Interrupt handler
__attribute__ ((interrupt_handler)) void my_vblank_irq (void)
{
   int16_t vdc_stat = vdc_status(0);

   if (vdc_stat & VDC_STAT_VD )
   {
      sda_frame_count++;
   }
}
///////////////////////////////// Interrupt handler end


// wait_vsync(0) will wait until the next VBlank period.
// higher values will wait for more frames
//
void wait_vsync(int numframes)
{
   while (sda_frame_count < (last_sda_frame_count + numframes + 1));

   last_sda_frame_count = sda_frame_count;
}


// Put known position, and random direction/speed & color to them
//
void initialize_pixels(void)
{
int i;
int temprand;

    srand(563);

    for (i = 0; i < 63; i++) {
        pixels[i].active = 1;
        pixels[i].x = (128 + 0x20) << 8;
        pixels[i].y = (120 + 0x40) << 8;

	temprand = rand();
        pixels[i].dx = ((temprand & 0x3ff) - 0x100) & 0x3ff;
	if ((temprand & 0x800) != 0)
            pixels[i].dx = pixels[i].dx * (-1);

	temprand = rand();
        pixels[i].dy = temprand & 0x3ff;
	if ((temprand & 0x800) != 0)
            pixels[i].dy = pixels[i].dy * (-1);

        pixels[i].dy -= 0x90 ;

	pixels[i].palette = (rand() & 3) + 1;
    }
}

// This loop should go from top to bottom once per frame
// We make sure of it by putting a wait_vsync(0) at the bottom
//
void mainloop(void)
{
int i;
u32 pad;

	pad = contrlr_pad_read(0);
	if (pad & JOY_RUN)
	    initialize_pixels();

	vdc_set(VDC0);
	for (i = 0; i < 63; i++)
	{
	    if (pixels[i].active == 0)
	        continue;

	    vdc_spr_set(i);


	    pixels[i].x += pixels[i].dx;
	    if ((pixels[i].x < 0x1f00) || (pixels[i].x > 0x14000)) {
	        pixels[i].active = 0;
	    }
	    pixels[i].y += pixels[i].dy;
	    if ((pixels[i].y < 0x3f00) || (pixels[i].y > 0x14000)) {
	        pixels[i].active = 0;
	    }

	    if (pixels[i].active != 0)
	        pixels[i].dy += 0x10;

	    x = (pixels[i].x >> 8);
	    y = (pixels[i].y >> 8);

	    vdc_spr_xy(x, y);
	}

	wait_vsync(0);
}

int main(int argc, char *argv[])
{
	int i;
	u16 microprog[16];

	vdc_init_5MHz(VDC0);
	vdc_init_5MHz(VDC1);

	king_init();
	tetsu_init();
	contrlr_pad_init(0);
	
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
	tetsu_set_palette(0x10, 0x0088);
	tetsu_set_palette(0x11, 0xE088);
	tetsu_set_palette(0x20, 0x0088);
	tetsu_set_palette(0x21, 0xE08F);
	tetsu_set_palette(0x30, 0x0088);
	tetsu_set_palette(0x31, 0xE0F0);
	tetsu_set_palette(0x40, 0x0088);
	tetsu_set_palette(0x41, 0xFF39);

	tetsu_set_video_mode(TETSU_LINES_262, 0, TETSU_DOTCLOCK_5MHz, TETSU_COLORS_16,
				TETSU_COLORS_16, 0, 1, 1, 0, 0, 0, 0);
	king_set_bat_cg_addr(KING_BG0, 0, 0);
	king_set_bat_cg_addr(KING_BG0SUB, 0, 0);
	king_set_scroll(KING_BG0, 0, 0);
	king_set_bg_size(KING_BG0, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256);

        vdc_setreg(VDC0, VDC_REG_CR, VDC_CR_SB);
        vdc_setreg(VDC0, VDC_REG_MWR, VDC_MWR_SCREEN_32x32);
	vdc_set_scroll(VDC0, 0, 0);

	king_set_kram_read(0, 1);
	king_set_kram_write(0, 1);

	// Clear BG0's RAM
	for(i = 0; i < 0x1E00; i++) {
		king_kram_write(0);
	}

	// load sprite data
	// -> Place at VRAM address set by sprite_image_load_addr
	//
	vdc_set_vram_write(VDC0, sprite_image_load_addr);
	for(i = 0; i < 8*4; i++) {
		vdc_vram_write(VDC0, spr_data[i]); /* sprite is plus sign */
	}

	vdc_set(VDC0);

	initialize_pixels();
	for (i = 0; i < 63; i++) {
	    vdc_spr_set(i);  // Use sprite #0, but could be any (0 - 63)
	    vdc_spr_create((pixels[i].x>>8),
	                   (pixels[i].y>>8),
			   VDC_SPR_PATTERN(sprite_image_load_addr),
			   pixels[i].palette);
	}

	king_set_kram_write(0, 1);
	printstr("VDC multi-sprite example", 5, 0x10, 1);

        // Disable all interrupts before changing handlers.
        irq_set_mask(0x7F);

        // Replace firmware IRQ handlers for the Timer and HuC6270-A.
        //
        // This libpcfx function uses the V810's hardware IRQ numbering,
        // see FXGA_GA and FXGABOAD documents for more info ...
        irq_set_raw_handler(0xC, my_vblank_irq);

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

	/* Now that the interrupt is set up, we can enable the hardware to produce it */
	vdc_setreg(VDC0, VDC_REG_CR, (VDC_CR_SB|VDC_CR_IRQ_VC));  // Set Hu6270 SP to show, and VSYNC Interrupt

	x = 0xA0;  // note that X-offsets are not 0-relative (0x20 is the left edge of the screen)
	y = 0xC0;  // note that Y-offsets are not 0-relative (0x40 is the top edge of the screen)

	while (1) {
	    mainloop();
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

