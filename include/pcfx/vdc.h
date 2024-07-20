/*
        liberis -- A set of libraries for controlling the NEC PC-FX

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
Copyright (C) 2011                           Nodtveidt <david@eponasoft.com>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*
 *  High-level access to the VDC (HuC6270) video chips.
 */

#ifndef _LIBPCFX_VDC_H_
#define _LIBPCFX_VDC_H_


// Normal sequence of operation:
// -----------------------------
// Based on frequency choice when initializing TETSU (5MHz or 7MHz), use
// the appropriate vdc_init_xMHz() initialization function which clears
// VRAM, and initializes VDC registers to default settings for that pixel
// clock.
//
// Functions are supplied for the SIMPLE VDC registers which are most likely
// to be changed by the programmer (RCR, BXR, BYR, SOUR/DESR/LENR, DVSSR)
//
// For other VDC registers such as bitfield registers (CR, MWR, DCR), and
// screen size/position registers (HSR, HDR, VPR, VDR, VCR), you can use
// vdc_setreg using the MACRO names below.
//
// You will almost certainly want to go back and set the CR register to
// show background and sprites (they are disabled by default).
//
// You will also probably want to trigger a VBLANK interrupt.
//
// Note that only the memory is readable - the registers are not. This
// is one reason why the multi-bitfield registers don't have direct-setting
// functions (the origianl version of liberis assumed that they were indeed
// readable and tried to set sub-bitfields, resulting in bad settings).
//
// Remember to set up interrupt handling in your program before setting
// any of these registers to fire interrupts.
//



// HuC6270 VDC defines
//
#define VDC_REG_MAWR    0x00      // Memory Address Write register
#define VDC_REG_MARR    0x01      // Memory Address Read register
#define VDC_REG_DATA    0x02      // Data (write or read)
#define VDC_REG_CR      0x05      // Control register
#define VDC_REG_RCR     0x06      // Raster Counter register
#define VDC_REG_BXR     0x07      // BGX Scroll register
#define VDC_REG_BYR     0x08      // BGY Scroll register
#define VDC_REG_MWR     0x09      // Memory Access Width register
#define VDC_REG_HSR     0x0A      // Horizontal Sync register
#define VDC_REG_HDR     0x0B      // Horizontal Display register
#define VDC_REG_VPR     0x0C      // Vertical Sync register
#define VDC_REG_VDR     0x0D      // Vertical Display register
#define VDC_REG_VCR     0x0E      // Vertical Display End Position register
#define VDC_REG_DCR     0x0F      // Block Transfer Control register
#define VDC_REG_SOUR    0x10      // Block Transfer Source Address register
#define VDC_REG_DESR    0x11      // Block Transfer Destination Address register
#define VDC_REG_LENR    0x12      // Block Transfer Length register
#define VDC_REG_DVSSR   0x13      // VRAM-SATB Block Transfer Source Address register

#define VDC_STAT_CR     0x0001    // Collision detect
#define VDC_STAT_OR     0x0002    // Over detect (too many sprites)
#define VDC_STAT_RR     0x0004    // Raster scanline detect
#define VDC_STAT_DS     0x0008    // Block xfer from VRAM to SATB end detect
#define VDC_STAT_DV     0x0010    // Block xfer from VRAM to VRAM end detect
#define VDC_STAT_VD     0x0020    // Vertical Blank Detect
#define VDC_STAT_BSY    0x0040    // Busy

#define VDC_CR_IRQ_CC   0x0001    // Interrupt Request Enable on collision detect
#define VDC_CR_IRQ_OC   0x0002    // Interrupt Request Enable on over detect
#define VDC_CR_IRQ_RC   0x0004    // Interrupt Request Enable on raster detect
#define VDC_CR_IRQ_VC   0x0008    // Interrupt Request Enable on vertical blank detect

// Note that CR bits 0x0010 and 0x0020 are for external sync ('EX'), which are normally '00'
#define VDC_CR_SB       0x0040    // Sprite blank (1 = visible)
#define VDC_CR_BB       0x0080    // Background blank (1 = visible)

// Note that CR bits 0x0100 and 0x0200 are for DISP output select ('TE'), which are normally '00'
// Note that CR bit  0x0400 is for Dynamic RAM refresh ('DR'), which is normally '0'

#define VDC_CR_IW_01    0x0000    // Bitfield for auto-increment of address pointer of 0x01
#define VDC_CR_IW_20    0x0800    // Bitfield for auto-increment of address pointer of 0x20
#define VDC_CR_IW_40    0x1000    // Bitfield for auto-increment of address pointer of 0x40
#define VDC_CR_IW_80    0x1800    // Bitfield for auto-increment of address pointer of 0x80

// Note that MWR VRAM   access width mode (0x0001 & 0x0002) is usually '00'
// Note that MWR Sprite access width mode (0x0004 & 0x0008) is usually '00'
#define VDC_MWR_SCREEN_32x32   0x0000    // Bitfield for virtual screen map of  32 wide, 32 tall
#define VDC_MWR_SCREEN_64x32   0x0010    // Bitfield for virtual screen map of  64 wide, 32 tall
#define VDC_MWR_SCREEN_128x32  0x0020    // Bitfield for virtual screen map of 128 wide, 32 tall
#define VDC_MWR_SCREEN_32x64   0x0040    // Bitfield for virtual screen map of  32 wide, 64 tall
#define VDC_MWR_SCREEN_64x64   0x0050    // Bitfield for virtual screen map of  64 wide, 64 tall
#define VDC_MWR_SCREEN_128x64  0x0060    // Bitfield for virtual screen map of 128 wide, 64 tall
// Note that MWR CG mode for 4 clocks ode (0x0080) is usually '0'

#define VDC_DCR_SATB_IRQ   0x0001    // Generate IRQ upon completion of SATB DMA
#define VDC_DCR_VRAM_IRQ   0x0002    // Generate IRQ upon completion of VRAM-VRAM DMA
#define VDC_DCR_SRC_DEC    0x0004    // Decrement source addr during DMA (0 = Inc; 1 = Dec)
#define VDC_DCR_DST_DEC    0x0008    // Decrement dest   addr during DMA (0 = Inc; 1 = Dec)
#define VDC_DCR_SATB_AUTO  0x0010    // Automatically trigger SATB each VBlank



#define VDC_CHR_SIZE        0x10
#define VDC_CHRREF(palette, vramaddr)       ((palette << 12) | (vramaddr >> 4))

#define VDC_SPR_Y_INVERT         0x8000
#define VDC_SPR_Y_HEIGHT_1       0x0
#define VDC_SPR_Y_HEIGHT_2       0x1000
#define VDC_SPR_Y_HEIGHT_4       0x3000

#define VDC_SPR_X_INVERT         0x800
#define VDC_SPR_X_WIDTH_1        0x0
#define VDC_SPR_X_WIDTH_2        0x100
#define VDC_SPR_PRIO_BG          0x0
#define VDC_SPR_PRIO_SP          0x80
#define VDC_SPR_PATTERN(vramaddr)        (vramaddr >> 5)


#define VDC_SPR_CELL        0x0040

typedef enum {
        VDC0,
        VDC1
} VDCNUM;



// General
void vdc_init_5MHz(int chip);
void vdc_init_7MHz(int chip);
void vdc_set(int chip);

// Sprites
void vdc_spr_set(int spr);
void vdc_spr_x(s16 x);
void vdc_spr_y(s16 y);
void vdc_spr_xy(s16 x, s16 y);
void vdc_spr_pattern(u16 pat);
void vdc_spr_pri(int pri);
void vdc_spr_pal(int pal);
void vdc_spr_ctrl(u16 mask, u16 val);
void vdc_spr_create(s16 x, s16 y, u16 pat, u16 ctrl);
s16 vdc_spr_get_x(void);
s16 vdc_spr_get_y(void);
u16 vdc_spr_get_pattern(void);
u16 vdc_spr_get_ctrl(void);
int vdc_spr_get_pal(void);



//***************************************
// "LOW LEVEL" functions
//***************************************
//

/* Get VDC status
 *
 * chip:  Which VDC to act on. (0 ~ 1)
 *
 * return value: The VDC status
 */
s16 vdc_status(int chip);

/* Set a VDC register to a value
 *
 * chip:  Which VDC to act on. (0 ~ 1)
 * reg:   Which VDC register to initialize. (0 ~ 0x13)
 * value: The value to set it to (0 ~ 0xFFFF)
 */
void vdc_setreg(int chip, int reg, int value);


/* Set the VRAM write address for a VDC chip.
 *
 * chip:  Which VDC to set the write address for. (0 ~ 1)
 * addr:  New VRAM address for write pointer.
 */
void vdc_set_vram_write(int chip, u16 addr);

/* Write to VRAM on a VDC chip.
 *
 * chip:  Which VDC to write data to. (0 ~ 1)
 * data:  Data to write.
 */
void vdc_vram_write(int chip, u16 data);

/* Set the VRAM read address for a VDC chip.
 *
 * chip:  Which VDC to set the read address for. (0 ~ 1)
 * addr:  New VRAM address for read pointer.
 */
void vdc_set_vram_read(int chip, u16 addr);

/* Read from VRAM from a VDC chip.
 *
 * chip:  Which VDC to read data from. (0 ~ 1)
 * return = The data located at the read pointer address.
 */
u16 vdc_vram_read(int chip);


/*! Set interrupt information for a VDC chip.
 *
 * chip:          Which VDC to set interrupts for. (0 ~ 1)
 * vblank_irq:    Whether an IRQ should fire on VBlank.
 * raster_irq:    Whether an IRQ should fire on raster match.
 * excess_spr:    Whether an IRQ should fire on too many sprites per line.
 * spr_collision: Whether an IRQ should fire on a sprite overlapping
 *                      sprite 0.
 */
void vdc_set_interrupts(int chip, int vblank_irq, int raster_irq,
                        int excess_spr, int spr_collision);

/* Set the raster to generate an IRQ from.
 *
 * chip:   Which VDC to set the raster on. (0 ~ 1)
 * raster: Which raster to generate an IRQ on.
 */
void vdc_set_raster(int chip, int raster);

/* Scroll a VDC background.
 *
 * chip: Which VDC to scroll. (0 ~ 1)
 * x:    Top-left X coordinate of the background.
 * y:    Top-left Y coordinate of the background.
 */
void vdc_set_scroll(int chip, u16 x, u16 y);

/* Perform a VDC DMA.
 *
 * chip: Which VDC to DMA on. (0 ~ 1)
 * src:  The source address of the DMA.
 * dst:  The destination of the DMA.
 * len:   How many 16bit words to transfer.
 */
void vdc_do_dma(int chip, u16 src, u16 dst, u16 len);

/* Sets the Sprite Attribute Table Block address.
 *
 * Setting the address starts a VRAM->SATB DMA.
 * chip: Which VDC to set the SATB for. (0 ~ 1)
 * addr: VRAM address for the start of the SATB.
 */
void vdc_set_satb_address(int chip, u16 addr);


#endif
